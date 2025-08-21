Rails.application.routes.draw do
  resources :projects do
    patch :reorder, on: :collection
  end

  # Blog routes
  resources :blog_posts, path: "blog" do
    post :autosave, on: :member
  end

  # Dashboard routes
  get "dashboard", to: "dashboard#index"
  devise_for :users

  # Redirect already authenticated users to dashboard instead of root
  authenticated :user do
    root "dashboard#index", as: :authenticated_root
  end

  # Profile routes - authenticated user's own profile
  resource :profile, only: [ :show, :edit, :update ]

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
