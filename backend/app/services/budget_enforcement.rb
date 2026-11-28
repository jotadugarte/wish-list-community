# frozen_string_literal: true

# Enforces Activity budget_mode against item/reservation prices (O4A).
# Traceability: [REQ-ACT-005]
class BudgetEnforcement
  # [REQ-ACT-005] Pre: BudgetMode VO. Post: raises when price violates mode.
  def self.assert_price!(budget_mode:, price_cents:)
    raise ArgumentError, "Pre-condition failed: budget_mode must be BudgetMode" unless budget_mode.is_a?(BudgetMode)

    return if budget_mode.none?

    if price_cents.nil?
      raise ArgumentError, "Invalid budget: price is required for #{budget_mode.value}"
    end

    cents = Integer(price_cents)
    case budget_mode.value
    when "fixed"
      raise ArgumentError, "Invalid budget: price must equal fixed amount" unless cents == budget_mode.amount_cents
    when "min_only"
      raise ArgumentError, "Invalid budget: price below min" if cents < budget_mode.amount_cents
    when "max_only"
      raise ArgumentError, "Invalid budget: price above max" if cents > budget_mode.amount_cents
    when "range"
      if cents < budget_mode.amount_cents || cents > budget_mode.max_cents
        raise ArgumentError, "Invalid budget: price outside range"
      end
    else
      raise ArgumentError, "Pre-condition failed: unsupported budget_mode #{budget_mode.value}"
    end
  end

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
