# frozen_string_literal: true

module Admin
  # Presentational state for the Admin brand guide. No domain writes.
  # Traceability: [REQ-ARCH-001], [REQ-ADM-001]
  class StyleGuidePage
    APPEARANCES = %w[light dark].freeze
    COPIES = %w[es en].freeze
    PREVIEWS = %w[web app].freeze

    attr_reader :version, :appearance, :copy, :preview, :variables

    # [REQ-ARCH-001] Pre-condition: catalog is loaded by the caller default.
    # Post-condition: version stamp is present.
    def self.build(params:, catalog: SharedDesignTokens.load)
      page = new(params, catalog)
      raise "Post-condition failed: version blank" if page.version.to_s.empty?

      page
    end

    def initialize(params, catalog)
      raise ArgumentError, "Pre-condition failed: catalog missing" if catalog.nil?

      @catalog = catalog
      @appearance = pick(params[:appearance], APPEARANCES, "light")
      @copy = pick(params[:copy], COPIES, fallback_copy)
      @preview = pick(params[:preview], PREVIEWS, "web")
      @version = catalog.version
      @variables = catalog.css_variables(
        palette_id: catalog.default_palette_id,
        appearance: @appearance
      )
    end

    def style_attribute
      @variables.map { |name, value| "#{name}:#{value}" }.join(";")
    end

    # [REQ-ARCH-001] Post-condition: row count stays within the color-role bound.
    def rows
      built = @variables.map { |name, value| { role: name.delete_prefix("--c-"), hex: value } }
      raise "Post-condition failed: token row bound exceeded" if built.size > SharedDesignTokens::MAX_COLOR_ROLES

      built
    end

    def path_for(appearance:, copy:, preview: @preview)
      "/admin/style_guide?appearance=#{appearance}&copy=#{copy}&preview=#{preview}"
    end

    def web?
      preview == "web"
    end

    def app?
      preview == "app"
    end

    private

    def pick(raw, allowed, fallback)
      value = raw.to_s
      allowed.include?(value) ? value : fallback
    end

    def fallback_copy
      locale = I18n.locale.to_s
      COPIES.include?(locale) ? locale : "es"
    end
  end
end
