# frozen_string_literal: true

module Api
  module V1
    # GET/PATCH notification preferences for the current user.
    # Traceability: [REQ-NOTIF-001]
    class NotificationPreferencesController < BaseController
      skip_after_action :verify_policy_scoped
      rate_limit to: 20, within: 3.minutes, only: :update, name: "api_notification_prefs_update",
                    by: -> { current_user&.id || request.remote_ip }, with: -> {
        render json: { error: I18n.t("api.v1.errors.rate_limited") }, status: :too_many_requests
      }

      def show
        authorize :notification_preference, :show?
        pref = NotificationPreference.for_user(current_user)
        render json: { notification_preference: serialize_pref(pref) }, status: :ok
      end

      def update
        authorize :notification_preference, :update?
        pref = NotificationPreference.find_or_initialize_by(user_id: current_user.id)
        incoming = params.require(:notification_preference).permit(channels: {}).to_h
        channels = pref.channels.is_a?(Hash) ? pref.channels.deep_dup : {}
        if incoming["channels"].is_a?(Hash) || incoming[:channels].is_a?(Hash)
          raw = (incoming["channels"] || incoming[:channels])
          raw.each do |event_key, channel_hash|
            next unless channel_hash.is_a?(Hash)

            key = event_key.to_s
            existing = channels[key].is_a?(Hash) ? channels[key].stringify_keys : {}
            existing = existing.slice(*NotificationPreference::CHANNELS)
            patch = channel_hash.stringify_keys.slice(*NotificationPreference::CHANNELS)
            # Deep-merge per channel so single-channel PATCHes (Flutter toggles)
            # do not wipe sibling opt-outs for the same event.
            channels[key] = existing.merge(patch)
          end
        end
        pref.channels = channels
        pref.save!
        render json: { notification_preference: serialize_pref(pref) }, status: :ok
      end

      private

      def serialize_pref(pref)
        {
          channels: pref.channels || {},
          defaults_events: NotificationPreference::DEFAULT_EVENTS
        }
      end
    end
  end
end
