# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Hotwire MemberWebShell [REQ-WISH-001]", type: :request do
  let(:member) { create(:user, username: "shell_member") }

  def login_web!(user)
    post "/session", params: { email_address: user.email_address, password: "SecurePassword123!" }
  end

  it "redirects guests from member shell to login (O12A)" do
    get "/app"
    expect(response).to redirect_to(new_session_path)
  end

  it "renders logged-in nav with phone-parity sections (O12A/O2B)" do
    login_web!(member)
    get "/app"
    expect(response).to redirect_to("/app/wishlists")
    follow_redirect!
    expect(response).to have_http_status(:ok)
    body = response.body
    expect(body).to include("Mis listas").or include("My wishlists").or include("Listas")
    expect(body).to include("Compartidas").or include("Shared")
    expect(body).to include("Amigos").or include("Friends")
    expect(body).to include("Reservaciones").or include("Reservations")
    expect(body).to include("Avisos").or include("Notifications")
    expect(body).to include("Ajustes").or include("Settings")
    expect(body).to include('href="/app/wishlists"')
    expect(body).to include('href="/app/shared"')
    expect(body).to include('href="/app/friends"')
    expect(body).to include('href="/app/reservations"')
    expect(body).to include('href="/app/notifications"')
    expect(body).to include('href="/app/settings"')
  end

  it "serves empty section shells for each nav target when logged in" do
    login_web!(member)
    %w[/app/wishlists /app/shared /app/friends /app/reservations /app/notifications /app/settings].each do |path|
      get path
      expect(response).to have_http_status(:ok), "expected 200 for #{path}"
      expect(response.body).to include("<nav").or include("member-nav")
    end
  end
end
