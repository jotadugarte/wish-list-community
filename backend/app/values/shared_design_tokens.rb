# frozen_string_literal: true

# Reads the monorepo DesignTokens file shared by Admin Hotwire and Flutter.
# Traceability: [REQ-ARCH-001]
class SharedDesignTokens
  MAX_PALETTES = 20
  MAX_COLOR_ROLES = 10
  APPEARANCES = %w[light dark].freeze
  ROLE_TO_CSS = {
    "bg" => "--c-bg",
    "surface" => "--c-surface",
    "text" => "--c-text",
    "muted" => "--c-muted",
    "primary" => "--c-primary",
    "primaryFg" => "--c-primary-fg",
    "accent" => "--c-accent",
    "accentBg" => "--c-accent-bg",
    "border" => "--c-border",
    "specBg" => "--c-spec-bg"
  }.freeze
  DEFAULT_PATH = File.expand_path("../../../design/design_tokens.json", __dir__)

  attr_reader :version

  # [REQ-ARCH-001] Pre-condition: the shared JSON file exists.
  # Post-condition: catalog version is present.
  def self.load(path = DEFAULT_PATH)
    raise ArgumentError, "Pre-condition failed: design tokens file missing" unless File.file?(path)

    catalog = new(JSON.parse(File.read(path)))
    raise "Post-condition failed: version blank" if catalog.version.to_s.empty?

    catalog
  end

  # [REQ-ARCH-001] Pre-condition: payload includes a version and palettes.
  # Post-condition: palette catalog is not empty.
  def initialize(raw)
    raise ArgumentError, "Pre-condition failed: version missing" if raw["version"].to_s.empty?

    @version = raw["version"].to_s.freeze
    @defaults = raw.fetch("defaults")
    @palettes = raw.fetch("palettes")
    raise "Post-condition failed: palette catalog empty" if @palettes.empty?
  end

  def default_palette_id
    @defaults.fetch("palette_id")
  end

  def default_typography_id
    @defaults.fetch("typography_id")
  end

  def default_icon_style_id
    @defaults.fetch("icon_style_id")
  end

  def default_nav_structure_id
    @defaults.fetch("nav_structure_id")
  end

  def app_name
    @defaults.fetch("app_name")
  end

  # [REQ-ARCH-001] Pre-condition: appearance and role are known.
  # Post-condition: returns a 6-digit hex color.
  def hex(palette_id:, appearance:, role:)
    raise ArgumentError, "Pre-condition failed: unknown appearance" unless APPEARANCES.include?(appearance)
    raise ArgumentError, "Pre-condition failed: unknown role" unless ROLE_TO_CSS.key?(role)

    value = @palettes.fetch(palette_id).fetch(appearance).fetch(role)
    raise "Post-condition failed: hex missing" unless value.match?(/\A#[0-9A-F]{6}\z/)

    value
  end

  # [REQ-ARCH-001] Post-condition: palette count stays within the studio bound.
  def palette_ids
    ids = @palettes.keys.sort
    raise "Post-condition failed: palette bound exceeded" if ids.size > MAX_PALETTES

    ids
  end

  # [REQ-ARCH-001] Post-condition: one CSS variable per color role, never more.
  def css_variables(palette_id:, appearance:)
    variables = {}
    ROLE_TO_CSS.each do |role, css_name|
      variables[css_name] = hex(palette_id: palette_id, appearance: appearance, role: role)
    end
    raise "Post-condition failed: css variable bound exceeded" if variables.size > MAX_COLOR_ROLES

    variables
  end
end
