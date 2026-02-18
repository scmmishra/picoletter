Rails.application.routes.draw do
  default_url_options host: Rails.application.config.host

  mount MissionControl::Jobs::Engine, at: "/admin/jobs"
  mount ActiveHashcash::Engine, at: "/admin/hashcash"

  # Webhook routes
  scope "/webhook" do
    post "sns", to: "webhook#sns"
  end

  # Auth routes
  namespace :auth do
    get "login", to: "sessions#new"
    post "login", to: "sessions#create"
    delete "logout", to: "sessions#destroy"

    # OmniAuth routes
    namespace :omniauth do
      get "failure", to: "callbacks#failure"
    end
  end

  # OmniAuth callback routes
  match "auth/github/callback", to: "auth/omniauth/callbacks#github", via: [ :get, :post ]
  match "auth/google_oauth2/callback", to: "auth/omniauth/callbacks#google_oauth2", via: [ :get, :post ]
  get "auth/failure", to: "auth/omniauth/callbacks#failure"

  # Signup routes
  get "/signup", to: "users#new"
  post "/signup", to: "users#create"
  get "/verify", to: "users#show_verify"
  get "/confirm", to: "users#confirm_verification", as: :confirm_verification
  post "/resend_verification_email", to: "users#resend_verification_email"

  # Invitation routes
  get "/invitations/:token", to: "invitations#show", as: :invitation
  post "/invitations/:token", to: "invitations#accept", as: :accept_invitation_submit
  post "/invitations/:token/ignore", to: "invitations#ignore", as: :ignore_invitation

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
    match "embed/subscribe", to: "subscribers#embed_subscribe", as: :embed_subscribe, via: [ :get, :post ]
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

      resource :settings, only: [ :show, :update ], path: "settings"

      namespace :settings, path: "settings" do
        # Profile
        get "profile", to: "profile#show", as: :profile
        patch "profile", to: "profile#update"
        delete "profile/connected_services/:id", to: "profile#destroy_connected_service", as: :profile_connected_service

        # Design
        get "design", to: "design#show", as: :design
        patch "design", to: "design#update"

        # Sending
        get "sending", to: "sending#show", as: :sending
        patch "sending", to: "sending#update"
        post "sending/domain", to: "sending#connect_domain", as: :sending_connect_domain
        post "sending/verify_domain", to: "sending#verify_domain", as: :sending_verify_domain
        delete "sending/domain", to: "sending#disconnect_domain", as: :sending_disconnect_domain

        # API
        get "api", to: "api#show", as: :api
        post "api/generate_token", to: "api#generate_token", as: :api_generate_token
        patch "api/rotate_token", to: "api#rotate_token", as: :api_rotate_token

        # Embedding
        get "embedding", to: "embedding#show", as: :embedding
        patch "embedding", to: "embedding#update"

        if AppConfig.get("ENABLE_BILLING", false) || Rails.env.test?
          get "billing", to: "billing#show", as: :billing
          get "billing/checkout", to: "billing#checkout", as: :billing_checkout
          get "billing/manage", to: "billing#manage", as: :billing_manage
        end

        # Team management routes
        get "team", to: "team#index", as: :team
        post "team/invite", to: "team#invite", as: :team_invite
        delete "team/members/:id", to: "team#destroy", as: :team_member
        patch "team/members/:id", to: "team#update_role", as: :team_member_role
        delete "team/invitations/:id", to: "team#destroy_invitation", as: :team_invitation
      end

      resources :labels, only: [ :index, :create, :destroy, :update ], path: "labels"

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

  # Public API routes
  namespace :api do
    namespace :v1 do
      resources :subscribers, only: [ :create ]
    end

    # Admin API routes
    if AppConfig.get("ENABLE_BILLING", false) || Rails.env.test?
      namespace :admin do
        post "users/update_limits", to: "users#update_limits"
        post "users/toggle_active", to: "users#toggle_active"
      end
    end
  end
end
