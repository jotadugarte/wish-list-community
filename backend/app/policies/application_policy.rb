# frozen_string_literal: true

# Central Pundit policy enforcing Default-Deny and the "Block Wins" invariant.
# Traceability: [REQ-ARCH-001], [REQ-BLOCK-001]
class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  # [REQ-BLOCK-001] Default-deny across all actions unless explicitly overridden by a subclass.
  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  # [REQ-BLOCK-001] Central "Block Wins" check between the current user and a target owner/user.
  def blocked_between?(target_user)
    UserBlock.blocked_between?(user, target_user)
  end

  # Base Scope for Pundit policy scopes (default-deny empty relation).
  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope.none
    end
  end
end
