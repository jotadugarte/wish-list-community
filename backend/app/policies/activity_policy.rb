# frozen_string_literal: true

# Pundit policy for Activity board access and admin mutations.
# Traceability: [REQ-ACT-001], [REQ-BLOCK-001], [REQ-ARCH-001]
class ActivityPolicy < ApplicationPolicy
  # [REQ-ACT-001] Authenticated users may create activities.
  def create?
    user.present? && !user.discarded?
  end

  # [REQ-ACT-001] [REQ-BLOCK-001] Board access for creator or accepted participants; Block Wins.
  def show?
    return false if user.nil? || user.discarded? || record.nil? || record.cancelled?
    return true if creator?
    return false if blocked_from_activity?
    return true if accepted_participant?

    false
  end

  # [REQ-ACT-001] [REQ-BLOCK-001] Join/accept only when not blocked with creator or participants.
  def join?
    return false if user.nil? || user.discarded? || record.nil? || record.cancelled? || record.sealed?
    return false if blocked_from_activity?

    true
  end

  # [REQ-ACT-001] Creator or co-organizer may manage invites/exclusions/draw.
  def manage?
    return false unless show?

    creator? || co_organizer?
  end

  alias update? manage?
  alias invite? manage?
  alias draw? manage?
  alias recover_dropout? manage?
  alias cancel? manage?

  # [REQ-ACT-001] Only the creator may transfer ownership (FC2C).
  def transfer?
    return false if user.nil? || user.discarded? || record.nil? || record.cancelled?

    creator?
  end

  class Scope < ApplicationPolicy::Scope
    MAX_SCOPE_ROWS = 500

    # [REQ-ACT-001] Activities where the viewer is creator or accepted participant.
    def resolve
      return scope.none if user.nil? || user.discarded?

      participant_ids = ActivityParticipant.where(user_id: user.id, status: "accepted")
                                          .limit(MAX_SCOPE_ROWS)
                                          .pluck(:activity_id)
      scope.where(creator_id: user.id).or(scope.where(id: participant_ids)).limit(MAX_SCOPE_ROWS)
    end
  end

  private

  def creator?
    user.id == record.creator_id
  end

  def accepted_participant?
    record.participants.where(user_id: user.id, status: "accepted").exists?
  end

  def co_organizer?
    record.participants.where(user_id: user.id, status: "accepted", co_organizer: true).exists?
  end

  def blocked_from_activity?
    return true if blocked_between?(record.creator)

    participant_user_ids = record.participants.where(status: %w[invited accepted])
                                 .limit(500)
                                 .pluck(:user_id)
    participant_user_ids.any? { |uid| uid != user.id && UserBlock.blocked_between?(user, User.new(id: uid)) }
  end
end
