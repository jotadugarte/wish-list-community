# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin style guide gate [REQ-ADM-001]", type: :request do
  let(:password) { "SecurePassword123!" }
  let!(:admin) do
    create(
      :user,
      role: "admin",
      username: "guide_admin",
      email_address: "guide_admin@example.com",
      password: password,
      password_confirmation: password
    )
  end
  let!(:member) do
    create(
      :user,
      username: "guide_member",
      email_address: "guide_member@example.com",
      password: password,
      password_confirmation: password
    )
  end

  def sign_in(user)
    post "/session", params: { email_address: user.email_address, password: password }
  end

  it "returns ok for an admin cookie session [REQ-ADM-001]" do
    sign_in(admin)
    get "/admin/style_guide"

    expect(response).to have_http_status(:ok)
  end

  it "returns not-found for a signed-in member without revealing the guide [REQ-ADM-001]" do
    sign_in(member)
    get "/admin/style_guide"

    expect(response).to have_http_status(:not_found)
    expect(response.body).not_to include("brand-guide")
  end

  it "returns not-found for a guest [REQ-ADM-001]" do
    get "/admin/style_guide"

    expect(response).to have_http_status(:not_found)
  end

  describe "guide chrome [REQ-ARCH-001]" do
    before { sign_in(admin) }

    it "shows the admin nav, token table, toggles, version stamp, and CSS variables [REQ-ARCH-001]" do
      catalog = SharedDesignTokens.load
      get "/admin/style_guide"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("admin.nav.style_guide"))
      expect(response.body).to include(I18n.t("admin.nav.reports"))
      expect(response.body).to include("brand-guide")
      expect(response.body).to include(catalog.version)
      expect(response.body).to include("--c-primary:#1F4037")
      expect(response.body).to include(I18n.t("admin.style_guide.toggles.dark"))
      expect(response.body).to include(I18n.t("admin.style_guide.toggles.english"))
      expect(response.body).to include("<table")
    end

    it "applies the dark palette when the appearance toggle is dark [REQ-ARCH-001]" do
      get "/admin/style_guide", params: { appearance: "dark" }

      expect(response.body).to include('data-appearance="dark"')
      expect(response.body).to include("--c-primary:#4E8C73")
    end

    it "switches the guide copy to English [REQ-ARCH-001]" do
      get "/admin/style_guide", params: { copy: "en" }

      expect(response.body).to include('data-copy="en"')
      expect(response.body).to include(I18n.t("admin.style_guide.copy_label", locale: :en))
    end
  end

  describe "web preview [REQ-ARCH-001]" do
    before { sign_in(admin) }

    it "shows inert sample flows, button states, accessibility notes, and do/don't [REQ-ARCH-001]" do
      get "/admin/style_guide", params: { preview: "web" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('data-preview="web"')
      expect(response.body).to include(I18n.t("admin.style_guide.web.flow_title"))
      expect(response.body).to include('type="button"')
      expect(response.body).to include("disabled")
      expect(response.body).to include(I18n.t("admin.style_guide.a11y.heading"))
      expect(response.body).to include(I18n.t("admin.style_guide.do_dont.heading"))
      expect(response.body).not_to include("<form")
    end

    it "keeps the web sample in English when copy is en [REQ-ARCH-001]" do
      get "/admin/style_guide", params: { preview: "web", copy: "en" }

      expect(response.body).to include(I18n.t("admin.style_guide.web.flow_title", locale: :en))
    end
  end

  describe "print stylesheet [REQ-ADM-001]" do
    before { sign_in(admin) }

    it "includes print rules that hide the toggles for PDF [REQ-ADM-001]" do
      get "/admin/style_guide"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("@media print")
      expect(response.body).to include(".brand-guide-controls")
      expect(response.body).to include("display:none")
    end
  end

  describe "app preview [REQ-ARCH-001]" do
    before { sign_in(admin) }

    it "shows an HTML phone mock from the shared tokens, not Flutter Web [REQ-ARCH-001]" do
      get "/admin/style_guide", params: { preview: "app" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('data-preview="app"')
      expect(response.body).to include("brand-phone-mock")
      expect(response.body).to include(SharedDesignTokens.load.app_name)
      expect(response.body).to include(I18n.t("admin.style_guide.app.screen_title"))
      expect(response.body).to include("--c-primary")
      expect(response.body).not_to include("flutter.js")
      expect(response.body).not_to include("<form")
    end
  end
end
