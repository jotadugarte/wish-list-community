# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Hotwire mutation rate_limit declarations [REQ-DISC-001]" do
  MUTATION_RATE_LIMITS = {
    "secret_link_reservations_controller.rb" => {
      controller: SecretLinkReservationsController,
      actions: %i[create update destroy]
    },
    "secret_link_gifts_controller.rb" => {
      controller: SecretLinkGiftsController,
      actions: %i[mark_purchased mark_delivered confirm_received mark_received]
    },
    "sessions_controller.rb" => {
      controller: SessionsController,
      actions: %i[destroy]
    }
  }.freeze

  PRESERVED_CAPS = {
    "sessions_controller.rb" => /rate_limit\s+to:\s*10,\s*within:\s*3\.minutes,\s*only:\s*:create/,
    "web_signups_controller.rb" => /rate_limit\s+to:\s*10,\s*within:\s*3\.minutes,\s*only:\s*:create/
  }.freeze

  def actions_covered(source)
    covered = []
    source.scan(/rate_limit\s+to:\s*(\d+),\s*within:\s*([^,\n]+),(?:[^\n]*only:\s*([^\n]+))?/).each do |to, within, only_clause|
      expect(to.to_i).to be_between(5, 30)
      expect(within).to match(/minutes|hour/)
      if only_clause.nil?
        covered << :__all__
        next
      end
      symbols = only_clause.scan(/:([a-z0-9_]+)/).flatten.map(&:to_sym)
      if symbols.empty?
        percent_i = only_clause[/\%i\[([^\]]+)\]/, 1]
        symbols = percent_i.to_s.split.map(&:to_sym) if percent_i
      end
      covered.concat(symbols)
    end
    covered
  end

  MUTATION_RATE_LIMITS.each do |filename, config|
    it "declares rate_limit covering #{config[:actions].join(', ')} on #{filename}" do
      source = File.read(Rails.root.join("app/controllers", filename))
      covered = actions_covered(source)
      config[:actions].each do |action|
        expect(covered.include?(action) || covered.include?(:__all__)).to(
          be(true),
          "expected rate_limit covering :#{action} in #{filename}, covered=#{covered.inspect}"
        )
      end
      expect(config[:controller]).to respond_to(:rate_limit)
    end
  end

  PRESERVED_CAPS.each do |filename, pattern|
    it "keeps existing Hotwire auth cap unchanged in #{filename}" do
      source = File.read(Rails.root.join("app/controllers", filename))
      expect(source).to match(pattern)
    end
  end
end
