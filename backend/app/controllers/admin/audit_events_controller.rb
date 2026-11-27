# frozen_string_literal: true

module Admin
  # Hotwire AuditEvent viewer with moderation-only 1-click revert (O4A).
  # Traceability: [REQ-ADM-001]
  class AuditEventsController < BaseController
    REVERTABLE = {
      "user.suspended" => :unsuspend_user,
      "user.soft_deleted" => :restore_user,
      "wishlist.soft_deleted" => :restore_wishlist,
      "report.dismissed" => :reopen_report
    }.freeze

    helper_method :revertable_event?

    rate_limit to: 20, within: 3.minutes, only: :revert, name: "admin_audit_revert",
               by: -> { current_user&.id || request.remote_ip },
               with: -> { rate_limit_admin_write }

    # [REQ-ADM-001] Lists recent AuditEvents, optionally filtered by action.
    def index
      authorize :admin, :index?, policy_class: AdminPolicy
      scope = AuditEvent.order(created_at: :desc).limit(100)
      filter = params[:action_filter].to_s.strip
      scope = scope.where(action: filter) if filter.present?
      @action_filter = filter
      @audit_events = scope
    end

    # [REQ-ADM-001] Shows one AuditEvent with optional revert control.
    def show
      @audit_event = AuditEvent.find(params[:id])
      authorize :admin, :show?, policy_class: AdminPolicy
      @revertable = revertable_event?(@audit_event)
    end

    # [REQ-ADM-001] Runs a compensating moderation revert; never mutates old AuditEvents.
    def revert
      @audit_event = AuditEvent.find(params[:id])
      authorize :admin, :revert?, policy_class: AdminPolicy
      perform_revert!(@audit_event)
      redirect_to admin_audit_events_path, notice: I18n.t("admin.notices.revert_applied"), status: :see_other
    end

    private

    def perform_revert!(event)
      raise ArgumentError, "Pre-condition failed: event is not revertable" unless revertable_event?(event)

      send(REVERTABLE.fetch(event.action), event)
    end

    # Soft-delete reverts require an immutable admin_enforcement snapshot, a discarded record,
    # and that this event is the latest soft_delete for the auditable (O4A).
    def revertable_event?(event)
      return false unless REVERTABLE.key?(event.action)
      return true unless event.action.end_with?(".soft_deleted")

      return false unless ActiveModel::Type::Boolean.new.cast(event.metadata["admin_enforcement"])

      record = event.auditable
      return false unless record&.discarded?

      latest = record.latest_soft_delete_event
      latest&.id == event.id
    end

    def unsuspend_user(event)
      user = User.find(event.auditable_id)
      user.unsuspend!(actor: current_user)
    end

    def restore_user(event)
      user = User.find(event.auditable_id)
      raise ArgumentError, restore_failure_key(user) unless user.restore!(actor: current_user)
    end

    def restore_wishlist(event)
      wishlist = Wishlist.find(event.auditable_id)
      raise ArgumentError, restore_failure_key(wishlist) unless wishlist.restore!(actor: current_user)
    end

    def restore_failure_key(record)
      return "Pre-condition failed: record is not soft-deleted" unless record.discarded?
      return "Pre-condition failed: restoration window expired" unless record.restorable?

      "Pre-condition failed: restore denied"
    end

    def reopen_report(event)
      report = Report.find(event.auditable_id)
      report.reopen!(actor: current_user)
    end
  end
end
