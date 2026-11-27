# frozen_string_literal: true

require "rails_helper"

RSpec.describe Report, "triage domain [REQ-ADM-001] [REQ-DISC-001] [REQ-LIFE-001]" do
  let(:admin) { create(:user, role: "admin", username: "triage_admin", email_address: "triage_admin@example.com") }
  let(:reporter) { create(:user, username: "reporter_one", email_address: "reporter_one@example.com") }
  let(:target) { create(:user, username: "target_one", email_address: "target_one@example.com") }
  let!(:report) { Report.submit!(reporter: reporter, reportable: target, reason: "spam") }

  describe "#dismiss! [REQ-ADM-001]" do
    it "marks the report dismissed, records AuditEvent, creates no Notification, and leaves UserBlock untouched" do
      expect do
        expect(report.dismiss!(actor: admin)).to be(true)
      end.to change(AuditEvent, :count).by(1)
        .and change(Notification, :count).by(0)
        .and change(UserBlock, :count).by(0)

      expect(report.reload.status).to eq("dismissed")
      event = AuditEvent.order(:id).last
      expect(event.action).to eq("report.dismissed")
      expect(event.actor_id).to eq(admin.id)
      expect(event.auditable).to eq(report)
    end
  end

  describe "#review_with_suspend! [REQ-ADM-001]" do
    it "suspends the target user, marks report reviewed, records AuditEvents, and creates no Notification" do
      expect do
        expect(report.review_with_suspend!(actor: admin, target_user: target)).to be(true)
      end.to change(Notification, :count).by(0)
        .and change(UserBlock, :count).by(0)

      expect(report.reload.status).to eq("reviewed")
      expect(target.reload.suspended?).to be(true)
      expect(target.discarded?).to be(false)
      actions = AuditEvent.order(:id).last(3).map(&:action)
      expect(actions).to include("user.suspended", "report.reviewed")
    end

    it "rejects suspending self or the last remaining admin [REQ-ADM-001]" do
      sole = admin
      self_report = Report.submit!(reporter: reporter, reportable: sole, reason: "harassment")
      expect do
        self_report.review_with_suspend!(actor: sole, target_user: sole)
      end.to raise_error(ArgumentError, /Pre-condition failed/)
      expect(sole.reload.suspended?).to be(false)
      expect(self_report.reload.status).to eq("pending")
    end
  end

  describe "#review_with_soft_delete_user! [REQ-ADM-001] [REQ-LIFE-001]" do
    it "soft-deletes the account via SoftDeletable (30-day window), marks reviewed, no Notification" do
      expect do
        expect(report.review_with_soft_delete_user!(actor: admin, target_user: target)).to be(true)
      end.to change(Notification, :count).by(0)
        .and change(UserBlock, :count).by(0)

      expect(report.reload.status).to eq("reviewed")
      expect(target.reload.discarded?).to be(true)
      expect(target.restorable?).to be(true)
      expect(AuditEvent.where(action: "user.soft_deleted", auditable: target).count).to eq(1)
      expect(AuditEvent.where(action: "report.reviewed", auditable: report).count).to eq(1)
    end

    it "rejects soft-deleting self or the last remaining admin [REQ-ADM-001]" do
      sole = admin
      self_report = Report.submit!(reporter: reporter, reportable: sole, reason: "spam")
      expect do
        self_report.review_with_soft_delete_user!(actor: sole, target_user: sole)
      end.to raise_error(ArgumentError, /Pre-condition failed/)
      expect(sole.reload.discarded?).to be(false)
    end
  end

  describe "#review_with_soft_delete_wishlist! [REQ-ADM-001] [REQ-DISC-001] [REQ-LIFE-001]" do
    let(:owner) { create(:user, username: "wl_owner", email_address: "wl_owner@example.com") }
    let(:friend) { create(:user, username: "wl_friend", email_address: "wl_friend@example.com") }
    let(:wishlist) { create(:wishlist, owner: owner, privacy_mode: "friends") }
    let!(:wishlist_report) do
      Friendship.request!(requester: owner, addressee: friend).accept!(actor: friend)
      Report.submit!(reporter: friend, reportable: wishlist, reason: "spam")
    end

    it "soft-deletes the wishlist (30-day window), marks reviewed, no Notification, UserBlock untouched" do
      expect do
        expect(wishlist_report.review_with_soft_delete_wishlist!(actor: admin, wishlist: wishlist)).to be(true)
      end.to change(Notification, :count).by(0)
        .and change(UserBlock, :count).by(0)

      expect(wishlist_report.reload.status).to eq("reviewed")
      expect(wishlist.reload.discarded?).to be(true)
      expect(wishlist.restorable?).to be(true)
      expect(AuditEvent.where(action: "wishlist.soft_deleted", auditable: wishlist).count).to eq(1)
      expect(AuditEvent.where(action: "report.reviewed", auditable: wishlist_report).count).to eq(1)
    end
  end

  describe "enforcement target must match reportable [REQ-ADM-001]" do
    it "rejects suspend when target_user is not the reported user" do
      other = create(:user, username: "wrong_target", email_address: "wrong_target@example.com")
      expect do
        report.review_with_suspend!(actor: admin, target_user: other)
      end.to raise_error(ArgumentError, /target_user must match reportable/)
      expect(other.reload.suspended?).to be(false)
      expect(report.reload.status).to eq("pending")
    end

    it "rejects soft-delete user when target_user is not the reported owner for a wishlist report" do
      owner = create(:user, username: "own_match", email_address: "own_match@example.com")
      friend = create(:user, username: "fr_match", email_address: "fr_match@example.com")
      wishlist = create(:wishlist, owner: owner, privacy_mode: "friends")
      Friendship.request!(requester: owner, addressee: friend).accept!(actor: friend)
      wl_report = Report.submit!(reporter: friend, reportable: wishlist, reason: "spam")
      stranger = create(:user, username: "stranger_t", email_address: "stranger_t@example.com")

      expect do
        wl_report.review_with_soft_delete_user!(actor: admin, target_user: stranger)
      end.to raise_error(ArgumentError, /target_user must match reportable/)
      expect(stranger.reload.discarded?).to be(false)
    end
  end
end
