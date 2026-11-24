# frozen_string_literal: true

require "rails_helper"

RSpec.describe SoftDeletable, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  after { travel_back }

  let(:user) do
    User.create!(
      email_address: "lifecycle@example.com",
      username: "lifecycle_user",
      password: "SecurePassword123!",
      password_confirmation: "SecurePassword123!",
      locale: "es",
      time_zone: "UTC",
      terms_accepted_at: Time.current
    )
  end

  describe "#soft_delete!, #restore!, and no-ghost-reservation callbacks [REQ-LIFE-001] [REQ-LIFE-002]" do
    it "soft-deletes the user, revokes sessions/api_tokens/device_tokens, and runs on_soft_delete hooks [REQ-LIFE-001] [REQ-LIFE-002]" do
      _api_token, raw_token = ApiToken.issue_for!(user, fcm_token: "fcm_lifecycle_123")
      user.sessions.create!(ip_address: "127.0.0.1")

      reservations_canceled = false
      User.register_soft_delete_hook(:cancel_active_reservations_test) do |record|
        reservations_canceled = true if record == user
      end

      expect(user.soft_delete!).to be(true)
      expect(user.discarded?).to be(true)
      expect(reservations_canceled).to be(true)
      expect(ApiToken.authenticate(raw_token)).to be_nil
      expect(DeviceToken.where(user: user).count).to eq(0)
      expect(Session.where(user: user).count).to eq(0)
      expect(AuditEvent.where(action: "user.soft_deleted", auditable: user).count).to eq(1)
    ensure
      User.unregister_soft_delete_hook(:cancel_active_reservations_test)
    end

    it "restores a soft-deleted record within the 30-day grace window without resurrecting ghost reservations [REQ-LIFE-001] [REQ-LIFE-002]" do
      freeze_time
      ghost_reservations_state = "active_before_delete"

      User.register_soft_delete_hook(:purge_reservations_on_delete) do |_record|
        ghost_reservations_state = "permanently_canceled"
      end

      User.register_restore_hook(:restore_items_clean) do |_record|
        # Restores child items without touching canceled reservations
        expect(ghost_reservations_state).to eq("permanently_canceled")
      end

      user.soft_delete!
      travel 15.days

      expect(user.restore!).to be(true)
      expect(user.discarded?).to be(false)
      expect(ghost_reservations_state).to eq("permanently_canceled")
      expect(AuditEvent.where(action: "user.restored", auditable: user).count).to eq(1)
    ensure
      User.unregister_soft_delete_hook(:purge_reservations_on_delete)
      User.unregister_restore_hook(:restore_items_clean)
    end

    it "denies restoration after the 30-day grace window has expired [REQ-LIFE-002]" do
      freeze_time
      user.soft_delete!

      travel 31.days
      expect(user.restore!).to be(false)
      expect(user.discarded?).to be(true)
      expect(user.errors[:base].join).to match(/30 days|expired/i)
    end
  end

  describe "PiiPurgeJob [REQ-LIFE-002]" do
    it "permanently anonymizes PII for accounts soft-deleted more than 30 days ago [REQ-LIFE-002]" do
      freeze_time
      expired_user = user
      expired_user.soft_delete!

      recent_user = User.create!(
        email_address: "recent@example.com",
        username: "recent_user",
        password: "SecurePassword123!",
        password_confirmation: "SecurePassword123!",
        locale: "es",
        time_zone: "UTC",
        terms_accepted_at: Time.current
      )

      travel 20.days
      recent_user.soft_delete!

      travel 12.days # expired_user is at 32 days; recent_user is at 12 days
      PiiPurgeJob.perform_now

      expect(expired_user.reload.email_address).to start_with("purged_")
      expect(expired_user.username).to start_with("purged_")
      expect(recent_user.reload.email_address).to eq("recent@example.com")
    end
  end
end
