require "net/http"
require "json"
require "uri"
require "timeout"

class AiApiClient
  class ServiceError < StandardError; end
  class TimeoutError < ServiceError; end
  class NetworkError < ServiceError; end
  class InvalidResponseError < ServiceError; end

  # AI service endpoint configuration

  def initialize(agent_type = :create)
    @agent_type = agent_type
    configure_agent
    validate_configuration
    @uri = URI(@service_url)
    Rails.logger.info "AI Service URL configured as: #{@service_url} for agent: #{@agent_type}"
  end

  # Send payload to AI service and return the response
  def create_routine(payload)
    retries = 0

    begin
      response = make_request(payload)
      validate_response(response)
      response.body

    rescue Net::ReadTimeout, Net::OpenTimeout, Timeout::Error => e
      Rails.logger.error "AI API Timeout: #{e.message}"
      raise TimeoutError, "AI service request timed out"

    rescue Net::HTTPError, SocketError, Errno::ECONNREFUSED => e
      Rails.logger.error "AI API Network Error: #{e.message}"

      retries += 1
      if retries <= @max_retries
        Rails.logger.info "Retrying AI API request (attempt #{retries + 1}/#{@max_retries + 1})"
        sleep(2 ** retries) # Exponential backoff: 2s, 4s
        retry
      end

      raise NetworkError, "Unable to connect to AI service after #{@max_retries + 1} attempts"

    rescue JSON::ParserError => e
      Rails.logger.error "AI API JSON Parse Error: #{e.message}"
      raise InvalidResponseError, "AI service returned invalid JSON"

    rescue StandardError => e
      Rails.logger.error "AI API Unexpected Error: #{e.message}"
      raise ServiceError, "Unexpected error communicating with AI service"
    end
  end

  private

  def configure_agent
    case @agent_type
    when :create
      @service_url = ENV["AI_SERVICE_URL"]
      @api_key = ENV["AI_API_KEY"]
      @timeout = (ENV["AI_REQUEST_TIMEOUT"] || 60).to_i
      @max_retries = (ENV["AI_MAX_RETRIES"] || 2).to_i
    when :modify
      @service_url = ENV["AI_MODIFY_SERVICE_URL"]
      @api_key = ENV["AI_MODIFY_API_KEY"]
      @timeout = (ENV["AI_MODIFY_REQUEST_TIMEOUT"] || 60).to_i
      @max_retries = (ENV["AI_MODIFY_MAX_RETRIES"] || 2).to_i
    else
      raise ServiceError, "Unknown agent_type: #{@agent_type}. Use :create or :modify"
    end
  end

  def validate_configuration
    if @service_url.blank?
      raise ServiceError, "AI service URL for #{@agent_type} agent is required but not set"
    end

    if @api_key.blank?
      raise ServiceError, "AI API key for #{@agent_type} agent is required but not set"
    end
  end

  def make_request(payload)
    http = Net::HTTP.new(@uri.host, @uri.port)
    http.read_timeout = @timeout
    http.open_timeout = @timeout

    # Configure SSL for HTTPS URLs
    if @uri.scheme == "https"
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    end

    # Create the request
    request = Net::HTTP::Post.new(@uri)
    request["Content-Type"] = "application/json"
    request["Accept"] = "application/json"
    request["User-Agent"] = "Ruby/Rails SmartLift API Client"

    # Add Authorization header
    if @api_key.present?
      request["Authorization"] = "Bearer #{@api_key}"
    end

    # Set the request body - send the structured payload as JSON
    request.body = payload.to_json

    Rails.logger.info "Sending AI API request to #{@uri}"
    Rails.logger.debug "Request body: #{request.body}" if Rails.env.development?

    # Send the request
    response = http.request(request)

    Rails.logger.info "AI API response status: #{response.code}"
    Rails.logger.debug "AI API response headers: #{response.to_hash}" if Rails.env.development?
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
