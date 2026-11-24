# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApiToken, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  after { travel_back }

  let(:user) do
    User.create!(
      email_address: "ceci@example.com",
      username: "ceci_nata",
      password: "SecurePassword123!",
      password_confirmation: "SecurePassword123!",
      locale: "es",
      time_zone: "America/Bogota",
      terms_accepted_at: Time.current
    )
  end

  describe ".issue_for! and .authenticate [REQ-AUTH-001] [REQ-NOTIF-002]" do
    it "stores only the SHA-256 token_digest in PostgreSQL and authenticates via the raw token [REQ-AUTH-001]" do
      api_token, raw_token = described_class.issue_for!(user, device_name: "Ceci iPhone 16")

      expect(raw_token).to be_present
      expect(api_token.token_digest).to eq(Digest::SHA256.hexdigest(raw_token))
      expect(api_token.token_digest).not_to eq(raw_token)
      expect(described_class.authenticate(raw_token)).to eq(api_token)
    end

    it "rejects expired or revoked tokens [REQ-AUTH-001]" do
      freeze_time
      api_token, raw_token = described_class.issue_for!(user, expires_in: 7.days)

      travel 8.days
      expect(described_class.authenticate(raw_token)).to be_nil

      travel_back
      api_token.revoke!
      expect(described_class.authenticate(raw_token)).to be_nil
    end

    it "automatically unbinds/deletes associated FCM DeviceTokens when revoked [REQ-NOTIF-002]" do
      api_token, _raw_token = described_class.issue_for!(
        user,
        device_name: "Shared iPad",
        fcm_token: "fcm_push_token_shared_ipad_123"
      )

      expect(DeviceToken.where(api_token: api_token).count).to eq(1)

      api_token.revoke!

      expect(api_token.reload.revoked_at).to be_present
      expect(DeviceToken.where(api_token: api_token).count).to eq(0)
    end
  end
end
