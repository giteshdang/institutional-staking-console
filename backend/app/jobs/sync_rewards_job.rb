# frozen_string_literal: true

class SyncRewardsJob < ApplicationJob
  queue_as :default

  def perform(organization_id, from: Date.today - 7, to: Date.today)
    organization = Organization.find(organization_id)
    client = ChainClients::MockChainClient.new
    sync_run = organization.sync_runs.create!(kind: "rewards", status: "running")

    rows = client.fetch_rewards(organization, from: from, to: to)
    now = Time.current
    records = rows.map do |row|
      network = Network.find_by!(slug: row.fetch(:network))
      {
        organization_id: organization.id,
        network_id: network.id,
        validator_ref: row[:validator_ref],
        reward_date: row.fetch(:date),
        amount: row.fetch(:amount).to_s,
        external_id: row.fetch(:external_id),
        created_at: now,
        updated_at: now
      }
    end

    RewardEvent.upsert_all(records, unique_by: :index_reward_events_on_external_id) if records.any?
    sync_run.update!(status: "completed", finished_at: Time.current)
  rescue StandardError
    sync_run&.update_columns(status: "failed", finished_at: Time.current, updated_at: Time.current)
    raise
  end
end
