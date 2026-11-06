# frozen_string_literal: true

module Api
  module V1
    class RewardsController < ApplicationController
      def index
        rewards = current_organization.reward_events.includes(:network)
        rewards = rewards.where(network: Network.find_by(slug: params[:network])) if params[:network].present?
        rewards = rewards.where("reward_date >= ?", Date.iso8601(params[:start])) if params[:start].present?
        rewards = rewards.where("reward_date <= ?", Date.iso8601(params[:end])) if params[:end].present?

        rows = rewards.to_a
          .group_by { |reward| [reward.network.slug, reward.reward_date] }
          .map do |(network, date), events|
            {
              network: network,
              date: date.iso8601,
              amount: events.sum { |event| Integer(event.amount, 10) }.to_s
            }
          end
          .sort_by { |row| [row[:date], row[:network]] }

        render json: { data: rows }
      rescue Date::Error
        render json: { error: "invalid_date", details: "start and end must use YYYY-MM-DD" }, status: :unprocessable_entity
      end
    end
  end
end
