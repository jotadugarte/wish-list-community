# frozen_string_literal: true

module Member
  # Hotwire friends + incoming requests index (phone parity O12A/O2B).
  # Traceability: [REQ-SOC-001], [REQ-BLOCK-001]
  class FriendsController < BaseController
    MAX_INDEX = 100

    def index
      authorize Friendship, :index?
      scoped = policy_scope(Friendship).includes(:requester, :addressee).limit(MAX_INDEX)
      @friends = scoped.select { |f| f.status == "accepted" && f.active_participants? }
      @incoming = scoped.select { |f| f.status == "pending" && f.addressee_id == current_user.id && f.active_participants? }
    end
  end
end
