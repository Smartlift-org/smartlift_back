require 'json'

class AiWorkoutRoutineService
  class InvalidExerciseIdError < StandardError; end
  class InvalidResponseError < StandardError; end
  class ServiceUnavailableError < StandardError; end

  def initialize(params)
    @params = params
    @ai_client = AiApiClient.new
  end

  def generate_routine
    begin
      # Build the prompt for the AI
      prompt = build_prompt
      
      # Send to AI service
      response = @ai_client.generate_routine(prompt)
      
      # Parse and validate the response
      parsed_response = parse_ai_response(response)
      
      # Validate exercise IDs
      validate_exercise_ids(parsed_response[:routines])
      
      # Return the structured response
      {
        routines: parsed_response[:routines]
      }
      
    rescue AiApiClient::TimeoutError => e
      raise ServiceUnavailableError, "AI service timeout: #{e.message}"
    rescue AiApiClient::NetworkError => e
      raise ServiceUnavailableError, "AI service network error: #{e.message}"
    rescue AiApiClient::ServiceError => e
      raise ServiceUnavailableError, "AI service error: #{e.message}"
    rescue InvalidExerciseIdError => e
      raise e
    rescue StandardError => e
      Rails.logger.error "AI Workout Routine Service Error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise InvalidResponseError, "Failed to generate routine: #{e.message}"
    end
  end

  private

  def build_prompt

    # Build the prompt according to the new specification
    prompt = <<~PROMPT

      User fitness data:
      - Age: #{@params[:age]}
      - Gender: #{@params[:gender]}
      - Weight: #{@params[:weight]}kg
      - Height: #{@params[:height]}cm
      - Experience level: #{@params[:experience_level]} (beginner, intermediate, or expert)
      - Preferences: #{@params[:preferences] || 'None specified'}
      - Training frequency: #{@params[:frequency_per_week]} sessions per week
      - Time per session: #{@params[:time_per_session]} minutes
      - Training goal: #{@params[:goal]}

    PROMPT

    Rails.logger.info "Generated AI prompt for user profile: #{@params[:age]}yo #{@params[:gender]}, #{@params[:experience_level]} level"
    Rails.logger.debug "Full prompt: #{prompt}" if Rails.env.development?
    
    prompt
  end

  def build_exercise_catalog
    # Get available exercises (using all exercises with reasonable limit)
    available_exercises = Exercise.limit(100) # Limit to avoid too long prompts
                                 .select(:id, :name, :primary_muscles, :level)
    
    catalog = available_exercises.map do |exercise|
      primary_muscles = exercise.primary_muscles.is_a?(Array) ? exercise.primary_muscles.join(', ') : exercise.primary_muscles
      "ID: #{exercise.id}, Name: #{exercise.name}, Level: #{exercise.level}, Primary Muscles: #{primary_muscles}"
    end.join("\n")
    
    
    Rails.logger.info "Built exercise catalog with #{available_exercises.count} exercises"
    catalog
  end

  def parse_ai_response(response)
    Rails.logger.debug "Raw AI response: #{response.inspect}" if Rails.env.development?
    
    # Clean the response (remove any potential whitespace or extra characters)
    json_content = response.strip
    
    # Parse TheAnswer.ai response format
    begin
      ai_response = JSON.parse(json_content, symbolize_names: true)
    rescue JSON::ParserError => e
      Rails.logger.error "JSON parsing failed. Content: #{json_content[0..500]}..."
      raise InvalidResponseError, "Invalid JSON in AI response: #{e.message}. Response must be valid JSON only."
    end
    
    # Check if response has the nested 'json' field (TheAnswer.ai format) or direct routines
    routine_data = if ai_response[:json].present?
      ai_response[:json]  # TheAnswer.ai nested format
    elsif ai_response[:routines].present?
      ai_response  # Direct routines format
    else
      Rails.logger.error "AI response missing 'json' or 'routines' field: #{ai_response}"
      raise InvalidResponseError, "AI response must contain 'json' or 'routines' field"
    end
    
    # Validate the JSON structure
    validate_routine_structure(routine_data)
    
    {
      routines: routine_data[:routines]
    }
  end

  def validate_routine_structure(routine_data)
    # Check for required top-level structure
    unless routine_data.is_a?(Hash) && routine_data[:routines].is_a?(Array)
      raise InvalidResponseError, "AI response must contain 'routines' array"
    end
    
    # Validate each routine
    routine_data[:routines].each_with_index do |routine_item, index|
      unless routine_item.is_a?(Hash) && routine_item[:routine].is_a?(Hash)
        raise InvalidResponseError, "Routine #{index + 1} has invalid structure"
      end
      
      routine = routine_item[:routine]
      unless routine[:name].present? && routine[:routine_exercises_attributes].is_a?(Array)
        raise InvalidResponseError, "Routine #{index + 1} missing required fields"
      end
      
      # Validate exercises
      routine[:routine_exercises_attributes].each_with_index do |exercise, ex_index|
        unless exercise[:exercise_id].present? && 
               exercise[:sets].is_a?(Integer) && 
               exercise[:reps].is_a?(Integer) && 
               exercise[:rest_time].is_a?(Integer) &&
               exercise[:order].is_a?(Integer)
          raise InvalidResponseError, "Routine #{index + 1}, exercise #{ex_index + 1} has invalid structure"
        end
      end
    end
  end

  def validate_exercise_ids(routines_array)
    # Collect all exercise IDs from the routines
    exercise_ids = []
    routines_array.each do |routine_item|
      routine_item[:routine][:routine_exercises_attributes].each do |exercise|
        exercise_ids << exercise[:exercise_id]
      end
    end
    
    # Check if all exercise IDs exist in the database
    existing_ids = Exercise.where(id: exercise_ids).pluck(:id)
    missing_ids = exercise_ids - existing_ids
    
    if missing_ids.any?
      raise InvalidExerciseIdError, "Invalid exercise IDs found in AI response: #{missing_ids.join(', ')}"
    end
    
    Rails.logger.info "Validated #{exercise_ids.length} exercise IDs successfully"
  end
end 