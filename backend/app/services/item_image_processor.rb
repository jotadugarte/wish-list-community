# frozen_string_literal: true

# Server-side image pipeline: size check, resize, WebP encode, EXIF/GPS strip via libvips.
# Traceability: [REQ-ITEM-002]
class ItemImageProcessor
  MAX_IMAGES = Item::MAX_IMAGES
  MAX_BYTES = ImageDimensions::MAX_BYTES
  MAX_SIDE = ImageDimensions::MAX_LONGEST_SIDE

  # [REQ-ITEM-002] Attach and process uploaded IO on an Item. Raises ArgumentError on violations.
  def self.attach!(item:, io:, filename:)
    new(item: item, io: io, filename: filename).attach!
  end

  def initialize(item:, io:, filename:)
    @item = item
    @io = io
    @filename = filename.to_s
  end

  # [REQ-ITEM-002] Pre: item persisted, under image cap, io within byte limit.
  # Post: attachment present as WebP without EXIF GPS.
  def attach!
    raise ArgumentError, "Pre-condition failed: item must be persisted" unless @item.persisted?
    raise ArgumentError, "Pre-condition failed: filename required" if @filename.strip.empty?
    raise ArgumentError, "images cannot exceed #{MAX_IMAGES}" if @item.images.attachments.size >= MAX_IMAGES

    bytes = read_limited_bytes!
    processed = process_with_vips(bytes)
    @item.images.attach(
      io: StringIO.new(processed),
      filename: webp_filename,
      content_type: "image/webp"
    )
    raise "Post-condition failed: image not attached" unless @item.images.attached?
    @item.images.attachments.last
  end

  private

  def read_limited_bytes!
    data = @io.read
    raise ArgumentError, "image exceeds #{MAX_BYTES} bytes" if data.bytesize > MAX_BYTES
    raise ArgumentError, "image is empty" if data.bytesize.zero?

    data
  end

  def process_with_vips(bytes)
    require "image_processing/vips"
    require "vips"

    source = Tempfile.new([ "item-src", ".bin" ])
    source.binmode
    source.write(bytes)
    source.flush
    pipeline = ImageProcessing::Vips
                 .source(source.path)
                 .resize_to_limit(MAX_SIDE, MAX_SIDE)
                 .convert("webp")
                 .saver(strip: true)
    result = pipeline.call
    output = File.binread(result.path)
    File.delete(result.path) if File.exist?(result.path)
    raise "Post-condition failed: processed image empty" if output.bytesize.zero?

    output
  ensure
    if source
      source.close
      source.unlink
    end
  end

  def webp_filename
    base = File.basename(@filename, ".*")
    base = "image" if base.strip.empty?
    "#{base}.webp"
  end
end
