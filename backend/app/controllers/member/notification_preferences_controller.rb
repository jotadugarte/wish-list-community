# frozen_string_literal: true

module Member
  # Hotwire notification preference toggles.
  # Traceability: [REQ-NOTIF-001]
  class NotificationPreferencesController < BaseController
    rate_limit to: 20, within: 3.minutes, only: :update,
               name: "member_notification_prefs_update",
               by: -> { current_user&.id || request.remote_ip },
               with: -> {
                 redirect_back fallback_location: member_settings_path,
                               alert: I18n.t("api.v1.errors.rate_limited"),
                               status: :see_other
               }

    def show
      authorize :notification_preference, :show?
      @pref = NotificationPreference.for_user(current_user)
      @events = NotificationPreference::DEFAULT_EVENTS
    end

    def update
      authorize :notification_preference, :update?
      pref = NotificationPreference.find_or_initialize_by(user_id: current_user.id)
      channels = pref.channels.is_a?(Hash) ? pref.channels.deep_dup : {}
      raw = params.dig(:notification_preference, :channels) || {}
      NotificationPreference::DEFAULT_EVENTS.each do |event_key|
        channel_hash = raw[event_key] || raw[event_key.to_s] || {}
        next unless channel_hash.is_a?(ActionController::Parameters) || channel_hash.is_a?(Hash)

        channels[event_key.to_s] = normalize_channels(channel_hash)
      end
      pref.channels = channels
      pref.save!
      redirect_to member_notification_preferences_path, notice: I18n.t("member.notifications.prefs_saved"), status: :see_other
    end

    private

    def normalize_channels(channel_hash)
      raw_hash = if channel_hash.is_a?(ActionController::Parameters)
        channel_hash.to_unsafe_h
      else
        channel_hash.to_h
      end
      hash = raw_hash.stringify_keys.slice(*NotificationPreference::CHANNELS)
      NotificationPreference::CHANNELS.index_with do |channel|
        raw = hash[channel]
        raw = raw.last if raw.is_a?(Array)
        ActiveModel::Type::Boolean.new.cast(raw) == true
      end
    end
  end
end
