# frozen_string_literal: true

# Value Object for a reservation estimated calendar date in the reserver's time zone.
# Traceability: [REQ-RES-001], [REQ-USER-003]
class EstimatedDate
  attr_reader :value, :time_zone_name

  # [REQ-RES-001] Pre-condition: raw parses to a Date; time_zone is a known zone name.
  # Post-condition: @value is a Date.
  def initialize(raw_date, time_zone:)
    @time_zone_name = time_zone.to_s
    zone = ActiveSupport::TimeZone[@time_zone_name]
    raise ArgumentError, "Unknown time zone: #{time_zone}" if zone.nil?

    parsed = parse_date(raw_date)
    raise ArgumentError, "Invalid estimated_date" if parsed.nil?

    @value = parsed
    raise "Post-condition failed: value must be a Date" unless @value.is_a?(Date)
  end

  # [REQ-RES-001] Pre-condition: value present. Raises if date is before today in zone.
  def assert_not_past!
    zone = ActiveSupport::TimeZone[time_zone_name]
    raise ArgumentError, "estimated_date cannot be in the past" if value < zone.today

    true
  end

  def ==(other)
    other.is_a?(self.class) && value == other.value && time_zone_name == other.time_zone_name
  end
  alias eql? ==

  def hash
    [ value, time_zone_name ].hash
  end

  def to_s
    value.iso8601
  end

  private

  def parse_date(raw_date)
    return raw_date if raw_date.is_a?(Date)
    return nil if raw_date.blank?

    Date.iso8601(raw_date.to_s)
  rescue ArgumentError
    nil
  end
end
