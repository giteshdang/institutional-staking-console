# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Stake operations API", type: :request do
  let!(:org) { Organization.create!(name: "Test Org") }
  let!(:key) { ApiKey.create!(organization: org, token: "test-key") }
  let!(:ethereum) { Network.create!(slug: "ethereum", display_name: "Ethereum") }
  let(:headers) { { "X-Api-Key" => key.token } }

  it "creates and submits an operation" do
    post "/api/v1/stake_operations",
         params: { network: "ethereum", action: "stake", amount: "1000" },
         headers: headers,
         as: :json

    expect(response).to have_http_status(:created)
    expect(response.parsed_body["data"]).to include(
      "network" => "ethereum",
      "action" => "stake",
      "amount" => "1000",
      "status" => "submitted"
    )
    expect(response.parsed_body.dig("data", "external_id")).to start_with("mock-stake-")
  end

  it "returns 422 for invalid parameters" do
    post "/api/v1/stake_operations",
         params: { network: "ethereum", action: "delegate", amount: "1.5" },
         headers: headers,
         as: :json

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body["error"]).to eq("validation_failed")
  end

  it "lists only the authenticated organization's operations" do
    StakeOperation.create!(organization: org, network: ethereum, action: "unstake", amount: "5", status: "pending")
    other = Organization.create!(name: "Other Org")
    StakeOperation.create!(organization: other, network: ethereum, action: "stake", amount: "9", status: "pending")

    get "/api/v1/stake_operations", headers: headers

    expect(response.parsed_body["data"].length).to eq(1)
    expect(response.parsed_body.dig("data", 0, "amount")).to eq("5")
  end
end
