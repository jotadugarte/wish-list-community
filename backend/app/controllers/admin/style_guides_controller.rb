# frozen_string_literal: true

module Admin
  # Admin-only Hotwire brand guide. Non-admins stay on the BaseController 404 gate.
  # Traceability: [REQ-ADM-001], [REQ-ARCH-001]
  class StyleGuidesController < BaseController
    # [REQ-ADM-001] Shows the brand guide to a role=admin cookie session.
    def show
      authorize :admin, :show?, policy_class: AdminPolicy
    end
  end
end
