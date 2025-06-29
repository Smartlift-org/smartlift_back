# SmartLift API Architecture

## Overview

SmartLift API is a Ruby on Rails-based RESTful API designed to power a fitness tracking mobile application. The system follows a modular architecture with clear separation of concerns, making it scalable and maintainable.

## System Architecture

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Mobile App     │────▶│   Rails API     │────▶│   PostgreSQL    │
│ (React Native)  │     │  (Port 3000)    │     │  (Port 5433)    │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                               │                           │
                               ▼                           ▼
                        ┌─────────────────┐     ┌─────────────────┐
                        │     Redis       │     │   AI Service    │
                        │  (Port 6380)    │     │  (Port 4000)    │
                        └─────────────────┘     └─────────────────┘
```

## Technology Stack

### Core Technologies
- **Ruby**: 3.1.2
- **Rails**: 7.1.5 (API mode)
- **PostgreSQL**: 15.x
- **Redis**: 7.x
- **Docker**: For containerization
- **JWT**: For authentication

### Key Gems
- `jwt`: Token-based authentication
- `bcrypt`: Password encryption
- `rack-cors`: Cross-Origin Resource Sharing
- `rack-attack`: Rate limiting and security
- `active_model_serializers`: JSON serialization
- `rspec-rails`: Testing framework
- `factory_bot_rails`: Test data generation
- `whenever`: Cron job management

## Project Structure

```
smartlift_api/
├── app/
│   ├── controllers/        # API endpoints
│   │   ├── api/           # Versioned API controllers
│   │   │   └── v1/        # Version 1 endpoints
│   │   ├── workout/       # Workout-specific controllers
│   │   └── concerns/      # Shared controller logic
│   ├── models/            # ActiveRecord models
│   │   └── concerns/      # Shared model logic
│   ├── services/          # Business logic services
│   ├── serializers/       # JSON serializers
│   └── mailers/          # Email functionality
├── config/               # Application configuration
├── db/                   # Database files
│   ├── migrate/         # Database migrations
│   └── seeds.rb         # Seed data
├── lib/                 # Custom libraries
├── spec/                # RSpec tests
└── docs/                # Documentation
```

## Key Components

### 1. Authentication System

**JWT-based Authentication**
- Token generation in `JsonWebToken` class
- Token validation in `ApplicationController`
- User authentication in `AuthController`

```ruby
# Token generation flow
User Login → AuthController → JsonWebToken.encode → JWT Token
```

### 2. Workout Tracking System

**Core Models:**
- `Workout`: Main workout session
- `WorkoutExercise`: Exercise within a workout
- `WorkoutSet`: Individual set tracking
- `WorkoutPause`: Pause management

**State Machine:**
```
┌─────────────┐     pause      ┌─────────────┐
│ in_progress │───────────────▶│   paused    │
└─────────────┘                └─────────────┘
      │                              │
      │ complete                     │ resume
      ▼                              ▼
┌─────────────┐                ┌─────────────┐
│  completed  │                │ in_progress │
└─────────────┘                └─────────────┘
      │
      │ abandon
      ▼
┌─────────────┐
│  abandoned  │
└─────────────┘
```

### 3. AI Integration

**AI Workout Generation Flow:**
```
User Request → AiWorkoutRoutinesController → AiWorkoutRoutineService
                                                      │
                                                      ▼
                                              AiApiClient → External AI
                                                      │
                                                      ▼
                                              Parse Response → Validate
                                                      │
                                                      ▼
                                              Return Routine
```

**Key Components:**
- `AiWorkoutRoutineService`: Orchestrates AI routine generation
- `AiApiClient`: Handles external AI API communication
- Prompt engineering for workout generation
- Response parsing and validation

### 4. Exercise Management

**Exercise Database:**
- Pre-loaded exercise catalog (IDs: 98-970)
- Categorized by muscle groups and equipment
- Video URLs and instructions support

**Routine System:**
- Routines contain multiple exercises
- Support for supersets and circuit training
- Customizable sets, reps, and rest times

### 5. Performance Tracking

**Personal Records:**
- Automatic PR detection
- Multiple record types (max weight, max reps, etc.)
- Historical tracking

**Statistics:**
- Workout frequency and volume
- Progress over time
- Exercise popularity

## Database Design

### Key Tables

```sql
-- Users table
users
├── id
├── email
├── password_digest
├── name
├── role (member/trainer/admin)
└── timestamps

