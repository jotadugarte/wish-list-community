# frozen_string_literal: true

module Admin
  # Web-only Admin panel base: cookie session + role=admin + Pundit default-deny.
  # Non-admins receive 404 (no panel existence leak). Traceability: [REQ-ADM-001]
  class BaseController < ApplicationController
    include WebAuthentication
    include Pundit::Authorization

    DOMAIN_ERROR_KEYS = {
      "Pre-condition failed: event is not revertable" => "admin.errors.event_not_revertable",
      "Pre-condition failed: record is not soft-deleted" => "admin.errors.not_soft_deleted",
      "Pre-condition failed: restoration window expired" => "admin.errors.restoration_window_expired",
      "Pre-condition failed: restore denied" => "admin.errors.restore_denied",
      "Pre-condition failed: report must be pending" => "admin.errors.report_must_be_pending",
      "Pre-condition failed: report must be dismissed" => "admin.errors.report_must_be_dismissed",
      "Pre-condition failed: actor must be an admin" => "admin.errors.actor_must_be_admin",
      "Pre-condition failed: cannot suspend yourself" => "admin.errors.cannot_suspend_yourself",
      "Pre-condition failed: cannot enforce against yourself" => "admin.errors.cannot_enforce_against_yourself",
      "Pre-condition failed: cannot suspend the last remaining admin" => "admin.errors.cannot_suspend_last_admin",
      "Pre-condition failed: cannot soft-delete the last remaining admin" => "admin.errors.cannot_soft_delete_last_admin",
      "Pre-condition failed: user must be suspended" => "admin.errors.user_must_be_suspended",
      "Pre-condition failed: target_user must match reportable" => "admin.errors.target_must_match_reportable",
      "Pre-condition failed: wishlist must match reportable" => "admin.errors.wishlist_must_match_reportable",
      "Pre-condition failed: record is already soft-deleted" => "admin.errors.already_soft_deleted",
      "Pre-condition failed: unsupported reportable" => "admin.errors.unsupported_reportable",
      "Pre-condition failed: reportable must be Wishlist" => "admin.errors.reportable_must_be_wishlist"
    }.freeze

    layout "admin"

    before_action :require_admin!
    after_action :verify_authorized

    rescue_from Pundit::NotAuthorizedError, with: :hide_admin_panel
    rescue_from ActiveRecord::RecordNotFound, with: :hide_admin_panel
    rescue_from ArgumentError, with: :handle_domain_error
    rescue_from ActiveRecord::RecordInvalid, with: :handle_domain_error
    rescue_from ActiveRecord::RecordNotUnique, with: :handle_domain_error

    private

    def require_admin!
      raise Pundit::NotAuthorizedError unless current_user&.role == "admin"
    end

    def hide_admin_panel
      skip_authorization
      head :not_found
    end

    def handle_domain_error(error)
      skip_authorization
      redirect_back fallback_location: admin_root_path, alert: localize_domain_error(error), status: :see_other
    end

    def localize_domain_error(error)
      if error.respond_to?(:record) && error.record&.errors&.full_messages&.any?
        return error.record.errors.full_messages.to_sentence
      end

      key = DOMAIN_ERROR_KEYS[error.message]
      return I18n.t(key) if key

      I18n.t("admin.errors.domain_generic", message: error.message)
    end

    def rate_limit_admin_write
      redirect_back fallback_location: admin_root_path,
                    alert: I18n.t("api.v1.errors.rate_limited"),
                    status: :see_other
    end
  end
end
