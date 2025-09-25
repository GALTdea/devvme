Rails.application.routes.draw do
  get "limited_access/pending_activation"
  get "limited_access/suspended"
  get "limited_access/deactivated"
  namespace :admin do
    get "blog_analytics/index"
    get "analytics/index"
    get "analytics/registration_trends"
    get "analytics/user_engagement"
    get "visitor_analytics/index"
    root "dashboard#index"

    get "dashboard/export", to: "dashboard#export", as: :dashboard_export
    get "dashboard/online_users", to: "dashboard#online_users", as: :dashboard_online_users

    resources :users do
      member do
        patch :suspend
        patch :unsuspend
        patch :activate
        patch :deactivate
        patch :promote
        patch :demote
        delete :destroy
      end
      collection do
        post :bulk_suspend
        post :bulk_delete
        post :bulk_promote
        post :bulk_demote
      end
    end

    resources :activities, only: [:index, :show]

    namespace :content_moderation do
      get :index
      get :blog_posts
      get :projects
      patch 'blog_posts/:id/moderate', to: 'content_moderation#moderate_blog_post', as: :moderate_blog_post
      patch 'projects/:id/moderate', to: 'content_moderation#moderate_project', as: :moderate_project
    end

    get "dashboard", to: "dashboard#index"
  end
  resources :projects do
    patch :reorder, on: :collection
  end

  # Public blog routes (no authentication required)
  get "blog", to: "public_blog#index", as: :public_blog_index
  get "blog/:id", to: "public_blog#show", as: :public_blog_post
  get "blog.rss", to: "public_blog#rss", as: :public_blog_rss, defaults: { format: :xml }

  # Public project routes (no authentication required)
  get "explore", to: "public_projects#index", as: :public_projects
  get "explore/:id", to: "public_projects#show", as: :public_project

  # SEO Sitemap
  get "sitemap.xml", to: "sitemap#index", as: :sitemap, defaults: { format: :xml }

  # Admin blog routes (authentication required)
  resources :blog_posts, path: "admin/blog" do
    post :autosave, on: :member
    patch :archive, on: :member
    patch :unarchive, on: :member
  end

  # Dashboard routes
  get "dashboard", to: "dashboard#index"

  # Beta testing routes
  get "beta/confirmation", to: "beta#confirmation", as: :beta_confirmation
  get "beta/waiting", to: "beta#waiting", as: :beta_waiting

  # Limited access routes - for users with restricted access
  get "pending_activation", to: "limited_access#pending_activation", as: :pending_activation
  get "suspended", to: "limited_access#suspended", as: :suspended
  get "deactivated", to: "limited_access#deactivated", as: :deactivated

  # Devise with custom registrations controller for beta flow
  devise_for :users, controllers: {
    registrations: 'users/registrations'
  }

  # Redirect already authenticated users to dashboard instead of root
  authenticated :user do
    root "dashboard#index", as: :authenticated_root
  end

  # Profile routes - authenticated user's own profile
  resource :profile, only: [ :show, :edit, :update ] do
    get :complete, on: :member
  end

  # Social media images for profiles
  get "social/:username/image", to: "social_images#profile_image", as: :social_profile_image, constraints: { username: /[a-zA-Z0-9_-]+/ }

  # Public profile routes - for sharing and visitor access
  # Uses username with FriendlyId for clean URLs like /gustavo
  get "/:username", to: "public_profiles#show", as: :public_profile, constraints: { username: /[a-zA-Z0-9_-]+/ }

  root "home#index"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
