# frozen_string_literal: true

module Api
  module V1
    class PortfolioController < ApplicationController
      def show
        validators = current_organization.validators.includes(:network).to_a
        rewards = current_organization.reward_events.includes(:network).to_a
        networks = (validators.map(&:network) + rewards.map(&:network)).uniq(&:id).sort_by(&:slug)

        data = networks.map do |network|
          network_validators = validators.select { |validator| validator.network_id == network.id }
          network_rewards = rewards.select { |reward| reward.network_id == network.id }

          {
            protocol: network.slug,
            balance: sum_amounts(network_validators.map(&:balance)),
            total_rewards_received: sum_amounts(network_rewards.map(&:amount)),
            updated_at: network_validators.map(&:updated_at).compact.max&.iso8601,
            started_at: network_validators.map(&:created_at).compact.min&.iso8601
          }
        end

        last_sync = current_organization.sync_runs.where(kind: "rewards", status: "completed").maximum(:finished_at)
        render json: { data: data, last_synced_at: last_sync&.iso8601 }
      end

      private

      def sum_amounts(amounts)
        amounts.sum { |amount| Integer(amount, 10) }.to_s
      end
    end
  end
end
