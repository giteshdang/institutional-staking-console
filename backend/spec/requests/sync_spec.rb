# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Rewards sync API", type: :request do
  include ActiveJob::TestHelper

  let!(:org) { Organization.create!(name: "Test Org") }
  let!(:key) { ApiKey.create!(organization: org, token: "test-key") }

  it "enqueues a sync for the authenticated organization" do
    expect do
      post "/api/v1/sync/rewards",
           params: { start: "2024-01-01", end: "2024-01-02" },
           headers: { "X-Api-Key" => key.token },
           as: :json
    end.to have_enqueued_job(SyncRewardsJob).with(org.id, from: Date.new(2024, 1, 1), to: Date.new(2024, 1, 2))

    expect(response).to have_http_status(:accepted)
  end
end
