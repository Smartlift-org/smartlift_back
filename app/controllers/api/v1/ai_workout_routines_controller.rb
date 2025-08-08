class Api::V1::AiWorkoutRoutinesController < ApplicationController
  # Authentication is required for this endpoint
  # Use JWT token in Authorization header: Bearer <token>

  # POST /api/v1/ai/workout_routines
  def create
    begin
      # Validate input parameters
      validation_errors = validate_input_params
      if validation_errors.any?
        return render json: {
          success: false,
          error: "Validation failed",
          details: validation_errors
        }, status: :bad_request
      end

      # Initialize the AI workout routine service
      service = AiWorkoutRoutineService.new(workout_params)

      # Generate the routine using AI
      result = service.create_routine

      # Return successful response
      render json: {
        success: true,
        data: {
          routines: result[:routines],
          generated_at: Time.current.iso8601
        }
      }, status: :ok

    rescue AiWorkoutRoutineService::InvalidResponseError => e
      render json: {
        success: false,
        error: "AI service returned invalid response",
        details: e.message
      }, status: :unprocessable_entity

    rescue AiWorkoutRoutineService::ServiceUnavailableError => e
      render json: {
        success: false,
        error: "AI service temporarily unavailable",
        details: "Please try again later"
      }, status: :service_unavailable

    rescue StandardError => e
      Rails.logger.error "AI Workout Routine Generation Error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")

      render json: {
        success: false,
        error: "Internal server error",
        details: "An unexpected error occurred while generating the routine"
      }, status: :internal_server_error
    end
  end

  # POST /api/v1/ai/workout_routines/modify
  def modify
    begin
      # Validate input parameters
      validation_errors = validate_modification_params
      if validation_errors.any?
        return render json: {
          success: false,
          error: "Validation failed",
          details: validation_errors
        }, status: :bad_request
      end

      # Initialize the AI workout routine service for modification
      service = AiWorkoutRoutineService.new({}, :modify)

      # Modify the routine using AI
      result = service.modify_routine(params[:routine], params[:modification_message])

      # Return successful response
      render json: {
        success: true,
        data: {
          routines: result[:routines],
          generated_at: Time.current.iso8601
        }
      }, status: :ok

    rescue AiWorkoutRoutineService::InvalidResponseError => e
      render json: {
        success: false,
        error: "AI service returned invalid response",
        details: e.message
      }, status: :unprocessable_entity

    rescue AiWorkoutRoutineService::ServiceUnavailableError => e
      render json: {
        success: false,
        error: "AI service temporarily unavailable",
        details: "Please try again later"
      }, status: :service_unavailable

    rescue StandardError => e
      Rails.logger.error "AI Workout Routine Modification Error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")

      render json: {
        success: false,
        error: "Internal server error",
        details: "An unexpected error occurred while modifying the routine"
      }, status: :internal_server_error
    end
  end

  private

  def workout_params
    params.permit(
      :age, :gender, :weight, :height, :experience_level,
      :preferences, :frequency_per_week, :time_per_session, :goal
    )
  end

  def validate_input_params
    errors = {}

    # Age validation
    age = params[:age]
    if age.blank?
      errors[:age] = [ "is required" ]
    else
      age_int = age.to_i
      if age_int < 13 || age_int > 100
        errors[:age] = [ "must be between 13 and 100" ]
      end
    end

    # Gender validation
    gender = params[:gender]
    if gender.blank?
      errors[:gender] = [ "is required" ]
    elsif !%w[male female other].include?(gender.to_s)
      errors[:gender] = [ "must be one of: male, female, other" ]
    end

    # Weight validation
    weight = params[:weight]
    if weight.blank?
      errors[:weight] = [ "is required" ]
    else
      weight_num = weight.to_f
      if weight_num <= 0 || weight_num > 300
        errors[:weight] = [ "must be between 1 and 300 kg" ]
      end
    end

    # Height validation
    height = params[:height]
    if height.blank?
      errors[:height] = [ "is required" ]
    else
      height_int = height.to_i
      if height_int < 100 || height_int > 250
        errors[:height] = [ "must be between 100 and 250 cm" ]
      end
    end

    # Experience level validation
    experience_level = params[:experience_level]
    if experience_level.blank?
      errors[:experience_level] = [ "is required" ]
    elsif !%w[beginner intermediate advanced].include?(experience_level.to_s)
      errors[:experience_level] = [ "must be one of: beginner, intermediate, advanced" ]
    end


    # Frequency validation
    frequency = params[:frequency_per_week]
    if frequency.blank?
      errors[:frequency_per_week] = [ "is required" ]
    else
      frequency_int = frequency.to_i
      if frequency_int < 1 || frequency_int > 7
        errors[:frequency_per_week] = [ "must be between 1 and 7 days" ]
      end
    end

    # Session time validation
    time_per_session = params[:time_per_session]
    if time_per_session.blank?
      errors[:time_per_session] = [ "is required" ]
    else
      time_int = time_per_session.to_i
      if time_int < 15 || time_int > 180
        errors[:time_per_session] = [ "must be between 15 and 180 minutes" ]
      end
    end

    # Goal validation
    goal = params[:goal]
    if goal.blank?
      errors[:goal] = [ "is required" ]
    elsif goal.to_s.length < 3
      errors[:goal] = [ "must be at least 3 characters long" ]
    end

    # Preferences validation (optional)
    preferences = params[:preferences]
    if preferences.present? && preferences.to_s.length > 500
      errors[:preferences] = [ "must be less than 500 characters" ]
    end

    errors
  end

  def validate_modification_params
    errors = {}

    # Routine validation
    routine = params[:routine]
    if routine.blank?
      errors[:routine] = [ "is required" ]
    elsif !routine.respond_to?(:key?) && !routine.respond_to?(:[])
      errors[:routine] = [ "must be a valid routine object" ]
    else
      # Validate routine structure (Rails uses string keys for nested parameters)
      exercises_key = routine.key?(:routine_exercises_attributes) ? :routine_exercises_attributes : 'routine_exercises_attributes'
      exercises = routine[exercises_key]
      
      unless exercises.is_a?(Array)
        errors[:routine] = [ "must contain routine_exercises_attributes array" ]
      else
        # Check if at least one exercise needs modification
        needs_modification = exercises.any? do |ex|
          # Check both symbol and string keys
          needs_mod_value = ex[:needs_modification] || ex['needs_modification']
          # Handle both boolean true and string "true"
          [true, 'true', 'True', '1', 1].include?(needs_mod_value)
        end
        unless needs_modification
          errors[:routine] = [ "must have at least one exercise marked for modification" ]
        end
      end
    end

    # Modification message validation
    message = params[:modification_message]
    if message.blank?
      errors[:modification_message] = [ "is required" ]
    elsif message.to_s.length < 3
      errors[:modification_message] = [ "must be at least 3 characters long" ]
    elsif message.to_s.length > 1000
      errors[:modification_message] = [ "must be less than 1000 characters" ]
    end

    errors
  end
end
