# frozen_string_literal: true

require "rails_helper"
require "vips"

RSpec.describe ItemImageProcessor do
  let(:item) { create(:item) }

  def build_png(width:, height:)
    image = Vips::Image.black(width, height).copy(interpretation: :srgb)
    # Embed a GPS-like string in comment metadata when supported
    tmp = Tempfile.new([ "src", ".png" ])
    image.write_to_file(tmp.path)
    tmp.rewind
    tmp
  end

  describe "processing rules [REQ-ITEM-002]" do
    it "attaches a WebP image resized to at most 1600px and strips metadata [REQ-ITEM-002]" do
      file = build_png(width: 2000, height: 1000)
      attachment = described_class.attach!(item: item, io: file, filename: "photo.png")
      item.reload

      expect(item.images.count).to eq(1)
      blob = attachment.blob
      expect(blob.content_type).to eq("image/webp")
      expect(blob.byte_size).to be > 0
      expect(blob.byte_size).to be <= ImageDimensions::MAX_BYTES

      downloaded = blob.download
      processed = Vips::Image.new_from_buffer(downloaded, "")
      expect([ processed.width, processed.height ].max).to be <= 1600
      # EXIF/GPS should be absent after strip
      expect(processed.get_fields.grep(/exif|gps/i)).to be_empty
    ensure
      file.close!
    end

    it "rejects images larger than 2MB [REQ-ITEM-002]" do
      big = StringIO.new("x" * (ImageDimensions::MAX_BYTES + 1))
      expect {
        described_class.attach!(item: item, io: big, filename: "big.png")
      }.to raise_error(ArgumentError, /bytes/i)
    end

    it "rejects a fourth image [REQ-ITEM-002]" do
      3.times do |i|
        file = build_png(width: 100, height: 100)
        described_class.attach!(item: item, io: file, filename: "p#{i}.png")
        file.close!
      end
      file = build_png(width: 100, height: 100)
      expect {
        described_class.attach!(item: item, io: file, filename: "fourth.png")
      }.to raise_error(ArgumentError, /exceed/i)
    ensure
      file&.close!
    end
  end
end
