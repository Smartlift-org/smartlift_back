require 'rails_helper'

# AI API client tests
RSpec.describe AiApiClient do
  # Mock environment variables for all tests
  before do
    allow(ENV).to receive(:[]).with('AI_SERVICE_URL').and_return('https://api.example.com')
    allow(ENV).to receive(:[]).with('AI_API_KEY').and_return('test-key')
    allow(ENV).to receive(:[]).with('AI_REQUEST_TIMEOUT').and_return('60')
    allow(ENV).to receive(:[]).with('AI_MAX_RETRIES').and_return('2')
  end

  let(:client) { described_class.new }

  # Helper to mock complete HTTP response
  def mock_http_success_response(body)
    mock_response = instance_double(Net::HTTPResponse)
    allow(mock_response).to receive(:code).and_return('200')
    allow(mock_response).to receive(:body).and_return(body)
    allow(mock_response).to receive(:to_hash).and_return({
      'content-type' => ['application/json'],
      'status' => ['200']
    })

    mock_http = instance_double(Net::HTTP)
    allow(Net::HTTP).to receive(:new).and_return(mock_http)
    allow(mock_http).to receive(:read_timeout=)
    allow(mock_http).to receive(:open_timeout=)
    allow(mock_http).to receive(:use_ssl=)
    allow(mock_http).to receive(:verify_mode=)
    allow(mock_http).to receive(:request).and_return(mock_response)
    
    mock_response
  end

  let(:test_prompt) { "Test prompt for AI service" }
  let(:mock_response_body) do
    <<~RESPONSE
      <explicacion>
      Esta es una rutina de prueba generada por el sistema de AI.
      </explicacion>

      <json>
      {
        "days": [
          {
            "day": "Monday",
            "routine": {
              "name": "Test Routine",
              "difficulty": "intermediate",
              "duration": 45,
              "routine_exercises_attributes": []
            }
          }
        ]
      }
      </json>
    RESPONSE
  end

  describe '#create_routine' do
    context 'when API request is successful' do
      it 'returns the response body' do
        # Mock environment variables
        allow(ENV).to receive(:[]).with('AI_SERVICE_URL').and_return('https://api.example.com')
        allow(ENV).to receive(:[]).with('AI_API_KEY').and_return('test-key')
        allow(ENV).to receive(:[]).with('AI_REQUEST_TIMEOUT').and_return('60')
        allow(ENV).to receive(:[]).with('AI_MAX_RETRIES').and_return('2')

        # Create client with mocked env vars
        client = described_class.new

        # Mock successful HTTP response
        mock_response = instance_double(Net::HTTPResponse)
        allow(mock_response).to receive(:code).and_return('200')
        allow(mock_response).to receive(:body).and_return(mock_response_body)
        allow(mock_response).to receive(:to_hash).and_return({
          'content-type' => ['application/json'],
          'status' => ['200']
        })
        allow(mock_response).to receive(:to_hash).and_return({
          'content-type' => ['application/json'],
          'status' => ['200']
        })

        # Mock HTTP client
        mock_http = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:new).and_return(mock_http)
        allow(mock_http).to receive(:read_timeout=)
        allow(mock_http).to receive(:open_timeout=)
        allow(mock_http).to receive(:use_ssl=)
        allow(mock_http).to receive(:verify_mode=)
        allow(mock_http).to receive(:request).and_return(mock_response)

        result = client.create_routine(test_prompt)

        expect(result).to eq(mock_response_body)
      end

      it 'sends correct request body format' do
        mock_response = instance_double(Net::HTTPResponse)
        allow(mock_response).to receive(:code).and_return('200')
        allow(mock_response).to receive(:body).and_return(mock_response_body)
        allow(mock_response).to receive(:to_hash).and_return({
          'content-type' => ['application/json'],
          'status' => ['200']
        })

        mock_http = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:new).and_return(mock_http)
        allow(mock_http).to receive(:read_timeout=)
        allow(mock_http).to receive(:open_timeout=)
        allow(mock_http).to receive(:use_ssl=)
        allow(mock_http).to receive(:verify_mode=)

        # Capture the request to verify its structure
        captured_request = nil
        allow(mock_http).to receive(:request) do |request|
          captured_request = request
          mock_response
        end

        client.create_routine(test_prompt)

        expect(captured_request).to be_a(Net::HTTP::Post)
        expect(captured_request['Content-Type']).to eq('application/json')

        request_body = JSON.parse(captured_request.body)
        expect(request_body['question']).to eq(test_prompt)
      end
    end

    context 'when API request times out' do
      it 'raises TimeoutError for read timeout' do
        mock_http = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:new).and_return(mock_http)
        allow(mock_http).to receive(:read_timeout=)
        allow(mock_http).to receive(:open_timeout=)
        allow(mock_http).to receive(:use_ssl=)
        allow(mock_http).to receive(:verify_mode=)
        allow(mock_http).to receive(:request).and_raise(Net::ReadTimeout)

        expect { client.create_routine(test_prompt) }.to raise_error(
          AiApiClient::TimeoutError,
          /AI service request timed out/
        )
      end

      it 'raises TimeoutError for open timeout' do
        mock_http = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:new).and_return(mock_http)
        allow(mock_http).to receive(:read_timeout=)
        allow(mock_http).to receive(:open_timeout=)
        allow(mock_http).to receive(:use_ssl=)
        allow(mock_http).to receive(:verify_mode=)
        allow(mock_http).to receive(:request).and_raise(Net::OpenTimeout)

        expect { client.create_routine(test_prompt) }.to raise_error(
          AiApiClient::TimeoutError,
          /AI service request timed out/
        )
      end

      it 'raises TimeoutError for general timeout' do
        mock_http = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:new).and_return(mock_http)
        allow(mock_http).to receive(:read_timeout=)
        allow(mock_http).to receive(:open_timeout=)
        allow(mock_http).to receive(:use_ssl=)
        allow(mock_http).to receive(:verify_mode=)
        allow(mock_http).to receive(:request).and_raise(Timeout::Error)

        expect { client.create_routine(test_prompt) }.to raise_error(
          AiApiClient::TimeoutError,
          /AI service request timed out/
        )
      end
    end

    context 'when API request has network issues' do
      it 'retries on connection refused and then raises NetworkError' do
        mock_http = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:new).and_return(mock_http)
        allow(mock_http).to receive(:read_timeout=)
        allow(mock_http).to receive(:open_timeout=)
        allow(mock_http).to receive(:use_ssl=)
        allow(mock_http).to receive(:verify_mode=)
        allow(mock_http).to receive(:request).and_raise(Errno::ECONNREFUSED)

        # Mock sleep to speed up test
        allow_any_instance_of(Object).to receive(:sleep)

        expect { client.create_routine(test_prompt) }.to raise_error(
          AiApiClient::NetworkError,
          /Unable to connect to AI service after 3 attempts/
        )
      end

      it 'retries with exponential backoff' do
        mock_http = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:new).and_return(mock_http)
        allow(mock_http).to receive(:read_timeout=)
        allow(mock_http).to receive(:open_timeout=)
        allow(mock_http).to receive(:use_ssl=)
        allow(mock_http).to receive(:verify_mode=)
        allow(mock_http).to receive(:request).and_raise(SocketError)

        # Track sleep calls to verify exponential backoff
        sleep_calls = []
        allow_any_instance_of(Object).to receive(:sleep) { |_, duration| sleep_calls << duration }

        expect { client.create_routine(test_prompt) }.to raise_error(AiApiClient::NetworkError)
        expect(sleep_calls).to eq([ 2, 4 ]) # 2^1, 2^2
      end
    end

    context 'when API returns error status codes' do
      it 'raises InvalidResponseError for 400 Bad Request' do
        mock_response = instance_double(Net::HTTPResponse)
        allow(mock_response).to receive(:code).and_return('400')
        allow(mock_response).to receive(:to_hash).and_return({
          'content-type' => ['application/json'],
          'status' => ['400']
        })
        allow(mock_response).to receive(:body).and_return('Bad request')

        mock_http = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:new).and_return(mock_http)
        allow(mock_http).to receive(:read_timeout=)
        allow(mock_http).to receive(:open_timeout=)
        allow(mock_http).to receive(:use_ssl=)
        allow(mock_http).to receive(:verify_mode=)
        allow(mock_http).to receive(:request).and_return(mock_response)

        expect { client.create_routine(test_prompt) }.to raise_error(
          AiApiClient::InvalidResponseError,
          /AI service rejected the request \(400\)/
        )
      end

      it 'raises NetworkError for 404 Not Found' do
        mock_response = instance_double(Net::HTTPResponse)
        allow(mock_response).to receive(:code).and_return('404')
        allow(mock_response).to receive(:to_hash).and_return({
          'content-type' => ['application/json'],
          'status' => ['404']
        })

        mock_http = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:new).and_return(mock_http)
        allow(mock_http).to receive(:read_timeout=)
        allow(mock_http).to receive(:open_timeout=)
        allow(mock_http).to receive(:use_ssl=)
        allow(mock_http).to receive(:verify_mode=)
        allow(mock_http).to receive(:request).and_return(mock_response)

        expect { client.create_routine(test_prompt) }.to raise_error(
          AiApiClient::NetworkError,
          /AI service endpoint not found \(404\)/
        )
      end

      it 'raises ServiceError for 429 Rate Limit' do
        mock_response = instance_double(Net::HTTPResponse)
        allow(mock_response).to receive(:code).and_return('429')
        allow(mock_response).to receive(:to_hash).and_return({
          'content-type' => ['application/json'],
          'status' => ['429']
        })

        mock_http = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:new).and_return(mock_http)
        allow(mock_http).to receive(:read_timeout=)
        allow(mock_http).to receive(:open_timeout=)
        allow(mock_http).to receive(:use_ssl=)
        allow(mock_http).to receive(:verify_mode=)
        allow(mock_http).to receive(:request).and_return(mock_response)

        expect { client.create_routine(test_prompt) }.to raise_error(
          AiApiClient::ServiceError,
          /AI service rate limit exceeded \(429\)/
        )
      end

      it 'raises ServiceError for 500 Internal Server Error' do
        mock_response = instance_double(Net::HTTPResponse)
        allow(mock_response).to receive(:code).and_return('500')
        allow(mock_response).to receive(:to_hash).and_return({
          'content-type' => ['application/json'],
          'status' => ['500']
        })

        mock_http = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:new).and_return(mock_http)
        allow(mock_http).to receive(:read_timeout=)
        allow(mock_http).to receive(:open_timeout=)
        allow(mock_http).to receive(:use_ssl=)
        allow(mock_http).to receive(:verify_mode=)
        allow(mock_http).to receive(:request).and_return(mock_response)

        expect { client.create_routine(test_prompt) }.to raise_error(
          AiApiClient::ServiceError,
          /AI service internal error \(500\)/
        )
      end

      it 'raises InvalidResponseError for unexpected status codes' do
        mock_response = instance_double(Net::HTTPResponse)
        allow(mock_response).to receive(:code).and_return('418') # I'm a teapot
        allow(mock_response).to receive(:to_hash).and_return({
          'content-type' => ['application/json'],
          'status' => ['418']
        })

        mock_http = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:new).and_return(mock_http)
        allow(mock_http).to receive(:read_timeout=)
        allow(mock_http).to receive(:open_timeout=)
        allow(mock_http).to receive(:use_ssl=)
        allow(mock_http).to receive(:verify_mode=)
        allow(mock_http).to receive(:request).and_return(mock_response)

        expect { client.create_routine(test_prompt) }.to raise_error(
          AiApiClient::InvalidResponseError,
          /AI service returned unexpected status: 418/
        )
      end
    end

    context 'when API returns empty response' do
      it 'raises InvalidResponseError' do
        mock_response = instance_double(Net::HTTPResponse)
        allow(mock_response).to receive(:code).and_return('200')
        allow(mock_response).to receive(:body).and_return('')
        allow(mock_response).to receive(:to_hash).and_return({
          'content-type' => ['application/json'],
          'status' => ['200']
        })

        mock_http = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:new).and_return(mock_http)
        allow(mock_http).to receive(:read_timeout=)
        allow(mock_http).to receive(:open_timeout=)
        allow(mock_http).to receive(:use_ssl=)
        allow(mock_http).to receive(:verify_mode=)
        allow(mock_http).to receive(:request).and_return(mock_response)

        expect { client.create_routine(test_prompt) }.to raise_error(
          AiApiClient::InvalidResponseError,
          /AI service returned empty response/
        )
      end
    end
  end

  describe 'configuration' do
    it 'configures create agent correctly with environment variables' do
      allow(ENV).to receive(:[]).with('AI_SERVICE_URL').and_return('https://create.example.com')
      allow(ENV).to receive(:[]).with('AI_API_KEY').and_return('create-key')
      allow(ENV).to receive(:[]).with('AI_REQUEST_TIMEOUT').and_return('30')
      allow(ENV).to receive(:[]).with('AI_MAX_RETRIES').and_return('1')

      client = described_class.new(:create)

      expect(client.instance_variable_get(:@service_url)).to eq('https://create.example.com')
      expect(client.instance_variable_get(:@api_key)).to eq('create-key')
      expect(client.instance_variable_get(:@timeout)).to eq(30)
      expect(client.instance_variable_get(:@max_retries)).to eq(1)
    end

    it 'configures modify agent correctly with environment variables' do
      allow(ENV).to receive(:[]).with('AI_MODIFY_SERVICE_URL').and_return('https://modify.example.com')
      allow(ENV).to receive(:[]).with('AI_MODIFY_API_KEY').and_return('modify-key')
      allow(ENV).to receive(:[]).with('AI_MODIFY_REQUEST_TIMEOUT').and_return('45')
      allow(ENV).to receive(:[]).with('AI_MODIFY_MAX_RETRIES').and_return('3')

      client = described_class.new(:modify)

      expect(client.instance_variable_get(:@service_url)).to eq('https://modify.example.com')
      expect(client.instance_variable_get(:@api_key)).to eq('modify-key')
      expect(client.instance_variable_get(:@timeout)).to eq(45)
      expect(client.instance_variable_get(:@max_retries)).to eq(3)
    end

    it 'uses default timeout and retry values when env vars not set' do
      allow(ENV).to receive(:[]).with('AI_SERVICE_URL').and_return('https://example.com')
      allow(ENV).to receive(:[]).with('AI_API_KEY').and_return('key')
      allow(ENV).to receive(:[]).with('AI_REQUEST_TIMEOUT').and_return(nil)
      allow(ENV).to receive(:[]).with('AI_MAX_RETRIES').and_return(nil)

      client = described_class.new(:create)

      expect(client.instance_variable_get(:@timeout)).to eq(60)
      expect(client.instance_variable_get(:@max_retries)).to eq(2)
    end
  end

  describe 'logging' do
    it 'logs API requests in development' do
      allow(Rails.env).to receive(:development?).and_return(true)

      mock_response = instance_double(Net::HTTPResponse)
      allow(mock_response).to receive(:code).and_return('200')
      allow(mock_response).to receive(:body).and_return(mock_response_body)

      mock_http = instance_double(Net::HTTP)
      allow(Net::HTTP).to receive(:new).and_return(mock_http)
      allow(mock_http).to receive(:read_timeout=)
      allow(mock_http).to receive(:open_timeout=)
      allow(mock_http).to receive(:request).and_return(mock_response)

      expect(Rails.logger).to receive(:info).with(/Sending AI API request/)
      expect(Rails.logger).to receive(:debug).with(/Request body:/)
      expect(Rails.logger).to receive(:info).with(/AI API response status: 200/)
      expect(Rails.logger).to receive(:debug).with(/AI API response body:/)

      client.create_routine(test_prompt)
    end

    it 'logs errors appropriately' do
      mock_http = instance_double(Net::HTTP)
      allow(Net::HTTP).to receive(:new).and_return(mock_http)
      allow(mock_http).to receive(:read_timeout=)
      allow(mock_http).to receive(:open_timeout=)
      allow(mock_http).to receive(:request).and_raise(Net::ReadTimeout)

      expect(Rails.logger).to receive(:error).with(/AI API Timeout/)

      expect { client.create_routine(test_prompt) }.to raise_error(AiApiClient::TimeoutError)
    end
  end

  # Additional comprehensive tests for retry mechanism and edge cases

  describe 'retry mechanism with detailed scenarios' do
    context 'with different failure types' do
      it 'retries exactly the configured number of times for network errors' do
        allow(ENV).to receive(:[]).with('AI_MAX_RETRIES').and_return('3')
        client = described_class.new

        mock_http = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:new).and_return(mock_http)
        allow(mock_http).to receive(:read_timeout=)
        allow(mock_http).to receive(:open_timeout=)
        allow(mock_http).to receive(:use_ssl=)
        allow(mock_http).to receive(:verify_mode=)

        # Track number of attempts
        attempt_count = 0
        allow(mock_http).to receive(:request) do
          attempt_count += 1
          raise Errno::ECONNREFUSED
        end

        # Mock sleep to speed up test
        allow_any_instance_of(Object).to receive(:sleep)

        expect { client.create_routine(test_prompt) }.to raise_error(AiApiClient::NetworkError)
        expect(attempt_count).to eq(4) # Initial attempt + 3 retries
      end

      it 'does not retry for timeout errors' do
        mock_http = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:new).and_return(mock_http)
        allow(mock_http).to receive(:read_timeout=)
        allow(mock_http).to receive(:open_timeout=)
        allow(mock_http).to receive(:use_ssl=)
        allow(mock_http).to receive(:verify_mode=)

        attempt_count = 0
        allow(mock_http).to receive(:request) do
          attempt_count += 1
          raise Net::ReadTimeout
        end

        expect { client.create_routine(test_prompt) }.to raise_error(AiApiClient::TimeoutError)
        expect(attempt_count).to eq(1) # No retries for timeout
      end

      it 'succeeds on second attempt after first failure' do
        mock_http = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:new).and_return(mock_http)
        allow(mock_http).to receive(:read_timeout=)
        allow(mock_http).to receive(:open_timeout=)
        allow(mock_http).to receive(:use_ssl=)
        allow(mock_http).to receive(:verify_mode=)

        attempt_count = 0
        allow(mock_http).to receive(:request) do
          attempt_count += 1
          if attempt_count == 1
            raise SocketError, 'Network unreachable'
          else
            mock_response = instance_double(Net::HTTPResponse)
            allow(mock_response).to receive(:code).and_return('200')
            allow(mock_response).to receive(:body).and_return(mock_response_body)
            allow(mock_response).to receive(:to_hash).and_return({
              'content-type' => ['application/json'],
              'status' => ['200']
            })
            mock_response
          end
        end

        # Mock sleep to speed up test
        allow_any_instance_of(Object).to receive(:sleep)

        result = client.create_routine(test_prompt)
        expect(result).to eq(mock_response_body)
        expect(attempt_count).to eq(2)
      end
    end

    context 'with exponential backoff verification' do
      it 'uses correct exponential backoff timing' do
        mock_http = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:new).and_return(mock_http)
        allow(mock_http).to receive(:read_timeout=)
        allow(mock_http).to receive(:open_timeout=)
        allow(mock_http).to receive(:use_ssl=)
        allow(mock_http).to receive(:verify_mode=)
        allow(mock_http).to receive(:request).and_raise(Errno::ECONNREFUSED)

        sleep_durations = []
        allow_any_instance_of(Object).to receive(:sleep) { |_, duration| sleep_durations << duration }

        expect { client.create_routine(test_prompt) }.to raise_error(AiApiClient::NetworkError)
        expect(sleep_durations).to eq([2, 4]) # 2^1, 2^2 for default 2 retries
      end

      it 'uses correct backoff with custom retry count' do
        allow(ENV).to receive(:[]).with('AI_MAX_RETRIES').and_return('4')
        client = described_class.new

        mock_http = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:new).and_return(mock_http)
        allow(mock_http).to receive(:read_timeout=)
        allow(mock_http).to receive(:open_timeout=)
        allow(mock_http).to receive(:use_ssl=)
        allow(mock_http).to receive(:verify_mode=)
        allow(mock_http).to receive(:request).and_raise(SocketError)

        sleep_durations = []
        allow_any_instance_of(Object).to receive(:sleep) { |_, duration| sleep_durations << duration }

        expect { client.create_routine(test_prompt) }.to raise_error(AiApiClient::NetworkError)
        expect(sleep_durations).to eq([2, 4, 8, 16]) # 2^1, 2^2, 2^3, 2^4
      end
    end
  end

  describe 'comprehensive response validation' do
    context 'with edge case response bodies' do
      it 'handles response with only whitespace' do
        mock_response = instance_double(Net::HTTPResponse)
        allow(mock_response).to receive(:code).and_return('200')
        allow(mock_response).to receive(:body).and_return('   \n\t   ')
        allow(mock_response).to receive(:to_hash).and_return({
          'content-type' => ['application/json'],
          'status' => ['200']
        })

        mock_http = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:new).and_return(mock_http)
        allow(mock_http).to receive(:read_timeout=)
        allow(mock_http).to receive(:open_timeout=)
        allow(mock_http).to receive(:use_ssl=)
        allow(mock_http).to receive(:verify_mode=)
        allow(mock_http).to receive(:request).and_return(mock_response)

        expect { client.create_routine(test_prompt) }.to raise_error(
          AiApiClient::InvalidResponseError,
          /AI service returned empty response/
        )
      end

      it 'handles extremely large response body' do
        large_body = 'x' * 10_000_000  # 10MB response

        mock_response = instance_double(Net::HTTPResponse)
        allow(mock_response).to receive(:code).and_return('200')
        allow(mock_response).to receive(:body).and_return(large_body)
        allow(mock_response).to receive(:to_hash).and_return({
          'content-type' => ['application/json'],
          'status' => ['200']
        })

        mock_http = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:new).and_return(mock_http)
        allow(mock_http).to receive(:read_timeout=)
        allow(mock_http).to receive(:open_timeout=)
        allow(mock_http).to receive(:use_ssl=)
        allow(mock_http).to receive(:verify_mode=)
        allow(mock_http).to receive(:request).and_return(mock_response)

        result = client.create_routine(test_prompt)
        expect(result).to eq(large_body)
      end

      it 'handles response with binary content' do
        binary_content = "\x00\x01\x02\xFF\xFE"

        mock_response = instance_double(Net::HTTPResponse)
        allow(mock_response).to receive(:code).and_return('200')
        allow(mock_response).to receive(:body).and_return(binary_content)
        allow(mock_response).to receive(:to_hash).and_return({
          'content-type' => ['application/json'],
          'status' => ['200']
        })

        mock_http = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:new).and_return(mock_http)
        allow(mock_http).to receive(:read_timeout=)
        allow(mock_http).to receive(:open_timeout=)
        allow(mock_http).to receive(:use_ssl=)
        allow(mock_http).to receive(:verify_mode=)
        allow(mock_http).to receive(:request).and_return(mock_response)

        result = client.create_routine(test_prompt)
        expect(result).to eq(binary_content)
      end
    end

    context 'with additional HTTP status codes' do
      it 'handles 401 Unauthorized' do
        mock_response = instance_double(Net::HTTPResponse)
        allow(mock_response).to receive(:code).and_return('401')
        allow(mock_response).to receive(:body).and_return('Unauthorized')
        allow(mock_response).to receive(:to_hash).and_return({
          'content-type' => ['application/json'],
          'status' => ['401']
        })

        mock_http = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:new).and_return(mock_http)
        allow(mock_http).to receive(:read_timeout=)
        allow(mock_http).to receive(:open_timeout=)
        allow(mock_http).to receive(:use_ssl=)
        allow(mock_http).to receive(:verify_mode=)
        allow(mock_http).to receive(:request).and_return(mock_response)

        expect { client.create_routine(test_prompt) }.to raise_error(
          AiApiClient::InvalidResponseError,
          /AI service rejected the request \(401\)/
        )
      end

      it 'handles 403 Forbidden' do
        mock_response = instance_double(Net::HTTPResponse)
        allow(mock_response).to receive(:code).and_return('403')
        allow(mock_response).to receive(:body).and_return('Forbidden')
        allow(mock_response).to receive(:to_hash).and_return({
          'content-type' => ['application/json'],
          'status' => ['403']
        })

        mock_http = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:new).and_return(mock_http)
        allow(mock_http).to receive(:read_timeout=)
        allow(mock_http).to receive(:open_timeout=)
        allow(mock_http).to receive(:use_ssl=)
        allow(mock_http).to receive(:verify_mode=)
        allow(mock_http).to receive(:request).and_return(mock_response)

        expect { client.create_routine(test_prompt) }.to raise_error(
          AiApiClient::InvalidResponseError,
          /AI service rejected the request \(403\)/
        )
      end

      it 'handles 502 Bad Gateway' do
        mock_response = instance_double(Net::HTTPResponse)
        allow(mock_response).to receive(:code).and_return('502')
        allow(mock_response).to receive(:to_hash).and_return({
          'content-type' => ['application/json'],
          'status' => ['502']
        })

        mock_http = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:new).and_return(mock_http)
        allow(mock_http).to receive(:read_timeout=)
        allow(mock_http).to receive(:open_timeout=)
        allow(mock_http).to receive(:use_ssl=)
        allow(mock_http).to receive(:verify_mode=)
        allow(mock_http).to receive(:request).and_return(mock_response)

        expect { client.create_routine(test_prompt) }.to raise_error(
          AiApiClient::ServiceError,
          /AI service internal error \(502\)/
        )
      end

      it 'handles 503 Service Unavailable' do
        mock_response = instance_double(Net::HTTPResponse)
        allow(mock_response).to receive(:code).and_return('503')
        allow(mock_response).to receive(:to_hash).and_return({
          'content-type' => ['application/json'],
          'status' => ['503']
        })

        mock_http = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:new).and_return(mock_http)
        allow(mock_http).to receive(:read_timeout=)
        allow(mock_http).to receive(:open_timeout=)
        allow(mock_http).to receive(:use_ssl=)
        allow(mock_http).to receive(:verify_mode=)
        allow(mock_http).to receive(:request).and_return(mock_response)

        expect { client.create_routine(test_prompt) }.to raise_error(
          AiApiClient::ServiceError,
          /AI service internal error \(503\)/
        )
      end
    end
  end

  describe 'configuration edge cases' do
    context 'with invalid environment variables' do
      it 'handles non-numeric timeout values' do
        allow(ENV).to receive(:[]).with('AI_SERVICE_URL').and_return('https://example.com')
        allow(ENV).to receive(:[]).with('AI_API_KEY').and_return('key')
        allow(ENV).to receive(:[]).with('AI_REQUEST_TIMEOUT').and_return('not_a_number')
        allow(ENV).to receive(:[]).with('AI_MAX_RETRIES').and_return('2')

        client = described_class.new

        expect(client.instance_variable_get(:@timeout)).to eq(0) # to_i converts invalid string to 0
      end

      it 'handles negative retry values' do
        allow(ENV).to receive(:[]).with('AI_SERVICE_URL').and_return('https://example.com')
        allow(ENV).to receive(:[]).with('AI_API_KEY').and_return('key')
        allow(ENV).to receive(:[]).with('AI_REQUEST_TIMEOUT').and_return('60')
        allow(ENV).to receive(:[]).with('AI_MAX_RETRIES').and_return('-1')

        client = described_class.new

        expect(client.instance_variable_get(:@max_retries)).to eq(-1)
      end

      it 'validates missing service URL for create agent' do
        allow(ENV).to receive(:[]).with('AI_SERVICE_URL').and_return(nil)
        allow(ENV).to receive(:[]).with('AI_API_KEY').and_return('key')

        expect { described_class.new(:create) }.to raise_error(
          AiApiClient::ServiceError,
          /AI service URL for create agent is required but not set/
        )
      end

      it 'validates missing API key for modify agent' do
        allow(ENV).to receive(:[]).with('AI_MODIFY_SERVICE_URL').and_return('https://example.com')
        allow(ENV).to receive(:[]).with('AI_MODIFY_API_KEY').and_return('')

        expect { described_class.new(:modify) }.to raise_error(
          AiApiClient::ServiceError,
          /AI API key for modify agent is required but not set/
        )
      end

      it 'raises error for unknown agent type' do
        expect { described_class.new(:unknown_agent) }.to raise_error(
          AiApiClient::ServiceError,
          /Unknown agent_type: unknown_agent. Use :create or :modify/
        )
      end
    end
  end

  describe 'request construction edge cases' do
    it 'handles very long prompt inputs' do
      very_long_prompt = 'A' * 100_000  # 100KB prompt

      mock_response = instance_double(Net::HTTPResponse)
      allow(mock_response).to receive(:code).and_return('200')
      allow(mock_response).to receive(:body).and_return(mock_response_body)
      allow(mock_response).to receive(:to_hash).and_return({
        'content-type' => ['application/json'],
        'status' => ['200']
      })

      mock_http = instance_double(Net::HTTP)
      allow(Net::HTTP).to receive(:new).and_return(mock_http)
      allow(mock_http).to receive(:read_timeout=)
      allow(mock_http).to receive(:open_timeout=)
      allow(mock_http).to receive(:use_ssl=)
      allow(mock_http).to receive(:verify_mode=)

      captured_request = nil
      allow(mock_http).to receive(:request) do |request|
        captured_request = request
        mock_response
      end

      client.create_routine(very_long_prompt)

      request_body = JSON.parse(captured_request.body)
      expect(request_body['question']).to eq(very_long_prompt)
      expect(request_body['question'].length).to eq(100_000)
    end

    it 'handles prompt with special characters and unicode' do
      special_prompt = "Test with émöjis 💪🏋️‍♂️ and spëcîål characters: àáâãäåæçèéêë\nNewlines\tTabs"

      mock_response = instance_double(Net::HTTPResponse)
      allow(mock_response).to receive(:code).and_return('200')
      allow(mock_response).to receive(:body).and_return(mock_response_body)
      allow(mock_response).to receive(:to_hash).and_return({
        'content-type' => ['application/json'],
        'status' => ['200']
      })

      mock_http = instance_double(Net::HTTP)
      allow(Net::HTTP).to receive(:new).and_return(mock_http)
      allow(mock_http).to receive(:read_timeout=)
      allow(mock_http).to receive(:open_timeout=)
      allow(mock_http).to receive(:use_ssl=)
      allow(mock_http).to receive(:verify_mode=)

      captured_request = nil
      allow(mock_http).to receive(:request) do |request|
        captured_request = request
        mock_response
      end

      client.create_routine(special_prompt)

      request_body = JSON.parse(captured_request.body)
      expect(request_body['question']).to eq(special_prompt)
      expect(request_body['question']).to include('💪🏋️‍♂️')
      expect(request_body['question']).to include('àáâãäåæçèéêë')
    end

    it 'sets correct headers for all requests' do
      mock_response = instance_double(Net::HTTPResponse)
      allow(mock_response).to receive(:code).and_return('200')
      allow(mock_response).to receive(:body).and_return(mock_response_body)
      allow(mock_response).to receive(:to_hash).and_return({
        'content-type' => ['application/json'],
        'status' => ['200']
      })

      mock_http = instance_double(Net::HTTP)
      allow(Net::HTTP).to receive(:new).and_return(mock_http)
      allow(mock_http).to receive(:read_timeout=)
      allow(mock_http).to receive(:open_timeout=)
      allow(mock_http).to receive(:use_ssl=)
      allow(mock_http).to receive(:verify_mode=)

      captured_request = nil
      allow(mock_http).to receive(:request) do |request|
        captured_request = request
        mock_response
      end

      client.create_routine(test_prompt)

      expect(captured_request['Content-Type']).to eq('application/json')
      expect(captured_request['Accept']).to eq('application/json')
      expect(captured_request['User-Agent']).to eq('Ruby/Rails SmartLift API Client')
      expect(captured_request['Authorization']).to eq('Bearer test-key')
    end
  end
end
