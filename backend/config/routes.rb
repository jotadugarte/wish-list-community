# frozen_string_literal: true

Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  resource :session, only: %i[create destroy]

  namespace :api do
    namespace :v1 do
      resource :session, only: %i[create destroy]
      resource :passwords, only: %i[create]
      get "me" => "profiles#show"
    end
  end

  root "rails/health#show"
end
