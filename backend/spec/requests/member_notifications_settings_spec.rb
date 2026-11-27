# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Hotwire inbox prefs and account settings [REQ-NOTIF-001] [REQ-LIFE-001]", type: :request do
  let(:user) { create(:user) }

  def login_web!(u)
    post "/session", params: { email_address: u.email_address, password: "SecurePassword123!" }
  end

  before { login_web!(user) }

  it "shows notification inbox and marks a note read" do
    note = Notification.create!(user: user, event_key: "friend.request_received", title: "Hola", body: "x")
    get "/app/notifications"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Hola")

    post "/app/notifications/#{note.id}/mark_read"
    expect(note.reload.read_at).to be_present
  end

  it "shows and updates notification preference toggles" do
    get "/app/settings/notification_preferences"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("friend.request_received")
    expect(response.body).to include('type="hidden"')

    patch "/app/settings/notification_preferences", params: {
      notification_preference: {
        channels: { "friend.request_received" => { "email" => "0", "in_app" => "1", "push" => "1" } }
      }
    }
    expect(response).to be_redirect
    pref = NotificationPreference.find_by!(user_id: user.id)
    expect(pref.enabled_channels_for("friend.request_received")["email"]).to eq(false)
  end

  it "turns all channels off when every checkbox is unchecked [REQ-NOTIF-001]" do
    NotificationPreference.create!(
      user: user,
      channels: { "friend.request_received" => { "email" => true, "in_app" => true, "push" => true } }
    )
    all_off = NotificationPreference::DEFAULT_EVENTS.index_with do |_event|
      NotificationPreference::CHANNELS.index_with { |_c| "0" }
    end
    patch "/app/settings/notification_preferences", params: {
      notification_preference: { channels: all_off }
    }
    expect(response).to be_redirect
    pref = NotificationPreference.find_by!(user_id: user.id)
    channels = pref.enabled_channels_for("friend.request_received")
    expect(channels.values).to all(eq(false))
  end

  it "does not opt out absent events on a partial prefs PATCH [REQ-NOTIF-001]" do
    NotificationPreference.create!(
      user: user,
      channels: {
        "friend.request_received" => { "email" => true, "in_app" => true, "push" => true },
        "gift.thank_you" => { "email" => true, "in_app" => true, "push" => true }
      }
    )
    patch "/app/settings/notification_preferences", params: {
      notification_preference: {
        channels: { "friend.request_received" => { "email" => "0", "in_app" => "1", "push" => "1" } }
      }
    }
    expect(response).to be_redirect
    pref = NotificationPreference.find_by!(user_id: user.id)
    expect(pref.enabled_channels_for("friend.request_received")["email"]).to eq(false)
    expect(pref.enabled_channels_for("gift.thank_you").values).to all(eq(true))
  end


  it "settings page links to legal pages and supports account soft-delete" do
    get "/app/settings"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("/terms")
    expect(response.body).to include("/privacy")
    expect(response.body).to include("delete").or include("borrar").or include("Eliminar")

    delete "/app/settings/account"
    expect(user.reload.discarded_at).to be_present
    expect(response).to redirect_to(new_session_path)
    follow_redirect!
    expect(response.body).to include(I18n.t("member.settings.account_deleted", locale: user.locale.to_sym))
  end
end
