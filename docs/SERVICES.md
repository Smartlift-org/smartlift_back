# SmartLift API Services Documentation

## Overview

This document describes the service layer of the SmartLift API, which encapsulates business logic and external integrations. Services follow the Single Responsibility Principle and are designed to be testable and reusable.

## Service Architecture

```
Controllers → Services → Models/External APIs
                ↓
           Serializers → JSON Response
```

## Core Services

### 1. AiWorkoutRoutineService

**Purpose**: Generate personalized workout routines using AI based on user preferences and goals.

**Location**: `app/services/ai_workout_routine_service.rb`

**Usage**:
```ruby
# In controller
service = AiWorkoutRoutineService.new(ai_routine_params)
result = service.call

# Parameters
{
  age: 25,
  gender: "male",
  weight: 80,
  height: 180,
  experience_level: "intermediate",
  equipment: ["barbell", "dumbbell", "cables"],
  preferences: "Focus on strength building",
  frequency_per_week: 4,
  time_per_session: 60,
  goal: "Build muscle and increase strength"
}

# Response
{
  explanation: "Esta rutina está diseñada para...",
  routine: {
    days: [
      {
        day: "Monday",
        routine: {
          name: "Upper Body Push",
          description: "Chest, shoulders, and triceps",
          difficulty: "intermediate",
          duration: 60,
          routine_exercises_attributes: [...]
        }
      }
    ]
  }
}
```

**Key Methods**:
- `call`: Main entry point that orchestrates the routine generation
- `build_prompt`: Creates the AI prompt with user parameters
- `parse_ai_response`: Extracts and validates the AI response
- `validate_exercises`: Ensures all suggested exercises exist in database

**Error Handling**:
- `AiServiceError`: When AI service is unavailable
- `InvalidResponseError`: When AI response cannot be parsed

### 2. AiApiClient

**Purpose**: HTTP client for communicating with external AI service.

**Location**: `app/services/ai_api_client.rb`

**Configuration**:
```ruby
API_ENDPOINT = 'http://localhost:4000/api/v1/prediction/53773a52-4eac-42b8-a5d0-4f9aa5e20529'
TIMEOUT_SECONDS = 60
MAX_RETRIES = 2
```

**Usage**:
```ruby
client = AiApiClient.new
response = client.generate_routine(prompt)
```

**Features**:
- Automatic retry with exponential backoff
- Timeout handling
- Comprehensive error responses
- Request/response logging

**Error Codes Handled**:
- 200: Success
- 400: Bad Request
- 401/403: Authentication errors
- 429: Rate limiting
- 500-504: Server errors

### 3. WorkoutCompletionService (Planned)

**Purpose**: Handle the complex logic of completing a workout session.

**Suggested Implementation**:
```ruby
class WorkoutCompletionService
  def initialize(workout, completion_params = {})
    @workout = workout
    @params = completion_params
  end
  
  def call
    return false unless can_complete?
    
    ActiveRecord::Base.transaction do
      resume_if_paused
      finalize_all_exercises
      calculate_workout_metrics
      check_for_personal_records
      update_user_statistics
      mark_as_completed
    end
    
    send_completion_notification
    true
  rescue StandardError => e
    handle_error(e)
    false
  end
  
  private
  
  def can_complete?
    @workout.active? && @workout.has_exercises?
  end
  
  def finalize_all_exercises
    @workout.exercises.each(&:finalize!)
  end
  
  def calculate_workout_metrics
    @workout.update!(
      total_volume: calculate_total_volume,
      total_sets_completed: count_completed_sets,
      average_rpe: calculate_average_rpe
    )
  end
  
  def check_for_personal_records
    PersonalRecordChecker.new(@workout).check_all
  end
end
```

### 4. PersonalRecordChecker (Planned)

**Purpose**: Detect and record personal records achieved during workouts.

**Suggested Implementation**:
```ruby
class PersonalRecordChecker
  RECORD_TYPES = %w[max_weight max_reps max_volume].freeze
  
  def initialize(workout)
    @workout = workout
    @user = workout.user
  end
  
  def check_all
    @workout.exercises.each do |exercise|
      check_exercise_records(exercise)
    end
  end
  
  private
  
  def check_exercise_records(workout_exercise)
    workout_exercise.sets.completed.normal.each do |set|
      check_weight_record(set)
      check_reps_record(set)
      check_volume_record(set)
    end
  end
  
  def check_weight_record(set)
    current_max = PersonalRecord.where(
      user: @user,
      exercise: set.exercise,
      record_type: 'max_weight'
    ).maximum(:value) || 0
    
    if set.weight > current_max
      create_personal_record(set, 'max_weight', set.weight)
    end
  end
end
```

