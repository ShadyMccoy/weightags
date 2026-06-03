class CsvImportsController < ApplicationController
  include PartnerResolution
  before_action :require_org

  def new
    @partners = partner_options
  end

  def create
    @counterparty = resolve_counterparty
    @side = chosen_side
    @csv_text = read_csv_text

    if @counterparty.nil?
      redirect_to new_csv_import_path, alert: "Choose a partner for this import." and return
    end
    if @csv_text.blank?
      redirect_to new_csv_import_path, alert: "Choose a CSV file to import." and return
    end

    @import = build_import

    if params[:report].present?
      send_data @import.error_report_csv,
        filename: "weightags-import-errors.csv", type: "text/csv" and return
    end

    if @import.parse_error || @import.missing_required.any? || @import.invalid_rows.any?
      Alerter.raise!(kind: "csv_ingest_error",
        message: @import.parse_error || "CSV import had rejected rows",
        org_id: Current.org.id, missing: @import.missing_required, rejected: @import.invalid_rows.size)
    end

    render :preview
  end

  def commit
    @counterparty = Current.org.partner_orgs.find(params[:counterparty_org_id])
    @side = chosen_side
    @csv_text = params[:csv_text].to_s
    @import = build_import

    imported = @import.import!
    if imported.positive?
      AuditEvent.record!(action: "csv.imported", user: Current.user, actor_org: Current.org,
        metadata: { rows: imported, side: @side, partner: @counterparty.name })
      redirect_to tags_path, notice: "Imported #{imported} weigh #{'tag'.pluralize(imported)}."
    else
      redirect_to new_csv_import_path, alert: "Nothing was imported — every row was rejected."
    end
  rescue => e
    Alerter.raise!(kind: "csv_ingest_error", message: "commit failed: #{e.message}",
      org_id: Current.org&.id)
    redirect_to new_csv_import_path, alert: "Import failed; no rows were saved."
  end

  private

  def build_import
    Csv::WeighImport.new(csv_text: @csv_text, org: Current.org,
      counterparty: @counterparty, side: @side, actor: Current.user)
  end

  def read_csv_text
    if params[:file].respond_to?(:read)
      params[:file].read.force_encoding("UTF-8")
    else
      params[:csv_text].to_s
    end
  end
end
