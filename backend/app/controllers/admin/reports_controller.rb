# frozen_string_literal: true

module Admin
  # Hotwire report triage queue: dismiss, suspend, soft-delete account/wishlist.
  # Traceability: [REQ-ADM-001], [REQ-DISC-001]
  class ReportsController < BaseController
    rate_limit to: 20, within: 3.minutes,
               only: %i[dismiss suspend soft_delete_user soft_delete_wishlist],
               name: "admin_reports_writes",
               by: -> { current_user&.id || request.remote_ip },
               with: -> { rate_limit_admin_write }

    # [REQ-ADM-001] Lists pending User and Wishlist reports for triage.
    def index
      authorize :admin, :index?, policy_class: AdminPolicy
      @reports = Report.where(status: "pending").includes(:reporter, :reportable)
                      .order(created_at: :desc).limit(100)
    end

    # [REQ-ADM-001] Shows one report with clear user-vs-wishlist action targets.
    def show
      @report = Report.find(params[:id])
      authorize :admin, :show?, policy_class: AdminPolicy
    end

    # [REQ-ADM-001] Dismisses a pending report without enforcement.
    def dismiss
      @report = Report.find(params[:id])
      authorize :admin, :dismiss?, policy_class: AdminPolicy
      @report.dismiss!(actor: current_user)
      redirect_to admin_reports_path, notice: I18n.t("admin.notices.report_dismissed"), status: :see_other
    end

    # [REQ-ADM-001] Suspends the reported user and marks the report reviewed.
    def suspend
      @report = Report.find(params[:id])
      authorize :admin, :suspend?, policy_class: AdminPolicy
      target = enforcement_user!(@report)
      @report.review_with_suspend!(actor: current_user, target_user: target)
      redirect_to admin_reports_path, notice: I18n.t("admin.notices.user_suspended"), status: :see_other
    end

    # [REQ-ADM-001] Soft-deletes the reported user account (30-day window).
    def soft_delete_user
      @report = Report.find(params[:id])
      authorize :admin, :soft_delete_user?, policy_class: AdminPolicy
      target = enforcement_user!(@report)
      @report.review_with_soft_delete_user!(actor: current_user, target_user: target)
      redirect_to admin_reports_path, notice: I18n.t("admin.notices.account_soft_deleted"), status: :see_other
    end

    # [REQ-ADM-001] Soft-deletes the reported wishlist (30-day window).
    def soft_delete_wishlist
      @report = Report.find(params[:id])
      authorize :admin, :soft_delete_wishlist?, policy_class: AdminPolicy
      wishlist = enforcement_wishlist!(@report)
      @report.review_with_soft_delete_wishlist!(actor: current_user, wishlist: wishlist)
      redirect_to admin_reports_path, notice: I18n.t("admin.notices.wishlist_soft_deleted"), status: :see_other
    end

    private

    def enforcement_user!(report)
      if report.reportable_type == "User"
        report.reportable
      elsif report.reportable_type == "Wishlist"
        report.reportable.owner
      else
        raise ArgumentError, "Pre-condition failed: unsupported reportable"
      end
    end

    def enforcement_wishlist!(report)
      raise ArgumentError, "Pre-condition failed: reportable must be Wishlist" unless report.reportable_type == "Wishlist"

      report.reportable
    end
  end
end
