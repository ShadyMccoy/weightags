module Api
  module V1
    # The whole headless surface: upload a weigh, and sync statuses back down.
    #   GET    /api/v1/weigh_tags      — list (same filters as the web index)
    #   GET    /api/v1/weigh_tags/:id  — one weigh tag
    #   POST   /api/v1/weigh_tags      — record your weigh (creates or pairs)
    class WeighTagsController < BaseController
      MAX_PER_PAGE = 200
      DEFAULT_PER_PAGE = 50

      before_action :require_write_scope, only: :create

      def index
        scope = Tags::Query.new(org: current_org, params: filter_params).results
          .includes(:sender_org, :receiver_org, :weighs, :invoice_batch)
        page = [ params[:page].to_i, 1 ].max
        per_page = per_page_param
        tags = scope.limit(per_page).offset((page - 1) * per_page)

        render json: {
          weigh_tags: tags.map { |t| serialize(t) },
          page: page,
          per_page: per_page
        }
      end

      def show
        tag = current_org.tags
          .includes(:sender_org, :receiver_org, :weighs, :invoice_batch)
          .find(params[:id])
        render json: { weigh_tag: serialize(tag) }
      end

      def create
        into = resolve_into
        return if performed?

        result =
          if into
            Weighs::Poster.call(org: current_org, actor: current_actor,
              attributes: weigh_params, into: into)
          else
            counterparty = resolve_counterparty
            return render_error(:unprocessable_entity,
              "Name a partner: pass 'partner' (or 'partner_id'), or weigh in with 'weigh_tag_id'.") if counterparty.nil?

            Weighs::Poster.call(org: current_org, actor: current_actor,
              counterparty: counterparty, side: side, attributes: weigh_params)
          end

        if result.ok?
          render json: { weigh_tag: serialize(result.tag) }, status: :created
        else
          render_error(:unprocessable_entity, "Could not save weigh tag.",
            result.weigh.errors.full_messages)
        end
      end

      private

      def require_write_scope
        return if current_api_key.can_write?
        render_error(:forbidden,
          "This API key is read-only. Use a read-write key to upload weighs.")
      end

      def serialize(tag)
        Api::WeighTagSerializer.call(tag, current_org)
      end

      def filter_params
        params.permit(:q, :status, :partner_id, :from, :to, :invoice_number)
      end

      def per_page_param
        requested = params[:per_page].to_i
        return DEFAULT_PER_PAGE if requested <= 0
        [ requested, MAX_PER_PAGE ].min
      end

      def weigh_params
        params.permit(:bol, :ship_date, :truck, :driver, :commodity, :gross, :tare,
          :net, :moisture, :grade, :weighed_by, :scale_id, :weighed_at, :notes)
      end

      # Weigh-in against a partner's existing shipment (preferred ingest path): no
      # re-keyed BOL, identity is shared from the start. Restricted to the caller's
      # own tags — a non-participant id 404s.
      def resolve_into
        return nil if params[:weigh_tag_id].blank?
        current_org.tags.find(params[:weigh_tag_id])
      end

      def resolve_counterparty
        if params[:partner_id].present?
          current_org.partner_orgs.find(params[:partner_id])
        elsif params[:partner].present?
          name = params[:partner].to_s.strip
          existing = current_org.partner_orgs.where("lower(orgs.name) = ?", name.downcase).first
          existing || create_partner(name, params[:partner_email].to_s.strip.presence)
        end
      end

      def create_partner(name, invite_email)
        org = Org.create!(name: name, claimed: false)
        Partnership.ensure!(org: current_org, counterparty: org, invite_email: invite_email)
        if invite_email
          InvitationMailer.with(org: org, from_org: current_org, email: invite_email).invite.deliver_later
        end
        org
      end

      def side
        params[:role].to_s.presence_in(%w[sender receiver]) || "sender"
      end
    end
  end
end
