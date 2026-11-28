# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public legal pages [REQ-AUTH-002]", type: :request do
  it "GET /terms is public 200 with es+en placeholder content (O8A/O13A)" do
    get "/terms"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Terms of Use").or include("Términos")
    expect(response.body).to match(/Terms of Use|Términos de Uso/)
    # Bilingual sections present
    expect(response.body).to include("lang=\"es\"").or include("Español").or include("es")
    expect(response.body).to include("English").or include("lang=\"en\"").or include("en")
  end

  it "GET /privacy is public 200 with es+en placeholder content (O8A/O13A)" do
    get "/privacy"
    expect(response).to have_http_status(:ok)
    expect(response.body).to match(/Privacy|Privacidad/)
  end

  it "login and signup pages link to /terms and /privacy" do
    get "/session/new"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('href="/terms"').or include("terms_path")
    expect(response.body).to include("/terms")
    expect(response.body).to include("/privacy")

    get "/signup/new"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("/terms")
    expect(response.body).to include("/privacy")
  end
end
