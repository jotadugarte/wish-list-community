# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:email_address) { |n| "user_#{n}@example.com" }
    sequence(:username) { |n| "user_handle_#{n}" }
    password { "SecurePassword123!" }
    password_confirmation { "SecurePassword123!" }
    locale { "es" }
    time_zone { "America/Bogota" }
    terms_accepted_at { Time.current }
  end
end
