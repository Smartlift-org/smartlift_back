require 'rails_helper'

# End-to-end integration tests for AI workout routine endpoint
# Tests the complete flow from request to response with exercise ID assignment
RSpec.describe '/api/v1/ai/workout_routines', type: :request do
  let(:valid_params) do
    {
      age: 30,
      gender: 'male',
      weight: 80,
      height: 175,
      experience_level: 'intermediate',
      preferences: 'Upper body focus',
      frequency_per_week: 3,
      time_per_session: 45,
      goal: 'Build muscle'
    }
  end

  # Create test exercises for integration testing
  before do
    @test_exercises = [
      Exercise.find_or_create_by!(name: 'Push-up') do |ex|
        ex.level = 'beginner'
        ex.instructions = 'Basic push-up exercise'
        ex.primary_muscles = ['chest']
        ex.images = []
      end,
      Exercise.find_or_create_by!(name: 'Bench Press') do |ex|
        ex.level = 'intermediate'
        ex.instructions = 'Barbell bench press'
        ex.primary_muscles = ['chest']
        ex.images = []
      end,
      Exercise.find_or_create_by!(name: 'Pull-up') do |ex|
        ex.level = 'intermediate'
        ex.instructions = 'Pull-up exercise'
        ex.primary_muscles = ['back']
        ex.images = []
      end
    ]
  end

  after do
    # Clean up test exercises
    @test_exercises.each(&:destroy!)
  end

  describe 'POST /api/v1/ai/workout_routines' do
    context 'when AI service returns exercises with names only' do
      let(:mock_ai_response_with_names) do
        {
          "routines": [
            {
              "routine": {
                "name": "Upper Body Strength",
                "description": "Focus on upper body development",
                "difficulty": "intermediate",
                "duration": 45,
                "exercises": [
                  {
                    "name": "Push-up",
                    "sets": 3,
                    "reps": 12,
                    "rest_time": 60,
                    "order": 1
                  },
                  {
                    "name": "Bench Press",
                    "sets": 4,
                    "reps": 8,
                    "rest_time": 120,
                    "order": 2
                  },
                  {
                    "name": "Pull-up",
                    "sets": 3,
                    "reps": 6,
                    "rest_time": 90,
                    "order": 3
                  }
                ]
              }
            }
          ]
        }.to_json
      end

      it 'assigns exercise IDs and returns complete routine data' do
        # Mock the AI client to return exercises with names only
        mock_client = instance_double(AiApiClient)
        allow(AiApiClient).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:create_routine).and_return(mock_ai_response_with_names)

        post '/api/v1/ai/workout_routines', params: valid_params

        expect(response).to have_http_status(:success)
        
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('routines')
        expect(json_response['routines']).to be_an(Array)
        expect(json_response['routines'].length).to eq(1)

        routine = json_response['routines'][0]['routine']
        expect(routine).to have_key('exercises')
        expect(routine['exercises'].length).to eq(3)

        # Verify all exercises have been assigned exercise_id
        routine['exercises'].each_with_index do |exercise, index|
          expect(exercise).to have_key('exercise_id')
          expect(exercise['exercise_id']).to be_present
          expect(exercise['exercise_id']).to be_a(Integer)
          
          expect(exercise).to have_key('name')
          expect(exercise['name']).to be_present
          
          # Verify the exercise_id corresponds to a real exercise
          found_exercise = Exercise.find(exercise['exercise_id'])
          expect(found_exercise).to be_present
          
          # The name should match what was found in the database
          expect(exercise['name']).to eq(found_exercise.name)
        end

        # Verify specific exercise assignments
        push_up = routine['exercises'].find { |ex| ex['name'] == 'Push-up' }
        expect(push_up).to be_present
        expect(push_up['exercise_id']).to eq(@test_exercises[0].id)
        expect(push_up['sets']).to eq(3)
        expect(push_up['reps']).to eq(12)
        expect(push_up['rest_time']).to eq(60)

        bench_press = routine['exercises'].find { |ex| ex['name'] == 'Bench Press' }
        expect(bench_press).to be_present
        expect(bench_press['exercise_id']).to eq(@test_exercises[1].id)

        pull_up = routine['exercises'].find { |ex| ex['name'] == 'Pull-up' }
        expect(pull_up).to be_present
        expect(pull_up['exercise_id']).to eq(@test_exercises[2].id)
      end

      it 'handles partial exercise name matches' do
        # Mock AI response with partial names
        partial_name_response = {
          "routines": [{
            "routine": {
              "name": "Partial Match Test",
              "description": "Testing partial name matching",
              "difficulty": "intermediate",
              "duration": 30,
              "exercises": [
                {
                  "name": "Push",  # Should match "Push-up"
                  "sets": 3,
                  "reps": 10,
                  "order": 1
                },
                {
                  "name": "Bench",  # Should match "Bench Press"
                  "sets": 3,
                  "reps": 8,
                  "order": 2
                }
              ]
            }
          }]
        }.to_json

        mock_client = instance_double(AiApiClient)
        allow(AiApiClient).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:create_routine).and_return(partial_name_response)

        post '/api/v1/ai/workout_routines', params: valid_params

        expect(response).to have_http_status(:success)
        
        json_response = JSON.parse(response.body)
        routine = json_response['routines'][0]['routine']
        exercises = routine['exercises']

        # Should find exercises despite partial names
        expect(exercises.length).to eq(2)
        exercises.each do |exercise|
          expect(exercise['exercise_id']).to be_present
          expect(exercise['name']).to be_present
          # Name should be the full name from the database, not the partial input
          expect(['Push-up', 'Bench Press']).to include(exercise['name'])
        end
      end

      it 'handles case insensitive exercise names' do
        # Mock AI response with various cases
        case_insensitive_response = {
          "routines": [{
            "routine": {
              "name": "Case Test",
              "exercises": [
                { "name": "PUSH-UP", "sets": 3, "reps": 10, "order": 1 },
                { "name": "bench press", "sets": 3, "reps": 8, "order": 2 },
                { "name": "Pull-Up", "sets": 3, "reps": 6, "order": 3 }
              ]
            }
          }]
        }.to_json

        mock_client = instance_double(AiApiClient)
        allow(AiApiClient).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:create_routine).and_return(case_insensitive_response)

        post '/api/v1/ai/workout_routines', params: valid_params

        expect(response).to have_http_status(:success)
        
        json_response = JSON.parse(response.body)
        exercises = json_response['routines'][0]['routine']['exercises']

        # All exercises should be found despite case differences
        expect(exercises.length).to eq(3)
        exercises.each do |exercise|
          expect(exercise['exercise_id']).to be_present
          # Names should be standardized to database values
          expect(['Push-up', 'Bench Press', 'Pull-up']).to include(exercise['name'])
        end
      end
    end

    context 'when AI service returns non-existent exercise names' do
      let(:invalid_exercise_response) do
        {
          "routines": [{
            "routine": {
              "name": "Invalid Exercise Test",
              "exercises": [
                { "name": "NonexistentExercise123", "sets": 3, "reps": 10, "order": 1 }
              ]
            }
          }]
        }.to_json
      end

      it 'returns error when exercise cannot be found' do
        mock_client = instance_double(AiApiClient)
        allow(AiApiClient).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:create_routine).and_return(invalid_exercise_response)

        post '/api/v1/ai/workout_routines', params: valid_params

        expect(response).to have_http_status(:unprocessable_entity)
        
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('error')
        expect(json_response['error']).to include('NonexistentExercise123')
      end
    end

    context 'with multiple routines containing various exercise scenarios' do
      let(:complex_ai_response) do
        {
          "routines": [
            {
              "routine": {
                "name": "Day 1: Upper Body",
                "exercises": [
                  { "name": "Push-up", "sets": 3, "reps": 12, "order": 1 },
                  { "name": "BENCH PRESS", "sets": 4, "reps": 8, "order": 2 }
                ]
              }
            },
            {
              "routine": {
                "name": "Day 2: Pull Focus", 
                "exercises": [
                  { "name": "pull-up", "sets": 3, "reps": 6, "order": 1 },
                  { "name": "Pull", "sets": 3, "reps": 8, "order": 2 }
                ]
              }
            }
          ]
        }.to_json
      end

      it 'processes multiple routines with mixed case and partial names' do
        mock_client = instance_double(AiApiClient)
        allow(AiApiClient).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:create_routine).and_return(complex_ai_response)

        post '/api/v1/ai/workout_routines', params: valid_params

        expect(response).to have_http_status(:success)
        
        json_response = JSON.parse(response.body)
        expect(json_response['routines'].length).to eq(2)

        # Check first routine
        day1_exercises = json_response['routines'][0]['routine']['exercises']
        expect(day1_exercises.length).to eq(2)
        day1_exercises.each do |exercise|
          expect(exercise['exercise_id']).to be_present
          expect(['Push-up', 'Bench Press']).to include(exercise['name'])
        end

        # Check second routine
        day2_exercises = json_response['routines'][1]['routine']['exercises']
        expect(day2_exercises.length).to eq(2)
        day2_exercises.each do |exercise|
          expect(exercise['exercise_id']).to be_present
          expect(exercise['name']).to eq('Pull-up')  # Both should resolve to Pull-up
        end
      end
    end

    context 'performance testing with realistic AI response size' do
      let(:large_routine_response) do
        exercises = [
          'Push-up', 'Bench Press', 'Pull-up', 'Shoulder Press', 'Row',
          'Squat', 'Lunge', 'Deadlift', 'Curl', 'Extension',
          'Press', 'Fly', 'Raise', 'Dip', 'Plank'
        ].map.with_index do |name, index|
          {
            "name": name,
            "sets": 3,
            "reps": 10,
            "rest_time": 60,
            "order": index + 1
          }
        end

        {
          "routines": [{
            "routine": {
              "name": "Large Routine Performance Test",
              "description": "Testing performance with 15 exercises",
              "difficulty": "intermediate",
              "duration": 60,
              "exercises": exercises
            }
          }]
        }.to_json
      end

      it 'processes large routine within acceptable time limits' do
        mock_client = instance_double(AiApiClient)
        allow(AiApiClient).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:create_routine).and_return(large_routine_response)

        start_time = Time.now
        post '/api/v1/ai/workout_routines', params: valid_params
        end_time = Time.now

        response_time_ms = ((end_time - start_time) * 1000).round(2)

        # Should respond within reasonable time (including network overhead)
        expect(response_time_ms).to be < 2000  # 2 seconds max for full request

        if response.successful?
          json_response = JSON.parse(response.body)
          exercises = json_response['routines'][0]['routine']['exercises']
          
          # Should have processed all or most exercises
          successful_assignments = exercises.count { |ex| ex['exercise_id'].present? }
          success_rate = successful_assignments.to_f / exercises.length
          
          expect(success_rate).to be > 0.5  # At least 50% success rate
          
          puts "Performance test results:"
          puts "- Response time: #{response_time_ms}ms"
          puts "- Exercise assignments: #{successful_assignments}/#{exercises.length}"
          puts "- Success rate: #{(success_rate * 100).round(1)}%"
        end
      end
    end
  end

  describe 'error handling and edge cases' do
    it 'handles AI service timeout gracefully' do
      mock_client = instance_double(AiApiClient)
      allow(AiApiClient).to receive(:new).and_return(mock_client)
      allow(mock_client).to receive(:create_routine)
        .and_raise(AiApiClient::TimeoutError, 'Service timeout')

      post '/api/v1/ai/workout_routines', params: valid_params

      expect(response).to have_http_status(:service_unavailable)
      
      json_response = JSON.parse(response.body)
      expect(json_response).to have_key('error')
      expect(json_response['error']).to include('timeout')
    end

    it 'handles AI service network errors gracefully' do
      mock_client = instance_double(AiApiClient)
      allow(AiApiClient).to receive(:new).and_return(mock_client)
      allow(mock_client).to receive(:create_routine)
        .and_raise(AiApiClient::NetworkError, 'Network error')

      post '/api/v1/ai/workout_routines', params: valid_params

      expect(response).to have_http_status(:service_unavailable)
    end

    it 'validates required parameters' do
      post '/api/v1/ai/workout_routines', params: {}

      expect(response).to have_http_status(:bad_request)
    end
  end
end