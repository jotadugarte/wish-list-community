# frozen_string_literal: true

# Stores only the SHA-256 digest of API v1 bearer tokens and manages token expiration,
# revocation, and automatic unbinding of push notification DeviceTokens.
# Traceability: [REQ-AUTH-001], [REQ-NOTIF-002]
class ApiToken < ApplicationRecord
  DEFAULT_TTL = 90.days

  belongs_to :user
  has_many :device_tokens, dependent: :destroy

  validates :token_digest, presence: true, uniqueness: true
  validates :expires_at, presence: true

  scope :active, -> { where(revoked_at: nil).where("expires_at > ?", Time.current) }

  # [REQ-AUTH-001] [REQ-NOTIF-002] Issues a new API token for a user, persisting only the SHA-256 digest
  # and optionally binding an FCM push device_token to this session.
  def self.issue_for!(user, device_name: nil, expires_in: DEFAULT_TTL, fcm_token: nil)
    raise ArgumentError, "Pre-condition failed: user must be persisted" unless user&.persisted?

    vo = AuthToken.generate
    record = nil

    transaction do
      record = create!(
        user: user,
        token_digest: vo.digest,
        device_name: device_name,
        expires_at: expires_in.from_now,
        last_used_at: Time.current
      )

      if fcm_token.present?
        DeviceToken.where(token: fcm_token).delete_all
        record.device_tokens.create!(user: user, token: fcm_token)
      end
    end

    raise "Post-condition failed: raw token must not be stored in token_digest" if record.token_digest == vo.raw

    [ record, vo.raw ]
  end

  # [REQ-AUTH-001] Finds an active, non-expired, non-revoked ApiToken by raw token string.
  def self.authenticate(raw_token)
    return nil if raw_token.to_s.strip.empty?

    vo = AuthToken.from_raw(raw_token)
    token_record = active.includes(:user).find_by(token_digest: vo.digest)
    return nil if token_record.nil?
    user = token_record.user
    return nil if user.discarded_at.present? || user.suspended_at.present?

    token_record
  end

  # [REQ-NOTIF-002] Binds (or replaces) the FCM device_token for this API session.
  def bind_device_token!(fcm_token)
    raise ArgumentError, "Pre-condition failed: token must be persisted" unless persisted?
    return if fcm_token.blank?

    transaction do
      DeviceToken.where(token: fcm_token).delete_all
      device_tokens.destroy_all
      device_tokens.create!(user: user, token: fcm_token)
    end
  end

  # [REQ-AUTH-001] [REQ-NOTIF-002] Revokes this token and destroys all bound FCM DeviceTokens.
  def revoke!
    raise ArgumentError, "Pre-condition failed: token must be persisted" unless persisted?

    transaction do
      device_tokens.destroy_all
      update!(revoked_at: Time.current)
    end

    raise "Post-condition failed: revoked_at must be present" if revoked_at.nil?

    true
  end
end
