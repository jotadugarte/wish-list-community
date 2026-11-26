# frozen_string_literal: true

# Value Object for processed image bounds (longest side).
# Traceability: [REQ-ITEM-002]
class ImageDimensions
  MAX_LONGEST_SIDE = 1600
  MAX_BYTES = 2 * 1024 * 1024

  attr_reader :width, :height

  # [REQ-ITEM-002] Pre-condition: width/height positive integers.
  def initialize(width:, height:)
    w = Integer(width)
    h = Integer(height)
    raise ArgumentError, "Invalid image dimensions" if w <= 0 || h <= 0

    @width = w
    @height = h
  end

  # [REQ-ITEM-002] Longest side in pixels.
  def longest_side
    [ width, height ].max
  end

  # [REQ-ITEM-002] Whether dimensions already fit the processing bound.
  def within_max?
    longest_side <= MAX_LONGEST_SIDE
  end
end
