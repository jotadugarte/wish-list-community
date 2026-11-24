# frozen_string_literal: true

# Policy governing visibility of a User's basic @username profile card.
# Enforces anti-stalking and the "Block Wins" rule: if blocked in either direction,
# access is completely denied.
# Traceability: [REQ-BLOCK-001], [REQ-WISH-001]
class UserPolicy < ApplicationPolicy
  # [REQ-BLOCK-001] Permits viewing basic public @username card only if active and not blocked.
  def show?
    return false if record.nil? || record.discarded_at.present?
    return false if blocked_between?(record)

    true
  end
end
