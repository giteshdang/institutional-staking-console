# frozen_string_literal: true

module Api
  module V1
    class SyncController < ApplicationController
      def rewards
        from = params[:start].present? ? Date.iso8601(params[:start]) : Date.current - 7
        to = params[:end].present? ? Date.iso8601(params[:end]) : Date.current
        return render json: { error: "invalid_date_range" }, status: :unprocessable_entity if from > to

        job = SyncRewardsJob.perform_later(current_organization.id, from: from, to: to)
        render json: { data: { job_id: job.job_id, status: "queued" } }, status: :accepted
      rescue Date::Error
        render json: { error: "invalid_date", details: "start and end must use YYYY-MM-DD" }, status: :unprocessable_entity
      end
    end
  end
end