### 5. WorkoutStatisticsService (Planned)

**Purpose**: Calculate and aggregate user workout statistics.

**Suggested Implementation**:
```ruby
class WorkoutStatisticsService
  def initialize(user, period = :all_time)
    @user = user
    @period = period
  end
  
  def call
    {
      total_workouts: total_workouts,
      total_volume: total_volume,
      total_duration_hours: total_duration_hours,
      current_streak: calculate_current_streak,
      longest_streak: calculate_longest_streak,
      favorite_exercises: calculate_favorite_exercises,
      progress_metrics: calculate_progress_metrics,
      weekly_stats: weekly_statistics
    }
  end
  
  private
  
  def workouts_in_period
    case @period
    when :week
      @user.workouts.completed.where('completed_at > ?', 1.week.ago)
    when :month
      @user.workouts.completed.where('completed_at > ?', 1.month.ago)
    else
      @user.workouts.completed
    end
  end
  
  def calculate_current_streak
    # Logic to calculate consecutive workout days
  end
  
  def calculate_favorite_exercises
    @user.workout_exercises
         .joins(:exercise)
         .group('exercises.id', 'exercises.name')
         .count
         .sort_by { |_, count| -count }
         .first(5)
         .map { |(id, name), count| 
           { exercise_id: id, name: name, times_performed: count }
         }
  end
end
```

### 6. RoutineCloner (Planned)

**Purpose**: Create copies of existing workout routines.

**Suggested Implementation**:
```ruby
class RoutineCloner
  def initialize(routine, options = {})
    @routine = routine
    @options = options
  end
  
  def call
    new_routine = @routine.dup
    new_routine.name = @options[:name] || "Copy of #{@routine.name}"
    new_routine.user = @options[:user] || @routine.user
    
    ActiveRecord::Base.transaction do
      new_routine.save!
      clone_exercises(new_routine)
    end
    
    new_routine
  end
  
  private
  
  def clone_exercises(new_routine)
    @routine.routine_exercises.each do |exercise|
      new_routine.routine_exercises.create!(
        exercise: exercise.exercise,
        sets: exercise.sets,
        reps: exercise.reps,
        rest_time: exercise.rest_time,
        order: exercise.order,
        group_type: exercise.group_type,
        group_order: exercise.group_order
      )
    end
  end
end
```

### 7. ExerciseRecommendationService (Planned)

**Purpose**: Recommend exercises based on user history and preferences.

**Suggested Implementation**:
```ruby
class ExerciseRecommendationService
  def initialize(user, muscle_group = nil)
    @user = user
    @muscle_group = muscle_group
  end
  
  def call
    base_exercises = Exercise.all
    base_exercises = base_exercises.where(muscle_group: @muscle_group) if @muscle_group
    
    recommendations = base_exercises.map do |exercise|
      {
        exercise: exercise,
        score: calculate_recommendation_score(exercise)
      }
    end
    
    recommendations.sort_by { |r| -r[:score] }
                  .first(10)
                  .map { |r| r[:exercise] }
  end
  
  private
  
  def calculate_recommendation_score(exercise)
    frequency_score = calculate_frequency_score(exercise)
    performance_score = calculate_performance_score(exercise)
    variety_score = calculate_variety_score(exercise)
    
    (frequency_score * 0.3) + (performance_score * 0.5) + (variety_score * 0.2)
  end
end
```

## Service Patterns

### 1. Service Object Pattern

All services follow a consistent pattern:

```ruby
class ServiceName
  def initialize(params)
    @params = params
  end
  
  def call
    # Main logic here
    # Return result or raise exception
  end
  
  private
  
  # Private helper methods
end
```

### 2. Error Handling

Services should handle errors gracefully:

```ruby
class ServiceWithErrorHandling
  class ServiceError < StandardError; end
  class ValidationError < ServiceError; end
  
  def call
    validate_inputs!
    perform_action
  rescue StandardError => e
    handle_error(e)
    raise ServiceError, "Operation failed: #{e.message}"
  end
  
  private
  
  def validate_inputs!
    raise ValidationError, "Invalid input" unless valid?
  end
end
```

### 3. Transaction Management

Use database transactions for data consistency:

```ruby
def call
  ActiveRecord::Base.transaction do
    step_one
    step_two
    step_three
  end
rescue ActiveRecord::RecordInvalid => e
  handle_validation_error(e)
  false
end
```

