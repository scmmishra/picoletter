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

      resource :settings, only: [ :show, :update ], path: "settings", module: "newsletters" do
        get :profile
        patch :profile, action: :update_profile, as: :update_profile

        get :design
        patch :design, action: :update_design, as: :update_design

        get :sending
        patch :sending, action: :update_sending, as: :update_sending
      end

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
