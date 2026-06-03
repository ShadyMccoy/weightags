require "test_helper"

class Csv::WeighImportTest < ActiveSupport::TestCase
  setup { @rel = build_relationship }

  def import(text)
    Csv::WeighImport.new(csv_text: text, org: @rel.grower, counterparty: @rel.buyer,
      side: :sender, actor: @rel.grower_user)
  end

  VALID = <<~CSV
    BOL,Ship Date,Truck,Commodity,Gross,Tare
    BOL-100,2026-05-27,T-12,Almonds,52000,14000
    BOL-101,2026-05-27,T-13,Almonds,48000,13500
  CSV

  test "valid rows preview their mapped values and commit exactly those rows" do
    imp = import(VALID)
    assert imp.all_valid?
    assert_equal 2, imp.valid_rows.size
    assert_equal "bol", imp.mapping.keys.first # bol mapped from "BOL"

    assert_difference -> { Weigh.count }, 2 do
      assert_equal 2, imp.import!
    end
    assert_equal 38_000, Weigh.find_by(bol: "BOL-100").net # derived gross - tare
  end

  test "malformed rows are rejected row-by-row with reasons and an error report" do
    text = <<~CSV
      BOL,Gross,Tare
      BOL-200,50000,12000
      ,49000,12000
      BOL-202,notanumber,12000
    CSV
    imp = import(text)

    assert_equal 1, imp.valid_rows.size
    assert_equal 2, imp.invalid_rows.size
    assert_match(/bol is required/i, imp.invalid_rows.first.errors.join)
    report = imp.error_report_csv
    assert_match "errors", report
    assert_match(/not a valid decimal/i, report)
  end

  test "commit is all-or-nothing — a row without a net weight is rejected, valid rows still need atomicity" do
    text = "BOL,Net\nBOL-300,1000\nBOL-301,\n"
    imp = import(text)
    assert_equal 1, imp.valid_rows.size
    assert_equal 1, imp.invalid_rows.size # missing net (no gross/tare either)
    assert_match(/net is required/i, imp.invalid_rows.first.errors.join)
  end

  test "a missing required column is reported, nothing parses as a row" do
    imp = import("Gross,Tare\n50000,12000\n")
    assert_includes imp.missing_required, "bol"
    assert_empty imp.valid_rows
  end
end
