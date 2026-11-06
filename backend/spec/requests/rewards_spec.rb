# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Rewards API", type: :request do
  let!(:org) { Organization.create!(name: "Test Org") }
  let!(:key) { ApiKey.create!(organization: org, token: "test-key") }
  let!(:ethereum) { Network.create!(slug: "ethereum", display_name: "Ethereum") }
  let!(:solana) { Network.create!(slug: "solana", display_name: "Solana") }

  before do
    RewardEvent.create!(organization: org, network: ethereum, reward_date: Date.new(2024, 1, 1), amount: "10", external_id: "eth-1")
    RewardEvent.create!(organization: org, network: ethereum, reward_date: Date.new(2024, 1, 1), amount: "15", external_id: "eth-2")
    RewardEvent.create!(organization: org, network: solana, reward_date: Date.new(2024, 1, 2), amount: "7", external_id: "sol-1")
  end

  it "returns daily rollups as string amounts" do
    get "/api/v1/rewards", headers: { "X-Api-Key" => key.token }

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["data"]).to eq([
      { "network" => "ethereum", "date" => "2024-01-01", "amount" => "25" },
      { "network" => "solana", "date" => "2024-01-02", "amount" => "7" }
    ])
  end

  it "filters by network and date range" do
    get "/api/v1/rewards",
        params: { network: "solana", start: "2024-01-02", end: "2024-01-02" },
        headers: { "X-Api-Key" => key.token }

    expect(response.parsed_body["data"]).to eq([
      { "network" => "solana", "date" => "2024-01-02", "amount" => "7" }
    ])
  end
end
