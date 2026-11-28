# frozen_string_literal: true

# Sprint A activity notification fan-out via NotificationDispatcher.
# Traceability: [REQ-NOTIF-001], [REQ-NOTIF-002], [REQ-ACT-001], [REQ-ACT-003]
class ActivityNotifier
  class << self
    def invite!(activity:, recipient:, actor:)
      dispatch!(
        user: recipient,
        event_key: "activity.invite",
        title: I18n.t("notifications.activity.invite.title", name: activity.name),
        body: I18n.t("notifications.activity.invite.body", actor: actor.username),
        payload: { activity_id: activity.id }
      )
    end

    def accepted!(activity:, participant:, actor:)
      notify_admins(
        activity: activity,
        event_key: "activity.accepted",
        title: I18n.t("notifications.activity.accepted.title", name: activity.name),
        body: I18n.t("notifications.activity.accepted.body", actor: actor.username),
        payload: { activity_id: activity.id, user_id: participant.user_id },
        except_user_id: actor.id
      )
    end

    def declined!(activity:, actor:)
      notify_admins(
        activity: activity,
        event_key: "activity.declined",
        title: I18n.t("notifications.activity.declined.title", name: activity.name),
        body: I18n.t("notifications.activity.declined.body", actor: actor.username),
        payload: { activity_id: activity.id },
        except_user_id: actor.id
      )
    end

    def co_organizer_appointed!(activity:, user:, actor:)
      dispatch!(
        user: user,
        event_key: "activity.co_organizer_appointed",
        title: I18n.t("notifications.activity.co_organizer_appointed.title", name: activity.name),
        body: I18n.t("notifications.activity.co_organizer_appointed.body"),
        payload: { activity_id: activity.id, actor_id: actor.id }
      )
    end

    def drawn!(activity:)
      ActivityAssignment.where(activity: activity).includes(:recipient).limit(500).find_each do |assignment|
        dispatch!(
          user: assignment.giver,
          event_key: "activity.drawn",
          title: I18n.t("notifications.activity.drawn.title", name: activity.name),
          body: I18n.t("notifications.activity.drawn.body", recipient: assignment.recipient.username),
          payload: {
            activity_id: activity.id,
            recipient_username: assignment.recipient.username
          }
        )
      end
    end

    def arrancar!(activity:)
      notify_accepted(
        activity: activity,
        event_key: "activity.arrancar",
        title: I18n.t("notifications.activity.arrancar.title", name: activity.name),
        body: I18n.t("notifications.activity.arrancar.body"),
        payload: { activity_id: activity.id }
      )
    end

    def left!(activity:, actor:)
      notify_admins(
        activity: activity,
        event_key: "activity.left",
        title: I18n.t("notifications.activity.left.title", name: activity.name),
        body: I18n.t("notifications.activity.left.body", actor: actor.username),
        payload: { activity_id: activity.id },
        except_user_id: actor.id
      )
      return unless activity.reload.needs_dropout_recovery?

      notify_admins(
        activity: activity,
        event_key: "activity.dropout_needs_cure",
        title: I18n.t("notifications.activity.dropout_needs_cure.title", name: activity.name),
        body: I18n.t("notifications.activity.dropout_needs_cure.body"),
        payload: { activity_id: activity.id }
      )
    end

    def blind_bridged!(activity:, result:)
      giver = User.find_by(id: result.notified_giver_id)
      return if giver.nil?

      dispatch!(
        user: giver,
        event_key: "activity.blind_bridged",
        title: I18n.t("notifications.activity.blind_bridged.title", name: activity.name),
        body: I18n.t("notifications.activity.blind_bridged.body"),
        payload: { activity_id: activity.id, recipient_id: result.new_recipient_id }
      )
    end

    def full_redraw!(activity:)
      # Draw service already sent private activity.drawn notices for each giver.
      notify_admins(
        activity: activity,
        event_key: "activity.full_redraw",
        title: I18n.t("notifications.activity.full_redraw.title", name: activity.name),
        body: I18n.t("notifications.activity.full_redraw.body"),
        payload: { activity_id: activity.id }
      )
    end

    def cancelled!(activity:, actor:)
      notify_accepted(
        activity: activity,
        event_key: "activity.cancelled",
        title: I18n.t("notifications.activity.cancelled.title", name: activity.name),
        body: I18n.t("notifications.activity.cancelled.body", actor: actor.username),
        payload: { activity_id: activity.id }
      )
    end

    def ownership_transferred!(activity:, new_creator:, actor:)
      dispatch!(
        user: new_creator,
        event_key: "activity.ownership_transferred",
        title: I18n.t("notifications.activity.ownership_transferred.title", name: activity.name),
        body: I18n.t("notifications.activity.ownership_transferred.body", actor: actor.username),
        payload: { activity_id: activity.id }
      )
    end

    private

    def dispatch!(user:, event_key:, title:, body:, payload:)
      NotificationDispatcher.dispatch!(
        user: user,
        event_key: event_key,
        title: title,
        body: body,
        payload: payload
      )
    end

    def notify_admins(activity:, event_key:, title:, body:, payload:, except_user_id: nil)
      admin_ids = [ activity.creator_id ]
      co_ids = activity.participants.where(status: "accepted", co_organizer: true).limit(100).pluck(:user_id)
      (admin_ids + co_ids).uniq.first(100).each do |user_id|
        next if except_user_id && user_id == except_user_id

        user = User.find_by(id: user_id)
        next if user.nil?

        dispatch!(user: user, event_key: event_key, title: title, body: body, payload: payload)
      end
    end

    def notify_accepted(activity:, event_key:, title:, body:, payload:)
      activity.participants.where(status: "accepted").includes(:user).limit(500).find_each do |participant|
        dispatch!(user: participant.user, event_key: event_key, title: title, body: body, payload: payload)
      end
    end
  end
end
