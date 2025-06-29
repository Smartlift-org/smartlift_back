Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"

  # API root endpoint
  root "api_status#index"

  # Users
  post "/users", to: "users#create"
  patch "/users/:id", to: "users#update"
  post "/auth/login", to: "auth#login"
  get "/profile", to: "users#profile"

  # Exercises
  get "/exercises", to: "exercises#index"
  get "/exercises/:id", to: "exercises#show"
  post "/exercises", to: "exercises#create"
  patch "/exercises/:id", to: "exercises#update"
  delete "/exercises/:id", to: "exercises#destroy"

  # User Stats
  get "/user_stats", to: "user_stats#index"
  post "/user_stats", to: "user_stats#create"
  patch "/user_stats", to: "user_stats#update"
  put "/user_stats", to: "user_stats#update"

  resources :routines do
    resources :exercises, only: [:create, :destroy], controller: 'routine_exercises'
  end

  # Workout tracking - Better structured
  resources :workouts do
    collection do
      post :free, to: 'workouts#create_free'
    end
    member do
      put :pause
      put :resume
      put :complete
      put :abandon
    end
  end

  # Nested workout resources with proper namespace
  namespace :workout do
    resources :exercises do
      member do
        post :record_set
        put :complete
        put :finalize
      end
      resources :sets do
        member do
          put :start
          put :complete
          put :mark_as_completed
        end
      end
    end
  end

  # Performance tracking
  resources :personal_records, only: [:index, :show] do
    collection do
      get 'by_exercise/:exercise_id', to: 'personal_records#by_exercise'
      get 'recent'
      get 'latest'
      get 'statistics'
    end
  end
end
