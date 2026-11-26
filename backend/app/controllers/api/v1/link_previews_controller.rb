# frozen_string_literal: true

module Api
  module V1
    # Synchronous OpenGraph preview for store URLs (confirm before persist — O3A).
    # Traceability: [REQ-ITEM-006]
    class LinkPreviewsController < BaseController
      skip_after_action :verify_policy_scoped
      rate_limit to: 30, within: 3.minutes, only: :create, with: -> {
        render json: { error: I18n.t("api.v1.errors.unauthorized") }, status: :too_many_requests
      }

      # [REQ-ITEM-006] POST /api/v1/link_previews { url } → preview fields (best-effort).
      def create
        authorize :link_preview, :create?
        url = params.require(:url)
        preview = OpenGraphPreview.fetch(url)
        render json: preview, status: :ok
      rescue ArgumentError, ActionController::ParameterMissing
        render json: { errors: [ "Invalid url" ] }, status: :unprocessable_content
      end
    end
  end
end
