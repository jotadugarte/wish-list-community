# frozen_string_literal: true

module Member
  # Hotwire item CRUD + multipart images (server libvips still mandatory).
  # Traceability: [REQ-ITEM-001], [REQ-ITEM-002] O5A
  class ItemsController < BaseController
    rate_limit to: 20, within: 3.minutes, only: %i[create update destroy],
               name: "member_items_write",
               by: -> { current_user&.id || request.remote_ip },
               with: -> {
                 redirect_back fallback_location: member_wishlists_path,
                               alert: I18n.t("api.v1.errors.rate_limited"),
                               status: :see_other
               }

    MAX_LINKS = 20

    def new
      @wishlist = find_personal_wishlist_kept!
      authorize @wishlist, :create?, policy_class: ItemPolicy
      @item = @wishlist.items.new
    end

    def create
      @wishlist = find_personal_wishlist_kept!
      authorize @wishlist, :create?, policy_class: ItemPolicy
      Item.transaction do
        @item = @wishlist.items.create!(item_attrs)
        replace_links!(@item)
        attach_uploaded_images!(@item)
      end
      redirect_to member_wishlist_path(@wishlist), notice: I18n.t("member.items.created"), status: :see_other
    rescue ArgumentError, ActiveRecord::RecordInvalid, ImageProcessing::Error, Vips::Error
      @item = @wishlist.items.new(item_attrs)
      flash.now[:alert] = I18n.t("member.items.invalid")
      render :new, status: :unprocessable_content
    end

    def edit
      @item = find_personal_item_kept!
      authorize @item, :update?
      @wishlist = @item.wishlist
    end

    def update
      @item = find_personal_item_kept!
      authorize @item, :update?
      @wishlist = @item.wishlist
      Item.transaction do
        @item.update!(item_attrs) if item_attrs.present?
        replace_links!(@item) if links_submitted?
        attach_uploaded_images!(@item)
      end
      redirect_to member_wishlist_path(@wishlist), notice: I18n.t("member.items.updated"), status: :see_other
    rescue ArgumentError, ActiveRecord::RecordInvalid, ImageProcessing::Error, Vips::Error
      flash.now[:alert] = I18n.t("member.items.invalid")
      render :edit, status: :unprocessable_content
    end

    def destroy
      @item = find_personal_item_kept!
      authorize @item, :destroy?
      wishlist = @item.wishlist
      @item.soft_delete!(actor: current_user)
      redirect_to member_wishlist_path(wishlist), notice: I18n.t("member.items.deleted"), status: :see_other
    end

    private

    # [REQ-ACT-001] FC1A: activity-scoped items stay on activity board routes.
    def find_personal_wishlist_kept!
      current_user.wishlists.personal.kept.find(params[:wishlist_id])
    end

    def find_personal_item_kept!
      item = Item.kept.find(params[:id])
      raise ActiveRecord::RecordNotFound if item.wishlist.activity_scoped?

      item
    end

    def item_attrs
      permitted = params.fetch(:item, ActionController::Parameters.new).permit(
        :title, :specifications, :priority, :price_cents, :currency
      )
      attrs = {}
      permitted.each do |key, value|
        attrs[key.to_s] = value if value.present?
      end
      attrs
    end

    def links_submitted?
      item_params = params[:item]
      return false if item_params.nil?

      item_params.key?(:links) || item_params.key?("links") ||
        item_params.key?(:links_text) || item_params.key?("links_text")
    end

    def replace_links!(item)
      links = submitted_link_urls.first(MAX_LINKS)
      item.item_links.destroy_all
      links.each_with_index do |url, index|
        next if url.blank?

        item.item_links.create!(url: url, position: index)
      end
    end

    def submitted_link_urls
      text = params.dig(:item, :links_text)
      if text.present?
        return text.to_s.split(/\r?\n/).map(&:strip).reject(&:blank?)
      end

      Array(params.dig(:item, :links)).map { |url| url.to_s.strip }.reject(&:blank?)
    end

    def attach_uploaded_images!(item)
      files = Array(params[:images]).first(Item::MAX_IMAGES)
      files.each do |file|
        next if file.blank?

        ItemImageProcessor.attach!(item: item, io: file.tempfile, filename: file.original_filename)
      end
    rescue ArgumentError
      raise
    rescue ImageProcessing::Error, Vips::Error
      raise ArgumentError, I18n.t("member.items.invalid")
    end
  end
end
