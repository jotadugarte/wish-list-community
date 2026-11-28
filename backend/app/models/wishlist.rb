# frozen_string_literal: true

# Owned wishlist shell with anti-stalking privacy modes and optional Secret Link.
# Traceability: [REQ-WISH-001], [REQ-WISH-002], [REQ-WISH-004], [REQ-WISH-006],
# [REQ-ARCH-002], [REQ-LIFE-001]
class Wishlist < ApplicationRecord
  include SoftDeletable

  PRIVACY_MODES = PrivacyMode::ALLOWED
  MAX_TOKEN_MINT_ATTEMPTS = 5

  belongs_to :owner, class_name: "User"
  belongs_to :activity, optional: true
  has_many :wishlist_shares, dependent: :destroy
  has_many :items, dependent: :destroy, inverse_of: :wishlist

  # [REQ-ARCH-002] Personal My Wishlists exclude activity-scoped rows (FC1A).
  scope :personal, -> { where(activity_id: nil) }
  # [REQ-ARCH-002] Activity-board lists only (not personal My Wishlists).
  scope :activity_scoped, -> { where.not(activity_id: nil) }

  # [REQ-LIFE-001] Cascade soft-delete to Items so restore leaves a clean slate for S5 reservations.
  register_soft_delete_hook(:cascade_soft_delete_items) do |wishlist_record|
    ::Item
    cascaded_ids = []
    wishlist_record.items.kept.limit(500).find_each do |item|
      item.soft_delete!(actor: wishlist_record.owner)
      cascaded_ids << item.id
    end
    wishlist_record.merge_soft_delete_audit_metadata!("cascaded_item_ids" => cascaded_ids)
  end

  # [REQ-LIFE-001] Restore only items cascaded in the matching soft-delete AuditEvent.
  register_restore_hook(:cascade_restore_items) do |wishlist_record|
    ::Item
    ::AuditEvent
    event = AuditEvent.where(auditable_type: "Wishlist", auditable_id: wishlist_record.id, action: "wishlist.soft_deleted")
                      .order(created_at: :desc)
                      .limit(1)
                      .first
    next if event.nil?

    cascaded_ids = Array(event.metadata["cascaded_item_ids"]).map(&:to_i).first(500)
    next if cascaded_ids.empty?

    wishlist_record.items.discarded.where(id: cascaded_ids).limit(500).find_each do |item|
      item.restore!(actor: wishlist_record.owner)
    end
  end

  before_validation :apply_default_privacy_mode, on: :create

  validates :title, presence: true
  validates :privacy_mode, presence: true, inclusion: { in: PRIVACY_MODES }
  validates :share_token, uniqueness: { allow_nil: true }
  validate :share_token_matches_privacy_mode

  # [REQ-WISH-001] Returns the PrivacyMode Value Object for this wishlist.
  def privacy_mode_vo
    PrivacyMode.new(privacy_mode)
  end

  # [REQ-WISH-006] Returns the ShareToken Value Object when a token is present.
  def share_token_vo
    return nil if share_token.blank?

    ShareToken.new(share_token)
  end

  # [REQ-ARCH-002] [REQ-ACT-001] True when this wishlist belongs to an Activity (FC4A).
  def activity_scoped?
    activity_id.present?
  end

  # [REQ-WISH-001] [REQ-WISH-002] Switches privacy mode, minting or wiping share_token.
  # No-op when the requested mode already matches (avoids reminting without O4A rotate).
  def switch_privacy_mode!(mode_vo)
    raise ArgumentError, "Pre-condition failed: mode must be PrivacyMode" unless mode_vo.is_a?(PrivacyMode)
    raise ArgumentError, "Pre-condition failed: wishlist must be persisted" unless persisted?
    raise ArgumentError, "Pre-condition failed: activity wishlists cannot switch personal privacy" if activity_scoped?
    return self if privacy_mode == mode_vo.value

    transaction do
      if mode_vo.shared?
        update!(privacy_mode: mode_vo.value, share_token: mint_unique_share_token!)
      else
        update!(privacy_mode: mode_vo.value, share_token: nil)
        revoke_secret_link_shares!
      end
    end

    raise "Post-condition failed: privacy_mode mismatch" unless privacy_mode == mode_vo.value
    raise "Post-condition failed: friends must wipe share_token" if mode_vo.friends? && share_token.present?
    raise "Post-condition failed: shared must mint share_token" if mode_vo.shared? && share_token.blank?
    assert_secret_link_shares_revoked! if mode_vo.friends?

    self
  end

  # [REQ-WISH-001] [REQ-WISH-006] [REQ-ARCH-002] Serializes the wishlist shell for API clients.
  # share_token is owner-only on personal lists; activity lists never expose Secret Link (FC4A).
  def as_api_json(viewer: nil)
    payload = {
      id: id,
      title: title,
      privacy_mode: privacy_mode,
      event_date: event_date,
      max_reservations_per_user: max_reservations_per_user,
      owner: owner.public_profile_json,
      discarded_at: discarded_at,
      created_at: created_at,
      updated_at: updated_at
    }
    payload[:activity_id] = activity_id if activity_scoped?
    if !activity_scoped? && viewer.present? && viewer.id == owner_id
      payload[:share_token] = share_token
    end
    payload
  end

  # [REQ-WISH-002] [REQ-WISH-006] Rotates share_token while remaining shared (O4A).
  def rotate_share_token!
    raise ArgumentError, "Pre-condition failed: activity wishlists cannot use Secret Link" if activity_scoped?
    raise ArgumentError, "Pre-condition failed: must be shared" unless privacy_mode_vo.shared?
    raise ArgumentError, "Pre-condition failed: wishlist must be persisted" unless persisted?

    previous = share_token
    transaction do
      update!(share_token: mint_unique_share_token!)
      revoke_secret_link_shares!
    end

    raise "Post-condition failed: token must change" if share_token == previous || share_token.blank?
    assert_secret_link_shares_revoked!

    self
  end

  private

  def apply_default_privacy_mode
    self.privacy_mode = "friends" if privacy_mode.blank?
  end

  def share_token_matches_privacy_mode
    if privacy_mode == "friends" && share_token.present?
      errors.add(:share_token, "must be blank when privacy_mode is friends")
    elsif privacy_mode == "shared" && share_token.blank? && persisted?
      errors.add(:share_token, "must be present when privacy_mode is shared")
    end
  end

  def mint_unique_share_token!
    attempts = 0
    while attempts < MAX_TOKEN_MINT_ATTEMPTS
      attempts += 1
      candidate = ShareToken.generate.value
      return candidate unless self.class.where(share_token: candidate).where.not(id: id).exists?
    end
    raise "Post-condition failed: unable to mint unique share_token"
  end

  def revoke_secret_link_shares!
    wishlist_shares.where(source: "secret_link").limit(10_000).delete_all
  end

  def assert_secret_link_shares_revoked!
    remaining = wishlist_shares.where(source: "secret_link").exists?
    raise "Post-condition failed: secret_link shares must be revoked" if remaining
  end
end
