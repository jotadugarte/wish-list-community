# frozen_string_literal: true

module Api
  module V1
    # Item CRUD on activity-scoped wishlists (budget/currency via Item validations).
    # Traceability: [REQ-ACT-005], [REQ-ITEM-001], [REQ-ARCH-001], [REQ-LIFE-001]
    class ActivityItemsController < BaseController
      skip_after_action :verify_policy_scoped
      rate_limit to: 20, within: 3.minutes, only: %i[create update destroy], name: "api_activity_items_write",
                 by: -> { current_user&.id || request.remote_ip }, with: -> {
        render json: { error: I18n.t("api.v1.errors.rate_limited") }, status: :too_many_requests
      }
      MAX_INDEX = 200

      # [REQ-ACT-005] Lists kept items on a visible activity wishlist.
      def index
        activity, wishlist = find_activity_wishlist!
        authorize activity, :show?
        unless ActivityVisibilityGate.can_view_list?(viewer: current_user, owner_wishlist: wishlist)
          raise Pundit::NotAuthorizedError
        end

        items = wishlist.items.kept.order(:position, :id).limit(MAX_INDEX)
        render json: { items: items.map { |i| i.as_api_json(viewer: current_user) } }, status: :ok
      end

      # [REQ-ACT-005] Owner creates an item on their activity wishlist.
      def create
        activity, wishlist = find_activity_wishlist!
        authorize activity, :show?
        raise Pundit::NotAuthorizedError unless wishlist.owner_id == current_user.id

        item = wishlist.items.create!(item_attrs)
        render json: { item: item.as_api_json(viewer: current_user) }, status: :created
      rescue ArgumentError, ActiveRecord::RecordInvalid => e
        skip_authorization unless @_pundit_policy_authorized
        render json: { errors: record_errors(e) }, status: :unprocessable_content
      end

      # [REQ-ACT-005] Owner updates an activity item.
      def update
        activity, item = find_activity_item!
        authorize activity, :show?
        raise Pundit::NotAuthorizedError unless item.wishlist.owner_id == current_user.id

        critical_before = [ item.title, item.specifications ]
        item.update!(item_attrs)
        if critical_before != [ item.title, item.specifications ]
          Reservation.notify_critical_edit!(item: item)
        end
        render json: { item: item.reload.as_api_json(viewer: current_user) }, status: :ok
      rescue ArgumentError, ActiveRecord::RecordInvalid => e
        render json: { errors: record_errors(e) }, status: :unprocessable_content
      end

      # [REQ-LIFE-001] Owner soft-deletes an activity item.
      def destroy
        activity, item = find_activity_item!
        authorize activity, :show?
        raise Pundit::NotAuthorizedError unless item.wishlist.owner_id == current_user.id

        item.soft_delete!(actor: current_user)
        head :no_content
      end

      private

      def find_activity!
        Activity.find(params[:activity_id])
      end

      def find_activity_wishlist!
        activity = find_activity!
        wishlist = Wishlist.kept.find_by!(id: params[:wishlist_id], activity_id: activity.id)
        [ activity, wishlist ]
      end

      def find_activity_item!
        activity = find_activity!
        item = Item.kept.find(params[:id])
        raise ActiveRecord::RecordNotFound unless item.wishlist.activity_id == activity.id

        [ activity, item ]
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

      def record_errors(error)
        if error.is_a?(ActiveRecord::RecordInvalid) && error.record.present?
          msgs = error.record.errors.full_messages
          return msgs if msgs.any?
        end

        [ error.message.presence || I18n.t("api.v1.errors.unprocessable") ]
      end
    end
  end
end
