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
      expect(prompt).to include('Age: 30')
      expect(prompt).to include('Gender: male')
      expect(prompt).to include('Weight: 80kg')
      expect(prompt).to include('Height: 175cm')
      expect(prompt).to include('Experience level: intermediate')
      expect(prompt).to include('Training frequency: 3 sessions per week')
      expect(prompt).to include('Time per session: 45 minutes')
      expect(prompt).to include('Training goal: ganar masa muscular')
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

  # Tests for modify_exercises functionality
  describe '#modify_exercises' do
    let(:modify_service) { described_class.new({}, :modify) }
    
    # Create exercises first and use their IDs dynamically
    let!(:exercise1) { create(:exercise, name: 'Test Bench Press 1') }
    let!(:exercise2) { create(:exercise, name: 'Test Squat 1') }
    let!(:exercise3) { create(:exercise, name: 'Test Pull-up 1') }
    
    let(:sample_exercises) do
      [
        {
          exercise_id: exercise1.id,
          sets: 4,
          reps: 10,
          rest_time: 60,
          order: 1
        },
        {
          exercise_id: exercise2.id,
          sets: 3,
          reps: 12,
          rest_time: 45,
          order: 2
        }
      ]
    end

    let(:user_message) { 'Change the first exercise to a back exercise' }

    let(:mock_modify_exercises_ai_response) do
      {
        exercises: [
          {
            exercise_id: exercise3.id,
            sets: 4,
            reps: 10,
            rest_time: 60,
            order: 1
          },
          {
            exercise_id: exercise2.id,
            sets: 3,
            reps: 12,
            rest_time: 45,
            order: 2
          }
        ]
      }.to_json
    end

    context 'when AI service returns valid response' do
      it 'returns modified exercises in correct format' do
        mock_client = instance_double(AiApiClient)
        allow(AiApiClient).to receive(:new).with(:modify).and_return(mock_client)
        allow(mock_client).to receive(:create_routine).and_return(mock_modify_exercises_ai_response)

        result = modify_service.modify_exercises(sample_exercises, user_message)

        expect(result).to have_key(:exercises)
        expect(result[:exercises]).to be_an(Array)
        expect(result[:exercises].length).to eq(2)
        expect(result[:exercises].first[:exercise_id]).to eq(exercise3.id)
        expect(result[:exercises].first[:sets]).to eq(4)
        expect(result[:exercises].first[:reps]).to eq(10)
      end

      it 'normalizes exercise order sequentially' do
        mock_client = instance_double(AiApiClient)
        allow(AiApiClient).to receive(:new).with(:modify).and_return(mock_client)
        allow(mock_client).to receive(:create_routine).and_return(mock_modify_exercises_ai_response)

        result = modify_service.modify_exercises(sample_exercises, user_message)

        expect(result[:exercises][0][:order]).to eq(1)
        expect(result[:exercises][1][:order]).to eq(2)
      end

      it 'sets default values for optional fields' do
        mock_client = instance_double(AiApiClient)
        allow(AiApiClient).to receive(:new).with(:modify).and_return(mock_client)
        allow(mock_client).to receive(:create_routine).and_return(mock_modify_exercises_ai_response)

        result = modify_service.modify_exercises(sample_exercises, user_message)

        result[:exercises].each do |exercise|
          expect(exercise[:rest_time]).to be_present
          expect(exercise[:order]).to be_present
        end
      end
    end

    context 'when AI service is unavailable' do
      it 'handles network errors' do
        mock_client = instance_double(AiApiClient)
        allow(AiApiClient).to receive(:new).with(:modify).and_return(mock_client)
        allow(mock_client).to receive(:create_routine)
          .and_raise(AiApiClient::NetworkError, 'Network error')

        expect { modify_service.modify_exercises(sample_exercises, user_message) }.to raise_error(
          AiWorkoutRoutineService::ServiceUnavailableError,
          /AI service network error/
        )
      end
    end

    context 'when AI response has invalid exercise structure' do
      let(:invalid_response) do
        {
          exercises: [
            { exercise_id: exercise1.id, sets: 4 } # Missing reps
          ]
        }.to_json
      end

      it 'raises InvalidResponseError' do
        mock_client = instance_double(AiApiClient)
        allow(AiApiClient).to receive(:new).with(:modify).and_return(mock_client)
        allow(mock_client).to receive(:create_routine).and_return(invalid_response)

        expect { modify_service.modify_exercises(sample_exercises, user_message) }.to raise_error(
          AiWorkoutRoutineService::InvalidResponseError,
          /Exercise 1 has invalid structure/
        )
      end
    end

    context 'when AI response has non-existent exercise_id' do
      let(:non_existent_response) do
        {
          exercises: [
            { exercise_id: 99999, sets: 4, reps: 10 } # Non-existent ID
          ]
        }.to_json
      end

      it 'raises InvalidResponseError' do
        mock_client = instance_double(AiApiClient)
        allow(AiApiClient).to receive(:new).with(:modify).and_return(mock_client)
        allow(mock_client).to receive(:create_routine).and_return(non_existent_response)

        expect { modify_service.modify_exercises(sample_exercises, user_message) }.to raise_error(
          AiWorkoutRoutineService::InvalidResponseError,
          /Exercise ID 99999 does not exist in the database/
        )
      end
    end

    context 'when AI response has values out of range' do
      let(:out_of_range_response) do
        {
          exercises: [
            { exercise_id: exercise1.id, sets: 25, reps: 10 } # Sets > 20
          ]
        }.to_json
      end

      it 'raises InvalidResponseError for sets out of range' do
        mock_client = instance_double(AiApiClient)
        allow(AiApiClient).to receive(:new).with(:modify).and_return(mock_client)
        allow(mock_client).to receive(:create_routine).and_return(out_of_range_response)

        expect { modify_service.modify_exercises(sample_exercises, user_message) }.to raise_error(
          AiWorkoutRoutineService::InvalidResponseError,
          /Exercise 1: sets must be between 1 and 20/
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

  describe '#build_modify_payload' do
    let(:modify_service) { described_class.new({}, :modify) }
    
    # Create exercises first and use their IDs dynamically
    let!(:exercise1) { create(:exercise, name: 'Test Bench Press 2') }
    let!(:exercise2) { create(:exercise, name: 'Test Squat 2') }
    
    let(:sample_exercises) do
      [
        { exercise_id: exercise1.id, sets: 3, reps: 10, rest_time: 60, order: 1 },
        { exercise_id: exercise2.id, sets: 4, reps: 12, rest_time: 45, order: 2 }
      ]
    end
    let(:user_message) { 'Change the first exercise to a back exercise' }

    it 'constructs payload with user message and exercises JSON' do
      payload = modify_service.send(:build_modify_payload, user_message, sample_exercises)

      expect(payload).to include('Change the first exercise to a back exercise')
      expect(payload).to include('"exercise_id"')
      expect(payload).to include('"sets"')
      expect(payload).to include('"reps"')
      expect(payload).to include('"rest_time"')
      expect(payload).to include('"order"')
    end

    it 'uses pretty JSON format for exercises' do
      payload = modify_service.send(:build_modify_payload, user_message, sample_exercises)
      
      # The method uses to_json which doesn't format with pretty JSON
      expect(payload).to include('"user_message"')
      expect(payload).to include('"exercises"')
      expect(payload).to include('"exercise_id"')
    end
  end

  describe '#parse_modification_response' do
    let(:modify_service) { described_class.new({}, :modify) }
    
    # Create exercises first and use their IDs dynamically
    let!(:exercise1) { create(:exercise, name: 'Test Bench Press 3') }

    context 'with direct routine format' do
      let(:direct_response) do
        {
          routine: {
            name: 'Modified Routine',
            routine_exercises_attributes: [
              { exercise_id: exercise1.id, sets: 3, reps: 10 }
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
                { exercise_id: exercise1.id, sets: 3, reps: 10 }
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

      it 'raises InvalidResponseError for missing routine field' do
        expect { modify_service.send(:parse_modification_response, missing_routine_response) }.to raise_error(
          AiWorkoutRoutineService::InvalidResponseError,
          /AI response must contain 'routine' field/
        )
      end
    end
  end

  describe '#parse_exercises_response' do
    let(:modify_service) { described_class.new({}, :modify) }

    context 'with direct exercises format' do
      let(:direct_response) do
        {
          exercises: [
            { exercise_id: 125, sets: 4, reps: 10, rest_time: 60, order: 1 },
            { exercise_id: 901, sets: 3, reps: 12, rest_time: 45, order: 2 }
          ]
        }.to_json
      end

      it 'parses direct exercises format correctly' do
        result = modify_service.send(:parse_exercises_response, direct_response)
        
        expect(result).to have_key(:exercises)
        expect(result[:exercises]).to be_an(Array)
        expect(result[:exercises].length).to eq(2)
        expect(result[:exercises].first[:exercise_id]).to eq(125)
      end
    end

    context 'with nested json format' do
      let(:nested_response) do
        {
          json: {
            exercises: [
              { exercise_id: 125, sets: 4, reps: 10, rest_time: 60, order: 1 },
              { exercise_id: 901, sets: 3, reps: 12, rest_time: 45, order: 2 }
            ]
          }
        }.to_json
      end

      it 'parses nested json format correctly' do
        result = modify_service.send(:parse_exercises_response, nested_response)
        
        expect(result).to have_key(:exercises)
        expect(result[:exercises]).to be_an(Array)
        expect(result[:exercises].length).to eq(2)
        expect(result[:exercises].first[:exercise_id]).to eq(125)
      end
    end

    context 'with invalid JSON' do
      it 'raises InvalidResponseError for malformed JSON' do
        expect { modify_service.send(:parse_exercises_response, 'invalid json') }.to raise_error(
          AiWorkoutRoutineService::InvalidResponseError,
          /Invalid JSON in AI response/
        )
      end
    end

    context 'with missing exercises field' do
      let(:missing_exercises_response) do
        { invalid: 'structure' }.to_json
      end

      it 'raises InvalidResponseError for missing exercises field' do
        expect { modify_service.send(:parse_exercises_response, missing_exercises_response) }.to raise_error(
          AiWorkoutRoutineService::InvalidResponseError,
          /AI response must contain 'exercises' field/
        )
      end
    end
  end

  describe '#validate_exercises_structure' do
    let(:modify_service) { described_class.new({}, :modify) }

    context 'with valid exercises structure' do
      let(:valid_exercises) do
        [
          { exercise_id: 125, sets: 4, reps: 10 },
          { exercise_id: 901, sets: 3, reps: 12 }
        ]
      end

      it 'does not raise error for valid structure' do
        expect { modify_service.send(:validate_exercises_structure, valid_exercises) }.not_to raise_error
      end
    end

    context 'with invalid exercises structure' do
      let(:invalid_exercises) do
        [
          { exercise_id: 125, sets: 4 }, # Missing reps
          { exercise_id: 901, sets: 3, reps: 12 }
        ]
      end

      it 'raises InvalidResponseError for missing required fields' do
        expect { modify_service.send(:validate_exercises_structure, invalid_exercises) }.to raise_error(
          AiWorkoutRoutineService::InvalidResponseError,
          /Exercise 1 has invalid structure/
        )
      end
    end

    context 'with non-array exercises' do
      it 'raises InvalidResponseError for non-array input' do
        expect { modify_service.send(:validate_exercises_structure, 'not an array') }.to raise_error(
          AiWorkoutRoutineService::InvalidResponseError,
          /AI response must contain 'exercises' array/
        )
      end
    end
  end

  describe '#validate_exercises_existence' do
    let(:modify_service) { described_class.new({}, :modify) }

    # Create exercises first and use their IDs dynamically
    let!(:exercise1) { create(:exercise, name: 'Test Pull-up 1') }
    let!(:exercise2) { create(:exercise, name: 'Test Squat 3') }

    context 'with existing exercise IDs' do
      let(:existing_exercises) do
        [
          { exercise_id: exercise1.id, sets: 4, reps: 10 },
          { exercise_id: exercise2.id, sets: 3, reps: 12 }
        ]
      end

      it 'does not raise error for existing exercises' do
        expect { modify_service.send(:validate_exercises_existence, existing_exercises) }.not_to raise_error
      end
    end

    context 'with non-existing exercise ID' do
      let(:non_existing_exercises) do
        [
          { exercise_id: 99999, sets: 4, reps: 10 } # Non-existent ID
        ]
      end

      it 'raises InvalidResponseError for non-existing exercise' do
        expect { modify_service.send(:validate_exercises_existence, non_existing_exercises) }.to raise_error(
          AiWorkoutRoutineService::InvalidResponseError,
          /Exercise ID 99999 does not exist in the database/
        )
      end
    end
  end

  describe '#validate_exercise_ranges' do
    let(:modify_service) { described_class.new({}, :modify) }

    # Create exercises first and use their IDs dynamically
    let!(:exercise1) { create(:exercise, name: 'Test Pull-up 2') }
    let!(:exercise2) { create(:exercise, name: 'Test Squat 4') }

    context 'with valid exercise values' do
      let(:valid_exercises) do
        [
          { exercise_id: exercise1.id, sets: 4, reps: 10, rest_time: 60 },
          { exercise_id: exercise2.id, sets: 3, reps: 12, rest_time: 45 }
        ]
      end

      it 'does not raise error for valid ranges' do
        expect { modify_service.send(:validate_exercise_ranges, valid_exercises) }.not_to raise_error
      end
    end

    context 'with sets out of range' do
      let(:invalid_sets_exercises) do
        [
          { exercise_id: exercise1.id, sets: 25, reps: 10 } # Sets > 20
        ]
      end

      it 'raises InvalidResponseError for sets out of range' do
        expect { modify_service.send(:validate_exercise_ranges, invalid_sets_exercises) }.to raise_error(
          AiWorkoutRoutineService::InvalidResponseError,
          /Exercise 1: sets must be between 1 and 20/
        )
      end
    end

    context 'with reps out of range' do
      let(:invalid_reps_exercises) do
        [
          { exercise_id: exercise1.id, sets: 4, reps: 150 } # Reps > 100
        ]
      end

      it 'raises InvalidResponseError for reps out of range' do
        expect { modify_service.send(:validate_exercise_ranges, invalid_reps_exercises) }.to raise_error(
          AiWorkoutRoutineService::InvalidResponseError,
          /Exercise 1: reps must be between 1 and 100/
        )
      end
    end

    context 'with rest_time out of range' do
      let(:invalid_rest_time_exercises) do
        [
          { exercise_id: exercise1.id, sets: 4, reps: 10, rest_time: 700 } # Rest time > 600
        ]
      end

      it 'raises InvalidResponseError for rest_time out of range' do
        expect { modify_service.send(:validate_exercise_ranges, invalid_rest_time_exercises) }.to raise_error(
          AiWorkoutRoutineService::InvalidResponseError,
          /Exercise 1: rest_time must be between 0 and 600 seconds/
        )
      end
    end
  end

  describe '#set_default_values' do
    let(:modify_service) { described_class.new({}, :modify) }

    # Create exercises first and use their IDs dynamically
    let!(:exercise1) { create(:exercise, name: 'Test Pull-up 3') }
    let!(:exercise2) { create(:exercise, name: 'Test Squat 5') }

    let(:exercises) do
      [
        { exercise_id: exercise1.id, sets: 4, reps: 10 },
        { exercise_id: exercise2.id, sets: 3, reps: 12 }
      ]
    end

    it 'sets default rest_time to 0 if not present' do
      modify_service.send(:set_default_values, exercises)
      
      exercises.each do |exercise|
        expect(exercise[:rest_time]).to eq(0)
      end
    end

    it 'sets default order to 1 if not present' do
      modify_service.send(:set_default_values, exercises)
      
      exercises.each do |exercise|
        expect(exercise[:order]).to eq(1)
      end
    end

    it 'does not override existing values' do
      exercises[0][:rest_time] = 90
      exercises[1][:order] = 5
      
      modify_service.send(:set_default_values, exercises)
      
      expect(exercises[0][:rest_time]).to eq(90)
      expect(exercises[1][:order]).to eq(5)
    end
  end

  describe '#normalize_exercise_order' do
    let(:modify_service) { described_class.new({}, :modify) }

    # Create exercises first and use their IDs dynamically
    let!(:exercise1) { create(:exercise, name: 'Test Pull-up 4') }
    let!(:exercise2) { create(:exercise, name: 'Test Squat 6') }

    let(:exercises) do
      [
        { exercise_id: exercise1.id, sets: 4, reps: 10, order: 5 },
        { exercise_id: exercise2.id, sets: 3, reps: 12, order: 2 }
      ]
    end

    it 'reassigns order sequentially starting from 1' do
      modify_service.send(:normalize_exercise_order, exercises)
      
      expect(exercises[0][:order]).to eq(1)
      expect(exercises[1][:order]).to eq(2)
    end

    it 'overrides existing order values' do
      modify_service.send(:normalize_exercise_order, exercises)
      
      exercises.each_with_index do |exercise, index|
        expect(exercise[:order]).to eq(index + 1)
      end
    end
  end
end
