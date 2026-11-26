# frozen_string_literal: true

module Api
  module V1
    # Item CRUD under wishlists + member restore/image detach.
    # Traceability: [REQ-ITEM-001], [REQ-ITEM-002], [REQ-ITEM-003], [REQ-ITEM-005],
    # [REQ-ARCH-002], [REQ-LIFE-001]
    class ItemsController < BaseController
      skip_after_action :verify_policy_scoped
      MAX_INDEX = 200
      MAX_LINKS = 20

      # [REQ-ITEM-001] Lists kept items for a visible wishlist ordered by position.
      def index
        wishlist = find_wishlist_for_read!
        authorize wishlist, :index?, policy_class: ItemPolicy
        items = wishlist.items.kept.order(:position, :id).limit(MAX_INDEX).to_a
        holds = Item.active_holds_by_item_id(items.map(&:id))
        render json: {
          items: items.map { |i| i.as_api_json(viewer: current_user, holds_by_item_id: holds) }
        }, status: :ok
      end

      # [REQ-ITEM-001] Creates an item for the wishlist owner (O3A/O4A/O5A).
      def create
        wishlist = current_user.wishlists.kept.find(params[:wishlist_id])
        authorize wishlist, :create?, policy_class: ItemPolicy
        item = nil
        Item.transaction do
          item = build_item!(wishlist)
          apply_confirmed_preview!(item)
          attach_uploaded_images!(item)
        end
        render json: { item: item.reload.as_api_json(viewer: current_user) }, status: :created
      rescue ArgumentError, ActiveRecord::RecordInvalid, ImageProcessing::Error, Vips::Error => e
        skip_authorization unless @_pundit_policy_authorized
        render json: { errors: [ e.message.presence || "Invalid item" ] }, status: :unprocessable_content
      end

      # [REQ-ITEM-001] Shows a kept item when the parent wishlist is visible.
      def show
        item = Item.kept.find(params[:id])
        authorize item, :show?
        render json: { item: item.as_api_json(viewer: current_user) }, status: :ok
      end

      # [REQ-ITEM-001] Owner updates fields, links, and optional images.
      def update
        item = Item.kept.find(params[:id])
        authorize item, :update?
        Item.transaction do
          apply_item_updates!(item)
          apply_confirmed_preview!(item)
          attach_uploaded_images!(item)
        end
        render json: { item: item.reload.as_api_json(viewer: current_user) }, status: :ok
      rescue ArgumentError, ActiveRecord::RecordInvalid, ImageProcessing::Error, Vips::Error => e
        render json: { errors: [ e.message ] }, status: :unprocessable_content
      end

      # [REQ-LIFE-001] Soft-deletes an item.
      def destroy
        item = Item.kept.find(params[:id])
        authorize item, :destroy?
        item.soft_delete!(actor: current_user)
        head :no_content
      end

      # [REQ-LIFE-001] Restores a soft-deleted item.
      def restore
        item = Item.discarded.find(params[:id])
        authorize item, :restore?
        unless item.restore!(actor: current_user)
          return render json: { errors: [ "not restorable" ] }, status: :unprocessable_content
        end

        render json: { item: item.as_api_json(viewer: current_user) }, status: :ok
      end

      # [REQ-ITEM-002] Detaches one image attachment.
      def destroy_image
        item = Item.kept.find(params[:id])
        authorize item, :manage_images?
        attachment = item.images.attachments.find(params[:image_id])
        attachment.purge
        render json: { item: item.reload.as_api_json(viewer: current_user) }, status: :ok
      end

      # [REQ-ITEM-001] Reorders items for a wishlist (O8A).
      def reorder
        wishlist = current_user.wishlists.kept.find(params[:wishlist_id])
        authorize wishlist, :reorder?, policy_class: ItemPolicy
        ids = Array(params.require(:item_ids)).map(&:to_i).first(MAX_INDEX)
        reorder_items!(wishlist, ids)
        items = wishlist.items.kept.order(:position, :id).limit(MAX_INDEX)
        render json: { items: items.map { |i| i.as_api_json(viewer: current_user) } }, status: :ok
      rescue ArgumentError, ActiveRecord::RecordInvalid => e
        render json: { errors: [ e.message ] }, status: :unprocessable_content
      end

      private

      def find_wishlist_for_read!
        Wishlist.kept.find(params[:wishlist_id])
      end

      def build_item!(wishlist)
        item = wishlist.items.create!(item_attrs)
        replace_links!(item, links_params)
        item
      end

      def apply_item_updates!(item)
        critical_before = [ item.title, item.specifications, item.item_links.limit(50).pluck(:url) ]
        item.update!(item_attrs) if item_attrs.present?
        replace_links!(item, links_params) if params[:item]&.key?(:links)
        critical_after = [ item.title, item.specifications, item.item_links.limit(50).pluck(:url) ]
        if critical_before != critical_after
          Reservation
          Reservation.notify_critical_edit!(item: item)
        end
      end

      def item_attrs
        permitted = params.fetch(:item, ActionController::Parameters.new).permit(
          :title, :specifications, :priority, :price_cents, :currency
        )
        attrs = {}
        permitted.each do |key, value|
          name = key.to_s
          if %w[specifications price_cents currency].include?(name)
            attrs[name] = blank_to_nil_price_field(name, value)
          elsif value.present?
            attrs[name] = value
          end
        end
        preview_title = params.dig(:confirmed_preview, :title).presence || params.dig(:confirmed_preview, "title").presence
        attrs["title"] = preview_title if attrs["title"].blank? && preview_title.present?
        attrs
      end

      # Nullable pair fields (REQ-ARCH-002): blank/nil clears; keep explicit keys so PATCH can unset.
      def blank_to_nil_price_field(name, value)
        return nil if value.nil? || value == ""
        return Integer(value) if name == "price_cents"

        value
      end

      def links_params
        Array(params.dig(:item, :links)).first(MAX_LINKS)
      end

      def replace_links!(item, links)
        return if links.nil?

        item.item_links.destroy_all
        links.each_with_index do |link, index|
          url = link.is_a?(Hash) || link.is_a?(ActionController::Parameters) ? link[:url] || link["url"] : link
          next if url.blank?

          item.item_links.create!(url: url, position: index)
        end
      end

      def apply_confirmed_preview!(item)
        preview = params[:confirmed_preview]
        return if preview.blank?

        title = preview[:title].presence || preview["title"].presence
        item.update!(title: title) if title.present?

        image_url = preview[:image_url].presence || preview["image_url"].presence
        return if image_url.blank?

        attach_remote_preview_image!(item, image_url)
      end

      def attach_remote_preview_image!(item, image_url)
        bytes = OpenGraphPreview.download_bytes(image_url)
        return if bytes.blank?

        ItemImageProcessor.attach!(item: item, io: StringIO.new(bytes), filename: "preview.bin")
      rescue ArgumentError, ImageProcessing::Error, Vips::Error
        raise ArgumentError, "preview image could not be processed"
      end

      def attach_uploaded_images!(item)
        files = Array(params[:images]).first(Item::MAX_IMAGES)
        files.each do |file|
          next if file.blank?

          ItemImageProcessor.attach!(item: item, io: file.tempfile, filename: file.original_filename)
        end
      rescue ArgumentError
        raise
      rescue ImageProcessing::Error, Vips::Error => e
        raise ArgumentError, e.message.presence || "image could not be processed"
      end

      def reorder_items!(wishlist, ids)
        raise ArgumentError, "item_ids required" if ids.empty?

        all_kept_ids = wishlist.items.kept.order(:position, :id).pluck(:id)
        raise ArgumentError, "item_ids must include every kept item" unless ids.sort == all_kept_ids.sort
        raise ArgumentError, "item_ids must belong to wishlist" unless ids.uniq.size == ids.size

        Item.transaction do
          ids.each_with_index do |id, index|
            wishlist.items.kept.where(id: id).update_all(position: index) # rubocop:disable Rails/SkipsModelValidations
          end
        end
      end
    end
  end
end
