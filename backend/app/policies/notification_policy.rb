# frozen_string_literal: true

# In-app notifications belong to the recipient only.
# Traceability: [REQ-NOTIF-001]
class NotificationPolicy < ApplicationPolicy
  def index?
    user.present? && !user.discarded?
  end

  def update?
    user.present? && !user.discarded? && record.user_id == user.id
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none if user.nil?

      scope.where(user_id: user.id).limit(200)
    end
  end
end
