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
end
