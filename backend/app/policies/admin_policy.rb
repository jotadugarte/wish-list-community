# frozen_string_literal: true

# Default-deny Pundit policy for the Web-only Admin panel (role=admin cookie session).
# Traceability: [REQ-ADM-001], [REQ-ARCH-001]
class AdminPolicy < ApplicationPolicy
  def index?
    admin?
  end

  def show?
    admin?
  end

  def dismiss?
    admin?
  end

  def suspend?
    admin?
  end

  def soft_delete_user?
    admin?
  end

  def soft_delete_wishlist?
    admin?
  end

  def access?
    admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless user&.role == "admin"

      scope.all
    end
  end

  private

  def admin?
    user.present? && user.role == "admin" && !user.suspended? && !user.discarded?
  end
end
