class InvoiceBatchesController < ApplicationController
  before_action :require_org
  before_action :set_batch, only: %i[show pdf]

  def index
    @batches = InvoiceBatch.for_org(current_org).includes(:sender_org, :receiver_org, :tags)
      .order(created_at: :desc)
  end

  def show
  end

  def pdf
    data = InvoiceBatches::Pdf.render(@batch, verify_url: verify_url(@batch.token))
    send_data data, filename: "invoice-#{@batch.external_invoice_number.parameterize}.pdf",
      type: "application/pdf", disposition: "inline"
  end

  def new
    @tags = current_org.sent_tags.closed_unbilled
      .includes(:receiver_org, :weighs).order(ship_date: :desc)
  end

  def create
    result = InvoiceBatches::Create.new(
      org: current_org, actor: Current.user,
      load_ids: params[:load_ids], external_invoice_number: params[:external_invoice_number],
      invoice_date: params[:invoice_date], notes: params[:notes]
    ).call

    if result.ok?
      redirect_to tags_path(status: "invoiced"),
        notice: "Marked #{result.batch.tags.size} weigh #{'tag'.pluralize(result.batch.tags.size)} as invoiced under #{result.batch.external_invoice_number}."
    else
      redirect_to new_invoice_batch_path, alert: result.error
    end
  end

  private

  def set_batch
    @batch = InvoiceBatch.for_org(current_org).find(params[:id])
  end
end
