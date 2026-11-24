# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserPolicy do
  let(:alice) do
    User.create!(
      email_address: "alice_p@example.com",
      username: "alice_policy",
      password: "SecurePassword123!",
      password_confirmation: "SecurePassword123!",
      locale: "es",
      time_zone: "UTC",
      terms_accepted_at: Time.current
    )
  end

  let(:bob) do
    User.create!(
      email_address: "bob_p@example.com",
      username: "bob_policy",
      password: "SecurePassword123!",
      password_confirmation: "SecurePassword123!",
      locale: "es",
      time_zone: "UTC",
      terms_accepted_at: Time.current
    )
  end

  describe "Default-Deny ApplicationPolicy & Block Wins invariant [REQ-BLOCK-001]" do
    it "defaults ApplicationPolicy actions to false (default-deny) [REQ-BLOCK-001]" do
      base_policy = ApplicationPolicy.new(alice, bob)
      expect(base_policy.index?).to be(false)
      expect(base_policy.show?).to be(false)
      expect(base_policy.create?).to be(false)
      expect(base_policy.update?).to be(false)
      expect(base_policy.destroy?).to be(false)
    end

    it "permits viewing a non-blocked user's basic profile and denies access in both directions once blocked [REQ-BLOCK-001]" do
      expect(described_class.new(alice, bob).show?).to be(true)
      expect(described_class.new(bob, alice).show?).to be(true)

      UserBlock.block!(blocker: alice, blocked: bob)

      expect(described_class.new(alice, bob).show?).to be(false)
      expect(described_class.new(bob, alice).show?).to be(false)
    end
  end
end
