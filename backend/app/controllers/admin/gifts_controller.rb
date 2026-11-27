# frozen_string_literal: true

module Admin
  # Read-only Hotwire gift detail with gifter identity + purchase_link_ref (O5A).
  # Traceability: [REQ-ADM-001], [REQ-GIFT-001]
  class GiftsController < BaseController
    # [REQ-ADM-001] Shows admin-only gifter username/email and purchase_link_ref.
    def show
      @gift = GiftRecord.includes(:gifter, item: { wishlist: :owner }).find(params[:id])
      authorize :admin, :show?, policy_class: AdminPolicy
    end
  end
end
