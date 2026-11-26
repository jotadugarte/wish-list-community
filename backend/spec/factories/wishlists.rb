# frozen_string_literal: true

FactoryBot.define do
  factory :wishlist do
    owner { association :user }
    sequence(:title) { |n| "Wishlist #{n}" }
    privacy_mode { "friends" }
    share_token { nil }
    event_date { nil }
    activity_id { nil }
    max_reservations_per_user { nil }

    trait :shared do
      after(:create) do |wishlist|
        wishlist.switch_privacy_mode!(PrivacyMode.new("shared"))
      end
    end
  end

  factory :wishlist_share do
    wishlist { association :wishlist, :shared }
    user { association :user }
    source { "explicit" }
  end
end
