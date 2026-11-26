# frozen_string_literal: true

# Owned wishlist shell with anti-stalking privacy modes and optional Secret Link.
# Traceability: [REQ-WISH-001], [REQ-WISH-002], [REQ-WISH-004], [REQ-WISH-006],
# [REQ-ARCH-002], [REQ-LIFE-001]
class Wishlist < ApplicationRecord
  include SoftDeletable

  PRIVACY_MODES = PrivacyMode::ALLOWED
  MAX_TOKEN_MINT_ATTEMPTS = 5

  belongs_to :owner, class_name: "User"
  has_many :wishlist_shares, dependent: :destroy

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

  # [REQ-WISH-001] [REQ-WISH-002] Switches privacy mode, minting or wiping share_token.
  def switch_privacy_mode!(mode_vo)
    raise ArgumentError, "Pre-condition failed: mode must be PrivacyMode" unless mode_vo.is_a?(PrivacyMode)
    raise ArgumentError, "Pre-condition failed: wishlist must be persisted" unless persisted?

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

    self
  end

  # [REQ-WISH-002] [REQ-WISH-006] Rotates share_token while remaining shared (O4A).
  def rotate_share_token!
    raise ArgumentError, "Pre-condition failed: must be shared" unless privacy_mode_vo.shared?
    raise ArgumentError, "Pre-condition failed: wishlist must be persisted" unless persisted?

    previous = share_token
    transaction do
      update!(share_token: mint_unique_share_token!)
      revoke_secret_link_shares!
    end

    raise "Post-condition failed: token must change" if share_token == previous || share_token.blank?

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
end
