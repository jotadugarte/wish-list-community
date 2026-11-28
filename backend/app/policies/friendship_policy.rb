# frozen_string_literal: true

# Policy governing Friendship listing, request creation, acceptance, and removal.
# Enforces "Block Wins" and strict actor participation checks.
# Traceability: [REQ-SOC-001], [REQ-BLOCK-001]
class FriendshipPolicy < ApplicationPolicy
  # [REQ-SOC-001] Any authenticated active user can list their own friendships.
  def index?
    user.present? && !user.discarded?
  end

  # [REQ-SOC-001] [REQ-BLOCK-001] Only the requester can create a friendship if neither user is blocked.
  def create?
    return false if user.nil? || record.nil? || record.addressee.nil?
    return false if user.id != record.requester_id || user.id == record.addressee_id
    return false if record.addressee.discarded?
    return false if blocked_between?(record.addressee)

    true
  end

  # [REQ-SOC-001] [REQ-BLOCK-001] Only the addressee of a pending request can accept it.
  def update?
    return false if user.nil? || record.nil?
    return false unless record.status == "pending" && record.addressee_id == user.id
    return false if blocked_between?(record.requester)

    true
  end

  # [REQ-SOC-001] Either participant (requester or addressee) can decline, cancel, or unfriend.
  def destroy?
    return false if user.nil? || record.nil?

    record.requester_id == user.id || record.addressee_id == user.id
  end

  # [REQ-SOC-001] Scope listings to friendships where the viewer participates.
  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none if user.nil? || user.discarded?

      scope.where(requester_id: user.id).or(scope.where(addressee_id: user.id))
    end
  end
end
