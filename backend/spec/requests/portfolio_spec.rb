# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Portfolio API", type: :request do
  let!(:org) { Organization.create!(name: "Test Org") }
  let!(:key) { ApiKey.create!(organization: org, token: "test-key") }
  let!(:ethereum) { Network.create!(slug: "ethereum", display_name: "Ethereum") }

  it "rejects missing api key" do
    get "/api/v1/portfolio"
    expect(response).to have_http_status(:unauthorized)
  end

  it "rejects an invalid api key" do
    get "/api/v1/portfolio", headers: { "X-Api-Key" => "not-a-real-key" }
    expect(response).to have_http_status(:unauthorized)
  end

  it "returns aggregated portfolio for the authenticated organization" do
    Validator.create!(organization: org, network: ethereum, external_ref: "one", balance: "20")
    Validator.create!(organization: org, network: ethereum, external_ref: "two", balance: "22")
    RewardEvent.create!(organization: org, network: ethereum, reward_date: Date.new(2024, 1, 1), amount: "3", external_id: "reward-1")
    RewardEvent.create!(organization: org, network: ethereum, reward_date: Date.new(2024, 1, 2), amount: "4", external_id: "reward-2")
    finished_at = Time.zone.parse("2024-01-03 12:00:00")
    SyncRun.create!(organization: org, kind: "rewards", status: "completed", finished_at: finished_at)

    get "/api/v1/portfolio", headers: { "X-Api-Key" => key.token }

    expect(response).to have_http_status(:ok)
    body = response.parsed_body
    expect(body["data"].first).to include(
      "protocol" => "ethereum",
      "balance" => "42",
      "total_rewards_received" => "7"
    )
    expect(body["last_synced_at"]).to eq(finished_at.iso8601)
  end
end
