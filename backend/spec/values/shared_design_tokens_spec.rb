# frozen_string_literal: true

require "rails_helper"

RSpec.describe SharedDesignTokens do
  describe ".load [REQ-ARCH-001]" do
    it "reads the shared file and exposes a version stamp [REQ-ARCH-001]" do
      catalog = described_class.load

      expect(catalog.version).to match(/\A\d{4}-\d{2}-\d{2}\./)
      expect(catalog.default_palette_id).to eq("01")
      expect(catalog.default_typography_id).to eq("01")
      expect(catalog.default_icon_style_id).to eq("02")
      expect(catalog.default_nav_structure_id).to eq("A")
      expect(catalog.app_name).to eq("Wish List")
    end

    it "exposes today's palette 01 colors for light and dark [REQ-ARCH-001]" do
      catalog = described_class.load

      expect(catalog.hex(palette_id: "01", appearance: "light", role: "primary")).to eq("#1F4037")
      expect(catalog.hex(palette_id: "01", appearance: "dark", role: "primary")).to eq("#4E8C73")
      expect(catalog.palette_ids).to eq((1..20).map { |n| format("%02d", n) })
    end

    it "builds bounded CSS variables for the active appearance [REQ-ARCH-001]" do
      catalog = described_class.load
      variables = catalog.css_variables(palette_id: "01", appearance: "light")

      expect(variables.fetch("--c-primary")).to eq("#1F4037")
      expect(variables.fetch("--c-bg")).to eq("#F6F5F0")
      expect(variables.size).to be <= SharedDesignTokens::MAX_COLOR_ROLES
    end
  end
end
