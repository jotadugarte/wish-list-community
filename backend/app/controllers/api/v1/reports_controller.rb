# frozen_string_literal: true

module Api
  module V1
    # Handles user and wishlist abuse report submissions for the moderation queue.
    # Traceability: [REQ-SOC-001], [REQ-DISC-001], [REQ-ADM-001]
    class ReportsController < BaseController
      skip_after_action :verify_policy_scoped
      rate_limit to: 20, within: 3.minutes, only: :create, with: -> {
        render json: { error: I18n.t("api.v1.errors.rate_limited") }, status: :too_many_requests
      }

      ALLOWED_REPORTABLE_TYPES = {
        "User" => User,
        "Wishlist" => Wishlist
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
      rescue ArgumentError, ActiveRecord::RecordInvalid
        skip_authorization
        render json: { error: I18n.t("api.v1.errors.report_invalid") }, status: :unprocessable_content
      end

      private

      def resolve_reportable!(raw_type, raw_id)
        klass = ALLOWED_REPORTABLE_TYPES[raw_type.to_s]
        raise ArgumentError, "Unsupported reportable_type" if klass.nil?

        return klass.kept.find(raw_id) if klass == Wishlist

        klass.find(raw_id)
      end
    end
  end
end
