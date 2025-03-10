Rails.application.routes.draw do
  default_url_options host: Rails.application.config.host

  mount MissionControl::Jobs::Engine, at: "/admin/jobs"

  # Webhook routes
  scope "/webhook" do
    post "sns", to: "webhook#sns"
  end

  # Auth routes
  namespace :auth do
    get "login", to: "sessions#new"
    post "login", to: "sessions#create"
    delete "logout", to: "sessions#destroy"
  end

  # Signup routes
  get "/signup", to: "users#new"
  post "/signup", to: "users#create"
  get "/verify", to: "users#show_verify"
  get "/confirm", to: "users#confirm_verification", as: :confirm_verification
  post "/resend_verification_email", to: "users#resend_verification_email"

  # Redirect old login
  get "/login", to: redirect("/auth/login")

  # Dev-only playground
  if Rails.env.development?
    get "/dev/playground", to: "playground#show", as: :playground
  end

  # Health check
  get "healthz" => "rails/health#show", as: :rails_health_check

  # Password token-based routes
  resources :passwords, param: :token

  # Public newsletter routes
  scope path: ":slug", module: "public" do
    match "unsubscribe", to: "subscribers#unsubscribe", as: :unsubscribe, via: [ :get, :post ]
    match "subscribe", to: "subscribers#public_subscribe", as: :subscribe, via: [ :get, :post ]
    match "embed/subscribe", to: "subscribers#embed_subscribe", as: :embed_subscribe, via: :post
    get "confirm", to: "subscribers#confirm_subscriber", as: :confirm
    get "almost-there", to: "subscribers#almost_there", as: :almost_there
    get "/", to: "newsletters#show", as: :newsletter
    get "posts", to: "newsletters#all_posts", as: :newsletter_all_posts
    get "posts/:post_slug", to: "newsletters#show_post", as: :newsletter_post
  end

  # App routes
  scope "/app" do
    get "new", to: "newsletters#new", as: :new_newsletter
    post "new", to: "newsletters#create", as: :create_newsletter

    scope ":slug", module: "newsletters" do
      get "new", to: "posts#new", as: :new_post
      post "new", to: "posts#create", as: :create_post

      resource :settings, only: [ :show, :update ], path: "settings" do
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

      resources :labels, only: [ :index, :create, :destroy ], path: "labels"

      resources :subscribers, only: [ :index, :show ], path: "subscribers" do
        collection do
          get ":id", to: "subscribers#show", as: :show
          patch ":id", to: "subscribers#update", as: :update
          delete ":id", to: "subscribers#destroy", as: :destroy
          post ":id/unsubscribe", to: "subscribers#unsubscribe", as: :unsubscribe
          post ":id/send_reminder", to: "subscribers#send_reminder", as: :send_reminder
          post ":id/labels/add", to: "subscribers/labels#add", as: :add_label
          delete ":id/labels/:label_name", to: "subscribers/labels#remove", as: :remove_label
        end
      end

      resources :posts, only: [ :index, :edit, :show, :update ], path: "" do
        member do
          post :publish
          post :send_test
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
