#!/usr/bin/env ruby
# AI Workout Routine Generation Example
# This script demonstrates how to use the SmartLift API's AI-powered workout routine generation

require 'net/http'
require 'json'
require 'uri'

class SmartLiftAiExample
  def initialize(base_url = 'http://localhost:3000')
    @base_url = base_url
  end

  def generate_workout_routine
    # Example user profile for AI routine generation
    user_profile = {
      age: 28,
      gender: 'male',
      weight: 75,
      height: 178,
      experience_level: 'intermediate',
      equipment: [ 'barbell', 'dumbbell', 'cable' ],
      preferences: 'Prefiero ejercicios compuestos, no me gusta el cardio',
      frequency_per_week: 4,
      time_per_session: 60,
      goal: 'ganar masa muscular y fuerza'
    }

    # Make API request
    uri = URI("#{@base_url}/api/v1/ai/workout_routines")
    http = Net::HTTP.new(uri.host, uri.port)

    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    # Add authentication header if required
    # request['Authorization'] = 'Bearer your_jwt_token_here'

    request.body = user_profile.to_json

    puts "🤖 Generating AI workout routine..."
    puts "📤 Request URL: #{uri}"
    puts "📤 User Profile:"
    puts JSON.pretty_generate(user_profile)
    puts "\n" + "="*50 + "\n"

    begin
      response = http.request(request)

      case response.code.to_i
      when 200
        result = JSON.parse(response.body)
        display_success_response(result)
      when 400
        error = JSON.parse(response.body)
        display_validation_error(error)
      when 503
        error = JSON.parse(response.body)
        display_service_error(error)
      else
        puts "❌ Unexpected response code: #{response.code}"
        puts response.body
      end

    rescue Errno::ECONNREFUSED
      puts "❌ Connection refused. Make sure the SmartLift API server is running on #{@base_url}"
    rescue JSON::ParserError => e
      puts "❌ Invalid JSON response: #{e.message}"
    rescue StandardError => e
      puts "❌ Unexpected error: #{e.message}"
    end
  end

  private

  def display_success_response(result)
    puts "✅ AI Workout Routine Generated Successfully!"
    puts "\n📝 Explanation (in Spanish):"
    puts "-" * 40
    puts result['data']['explanation']

    puts "\n🏋️ Weekly Routine:"
    puts "-" * 40

    result['data']['routine']['days'].each_with_index do |day_data, index|
      day = day_data['day']
      routine = day_data['routine']

      puts "\n📅 Day #{index + 1}: #{day}"
      puts "   🎯 Routine: #{routine['name']}"
      puts "   📋 Description: #{routine['description']}"
      puts "   ⚡ Difficulty: #{routine['difficulty']}"
      puts "   ⏱️  Duration: #{routine['duration']} minutes"

      puts "   💪 Exercises:"
      routine['routine_exercises_attributes'].each do |exercise|
        puts "      #{exercise['order']}. Exercise ID: #{exercise['exercise_id']}"
        puts "         Sets: #{exercise['sets']}, Reps: #{exercise['reps']}"
        puts "         Rest: #{exercise['rest_time']} seconds"
      end
    end

    puts "\n⏰ Generated at: #{result['data']['generated_at']}"
  end

  def display_validation_error(error)
    puts "❌ Validation Error:"
    puts "Error: #{error['error']}"

    if error['details']
      puts "\nValidation Details:"
      error['details'].each do |field, messages|
        puts "  #{field}: #{messages.join(', ')}"
      end
    end
  end

  def display_service_error(error)
    puts "❌ Service Error:"
    puts "Error: #{error['error']}"
    puts "Details: #{error['details']}"
    puts "\n💡 This usually means the AI service is temporarily unavailable."
    puts "   Please try again in a few minutes."
  end

  def demonstrate_validation_errors
    puts "\n" + "="*60
    puts "🧪 Demonstrating Validation Errors"
    puts "="*60

    # Example with invalid age
    invalid_profile = {
      age: 12, # Too young
      gender: 'invalid_gender', # Invalid gender
      weight: 0, # Invalid weight
      height: 50, # Too short
      experience_level: 'expert_level', # Invalid level
      equipment: [], # Empty equipment
      frequency_per_week: 8, # Too many days
      time_per_session: 10, # Too short
      goal: 'xy' # Too short
    }

    uri = URI("#{@base_url}/api/v1/ai/workout_routines")
    http = Net::HTTP.new(uri.host, uri.port)

    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request.body = invalid_profile.to_json

    puts "📤 Sending invalid profile to demonstrate validation..."

    begin
      response = http.request(request)
      if response.code.to_i == 400
        error = JSON.parse(response.body)
        display_validation_error(error)
      else
        puts "Unexpected response: #{response.code}"
      end
    rescue StandardError => e
      puts "Error: #{e.message}"
    end
  end
end

# Run the example
if __FILE__ == $0
  puts "🚀 SmartLift AI Workout Routine Generation Example"
  puts "="*60

  example = SmartLiftAiExample.new

  # Generate a workout routine
  example.generate_workout_routine

  # Demonstrate validation errors
  example.demonstrate_validation_errors

  puts "\n" + "="*60
  puts "✨ Example completed!"
  puts "💡 For more information, check the API documentation at docs/API_DOCUMENTATION.md"
end
