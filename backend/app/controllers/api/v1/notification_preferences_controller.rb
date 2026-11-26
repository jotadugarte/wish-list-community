# frozen_string_literal: true

module Api
  module V1
    # GET/PATCH notification preferences for the current user.
    # Traceability: [REQ-NOTIF-001]
    class NotificationPreferencesController < BaseController
      skip_after_action :verify_policy_scoped

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
        Array(incoming["channels"] || incoming[:channels]).each { |_| } # no-op keep structure
        if incoming["channels"].is_a?(Hash) || incoming[:channels].is_a?(Hash)
          raw = (incoming["channels"] || incoming[:channels])
          raw.each do |event_key, channel_hash|
            next unless channel_hash.is_a?(Hash)

            channels[event_key.to_s] = channel_hash.stringify_keys.slice(*NotificationPreference::CHANNELS)
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
          defaults_events: NotificationPreference::S5_EVENTS
        }
      end
    end
  end
end
