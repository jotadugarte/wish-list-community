# frozen_string_literal: true

module Member
  # Hotwire item create on activity-scoped wishlists (board-only; FC1A).
  # Traceability: [REQ-ACT-005], [REQ-ITEM-001], [REQ-ARCH-001]
  class ActivityItemsController < BaseController
    skip_after_action :verify_policy_scoped
    rate_limit to: 20, within: 3.minutes, only: %i[create],
               name: "member_activity_items_write",
               by: -> { current_user&.id || request.remote_ip },
               with: -> {
                 redirect_back fallback_location: member_activities_path,
                               alert: I18n.t("api.v1.errors.rate_limited"),
                               status: :see_other
               }

    # [REQ-ACT-005] Owner adds an item with price/currency on the activity board.
    def create
      activity, wishlist = find_activity_wishlist!
      authorize activity, :show?
      raise Pundit::NotAuthorizedError unless wishlist.owner_id == current_user.id

      wishlist.items.create!(item_attrs)
      redirect_to member_activity_path(activity),
                  notice: I18n.t("member.items.created"),
                  status: :see_other
    rescue ArgumentError, ActiveRecord::RecordInvalid => e
      skip_authorization unless @_pundit_policy_authorized
      redirect_to member_activity_path(params[:activity_id]),
                  alert: budget_or_item_error(e),
                  status: :see_other
    end

    private

    def find_activity_wishlist!
      activity = Activity.find(params[:activity_id])
      wishlist = Wishlist.kept.find_by!(id: params[:wishlist_id], activity_id: activity.id)
      [ activity, wishlist ]
    end

    def item_attrs
      permitted = params.fetch(:item, ActionController::Parameters.new).permit(
        :title, :specifications, :priority, :price_cents, :currency
      )
      attrs = {}
      permitted.each do |key, value|
        name = key.to_s
        if %w[specifications price_cents currency].include?(name)
          attrs[name] = blank_to_nil_field(name, value)
        elsif value.present?
          attrs[name] = value
        end
      end
      attrs
    end

    def blank_to_nil_field(name, value)
      return nil if value.nil? || value == ""
      return Integer(value) if name == "price_cents"

      value
    end

    def budget_or_item_error(error)
      if error.is_a?(ActiveRecord::RecordInvalid) && error.record&.errors&.any?
        return error.record.errors.full_messages.join(", ")
      end

      error.message.presence || I18n.t("member.items.invalid")
    end
  end
end
