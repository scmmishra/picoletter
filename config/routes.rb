Rails.application.routes.draw do
  namespace :auth do
    get "login", to: "sessions#new"
    post "login", to: "sessions#create"
    delete "logout", to: "sessions#destroy"
  end

  resources :newsletters, only: [ :index, :new, :show ]

  get "up" => "rails/health#show", as: :rails_health_check
end
