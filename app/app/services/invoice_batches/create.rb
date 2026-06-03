module InvoiceBatches
  class Create
    Result = Struct.new(:batch, :ok, :error, keyword_init: true) do
      def ok? = ok
    end

    def initialize(org:, actor:, load_ids:, external_invoice_number:, invoice_date: nil, notes: nil)
      @org = org
      @actor = actor
      @tag_ids = Array(load_ids).reject(&:blank?)
      @number = external_invoice_number.to_s.strip
      @invoice_date = invoice_date
      @notes = notes
    end

    def call
      return failure("Enter an external invoice number.") if @number.blank?

      tags = eligible_loads
      return failure("Select at least one closed, not-yet-invoiced weigh tag.") if tags.empty?

      receivers = tags.map(&:receiver_org_id).uniq
      return failure("Select weigh tags for a single partner per invoice.") if receivers.size > 1

      batch = nil
      ActiveRecord::Base.transaction do
        batch = InvoiceBatch.create!(
          sender_org: @org, receiver_org: Org.find(receivers.first),
          external_invoice_number: @number, invoice_date: @invoice_date,
          notes: @notes, created_by: @actor
        )
        tags.each do |tag|
          tag.update!(invoice_batch: batch, state: :invoiced)
          AuditEvent.record!(action: "tag.invoiced", subject: tag, user: @actor,
            actor_org: @org, bol: tag.bol, metadata: { invoice_number: @number })
        end
        AuditEvent.record!(action: "invoice_batch.created", subject: batch, user: @actor,
          actor_org: @org, metadata: { invoice_number: @number, tags: tags.size })
      end
      tags.each do |l|
        Notifier.invoiced(l)
        Tags::Broadcaster.refresh(l)
      end
      Result.new(batch: batch, ok: true)
    rescue ActiveRecord::RecordInvalid => e
      failure(e.message)
    end

    private

    def eligible_loads
      Tag.where(id: @tag_ids, sender_org_id: @org.id).closed_unbilled.to_a
    end

    def failure(message)
      Result.new(batch: nil, ok: false, error: message)
    end
  end
end
