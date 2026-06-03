require "csv"

module Csv
  class WeighImport
    COLUMNS = {
      "bol"         => { required: true },
      "ship_date"   => { type: :date },
      "truck"       => {},
      "driver"      => {},
      "commodity"   => {},
      "gross"       => { type: :decimal },
      "tare"        => { type: :decimal },
      "net"         => { type: :decimal },
      "moisture"    => { type: :decimal },
      "grade"       => {},
      "weighed_by"  => {},
      "scale_id"    => {},
      "weighed_at"  => { type: :datetime },
      "notes"       => {}
    }.freeze

    Row = Struct.new(:line, :raw, :attributes, :errors, keyword_init: true) do
      def valid? = errors.empty?
    end

    attr_reader :rows, :headers

    def initialize(csv_text:, org:, counterparty:, side:, actor:)
      @csv_text = csv_text.to_s
      @org = org
      @counterparty = counterparty
      @side = side
      @actor = actor
      parse!
    end

    def valid_rows   = rows.select(&:valid?)
    def invalid_rows = rows.reject(&:valid?)
    def any?         = rows.any?
    def all_valid?   = invalid_rows.empty? && any?

    def import!
      imported = 0
      ActiveRecord::Base.transaction do
        valid_rows.each do |row|
          result = Weighs::Poster.call(
            org: @org, counterparty: @counterparty, side: @side,
            actor: @actor, attributes: row.attributes
          )
          unless result.ok?
            row.errors.concat(result.weigh.errors.full_messages)
            raise ActiveRecord::Rollback
          end
          imported += 1
        end
      end
      imported
    end

    def error_report_csv
      CSV.generate do |out|
        out << (@headers + [ "errors" ])
        invalid_rows.each do |row|
          out << (@headers.map { |h| row.raw[h] } + [ row.errors.join("; ") ])
        end
      end
    end

    private

    def parse!
      @rows = []
      table = CSV.parse(@csv_text, headers: true)
      @headers = table.headers.compact
      @mapping = build_mapping(@headers)

      validate_headers!
      return unless @missing_required.empty?

      table.each_with_index do |csv_row, i|
        raw = csv_row.to_h
        attributes, errors = coerce(raw)
        @rows << Row.new(line: i + 2, raw: raw, attributes: attributes, errors: errors)
      end
    rescue CSV::MalformedCSVError => e
      @rows = []
      @headers ||= []
      @parse_error = "Could not read the file as CSV: #{e.message}"
    end

    def build_mapping(headers)
      normalized = headers.index_by { |h| normalize(h) }
      COLUMNS.keys.each_with_object({}) do |col, map|
        header = normalized[normalize(col)]
        map[col] = header if header
      end
    end

    def validate_headers!
      @missing_required = COLUMNS.select { |_, o| o[:required] }.keys.reject { |c| @mapping.key?(c) }
    end

    def coerce(raw)
      attrs = {}
      errors = []
      COLUMNS.each do |col, opts|
        header = @mapping[col]
        value = header ? raw[header] : nil
        value = value.to_s.strip if value
        if value.blank?
          errors << "#{col} is required" if opts[:required]
          next
        end
        casted, err = cast(value, opts[:type])
        if err
          errors << "#{col}: #{err}"
        else
          attrs[col.to_sym] = casted
        end
      end
      unless attrs[:net] || (attrs[:gross] && attrs[:tare])
        errors << "net is required (or provide gross and tare)"
      end
      [ attrs, errors ]
    end

    def cast(value, type)
      case type
      when :decimal
        Float(value)
        [ BigDecimal(value), nil ]
      when :date
        [ Date.parse(value), nil ]
      when :datetime
        [ Time.zone.parse(value) || raise(ArgumentError), nil ]
      else
        [ value, nil ]
      end
    rescue ArgumentError, TypeError
      [ nil, "'#{value}' is not a valid #{type}" ]
    end

    def normalize(str)
      str.to_s.downcase.gsub(/[^a-z0-9]/, "")
    end

    public

    def parse_error = @parse_error
    def missing_required = @missing_required || []
    def mapping = @mapping || {}
  end
end
