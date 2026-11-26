# frozen_string_literal: true

# Grants a specific user durable access to a wishlist (explicit friend or secret_link).
# Traceability: [REQ-WISH-003], [REQ-BLOCK-002]
class WishlistShare < ApplicationRecord
  SOURCES = %w[explicit secret_link].freeze

  belongs_to :wishlist
  belongs_to :user

  validates :source, presence: true, inclusion: { in: SOURCES }
  validates :user_id, uniqueness: { scope: :wishlist_id }
  validate :cannot_share_with_owner

  # [REQ-WISH-003] Upserts a secret_link share for a logged-in non-owner viewer.
  def self.upsert_secret_link!(wishlist:, user:)
    raise ArgumentError, "Pre-condition failed: wishlist and user must be persisted" unless wishlist&.persisted? && user&.persisted?
    raise ArgumentError, "Pre-condition failed: cannot share with owner" if wishlist.owner_id == user.id
    raise ArgumentError, "Pre-condition failed: wishlist must be shared with token" unless wishlist.privacy_mode_vo.shared? && wishlist.share_token.present?
    raise ArgumentError, "Pre-condition failed: user is blocked" if UserBlock.blocked_between?(wishlist.owner, user)

    record = find_or_initialize_by(wishlist: wishlist, user: user)
    record.source = "secret_link" if record.new_record? || record.source == "secret_link"
    record.source = "explicit" if record.persisted? && record.source == "explicit"
    record.save!

    raise "Post-condition failed: share must persist" unless record.persisted?

    record
  end

  # [REQ-WISH-003] Creates or updates an explicit share for a selected friend.
  def self.upsert_explicit!(wishlist:, user:)
    raise ArgumentError, "Pre-condition failed: wishlist and user must be persisted" unless wishlist&.persisted? && user&.persisted?
    raise ArgumentError, "Pre-condition failed: cannot share with owner" if wishlist.owner_id == user.id
    raise ArgumentError, "Pre-condition failed: wishlist must be shared" unless wishlist.privacy_mode_vo.shared?
    raise ArgumentError, "Pre-condition failed: user is blocked" if UserBlock.blocked_between?(wishlist.owner, user)
    raise ArgumentError, "Pre-condition failed: users must be accepted friends" unless Friendship.status_between(wishlist.owner, user) == "accepted"

    record = find_or_initialize_by(wishlist: wishlist, user: user)
    record.source = "explicit"
    record.save!

    raise "Post-condition failed: explicit share must persist" unless record.persisted? && record.source == "explicit"

    record
  end

  # [REQ-WISH-003] Serializes a share row for API responses.
  def as_api_json
    {
      id: id,
      wishlist_id: wishlist_id,
      user_id: user_id,
      source: source,
      user: user.public_profile_json,
      created_at: created_at
    }
  end

  # [REQ-BLOCK-002] Deletes all shares between a pair of users (either as owner or sharee).
  def self.delete_between!(user_a, user_b)
    raise ArgumentError, "Pre-condition failed: both users required" if user_a.nil? || user_b.nil?

    owned_by_a = Wishlist.where(owner_id: user_a.id).select(:id)
    owned_by_b = Wishlist.where(owner_id: user_b.id).select(:id)

    where(user_id: user_b.id, wishlist_id: owned_by_a)
      .or(where(user_id: user_a.id, wishlist_id: owned_by_b))
      .limit(10_000)
      .delete_all
  end

  private

  def cannot_share_with_owner
    return if wishlist.nil? || user_id.nil?
    return if wishlist.owner_id != user_id

    errors.add(:user_id, "cannot share a wishlist with its owner")
  end
end

UserBlock.register_cleanup_hook(:destroy_wishlist_shares) do |blocker, blocked|
  WishlistShare
  WishlistShare.delete_between!(blocker, blocked)
end
