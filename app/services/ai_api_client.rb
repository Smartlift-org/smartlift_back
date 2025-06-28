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
  # Use environment variable if set, otherwise use default based on environment
  # For Docker: host.docker.internal allows accessing host services
  # For local development: use localhost
  DEFAULT_AI_HOST = ENV['AI_SERVICE_HOST'] || (Rails.env.development? ? 'host.docker.internal' : 'localhost')
  DEFAULT_AI_PORT = ENV['AI_SERVICE_PORT'] || '4000'
  AI_SERVICE_URL = ENV['AI_SERVICE_URL'] || "http://#{DEFAULT_AI_HOST}:#{DEFAULT_AI_PORT}/api/v1/prediction/53773a52-4eac-42b8-a5d0-4f9aa5e20529"
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
    
    # Create the request
    request = Net::HTTP::Post.new(@uri)
    request['Content-Type'] = 'application/json'
    
    # Set the request body
    request.body = {
      question: prompt
    }.to_json
    
    Rails.logger.info "Sending AI API request to #{@uri}"
    Rails.logger.debug "Request body: #{request.body}" if Rails.env.development?
    
    # Send the request
    response = http.request(request)
    
    Rails.logger.info "AI API response status: #{response.code}"
    Rails.logger.debug "AI API response body: #{response.body}" if Rails.env.development?
    
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