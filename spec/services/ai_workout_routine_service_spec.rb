require 'rails_helper'

# AI functionality tests
RSpec.describe AiWorkoutRoutineService do
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
      "routines": [
        {
          "routine": {
            "name": "Upper Body Strength",
            "description": "Focus on chest, shoulders and triceps",
            "difficulty": "intermediate",
            "duration": 45,
            "routine_exercises_attributes": [
              {
                "exercise_id": 900,
                "sets": 4,
                "reps": 10,
                "rest_time": 60,
                "order": 1
              },
              {
                "exercise_id": 901,
                "sets": 3,
                "reps": 12,
                "rest_time": 45,
                "order": 2
              }
            ]
          }
        },
        {
          "routine": {
            "name": "Lower Body Power",
            "description": "Focus on legs and glutes",
            "difficulty": "intermediate",
            "duration": 45,
            "routine_exercises_attributes": [
              {
                "exercise_id": 902,
                "sets": 4,
                "reps": 8,
                "rest_time": 90,
                "order": 1
              },
              {
                "exercise_id": 903,
                "sets": 3,
                "reps": 10,
                "rest_time": 60,
                "order": 2
              }
            ]
          }
        }
      ]
    }.to_json
  end

  let(:service) { described_class.new(valid_params) }

  before do
    # Create test exercises using find_or_create_by to avoid duplicate key errors
    unless Exercise.exists?(900)
      Exercise.create!(id: 900, name: 'Bench Press', level: 'beginner', instructions: 'Test', primary_muscles: ['chest'], images: [])
    end
    unless Exercise.exists?(901)
      Exercise.create!(id: 901, name: 'Dumbbell Curl', level: 'intermediate', instructions: 'Test', primary_muscles: ['arms'], images: [])
    end
    unless Exercise.exists?(902)
      Exercise.create!(id: 902, name: 'Squat', level: 'beginner', instructions: 'Test', primary_muscles: ['legs'], images: [])
    end
    unless Exercise.exists?(903)
      Exercise.create!(id: 903, name: 'Push-up', level: 'beginner', instructions: 'Test', primary_muscles: ['chest'], images: [])
    end
  end

  describe '#create_routine' do
    context 'when AI service returns valid response' do
      it 'returns parsed routine' do
        # Mock the AI client
        mock_client = instance_double(AiApiClient)
        allow(AiApiClient).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:create_routine).and_return(mock_ai_response)

        result = service.create_routine

        expect(result).to have_key(:routines)
        expect(result[:routines]).to be_an(Array)
        expect(result[:routines].length).to eq(2)

        # Check first routine structure
        first_routine = result[:routines][0]
        expect(first_routine).to have_key(:routine)
        expect(first_routine[:routine][:name]).to eq('Upper Body Strength')
        expect(first_routine[:routine][:routine_exercises_attributes]).to be_an(Array)
        expect(first_routine[:routine][:routine_exercises_attributes].length).to eq(2)
      end
    end

    context 'when AI service returns invalid response format' do
      it 'raises InvalidResponseError for malformed JSON' do
        mock_client = instance_double(AiApiClient)
        allow(AiApiClient).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:create_routine).and_return('{ invalid json }')

        expect { service.create_routine }.to raise_error(
          AiWorkoutRoutineService::InvalidResponseError,
          /Invalid JSON in AI response/
        )
      end

      it 'raises InvalidResponseError for missing routines field' do
        mock_client = instance_double(AiApiClient)
        allow(AiApiClient).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:create_routine).and_return('{"invalid": "structure"}')

        expect { service.create_routine }.to raise_error(
          AiWorkoutRoutineService::InvalidResponseError,
          /AI response must contain 'json' or 'routines' field/
        )
      end
    end


    context 'when AI client raises errors' do
      it 'converts AiApiClient::TimeoutError to ServiceUnavailableError' do
        mock_client = instance_double(AiApiClient)
        allow(AiApiClient).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:create_routine)
          .and_raise(AiApiClient::TimeoutError, 'Timeout')

        expect { service.create_routine }.to raise_error(
          AiWorkoutRoutineService::ServiceUnavailableError,
          /AI service timeout/
        )
      end

      it 'converts AiApiClient::NetworkError to ServiceUnavailableError' do
        mock_client = instance_double(AiApiClient)
        allow(AiApiClient).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:create_routine)
          .and_raise(AiApiClient::NetworkError, 'Network error')

        expect { service.create_routine }.to raise_error(
          AiWorkoutRoutineService::ServiceUnavailableError,
          /AI service network error/
        )
      end
    end
  end

  describe '#create_routine_prompt' do
    it 'includes all user parameters in the prompt' do
      prompt = service.send(:create_routine_prompt)

      expect(prompt).to include('Age: 30')
      expect(prompt).to include('Gender: male')
      expect(prompt).to include('Weight: 80kg')
      expect(prompt).to include('Height: 175cm')
      expect(prompt).to include('Experience level: intermediate')
      expect(prompt).to include('Preferences: No cardio, solo tren superior')
      expect(prompt).to include('Training frequency: 3 sessions per week')
      expect(prompt).to include('Time per session: 45 minutes')
      expect(prompt).to include('Training goal: ganar masa muscular')
    end

    it 'includes basic prompt structure' do
      prompt = service.send(:create_routine_prompt)

      expect(prompt).to include('User fitness data:')
      expect(prompt).to include('Please generate a personalized workout routine')
    end
  end

  # describe '#build_exercise_catalog' do
  #   it 'includes exercises matching user equipment' do
  #     catalog = service.send(:build_exercise_catalog)

  #     expect(catalog).to include('Bench Press')
  #     expect(catalog).to include('Dumbbell Curl')
  #     expect(catalog).to include('barbell')
  #     expect(catalog).to include('dumbbell')
  #   end

  #   it 'includes bodyweight exercises as fallback' do
  #     catalog = service.send(:build_exercise_catalog)

  #     expect(catalog).to include('Push-up')
  #     expect(catalog).to include('body only')
  #   end

  #   it 'falls back to bodyweight exercises when no equipment matches' do
  #     params_with_no_equipment = valid_params.merge(equipment: ['nonexistent'])
  #     service_no_equipment = described_class.new(params_with_no_equipment)

  #     catalog = service_no_equipment.send(:build_exercise_catalog)

  #     expect(catalog).to include('Push-up')
  #     expect(catalog).to include('body only')
  #   end
  # end

  describe '#parse_ai_response' do
    it 'correctly extracts routines from JSON response' do
      result = service.send(:parse_ai_response, mock_ai_response)

      expect(result).to have_key(:routines)
      expect(result[:routines]).to be_an(Array)
      expect(result[:routines].length).to eq(2)
    end
  end

  describe '#validate_routine_structure' do
    it 'validates correct routine structure' do
      valid_routine = {
        routines: [
          {
            routine: {
              name: 'Test Routine',
              routine_exercises_attributes: [
                {
                  exercise_id: 900,
                  sets: 3,
                  reps: 10,
                  rest_time: 60,
                  order: 1
                }
              ]
            }
          }
        ]
      }

      expect { service.send(:validate_routine_structure, valid_routine) }.not_to raise_error
    end

    it 'raises error for missing routines array' do
      invalid_routine = { invalid: 'structure' }

      expect { service.send(:validate_routine_structure, invalid_routine) }.to raise_error(
        AiWorkoutRoutineService::InvalidResponseError,
        /AI response must contain 'routines' array/
      )
    end

    it 'raises error for invalid routine structure' do
      invalid_routine = {
        routines: [
          { invalid: 'routine' }
        ]
      }

      expect { service.send(:validate_routine_structure, invalid_routine) }.to raise_error(
        AiWorkoutRoutineService::InvalidResponseError,
        /Routine 1 has invalid structure/
      )
    end

    it 'raises error for missing routine exercises' do
      invalid_routine = {
        routines: [
          {
            routine: {
              name: 'Test'
              # Missing routine_exercises_attributes
            }
          }
        ]
      }

      expect { service.send(:validate_routine_structure, invalid_routine) }.to raise_error(
        AiWorkoutRoutineService::InvalidResponseError,
        /Routine 1 missing required fields/
      )
    end
  end


  # Tests for modify_routine functionality
  describe '#modify_routine' do
    let(:modify_service) { described_class.new({}, :modify) }
    let(:sample_routine) do
      {
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
      }
    end

    let(:modification_message) { 'Change the first exercise to a back exercise' }

    let(:mock_modify_ai_response) do
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
      }.to_json
    end

    context 'when AI service returns valid response' do
      it 'returns modified routine in consistent format' do
        mock_client = instance_double(AiApiClient)
        allow(AiApiClient).to receive(:new).with(:modify).and_return(mock_client)
        allow(mock_client).to receive(:create_routine).and_return(mock_modify_ai_response)

        result = modify_service.modify_routine(sample_routine, modification_message)

        expect(result).to have_key(:routines)
        expect(result[:routines]).to be_an(Array)
        expect(result[:routines].first).to have_key(:routine)
        expect(result[:routines].first[:routine][:name]).to eq('Upper Body Strength - Modified')
      end
    end

    context 'when AI service is unavailable' do
      it 'handles network errors' do
        mock_client = instance_double(AiApiClient)
        allow(AiApiClient).to receive(:new).with(:modify).and_return(mock_client)
        allow(mock_client).to receive(:create_routine)
          .and_raise(AiApiClient::NetworkError, 'Network error')

        expect { modify_service.modify_routine(sample_routine, modification_message) }.to raise_error(
          AiWorkoutRoutineService::ServiceUnavailableError,
          /AI service network error/
        )
      end
    end
  end

  describe '#modify_routine_prompt' do
    let(:modify_service) { described_class.new({}, :modify) }
    let(:sample_routine) do
      {
        name: 'Test Routine',
        routine_exercises_attributes: [
          { exercise_id: 900, sets: 3, needs_modification: true }
        ]
      }
    end
    let(:message) { 'Change to back exercise' }

    it 'constructs prompt with message and routine JSON' do
      prompt = modify_service.send(:modify_routine_prompt, sample_routine, message)

      expect(prompt).to include('Change to back exercise')
      expect(prompt).to include('"name": "Test Routine"')
      expect(prompt).to include('"exercise_id": 900')
      expect(prompt).to include('"needs_modification": true')
    end

    it 'uses pretty JSON format' do
      prompt = modify_service.send(:modify_routine_prompt, sample_routine, message)
      
      # Check for pretty formatting (indentation)
      expect(prompt).to include("{\n")
      expect(prompt).to include("  \"name\"")
    end
  end

  describe '#parse_modification_response' do
    let(:modify_service) { described_class.new({}, :modify) }

    context 'with direct routine format' do
      let(:direct_response) do
        {
          routine: {
            name: 'Modified Routine',
            routine_exercises_attributes: [
              { exercise_id: 900, sets: 3, reps: 10 }
            ]
          }
        }.to_json
      end

      it 'parses direct routine format correctly' do
        result = modify_service.send(:parse_modification_response, direct_response)
        
        expect(result).to have_key(:routine)
        expect(result[:routine][:name]).to eq('Modified Routine')
      end
    end

    context 'with nested json format' do
      let(:nested_response) do
        {
          json: {
            routine: {
              name: 'Modified Routine',
              routine_exercises_attributes: [
                { exercise_id: 900, sets: 3, reps: 10 }
              ]
            }
          }
        }.to_json
      end

      it 'parses nested json format correctly' do
        result = modify_service.send(:parse_modification_response, nested_response)
        
        expect(result).to have_key(:routine)
        expect(result[:routine][:name]).to eq('Modified Routine')
      end
    end

    context 'with invalid JSON' do
      it 'raises InvalidResponseError for malformed JSON' do
        expect { modify_service.send(:parse_modification_response, 'invalid json') }.to raise_error(
          AiWorkoutRoutineService::InvalidResponseError,
          /Invalid JSON in AI response/
        )
      end
    end

    context 'with missing routine field' do
      let(:missing_routine_response) do
        { invalid: 'structure' }.to_json
      end

      it 'raises InvalidResponseError for missing routine' do
        expect { modify_service.send(:parse_modification_response, missing_routine_response) }.to raise_error(
          AiWorkoutRoutineService::InvalidResponseError,
          /AI response must contain 'routine' field/
        )
      end
    end
  end
end
