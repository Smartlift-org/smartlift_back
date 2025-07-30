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
      result = service.generate_routine
      
      # Return successful response
      render json: {
        success: true,
        data: {
          routines: result[:routines],
          generated_at: Time.current.iso8601
        }
      }, status: :ok

    rescue AiWorkoutRoutineService::InvalidExerciseIdError => e
      render json: {
        success: false,
        error: "Invalid exercise IDs in AI response",
        details: e.message
      }, status: :unprocessable_entity

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
      errors[:age] = ["is required"]
    elsif !age.is_a?(Integer) || age < 13 || age > 100
      errors[:age] = ["must be between 13 and 100"]
    end

    # Gender validation
    gender = params[:gender]
    if gender.blank?
      errors[:gender] = ["is required"]
    elsif !%w[male female other].include?(gender.to_s)
      errors[:gender] = ["must be one of: male, female, other"]
    end

    # Weight validation
    weight = params[:weight]
    if weight.blank?
      errors[:weight] = ["is required"]
    elsif !weight.is_a?(Numeric) || weight <= 0 || weight > 300
      errors[:weight] = ["must be between 1 and 300 kg"]
    end

    # Height validation
    height = params[:height]
    if height.blank?
      errors[:height] = ["is required"]
    elsif !height.is_a?(Integer) || height < 100 || height > 250
      errors[:height] = ["must be between 100 and 250 cm"]
    end

    # Experience level validation
    experience_level = params[:experience_level]
    if experience_level.blank?
      errors[:experience_level] = ["is required"]
    elsif !%w[beginner intermediate advanced].include?(experience_level.to_s)
      errors[:experience_level] = ["must be one of: beginner, intermediate, advanced"]
    end


    # Frequency validation
    frequency = params[:frequency_per_week]
    if frequency.blank?
      errors[:frequency_per_week] = ["is required"]
    elsif !frequency.is_a?(Integer) || frequency < 1 || frequency > 7
      errors[:frequency_per_week] = ["must be between 1 and 7 days"]
    end

    # Session time validation
    time_per_session = params[:time_per_session]
    if time_per_session.blank?
      errors[:time_per_session] = ["is required"]
    elsif !time_per_session.is_a?(Integer) || time_per_session < 15 || time_per_session > 180
      errors[:time_per_session] = ["must be between 15 and 180 minutes"]
    end

    # Goal validation
    goal = params[:goal]
    if goal.blank?
      errors[:goal] = ["is required"]
    elsif goal.to_s.length < 3
      errors[:goal] = ["must be at least 3 characters long"]
    end

    # Preferences validation (optional)
    preferences = params[:preferences]
    if preferences.present? && preferences.to_s.length > 500
      errors[:preferences] = ["must be less than 500 characters"]
    end

    errors
  end

end 