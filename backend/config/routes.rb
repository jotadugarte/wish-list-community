# frozen_string_literal: true

Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  resource :session, only: %i[create destroy]

  namespace :api do
    namespace :v1 do
      resource :session, only: %i[create destroy]
      resource :passwords, only: %i[create]
      resource :account, only: %i[destroy] do
        post :restore
      end
      get "me" => "profiles#show"
      get "users/search" => "users#search", as: :search_users
      get "users/:username" => "users#show", as: :user
      resources :friendships, only: %i[index create update destroy]
      resources :user_blocks, only: %i[create]
    end
  end

  root "rails/health#show"
end
