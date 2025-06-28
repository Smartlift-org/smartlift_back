# SmartLift API Development Guide

## Table of Contents
1. [Getting Started](#getting-started)
2. [Development Environment](#development-environment)
3. [Coding Standards](#coding-standards)
4. [Testing Guidelines](#testing-guidelines)
5. [Development Workflow](#development-workflow)
6. [Common Tasks](#common-tasks)
7. [Debugging Tips](#debugging-tips)
8. [Best Practices](#best-practices)

## Getting Started

### Prerequisites
- Docker and Docker Compose
- Git
- Your favorite code editor (VS Code, RubyMine, etc.)

### Initial Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd smartlift_api
   ```

2. **Start Docker containers**
   ```bash
   docker-compose up -d
   ```

3. **Setup database**
   ```bash
   docker-compose run --rm web rails db:create db:migrate db:seed
   ```

4. **Run tests to verify setup**
   ```bash
   docker-compose run --rm web rspec
   ```

## Development Environment

### Docker Services

| Service | Port | Description |
|---------|------|-------------|
| web | 3000 | Rails API server |
| db | 5433 | PostgreSQL database |
| redis | 6380 | Redis cache |

### Environment Variables

Create a `.env` file for local development:

```env
# Database
DATABASE_HOST=db
DATABASE_PORT=5432
DATABASE_USERNAME=postgres
DATABASE_PASSWORD=password

# Redis
REDIS_URL=redis://redis:6379/0

# JWT
JWT_SECRET_KEY=your-secret-key-here

# AI Service
AI_SERVICE_URL=http://localhost:4000
AI_SERVICE_API_KEY=your-api-key
```

### Useful Commands

```bash
# Start all services
docker-compose up

# Run Rails console
docker-compose run --rm web rails c

# Run database migrations
docker-compose run --rm web rails db:migrate

# Run specific tests
docker-compose run --rm web rspec spec/controllers/workouts_controller_spec.rb

# View logs
docker-compose logs -f web

# Clean rebuild
docker-compose down -v
docker-compose build --no-cache
docker-compose up
```

## Coding Standards

### Ruby Style Guide

We follow the [Ruby Style Guide](https://rubystyle.guide/) with some modifications:

```ruby
# Good: Use meaningful variable names
user_workout_count = user.workouts.count

# Bad: Avoid single letter variables
c = user.workouts.count

# Good: Use guard clauses
def process_workout
  return unless workout.valid?
  return if workout.completed?
  
  workout.process!
end

# Bad: Avoid deep nesting
def process_workout
  if workout.valid?
    unless workout.completed?
      workout.process!
    end
  end
end
```

### Rails Conventions

1. **Controllers**: Keep them thin
   ```ruby
   class WorkoutsController < ApplicationController
     def create
       @workout = WorkoutCreationService.new(current_user, workout_params).call
       
       if @workout.persisted?
         render json: @workout, status: :created
       else
         render json: @workout.errors, status: :unprocessable_entity
       end
     end
   end
   ```

2. **Models**: Business logic in services
   ```ruby
   class Workout < ApplicationRecord
     # Associations, validations, and scopes only
     belongs_to :user
     validates :status, inclusion: { in: STATUSES }
     scope :active, -> { where(status: ['in_progress', 'paused']) }
   end
   ```

3. **Services**: Encapsulate business logic
   ```ruby
   class WorkoutCompletionService
     def initialize(workout)
       @workout = workout
     end
     
     def call
       return false unless can_complete?
       
       ActiveRecord::Base.transaction do
         finalize_exercises
         calculate_statistics
         check_personal_records
         mark_as_completed
       end
       
       true
     rescue StandardError => e
       Rails.logger.error "Failed to complete workout: #{e.message}"
       false
     end
     
     private
     
     # Private methods...
   end
   ```

### API Response Standards

1. **Success Responses**
   ```json
   {
     "data": {
       "id": 1,
       "type": "workout",
       "attributes": {
         "name": "Morning Workout",
         "status": "completed"
       }
     }
   }
   ```

2. **Error Responses**
   ```json
   {
     "errors": [
       {
         "status": "422",
         "title": "Validation Error",
         "detail": "Name can't be blank"
       }
     ]
   }
   ```

### Database Guidelines

1. **Migrations**
   ```ruby
   class AddIndexesToWorkoutSets < ActiveRecord::Migration[7.1]
     def change
       add_index :workout_sets, :workout_exercise_id
       add_index :workout_sets, [:workout_exercise_id, :set_number], unique: true
       add_index :workout_sets, :completed_at
     end
   end
   ```

2. **Query Optimization**
   ```ruby
   # Good: Eager loading
   workouts = user.workouts.includes(:exercises, :routine)
   
   # Bad: N+1 queries
   workouts = user.workouts
   workouts.each { |w| w.exercises.count }
   ```

## Testing Guidelines

### Test Structure

```ruby
# spec/services/workout_completion_service_spec.rb
require 'rails_helper'

RSpec.describe WorkoutCompletionService do
  describe '#call' do
    let(:user) { create(:user) }
    let(:workout) { create(:workout, user: user, status: 'in_progress') }
    let(:service) { described_class.new(workout) }
    
    context 'when workout can be completed' do
      before do
        create_list(:workout_exercise, 3, workout: workout, completed: true)
      end
      
      it 'marks the workout as completed' do
        expect { service.call }.to change { workout.reload.status }
          .from('in_progress').to('completed')
      end
      
      it 'returns true' do
        expect(service.call).to be true
      end
    end
    
    context 'when workout cannot be completed' do
      it 'returns false' do
        expect(service.call).to be false
      end
    end
  end
end
```

### Testing Best Practices

1. **Use factories, not fixtures**
   ```ruby
   # spec/factories/workouts.rb
   FactoryBot.define do
     factory :workout do
       user
       routine
       status { 'in_progress' }
       started_at { Time.current }
       
       trait :completed do
         status { 'completed' }
         completed_at { Time.current }
       end
     end
   end
   ```

2. **Test behavior, not implementation**
   ```ruby
   # Good
   it 'creates a personal record when weight exceeds previous max' do
     expect { service.call }.to change { PersonalRecord.count }.by(1)
   end
   
   # Bad
   it 'calls check_personal_record method' do
     expect(service).to receive(:check_personal_record)
     service.call
   end
   ```

3. **Use shared examples**
   ```ruby
   # spec/support/shared_examples/authenticated_endpoint.rb
   RSpec.shared_examples 'authenticated endpoint' do
     context 'without authentication' do
       before { headers.delete('Authorization') }
       
       it 'returns 401 unauthorized' do
         subject
         expect(response).to have_http_status(:unauthorized)
       end
     end
   end
   ```

### Running Tests

```bash
# Run all tests
docker-compose run --rm web rspec

# Run specific file
docker-compose run --rm web rspec spec/models/workout_spec.rb

# Run with coverage
docker-compose run --rm -e COVERAGE=true web rspec

# Run only failing tests
docker-compose run --rm web rspec --only-failures
```

## Development Workflow

### Git Workflow

1. **Branch Naming**
   - Features: `feature/add-social-sharing`
   - Bugs: `fix/workout-completion-error`
   - Refactoring: `refactor/extract-workout-service`

2. **Commit Messages**
   ```
   feat: Add workout sharing functionality
   
   - Added ShareWorkoutService
   - Created sharing endpoints
   - Added tests for sharing flow
   
   Closes #123
   ```

3. **Pull Request Process**
   - Create feature branch from `develop`
   - Write tests first (TDD)
   - Implement feature
   - Run tests and linter
   - Create PR with description
   - Address review comments
   - Merge when approved

### Code Review Checklist

- [ ] Tests pass
- [ ] Code follows style guide
- [ ] No N+1 queries
- [ ] API responses follow standards
- [ ] Error handling is appropriate
- [ ] Documentation is updated
- [ ] Performance impact considered

## Common Tasks

### Adding a New Endpoint

1. **Add route**
   ```ruby
   # config/routes.rb
   resources :workout_templates do
     member do
       post :duplicate
     end
   end
   ```

2. **Create controller**
   ```ruby
   # app/controllers/workout_templates_controller.rb
   class WorkoutTemplatesController < ApplicationController
     before_action :set_template, only: [:show, :duplicate]
     
     def duplicate
       @new_template = TemplateCloner.new(@template).call
       render json: @new_template, status: :created
     end
     
     private
     
     def set_template
       @template = current_user.workout_templates.find(params[:id])
     end
   end
   ```

3. **Add tests**
   ```ruby
   # spec/controllers/workout_templates_controller_spec.rb
   RSpec.describe WorkoutTemplatesController do
     describe 'POST #duplicate' do
       it 'creates a copy of the template' do
         template = create(:workout_template, user: user)
         
         expect {
           post :duplicate, params: { id: template.id }
         }.to change { WorkoutTemplate.count }.by(1)
       end
     end
   end
   ```

### Adding a New Service

1. **Create service class**
   ```ruby
   # app/services/template_cloner.rb
   class TemplateCloner
     def initialize(template)
       @template = template
     end
     
     def call
       new_template = @template.dup
       new_template.name = "Copy of #{@template.name}"
       
       ActiveRecord::Base.transaction do
         new_template.save!
         clone_exercises(new_template)
       end
       
       new_template
     end
     
     private
     
     def clone_exercises(new_template)
       @template.exercises.each do |exercise|
         new_template.exercises << exercise.dup
       end
     end
   end
   ```

2. **Test the service**
   ```ruby
   # spec/services/template_cloner_spec.rb
   RSpec.describe TemplateCloner do
     # Tests...
   end
   ```

### Database Tasks

```bash
# Create a new migration
docker-compose run --rm web rails g migration AddNotesToWorkouts notes:text

# Run migrations
docker-compose run --rm web rails db:migrate

# Rollback migration
docker-compose run --rm web rails db:rollback

# Reset database
docker-compose run --rm web rails db:drop db:create db:migrate db:seed

# Access database console
docker-compose run --rm db psql -U postgres smartlift_development
```

## Debugging Tips

### Rails Console

```ruby
# Access console
docker-compose run --rm web rails c

# Reload console after code changes
reload!

# Pretty print objects
pp User.first.workouts.limit(5)

# Check SQL queries
ActiveRecord::Base.logger = Logger.new(STDOUT)
User.first.workouts.includes(:exercises).to_a
```

### Debugging with Pry

1. Add to Gemfile: `gem 'pry-rails'`
2. Add breakpoint: `binding.pry`
3. Run tests or server and interact at breakpoint

### Performance Debugging

```ruby
# Measure query time
ActiveRecord::Base.connection.execute("EXPLAIN ANALYZE SELECT * FROM workouts")

# Find N+1 queries
# Add to Gemfile: gem 'bullet'
# Check logs for Bullet warnings
```

### Common Issues

1. **Container won't start**
   ```bash
   docker-compose logs web
   docker-compose down -v
   docker-compose up --build
   ```

2. **Database connection errors**
   ```bash
   docker-compose restart db
   docker-compose run --rm web rails db:create
   ```

3. **Permission errors**
   ```bash
   # Fix ownership
   sudo chown -R $USER:$USER .
   ```

## Best Practices

### Security

1. **Never commit secrets**
   ```ruby
   # Bad
   API_KEY = "sk-1234567890"
   
   # Good
   API_KEY = ENV['API_KEY']
   ```

2. **Validate and sanitize input**
   ```ruby
   def workout_params
     params.require(:workout).permit(:name, :routine_id)
           .tap { |p| p[:name] = p[:name]&.strip }
   end
   ```

3. **Use strong parameters**
   ```ruby
   # Always use permit, never permit!
   params.require(:user).permit(:email, :name)
   ```

### Performance

1. **Use includes for associations**
   ```ruby
   # Good
   workouts = Workout.includes(:exercises, :user)
   
   # Bad
   workouts = Workout.all
   workouts.each { |w| w.exercises }
   ```

2. **Add database indexes**
   ```ruby
   add_index :workouts, :user_id
   add_index :workouts, [:user_id, :status]
   ```

3. **Cache expensive operations**
   ```ruby
   def user_statistics
     Rails.cache.fetch("user_stats_#{id}", expires_in: 1.hour) do
       calculate_statistics
     end
   end
   ```

### Code Quality

1. **Keep methods small**
   ```ruby
   # Each method should do one thing
   def complete_workout
     validate_completion
     finalize_exercises
     calculate_totals
     mark_completed
   end
   ```

2. **Use meaningful names**
   ```ruby
   # Good
   def exercises_completed_count
   
   # Bad
   def exc_count
   ```

3. **Document complex logic**
   ```ruby
   # Calculates the total volume (weight × reps) for all sets
   # in the workout, excluding warmup and failed sets
   def calculate_total_volume
     # Implementation
   end
   ```

## Resources

- [Rails Guides](https://guides.rubyonrails.org/)
- [Ruby Style Guide](https://rubystyle.guide/)
- [RSpec Best Practices](https://www.betterspecs.org/)
- [API Design Guidelines](https://jsonapi.org/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/) 