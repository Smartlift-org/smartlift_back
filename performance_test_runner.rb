#!/usr/bin/env ruby

# Performance Test Runner for Exercise ID Assignment System
# Run this with: docker-compose exec web rails runner "load 'performance_test_runner.rb'"

puts "=== EXERCISE ID ASSIGNMENT SYSTEM - COMPREHENSIVE TESTING ==="
puts "Started at: #{Time.now}"
puts

class ExerciseSearchTester
  attr_reader :service, :results, :errors

  def initialize
    @service = AiWorkoutRoutineService.new({})
    @results = {
      search_tests: [],
      performance_data: {},
      integration_tests: []
    }
    @errors = []
  end

  def run_all_tests
    puts "Database contains #{Exercise.count} exercises"
    puts "Testing new exercise search algorithm..."
    puts
    
    test_search_levels
    test_performance_scenarios
    test_ai_integration
    test_edge_cases
    
    generate_final_report
  end

  private

  def test_search_levels
    puts "=== SEARCH LEVEL TESTING ==="
    
    test_cases = [
      # Exact matches
      { name: 'Push-up', expected_strategy: 'exact', description: 'Common exercise exact match' },
      { name: 'Bench Press', expected_strategy: 'exact', description: 'Two-word exact match' },
      { name: 'SQUAT', expected_strategy: 'exact', description: 'Case insensitive exact' },
      
      # Partial matches
      { name: 'Bench', expected_strategy: 'partial', description: 'Partial name match' },
      { name: 'Press', expected_strategy: 'partial', description: 'Common suffix match' },
      { name: 'Curl', expected_strategy: 'partial', description: 'Exercise type match' },
      
      # Word-based matches
      { name: 'Dumbbell Row', expected_strategy: 'word', description: 'Multi-word exercise' },
      { name: 'Barbell Squat', expected_strategy: 'word', description: 'Equipment + exercise' },
      { name: 'Cable Fly', expected_strategy: 'word', description: 'Equipment variation' },
      
      # Similarity/fuzzy matches
      { name: 'Benchpress', expected_strategy: 'similarity', description: 'One word vs two' },
      { name: 'Pull Up', expected_strategy: 'similarity', description: 'Space vs hyphen' },
      { name: 'Dumbell Curl', expected_strategy: 'similarity', description: 'Typo in equipment' },
      
      # Expected failures
      { name: 'NonexistentExercise123', expected_strategy: 'error', description: 'Non-existent exercise' },
      { name: '', expected_strategy: 'error', description: 'Empty string' },
    ]

    test_cases.each_with_index do |test_case, index|
      print "#{index + 1}/#{test_cases.length}: #{test_case[:description]}... "
      
      start_time = Time.now
      begin
        result = @service.send(:find_exercise_by_name, test_case[:name])
        end_time = Time.now
        
        time_ms = ((end_time - start_time) * 1000).round(3)
        
        if test_case[:expected_strategy] == 'error'
          puts "✗ Expected error but found: #{result.name}"
          @errors << "Expected error for '#{test_case[:name]}' but found '#{result.name}'"
        else
          puts "✓ Found: '#{result.name}' (ID: #{result.id}) [#{time_ms}ms]"
          @results[:search_tests] << {
            input: test_case[:name],
            found_name: result.name,
            found_id: result.id,
            time_ms: time_ms,
            expected_strategy: test_case[:expected_strategy]
          }
        end
        
      rescue AiWorkoutRoutineService::InvalidResponseError => e
        end_time = Time.now
        time_ms = ((end_time - start_time) * 1000).round(3)
        
        if test_case[:expected_strategy] == 'error'
          puts "✓ Expected error: #{e.message} [#{time_ms}ms]"
        else
          puts "✗ Unexpected error: #{e.message}"
          @errors << "Unexpected error for '#{test_case[:name]}': #{e.message}"
        end
      rescue => e
        puts "✗ System error: #{e.message}"
        @errors << "System error for '#{test_case[:name]}': #{e.message}"
      end
    end
    
    puts
  end

  def test_performance_scenarios
    puts "=== PERFORMANCE TESTING ==="
    
    # Test with realistic exercise names from AI responses
    realistic_names = [
      'Push-up', 'Bench Press', 'Squat', 'Deadlift', 'Pull-up',
      'Overhead Press', 'Barbell Row', 'Dumbbell Curl', 'Tricep Dip',
      'Plank', 'Burpee', 'Lunge', 'Leg Press', 'Lat Pulldown', 'Chest Fly'
    ]
    
    # Single exercise performance
    puts "Single exercise search performance:"
    single_times = []
    realistic_names.each do |name|
      start_time = Time.now
      begin
        @service.send(:find_exercise_by_name, name)
        end_time = Time.now
        time_ms = ((end_time - start_time) * 1000).round(3)
        single_times << time_ms
        print "."
      rescue
        print "E"
      end
    end
    puts
    
    if single_times.any?
      avg_time = single_times.sum / single_times.length
      max_time = single_times.max
      min_time = single_times.min
      
      puts "- Average search time: #{avg_time.round(2)}ms"
      puts "- Fastest search: #{min_time}ms"
      puts "- Slowest search: #{max_time}ms"
      puts "- Success rate: #{single_times.length}/#{realistic_names.length}"
      
      @results[:performance_data][:single_search] = {
        average_ms: avg_time,
        max_ms: max_time,
        min_ms: min_time,
        success_rate: single_times.length.to_f / realistic_names.length
      }
    end
    
    # Batch processing performance (simulating AI response)
    puts "\nBatch processing performance (15 exercises):"
    batch_start = Time.now
    batch_exercises = realistic_names.map.with_index do |name, i|
      { name: name, sets: 3, reps: 10, order: i + 1 }
    end
    
    mock_response = {
      routines: [
        {
          routine: {
            name: 'Performance Test Routine',
            description: 'Testing batch exercise processing',
            difficulty: 'intermediate',
            duration: 45,
            exercises: batch_exercises
          }
        }
      ]
    }
    
    begin
      result = @service.send(:assign_exercise_ids_by_name, mock_response)
      batch_end = Time.now
      
      batch_time_ms = ((batch_end - batch_start) * 1000).round(2)
      avg_per_exercise = batch_time_ms / batch_exercises.length
      
      exercises = result[:routines][0][:routine][:exercises]
      successful_assignments = exercises.count { |ex| ex[:exercise_id].present? }
      
      puts "- Total batch time: #{batch_time_ms}ms"
      puts "- Average per exercise: #{avg_per_exercise.round(2)}ms"
      puts "- Successful assignments: #{successful_assignments}/#{batch_exercises.length}"
      puts "- Target met (<500ms): #{batch_time_ms < 500 ? '✓' : '✗'}"
      
      @results[:performance_data][:batch_processing] = {
        total_time_ms: batch_time_ms,
        per_exercise_ms: avg_per_exercise,
        success_rate: successful_assignments.to_f / batch_exercises.length,
        target_met: batch_time_ms < 500
      }
      
    rescue => e
      puts "✗ Batch processing failed: #{e.message}"
      @errors << "Batch processing error: #{e.message}"
    end
    
    puts
  end

  def test_ai_integration
    puts "=== AI INTEGRATION TESTING ==="
    
    # Test with realistic AI agent responses
    ai_scenarios = [
      {
        name: 'Upper Body Routine',
        exercises: [
          { name: 'Push-up', sets: 3, reps: 12 },
          { name: 'Bench Press', sets: 4, reps: 8 },
          { name: 'Pull Up', sets: 3, reps: 6 },
          { name: 'Overhead Press', sets: 3, reps: 10 },
          { name: 'Barbell Row', sets: 3, reps: 10 }
        ]
      },
      {
        name: 'Lower Body Routine',
        exercises: [
          { name: 'Squat', sets: 4, reps: 8 },
          { name: 'Deadlift', sets: 3, reps: 5 },
          { name: 'Lunge', sets: 3, reps: 12 },
          { name: 'Leg Press', sets: 3, reps: 15 },
          { name: 'Calf Raise', sets: 4, reps: 20 }
        ]
      },
      {
        name: 'Mixed Case and Typos',
        exercises: [
          { name: 'PUSH-UP', sets: 3, reps: 10 },
          { name: 'bench press', sets: 3, reps: 8 },
          { name: 'Benchpress', sets: 3, reps: 8 },  # One word
          { name: 'Pull Up', sets: 3, reps: 6 },     # Space instead of hyphen
          { name: 'Dumbell Curl', sets: 3, reps: 12 } # Typo in 'Dumbbell'
        ]
      }
    ]
    
    ai_scenarios.each_with_index do |scenario, index|
      puts "Scenario #{index + 1}: #{scenario[:name]}"
      
      mock_response = {
        routines: [
          {
            routine: {
              name: scenario[:name],
              description: 'AI integration test routine',
              difficulty: 'intermediate',
              duration: 45,
              exercises: scenario[:exercises].map.with_index do |ex, i|
                ex.merge(rest_time: 60, order: i + 1)
              end
            }
          }
        ]
      }
      
      start_time = Time.now
      begin
        result = @service.send(:assign_exercise_ids_by_name, mock_response)
        end_time = Time.now
        
        processing_time = ((end_time - start_time) * 1000).round(2)
        exercises = result[:routines][0][:routine][:exercises]
        successful_assignments = exercises.count { |ex| ex[:exercise_id].present? }
        
        puts "  - Processing time: #{processing_time}ms"
        puts "  - Successful assignments: #{successful_assignments}/#{exercises.length}"
        puts "  - Success rate: #{(successful_assignments.to_f / exercises.length * 100).round(1)}%"
        
        # Show individual results
        exercises.each_with_index do |exercise, ex_index|
          original_name = scenario[:exercises][ex_index][:name]
          if exercise[:exercise_id].present?
            puts "    ✓ '#{original_name}' → '#{exercise[:name]}' (ID: #{exercise[:exercise_id]})"
          else
            puts "    ✗ '#{original_name}' → NOT FOUND"
          end
        end
        
        @results[:integration_tests] << {
          scenario: scenario[:name],
          processing_time_ms: processing_time,
          success_rate: successful_assignments.to_f / exercises.length,
          details: exercises.map.with_index do |ex, i|
            {
              original: scenario[:exercises][i][:name],
              found: ex[:name],
              exercise_id: ex[:exercise_id]
            }
          end
        }
        
      rescue => e
        puts "  ✗ Failed: #{e.message}"
        @errors << "AI integration scenario '#{scenario[:name]}' failed: #{e.message}"
      end
      
      puts
    end
  end

  def test_edge_cases
    puts "=== EDGE CASE TESTING ==="
    
    edge_cases = [
      { name: nil, description: 'Nil input' },
      { name: '', description: 'Empty string' },
      { name: '   ', description: 'Whitespace only' },
      { name: 'A' * 100, description: 'Very long name' },
      { name: '!@#$%^&*()', description: 'Special characters only' },
      { name: '123456', description: 'Numbers only' },
      { name: 'Exercise With Multiple    Spaces', description: 'Multiple spaces' },
      { name: 'ExerciseWithNoSpaces', description: 'No spaces compound' }
    ]
    
    edge_cases.each do |test_case|
      print "Testing #{test_case[:description]}... "
      
      begin
        result = @service.send(:find_exercise_by_name, test_case[:name])
        if result
          puts "✓ Found: #{result.name}"
        else
          puts "✓ Returned nil (expected for invalid input)"
        end
      rescue AiWorkoutRoutineService::InvalidResponseError
        puts "✓ Properly raised InvalidResponseError"
      rescue => e
        puts "✗ Unexpected error: #{e.message}"
        @errors << "Edge case '#{test_case[:description]}' failed: #{e.message}"
      end
    end
    
    puts
  end

  def generate_final_report
    puts "=== FINAL PERFORMANCE & ACCURACY REPORT ==="
    puts "Generated at: #{Time.now}"
    puts
    
    # Search performance summary
    if @results[:performance_data][:single_search]
      perf = @results[:performance_data][:single_search]
      puts "SEARCH PERFORMANCE:"
      puts "- Average search time: #{perf[:average_ms].round(2)}ms"
      puts "- Max search time: #{perf[:max_ms]}ms"
      puts "- Min search time: #{perf[:min_ms]}ms"
      puts "- Success rate: #{(perf[:success_rate] * 100).round(1)}%"
      puts
    end
    
    # Batch processing performance
    if @results[:performance_data][:batch_processing]
      batch = @results[:performance_data][:batch_processing]
      puts "BATCH PROCESSING PERFORMANCE:"
      puts "- Total time for 15 exercises: #{batch[:total_time_ms]}ms"
      puts "- Average per exercise: #{batch[:per_exercise_ms].round(2)}ms"
      puts "- Success rate: #{(batch[:success_rate] * 100).round(1)}%"
      puts "- Met <500ms target: #{batch[:target_met] ? 'YES' : 'NO'}"
      puts
    end
    
    # Integration test summary
    if @results[:integration_tests].any?
      puts "AI INTEGRATION RESULTS:"
      total_scenarios = @results[:integration_tests].length
      successful_scenarios = @results[:integration_tests].count { |t| t[:success_rate] >= 0.8 }
      avg_success_rate = @results[:integration_tests].map { |t| t[:success_rate] }.sum / total_scenarios
      
      puts "- Total scenarios tested: #{total_scenarios}"
      puts "- Scenarios with >80% success: #{successful_scenarios}"
      puts "- Average success rate: #{(avg_success_rate * 100).round(1)}%"
      puts
    end
    
    # Search strategy effectiveness
    if @results[:search_tests].any?
      puts "SEARCH STRATEGY ANALYSIS:"
      by_time = @results[:search_tests].group_by { |t| t[:time_ms] < 10 }
      fast_searches = by_time[true]&.length || 0
      total_searches = @results[:search_tests].length
      
      puts "- Total successful searches: #{total_searches}"
      puts "- Searches under 10ms: #{fast_searches} (#{(fast_searches.to_f / total_searches * 100).round(1)}%)"
      
      avg_time = @results[:search_tests].map { |t| t[:time_ms] }.sum / total_searches
      puts "- Average successful search time: #{avg_time.round(2)}ms"
      puts
    end
    
    # Error summary
    if @errors.any?
      puts "ERRORS ENCOUNTERED:"
      @errors.each_with_index do |error, index|
        puts "#{index + 1}. #{error}"
      end
      puts
    end
    
    # Recommendations
    puts "RECOMMENDATIONS:"
    
    if @results[:performance_data][:batch_processing]&.dig(:target_met)
      puts "✓ Performance target met - system ready for production load"
    else
      puts "⚠ Performance target not met - consider optimization"
    end
    
    if @results[:integration_tests].any? && @results[:integration_tests].all? { |t| t[:success_rate] >= 0.8 }
      puts "✓ High accuracy across AI integration scenarios"
    else
      puts "⚠ Some accuracy issues detected - review search strategies"
    end
    
    if @errors.length <= 2
      puts "✓ Low error rate - system appears stable"
    else
      puts "⚠ High error rate detected - requires investigation"
    end
    
    puts
    puts "=== TEST COMPLETED ==="
    puts "Total errors: #{@errors.length}"
    puts "Overall status: #{@errors.length <= 2 && @results[:performance_data][:batch_processing]&.dig(:target_met) ? 'PASS' : 'NEEDS ATTENTION'}"
  end
end

# Run the comprehensive test suite
begin
  tester = ExerciseSearchTester.new
  tester.run_all_tests
rescue => e
  puts "CRITICAL ERROR: #{e.message}"
  puts e.backtrace.first(10)
  puts
  puts "Please ensure:"
  puts "1. Database is connected and populated"
  puts "2. Exercise model has required data"
  puts "3. AiWorkoutRoutineService is properly loaded"
end