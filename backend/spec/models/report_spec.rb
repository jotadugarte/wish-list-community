# frozen_string_literal: true

require "rails_helper"

RSpec.describe Report do
  let(:reporter) { create(:user) }
  let(:target_user) { create(:user) }

  describe ".submit! [REQ-SOC-001] [REQ-DISC-001] [REQ-ADM-001]" do
    it "creates a pending polymorphic report with a valid ReportReason and records an AuditEvent" do
      report = nil
      expect do
        report = described_class.submit!(
          reporter: reporter,
          reportable: target_user,
          reason: "impersonation",
          details: "Using my cousin's photos"
        )
      end.to change(AuditEvent, :count).by(1)

      expect(report).to be_persisted
      expect(report.status).to eq("pending")
      expect(report.reason_vo).to eq(ReportReason.new("impersonation"))
    end

    it "prevents a user from reporting themselves" do
      expect do
        described_class.submit!(
          reporter: reporter,
          reportable: reporter,
          reason: "spam"
        )
      end.to raise_error(ArgumentError, /Pre-condition failed/)
    end

    it "prevents duplicate pending reports by the same reporter on the same target" do
      described_class.submit!(reporter: reporter, reportable: target_user, reason: "spam")

      expect do
        described_class.submit!(reporter: reporter, reportable: target_user, reason: "harassment")
      end.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe ".submit! for Wishlist [REQ-DISC-001] [REQ-ADM-001]" do
    let(:owner) { create(:user) }
    let(:friend) { create(:user) }
    let(:wishlist) { create(:wishlist, owner: owner, privacy_mode: "friends") }

    before do
      Friendship.request!(requester: owner, addressee: friend).accept!(actor: friend)
    end

    it "accepts reportable: Wishlist with all five ReportReason values [REQ-DISC-001]" do
      ReportReason::ALLOWED_REASONS.each do |reason|
        target = create(:wishlist, owner: owner, privacy_mode: "friends")
        report = described_class.submit!(
          reporter: friend,
          reportable: target,
          reason: reason
        )
        expect(report).to be_persisted
        expect(report.status).to eq("pending")
        expect(report.reportable).to eq(target)
        expect(report.reason_vo).to eq(ReportReason.new(reason))
      end
    end

    it "records AuditEvent report.created and creates no Notification for the owner [REQ-ADM-001]" do
      expect do
        described_class.submit!(
          reporter: friend,
          reportable: wishlist,
          reason: "spam",
          details: "Suspicious list"
        )
      end.to change(AuditEvent, :count).by(1)
        .and change(Notification, :count).by(0)

      event = AuditEvent.order(:id).last
      expect(event.action).to eq("report.created")
      expect(event.metadata["reportable_type"]).to eq("Wishlist")
      expect(event.metadata["reportable_id"]).to eq(wishlist.id)
      expect(Notification.where(user_id: owner.id)).to be_empty
    end

    it "rejects duplicate pending wishlist reports by the same reporter [REQ-DISC-001]" do
      described_class.submit!(reporter: friend, reportable: wishlist, reason: "spam")

      expect do
        described_class.submit!(reporter: friend, reportable: wishlist, reason: "scam")
      end.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "rejects reporting your own wishlist [REQ-DISC-001]" do
      expect do
        described_class.submit!(reporter: owner, reportable: wishlist, reason: "spam")
      end.to raise_error(ArgumentError, /Pre-condition failed/)
    end
  end
end
