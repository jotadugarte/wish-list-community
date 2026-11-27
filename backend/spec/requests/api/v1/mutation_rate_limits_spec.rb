# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API v1 mutation rate_limit declarations [REQ-DISC-001]" do
  # O2A/R1: ~10–30 per few minutes on write mutations; auth/preview/restore caps stay as-is.
  MUTATION_RATE_LIMITS = {
    "friendships_controller.rb" => {
      controller: Api::V1::FriendshipsController,
      actions: %i[create update destroy]
    },
    "user_blocks_controller.rb" => {
      controller: Api::V1::UserBlocksController,
      actions: %i[create]
    },
    "wishlists_controller.rb" => {
      controller: Api::V1::WishlistsController,
      actions: %i[create update destroy rotate_share_token]
    },
    "wishlist_shares_controller.rb" => {
      controller: Api::V1::WishlistSharesController,
      actions: %i[create destroy]
    },
    "items_controller.rb" => {
      controller: Api::V1::ItemsController,
      actions: %i[create update destroy destroy_image]
    },
    "reservations_controller.rb" => {
      controller: Api::V1::ReservationsController,
      actions: %i[create update destroy]
    },
    "gifts_controller.rb" => {
      controller: Api::V1::GiftsController,
      actions: %i[mark_delivered confirm_received]
    },
    "reservation_gifts_controller.rb" => {
      controller: Api::V1::ReservationGiftsController,
      actions: %i[create]
    },
    "item_gifts_controller.rb" => {
      controller: Api::V1::ItemGiftsController,
      actions: %i[create]
    },
    "notification_preferences_controller.rb" => {
      controller: Api::V1::NotificationPreferencesController,
      actions: %i[update]
    },
    "sessions_controller.rb" => {
      controller: Api::V1::SessionsController,
      actions: %i[destroy]
    },
    "accounts_controller.rb" => {
      controller: Api::V1::AccountsController,
      actions: %i[destroy]
    },
    "reports_controller.rb" => {
      controller: Api::V1::ReportsController,
      actions: %i[create]
    }
  }.freeze

  PRESERVED_CAPS = {
    "sessions_controller.rb" => /rate_limit\s+to:\s*10,\s*within:\s*3\.minutes,\s*only:\s*:create/,
    "signups_controller.rb" => /rate_limit\s+to:\s*10,\s*within:\s*3\.minutes,\s*only:\s*:create/,
    "passwords_controller.rb" => /rate_limit\s+to:\s*5,\s*within:\s*3\.minutes,\s*only:\s*:create/,
    "accounts_controller.rb" => /rate_limit\s+to:\s*5,\s*within:\s*3\.minutes,\s*only:\s*:restore/,
    "link_previews_controller.rb" => /rate_limit\s+to:\s*30,\s*within:\s*3\.minutes,\s*only:\s*:create/
  }.freeze

  def rate_limit_blocks(source)
    source.scan(/rate_limit\s+to:\s*(\d+),\s*within:\s*([^,\n]+),(?:[^\n]*only:\s*([^\n]+))?/)
  end

  def actions_covered(source)
    covered = []
    rate_limit_blocks(source).each do |to, within, only_clause|
      to_i = to.to_i
      expect(to_i).to be_between(5, 30)
      expect(within).to match(/minutes|hour/)
      if only_clause.nil?
        covered << :__all__
        next
      end
      symbols = only_clause.scan(/:([a-z0-9_]+)/).flatten.map(&:to_sym)
      if symbols.empty?
        percent_i = only_clause[/\%i\[([^\]]+)\]/, 1]
        symbols = percent_i.to_s.split.map(&:to_sym) if percent_i
      end
      covered.concat(symbols)
    end
    covered
  end

  MUTATION_RATE_LIMITS.each do |filename, config|
    it "declares rate_limit covering #{config[:actions].join(', ')} on #{filename}" do
      path = Rails.root.join("app/controllers/api/v1", filename)
      source = File.read(path)
      covered = actions_covered(source)
      config[:actions].each do |action|
        expect(covered.include?(action) || covered.include?(:__all__)).to(
          be(true),
          "expected rate_limit covering :#{action} in #{filename}, covered=#{covered.inspect}"
        )
      end
      expect(config[:controller]).to respond_to(:rate_limit)
    end
  end

  PRESERVED_CAPS.each do |filename, pattern|
    it "keeps existing auth/preview/restore cap unchanged in #{filename}" do
      source = File.read(Rails.root.join("app/controllers/api/v1", filename))
      expect(source).to match(pattern)
    end
  end
end
