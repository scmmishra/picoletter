Rails.application.routes.draw do
  namespace :auth do
    get "login", to: "sessions#new"
    post "login", to: "sessions#create"
    delete "logout", to: "sessions#destroy"
  end

  # redirect /login to /auth/login
  get "/login", to: redirect("/auth/login")

  scope "/app/:slug" do
    get "new", to: "newsletters/posts#new", as: :new_post
    post "new", to: "newsletters/posts#create", as: :create_post

    resources :subscribers, only: [ :index ], path: "subscribers", module: "newsletters"

    resources :posts, only: [ :index, :edit, :show, :update ], path: "", module: "newsletters" do
      member do
        post :publish
        delete :destroy
      end

      collection do
        get :archive
        get :drafts
      end
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
