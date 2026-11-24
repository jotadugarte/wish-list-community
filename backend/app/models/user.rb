# frozen_string_literal: true

# Core identity model enforcing private normalized email, unique @username,
# 30-day username change cooldown, 30-day old-username quarantine, localization,
# and App Store / Google Play UGC terms acceptance.
# Traceability: [REQ-USER-001], [REQ-USER-002], [REQ-USER-003], [REQ-USER-004], [REQ-AUTH-002]
class User < ApplicationRecord
  SUPPORTED_LOCALES = %w[es en].freeze
  SUPPORTED_ROLES = %w[user admin].freeze
  USERNAME_COOLDOWN_DURATION = 30.days

  has_secure_password

  has_many :username_reservations, foreign_key: :previous_user_id, dependent: :destroy
  has_many :sessions, dependent: :destroy
  has_many :api_tokens, dependent: :destroy
  has_many :device_tokens, dependent: :destroy

  # [REQ-AUTH-001] Authenticates an active (non-discarded) user by normalized email and password.
  def self.authenticate_active(raw_email, raw_password)
    vo = EmailAddress.new(raw_email)
    candidate = where(discarded_at: nil).find_by("LOWER(email_address) = ?", vo.value)
    candidate&.authenticate(raw_password) || nil
  rescue ArgumentError
    nil
  end

  before_validation :normalize_identity_fields

  validates :email_address, presence: true, uniqueness: { case_sensitive: false }
  validates :username, presence: true, uniqueness: { case_sensitive: false }
  validates :locale, presence: true, inclusion: { in: SUPPORTED_LOCALES }
  validates :time_zone, presence: true
  validates :role, presence: true, inclusion: { in: SUPPORTED_ROLES }
  validates :terms_accepted_at, presence: true

  validate :validate_email_value_object
  validate :validate_username_value_object
  validate :validate_username_not_quarantined

  # [REQ-USER-001] Returns the EmailAddress Value Object.
  def email_vo
    EmailAddress.new(email_address)
  end

  # [REQ-USER-001] Returns the Username Value Object.
  def username_vo
    Username.new(username)
  end

  # [REQ-USER-001] Serializes only public profile fields; never exposes email_address.
  def public_profile_json
    {
      id: id,
      username: username_vo.value,
      created_at: created_at
    }
  end

  # [REQ-USER-001] [REQ-USER-004] Changes the user's @username enforcing the 30-day cooldown
  # and placing the previous @username into a 30-day quarantine.
  def change_username!(new_raw_username)
    raise ArgumentError, "Pre-condition failed: user must be persisted" unless persisted?

    if cooldown_active?
      errors.add(:username, "cannot be changed during the 30 days cooldown window")
      return false
    end

    candidate_vo = Username.new(new_raw_username)
    old_username = username

    transaction do
      quarantine_old_username!(old_username) if old_username != candidate_vo.value
      update!(username: candidate_vo.value, username_changed_at: Time.current)
    end

    raise "Post-condition failed: username_changed_at must be set" if username_changed_at.nil?

    true
  rescue ArgumentError, ActiveRecord::RecordInvalid => e
    errors.add(:username, e.message) if errors[:username].empty?
    false
  end

  private

  def cooldown_active?
    username_changed_at.present? && username_changed_at > USERNAME_COOLDOWN_DURATION.ago
  end

  def quarantine_old_username!(old_handle)
    UsernameReservation.where("LOWER(username) = ?", old_handle.downcase).delete_all
    UsernameReservation.create!(
      username: old_handle.downcase,
      previous_user: self,
      expires_at: UsernameReservation::QUARANTINE_DURATION.from_now
    )
  end

  def normalize_identity_fields
    self.email_address = email_address.to_s.strip.downcase if email_address.present?
    self.username = username.to_s.strip.downcase if username.present?
  end

  def validate_email_value_object
    return if email_address.blank?

    EmailAddress.new(email_address)
  rescue ArgumentError => e
    errors.add(:email_address, e.message)
  end

  def validate_username_value_object
    return if username.blank?

    Username.new(username)
  rescue ArgumentError => e
    errors.add(:username, e.message)
  end

  def validate_username_not_quarantined
    return if username.blank?
    return unless UsernameReservation.quarantined_for?(username, excluding_user_id: id)

    errors.add(:username, "is currently in quarantine and unavailable")
  end
end
