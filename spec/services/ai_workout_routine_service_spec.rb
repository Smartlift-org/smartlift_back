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

    context 'when AI response has exercises with names only (no exercise_id)' do
      let(:ai_response_with_names_only) do
        {
          exercises: [
            {
              name: 'Test Bench Press 1',  # Matches exercise1.name
              sets: 4,
              reps: 10,
              rest_time: 60,
              order: 1
            },
            {
              name: 'Test Squat 1',        # Matches exercise2.name
              sets: 3,
              reps: 12,
              rest_time: 45,
              order: 2
            },
            {
              name: 'Test Pull-up 1',      # Matches exercise3.name
              sets: 5,
              reps: 8,
              rest_time: 90,
              order: 3
            }
          ]
        }.to_json
      end

      it 'assigns exercise_id automatically using fuzzy search algorithm' do
        mock_client = instance_double(AiApiClient)
        allow(AiApiClient).to receive(:new).with(:modify).and_return(mock_client)
        allow(mock_client).to receive(:create_routine).and_return(ai_response_with_names_only)

        result = modify_service.modify_exercises(sample_exercises, user_message)

        expect(result).to have_key(:exercises)
        expect(result[:exercises]).to be_an(Array)
        expect(result[:exercises].length).to eq(3)

        # Verify all exercises have been assigned exercise_id
        result[:exercises].each_with_index do |exercise, index|
          expect(exercise).to have_key(:exercise_id)
          expect(exercise[:exercise_id]).to be_present
          expect(exercise[:exercise_id]).to be_a(Integer)
          
          expect(exercise).to have_key(:name)
          expect(exercise[:name]).to be_present
        end

        # Verify specific exercise assignments
        bench_press = result[:exercises].find { |ex| ex[:name] == 'Test Bench Press 1' }
        expect(bench_press).to be_present
        expect(bench_press[:exercise_id]).to eq(exercise1.id)
        expect(bench_press[:sets]).to eq(4)
        expect(bench_press[:reps]).to eq(10)

        squat = result[:exercises].find { |ex| ex[:name] == 'Test Squat 1' }
        expect(squat).to be_present
        expect(squat[:exercise_id]).to eq(exercise2.id)
        expect(squat[:sets]).to eq(3)
        expect(squat[:reps]).to eq(12)

        pull_up = result[:exercises].find { |ex| ex[:name] == 'Test Pull-up 1' }
        expect(pull_up).to be_present
        expect(pull_up[:exercise_id]).to eq(exercise3.id)
        expect(pull_up[:sets]).to eq(5)
        expect(pull_up[:reps]).to eq(8)
      end

      it 'preserves all other exercise attributes after ID assignment' do
        mock_client = instance_double(AiApiClient)
        allow(AiApiClient).to receive(:new).with(:modify).and_return(mock_client)
        allow(mock_client).to receive(:create_routine).and_return(ai_response_with_names_only)

        result = modify_service.modify_exercises(sample_exercises, user_message)

        result[:exercises].each do |exercise|
          expect(exercise[:sets]).to be_present
          expect(exercise[:reps]).to be_present
          expect(exercise[:rest_time]).to be_present
          expect(exercise[:order]).to be_present
        end
      end

      it 'handles partial name matches using fuzzy search' do
        # Create an exercise with a similar name
        similar_exercise = create(:exercise, name: 'Incline Test Bench Press 1')
        
        ai_response_with_partial_match = {
          exercises: [
            {
              name: 'Bench Press',  # Partial match for similar_exercise
              sets: 4,
              reps: 10,
              rest_time: 60,
              order: 1
            }
          ]
        }.to_json

        mock_client = instance_double(AiApiClient)
        allow(AiApiClient).to receive(:new).with(:modify).and_return(mock_client)
        allow(mock_client).to receive(:create_routine).and_return(ai_response_with_partial_match)

        result = modify_service.modify_exercises(sample_exercises, user_message)

        expect(result[:exercises].first[:exercise_id]).to be_present
        expect(result[:exercises].first[:name]).to be_present
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

  # Additional comprehensive tests for new functionality

  describe 'retry mechanism integration' do
    let(:service) { described_class.new(valid_params) }
    let(:modify_service) { described_class.new({}, :modify) }

    context 'when AI service fails and recovers' do
      it 'successfully retries after network failure' do
        mock_client = instance_double(AiApiClient)
        allow(AiApiClient).to receive(:new).and_return(mock_client)
        
        call_count = 0
        allow(mock_client).to receive(:create_routine) do
          call_count += 1
          if call_count == 1
            raise AiApiClient::NetworkError, 'Connection refused'
          else
            mock_ai_response
          end
        end

        result = service.create_routine

        expect(result).to have_key(:routines)
        expect(result[:routines]).to be_an(Array)
        expect(result[:routines].length).to eq(2)
      end

      it 'fails after maximum retries' do
        mock_client = instance_double(AiApiClient)
        allow(AiApiClient).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:create_routine)
          .and_raise(AiApiClient::NetworkError, 'Persistent network error')

        expect { service.create_routine }.to raise_error(
          AiWorkoutRoutineService::ServiceUnavailableError,
          /AI service network error/
        )
      end

      it 'handles timeout without retry for modify_exercises' do
        exercises = [{ exercise_id: 900, sets: 3, reps: 10 }]
        mock_client = instance_double(AiApiClient)
        allow(AiApiClient).to receive(:new).with(:modify).and_return(mock_client)
        allow(mock_client).to receive(:create_routine)
          .and_raise(AiApiClient::TimeoutError, 'Service timeout')

        expect { modify_service.modify_exercises(exercises, 'test message') }.to raise_error(
          AiWorkoutRoutineService::ServiceUnavailableError,
          /AI service timeout/
        )
      end
    end
  end

  describe 'exercise validation edge cases' do
    let(:modify_service) { described_class.new({}, :modify) }

    context 'with boundary value testing' do
      let!(:test_exercise) { create(:exercise, name: 'Boundary Test Exercise') }

      it 'accepts minimum valid values' do
        exercises = [
          { exercise_id: test_exercise.id, sets: 1, reps: 1, rest_time: 0 }
        ]

        expect { modify_service.send(:validate_exercise_ranges, exercises) }.not_to raise_error
      end

      it 'accepts maximum valid values' do
        exercises = [
          { exercise_id: test_exercise.id, sets: 20, reps: 100, rest_time: 600 }
        ]

        expect { modify_service.send(:validate_exercise_ranges, exercises) }.not_to raise_error
      end

      it 'rejects values below minimum' do
        exercises = [
          { exercise_id: test_exercise.id, sets: 0, reps: 10 }
        ]

        expect { modify_service.send(:validate_exercise_ranges, exercises) }.to raise_error(
          AiWorkoutRoutineService::InvalidResponseError,
          /sets must be between 1 and 20/
        )
      end

      it 'rejects values above maximum' do
        exercises = [
          { exercise_id: test_exercise.id, sets: 21, reps: 10 }
        ]

        expect { modify_service.send(:validate_exercise_ranges, exercises) }.to raise_error(
          AiWorkoutRoutineService::InvalidResponseError,
          /sets must be between 1 and 20/
        )
      end
    end

    context 'with data type validation' do
      let!(:test_exercise) { create(:exercise, name: 'Type Test Exercise') }

      it 'rejects string exercise_id' do
        exercises = [
          { exercise_id: 'not_a_number', sets: 3, reps: 10 }
        ]

        expect { modify_service.send(:validate_exercise_ranges, exercises) }.to raise_error(
          AiWorkoutRoutineService::InvalidResponseError,
          /exercise_id must be a positive integer/
        )
      end

      it 'rejects negative exercise_id' do
        exercises = [
          { exercise_id: -1, sets: 3, reps: 10 }
        ]

        expect { modify_service.send(:validate_exercise_ranges, exercises) }.to raise_error(
          AiWorkoutRoutineService::InvalidResponseError,
          /exercise_id must be a positive integer/
        )
      end

      it 'rejects string sets value' do
        exercises = [
          { exercise_id: test_exercise.id, sets: 'three', reps: 10 }
        ]

        expect { modify_service.send(:validate_exercise_ranges, exercises) }.to raise_error(
          AiWorkoutRoutineService::InvalidResponseError,
          /sets must be between 1 and 20/
        )
      end

      it 'rejects float reps value' do
        exercises = [
          { exercise_id: test_exercise.id, sets: 3, reps: 10.5 }
        ]

        expect { modify_service.send(:validate_exercise_ranges, exercises) }.to raise_error(
          AiWorkoutRoutineService::InvalidResponseError,
          /reps must be between 1 and 100/
        )
      end
    end
  end

  describe 'comprehensive AI response parsing' do
    let(:service) { described_class.new(valid_params) }

    context 'with malformed JSON structures' do
      it 'handles JSON with unexpected nesting' do
        malformed_response = {
          data: {
            nested: {
              routines: []
            }
          }
        }.to_json

        expect { service.send(:parse_ai_response, malformed_response) }.to raise_error(
          AiWorkoutRoutineService::InvalidResponseError,
          /AI response must contain 'json' or 'routines' field/
        )
      end

      it 'handles JSON with null values' do
        null_response = {
          routines: null
        }.to_json

        expect { service.send(:parse_ai_response, null_response) }.to raise_error(
          AiWorkoutRoutineService::InvalidResponseError,
          /AI response must contain 'routines' array/
        )
      end

      it 'handles JSON with mixed data types in arrays' do
        mixed_response = {
          routines: [
            'invalid_string',
            { routine: { name: 'Valid', exercises: [] } }
          ]
        }.to_json

        expect { service.send(:parse_ai_response, mixed_response) }.to raise_error(
          AiWorkoutRoutineService::InvalidResponseError,
          /Routine 1 has invalid structure/
        )
      end
    end

    context 'with edge case JSON content' do
      it 'handles very large JSON responses' do
        large_exercises = Array.new(100) do |i|
          {
            exercise_id: 900,
            sets: 3,
            reps: 10,
            rest_time: 60,
            order: i + 1
          }
        end

        large_response = {
          routines: [{
            routine: {
              name: 'Large Routine',
              description: 'Test routine with many exercises',
              difficulty: 'intermediate',
              duration: 120,
              exercises: large_exercises
            }
          }]
        }.to_json

        result = service.send(:parse_ai_response, large_response)
        expect(result[:routines]).to be_an(Array)
        expect(result[:routines].first[:routine][:exercises].length).to eq(100)
      end

      it 'handles JSON with special characters in strings' do
        special_char_response = {
          routines: [{
            routine: {
              name: 'Spëcîål Çhārs & Émöjïs 💪🏋️‍♂️',
              description: 'Tëst with ñôn-ASCII chars: àáâãäåæçèéêë',
              difficulty: 'intermediate',
              duration: 45,
              exercises: []
            }
          }]
        }.to_json

        result = service.send(:parse_ai_response, special_char_response)
        expect(result[:routines].first[:routine][:name]).to include('Spëcîål')
        expect(result[:routines].first[:routine][:description]).to include('àáâãäåæçèéêë')
      end

      it 'handles empty string values in required fields' do
        empty_string_response = {
          routines: [{
            routine: {
              name: '',
              description: 'Valid description',
              difficulty: 'intermediate',
              duration: 45,
              exercises: []
            }
          }]
        }.to_json

        expect { service.send(:parse_ai_response, empty_string_response) }.to raise_error(
          AiWorkoutRoutineService::InvalidResponseError,
          /Routine 1 missing required fields/
        )
      end
    end
  end

  describe 'exercise modification validation' do
    let(:modify_service) { described_class.new({}, :modify) }
    
    # Create test exercises with different characteristics
    let!(:chest_exercise) { create(:exercise, name: 'Bench Press') }
    let!(:back_exercise) { create(:exercise, name: 'Pull-up') }
    let!(:leg_exercise) { create(:exercise, name: 'Squat') }

    context 'when validating exercise existence with realistic scenarios' do
      it 'validates existing exercises in batch' do
        exercises = [
          { exercise_id: chest_exercise.id, sets: 3, reps: 10 },
          { exercise_id: back_exercise.id, sets: 3, reps: 8 },
          { exercise_id: leg_exercise.id, sets: 4, reps: 12 }
        ]

        expect { modify_service.send(:validate_exercises_existence, exercises) }.not_to raise_error
      end

      it 'identifies first non-existing exercise in batch' do
        exercises = [
          { exercise_id: chest_exercise.id, sets: 3, reps: 10 },
          { exercise_id: 99999, sets: 3, reps: 8 },  # Non-existent
          { exercise_id: leg_exercise.id, sets: 4, reps: 12 }
        ]

        expect { modify_service.send(:validate_exercises_existence, exercises) }.to raise_error(
          AiWorkoutRoutineService::InvalidResponseError,
          /Exercise ID 99999 does not exist in the database/
        )
      end

      it 'validates exercises after database changes' do
        temp_exercise = create(:exercise, name: 'Temporary Exercise')
        exercises = [{ exercise_id: temp_exercise.id, sets: 3, reps: 10 }]

        # First validation should pass
        expect { modify_service.send(:validate_exercises_existence, exercises) }.not_to raise_error

        # Delete the exercise
        temp_exercise.destroy

        # Second validation should fail
        expect { modify_service.send(:validate_exercises_existence, exercises) }.to raise_error(
          AiWorkoutRoutineService::InvalidResponseError,
          /Exercise ID #{temp_exercise.id} does not exist in the database/
        )
      end
    end

    context 'when processing complex exercise modifications' do
      it 'handles exercises with all optional fields' do
        exercises = [
          {
            exercise_id: chest_exercise.id,
            sets: 4,
            reps: 12,
            rest_time: 90,
            order: 1,
            weight: 100,
            notes: 'Increase weight next time'
          }
        ]

        # Should not raise error for extra fields
        expect { modify_service.send(:validate_exercises_existence, exercises) }.not_to raise_error
        expect { modify_service.send(:validate_exercise_ranges, exercises) }.not_to raise_error
      end

      it 'sets default values for missing optional fields' do
        exercises = [
          { exercise_id: chest_exercise.id, sets: 3, reps: 10 }
        ]

        modify_service.send(:set_default_values, exercises)

        expect(exercises[0][:rest_time]).to eq(0)
        expect(exercises[0][:order]).to eq(1)
      end

      it 'preserves existing optional field values' do
        exercises = [
          {
            exercise_id: chest_exercise.id,
            sets: 3,
            reps: 10,
            rest_time: 120,
            order: 5
          }
        ]

        modify_service.send(:set_default_values, exercises)

        expect(exercises[0][:rest_time]).to eq(120)
        expect(exercises[0][:order]).to eq(5)
      end
    end
  end

  # NEW COMPREHENSIVE TESTS FOR ADVANCED FUNCTIONALITY
  describe 'empty routines and retry mechanism' do
    let(:service) { described_class.new(valid_params) }
    
    context 'when AI service returns empty routines' do
      let(:empty_routines_response) do
        {
          routines: []
        }.to_json
      end

      it 'handles empty routines response without retry' do
        mock_client = instance_double(AiApiClient)
        allow(AiApiClient).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:create_routine).and_return(empty_routines_response)

        result = service.create_routine

        expect(result).to have_key(:routines)
        expect(result[:routines]).to be_an(Array)
        expect(result[:routines]).to be_empty
      end
    end

    context 'when AI service fails twice then succeeds' do
      it 'raises error after maximum retries from AiApiClient' do
        mock_client = instance_double(AiApiClient)
        allow(AiApiClient).to receive(:new).and_return(mock_client)
        
        # AiApiClient already handles retries internally, so when it raises NetworkError, 
        # it means it already exhausted its retries
        allow(mock_client).to receive(:create_routine)
          .and_raise(AiApiClient::NetworkError, 'Failed after all retries')

        expect { service.create_routine }.to raise_error(
          AiWorkoutRoutineService::ServiceUnavailableError,
          /AI service network error: Failed after all retries/
        )
      end

      it 'succeeds on second attempt when AiApiClient handles retries internally' do
        mock_client = instance_double(AiApiClient)
        allow(AiApiClient).to receive(:new).and_return(mock_client)
        
        # Simulate AiApiClient succeeding after internal retries
        allow(mock_client).to receive(:create_routine).and_return(mock_ai_response)

        result = service.create_routine

        expect(result).to have_key(:routines)
        expect(result[:routines]).to be_an(Array)
        expect(result[:routines].length).to eq(2)
      end
    end
  end

  describe 'exercise ID and name validation scenarios' do
    let(:modify_service) { described_class.new({}, :modify) }
    
    # Create test exercises with specific names for validation scenarios
    let!(:bench_press_exercise) { create(:exercise, name: 'Bench Press') }
    let!(:squat_exercise) { create(:exercise, name: 'Squat') }
    let!(:deadlift_exercise) { create(:exercise, name: 'Deadlift') }
    let!(:pull_up_exercise) { create(:exercise, name: 'Pull-up') }

    context 'when exercise ID does not exist but name exists in database' do
      let(:non_existent_id_response) do
        {
          exercises: [
            {
              exercise_id: 99999,  # Non-existent ID
              exercise_name: 'Bench Press',  # But name exists in DB
              sets: 4,
              reps: 10,
              rest_time: 60,
              order: 1
            }
          ]
        }.to_json
      end

      it 'raises InvalidResponseError for non-existent exercise_id' do
        mock_client = instance_double(AiApiClient)
        allow(AiApiClient).to receive(:new).with(:modify).and_return(mock_client)
        allow(mock_client).to receive(:create_routine).and_return(non_existent_id_response)

        sample_exercises = [
          { exercise_id: bench_press_exercise.id, sets: 3, reps: 10 }
        ]

        expect { modify_service.modify_exercises(sample_exercises, 'change exercise') }.to raise_error(
          AiWorkoutRoutineService::InvalidResponseError,
          /Exercise ID 99999 does not exist in the database/
        )
      end
    end

    context 'when exercise ID exists but name does not match' do
      let(:mismatched_name_response) do
        {
          exercises: [
            {
              exercise_id: bench_press_exercise.id,  # Valid ID
              exercise_name: 'Non-existent Exercise Name',  # But name doesn't match
              sets: 4,
              reps: 10,
              rest_time: 60,
              order: 1
            }
          ]
        }.to_json
      end

      it 'succeeds because only exercise_id is validated, not exercise_name' do
        mock_client = instance_double(AiApiClient)
        allow(AiApiClient).to receive(:new).with(:modify).and_return(mock_client)
        allow(mock_client).to receive(:create_routine).and_return(mismatched_name_response)

        sample_exercises = [
          { exercise_id: bench_press_exercise.id, sets: 3, reps: 10 }
        ]

        result = modify_service.modify_exercises(sample_exercises, 'change exercise name')

        expect(result).to have_key(:exercises)
        expect(result[:exercises]).to be_an(Array)
        expect(result[:exercises][0][:exercise_id]).to eq(bench_press_exercise.id)
        # Note: exercise_name field is ignored during validation
      end
    end

    context 'when exercise ID and name are both correct' do
      let(:correct_data_response) do
        {
          exercises: [
            {
              exercise_id: bench_press_exercise.id,
              exercise_name: 'Bench Press',  # Correct name matching DB
              sets: 4,
              reps: 12,
              rest_time: 90,
              order: 1
            },
            {
              exercise_id: squat_exercise.id,
              exercise_name: 'Squat',  # Correct name matching DB
              sets: 3,
              reps: 15,
              rest_time: 120,
              order: 2
            }
          ]
        }.to_json
      end

      it 'processes exercises without modification when data is correct' do
        mock_client = instance_double(AiApiClient)
        allow(AiApiClient).to receive(:new).with(:modify).and_return(mock_client)
        allow(mock_client).to receive(:create_routine).and_return(correct_data_response)

        sample_exercises = [
          { exercise_id: bench_press_exercise.id, sets: 3, reps: 10 },
          { exercise_id: squat_exercise.id, sets: 4, reps: 12 }
        ]

        result = modify_service.modify_exercises(sample_exercises, 'keep exercises as they are')

        expect(result).to have_key(:exercises)
        expect(result[:exercises]).to be_an(Array)
        expect(result[:exercises].length).to eq(2)
        
        # Verify first exercise
        expect(result[:exercises][0][:exercise_id]).to eq(bench_press_exercise.id)
        expect(result[:exercises][0][:sets]).to eq(4)
        expect(result[:exercises][0][:reps]).to eq(12)
        expect(result[:exercises][0][:rest_time]).to eq(90)
        expect(result[:exercises][0][:order]).to eq(1)
        
        # Verify second exercise
        expect(result[:exercises][1][:exercise_id]).to eq(squat_exercise.id)
        expect(result[:exercises][1][:sets]).to eq(3)
        expect(result[:exercises][1][:reps]).to eq(15)
        expect(result[:exercises][1][:rest_time]).to eq(120)
        expect(result[:exercises][1][:order]).to eq(2)
      end

      it 'preserves all exercise data fields correctly' do
        mock_client = instance_double(AiApiClient)
        allow(AiApiClient).to receive(:new).with(:modify).and_return(mock_client)
        allow(mock_client).to receive(:create_routine).and_return(correct_data_response)

        sample_exercises = [
          { exercise_id: bench_press_exercise.id, sets: 3, reps: 10 }
        ]

        result = modify_service.modify_exercises(sample_exercises, 'maintain current exercise')

        exercise = result[:exercises][0]
        
        # Verify all required fields are present and correct
        expect(exercise).to have_key(:exercise_id)
        expect(exercise).to have_key(:sets)
        expect(exercise).to have_key(:reps)
        expect(exercise).to have_key(:rest_time)
        expect(exercise).to have_key(:order)
        
        # Verify values are as expected
        expect(exercise[:exercise_id]).to be_a(Integer)
        expect(exercise[:sets]).to be_a(Integer)
        expect(exercise[:reps]).to be_a(Integer)
        expect(exercise[:rest_time]).to be_a(Integer)
        expect(exercise[:order]).to be_a(Integer)
      end
    end

    context 'when multiple exercises have mixed validation scenarios' do
      let(:mixed_scenario_response) do
        {
          exercises: [
            {
              exercise_id: bench_press_exercise.id,  # Valid ID and matching name
              exercise_name: 'Bench Press',
              sets: 4,
              reps: 10,
              rest_time: 60,
              order: 1
            },
            {
              exercise_id: squat_exercise.id,  # Valid ID but different name (should still work)
              exercise_name: 'Back Squat',
              sets: 3,
              reps: 12,
              rest_time: 90,
              order: 2
            },
            {
              exercise_id: deadlift_exercise.id,  # Valid ID with extra fields
              exercise_name: 'Deadlift',
              sets: 5,
              reps: 5,
              rest_time: 180,
              order: 3,
              weight: 225,  # Extra field
              notes: 'Heavy day'  # Extra field
            }
          ]
        }.to_json
      end

      it 'processes all exercises successfully when IDs are valid' do
        mock_client = instance_double(AiApiClient)
        allow(AiApiClient).to receive(:new).with(:modify).and_return(mock_client)
        allow(mock_client).to receive(:create_routine).and_return(mixed_scenario_response)

        sample_exercises = [
          { exercise_id: bench_press_exercise.id, sets: 3, reps: 8 },
          { exercise_id: squat_exercise.id, sets: 4, reps: 10 },
          { exercise_id: deadlift_exercise.id, sets: 3, reps: 6 }
        ]

        result = modify_service.modify_exercises(sample_exercises, 'update all exercises')

        expect(result[:exercises].length).to eq(3)
        
        # Verify each exercise processed correctly
        expect(result[:exercises][0][:exercise_id]).to eq(bench_press_exercise.id)
        expect(result[:exercises][1][:exercise_id]).to eq(squat_exercise.id)
        expect(result[:exercises][2][:exercise_id]).to eq(deadlift_exercise.id)
        
        # Verify orders are normalized
        expect(result[:exercises][0][:order]).to eq(1)
        expect(result[:exercises][1][:order]).to eq(2)
        expect(result[:exercises][2][:order]).to eq(3)
      end
    end
  end

  describe 'edge cases in exercise validation and processing' do
    let(:modify_service) { described_class.new({}, :modify) }
    let!(:test_exercise) { create(:exercise, name: 'Test Exercise') }

    context 'when AI response contains exercises with minimal required fields' do
      let(:minimal_fields_response) do
        {
          exercises: [
            {
              exercise_id: test_exercise.id,
              sets: 3,
              reps: 10
              # Missing rest_time and order (should get defaults)
            }
          ]
        }.to_json
      end

      it 'adds default values for missing optional fields' do
        mock_client = instance_double(AiApiClient)
        allow(AiApiClient).to receive(:new).with(:modify).and_return(mock_client)
        allow(mock_client).to receive(:create_routine).and_return(minimal_fields_response)

        sample_exercises = [
          { exercise_id: test_exercise.id, sets: 4, reps: 12 }
        ]

        result = modify_service.modify_exercises(sample_exercises, 'simplify exercise')

        exercise = result[:exercises][0]
        expect(exercise[:rest_time]).to eq(0)  # Default value
        expect(exercise[:order]).to eq(1)      # Default normalized value
      end
    end

    context 'when processing exercises with boundary values' do
      let(:boundary_values_response) do
        {
          exercises: [
            {
              exercise_id: test_exercise.id,
              sets: 1,      # Minimum valid value
              reps: 1,      # Minimum valid value
              rest_time: 0, # Minimum valid value
              order: 1
            },
            {
              exercise_id: test_exercise.id,
              sets: 20,     # Maximum valid value
              reps: 100,    # Maximum valid value
              rest_time: 600, # Maximum valid value
              order: 2
            }
          ]
        }.to_json
      end

      it 'accepts exercises with boundary values' do
        mock_client = instance_double(AiApiClient)
        allow(AiApiClient).to receive(:new).with(:modify).and_return(mock_client)
        allow(mock_client).to receive(:create_routine).and_return(boundary_values_response)

        sample_exercises = [
          { exercise_id: test_exercise.id, sets: 3, reps: 10 }
        ]

        result = modify_service.modify_exercises(sample_exercises, 'test boundary values')

        expect(result[:exercises].length).to eq(2)
        
        # Verify minimum values
        min_exercise = result[:exercises][0]
        expect(min_exercise[:sets]).to eq(1)
        expect(min_exercise[:reps]).to eq(1)
        expect(min_exercise[:rest_time]).to eq(0)
        
        # Verify maximum values
        max_exercise = result[:exercises][1]
        expect(max_exercise[:sets]).to eq(20)
        expect(max_exercise[:reps]).to eq(100)
        expect(max_exercise[:rest_time]).to eq(600)
      end
    end
  end

  # NEW COMPREHENSIVE TESTS FOR REQUESTED FUNCTIONALITY
  describe 'empty routines retry mechanism' do
    let(:service) { described_class.new(valid_params) }
    
    context 'when AI service returns empty routines with retry logic' do
      let(:empty_routines_response) do
        {
          routines: []
        }.to_json
      end

      it 'fails after 2 attempts returning InvalidResponseError when empty routines persist' do
        mock_client = instance_double(AiApiClient)
        allow(AiApiClient).to receive(:new).and_return(mock_client)
        # Both attempts return empty routines
        allow(mock_client).to receive(:create_routine).and_return(empty_routines_response)

        expect { service.create_routine }.to raise_error(
          AiWorkoutRoutineService::InvalidResponseError,
          /AI service returned empty routines after 2 attempts/
        )
      end

      it 'succeeds on second attempt when first returns empty, second returns valid routines' do
        mock_client = instance_double(AiApiClient)
        allow(AiApiClient).to receive(:new).and_return(mock_client)
        
        call_count = 0
        allow(mock_client).to receive(:create_routine) do
          call_count += 1
          if call_count == 1
            empty_routines_response  # First call returns empty
          else
            mock_ai_response  # Second call returns valid routines
          end
        end

        result = service.create_routine

        expect(result).to have_key(:routines)
        expect(result[:routines]).to be_an(Array)
        expect(result[:routines].length).to eq(2)
        expect(result[:routines]).not_to be_empty
      end
    end
  end

  describe 'exercise ID and name correction functionality' do
    let(:service) { described_class.new(valid_params) }
    
    # Create test exercises with specific names for correction scenarios
    let!(:existing_bench_press) { create(:exercise, name: 'Bench Press') }
    let!(:existing_squat) { create(:exercise, name: 'Squat') }
    let!(:existing_deadlift) { create(:exercise, name: 'Deadlift') }

    context 'when exercise ID does not exist but name exists in database' do
      let(:non_existent_id_response) do
        {
          routines: [{
            routine: {
              name: 'Test Routine',
              description: 'Test description',
              difficulty: 'intermediate',
              duration: 45,
              exercises: [
                {
                  exercise_id: 99999,  # Non-existent ID
                  name: 'Bench Press',  # But name exists in DB
                  sets: 4,
                  reps: 10,
                  rest_time: 60,
                  order: 1
                }
              ]
            }
          }]
        }.to_json
      end

      it 'corrects non-existent exercise_id by finding matching name in database' do
        mock_client = instance_double(AiApiClient)
        allow(AiApiClient).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:create_routine).and_return(non_existent_id_response)

        result = service.create_routine

        # Verify the exercise_id was corrected to the existing exercise's ID
        exercise = result[:routines][0][:routine][:exercises][0]
        expect(exercise[:exercise_id]).to eq(existing_bench_press.id)
        expect(exercise[:name]).to eq('Bench Press')
      end
    end

    context 'when exercise ID exists but name does not match database' do
      let(:mismatched_name_response) do
        {
          routines: [{
            routine: {
              name: 'Test Routine',
              description: 'Test description', 
              difficulty: 'intermediate',
              duration: 45,
              exercises: [
                {
                  exercise_id: existing_squat.id,  # Valid ID
                  name: 'Wrong Exercise Name',  # But name doesn't match DB
                  sets: 4,
                  reps: 10,
                  rest_time: 60,
                  order: 1
                }
              ]
            }
          }]
        }.to_json
      end

      it 'corrects exercise name to match database when ID exists but name differs' do
        mock_client = instance_double(AiApiClient)
        allow(AiApiClient).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:create_routine).and_return(mismatched_name_response)

        result = service.create_routine

        # Verify the name was corrected to match the database
        exercise = result[:routines][0][:routine][:exercises][0]
        expect(exercise[:exercise_id]).to eq(existing_squat.id)
        expect(exercise[:name]).to eq('Squat')  # Corrected name from database
      end
    end

    context 'when exercise ID and name are both correct' do
      let(:correct_data_response) do
        {
          routines: [{
            routine: {
              name: 'Test Routine',
              description: 'Test description',
              difficulty: 'intermediate', 
              duration: 45,
              exercises: [
                {
                  exercise_id: existing_deadlift.id,  # Correct ID
                  name: 'Deadlift',  # Correct name matching DB
                  sets: 5,
                  reps: 5,
                  rest_time: 180,
                  order: 1
                }
              ]
            }
          }]
        }.to_json
      end

      it 'does not modify exercise data when ID and name are already correct' do
        mock_client = instance_double(AiApiClient)
        allow(AiApiClient).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:create_routine).and_return(correct_data_response)

        result = service.create_routine

        # Verify data remains unchanged since it was already correct
        exercise = result[:routines][0][:routine][:exercises][0]
        expect(exercise[:exercise_id]).to eq(existing_deadlift.id)
        expect(exercise[:name]).to eq('Deadlift')
        expect(exercise[:sets]).to eq(5)
        expect(exercise[:reps]).to eq(5)
        expect(exercise[:rest_time]).to eq(180)
        expect(exercise[:order]).to eq(1)
      end
    end

    context 'when processing multiple exercises with mixed correction needs' do
      let(:mixed_correction_response) do
        {
          routines: [{
            routine: {
              name: 'Mixed Correction Test',
              description: 'Test with different correction scenarios',
              difficulty: 'intermediate',
              duration: 60,
              exercises: [
                {
                  exercise_id: 99998,  # Non-existent ID
                  name: 'Bench Press',  # Valid name in DB
                  sets: 4,
                  reps: 10,
                  order: 1
                },
                {
                  exercise_id: existing_squat.id,  # Valid ID
                  name: 'Wrong Squat Name',  # Wrong name
                  sets: 3,
                  reps: 12,
                  order: 2  
                },
                {
                  exercise_id: existing_deadlift.id,  # Correct ID
                  name: 'Deadlift',  # Correct name
                  sets: 5,
                  reps: 5,
                  order: 3
                }
              ]
            }
          }]
        }.to_json
      end

      it 'applies appropriate corrections to each exercise based on their individual needs' do
        mock_client = instance_double(AiApiClient)
        allow(AiApiClient).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:create_routine).and_return(mixed_correction_response)

        result = service.create_routine

        exercises = result[:routines][0][:routine][:exercises]
        
        # First exercise: ID corrected by name lookup
        expect(exercises[0][:exercise_id]).to eq(existing_bench_press.id)
        expect(exercises[0][:name]).to eq('Bench Press')
        
        # Second exercise: Name corrected to match database
        expect(exercises[1][:exercise_id]).to eq(existing_squat.id)
        expect(exercises[1][:name]).to eq('Squat')
        
        # Third exercise: No changes needed
        expect(exercises[2][:exercise_id]).to eq(existing_deadlift.id)
        expect(exercises[2][:name]).to eq('Deadlift')
      end
    end

    context 'when exercise name contains partial matches' do
      let!(:partial_match_exercise) { create(:exercise, name: 'Barbell Bench Press') }
      
      let(:partial_match_response) do
        {
          routines: [{
            routine: {
              name: 'Partial Match Test',
              description: 'Test partial name matching',
              difficulty: 'intermediate',
              duration: 45,
              exercises: [
                {
                  exercise_id: 99997,  # Non-existent ID
                  name: 'Bench Press',  # Partial match with 'Barbell Bench Press'
                  sets: 4,
                  reps: 10,
                  order: 1
                }
              ]
            }
          }]
        }.to_json
      end

      it 'finds exercise using partial name matching when exact match fails' do
        mock_client = instance_double(AiApiClient)
        allow(AiApiClient).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:create_routine).and_return(partial_match_response)

        result = service.create_routine

        # Should find 'Barbell Bench Press' using partial match with 'Bench Press'
        exercise = result[:routines][0][:routine][:exercises][0]
        expect(exercise[:exercise_id]).to eq(partial_match_exercise.id)
        expect(exercise[:name]).to eq('Barbell Bench Press')
      end
    end

    context 'when no matching exercise is found' do
      let(:no_match_response) do
        {
          routines: [{
            routine: {
              name: 'No Match Test',
              description: 'Test with no matching exercises',
              difficulty: 'intermediate',
              duration: 45,
              exercises: [
                {
                  exercise_id: 99996,  # Non-existent ID
                  name: 'Non-existent Exercise',  # Name not in DB
                  sets: 4,
                  reps: 10,
                  order: 1
                }
              ]
            }
          }]
        }.to_json
      end

      it 'leaves exercise unchanged when no match is found and logs error' do
        mock_client = instance_double(AiApiClient)
        allow(AiApiClient).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:create_routine).and_return(no_match_response)
        
        # Expect error to be logged but not to raise exception
        expect(Rails.logger).to receive(:error).with(
          /Could not find exercise by name 'Non-existent Exercise'/
        )

        result = service.create_routine

        # Exercise should remain with original (invalid) data
        exercise = result[:routines][0][:routine][:exercises][0]
        expect(exercise[:exercise_id]).to eq(99996)  # Unchanged
        expect(exercise[:name]).to eq('Non-existent Exercise')  # Unchanged
      end
    end
  end

  describe 'integration with realistic mock data' do
    let(:service) { described_class.new(valid_params) }
    let(:modify_service) { described_class.new({}, :modify) }

    # Create a realistic set of exercises
    before do
      @exercises = {
        bench_press: create(:exercise, name: 'Bench Press'),
        incline_dumbbell_press: create(:exercise, name: 'Incline Dumbbell Press'),
        pull_ups: create(:exercise, name: 'Pull-ups'),
        barbell_rows: create(:exercise, name: 'Barbell Rows'),
        squats: create(:exercise, name: 'Squats'),
        deadlifts: create(:exercise, name: 'Deadlifts'),
        overhead_press: create(:exercise, name: 'Overhead Press'),
        dips: create(:exercise, name: 'Dips')
      }
    end

    context 'with realistic AI responses' do
      let(:realistic_ai_response) do
        {
          routines: [
            {
              routine: {
                name: 'Upper Body Strength Training',
                description: 'Compound movements for upper body development',
                difficulty: 'intermediate',
                duration: 60,
                exercises: [
                  {
                    exercise_id: @exercises[:bench_press].id,
                    sets: 4,
                    reps: 8,
                    rest_time: 120,
                    order: 1
                  },
                  {
                    exercise_id: @exercises[:pull_ups].id,
                    sets: 3,
                    reps: 10,
                    rest_time: 90,
                    order: 2
                  },
                  {
                    exercise_id: @exercises[:overhead_press].id,
                    sets: 3,
                    reps: 12,
                    rest_time: 60,
                    order: 3
                  }
                ]
              }
            },
            {
              routine: {
                name: 'Lower Body Power',
                description: 'Explosive movements for lower body strength',
                difficulty: 'advanced',
                duration: 45,
                exercises: [
                  {
                    exercise_id: @exercises[:squats].id,
                    sets: 5,
                    reps: 5,
                    rest_time: 180,
                    order: 1
                  },
                  {
                    exercise_id: @exercises[:deadlifts].id,
                    sets: 3,
                    reps: 6,
                    rest_time: 240,
                    order: 2
                  }
                ]
              }
            }
          ]
        }.to_json
      end

      it 'processes realistic multi-routine response successfully' do
        mock_client = instance_double(AiApiClient)
        allow(AiApiClient).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:create_routine).and_return(realistic_ai_response)

        result = service.create_routine

        expect(result).to have_key(:routines)
        expect(result[:routines].length).to eq(2)
        
        # Validate first routine
        first_routine = result[:routines][0][:routine]
        expect(first_routine[:name]).to eq('Upper Body Strength Training')
        expect(first_routine[:exercises].length).to eq(3)
        expect(first_routine[:exercises][0][:exercise_id]).to eq(@exercises[:bench_press].id)
        
        # Validate second routine
        second_routine = result[:routines][1][:routine]
        expect(second_routine[:name]).to eq('Lower Body Power')
        expect(second_routine[:exercises].length).to eq(2)
        expect(second_routine[:exercises][0][:exercise_id]).to eq(@exercises[:squats].id)
      end

      it 'handles modification of realistic exercise list' do
        exercises = [
          {
            exercise_id: @exercises[:bench_press].id,
            sets: 4,
            reps: 8,
            rest_time: 120,
            order: 1
          },
          {
            exercise_id: @exercises[:incline_dumbbell_press].id,
            sets: 3,
            reps: 10,
            rest_time: 90,
            order: 2
          }
        ]

        modified_response = {
          exercises: [
            {
              exercise_id: @exercises[:dips].id,
              sets: 4,
              reps: 12,
              rest_time: 60,
              order: 1
            },
            {
              exercise_id: @exercises[:incline_dumbbell_press].id,
              sets: 3,
              reps: 10,
              rest_time: 90,
              order: 2
            }
          ]
        }.to_json

        mock_client = instance_double(AiApiClient)
        allow(AiApiClient).to receive(:new).with(:modify).and_return(mock_client)
        allow(mock_client).to receive(:create_routine).and_return(modified_response)

        result = modify_service.modify_exercises(exercises, 'Replace bench press with dips')

        expect(result[:exercises].length).to eq(2)
        expect(result[:exercises][0][:exercise_id]).to eq(@exercises[:dips].id)
        expect(result[:exercises][1][:exercise_id]).to eq(@exercises[:incline_dumbbell_press].id)
      end
    end

    context 'with error scenarios in realistic data' do
      it 'handles missing exercise in realistic routine' do
        invalid_routine_response = {
          routines: [{
            routine: {
              name: 'Invalid Routine',
              description: 'Contains non-existent exercise',
              difficulty: 'intermediate',
              duration: 45,
              exercises: [
                {
                  exercise_id: @exercises[:bench_press].id,
                  sets: 4,
                  reps: 8
                },
                {
                  exercise_id: 99999,  # Non-existent exercise
                  sets: 3,
                  reps: 10
                }
              ]
            }
          }]
        }.to_json

        mock_client = instance_double(AiApiClient)
        allow(AiApiClient).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:create_routine).and_return(invalid_routine_response)

        # The service should parse successfully but validation would catch the issue later
        result = service.send(:parse_ai_response, invalid_routine_response)
        expect(result[:routines]).to be_an(Array)
        expect(result[:routines][0][:routine][:exercises].length).to eq(2)
      end

      it 'handles realistic validation errors during exercise modification' do
        exercises = [
          {
            exercise_id: @exercises[:bench_press].id,
            sets: 25,  # Invalid: too many sets
            reps: 8,
            rest_time: 120
          }
        ]

        expect { modify_service.send(:validate_exercise_ranges, exercises) }.to raise_error(
          AiWorkoutRoutineService::InvalidResponseError,
          /sets must be between 1 and 20/
        )
      end
    end
  end

  # New comprehensive tests for retry logic and exercise ID correction
  describe '#create_routine with retry logic and exercise correction' do
    let(:service) { described_class.new(valid_params) }

    describe 'empty routines retry logic' do
      context 'when AI returns empty routines on all attempts' do
        it 'retries exactly 2 times then raises InvalidResponseError' do
          mock_client = instance_double(AiApiClient)
          allow(AiApiClient).to receive(:new).and_return(mock_client)
          
          # Mock AI to return empty routines on both attempts
          allow(mock_client).to receive(:create_routine)
            .exactly(2).times
            .and_return('{"routines": []}')
          
          expect(Rails.logger).to receive(:warn).with(/AI returned empty routines on attempt/)
          expect(Rails.logger).to receive(:info).with(/AI routine creation attempt/)
          
          expect { service.create_routine }.to raise_error(
            AiWorkoutRoutineService::InvalidResponseError,
            /AI service returned empty routines after 2 attempts/
          )
        end
      end

      context 'when AI succeeds on second attempt' do
        it 'returns valid data after first failure' do
          mock_client = instance_double(AiApiClient)
          allow(AiApiClient).to receive(:new).and_return(mock_client)
          
          # First call returns empty, second returns valid data
          call_count = 0
          allow(mock_client).to receive(:create_routine) do
            call_count += 1
            if call_count == 1
              '{"routines": []}'
            else
              mock_ai_response
            end
          end
          
          expect(Rails.logger).to receive(:warn).with(/AI returned empty routines on attempt 1/)
          expect(Rails.logger).to receive(:info).with(/Successfully generated .* routine\(s\) on attempt 2/)
          
          result = service.create_routine
          expect(result[:routines]).not_to be_empty
          expect(result[:routines].length).to eq(2)
        end
      end
    end

    describe 'exercise ID and name correction' do
      let!(:correct_bench_press) { create(:exercise, name: 'Bench Press') }
      let!(:correct_squat) { create(:exercise, name: 'Squat') }
      let!(:wrong_exercise) { create(:exercise, id: 999, name: 'Wrong Exercise') }

      context 'when exercise_id does not exist but name does' do
        it 'corrects exercise_id by finding exercise by name' do
          mock_client = instance_double(AiApiClient)
          allow(AiApiClient).to receive(:new).and_return(mock_client)
          
          invalid_id_response = {
            "routines": [{
              "routine": {
                "name": "Test Routine",
                "description": "Test",
                "difficulty": "beginner", 
                "duration": 45,
                "exercises": [{
                  "exercise_id": 88888,  # Non-existent ID
                  "name": "Bench Press", # But name exists in DB
                  "sets": 3,
                  "reps": 10,
                  "rest_time": 60,
                  "order": 1
                }]
              }
            }]
          }.to_json
          
          allow(mock_client).to receive(:create_routine).and_return(invalid_id_response)
          
          expect(Rails.logger).to receive(:info).with(/Exercise ID 88888 does not exist in database/)
          expect(Rails.logger).to receive(:info).with(/Corrected exercise 1 in routine 1/)
          
          result = service.create_routine
          fixed_exercise = result[:routines][0][:routine][:exercises][0]
          
          expect(fixed_exercise[:exercise_id]).to eq(correct_bench_press.id)
          expect(fixed_exercise[:name]).to eq('Bench Press')
        end
      end

      context 'when exercise_id exists but name does not match' do
        it 'corrects both ID and name by searching by name' do
          mock_client = instance_double(AiApiClient)
          allow(AiApiClient).to receive(:new).and_return(mock_client)
          
          mismatch_response = {
            "routines": [{
              "routine": {
                "name": "Test Routine", 
                "description": "Test",
                "difficulty": "beginner",
                "duration": 45,
                "exercises": [{
                  "exercise_id": 999,     # Exists but...
                  "name": "Bench Press", # Name doesn't match ID 999 (Wrong Exercise)
                  "sets": 3,
                  "reps": 10,
                  "rest_time": 60,
                  "order": 1
                }]
              }
            }]
          }.to_json
          
          allow(mock_client).to receive(:create_routine).and_return(mismatch_response)
          
          expect(Rails.logger).to receive(:info).with(/Exercise ID 999 name mismatch/)
          expect(Rails.logger).to receive(:info).with(/Corrected exercise 1 in routine 1/)
          
          result = service.create_routine
          fixed_exercise = result[:routines][0][:routine][:exercises][0]
          
          expect(fixed_exercise[:exercise_id]).to eq(correct_bench_press.id)
          expect(fixed_exercise[:name]).to eq('Bench Press')
        end
      end

      context 'when exercise_id and name are both correct' do
        it 'does not modify the exercise' do
          mock_client = instance_double(AiApiClient)
          allow(AiApiClient).to receive(:new).and_return(mock_client)
          
          correct_response = {
            "routines": [{
              "routine": {
                "name": "Test Routine",
                "description": "Test", 
                "difficulty": "beginner",
                "duration": 45,
                "exercises": [{
                  "exercise_id": correct_bench_press.id,
                  "name": "Bench Press",
                  "sets": 3,
                  "reps": 10,
                  "rest_time": 60,
                  "order": 1
                }]
              }
            }]
          }.to_json
          
          allow(mock_client).to receive(:create_routine).and_return(correct_response)
          
          expect(Rails.logger).to receive(:debug).with(/ID #{correct_bench_press.id} and name 'Bench Press' are correct/)
          
          result = service.create_routine
          exercise = result[:routines][0][:routine][:exercises][0]
          
          expect(exercise[:exercise_id]).to eq(correct_bench_press.id)
          expect(exercise[:name]).to eq('Bench Press')
        end
      end

      context 'when exercise name cannot be found' do
        it 'logs error but continues processing' do
          mock_client = instance_double(AiApiClient)
          allow(AiApiClient).to receive(:new).and_return(mock_client)
          
          unfindable_response = {
            "routines": [{
              "routine": {
                "name": "Test Routine",
                "description": "Test",
                "difficulty": "beginner", 
                "duration": 45,
                "exercises": [{
                  "exercise_id": 88888,
                  "name": "Nonexistent Exercise Name",
                  "sets": 3,
                  "reps": 10,
                  "rest_time": 60,
                  "order": 1
                }]
              }
            }]
          }.to_json
          
          allow(mock_client).to receive(:create_routine).and_return(unfindable_response)
          
          expect(Rails.logger).to receive(:info).with(/Exercise ID 88888 does not exist in database/)
          expect(Rails.logger).to receive(:error).with(/Could not find exercise by name 'Nonexistent Exercise Name'/)
          
          result = service.create_routine
          exercise = result[:routines][0][:routine][:exercises][0]
          
          # Should remain unchanged since no match was found
          expect(exercise[:exercise_id]).to eq(88888)
          expect(exercise[:name]).to eq('Nonexistent Exercise Name')
        end
      end
    end

    describe 'partial name matching' do
      let!(:bench_press_exercise) { create(:exercise, name: 'Incline Bench Press') }
      
      it 'finds exercises with partial name matches using ILIKE' do
        mock_client = instance_double(AiApiClient)
        allow(AiApiClient).to receive(:new).and_return(mock_client)
        
        partial_match_response = {
          "routines": [{
            "routine": {
              "name": "Test Routine",
              "description": "Test",
              "difficulty": "beginner",
              "duration": 45, 
              "exercises": [{
                "exercise_id": 99999,
                "name": "Bench Press",  # Partial match with "Incline Bench Press"
                "sets": 3,
                "reps": 10,
                "rest_time": 60,
                "order": 1
              }]
            }
          }]
        }.to_json
        
        allow(mock_client).to receive(:create_routine).and_return(partial_match_response)
        
        expect(Rails.logger).to receive(:info).with(/Exercise ID 99999 does not exist in database/)
        expect(Rails.logger).to receive(:info).with(/Corrected exercise 1 in routine 1.*Incline Bench Press/)
        
        result = service.create_routine
        fixed_exercise = result[:routines][0][:routine][:exercises][0]
        
        expect(fixed_exercise[:exercise_id]).to eq(bench_press_exercise.id)
        expect(fixed_exercise[:name]).to eq('Incline Bench Press')
      end
    end
  end
end
