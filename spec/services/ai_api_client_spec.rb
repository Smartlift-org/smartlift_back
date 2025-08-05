require 'rails_helper'

# AI API client tests
RSpec.describe AiApiClient, skip: "AI functionality not finished" do
  let(:client) { described_class.new }
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

  describe '#generate_routine' do
    context 'when API request is successful' do
      it 'returns the response body' do
        # Mock successful HTTP response
        mock_response = instance_double(Net::HTTPResponse)
        allow(mock_response).to receive(:code).and_return('200')
        allow(mock_response).to receive(:body).and_return(mock_response_body)

        # Mock HTTP client
        mock_http = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:new).and_return(mock_http)
        allow(mock_http).to receive(:read_timeout=)
        allow(mock_http).to receive(:open_timeout=)
        allow(mock_http).to receive(:request).and_return(mock_response)

        result = client.generate_routine(test_prompt)

        expect(result).to eq(mock_response_body)
      end

      it 'sends correct request body format' do
        mock_response = instance_double(Net::HTTPResponse)
        allow(mock_response).to receive(:code).and_return('200')
        allow(mock_response).to receive(:body).and_return(mock_response_body)

        mock_http = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:new).and_return(mock_http)
        allow(mock_http).to receive(:read_timeout=)
        allow(mock_http).to receive(:open_timeout=)

        # Capture the request to verify its structure
        captured_request = nil
        allow(mock_http).to receive(:request) do |request|
          captured_request = request
          mock_response
        end

        client.generate_routine(test_prompt)

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
        allow(mock_http).to receive(:request).and_raise(Net::ReadTimeout)

        expect { client.generate_routine(test_prompt) }.to raise_error(
          AiApiClient::TimeoutError,
          /AI service request timed out/
        )
      end

      it 'raises TimeoutError for open timeout' do
        mock_http = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:new).and_return(mock_http)
        allow(mock_http).to receive(:read_timeout=)
        allow(mock_http).to receive(:open_timeout=)
        allow(mock_http).to receive(:request).and_raise(Net::OpenTimeout)

        expect { client.generate_routine(test_prompt) }.to raise_error(
          AiApiClient::TimeoutError,
          /AI service request timed out/
        )
      end

      it 'raises TimeoutError for general timeout' do
        mock_http = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:new).and_return(mock_http)
        allow(mock_http).to receive(:read_timeout=)
        allow(mock_http).to receive(:open_timeout=)
        allow(mock_http).to receive(:request).and_raise(Timeout::Error)

        expect { client.generate_routine(test_prompt) }.to raise_error(
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
        allow(mock_http).to receive(:request).and_raise(Errno::ECONNREFUSED)

        # Mock sleep to speed up test
        allow_any_instance_of(Object).to receive(:sleep)

        expect { client.generate_routine(test_prompt) }.to raise_error(
          AiApiClient::NetworkError,
          /Unable to connect to AI service after 3 attempts/
        )
      end

      it 'retries with exponential backoff' do
        mock_http = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:new).and_return(mock_http)
        allow(mock_http).to receive(:read_timeout=)
        allow(mock_http).to receive(:open_timeout=)
        allow(mock_http).to receive(:request).and_raise(SocketError)

        # Track sleep calls to verify exponential backoff
        sleep_calls = []
        allow_any_instance_of(Object).to receive(:sleep) { |_, duration| sleep_calls << duration }

        expect { client.generate_routine(test_prompt) }.to raise_error(AiApiClient::NetworkError)
        expect(sleep_calls).to eq([ 2, 4 ]) # 2^1, 2^2
      end
    end

    context 'when API returns error status codes' do
      it 'raises InvalidResponseError for 400 Bad Request' do
        mock_response = instance_double(Net::HTTPResponse)
        allow(mock_response).to receive(:code).and_return('400')
        allow(mock_response).to receive(:body).and_return('Bad request')

        mock_http = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:new).and_return(mock_http)
        allow(mock_http).to receive(:read_timeout=)
        allow(mock_http).to receive(:open_timeout=)
        allow(mock_http).to receive(:request).and_return(mock_response)

        expect { client.generate_routine(test_prompt) }.to raise_error(
          AiApiClient::InvalidResponseError,
          /AI service rejected the request \(400\)/
        )
      end

      it 'raises NetworkError for 404 Not Found' do
        mock_response = instance_double(Net::HTTPResponse)
        allow(mock_response).to receive(:code).and_return('404')

        mock_http = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:new).and_return(mock_http)
        allow(mock_http).to receive(:read_timeout=)
        allow(mock_http).to receive(:open_timeout=)
        allow(mock_http).to receive(:request).and_return(mock_response)

        expect { client.generate_routine(test_prompt) }.to raise_error(
          AiApiClient::NetworkError,
          /AI service endpoint not found \(404\)/
        )
      end

      it 'raises ServiceError for 429 Rate Limit' do
        mock_response = instance_double(Net::HTTPResponse)
        allow(mock_response).to receive(:code).and_return('429')

        mock_http = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:new).and_return(mock_http)
        allow(mock_http).to receive(:read_timeout=)
        allow(mock_http).to receive(:open_timeout=)
        allow(mock_http).to receive(:request).and_return(mock_response)

        expect { client.generate_routine(test_prompt) }.to raise_error(
          AiApiClient::ServiceError,
          /AI service rate limit exceeded \(429\)/
        )
      end

      it 'raises ServiceError for 500 Internal Server Error' do
        mock_response = instance_double(Net::HTTPResponse)
        allow(mock_response).to receive(:code).and_return('500')

        mock_http = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:new).and_return(mock_http)
        allow(mock_http).to receive(:read_timeout=)
        allow(mock_http).to receive(:open_timeout=)
        allow(mock_http).to receive(:request).and_return(mock_response)

        expect { client.generate_routine(test_prompt) }.to raise_error(
          AiApiClient::ServiceError,
          /AI service internal error \(500\)/
        )
      end

      it 'raises InvalidResponseError for unexpected status codes' do
        mock_response = instance_double(Net::HTTPResponse)
        allow(mock_response).to receive(:code).and_return('418') # I'm a teapot

        mock_http = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:new).and_return(mock_http)
        allow(mock_http).to receive(:read_timeout=)
        allow(mock_http).to receive(:open_timeout=)
        allow(mock_http).to receive(:request).and_return(mock_response)

        expect { client.generate_routine(test_prompt) }.to raise_error(
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

        mock_http = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:new).and_return(mock_http)
        allow(mock_http).to receive(:read_timeout=)
        allow(mock_http).to receive(:open_timeout=)
        allow(mock_http).to receive(:request).and_return(mock_response)

        expect { client.generate_routine(test_prompt) }.to raise_error(
          AiApiClient::InvalidResponseError,
          /AI service returned empty response/
        )
      end
    end
  end

  describe 'configuration' do
    it 'uses correct API endpoint pattern' do
      # The URL is now dynamic based on environment
      expect(AiApiClient::AI_SERVICE_URL).to match(/http:\/\/.+:3000\/api\/v1\/prediction\/53773a52-4eac-42b8-a5d0-4f9aa5e20529/)
    end

    it 'uses correct timeout settings' do
      expect(AiApiClient::REQUEST_TIMEOUT).to be >= 60
    end

    it 'uses correct retry settings' do
      expect(AiApiClient::MAX_RETRIES).to be >= 2
    end

    it 'allows configuration via environment variables' do
      # Test that environment variables can override defaults
      ENV['AI_SERVICE_HOST'] = 'custom-host'
      ENV['AI_SERVICE_PORT'] = '8080'

      # Need to reload the constant
      Object.send(:remove_const, :AiApiClient) if defined?(AiApiClient)
      load 'app/services/ai_api_client.rb'

      expect(AiApiClient::AI_SERVICE_URL).to include('custom-host:8080')

      # Clean up
      ENV.delete('AI_SERVICE_HOST')
      ENV.delete('AI_SERVICE_PORT')
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

      client.generate_routine(test_prompt)
    end

    it 'logs errors appropriately' do
      mock_http = instance_double(Net::HTTP)
      allow(Net::HTTP).to receive(:new).and_return(mock_http)
      allow(mock_http).to receive(:read_timeout=)
      allow(mock_http).to receive(:open_timeout=)
      allow(mock_http).to receive(:request).and_raise(Net::ReadTimeout)

      expect(Rails.logger).to receive(:error).with(/AI API Timeout/)

      expect { client.generate_routine(test_prompt) }.to raise_error(AiApiClient::TimeoutError)
    end
  end
end
