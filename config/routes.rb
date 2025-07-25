Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
  
  # Alternative health check endpoint for compatibility
  get "health" => "rails/health#show", as: :health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"

  # API root endpoint - removed for security (use /up for health checks)

  # Users
  post "/users", to: "users#create"
  patch "/users/:id", to: "users#update"
  post "/auth/login", to: "auth#login"
  post "/auth/forgot-password", to: "auth#forgot_password"
  post "/auth/reset-password", to: "auth#reset_password"
  get "/auth/validate-token", to: "auth#validate_token"
  get "/profile", to: "users#profile"

  # Admin routes - Admin only endpoints
  scope :admin do
    get "/coaches", to: "users#index_coaches"
    get "/coaches/:id", to: "users#show_coach"
    patch "/coaches/:id", to: "users#update_coach"
    delete "/coaches/:id", to: "users#deactivate_coach"
    post "/coaches/:id/assign-users", to: "users#assign_users"
    delete "/coaches/:id/users/:user_id", to: "users#unassign_user"
    get "/users", to: "users#index_users"
    get "/users/:id", to: "users#show_user"
    patch "/users/:id", to: "users#update_user"
    get "/available-users", to: "users#available_users"
    post "/users", to: "users#create_by_admin"
  end

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

  # API v1 namespace for versioned endpoints
  namespace :api do
    namespace :v1 do
      # AI-powered workout routine generation
      resources :ai_workout_routines, only: [:create], path: 'ai/workout_routines'
      
      # New TrainerMembers controller (solución a problemas de reconocimiento de acciones)
      resources :trainers, only: [] do
        resources :members, only: [:show], controller: 'trainer_members' do
          member do
            get :routines
          end
        end
      end
      
      # Trainer endpoints
      resources :trainers, only: [:show] do
        member do
          get :members
          get :dashboard
          get :available_users
          get :list_routines, path: 'routines'
          post :assign_member, path: 'members'
          delete :unassign_member, path: 'members/:user_id'
          # Rutas eliminadas: member_profile y member_routines ahora son manejadas por TrainerMembersController
          post :assign_routine, path: 'members/:user_id/assign_routine'
          put :update_member_routine, path: 'members/:user_id/routines/:routine_id'
        end
      end
    end
  end
end
