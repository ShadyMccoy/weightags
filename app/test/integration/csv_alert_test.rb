require "test_helper"

class CsvAlertTest < ActionDispatch::IntegrationTest
  setup { @rel = build_relationship }

  test "previewing a malformed CSV raises a csv_ingest_error alert" do
    sign_in_as @rel.grower_user
    file = Rack::Test::UploadedFile.new(
      StringIO.new("Gross,Tare\n50000,12000\n"), "text/csv", original_filename: "bad.csv"
    )
    assert_difference -> { OperationalAlert.where(kind: "csv_ingest_error").count }, 1 do
      post csv_imports_path, params: { file: file, counterparty_org_id: @rel.buyer.id, side: "sender" }
    end
    assert_response :success # the preview renders, surfacing the missing-column error
  end
end
