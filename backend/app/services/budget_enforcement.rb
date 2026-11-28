# frozen_string_literal: true

# Enforces Activity budget_mode against item/reservation prices (O4A).
# Traceability: [REQ-ACT-005]
class BudgetEnforcement
  # [REQ-ACT-005] Pre: BudgetMode VO. Post: raises when price violates mode.
  def self.assert_price!(budget_mode:, price_cents:)
    raise ArgumentError, "Pre-condition failed: budget_mode must be BudgetMode" unless budget_mode.is_a?(BudgetMode)
    return if budget_mode.none?
    raise ArgumentError, "Invalid budget: price is required for #{budget_mode.value}" if price_cents.nil?

    assert_mode_amount!(budget_mode, Integer(price_cents))
  end

  def self.assert_mode_amount!(mode, cents)
    return assert_fixed_amount!(mode, cents) if mode.fixed?
    return assert_min_amount!(mode, cents) if mode.min_only?
    return assert_max_amount!(mode, cents) if mode.max_only?
    return assert_range_amount!(mode, cents) if mode.range?

    raise ArgumentError, "Pre-condition failed: unsupported budget_mode #{mode.value}"
  end
  private_class_method :assert_mode_amount!

  def self.assert_fixed_amount!(mode, cents)
    raise ArgumentError, "Invalid budget: price must equal fixed amount" unless cents == mode.amount_cents
  end
  private_class_method :assert_fixed_amount!

  def self.assert_min_amount!(mode, cents)
    raise ArgumentError, "Invalid budget: price below min" if cents < mode.amount_cents
  end
  private_class_method :assert_min_amount!

  def self.assert_max_amount!(mode, cents)
    raise ArgumentError, "Invalid budget: price above max" if cents > mode.amount_cents
  end
  private_class_method :assert_max_amount!

  def self.assert_range_amount!(mode, cents)
    out_of_range = cents < mode.amount_cents || cents > mode.max_cents
    raise ArgumentError, "Invalid budget: price outside range" if out_of_range
  end
  private_class_method :assert_range_amount!

  # [REQ-ACT-005] Activity item currency must match activity currency.
  def self.assert_currency!(activity:, currency:)
    raise ArgumentError, "Pre-condition failed: activity required" if activity.nil?

    normalized = currency.to_s.strip.upcase
    raise ArgumentError, "Invalid currency: must match activity currency" if normalized.blank?
    raise ArgumentError, "Invalid currency: must match activity currency" unless normalized == activity.currency
  end

  # [REQ-ACT-005] Combined guard for activity-scoped items (create/update/reserve).
  def self.assert_item!(item:)
    raise ArgumentError, "Pre-condition failed: item required" if item.nil?

    wishlist = item.wishlist
    return unless wishlist&.activity_scoped?

    activity = wishlist.activity
    raise ArgumentError, "Pre-condition failed: activity missing on scoped wishlist" if activity.nil?

    assert_currency!(activity: activity, currency: item.currency) if item.currency.present? || !activity.budget_mode_vo.none?
    assert_price!(budget_mode: activity.budget_mode_vo, price_cents: item.price_cents)
  end
end
