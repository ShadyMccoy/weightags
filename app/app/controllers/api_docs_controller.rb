# Public, no-auth API reference. Serves the OpenAPI spec (the broadly-accepted
# standard, importable into Postman/Insomnia/Stoplight) and a rendered Redoc page.
class ApiDocsController < ApplicationController
  allow_unauthenticated_access
  layout false

  SPEC_PATH = Rails.root.join("config", "openapi.yaml")

  # Human-readable reference (Redoc renders the spec below).
  def show
  end

  # The machine-readable OpenAPI document.
  def spec
    send_file SPEC_PATH, type: "application/yaml", disposition: "inline"
  end
end
