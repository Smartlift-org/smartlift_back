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
      validate_exercise_ids(parsed_response[:routine])
      
      # Return the structured response
      {
        routine: parsed_response[:routine]
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
    # Build the exercise catalog based on user's available equipment
    exercise_catalog = build_exercise_catalog

    # Build the prompt according to the new specification
    prompt = <<~PROMPT

      User Profile:
      - Age: #{@params[:age]} years
      - Gender: #{@params[:gender]}
      - Weight: #{@params[:weight]} kg
      - Height: #{@params[:height]} cm
      - Experience level: #{@params[:experience_level]}
      - Goal: #{@params[:goal]}
      - Weekly frequency: #{@params[:frequency_per_week]} sessions per week
      - Duration per session: #{@params[:time_per_session]} minutes
      - Available equipment: #{@params[:equipment].join(', ')}
      - Preferences: #{@params[:preferences] || 'No specific preferences'}

    PROMPT

    Rails.logger.info "Generated AI prompt for user profile: #{@params[:age]}yo #{@params[:gender]}, #{@params[:experience_level]} level"
    Rails.logger.debug "Full prompt: #{prompt}" if Rails.env.development?
    
    prompt
  end

  def build_exercise_catalog
    # Get exercises that match the user's available equipment
    available_exercises = Exercise.where(equipment: @params[:equipment])
                                 .or(Exercise.where(equipment: 'body only'))
                                 .limit(200) # Increased limit to provide more variety
                                 .select(:id, :name, :equipment, :category, :primary_muscles, :level)
                                 .order(:id)
    
    if available_exercises.count < 10
      # If we have very few exercises, include more bodyweight exercises
      additional_exercises = Exercise.where(equipment: 'body only')
                                    .where.not(id: available_exercises.pluck(:id))
                                    .limit(50)
                                    .select(:id, :name, :equipment, :category, :primary_muscles, :level)
      
      available_exercises = available_exercises + additional_exercises.to_a
    end
    
    # Build simple format catalog for the AI prompt
    catalog = available_exercises.map do |exercise|
      "ID: #{exercise.id}, Nombre: #{exercise.name}"
    end.join("\n")
    
    if catalog.blank?
      # Final fallback to any bodyweight exercises
      fallback_exercises = Exercise.where(equipment: 'body only')
                                  .limit(50)
                                  .select(:id, :name, :equipment, :category, :primary_muscles, :level)
      
      catalog = fallback_exercises.map do |exercise|
        "ID: #{exercise.id}, Nombre: #{exercise.name}"
      end.join("\n")
    end
    
    Rails.logger.info "Built exercise catalog with #{available_exercises.count} exercises for equipment: #{@params[:equipment].join(', ')}"
    Rails.logger.debug "Exercise catalog sample: #{catalog.split("\n").first(5).join(", ")}" if Rails.env.development?
    catalog
  end

  def generate_routine_templates
    templates = []
    
    (2..@params[:frequency_per_week]).each do |day|
      templates << ",
          {
            \"routine\": {
              \"day\": #{day},
              \"name\": \"Rutina de #{@params[:goal].downcase} - Día #{day}\",
              \"description\": \"Rutina enfocada en #{@params[:goal].downcase} para nivel #{@params[:experience_level]}\",
              \"difficulty\": \"#{@params[:experience_level]}\",
              \"duration\": #{@params[:time_per_session]},
              \"routine_exercises_attributes\": [
                {
                  \"exercise_id\": #{day + 5},
                  \"name\": \"Ejercicio #{day}\",
                  \"sets\": 3,
                  \"reps\": 10,
                  \"rest_time\": 60,
                  \"order\": 1
                }
              ]
            }
          }"
    end
    
    templates.join
  end

  def generate_weekly_distribution_example
    case @params[:frequency_per_week]
    when 1
      "- Rutina 1: Entrenamiento de cuerpo completo"
    when 2
      "- Rutina 1: Tren superior (pecho, espalda, hombros, brazos)\n      - Rutina 2: Tren inferior (piernas, glúteos, core)"
    when 3
      "- Rutina 1: Pecho, tríceps y hombros\n      - Rutina 2: Espalda, bíceps y core\n      - Rutina 3: Piernas y glúteos"
    when 4
      "- Rutina 1: Pecho y tríceps\n      - Rutina 2: Espalda y bíceps\n      - Rutina 3: Piernas y glúteos\n      - Rutina 4: Hombros y core"
    when 5
      "- Rutina 1: Pecho\n      - Rutina 2: Espalda\n      - Rutina 3: Piernas\n      - Rutina 4: Hombros y brazos\n      - Rutina 5: Core y cardio"
    when 6
      "- Rutina 1: Pecho y tríceps\n      - Rutina 2: Espalda y bíceps\n      - Rutina 3: Piernas\n      - Rutina 4: Hombros\n      - Rutina 5: Core\n      - Rutina 6: Cardio y flexibilidad"
    when 7
      "- Rutina 1: Pecho\n      - Rutina 2: Espalda\n      - Rutina 3: Piernas\n      - Rutina 4: Hombros\n      - Rutina 5: Brazos\n      - Rutina 6: Core\n      - Rutina 7: Cardio y recuperación"
    else
      "- Rutina 1: Entrenamiento general"
    end
  end

  def parse_ai_response(response)
    Rails.logger.debug "Raw AI response: #{response.inspect}" if Rails.env.development?
    
    # Clean the response (remove any potential whitespace or extra characters)
    json_content = response.strip
    
    # Parse the JSON directly since we expect only JSON
    begin
      parsed_response = JSON.parse(json_content, symbolize_names: true)
    rescue JSON::ParserError => e
      Rails.logger.error "JSON parsing failed. Content: #{json_content[0..500]}..."
      raise InvalidResponseError, "Invalid JSON in AI response: #{e.message}. Response must be valid JSON only."
    end
    
    # Handle different response structures from AI service
    routine_data = if parsed_response[:json].present?
      # AI service wrapped the response in a 'json' key
      parsed_response[:json]
    elsif parsed_response[:routines].present?
      # Direct response with routines array
      parsed_response
    else
      # Try to find routines in the response
      Rails.logger.error "AI response structure: #{parsed_response.keys}"
      raise InvalidResponseError, "AI response does not contain 'routines' array or 'json' wrapper"
    end
    
    # Validate the JSON structure
    validate_routine_structure(routine_data)
    
    {
      routine: routine_data
    }
  end

  def validate_routine_structure(routine_data)
    # Check for required top-level structure
    unless routine_data.is_a?(Hash) && routine_data[:routines].is_a?(Array)
      raise InvalidResponseError, "AI response must contain 'routines' array"
    end
    

    
    # Validate number of routines
    actual_routines = routine_data[:routines].length
    expected_routines = @params[:frequency_per_week]
    
    if actual_routines != expected_routines
      Rails.logger.warn "AI generated #{actual_routines} routines, expected #{expected_routines}"
      if actual_routines < expected_routines
        # Add missing routines with placeholder data
        (actual_routines + 1..expected_routines).each do |day|
          routine_data[:routines] << {
            routine: {
              day: day,
              name: "Rutina de #{@params[:goal].downcase} - Día #{day}",
              description: "Rutina enfocada en #{@params[:goal].downcase} para nivel #{@params[:experience_level]}",
              difficulty: @params[:experience_level],
              duration: @params[:time_per_session],
              routine_exercises_attributes: [
                {
                  exercise_id: 1,
                  name: "Ejercicio placeholder",
                  sets: 3,
                  reps: 10,
                  rest_time: 60,
                  order: 1
                }
              ]
            }
          }
        end
      elsif actual_routines > expected_routines
        # Remove extra routines
        routine_data[:routines] = routine_data[:routines].first(expected_routines)
      end
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

  def validate_exercise_ids(routine_data)
    # Collect all exercise IDs from the routines
    exercise_ids = []
    routine_data[:routines].each do |routine_item|
      routine_item[:routine][:routine_exercises_attributes].each do |exercise|
        exercise_ids << exercise[:exercise_id]
      end
    end
    
    Rails.logger.info "Exercise IDs from AI response: #{exercise_ids.join(', ')}"
    
    # Check if all exercise IDs exist in the database
    existing_ids = Exercise.where(id: exercise_ids).pluck(:id)
    missing_ids = exercise_ids - existing_ids
    
    if missing_ids.any?
      Rails.logger.error "Missing exercise IDs: #{missing_ids.join(', ')}"
      Rails.logger.error "Available exercise IDs: #{Exercise.where(id: exercise_ids).pluck(:id).join(', ')}"
      raise InvalidExerciseIdError, "Invalid exercise IDs found in AI response: #{missing_ids.join(', ')}"
    end
    
    Rails.logger.info "Validated #{exercise_ids.length} exercise IDs successfully"
  end
end 