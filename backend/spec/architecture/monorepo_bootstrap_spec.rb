# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Monorepo Foundation & Architecture Bootstrap", type: :request do
  describe "Rails 8 Backend & Health Endpoint [REQ-ARCH-001]" do
    it "boots the Rails 8 application with PostgreSQL, Pundit, and responds 200 OK on /up [REQ-ARCH-001]" do
      expect(Rails::VERSION::MAJOR).to eq(8)
      expect(ActiveRecord::Base.connection.adapter_name).to eq("PostgreSQL")
      expect(defined?(Pundit::Authorization)).to eq("constant")

      get "/up"
      expect(response).to have_http_status(:ok)
    end
  end
end
