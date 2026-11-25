# frozen_string_literal: true

module Api
  module V1
    # Handles user and wishlist abuse report submissions for the moderation queue.
    # Traceability: [REQ-SOC-001], [REQ-DISC-001], [REQ-ADM-001]
    class ReportsController < BaseController
      ALLOWED_REPORTABLE_TYPES = {
        "User" => User
      }.freeze

      # [REQ-SOC-001] [REQ-DISC-001] [REQ-ADM-001] Submits a polymorphic abuse report.
      def create
        target = resolve_reportable!(params[:reportable_type], params[:reportable_id])
        candidate = Report.new(reporter: current_user, reportable: target)
        authorize candidate, :create?

        report = Report.submit!(
          reporter: current_user,
          reportable: target,
          reason: params[:reason],
          details: params[:details]
        )

        render json: { report: report.as_api_json }, status: :created
      rescue ArgumentError, ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :unprocessable_content
      end

      private

      def resolve_reportable!(raw_type, raw_id)
        klass = ALLOWED_REPORTABLE_TYPES[raw_type.to_s]
        raise ArgumentError, "Unsupported reportable_type" if klass.nil?

        klass.find(raw_id)
      end
    end
  end
end
