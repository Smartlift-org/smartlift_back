require 'rails_helper'

RSpec.describe Api::V1::AiWorkoutRoutinesController, type: :controller do
  # Sample valid parameters
  let(:valid_params) do
    {
      age: 30,
      gender: 'male',
      weight: 80,
      height: 175,
      experience_level: 'intermediate',
      equipment: ['barbell', 'dumbbell'],
      preferences: 'No cardio, solo tren superior',
      frequency_per_week: 3,
      time_per_session: 45,
      goal: 'ganar masa muscular'
    }
  end

  let(:mock_ai_response) do
    {
      explanation: 'Esta rutina fue diseñada para maximizar el crecimiento muscular...',
      routine: {
        days: [
          {
            day: 'Monday',
            routine: {
              name: 'Upper Body Strength',
              description: 'Focus on chest, shoulders and triceps',
              difficulty: 'intermediate',
              duration: 45,
              routine_exercises_attributes: [
                {
                  exercise_id: 1,
                  sets: 4,
                  reps: 10,
                  rest_time: 60,
                  order: 1
                }
              ]
            }
          }
        ]
      }
    }
  end

  before do
    # Create a test exercise for validation
    FactoryBot.create(:exercise, id: 1, name: 'Push-up', equipment: 'body only')
  end

  describe 'POST #create' do
    context 'with valid parameters' do
      it 'returns success response with AI-generated routine' do
        # Mock the AI service
        mock_service = instance_double(AiWorkoutRoutineService)
        allow(AiWorkoutRoutineService).to receive(:new).and_return(mock_service)
        allow(mock_service).to receive(:generate_routine).and_return(mock_ai_response)

        post :create, params: valid_params

        expect(response).to have_http_status(:ok)
        
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response['data']['explanation']).to eq(mock_ai_response[:explanation])
        expect(json_response['data']['routine']).to eq(mock_ai_response[:routine].deep_stringify_keys)
        expect(json_response['data']['generated_at']).to be_present
      end
    end

    context 'with invalid parameters' do
      it 'returns validation error for missing age' do
        invalid_params = valid_params.except(:age)
        
        post :create, params: invalid_params

        expect(response).to have_http_status(:bad_request)
        
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be false
        expect(json_response['error']).to eq('Validation failed')
        expect(json_response['details']['age']).to include('is required')
      end

      it 'returns validation error for invalid age range' do
        invalid_params = valid_params.merge(age: 12)
        
        post :create, params: invalid_params

        expect(response).to have_http_status(:bad_request)
        
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be false
        expect(json_response['details']['age']).to include('must be between 13 and 100')
      end

      it 'returns validation error for invalid gender' do
        invalid_params = valid_params.merge(gender: 'invalid')
        
        post :create, params: invalid_params

        expect(response).to have_http_status(:bad_request)
        
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be false
        expect(json_response['details']['gender']).to include('must be one of: male, female, other')
      end

      it 'returns validation error for empty equipment' do
        invalid_params = valid_params.merge(equipment: [])
        
        post :create, params: invalid_params

        expect(response).to have_http_status(:bad_request)
        
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be false
        expect(json_response['details']['equipment']).to include('must include at least one valid equipment type')
      end

      it 'returns validation error for invalid frequency' do
        invalid_params = valid_params.merge(frequency_per_week: 8)
        
        post :create, params: invalid_params

        expect(response).to have_http_status(:bad_request)
        
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be false
        expect(json_response['details']['frequency_per_week']).to include('must be between 1 and 7 days')
      end
    end

    context 'when AI service fails' do
      it 'handles service unavailable error' do
        mock_service = instance_double(AiWorkoutRoutineService)
        allow(AiWorkoutRoutineService).to receive(:new).and_return(mock_service)
        allow(mock_service).to receive(:generate_routine)
          .and_raise(AiWorkoutRoutineService::ServiceUnavailableError, 'AI service down')

        post :create, params: valid_params

        expect(response).to have_http_status(:service_unavailable)
        
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be false
        expect(json_response['error']).to eq('AI service temporarily unavailable')
      end

      it 'handles invalid response error' do
        mock_service = instance_double(AiWorkoutRoutineService)
        allow(AiWorkoutRoutineService).to receive(:new).and_return(mock_service)
        allow(mock_service).to receive(:generate_routine)
          .and_raise(AiWorkoutRoutineService::InvalidResponseError, 'Invalid JSON')

        post :create, params: valid_params

        expect(response).to have_http_status(:unprocessable_entity)
        
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be false
        expect(json_response['error']).to eq('AI service returned invalid response')
      end

      it 'handles invalid exercise ID error' do
        mock_service = instance_double(AiWorkoutRoutineService)
        allow(AiWorkoutRoutineService).to receive(:new).and_return(mock_service)
        allow(mock_service).to receive(:generate_routine)
          .and_raise(AiWorkoutRoutineService::InvalidExerciseIdError, 'Exercise ID 999 not found')

        post :create, params: valid_params

        expect(response).to have_http_status(:unprocessable_entity)
        
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be false
        expect(json_response['error']).to eq('Invalid exercise IDs in AI response')
      end

      it 'handles unexpected errors' do
        mock_service = instance_double(AiWorkoutRoutineService)
        allow(AiWorkoutRoutineService).to receive(:new).and_return(mock_service)
        allow(mock_service).to receive(:generate_routine)
          .and_raise(StandardError, 'Unexpected error')

        post :create, params: valid_params

        expect(response).to have_http_status(:internal_server_error)
        
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be false
        expect(json_response['error']).to eq('Internal server error')
      end
    end
  end

  describe 'parameter validation' do
    it 'validates weight range' do
      invalid_params = valid_params.merge(weight: 0)
      
      post :create, params: invalid_params

      expect(response).to have_http_status(:bad_request)
      
      json_response = JSON.parse(response.body)
      expect(json_response['details']['weight']).to include('must be between 1 and 300 kg')
    end

    it 'validates height range' do
      invalid_params = valid_params.merge(height: 50)
      
      post :create, params: invalid_params

      expect(response).to have_http_status(:bad_request)
      
      json_response = JSON.parse(response.body)
      expect(json_response['details']['height']).to include('must be between 100 and 250 cm')
    end

    it 'validates session time range' do
      invalid_params = valid_params.merge(time_per_session: 10)
      
      post :create, params: invalid_params

      expect(response).to have_http_status(:bad_request)
      
      json_response = JSON.parse(response.body)
      expect(json_response['details']['time_per_session']).to include('must be between 15 and 180 minutes')
    end

    it 'validates preferences length' do
      long_preferences = 'a' * 501
      invalid_params = valid_params.merge(preferences: long_preferences)
      
      post :create, params: invalid_params

      expect(response).to have_http_status(:bad_request)
      
      json_response = JSON.parse(response.body)
      expect(json_response['details']['preferences']).to include('must be less than 500 characters')
    end
  end
end 