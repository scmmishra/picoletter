Rails.application.routes.draw do
  namespace :auth do
    get "login", to: "sessions#new"
    post "login", to: "sessions#create"
    delete "logout", to: "sessions#destroy"
  end

  get "/signup", to: "users#new"
  post "/signup", to: "users#create"

  # redirect /login to /auth/login
  get "/login", to: redirect("/auth/login")

  scope "/app" do
    get "new", to: "newsletters#new", as: :new_newsletter
    post "new", to: "newsletters#create", as: :create_newsletter

    scope "/:slug" do
      get "new", to: "newsletters/posts#new", as: :new_post
      post "new", to: "newsletters/posts#create", as: :create_post

      get "settings", to: "newsletters/settings#index", as: :settings
      patch "settings", to: "newsletters/settings#update", as: :update_settings

      get "settings/profile", to: "newsletters/settings#profile", as: :profile_settings
      patch "settings/profile", to: "newsletters/settings#update_profile", as: :update_profile_settings

      get "settings/design", to: "newsletters/settings#design", as: :design_settings
      patch "settings/design", to: "newsletters/settings#update_design", as: :update_design_settings

      get "settings/sending", to: "newsletters/settings#sending", as: :sending_settings
      patch "settings/sending", to: "newsletters/settings#update_sending", as: :update_sending_settings

      resources :subscribers, only: [ :index ], path: "subscribers", module: "newsletters"

      resources :posts, only: [ :index, :edit, :show, :update ], path: "", module: "newsletters" do
        member do
          post :publish
          post :schedule
          delete :destroy
          post :unschedule
        end

        collection do
          get :archive
          get :drafts
        end
      end
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
