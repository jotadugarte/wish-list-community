# frozen_string_literal: true

require "rails_helper"

RSpec.describe AuditEvent, type: :model do
  let(:actor) do
    User.create!(
      email_address: "actor@example.com",
      username: "actor_user",
      password: "SecurePassword123!",
      password_confirmation: "SecurePassword123!",
      locale: "es",
      time_zone: "UTC",
      terms_accepted_at: Time.current
    )
  end

  describe ".record! and immutability [REQ-ADM-001]" do
    it "creates an audit event with actor, action, auditable, and metadata [REQ-ADM-001]" do
      event = described_class.record!(
        actor: actor,
        action: "user.profile_updated",
        auditable: actor,
        metadata: { old_username: "old_handle" }
      )

      expect(event).to be_persisted
      expect(event.action).to eq("user.profile_updated")
      expect(event.metadata["old_username"]).to eq("old_handle")
    end

    it "is strictly immutable after creation (prevents updates and deletes) [REQ-ADM-001]" do
      event = described_class.record!(
        actor: actor,
        action: "user.profile_updated",
        auditable: actor
      )

      expect { event.update!(action: "tampered") }.to raise_error(ActiveRecord::ReadOnlyRecord)
      expect { event.destroy! }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end
  end
end
