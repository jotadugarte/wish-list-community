# frozen_string_literal: true

# Preferences are always scoped to the current user.
# Traceability: [REQ-NOTIF-001]
class NotificationPreferencePolicy < ApplicationPolicy
  def show?
    user.present? && !user.discarded?
  end

  def update?
    show?
  end
end
