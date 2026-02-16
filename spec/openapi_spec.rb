require "rails_helper"

describe "OpenAPI document", type: :request do
  subject(:schema) { skooma_openapi_schema }

  it { is_expected.to be_valid_document }
end
