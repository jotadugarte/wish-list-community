# frozen_string_literal: true

module Api
  module V1
    # Lists the current user's active and grace reservations.
    # Traceability: [REQ-RES-004]
    class MyReservationsController < BaseController
      # [REQ-RES-004] [REQ-GIFT-001] Index of active/grace holds + open gifts for the user.
      def index
        authorize Reservation, :index?
        reservations = policy_scope(Reservation).includes(item: :wishlist).order(updated_at: :desc).limit(200)
        open_gifts = GiftRecordPolicy::Scope.new(current_user, GiftRecord)
                                            .resolve
                                            .includes(item: :wishlist)
                                            .where(status: GiftStatus::OPEN)
                                            .order(updated_at: :desc)
                                            .limit(200)

        render json: {
          reservations: reservations.map { |r|
            r.as_api_json.merge(item_title: r.item.title, wishlist_title: r.item.wishlist.title)
          },
          open_gifts: open_gifts.map { |g|
            g.as_api_json(viewer: current_user)
             .merge(item_title: g.item.title, wishlist_title: g.item.wishlist.title)
          }
        }, status: :ok
      end
    end
  end
end

