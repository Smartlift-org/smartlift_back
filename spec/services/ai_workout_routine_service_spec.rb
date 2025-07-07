require 'rails_helper'

# AI functionality tests
RSpec.describe AiWorkoutRoutineService, skip: "AI functionality not finished" do
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
    <<~RESPONSE
      <explicacion>
      Esta rutina fue diseñada específicamente para tu objetivo de ganar masa muscular, considerando tu nivel intermedio y disponibilidad de mancuernas y barras. He incluido ejercicios compuestos que trabajan múltiples grupos musculares simultáneamente, maximizando el estímulo de crecimiento. Las series y repeticiones están ajustadas para el rango de hipertrofia (8-12 repeticiones), con descansos adecuados para permitir una recuperación completa entre series.
      </explicacion>

      <json>
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
                  "exercise_id": 1,
                  "sets": 4,
                  "reps": 10,
                  "rest_time": 60,
                  "order": 1
                },
                {
                  "exercise_id": 2,
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
                  "exercise_id": 3,
                  "sets": 4,
                  "reps": 8,
                  "rest_time": 90,
                  "order": 1
                },
                {
                  "exercise_id": 4,
                  "sets": 3,
                  "reps": 10,
                  "rest_time": 60,
                  "order": 2
                }
              ]
            }
          }
        ]
      }
      </json>
    RESPONSE
  end

  let(:service) { described_class.new(valid_params) }

  before do
    # Create test exercises
    FactoryBot.create(:exercise, id: 1, name: 'Bench Press', equipment: 'barbell', category: 'strength')
    FactoryBot.create(:exercise, id: 2, name: 'Dumbbell Curl', equipment: 'dumbbell', category: 'strength')
    FactoryBot.create(:exercise, id: 3, name: 'Squat', equipment: 'barbell', category: 'strength')
    FactoryBot.create(:exercise, id: 4, name: 'Push-up', equipment: 'body only', category: 'strength')
  end

  describe '#generate_routine' do
    context 'when AI service returns valid response' do
      it 'returns parsed explanation and routine' do
        # Mock the AI client
        mock_client = instance_double(AiApiClient)
        allow(AiApiClient).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:generate_routine).and_return(mock_ai_response)

        result = service.generate_routine

        expect(result[:explanation]).to include('Esta rutina fue diseñada específicamente')
        expect(result[:routine][:days]).to be_an(Array)
        expect(result[:routine][:days].length).to eq(2)
        
        # Check first day structure
        first_day = result[:routine][:days][0]
        expect(first_day[:day]).to eq('Monday')
        expect(first_day[:routine][:name]).to eq('Upper Body Strength')
        expect(first_day[:routine][:routine_exercises_attributes]).to be_an(Array)
        expect(first_day[:routine][:routine_exercises_attributes].length).to eq(2)
      end
    end

    context 'when AI service returns invalid response format' do
      it 'raises InvalidResponseError for missing explanation block' do
        mock_client = instance_double(AiApiClient)
        allow(AiApiClient).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:generate_routine).and_return('<json>{}</json>')

        expect { service.generate_routine }.to raise_error(
          AiWorkoutRoutineService::InvalidResponseError,
          /Could not find <explicacion> block/
        )
      end

      it 'raises InvalidResponseError for missing JSON block' do
        mock_client = instance_double(AiApiClient)
        allow(AiApiClient).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:generate_routine).and_return('<explicacion>Test</explicacion>')

        expect { service.generate_routine }.to raise_error(
          AiWorkoutRoutineService::InvalidResponseError,
          /Could not find <json> block/
        )
      end

      it 'raises InvalidResponseError for malformed JSON' do
        invalid_response = <<~RESPONSE
          <explicacion>Test</explicacion>
          <json>{ invalid json }</json>
        RESPONSE

        mock_client = instance_double(AiApiClient)
        allow(AiApiClient).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:generate_routine).and_return(invalid_response)

        expect { service.generate_routine }.to raise_error(
          AiWorkoutRoutineService::InvalidResponseError,
          /Invalid JSON in AI response/
        )
      end
    end

    context 'when AI service returns invalid exercise IDs' do
      it 'raises InvalidExerciseIdError' do
        invalid_response = mock_ai_response.gsub('"exercise_id": 1', '"exercise_id": 999')

        mock_client = instance_double(AiApiClient)
        allow(AiApiClient).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:generate_routine).and_return(invalid_response)

        expect { service.generate_routine }.to raise_error(
          AiWorkoutRoutineService::InvalidExerciseIdError,
          /Invalid exercise IDs found in AI response: 999/
        )
      end
    end

    context 'when AI client raises errors' do
      it 'converts AiApiClient::TimeoutError to ServiceUnavailableError' do
        mock_client = instance_double(AiApiClient)
        allow(AiApiClient).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:generate_routine)
          .and_raise(AiApiClient::TimeoutError, 'Timeout')

        expect { service.generate_routine }.to raise_error(
          AiWorkoutRoutineService::ServiceUnavailableError,
          /AI service timeout/
        )
      end

      it 'converts AiApiClient::NetworkError to ServiceUnavailableError' do
        mock_client = instance_double(AiApiClient)
        allow(AiApiClient).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:generate_routine)
          .and_raise(AiApiClient::NetworkError, 'Network error')

        expect { service.generate_routine }.to raise_error(
          AiWorkoutRoutineService::ServiceUnavailableError,
          /AI service network error/
        )
      end
    end
  end

  describe '#build_prompt' do
    it 'includes all user parameters in the prompt' do
      prompt = service.send(:build_prompt)

      expect(prompt).to include('Age: 30')
      expect(prompt).to include('Gender: male')
      expect(prompt).to include('Weight: 80kg')
      expect(prompt).to include('Height: 175cm')
      expect(prompt).to include('Experience level: intermediate')
      expect(prompt).to include('Available equipment: barbell, dumbbell')
      expect(prompt).to include('Preferences: No cardio, solo tren superior')
      expect(prompt).to include('Training frequency: 3 days per week')
      expect(prompt).to include('Session duration: 45 minutes')
      expect(prompt).to include('Goal: ganar masa muscular')
    end

    it 'includes exercise catalog in the prompt' do
      prompt = service.send(:build_prompt)

      expect(prompt).to include('EXERCISE CATALOG:')
      expect(prompt).to include('ID: 1, Name: Bench Press')
      expect(prompt).to include('ID: 2, Name: Dumbbell Curl')
    end

    it 'includes formatting instructions' do
      prompt = service.send(:build_prompt)

      expect(prompt).to include('<explicacion>')
      expect(prompt).to include('<json>')
      expect(prompt).to include('routine_exercises_attributes')
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
    it 'correctly extracts explanation and routine' do
      result = service.send(:parse_ai_response, mock_ai_response)

      expect(result[:explanation]).to include('Esta rutina fue diseñada específicamente')
      expect(result[:routine]).to be_a(Hash)
      expect(result[:routine][:days]).to be_an(Array)
    end
  end

  describe '#validate_routine_structure' do
    it 'validates correct routine structure' do
      valid_routine = {
        days: [
          {
            day: 'Monday',
            routine: {
              name: 'Test Routine',
              routine_exercises_attributes: [
                {
                  exercise_id: 1,
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

    it 'raises error for missing days array' do
      invalid_routine = { invalid: 'structure' }

      expect { service.send(:validate_routine_structure, invalid_routine) }.to raise_error(
        AiWorkoutRoutineService::InvalidResponseError,
        /AI response must contain 'days' array/
      )
    end

    it 'raises error for invalid day structure' do
      invalid_routine = {
        days: [
          { invalid: 'day' }
        ]
      }

      expect { service.send(:validate_routine_structure, invalid_routine) }.to raise_error(
        AiWorkoutRoutineService::InvalidResponseError,
        /Day 1 has invalid structure/
      )
    end

    it 'raises error for missing routine exercises' do
      invalid_routine = {
        days: [
          {
            day: 'Monday',
            routine: {
              name: 'Test'
              # Missing routine_exercises_attributes
            }
          }
        ]
      }

      expect { service.send(:validate_routine_structure, invalid_routine) }.to raise_error(
        AiWorkoutRoutineService::InvalidResponseError,
        /Day 1 routine missing required fields/
      )
    end
  end

  describe '#validate_exercise_ids' do
    it 'passes validation for existing exercise IDs' do
      valid_routine = {
        days: [
          {
            routine: {
              routine_exercises_attributes: [
                { exercise_id: 1 },
                { exercise_id: 2 }
              ]
            }
          }
        ]
      }

      expect { service.send(:validate_exercise_ids, valid_routine) }.not_to raise_error
    end

    it 'raises error for non-existent exercise IDs' do
      invalid_routine = {
        days: [
          {
            routine: {
              routine_exercises_attributes: [
                { exercise_id: 999 },
                { exercise_id: 1000 }
              ]
            }
          }
        ]
      }

      expect { service.send(:validate_exercise_ids, invalid_routine) }.to raise_error(
        AiWorkoutRoutineService::InvalidExerciseIdError,
        /Invalid exercise IDs found in AI response: 999, 1000/
      )
    end
  end
end 