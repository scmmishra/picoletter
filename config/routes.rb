Rails.application.routes.draw do
  namespace :auth do
    get "login", to: "sessions#new"
    post "login", to: "sessions#create"
    delete "logout", to: "sessions#destroy"
  end

  resources :newsletters, only: [ :new ], path: ""
  get "/:slug", to: "newsletters#show", as: :newsletter

  root "newsletters#index"

  get "up" => "rails/health#show", as: :rails_health_check
end
