Rails.application.routes.draw do
  default_url_options host: Rails.application.config.host
  mount MissionControl::Jobs::Engine, at: "/admin/jobs"

  post "/webhook/resend", to: "webhook#resend"
  post "/webhook/sns", to: "webhook#sns"

  resources :passwords, param: :token

  namespace :auth do
    get "login", to: "sessions#new"
    post "login", to: "sessions#create"
    delete "logout", to: "sessions#destroy"
  end

  get "/signup", to: "users#new"
  post "/signup", to: "users#create"

  # redirect /login to /auth/login
  get "/login", to: redirect("/auth/login")

  if Rails.env.development?
    get "/dev/playground", to: "playground#show", as: :playground
  end

  get "healthz" => "rails/health#show", as: :rails_health_check

  # unsubscribe

  scope "/:slug" do
    match "unsubscribe", to: "public/subscribers#unsubscribe", as: :unsubscribe, via: [ :get, :post ]
    match "subscribe", to: "public/subscribers#public_subscribe", as: :subscribe, via: [ :get, :post ]
    match "embed/subscribe", to: "public/subscribers#embed_subscribe", as: :embed_subscribe, via: [ :post ]
    get "confirm", to: "public/subscribers#confirm_subscriber", as: :confirm
    get "almost-there", to: "public/subscribers#almost_there", as: :almost_there
    get "/", to: "public/newsletters#show", as: :newsletter
    get "/posts", to: "public/newsletters#all_posts", as: :newsletter_all_posts
    get "/posts/:post_slug", to: "public/newsletters#show_post", as: :newsletter_post
  end

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
        post :verify_domain, action: :verify_domain, as: :verify_domain

        get :embedding
        patch :embedding, action: :update_embedding, as: :update_embedding
      end

      resources :subscribers, only: [ :index, :show ], path: "subscribers", module: "newsletters" do
        get ":id", to: "subscribers#show", on: :collection, as: :show
        patch ":id", to: "subscribers#update", on: :collection, as: :update
        delete ":id", to: "subscribers#destroy", on: :collection, as: :destroy
        post ":id/unsubscribe", to: "subscribers#unsubscribe", on: :collection, as: :unsubscribe
        post ":id/send_reminder", to: "subscribers#send_reminder", on: :collection, as: :send_reminder
      end

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
end
