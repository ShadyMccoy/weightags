require "prawn"
require "prawn/table"

module InvoiceBatches
  class Pdf
    def self.render(batch, verify_url:)
      new(batch, verify_url).render
    end

    def initialize(batch, verify_url)
      @batch = batch
      @verify_url = verify_url
    end

    def render
      doc = Prawn::Document.new(margin: 48)
      header(doc)
      meta(doc)
      table(doc)
      footer(doc)
      doc.render
    end

    private

    def header(doc)
      doc.fill_color "2d2a25"
      doc.text "WeighTags", size: 20, style: :bold
      doc.fill_color "706a61"
      doc.text "Invoice batch summary — System of Record for Commodity Weight Reconciliation", size: 9
      doc.fill_color "1f1d1a"
      doc.move_down 16
    end

    def meta(doc)
      rows = [
        [ "Invoice number", @batch.external_invoice_number ],
        [ "Invoice date", @batch.invoice_date&.strftime("%B %-d, %Y") || "—" ],
        [ "Sender", @batch.sender_org.name ],
        [ "Receiver", @batch.receiver_org.name ],
        [ "Weigh tags", @batch.load_count.to_s ]
      ]
      doc.table(rows, width: doc.bounds.width, cell_style: { borders: [], padding: [ 2, 6 ], size: 10 }) do
        column(0).font_style = :bold
        column(0).width = 130
      end
      doc.move_down 16
    end

    def table(doc)
      header = [ %w[BOL Ship\ date Commodity Truck Net\ (lb)] ]
      rows = @batch.tags.includes(:weighs).order(:ship_date).map do |tag|
        [
          tag.bol,
          tag.ship_date&.strftime("%m/%d/%Y") || "—",
          tag.commodity || "—",
          tag.truck || "—",
          number_with_delimiter((tag.canonical_net || tag.sender_weigh&.net).to_i)
        ]
      end
      total = [ [ "", "", "", "Total net", number_with_delimiter(@batch.total_net.to_i) ] ]

      doc.table(header + rows + total, width: doc.bounds.width, header: true,
        cell_style: { size: 9, padding: [ 4, 6 ] }) do |t|
        t.row(0).font_style = :bold
        t.row(0).background_color = "f5f2ed"
        t.row(-1).font_style = :bold
        t.row(-1).background_color = "f5f2ed"
        t.columns(4).align = :right
        t.column(4).align = :right
      end
    end

    def footer(doc)
      doc.move_down 20
      doc.fill_color "706a61"
      doc.text "Verify this record at:", size: 9
      doc.fill_color "4f46e5"
      doc.text @verify_url, size: 9
      doc.fill_color "706a61"
      doc.move_down 6
      doc.text "This is a neutral record of reconciled weigh tags. WeighTags does not generate the " \
               "invoice or its monetary total.", size: 8
    end

    def number_with_delimiter(n)
      ActiveSupport::NumberHelper.number_to_delimited(n.to_i)
    end
  end
end
