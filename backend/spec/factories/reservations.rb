# frozen_string_literal: true

FactoryBot.define do
  factory :reservation do
    item { association :item }
    user { association :user }
    status { "active" }
    estimated_date { Date.current + 7 }
    private_note { nil }
    grace_expires_at { nil }
  end
end
