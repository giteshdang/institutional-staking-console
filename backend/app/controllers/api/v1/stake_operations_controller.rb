# frozen_string_literal: true

module Api
  module V1
    class StakeOperationsController < ApplicationController
      def index
        ops = current_organization.stake_operations.order(created_at: :desc).limit(100)
        render json: {
          data: ops.map { |op| serialize(op) }
        }
      end

      def create
        payload = request.request_parameters
        network = Network.find_by(slug: payload["network"])
        return render json: { error: "unknown_network" }, status: :unprocessable_entity unless network

        op = current_organization.stake_operations.new(
          network: network,
          action: payload["action"],
          amount: payload["amount"].to_s,
          status: "pending"
        )

        unless op.valid?
          return render json: { error: "validation_failed", details: op.errors.full_messages }, status: :unprocessable_entity
        end

        op.save!
        result = ChainClients::MockChainClient.new.submit_stake(op)
        op.update!(external_id: result.fetch(:external_id), status: result.fetch(:status))

        render json: { data: serialize(op) }, status: :created
      rescue StandardError => e
        if defined?(op) && op&.persisted?
          op.update_columns(status: "failed", error_message: e.message, updated_at: Time.current)
        end
        raise
      end

      private

      def serialize(op)
        {
          id: op.id,
          network: op.network.slug,
          action: op.action,
          amount: op.amount,
          status: op.status,
          external_id: op.external_id,
          error_message: op.error_message,
          created_at: op.created_at.iso8601
        }
      end
    end
  end
end
