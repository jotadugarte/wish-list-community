# frozen_string_literal: true

Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  resource :session, only: %i[new create destroy]
  resource :signup, only: %i[new create], controller: "web_signups"
  get "terms", to: "legal_pages#terms", as: :terms
  get "privacy", to: "legal_pages#privacy", as: :privacy

  namespace :member, path: "app" do
    root to: "home#show"
    resources :wishlists, only: %i[index show new create edit update destroy] do
      member do
        post :rotate_share_token
      end
      resources :shares, only: %i[create destroy], controller: "wishlist_shares"
      resources :items, only: %i[new create], controller: "items"
    end
    resources :items, only: %i[edit update destroy], controller: "items" do
      resources :reservations, only: %i[create], controller: "reservations"
    end
    resources :reservations, only: %i[index destroy], controller: "reservations" do
      member do
        post :mark_purchased
      end
    end
    resources :gifts, only: [], controller: "gifts" do
      member do
        post :mark_delivered
        post :confirm_received
      end
    end
    get "shared", to: "shell#show", defaults: { section: "shared" }, as: :shared
    get "friends", to: "shell#show", defaults: { section: "friends" }, as: :friends
    resources :notifications, only: %i[index], controller: "notifications" do
      member do
        post :mark_read
      end
    end
    get "settings", to: "settings#show", as: :settings
    delete "settings/account", to: "settings#destroy_account", as: :settings_account
    resource :notification_preferences, only: %i[show update],
             controller: "notification_preferences",
             path: "settings/notification_preferences"
  end

  namespace :admin do
    root to: "reports#index"
    resources :reports, only: %i[index show] do
      member do
        post :dismiss
        post :suspend
        post :soft_delete_user
        post :soft_delete_wishlist
      end
    end
    resources :audit_events, only: %i[index show] do
      member do
        post :revert
      end
    end
    resources :gifts, only: %i[show]
  end

  get "s/:share_token", to: "secret_links#show", as: :secret_link,
      constraints: { share_token: /[A-Za-z0-9\-_]+/ }
  post "s/:share_token/items/:item_id/reservations", to: "secret_link_reservations#create", as: :secret_link_item_reservations,
      constraints: { share_token: /[A-Za-z0-9\-_]+/ }
  patch "s/:share_token/reservations/:id", to: "secret_link_reservations#update", as: :secret_link_reservation,
      constraints: { share_token: /[A-Za-z0-9\-_]+/ }
  delete "s/:share_token/reservations/:id", to: "secret_link_reservations#destroy",
      constraints: { share_token: /[A-Za-z0-9\-_]+/ }
  post "s/:share_token/reservations/:reservation_id/mark_purchased", to: "secret_link_gifts#mark_purchased",
      as: :secret_link_mark_purchased, constraints: { share_token: /[A-Za-z0-9\-_]+/ }
  post "s/:share_token/gifts/:id/mark_delivered", to: "secret_link_gifts#mark_delivered",
      as: :secret_link_mark_delivered, constraints: { share_token: /[A-Za-z0-9\-_]+/ }
  post "s/:share_token/gifts/:id/confirm_received", to: "secret_link_gifts#confirm_received",
      as: :secret_link_confirm_received, constraints: { share_token: /[A-Za-z0-9\-_]+/ }
  post "s/:share_token/items/:item_id/mark_received", to: "secret_link_gifts#mark_received",
      as: :secret_link_mark_received, constraints: { share_token: /[A-Za-z0-9\-_]+/ }
  post "s/:share_token/report", to: "secret_link_reports#create", as: :secret_link_report,
      constraints: { share_token: /[A-Za-z0-9\-_]+/ }

  namespace :api do
    namespace :v1 do
      resource :session, only: %i[create destroy]
      resource :signup, only: %i[create]
      resource :passwords, only: %i[create]
      resource :account, only: %i[destroy] do
        post :restore
      end
      get "me" => "profiles#show"
      get "users/search" => "users#search", as: :search_users
      get "users/:username/wishlists" => "user_wishlists#index", as: :user_wishlists
      get "users/:username" => "users#show", as: :user
      resources :friendships, only: %i[index create update destroy]
      resources :reports, only: %i[create]
      resources :user_blocks, only: %i[create]
      resources :wishlists, only: %i[index create show update destroy] do
        member do
          post :restore
        end
        post "share_token/rotate", to: "wishlists#rotate_share_token", on: :member
        resources :shares, only: %i[create destroy], controller: "wishlist_shares"
        resources :items, only: %i[index create], controller: "items"
        patch "items/reorder", to: "items#reorder"
      end
      resources :items, only: %i[show update destroy] do
        member do
          post :restore
          delete "images/:image_id", action: :destroy_image
        end
        resources :reservations, only: %i[create], controller: "reservations"
        post "mark_received", to: "item_gifts#create"
      end
      resources :reservations, only: %i[update destroy] do
        post "mark_purchased", to: "reservation_gifts#create"
      end
      resources :gifts, only: [] do
        member do
          post :mark_delivered
          post :confirm_received
        end
      end
      get "my_reservations" => "my_reservations#index"

      resource :notification_preferences, only: %i[show update]
      resources :notifications, only: %i[index] do
        member do
          post :mark_read
        end
      end
      resources :link_previews, only: %i[create]
      get "shared_wishlists" => "shared_wishlists#index"
    end
  end

  root "rails/health#show"
end
