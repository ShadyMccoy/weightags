module Api
  module V1
    # Base for the headless API. Bearer-token auth, no cookies, JSON only. Sets
    # Current.org from the key and binds the request to that org's row-level
    # security scope — the same isolation the web app gets, enforced in Postgres.
    class BaseController < ActionController::API
      before_action :authenticate_api_key!
      before_action :scope_to_org

      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from ActionController::ParameterMissing, with: :unprocessable

      private

      attr_reader :current_api_key

      def authenticate_api_key!
        @current_api_key = ApiKey.authenticate(bearer_token)
        unless @current_api_key
          return render_error(:unauthorized,
            "Provide a valid API key as 'Authorization: Bearer <token>'.")
        end
        @current_api_key.mark_used!
        Current.org = @current_api_key.org
      end

      def bearer_token
        request.authorization.to_s[/\ABearer\s+(.+)\z/i, 1]&.strip
      end

      def current_org
        Current.org
      end

      # The user who minted the key — the actor attributed in the audit log.
      def current_actor
        current_api_key.user
      end

      # Bind this request to the key's org for Postgres row-level security, the
      # same GUC the web Tenancy concern sets per request.
      def scope_to_org
        ActiveRecord::Base.connection.execute(
          ActiveRecord::Base.sanitize_sql(
            [ "SELECT set_config('app.accessible_org_ids', ?, false)", current_org.id.to_s ]
          )
        )
      rescue => e
        Rails.logger.warn("[API] could not set RLS scope: #{e.message}")
      end

      def render_error(status, message, details = nil)
        body = { error: message }
        body[:details] = details if details.present?
        render json: body, status: status
      end

      def not_found
        render_error(:not_found, "Not found.")
      end

      def unprocessable(error)
        render_error(:unprocessable_entity, error.message)
      end
    end
  end
end
