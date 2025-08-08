require 'rails_helper'

# TODO: AI functionality is not 100% complete yet
# Skipping these tests until AI implementation is finished
RSpec.describe Api::V1::AiWorkoutRoutinesController, type: :controller do
  # Sample valid parameters
  let(:valid_params) do
    {
      age: 30,
      gender: 'male',
      weight: 80,
      height: 175,
      experience_level: 'intermediate',
      preferences: 'No cardio, solo tren superior',
      frequency_per_week: 3,
      time_per_session: 45,
      goal: 'ganar masa muscular'
    }
  end

  let(:mock_ai_response) do
    {
      routines: [
        {
          routine: {
            day: 1,
            name: 'Rutina de ganar masa muscular - Día 1',
            description: 'Rutina enfocada en ganar masa muscular para nivel intermediate',
            difficulty: 'intermediate',
            duration: 45,
            routine_exercises_attributes: [
              {
                exercise_id: 900,
                name: 'Flexiones',
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
  end

  let(:test_user) { create(:user) }

  before do
    # Create test exercises for validation using find_or_create_by to avoid duplicates
    Exercise.find_or_create_by(id: 900) { |e| e.assign_attributes(name: 'Push-up', level: 'beginner', instructions: 'Test', primary_muscles: ['chest'], images: []) }
    Exercise.find_or_create_by(id: 901) { |e| e.assign_attributes(name: 'Bench Press', level: 'intermediate', instructions: 'Test', primary_muscles: ['chest'], images: []) }
    Exercise.find_or_create_by(id: 125) { |e| e.assign_attributes(name: 'Pull-up', level: 'intermediate', instructions: 'Test', primary_muscles: ['back'], images: []) }
    
    # Mock JWT authentication
    authenticate_user test_user
  end

  describe 'POST #create' do
    context 'with valid parameters' do
      it 'returns success response with AI-generated routine' do
        # Set JWT token directly in request headers
        token = JWT.encode({ user_id: test_user.id }, Rails.application.secret_key_base)
        request.headers['Authorization'] = "Bearer #{token}"
        
        # Mock the AI service
        mock_service = instance_double(AiWorkoutRoutineService)
        allow(AiWorkoutRoutineService).to receive(:new).and_return(mock_service)
        allow(mock_service).to receive(:create_routine).and_return(mock_ai_response)

        post :create, params: valid_params

        expect(response).to have_http_status(:ok)

        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response['data']['routines']).to be_an(Array)
        expect(json_response['data']['routines'].length).to eq(1)
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
        allow(mock_service).to receive(:create_routine)
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
        allow(mock_service).to receive(:create_routine)
          .and_raise(AiWorkoutRoutineService::InvalidResponseError, 'Invalid JSON')

        post :create, params: valid_params

        expect(response).to have_http_status(:unprocessable_entity)

        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be false
        expect(json_response['error']).to eq('AI service returned invalid response')
      end


      it 'handles unexpected errors' do
        mock_service = instance_double(AiWorkoutRoutineService)
        allow(AiWorkoutRoutineService).to receive(:new).and_return(mock_service)
        allow(mock_service).to receive(:create_routine)
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

  # Tests for modify endpoint
  describe 'POST #modify' do
    let(:valid_modify_params) do
      {
        routine: {
          name: 'Upper Body Strength',
          description: 'Focus on chest, shoulders and triceps',
          difficulty: 'intermediate',
          duration: 45,
          routine_exercises_attributes: [
            {
              exercise_id: 900,
              sets: 4,
              reps: 10,
              rest_time: 60,
              order: 1,
              needs_modification: true
            },
            {
              exercise_id: 901,
              sets: 3,
              reps: 12,
              rest_time: 45,
              order: 2,
              needs_modification: false
            }
          ]
        },
        modification_message: 'Change the first exercise to a back exercise'
      }
    end

    let(:mock_modify_response) do
      {
        routines: [
          {
            routine: {
              name: 'Upper Body Strength - Modified',
              description: 'Modified routine with back exercise',
              difficulty: 'intermediate',
              duration: 45,
              routine_exercises_attributes: [
                {
                  exercise_id: 125,
                  sets: 4,
                  reps: 10,
                  rest_time: 60,
                  order: 1
                },
                {
                  exercise_id: 901,
                  sets: 3,
                  reps: 12,
                  rest_time: 45,
                  order: 2
                }
              ]
            }
          }
        ]
      }
    end

    context 'with valid parameters' do
      it 'returns modified routine successfully' do
        mock_service = instance_double(AiWorkoutRoutineService)
        allow(AiWorkoutRoutineService).to receive(:new).with({}, :modify).and_return(mock_service)
        allow(mock_service).to receive(:modify_routine).and_return(mock_modify_response)

        post :modify, params: valid_modify_params

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        
        expect(json_response['success']).to be true
        expect(json_response['data']['routines']).to be_present
        expect(json_response['data']['generated_at']).to be_present
      end
    end

    context 'with missing routine parameter' do
      it 'returns validation error' do
        params = valid_modify_params.except(:routine)
        
        post :modify, params: params

        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        
        expect(json_response['success']).to be false
        expect(json_response['error']).to eq('Validation failed')
        expect(json_response['details']['routine']).to include('is required')
      end
    end

    context 'with missing modification_message parameter' do
      it 'returns validation error' do
        params = valid_modify_params.except(:modification_message)
        
        post :modify, params: params

        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        
        expect(json_response['success']).to be false
        expect(json_response['error']).to eq('Validation failed')
        expect(json_response['details']['modification_message']).to include('is required')
      end
    end

    context 'with no exercises marked for modification' do
      it 'returns validation error' do
        params = valid_modify_params.deep_dup
        params[:routine][:routine_exercises_attributes].each do |exercise|
          exercise[:needs_modification] = false
        end
        
        post :modify, params: params

        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        
        expect(json_response['success']).to be false
        expect(json_response['details']['routine']).to include('must have at least one exercise marked for modification')
      end
    end

    context 'when AI service returns invalid response' do
      it 'handles InvalidResponseError' do
        mock_service = instance_double(AiWorkoutRoutineService)
        allow(AiWorkoutRoutineService).to receive(:new).and_return(mock_service)
        allow(mock_service).to receive(:modify_routine)
          .and_raise(AiWorkoutRoutineService::InvalidResponseError, 'Invalid response')

        post :modify, params: valid_modify_params

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        
        expect(json_response['success']).to be false
        expect(json_response['error']).to eq('AI service returned invalid response')
      end
    end

    context 'when AI service is unavailable' do
      it 'handles ServiceUnavailableError' do
        mock_service = instance_double(AiWorkoutRoutineService)
        allow(AiWorkoutRoutineService).to receive(:new).and_return(mock_service)
        allow(mock_service).to receive(:modify_routine)
          .and_raise(AiWorkoutRoutineService::ServiceUnavailableError, 'Service unavailable')

        post :modify, params: valid_modify_params

        expect(response).to have_http_status(:service_unavailable)
        json_response = JSON.parse(response.body)
        
        expect(json_response['success']).to be false
        expect(json_response['error']).to eq('AI service temporarily unavailable')
      end
    end
  end
end
