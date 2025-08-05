Rails.application.config.middleware.insert_before 0, Rack::Cors do
  # Allow all origins for public endpoints like exercises
  allow do
    origins "*"
    resource "/exercises*",
      headers: :any,
      methods: [ :get, :options, :head ],
      credentials: false
  end

  # Allow specific origins for authenticated endpoints
  allow do
    origins "http://localhost:3000",
            "http://127.0.0.1:3000",
            "http://10.0.2.2:3000",  # Android emulator
            "http://localhost:19000", # Expo default
            "http://localhost:19006", # Expo web
            "https://protective-mercy-dev.up.railway.app" # Railway deployment
    resource "*",
      headers: :any,
      methods: [ :get, :post, :put, :patch, :delete, :options, :head ],
      credentials: true
  end
end
