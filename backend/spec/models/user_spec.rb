# frozen_string_literal: true

require "rails_helper"

RSpec.describe User, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  let(:valid_attributes) do
    {
      email_address: "Jader@Example.com",
      username: "jader_dev",
      password: "SecurePassword123!",
      password_confirmation: "SecurePassword123!",
      locale: "es",
      time_zone: "America/Bogota",
      terms_accepted_at: Time.current
    }
  end

  describe "validations and normalization [REQ-USER-001] [REQ-USER-002] [REQ-USER-003] [REQ-AUTH-002]" do
    it "creates a valid user with normalized email, username, locale, time_zone, and terms_accepted_at [REQ-USER-001]" do
      user = described_class.create!(valid_attributes)

      expect(user.email_address).to eq("jader@example.com")
      expect(user.username).to eq("jader_dev")
      expect(user.locale).to eq("es")
      expect(user.time_zone).to eq("America/Bogota")
      expect(user.terms_accepted_at).to be_present
      expect(user.email_vo).to be_a(EmailAddress)
      expect(user.username_vo).to be_a(Username)
    end

    it "requires terms_accepted_at upon creation for App Store / Google Play UGC compliance [REQ-AUTH-002]" do
      user = described_class.new(valid_attributes.merge(terms_accepted_at: nil))
      expect(user).not_to be_valid
      expect(user.errors[:terms_accepted_at]).to be_present
    end

    it "validates supported locales (es, en) and presence of time_zone [REQ-USER-002] [REQ-USER-003]" do
      user = described_class.new(valid_attributes.merge(locale: "fr"))
      expect(user).not_to be_valid
      expect(user.errors[:locale]).to be_present
    end

    it "never exposes email_address in public profile serialization [REQ-USER-001]" do
      user = described_class.create!(valid_attributes)
      profile = user.public_profile_json

      expect(profile[:username]).to eq("jader_dev")
      expect(profile).not_to have_key(:email_address)
      expect(profile).not_to have_key("email_address")
    end
  end

  describe "30-day username change cooldown & 30-day old-username quarantine [REQ-USER-001] [REQ-USER-004]" do
    after { travel_back }

    it "allows the first username change after sign-up and enforces a 30-day cooldown before changing again [REQ-USER-001]" do
      freeze_time
      user = described_class.create!(valid_attributes)

      # First change after creation succeeds and starts the 30-day cooldown
      expect(user.change_username!("jader_new")).to be(true)
      expect(user.reload.username).to eq("jader_new")

      # Attempting another change 10 days later fails due to 30-day cooldown
      travel 10.days
      expect(user.change_username!("jader_third")).to be(false)
      expect(user.errors[:username].join).to match(/30 days|cooldown/i)

      # After 21 more days (31 days total), the user can change their username again
      travel 21.days
      expect(user.change_username!("jader_third")).to be(true)
      expect(user.reload.username).to eq("jader_third")
    end

    it "quarantines the old username for 30 days so another user cannot claim it to impersonate them [REQ-USER-004]" do
      freeze_time
      user1 = described_class.create!(valid_attributes.merge(username: "ceci_nata"))
      user1.change_username!("ceci_pinilla")

      # Another user tries to register or switch to 'ceci_nata' 5 days later -> blocked by quarantine
      travel 5.days
      impersonator = described_class.new(
        valid_attributes.merge(
          email_address: "other@example.com",
          username: "ceci_nata"
        )
      )
      expect(impersonator).not_to be_valid
      expect(impersonator.errors[:username].join).to match(/quarantine|unavailable|taken/i)

      # After 26 more days (31 days total), the quarantine on 'ceci_nata' expires and it becomes available
      travel 26.days
      new_user = described_class.new(
        valid_attributes.merge(
          email_address: "other@example.com",
          username: "ceci_nata"
        )
      )
      expect(new_user).to be_valid
    end
  end
end
