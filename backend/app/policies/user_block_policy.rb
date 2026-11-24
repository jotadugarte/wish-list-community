# frozen_string_literal: true

# Policy governing creation of a UserBlock.
# Traceability: [REQ-BLOCK-001]
class UserBlockPolicy < ApplicationPolicy
  # [REQ-BLOCK-001] Any authenticated active user can block another distinct user.
  def create?
    user.present? && user.discarded_at.nil? && record.is_a?(User) && user.id != record.id
  end
end
