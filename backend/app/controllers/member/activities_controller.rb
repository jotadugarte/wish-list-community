# frozen_string_literal: true

module Member
  # Hotwire activity board + create (Sprint A shell; personal wishlist bridges).
  # Traceability: [REQ-ACT-001], [REQ-WISH-001], [REQ-ARCH-001]
  class ActivitiesController < BaseController
    skip_after_action :verify_policy_scoped
    MAX_BRIDGES = 50

    def index
      authorize Activity, :index?
      @activities = policy_scope(Activity).order(created_at: :desc).limit(100)
    end

    def new
      authorize Activity, :create?
      @activity = Activity.new(
        assignment_mode: "secret_santa",
        visibility_mode: "recipient_only",
        reservation_visibility: "hidden_from_recipient",
        budget_mode: "none",
        currency: "CRC"
      )
    end

    def create
      authorize Activity, :create?
      @activity = Activity.create!(activity_params.merge(creator: current_user))
      redirect_to member_activity_path(@activity), status: :see_other
    rescue ActiveRecord::RecordInvalid
      @activity = Activity.new(activity_params)
      flash.now[:alert] = I18n.t("activities.errors.invalid")
      render :new, status: :unprocessable_content
    end

    def show
      @activity = Activity.find(params[:id])
      authorize @activity, :show?
      @participants = @activity.participants.includes(:user).where(status: %w[invited accepted]).limit(200)
      @my_assignment = ActivityDrawService.assignment_for(activity: @activity, viewer: current_user)
      @wishlist_bridges = personal_wishlist_bridges
      @viewer_status = @activity.participants.find_by(user_id: current_user.id)&.status
      @viewer_status = "accepted" if current_user.id == @activity.creator_id && @viewer_status.nil?
      load_activity_lists!
    end

    # [REQ-ACT-001] Accept a pending invite from the Activity Link surface.
    def accept
      @activity = Activity.find(params[:id])
      authorize @activity, :join?
      participant = @activity.participants.find_by!(user: current_user, status: "invited")
      participant.accept!
      redirect_to member_activity_path(@activity), status: :see_other
    rescue ActiveRecord::RecordNotFound, ArgumentError
      redirect_to member_activities_path,
                  alert: I18n.t("activities.errors.invite_unavailable"),
                  status: :see_other
    end

    # [REQ-ACT-001] Decline a pending invite.
    def decline
      @activity = Activity.find(params[:id])
      authorize @activity, :join?
      participant = @activity.participants.find_by!(user: current_user, status: "invited")
      participant.decline!
      redirect_to member_activities_path, status: :see_other
    rescue ActiveRecord::RecordNotFound, ArgumentError
      redirect_to member_activities_path,
                  alert: I18n.t("activities.errors.invite_unavailable"),
                  status: :see_other
    end

    private

    def activity_params
      params.require(:activity).permit(
        :name, :currency, :assignment_mode, :visibility_mode, :reservation_visibility,
        :budget_mode, :budget_amount_cents, :budget_max_cents, :starts_on, :ends_on
      )
    end

    # [REQ-WISH-001] Bridge to personal wishlists of accepted participants the viewer may see.
    def personal_wishlist_bridges
      user_ids = @activity.participants.where(status: "accepted").limit(MAX_BRIDGES).pluck(:user_id)
      user_ids -= [ current_user.id ]
      return [] if user_ids.empty?

      Wishlist.kept.personal.where(owner_id: user_ids).includes(:owner).limit(MAX_BRIDGES).select do |wishlist|
        WishlistPolicy.new(current_user, wishlist).show?
      end
    end

    # [REQ-ACT-001] [REQ-ACT-005] Activity-scoped lists/items for the board (FC1A — not My Wishlists).
    def load_activity_lists!
      lists = Wishlist.kept.activity_scoped
                      .where(activity_id: @activity.id)
                      .includes(:owner)
                      .limit(MAX_BRIDGES)
                      .select { |w| ActivityVisibilityGate.can_view_list?(viewer: current_user, owner_wishlist: w) }
      @activity_wishlists = lists.first(MAX_BRIDGES)
      item_ids = []
      @activity_items_by_wishlist_id = {}
      @activity_wishlists.each do |wishlist|
        items = wishlist.items.kept.order(:position, :id).limit(200).to_a
        @activity_items_by_wishlist_id[wishlist.id] = items
        item_ids.concat(items.map(&:id))
      end
      item_ids = item_ids.first(500)
      @holds_by_item_id = Item.active_holds_by_item_id(item_ids)
      @open_gifts_by_item_id = Item.open_gifts_by_item_id(item_ids)
      @my_holds_by_item_id = Reservation.where(user_id: current_user.id, item_id: item_ids)
                                       .where(status: ReservationStatus::ACTIVE_HOLD)
                                       .index_by(&:item_id)
      @my_open_gifts_by_item_id = GiftRecord.where(gifter_id: current_user.id, item_id: item_ids)
                                           .where(status: GiftStatus::OPEN)
                                           .index_by(&:item_id)
      @received_gift_ids_by_wishlist = {}
      @activity_wishlists.each do |wishlist|
        @received_gift_ids_by_wishlist[wishlist.id] = Item.received_gift_item_ids_for(wishlist.id)
      end
    end
  end
end
