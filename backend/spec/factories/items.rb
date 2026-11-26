# frozen_string_literal: true

FactoryBot.define do
  factory :item do
    wishlist { association :wishlist }
    sequence(:title) { |n| "Item #{n}" }
    specifications { nil }
    priority { "medium" }
    price_cents { nil }
    currency { nil }
    position { 0 }

    trait :with_price do
      price_cents { 1999 }
      currency { "USD" }
    end
  end

  factory :item_link do
    item { association :item }
    sequence(:url) { |n| "https://shop.example/p/#{n}" }
    position { 0 }
  end
end
