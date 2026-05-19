Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  devise_for :users

  root "dashboard#index"
  get "dashboard", to: "dashboard#index"

  get   "profile",      to: "users#show",   as: :profile
  get   "profile/edit", to: "users#edit",   as: :edit_profile
  patch "profile",      to: "users#update"

  resources :time_off_requests, only: [ :index, :new, :create, :show ] do
    member do
      patch :approve
      patch :deny
      patch :cancel
    end
  end

  namespace :admin do
    resources :users, only: [ :index, :show, :edit, :update ]
    resources :departments
    resources :time_off_requests, only: [ :index ]
  end

  namespace :api do
    namespace :v1 do
      post   "auth/sign_in",  to: "sessions#create"
      delete "auth/sign_out", to: "sessions#destroy"

      resources :users, only: [ :index, :show, :update ]
      resources :departments, only: [ :index, :show ]

      resources :time_off_requests, only: [ :index, :create, :show, :update, :destroy ] do
        member do
          patch :approve
          patch :deny
          patch :cancel
        end
      end

      resources :approvals, only: [ :index, :show ]
    end
  end
end
