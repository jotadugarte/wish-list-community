# frozen_string_literal: true

# Group gift exchange shell (Secret Santa / Open Gifting) for Sprint A.
# Traceability: [REQ-ACT-001], [REQ-ACT-005], [REQ-ARCH-001]
class Activity < ApplicationRecord
  ASSIGNMENT_MODES = %w[secret_santa open_gifting].freeze
  VISIBILITY_MODES = %w[recipient_only all_participants].freeze
  RESERVATION_VISIBILITIES = %w[hidden_from_recipient visible_to_recipient].freeze
  STATUSES = %w[open sealed cancelled].freeze
  MAX_TOKEN_MINT_ATTEMPTS = 5

  belongs_to :creator, class_name: "User"
  has_many :participants, class_name: "ActivityParticipant", dependent: :destroy, inverse_of: :activity

  before_validation :mint_share_token_if_blank, on: :create
  after_create :ensure_creator_participant!

  validates :name, presence: true
  validates :currency, presence: true
  validates :assignment_mode, presence: true, inclusion: { in: ASSIGNMENT_MODES }
  validates :visibility_mode, presence: true, inclusion: { in: VISIBILITY_MODES }
  validates :reservation_visibility, presence: true, inclusion: { in: RESERVATION_VISIBILITIES }
  validates :budget_mode, presence: true, inclusion: { in: BudgetMode::ALLOWED }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :share_token, presence: true, uniqueness: true
  validate :budget_mode_bounds_are_valid

  # [REQ-ACT-001] Returns the opaque ActivityLinkToken Value Object.
  def link_token_vo
    ActivityLinkToken.new(share_token)
  end

  # [REQ-ACT-005] Returns the BudgetMode Value Object for configured bounds.
  def budget_mode_vo
    BudgetMode.new(budget_mode, amount_cents: budget_amount_cents, max_cents: budget_max_cents)
  end

  def sealed?
    sealed_at.present? || status == "sealed"
  end

  def cancelled?
    cancelled_at.present? || status == "cancelled"
  end

  def needs_dropout_recovery?
    needs_dropout_recovery == true
  end

  def secret_santa?
    assignment_mode == "secret_santa"
  end

  def open_gifting?
    assignment_mode == "open_gifting"
  end

  def accepted_participants
    participants.where(status: "accepted")
  end

  # [REQ-ACT-001] O2B layer-1 freeze after the first non-creator invitee accepts.
  def money_settings_frozen?
    money_settings_frozen_at.present?
  end

  # [REQ-ACT-001] Updates money/visibility settings while O2B layer-1 is unlocked.
  def update_settings!(actor:, currency: nil, budget_mode: nil, visibility_mode: nil, reservation_visibility: nil)
    raise ArgumentError, "Pre-condition failed: actor required" if actor.nil?
    raise ArgumentError, "Pre-condition failed: money settings are frozen" if money_settings_frozen?

    attrs = {}
    attrs[:currency] = currency if currency
    if budget_mode
      mode_vo = budget_mode.is_a?(BudgetMode) ? budget_mode : BudgetMode.new(budget_mode)
      attrs[:budget_mode] = mode_vo.value
      attrs[:budget_amount_cents] = mode_vo.amount_cents
      attrs[:budget_max_cents] = mode_vo.max_cents
    end
    attrs[:visibility_mode] = visibility_mode if visibility_mode
    attrs[:reservation_visibility] = reservation_visibility if reservation_visibility
    update!(attrs) unless attrs.empty?
    raise "Post-condition failed: settings must remain unfrozen after edit" if money_settings_frozen?

    self
  end

  # [REQ-ACT-001] Soft name/dates remain editable with an audit notice after freeze.
  def update_soft_fields!(actor:, name: nil, starts_on: nil, ends_on: nil)
    raise ArgumentError, "Pre-condition failed: actor required" if actor.nil?

    attrs = {}
    attrs[:name] = name unless name.nil?
    attrs[:starts_on] = starts_on unless starts_on.nil?
    attrs[:ends_on] = ends_on unless ends_on.nil?
    return self if attrs.empty?

    transaction do
      update!(attrs)
      AuditEvent.record!(
        actor: actor,
        action: "activity.soft_fields_updated",
        auditable: self,
        metadata: attrs.transform_values { |value| value.respond_to?(:iso8601) ? value.iso8601 : value }
      )
    end

    self
  end

  # [REQ-ACT-001] Locks money/visibility settings (idempotent).
  def freeze_money_settings!
    return self if money_settings_frozen?

    update!(money_settings_frozen_at: Time.current)
    raise "Post-condition failed: money settings must be frozen" unless money_settings_frozen?

    self
  end

  # [REQ-BLOCK-001] [REQ-ACT-003] Marks sealed secret_santa as needing Blind Bridge / Full Redraw.
  def require_dropout_recovery!
    raise ArgumentError, "Pre-condition failed: activity must be sealed secret_santa" unless sealed? && secret_santa?

    update!(needs_dropout_recovery: true)
    raise "Post-condition failed: dropout recovery required" unless needs_dropout_recovery?

    self
  end

  # [REQ-ACT-003] Clears the dropout recovery flag after bridge/redraw.
  def clear_dropout_recovery!
    update!(needs_dropout_recovery: false)
    raise "Post-condition failed: dropout recovery cleared" if needs_dropout_recovery?

    self
  end

  # [REQ-ACT-001] Serializes the activity shell for API clients (share_token creator-only).
  def as_api_json(viewer: nil)
    payload = {
      id: id,
      name: name,
      currency: currency,
      assignment_mode: assignment_mode,
      visibility_mode: visibility_mode,
      reservation_visibility: reservation_visibility,
      budget_mode: budget_mode,
      budget_amount_cents: budget_amount_cents,
      budget_max_cents: budget_max_cents,
      status: status,
      sealed_at: sealed_at,
      cancelled_at: cancelled_at,
      starts_on: starts_on,
      ends_on: ends_on,
      money_settings_frozen_at: money_settings_frozen_at,
      needs_dropout_recovery: needs_dropout_recovery?,
      creator: creator.public_profile_json,
      created_at: created_at,
      updated_at: updated_at
    }
    payload[:share_token] = share_token if viewer.present? && viewer.id == creator_id
    if viewer.present?
      payload[:viewer_status] =
        if viewer.id == creator_id
          participants.find_by(user_id: viewer.id)&.status || "accepted"
        else
          participants.find_by(user_id: viewer.id)&.status
        end
      payload[:viewer_can_manage] = ActivityPolicy.new(viewer, self).manage?
    end
    payload
  end

  private

  def mint_share_token_if_blank
    return if share_token.present?

    attempts = 0
    loop do
      attempts += 1
      raise "Post-condition failed: could not mint unique activity link token" if attempts > MAX_TOKEN_MINT_ATTEMPTS

      candidate = ActivityLinkToken.generate.value
      unless self.class.exists?(share_token: candidate)
        self.share_token = candidate
        break
      end
    end
  end

  def ensure_creator_participant!
    raise ArgumentError, "Pre-condition failed: creator must be present" if creator.blank?

    participants.find_or_create_by!(user: creator) do |participant|
      participant.status = "accepted"
      participant.co_organizer = true
      participant.accepted_at = Time.current
    end
  end

  def budget_mode_bounds_are_valid
    budget_mode_vo
  rescue ArgumentError => e
    errors.add(:budget_mode, e.message)
  end
end