### 4. Dependency Injection

Services should accept dependencies for testability:

```ruby
class NotificationService
  def initialize(user, mailer = UserMailer, notifier = PushNotifier)
    @user = user
    @mailer = mailer
    @notifier = notifier
  end
  
  def call
    @mailer.workout_completed(@user).deliver_later
    @notifier.send(@user, "Workout completed!")
  end
end
```

## Testing Services

### Unit Tests

```ruby
RSpec.describe AiWorkoutRoutineService do
  let(:valid_params) do
    {
      age: 25,
      gender: "male",
      weight: 80,
      height: 180,
      experience_level: "intermediate",
      equipment: ["barbell", "dumbbell"],
      preferences: "Strength focus",
      frequency_per_week: 4,
      time_per_session: 60,
      goal: "Build muscle"
    }
  end
  
  let(:service) { described_class.new(valid_params) }
  let(:ai_client) { instance_double(AiApiClient) }
  
  before do
    allow(AiApiClient).to receive(:new).and_return(ai_client)
  end
  
  describe '#call' do
    context 'with valid AI response' do
      let(:ai_response) { fixture_file('ai_response_valid.txt') }
      
      before do
        allow(ai_client).to receive(:generate_routine).and_return(ai_response)
      end
      
      it 'returns parsed routine' do
        result = service.call
        expect(result).to have_key(:explanation)
        expect(result).to have_key(:routine)
      end
    end
    
    context 'when AI service is unavailable' do
      before do
        allow(ai_client).to receive(:generate_routine)
          .and_raise(AiWorkoutRoutineService::AiServiceError)
      end
      
      it 'raises AiServiceError' do
        expect { service.call }.to raise_error(AiWorkoutRoutineService::AiServiceError)
      end
    end
  end
end
```

### Integration Tests

```ruby
RSpec.describe 'AI Workout Generation', type: :request do
  describe 'POST /api/v1/ai/workout_routines' do
    let(:valid_params) { ... }
    
    context 'with mocked AI service' do
      before do
        stub_ai_service_request
      end
      
      it 'generates a workout routine' do
        post '/api/v1/ai/workout_routines', 
             params: valid_params,
             headers: { 'X-API-Key' => 'test-key' }
        
        expect(response).to have_http_status(:ok)
        expect(json_response['success']).to be true
        expect(json_response['data']).to have_key('routine')
      end
    end
  end
end
```

## Best Practices

### 1. Single Responsibility
Each service should have one clear purpose.

### 2. Idempotency
Services should be idempotent when possible.

### 3. Logging
Log important operations and errors:

```ruby
Rails.logger.info "Starting routine generation for user #{user.id}"
Rails.logger.error "AI service error: #{e.message}"
```

### 4. Performance
- Use eager loading to avoid N+1 queries
- Cache expensive calculations
- Consider background jobs for heavy operations

### 5. Security
- Validate all inputs
- Sanitize data before external API calls
- Never log sensitive information

## Future Services

### Planned Services

1. **SocialSharingService**: Share workout achievements
2. **ExportService**: Export workout data in various formats
3. **NutritionIntegrationService**: Connect with nutrition APIs
4. **WearableDeviceService**: Sync with fitness trackers
5. **AnalyticsService**: Advanced workout analytics
6. **NotificationService**: Push notifications and emails

### Service Registry

Consider implementing a service registry for dependency management:

```ruby
class ServiceRegistry
  class << self
    def register(name, service_class)
      services[name] = service_class
    end
    
    def get(name)
      services[name] || raise("Service #{name} not found")
    end
    
    private
    
    def services
      @services ||= {}
    end
  end
end

# Usage
ServiceRegistry.register(:ai_workout, AiWorkoutRoutineService)
service = ServiceRegistry.get(:ai_workout).new(params)
```

## Monitoring and Metrics

### Service Metrics to Track

1. **Response Times**: How long services take to execute
2. **Success/Failure Rates**: Service reliability
3. **External API Calls**: Monitor third-party dependencies
4. **Error Frequencies**: Common failure points

### Example Instrumentation

```ruby
class InstrumentedService
  def call
    start_time = Time.current
    
    result = perform_operation
    
    track_metric('service.success', 1)
    track_metric('service.duration', Time.current - start_time)
    
    result
  rescue StandardError => e
    track_metric('service.error', 1, tags: { error: e.class.name })
    raise
  end
end
``` 