# frozen_string_literal: true

FactoryBot.define do
  factory :activity do
    association :creator, factory: :user
    sequence(:name) { |n| "Activity #{n}" }
    currency { "CRC" }
    assignment_mode { "secret_santa" }
    visibility_mode { "recipient_only" }
    reservation_visibility { "hidden_from_recipient" }
    budget_mode { "none" }
  end

  factory :activity_participant do
    association :activity
    association :user
    status { "invited" }
    co_organizer { false }
  end
end
