# frozen_string_literal: true

module Member
  # Hotwire friends + incoming requests index (phone parity O12A/O2B).
  # Traceability: [REQ-SOC-001], [REQ-BLOCK-001]
  class FriendsController < BaseController
    MAX_INDEX = 100

    def index
      authorize Friendship, :index?
      scoped = policy_scope(Friendship).includes(:requester, :addressee)
      @incoming = scoped.pending
                        .where(addressee_id: current_user.id)
                        .order(created_at: :desc)
                        .limit(MAX_INDEX)
                        .select(&:active_participants?)
      @friends = scoped.accepted
                       .order(updated_at: :desc)
                       .limit(MAX_INDEX)
                       .select(&:active_participants?)
    end
  end
end
