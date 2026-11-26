# frozen_string_literal: true

Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  resource :session, only: %i[new create destroy]
  resource :signup, only: %i[new create], controller: "web_signups"

  get "s/:share_token", to: "secret_links#show", as: :secret_link,
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
      end
      get "shared_wishlists" => "shared_wishlists#index"
    end
  end

  root "rails/health#show"
end
