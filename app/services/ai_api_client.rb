require 'net/http'
require 'json'
require 'uri'
require 'timeout'

class AiApiClient
  class ServiceError < StandardError; end
  class TimeoutError < ServiceError; end
  class NetworkError < ServiceError; end
  class InvalidResponseError < ServiceError; end

  # AI service endpoint configuration
  # TheAnswer.ai service configuration
  AI_SERVICE_URL = ENV['AI_SERVICE_URL'] || "https://lr-staging.studio.theanswer.ai/api/v1/prediction/dbc304ad-e576-4f7e-9974-b20cab09b9e9"
  AI_API_KEY = ENV['AI_API_KEY'] || "nC7uxcEX6etjtIoZi1tKeg9k1jroKl26g0sXnSy9FwI"
  REQUEST_TIMEOUT = (ENV['AI_REQUEST_TIMEOUT'] || 60).to_i # 60 seconds timeout
  MAX_RETRIES = (ENV['AI_MAX_RETRIES'] || 2).to_i

  def initialize
    @uri = URI(AI_SERVICE_URL)
    Rails.logger.info "AI Service URL configured as: #{AI_SERVICE_URL}"
  end

  # Send prompt to AI service and return the response
  def generate_routine(prompt)
    retries = 0
    
    begin
      response = make_request(prompt)
      validate_response(response)
      response.body
      
    rescue Net::ReadTimeout, Net::OpenTimeout, Timeout::Error => e
      Rails.logger.error "AI API Timeout: #{e.message}"
      raise TimeoutError, "AI service request timed out"
      
    rescue Net::HTTPError, SocketError, Errno::ECONNREFUSED => e
      Rails.logger.error "AI API Network Error: #{e.message}"
      
      retries += 1
      if retries <= MAX_RETRIES
        Rails.logger.info "Retrying AI API request (attempt #{retries + 1}/#{MAX_RETRIES + 1})"
        sleep(2 ** retries) # Exponential backoff: 2s, 4s
        retry
      end
      
      raise NetworkError, "Unable to connect to AI service after #{MAX_RETRIES + 1} attempts"
      
    rescue JSON::ParserError => e
      Rails.logger.error "AI API JSON Parse Error: #{e.message}"
      raise InvalidResponseError, "AI service returned invalid JSON"
      
    rescue StandardError => e
      Rails.logger.error "AI API Unexpected Error: #{e.message}"
      raise ServiceError, "Unexpected error communicating with AI service"
    end
  end

  private

  def make_request(prompt)
    http = Net::HTTP.new(@uri.host, @uri.port)
    http.read_timeout = REQUEST_TIMEOUT
    http.open_timeout = REQUEST_TIMEOUT
    
    # Configure SSL for HTTPS URLs
    if @uri.scheme == 'https'
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    end
    
    # Create the request
    request = Net::HTTP::Post.new(@uri)
    request['Content-Type'] = 'application/json'
    request['Accept'] = 'application/json'
    request['User-Agent'] = 'Ruby/Rails SmartLift API Client'
    
    # Add Authorization header for TheAnswer.ai
    if AI_API_KEY.present?
      request['Authorization'] = "Bearer #{AI_API_KEY}"
    end
    
    # Set the request body
    request.body = {
      question: prompt
    }.to_json
    
    Rails.logger.info "Sending AI API request to #{@uri}"
    Rails.logger.debug "Request body: #{request.body}" if Rails.env.development?
    
    # Send the request
    response = http.request(request)
    
    Rails.logger.info "AI API response status: #{response.code}"
    Rails.logger.info "AI API response headers: #{response.to_hash}"
    Rails.logger.error "AI API response body: #{response.body}" # Always log for debugging
    
    response
  end

  def validate_response(response)
    case response.code.to_i
    when 200
      # Success - validate that we have a response body
      if response.body.blank?
        raise InvalidResponseError, "AI service returned empty response"
      end
    when 400
      raise InvalidResponseError, "AI service rejected the request (400): #{response.body}"
    when 404
      raise NetworkError, "AI service endpoint not found (404)"
    when 429
      raise ServiceError, "AI service rate limit exceeded (429)"
    when 500..599
      raise ServiceError, "AI service internal error (#{response.code})"
    else
      raise InvalidResponseError, "AI service returned unexpected status: #{response.code}"
    end
  end
end 