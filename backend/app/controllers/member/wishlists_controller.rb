# frozen_string_literal: true

module Member
  # Hotwire owner wishlist CRUD + privacy/share/rotate (API parity O2B).
  # Traceability: [REQ-WISH-001], [REQ-WISH-002], [REQ-WISH-006], [REQ-LIFE-001]
  class WishlistsController < BaseController
    rate_limit to: 20, within: 3.minutes,
               only: %i[create update destroy rotate_share_token],
               name: "member_wishlists_write",
               by: -> { current_user&.id || request.remote_ip },
               with: -> {
                 redirect_back fallback_location: member_wishlists_path,
                               alert: I18n.t("api.v1.errors.rate_limited"),
                               status: :see_other
               }

    MAX_INDEX = 100

    def index
      authorize Wishlist, :index?
      @wishlists = policy_scope(Wishlist).where(owner_id: current_user.id)
                                        .order(created_at: :desc)
                                        .limit(MAX_INDEX)
    end

    def show
      @wishlist = policy_scope(Wishlist).find(params[:id])
      authorize @wishlist, :show?
      @shares = if @wishlist.owner_id == current_user.id
        @wishlist.wishlist_shares.includes(:user).limit(50)
      else
        []
      end
      @items = @wishlist.items.kept.order(:position, :id).limit(200)
      item_ids = @items.map(&:id)
      @holds_by_item_id = Item.active_holds_by_item_id(item_ids)
      @open_gifts_by_item_id = Item.open_gifts_by_item_id(item_ids)
      @received_gift_ids = Item.received_gift_item_ids_for(@wishlist.id)
    end

    def new
      authorize Wishlist, :create?
      @wishlist = current_user.wishlists.new(privacy_mode: "friends")
    end

    def create
      authorize Wishlist, :create?
      @wishlist = current_user.wishlists.create!(wishlist_create_params.merge(privacy_mode: "friends"))
      raise "Post-condition failed: default friends mode" unless @wishlist.privacy_mode == "friends"

      redirect_to member_wishlist_path(@wishlist), notice: I18n.t("member.wishlists.created"), status: :see_other
    rescue ActiveRecord::RecordInvalid
      @wishlist = current_user.wishlists.new(wishlist_create_params.merge(privacy_mode: "friends"))
      flash.now[:alert] = I18n.t("api.v1.errors.wishlist_invalid")
      render :new, status: :unprocessable_content
    end

    def edit
      @wishlist = current_user.wishlists.kept.find(params[:id])
      authorize @wishlist, :update?
    end

    def update
      @wishlist = current_user.wishlists.kept.find(params[:id])
      authorize @wishlist, :update?
      apply_updates!(@wishlist)
      redirect_to member_wishlist_path(@wishlist), notice: I18n.t("member.wishlists.updated"), status: :see_other
    rescue ArgumentError, ActiveRecord::RecordInvalid
      flash.now[:alert] = I18n.t("api.v1.errors.wishlist_invalid")
      render :edit, status: :unprocessable_content
    end

    def destroy
      @wishlist = current_user.wishlists.kept.find(params[:id])
      authorize @wishlist, :destroy?
      @wishlist.soft_delete!(actor: current_user)
      redirect_to member_wishlists_path, notice: I18n.t("member.wishlists.deleted"), status: :see_other
    end

    def rotate_share_token
      @wishlist = current_user.wishlists.kept.find(params[:id])
      authorize @wishlist, :rotate_share_token?
      WishlistPrivacyService.rotate_token!(wishlist: @wishlist)
      redirect_to member_wishlist_path(@wishlist), notice: I18n.t("member.wishlists.token_rotated"), status: :see_other
    rescue ArgumentError
      redirect_to member_wishlist_path(@wishlist), alert: I18n.t("api.v1.errors.wishlist_invalid"), status: :see_other
    end

    private

    def wishlist_create_params
      params.require(:wishlist).permit(:title, :event_date, :max_reservations_per_user)
    end

    def apply_updates!(wishlist)
      attrs = params.require(:wishlist).permit(:title, :event_date, :max_reservations_per_user, :privacy_mode)
      wishlist.transaction do
        if attrs.key?(:privacy_mode) && attrs[:privacy_mode].present?
          WishlistPrivacyService.change_mode!(wishlist: wishlist, mode: attrs[:privacy_mode])
        end
        wishlist.update!(attrs.except(:privacy_mode))
      end
    end
  end
end
