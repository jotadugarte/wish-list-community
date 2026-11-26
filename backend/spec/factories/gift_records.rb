# frozen_string_literal: true

FactoryBot.define do
  factory :gift_record do
    item { association :item }
    gifter { association :user }
    status { "purchased_secret" }
    thank_you_note { nil }
    purchase_link_ref { nil }
  end
end
