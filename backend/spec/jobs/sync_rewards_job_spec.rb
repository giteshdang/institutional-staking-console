# frozen_string_literal: true

require "rails_helper"

RSpec.describe SyncRewardsJob, type: :job do
  let!(:org) { Organization.create!(name: "Test Org") }
  let!(:ethereum) { Network.create!(slug: "ethereum", display_name: "Ethereum") }
  let!(:solana) { Network.create!(slug: "solana", display_name: "Solana") }

  before do
    Validator.create!(organization: org, network: ethereum, external_ref: "eth-validator", balance: "32")
    Validator.create!(organization: org, network: solana, external_ref: "sol-validator", balance: "100")
  end

  it "upserts reward events idempotently" do
    range = { from: Date.new(2024, 1, 1), to: Date.new(2024, 1, 2) }

    described_class.perform_now(org.id, **range)
    expect { described_class.perform_now(org.id, **range) }.not_to change(RewardEvent, :count)

    expect(RewardEvent.count).to eq(4)
    expect(org.sync_runs.where(status: "completed").count).to eq(2)
  end
end
