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
end
