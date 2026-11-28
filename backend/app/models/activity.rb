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

  def secret_santa?
    assignment_mode == "secret_santa"
  end

  def open_gifting?
    assignment_mode == "open_gifting"
  end

  def accepted_participants
    participants.where(status: "accepted")
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
