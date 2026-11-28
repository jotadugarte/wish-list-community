# frozen_string_literal: true

# Activity notification fan-out via NotificationDispatcher (Sprint A + B O6A).
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

    # --- Sprint B O6A catalog [REQ-NOTIF-001] ---

    # [REQ-NOTIF-001] Reserver: reserved activity item was edited.
    def item_touched_while_reserved!(item:, reservation:)
      raise ArgumentError, "Pre-condition failed: item required" if item.nil?
      raise ArgumentError, "Pre-condition failed: reservation required" if reservation.nil?

      activity = activity_for(item)
      return if activity.nil?

      user = reservation.user
      return if user.nil? || user.discarded?

      with_user_locale(user) do
        dispatch!(
          user: user,
          event_key: "activity.item_touched_while_reserved",
          title: I18n.t("notifications.activity.item_touched_while_reserved.title", name: activity.name),
          body: I18n.t("notifications.activity.item_touched_while_reserved.body", item: item.title),
          payload: activity_payload(activity, reservation_id: reservation.id, item_id: item.id)
        )
      end
    end

    # [REQ-NOTIF-001] Reserver: reserved activity item was soft-deleted / archived.
    def item_deleted_while_reserved!(item:, reservation:)
      raise ArgumentError, "Pre-condition failed: item required" if item.nil?
      raise ArgumentError, "Pre-condition failed: reservation required" if reservation.nil?

      activity = activity_for(item)
      return if activity.nil?

      user = reservation.user
      return if user.nil? || user.discarded?

      with_user_locale(user) do
        dispatch!(
          user: user,
          event_key: "activity.item_deleted",
          title: I18n.t("notifications.activity.item_deleted.title", name: activity.name),
          body: I18n.t("notifications.activity.item_deleted.body", item: item.title),
          payload: activity_payload(activity, reservation_id: reservation.id, item_id: item.id)
        )
      end
    end

    # [REQ-NOTIF-001] Item owner when reservation_visibility is visible_to_recipient.
    def reservation_created!(reservation:)
      notify_owner_on_visible_hold!(
        reservation: reservation,
        event_key: "activity.reservation_created",
        title_key: "notifications.activity.reservation_created.title",
        body_key: "notifications.activity.reservation_created.body"
      )
    end

    # [REQ-NOTIF-001] Item owner when a visible activity hold is released.
    def reservation_released!(reservation:)
      notify_owner_on_visible_hold!(
        reservation: reservation,
        event_key: "activity.reservation_released",
        title_key: "notifications.activity.reservation_released.title",
        body_key: "notifications.activity.reservation_released.body"
      )
    end

    # [REQ-NOTIF-001] Reserver enters 72h grace on an activity hold.
    def reservation_grace_started!(reservation:)
      notify_reserver!(
        reservation: reservation,
        event_key: "activity.reservation_grace_started",
        title_key: "notifications.activity.reservation_grace_started.title",
        body_key: "notifications.activity.reservation_grace_started.body"
      )
    end

    # [REQ-NOTIF-001] Reserver: activity hold auto-released after grace.
    def reservation_auto_released!(reservation:)
      notify_reserver!(
        reservation: reservation,
        event_key: "activity.reservation_auto_released",
        title_key: "notifications.activity.reservation_auto_released.title",
        body_key: "notifications.activity.reservation_auto_released.body"
      )
    end

    # [REQ-NOTIF-001] Gifter confirmation after mark purchased in activity.
    def gift_purchased!(gift:)
      raise ArgumentError, "Pre-condition failed: gift required" if gift.nil?

      activity = activity_for(gift.item)
      return if activity.nil?

      gifter = gift.gifter
      return if gifter.nil? || gifter.discarded?

      with_user_locale(gifter) do
        dispatch!(
          user: gifter,
          event_key: "activity.gift_purchased",
          title: I18n.t("notifications.activity.gift_purchased.title", name: activity.name),
          body: I18n.t("notifications.activity.gift_purchased.body", item: gift.item.title),
          payload: activity_payload(activity, gift_id: gift.id, item_id: gift.item_id)
        )
      end
    end

    # [REQ-NOTIF-001] Item owner: activity gift marked delivered.
    def gift_delivered!(gift:)
      raise ArgumentError, "Pre-condition failed: gift required" if gift.nil?

      activity = activity_for(gift.item)
      return if activity.nil?

      owner = gift.item.wishlist.owner
      return if owner.nil? || owner.discarded?

      with_user_locale(owner) do
        dispatch!(
          user: owner,
          event_key: "activity.gift_delivered",
          title: I18n.t("notifications.activity.gift_delivered.title", name: activity.name),
          body: I18n.t("notifications.activity.gift_delivered.body", item: gift.item.title),
          payload: activity_payload(activity, gift_id: gift.id, item_id: gift.item_id)
        )
      end
    end

    # [REQ-NOTIF-001] Gifter: owner confirmed receipt in activity.
    def gift_received!(gift:)
      raise ArgumentError, "Pre-condition failed: gift required" if gift.nil?

      activity = activity_for(gift.item)
      return if activity.nil?

      gifter = gift.gifter
      return if gifter.nil? || gifter.discarded?

      with_user_locale(gifter) do
        dispatch!(
          user: gifter,
          event_key: "activity.gift_received",
          title: I18n.t("notifications.activity.gift_received.title", name: activity.name),
          body: I18n.t("notifications.activity.gift_received.body", item: gift.item.title),
          payload: activity_payload(activity, gift_id: gift.id, item_id: gift.item_id)
        )
      end
    end

    # [REQ-NOTIF-001] Item owner: reserve blocked by activity budget.
    def budget_rejected!(item:, actor:)
      raise ArgumentError, "Pre-condition failed: item required" if item.nil?

      activity = activity_for(item)
      return if activity.nil?

      owner = item.wishlist.owner
      return if owner.nil? || owner.discarded?

      with_user_locale(owner) do
        dispatch!(
          user: owner,
          event_key: "activity.budget_rejected",
          title: I18n.t("notifications.activity.budget_rejected.title", name: activity.name),
          body: I18n.t(
            "notifications.activity.budget_rejected.body",
            item: item.title,
            actor: actor&.username.presence || I18n.t("notifications.activity.actor_anonymous")
          ),
          payload: activity_payload(activity, item_id: item.id, actor_id: actor&.id)
        )
      end
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

    def activity_for(item)
      wishlist = item&.wishlist
      return nil if wishlist.nil? || !wishlist.activity_scoped?

      wishlist.activity
    end

    def activity_payload(activity, **extra)
      { activity_id: activity.id }.merge(extra.compact)
    end

    def with_user_locale(user, &block)
      I18n.with_locale(user.locale.presence || I18n.default_locale, &block)
    end

    def visible_hold_to_owner?(activity)
      activity.reservation_visibility_vo.visible_to_recipient?
    end

    def notify_owner_on_visible_hold!(reservation:, event_key:, title_key:, body_key:)
      raise ArgumentError, "Pre-condition failed: reservation required" if reservation.nil?

      item = reservation.item
      activity = activity_for(item)
      return if activity.nil?
      return unless visible_hold_to_owner?(activity)

      owner = item.wishlist.owner
      return if owner.nil? || owner.discarded?

      with_user_locale(owner) do
        dispatch!(
          user: owner,
          event_key: event_key,
          title: I18n.t(title_key, name: activity.name),
          body: I18n.t(body_key, item: item.title),
          payload: activity_payload(activity, reservation_id: reservation.id, item_id: item.id)
        )
      end
    end

    def notify_reserver!(reservation:, event_key:, title_key:, body_key:)
      raise ArgumentError, "Pre-condition failed: reservation required" if reservation.nil?

      activity = activity_for(reservation.item)
      return if activity.nil?

      user = reservation.user
      return if user.nil? || user.discarded?

      with_user_locale(user) do
        dispatch!(
          user: user,
          event_key: event_key,
          title: I18n.t(title_key, name: activity.name),
          body: I18n.t(body_key),
          payload: activity_payload(activity, reservation_id: reservation.id, item_id: reservation.item_id)
        )
      end
    end
  end
end
