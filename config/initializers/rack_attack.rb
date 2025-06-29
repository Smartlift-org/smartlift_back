class Rack::Attack
  # Configuration for rack-attack store
  # In production, you should use Redis or Memcached
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  # Limit requests per IP
  throttle("req/ip", limit: 300, period: 5.minutes) do |req|
    req.ip
  end

  # Limit login attempts
  throttle("logins/ip", limit: 5, period: 1.minutes) do |req|
    if req.path == "/api/v1/auth/login" && req.post?
      req.ip
    end
  end

  # Limit registration attempts
  throttle("registrations/ip", limit: 3, period: 1.hour) do |req|
    if req.path == "/api/v1/auth/register" && req.post?
      req.ip
    end
  end

  # Block malicious IPs
  blocklist("block malicious IPs") do |req|
    # Block login attempts if the IP is not in the allowlist
    Rack::Attack::Allow2Ban.filter(req.ip, maxretry: 5, findtime: 1.hour, bantime: 24.hours) do
      req.path == "/api/v1/auth/login" && req.post? && req.env["HTTP_AUTHORIZATION"].blank?
    end
  end

  # Customize response when a request is blocked
  self.throttled_response = lambda do |env|
    [ 429, # status
      { "Content-Type" => "application/json" }, # headers
      [ { error: "Rate limit exceeded. Please try again later." }.to_json ] # body
    ]
  end

  # Rate limiting configuration
  # Throttle requests to public endpoints
  throttle('exercises/ip', limit: 100, period: 1.hour) do |req|
    req.ip if req.path.start_with?('/exercises')
  end

  # More aggressive limiting for unauthenticated requests
  throttle('unauthenticated/ip', limit: 50, period: 1.hour) do |req|
    req.ip unless req.env['HTTP_AUTHORIZATION']
  end

  # AI workout routine generation - more restrictive due to resource usage
  throttle('ai_workout_routines/ip', limit: 5, period: 1.hour) do |req|
    req.ip if req.path.start_with?('/api/v1/ai/workout_routines')
  end

  # Additional throttling for AI endpoints by user ID (if authenticated)
  throttle('ai_workout_routines/user', limit: 8, period: 1.hour) do |req|
    if req.path.start_with?('/api/v1/ai/workout_routines')
      user_id = extract_user_id_from_token(req.env['HTTP_AUTHORIZATION'])
      user_id if user_id
    end
  end

  private

  def self.extract_user_id_from_token(auth_header)
    return nil unless auth_header&.start_with?('Bearer ')
    
    token = auth_header.split(' ').last
    begin
      decoded = JsonWebToken.decode(token)
      decoded[:user_id] if decoded
    rescue StandardError
      nil
    end
  end
end
