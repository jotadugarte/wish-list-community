# frozen_string_literal: true

# Value Object for activity budget configuration modes.
# Traceability: [REQ-ACT-005]
class BudgetMode
  ALLOWED = %w[none fixed min_only max_only range].freeze
  MODES_REQUIRING_AMOUNT = %w[fixed min_only max_only range].freeze

  attr_reader :value, :amount_cents, :max_cents

  # [REQ-ACT-005] Pre-condition: mode + bounds must be valid for the chosen mode.
  # Post-condition: frozen allowed mode with consistent amount/max fields.
  def initialize(raw_mode, amount_cents: nil, max_cents: nil)
    normalized = raw_mode.to_s.strip.downcase
    raise ArgumentError, "Invalid budget_mode: must be one of #{ALLOWED.join(', ')}" unless ALLOWED.include?(normalized)

    @value = normalized.freeze
    @amount_cents = amount_cents.nil? ? nil : Integer(amount_cents)
    @max_cents = max_cents.nil? ? nil : Integer(max_cents)
    validate_bounds!
    raise "Post-condition failed: budget_mode must be frozen allowed value" unless @value.frozen? && ALLOWED.include?(@value)
  end

  def none?
    value == "none"
  end

  def fixed?
    value == "fixed"
  end

  def min_only?
    value == "min_only"
  end

  def max_only?
    value == "max_only"
  end

  def range?
    value == "range"
  end

  def ==(other)
    other.is_a?(self.class) &&
      value == other.value &&
      amount_cents == other.amount_cents &&
      max_cents == other.max_cents
  end
  alias eql? ==

  def hash
    [ value, amount_cents, max_cents ].hash
  end

  def to_s
    value
  end

  private

  def validate_bounds!
    if MODES_REQUIRING_AMOUNT.include?(value) && amount_cents.nil?
      raise ArgumentError, "Invalid budget_mode: amount_cents required for #{value}"
    end
    raise ArgumentError, "Invalid budget_mode: amount_cents must be positive" if amount_cents && amount_cents <= 0
    raise ArgumentError, "Invalid budget_mode: max_cents must be positive" if max_cents && max_cents <= 0

    return unless range?

    raise ArgumentError, "Invalid budget_mode: max_cents required for range" if max_cents.nil?
    raise ArgumentError, "Invalid budget_mode: range requires amount_cents <= max_cents" if amount_cents > max_cents
  end
end
