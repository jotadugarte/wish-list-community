# frozen_string_literal: true

module Admin
  # Web-only Admin panel base: cookie session + role=admin + Pundit default-deny.
  # Non-admins receive 404 (no panel existence leak). Traceability: [REQ-ADM-001]
  class BaseController < ApplicationController
    include WebAuthentication
    include Pundit::Authorization

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
      message = if error.respond_to?(:record) && error.record&.errors&.full_messages&.any?
        error.record.errors.full_messages.to_sentence
      else
        error.message
      end
      redirect_back fallback_location: admin_root_path, alert: message, status: :see_other
    end

    def rate_limit_admin_write
      redirect_back fallback_location: admin_root_path,
                    alert: I18n.t("api.v1.errors.rate_limited"),
                    status: :see_other
    end
  end
end
