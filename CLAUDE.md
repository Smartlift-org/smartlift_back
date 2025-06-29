# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SmartLift API is a Ruby on Rails 7.1.5 API-only application for a comprehensive fitness tracking platform. The system manages users (members/trainers), workout routines, AI-powered workout generation, real-time exercise tracking, and advanced performance analytics with personal record detection.

## Development Commands

### Docker Environment (Primary Development Method)
```bash
# Start all services
docker-compose up -d

# Stop services
docker-compose down

# View logs
docker-compose logs -f web

# Access Rails console
docker-compose run --rm web rails c

# Run database migrations
docker-compose run --rm web rails db:migrate

# Setup fresh database
docker-compose run --rm web rails db:create db:migrate db:seed

# Run tests
docker-compose run --rm web rspec

# Run specific test file
docker-compose run --rm web rspec spec/path/to/test_spec.rb

# Run linting
docker-compose run --rm web rubocop

# Run security audit
docker-compose run --rm web brakeman
```

### Native Rails Commands (if running locally)
```bash
# Start server
bin/rails server

# Run tests
bundle exec rspec

# Run linting
bundle exec rubocop

# Database operations
bin/rails db:migrate
bin/rails db:seed
```

## Architecture Overview

### Core Structure
- **Rails 7.1.5** in API mode with JWT authentication and Devise integration
- **PostgreSQL** database with performance-optimized indexes and foreign key constraints
- **Redis** for caching, session management, and rate limiting
- **Docker Compose** for containerized development environment
- **RSpec** for comprehensive testing with FactoryBot, Shoulda Matchers, and Faker
- **Rack::Attack** for rate limiting and DDoS protection
- **Active Model Serializers** for JSON API responses

### Key Models & Relationships
- `User` → has many workouts, routines, user_stats; supports roles (member/trainer)
- `CoachUser` → many-to-many relationship for trainer-client connections
- `UserStat` → user fitness profile (height, weight, goals, equipment, limitations)
- `Exercise` → database of 800+ exercises with categories, muscle groups, equipment types
- `Routine` → pre-planned workout templates with nested exercises
- `RoutineExercise` → exercises within routines with sets, reps, rest times, and grouping
- `Workout` → active workout sessions with simplified state machine and integrated pause tracking
- `WorkoutExercise` → exercises within workouts with progress tracking
- `WorkoutSet` → individual set tracking (weight, reps, RPE, set types, PR detection)

### Authentication System
- JWT tokens in `JsonWebToken` class (lib/json_web_token.rb)
- Token validation in `ApplicationController#authorize_request`
- API key authentication for external services (`authenticate_api_key`)
- User authentication via `AuthController#login`

### Workout State Machine (Ultra-Simplified)
Workouts progress through states: `in_progress` → `paused` → `completed`/`abandoned`
- **Ultra-simple pause/resume**: just status field changes (no tracking tables)
- **Real-time tracking** with optimized performance
- **Simple duration**: `completed_at - started_at` (pauses included)
- **Simplified feedback**: 1-10 workout rating + optional notes
- **Personal records calculated on-demand** (weight PRs, reps PRs, first-time PRs)
- **No stored PR fields**: all calculations happen in real-time for accuracy

### AI Integration
- `AiWorkoutRoutineService` orchestrates AI-powered workout generation with user profile integration
- `AiApiClient` handles external AI API communication with retry logic, timeout handling, and error management
- AI endpoint: `/api/v1/ai/workout_routines` with rate limiting (5 req/min)
- Environment variables: `AI_SERVICE_HOST`, `AI_SERVICE_PORT`, `AI_SERVICE_URL`, `AI_REQUEST_TIMEOUT`, `AI_MAX_RETRIES`
- Validates AI responses and ensures exercise IDs exist in database

## Database & Migrations

The database uses performance-optimized indexes on foreign keys, timestamps, and status fields. Key migrations are in `db/migrate/` with a backup schema at `db/schema_backup_20250624.rb`.

## Testing Strategy

- **RSpec** with request specs, model specs, and service specs
- **FactoryBot** for test data generation
- **Shoulda Matchers** for model validations
- Test files mirror app structure in `spec/`
- Authentication helper in `spec/support/authentication_helper.rb`

## API Design

### Versioned API Structure
- Main API routes under `/api/v1/` namespace  
- Core resources: users, exercises, routines, workouts
- **Simplified workout management via single `WorkoutsController`** (no namespace controllers)
- **Exercise and set management integrated into workout endpoints**
- **Personal records calculated on-demand** via `PersonalRecordsController`
- JWT authentication required for most endpoints

### Rate Limiting & Security
Configured via Rack::Attack with comprehensive protection:
- General requests: 300 requests per 5 minutes per IP
- Login attempts: 5 requests per minute per IP
- Registration: 3 requests per hour per IP
- Exercise endpoints: 100 requests per hour per IP
- Unauthenticated requests: 50 requests per hour per IP
- Malicious IP blocking with Allow2Ban (5 retries, 1 hour findtime, 24 hour bantime)
- JWT token validation with secure key base
- API key authentication for external services

## Services Directory