-- Workouts table
workouts
├── id
├── user_id
├── routine_id (optional)
├── workout_type (routine_based/free_style)
├── status
├── started_at
├── completed_at
└── performance_metrics

-- Exercises table
exercises
├── id
├── name
├── muscle_group
├── equipment
└── instructions

-- Workout tracking tables
workout_exercises
├── workout_id
├── exercise_id
└── performance_data

workout_sets
├── workout_exercise_id
├── weight
├── reps
├── rpe
└── timestamps
```

### Database Indexes

Performance-optimized indexes on:
- Foreign keys
- Timestamp fields for queries
- Status fields for filtering
- Composite indexes for complex queries

## API Design Principles

### 1. RESTful Design
- Resource-based URLs
- HTTP verbs for actions
- Consistent response formats

### 2. Version Management
- URL-based versioning (`/api/v1/`)
- Backward compatibility considerations

### 3. Error Handling
- Consistent error response format
- Meaningful error messages
- Proper HTTP status codes

### 4. Security
- JWT token expiration
- Rate limiting with Rack::Attack
- CORS configuration
- Parameter filtering

## Caching Strategy

### Redis Usage
- Session management
- API response caching
- Temporary data storage
- Background job queuing

### Cache Keys
```
user:<id>:active_workout
exercise:<id>:details
routine:<id>:exercises
stats:<user_id>:<period>
```

## Background Jobs

### Planned Job Types
- Email notifications
- Data aggregation
- Cleanup tasks
- Export generation

## Testing Strategy

### Test Coverage
- Unit tests for models
- Integration tests for controllers
- Service object tests
- Request specs for API endpoints

### Testing Tools
- RSpec for test framework
- FactoryBot for test data
- SimpleCov for coverage
- VCR for external API mocking

## Deployment Architecture

### Docker Configuration
```yaml
services:
  web:        # Rails application
  db:         # PostgreSQL database
  redis:      # Redis cache
```

### Environment Management
- Development: Docker Compose
- Staging: Kubernetes-ready
- Production: Scalable container orchestration

## Performance Considerations

### Database Optimization
- Eager loading to prevent N+1 queries
- Database indexes on frequently queried fields
- Query optimization in complex operations

### API Performance
- JSON serialization optimization
- Response pagination
- Selective field loading
- Caching frequently accessed data

## Security Measures

### Authentication & Authorization
- JWT tokens with expiration
- Role-based access control
- API key authentication for external services

### Data Protection
- Password encryption with bcrypt
- Parameter sanitization
- SQL injection prevention
- XSS protection

### Rate Limiting
```ruby
# config/initializers/rack_attack.rb
throttle("api/ip", limit: 100, period: 1.minute)
throttle("api/auth", limit: 10, period: 1.minute)
throttle("api/ai", limit: 5, period: 1.minute)
```

## Monitoring & Logging

### Application Logs
- Request/response logging
- Error tracking
- Performance metrics
- AI service interactions

### Health Checks
- Database connectivity
- Redis availability
- External service status

## Future Considerations

### Scalability
- Horizontal scaling support
- Database sharding readiness
- Microservices extraction points

### Feature Extensions
- WebSocket support for real-time updates
- GraphQL API layer
- Multi-tenancy support
- Advanced analytics engine

## Development Guidelines

### Code Organization
- Services for business logic
- Thin controllers
- Model concerns for shared behavior
- Clear separation of concerns

### Best Practices
- Follow Rails conventions
- Write comprehensive tests
- Document complex logic
- Use meaningful variable names
- Keep methods small and focused

### Git Workflow
- Feature branches
- Pull request reviews
- Continuous integration
- Semantic versioning 