# frozen_string_literal: true

# Result of a Blind Auto-Bridge — never includes the full assignment map.
# Traceability: [REQ-ACT-003], [REQ-ACT-004]
class BlindBridgeResult
  attr_reader :notified_giver_id, :new_recipient_id, :revealed_full_map

  # [REQ-ACT-003] Pre-condition: notified giver id required; full map must stay hidden.
  def initialize(notified_giver_id:, new_recipient_id:)
    raise ArgumentError, "Pre-condition failed: notified_giver_id required" if notified_giver_id.nil?
    raise ArgumentError, "Pre-condition failed: new_recipient_id required" if new_recipient_id.nil?

    @notified_giver_id = Integer(notified_giver_id)
    @new_recipient_id = Integer(new_recipient_id)
    @revealed_full_map = false
    raise "Post-condition failed: must not reveal full map" if @revealed_full_map
  end
end