Business logic is extracted into service objects in `app/services/`:
- `AiWorkoutRoutineService` - AI workout generation with user profile integration and response validation
- `AiApiClient` - External AI API communication with comprehensive error handling, retry logic, and timeout management

## Serializers

JSON API responses are standardized using Active Model Serializers in `app/serializers/`:
- `UserSerializer` - User profile and authentication data
- `WorkoutSerializer` - Workout sessions with simplified feedback (workout_rating) and nested exercises
- `WorkoutExerciseSerializer` - Exercise data within workouts
- `WorkoutSetSerializer` - Individual set data with **on-demand PR calculations** (no stored PR fields)

## Development Environment

### Port Configuration
- Rails API: `localhost:3000` (mapped to `3002` in docker-compose)
- PostgreSQL: `localhost:5433` (container port 5432)
- Redis: `localhost:6380` (container port 6379)
- AI Service: Configurable via `AI_SERVICE_HOST` and `AI_SERVICE_PORT`

### Container Architecture
- **web**: Rails application container with development dependencies
- **db**: PostgreSQL 15 with persistent volume
- **redis**: Redis 7 for caching and session storage
- **Development tools**: Integrated RuboCop, Brakeman, RSpec in web container

### Environment Variables
- Database connection via `DATABASE_URL`
- Redis via `REDIS_URL`
- AI service via `AI_SERVICE_HOST`/`AI_SERVICE_PORT`

## Code Quality Tools

- **RuboCop**: Rails Omakase configuration with Performance and Rails extensions
- **Brakeman**: Security vulnerability scanning with custom configurations
- **RSpec**: Comprehensive test suite with request specs, model specs, and service specs
- **FactoryBot**: Test data generation with realistic factories
- **Shoulda Matchers**: Model validation and association testing
- All tools run via Docker: `docker-compose run --rm web [rubocop|brakeman|rspec]`

## Critical Issues Identified & Status

### ✅ Fixed Issues
1. **Foreign Key Cascade Delete**: Added `has_many :workout_exercises, dependent: :destroy` to RoutineExercise model
2. **Exercise Controller Scope**: Fixed `by_difficulty` to use `by_level` scope
3. **Parameter Validation**: Removed duplicate `:instructions` parameter in ExercisesController
4. **WorkoutExercise Validation**: Added uniqueness validation for order within workout scope

### ✅ Architecture Simplifications Implemented
1. **WorkoutPause Model Eliminated**: Replaced with simple status-based pause/resume system
2. **Controller Consolidation**: Merged all workout functionality into single WorkoutsController
3. **Route Simplification**: Eliminated nested namespace routes for cleaner API structure
4. **Performance Optimization**: Optimized pause duration calculations and volume queries
5. **Workout Feedback Simplified**: Replaced 3 complex feedback fields with single 1-10 rating system
6. **Personal Records Simplified**: On-demand calculation instead of stored flags, supports both weight and reps PRs
7. **Pause System Ultra-Simplified**: Just status changes, no complex tracking

### 📊 Complexity Reduction Results
- **-40% codebase complexity**: Removed WorkoutPause model, namespace controllers, and stored PR tracking
- **-80+ lines of code**: Simplified pause/resume logic, feedback system, and PR detection
- **-3 controller files**: Consolidated into single WorkoutsController
- **-5 database fields**: Simplified feedback fields and eliminated stored PR flags
- **-1 database table**: Completely eliminated `workout_pauses` table
- **+Better maintainability**: Single point of control for workout operations
- **+Improved UX**: Single 1-10 rating vs complex multi-field feedback
- **+Smarter PRs**: Real-time calculation supporting both weight and reps progress
- **+Zero-friction pauses**: Simple status toggle without tracking overhead

### 🧹 Recent Cleanup (2025-06-28)
**Code Consistency Fixes:**
- ✅ **Controllers**: Fixed outdated `:pauses` includes, rewritten PersonalRecordsController for on-demand PRs
- ✅ **Serializers**: Updated WorkoutSerializer and WorkoutSetSerializer to use calculated PR fields  
- ✅ **Factories**: Updated test factories to remove deleted database fields
- ✅ **Migrations**: Removed redundant empty migration files
- ✅ **Models**: All references to deleted fields cleaned up
- ✅ **Documentation**: Frontend guide updated with accurate API structure and PR system
- ✅ **Unnecessary Tracking Removed**: Eliminated `followed_routine` and `completed_as_prescribed` fields

**Database State:**
- ✅ All simplification migrations executed successfully
- ✅ Schema updated to reflect actual structure (workout_rating, no PR fields, no pause table, no routine tracking)
- ✅ Foreign key constraints properly maintained

**Final Simplifications:**
- ❌ `followed_routine` - Users don't follow routines exactly, this was meaningless tracking
- ❌ `completed_as_prescribed` - Same reason, people adapt weights/reps naturally

### ⚠️ Performance Optimizations Needed
- Add database indexes for frequently queried fields
- Consider eager loading for nested associations
- Implement pagination for large datasets

### 🔒 Security Enhancements Recommended
- Validate ownership in nested resource controllers
- Sanitize search parameters to prevent injection
- Add HTTPS enforcement in production
- Consider implementing CSRF protection for state-changing operations