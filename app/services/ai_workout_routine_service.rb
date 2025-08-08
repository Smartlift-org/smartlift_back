require "json"

class AiWorkoutRoutineService
  class InvalidResponseError < StandardError; end
  class ServiceUnavailableError < StandardError; end

  def initialize(params, agent_type = :create)
    @params = params
    @ai_client = AiApiClient.new(agent_type)
  end

  def create_routine
    begin
      # Build the prompt for the AI
      prompt = create_routine_prompt

      # Send to AI service
      response = @ai_client.create_routine(prompt)

      # Parse and validate the response
      parsed_response = parse_ai_response(response)

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
    rescue StandardError => e
      Rails.logger.error "AI Workout Routine Service Error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise InvalidResponseError, "Failed to generate routine: #{e.message}"
    end
  end

  def modify_routine(routine_json, message)
    begin
      # Build the prompt for modification
      prompt = modify_routine_prompt(routine_json, message)

      # Send to AI service
      response = @ai_client.create_routine(prompt)

      # Parse and validate the response
      parsed_response = parse_modification_response(response)

      # Return the structured response (convert single routine to array for consistency)
      {
        routines: [{ routine: parsed_response[:routine] }]
      }

    rescue AiApiClient::TimeoutError => e
      raise ServiceUnavailableError, "AI service timeout: #{e.message}"
    rescue AiApiClient::NetworkError => e
      raise ServiceUnavailableError, "AI service network error: #{e.message}"
    rescue AiApiClient::ServiceError => e
      raise ServiceUnavailableError, "AI service error: #{e.message}"
    rescue StandardError => e
      Rails.logger.error "AI Workout Routine Modification Error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise InvalidResponseError, "Failed to modify routine: #{e.message}"
    end
  end

  private

  def create_routine_prompt
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

      Please generate a personalized workout routine based on this user profile.
    PROMPT

    Rails.logger.info "Generated AI prompt for user profile: #{@params[:age]}yo #{@params[:gender]}, #{@params[:experience_level]} level"
    Rails.logger.debug "Full prompt: #{prompt}" if Rails.env.development?

    prompt
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

  def modify_routine_prompt(routine_json, message)
    "#{message}\n\n#{JSON.pretty_generate(routine_json)}"
  end

  def parse_modification_response(response)
    Rails.logger.debug "Raw AI modification response: #{response.inspect}" if Rails.env.development?

    # Clean the response
    json_content = response.strip

    # Parse the response
    begin
      ai_response = JSON.parse(json_content, symbolize_names: true)
    rescue JSON::ParserError => e
      Rails.logger.error "JSON parsing failed. Content: #{json_content[0..500]}..."
      raise InvalidResponseError, "Invalid JSON in AI response: #{e.message}. Response must be valid JSON only."
    end

    # Check if response has the nested 'json' field or direct routine
    routine_data = if ai_response[:json].present? && ai_response[:json][:routine].present?
      ai_response[:json]  # TheAnswer.ai nested format
    elsif ai_response[:routine].present?
      ai_response  # Direct routine format
    else
      Rails.logger.error "AI response missing 'json.routine' or 'routine' field: #{ai_response}"
      raise InvalidResponseError, "AI response must contain 'routine' field"
    end

    # Validate the routine structure
    validate_modification_routine_structure(routine_data[:routine])

    {
      routine: routine_data[:routine]
    }
  end

  def validate_modification_routine_structure(routine)
    # Check for required routine structure
    unless routine.is_a?(Hash)
      raise InvalidResponseError, "AI response routine must be a hash"
    end

    unless routine[:name].present? && routine[:routine_exercises_attributes].is_a?(Array)
      raise InvalidResponseError, "Routine missing required fields: name and routine_exercises_attributes"
    end

    # Validate exercises basic structure
    routine[:routine_exercises_attributes].each_with_index do |exercise, ex_index|
      unless exercise.is_a?(Hash) &&
             exercise[:sets].present? &&
             exercise[:reps].present?
        raise InvalidResponseError, "Exercise #{ex_index + 1} has invalid structure"
      end
    end
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

      # Validate exercises basic structure
      routine[:routine_exercises_attributes].each_with_index do |exercise, ex_index|
        unless exercise.is_a?(Hash) &&
               exercise[:sets].present? &&
               exercise[:reps].present?
          raise InvalidResponseError, "Routine #{index + 1}, exercise #{ex_index + 1} has invalid structure"
        end
      end
    end
  end
end
