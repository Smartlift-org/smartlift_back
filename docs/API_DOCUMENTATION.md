# SmartLift API Documentation

## Overview

The SmartLift API is a RESTful API built with Ruby on Rails that powers a fitness tracking mobile application. It manages workouts, routines, exercises, user progress, and integrates with AI services for personalized workout generation.

## Base URL

```
http://localhost:3000
```

## Authentication

The API uses JWT (JSON Web Token) for authentication. Most endpoints require a valid JWT token in the Authorization header.

### Authentication Header Format

```
Authorization: Bearer <jwt_token>
```

### Obtaining a Token

To obtain a JWT token, authenticate using the login endpoint with valid credentials.

## API Endpoints

### Health Check

#### GET /
Check API health status.

**Response:**
```json
{
  "status": "ok",
  "message": "SmartLift API is running",
  "version": "1.0.0"
}
```

### Authentication

#### POST /auth/login
Authenticate user and receive JWT token.

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "name": "John Doe",
    "role": "member"
  }
}
```

### Users

#### POST /users
Create a new user account.

**Request Body:**
```json
{
  "user": {
    "email": "newuser@example.com",
    "password": "securepassword",
    "name": "Jane Doe",
    "age": 25,
    "gender": "female",
    "weight": 65,
    "height": 170
  }
}
```

**Response:**
```json
{
  "id": 2,
  "email": "newuser@example.com",
  "name": "Jane Doe",
  "created_at": "2024-01-15T10:00:00Z"
}
```

#### GET /profile
Get current user's profile.

**Headers:**
- Authorization: Bearer <token>

**Response:**
```json
{
  "id": 1,
  "email": "user@example.com",
  "name": "John Doe",
  "role": "member",
  "age": 30,
  "gender": "male",
  "weight": 80,
  "height": 180,
  "created_at": "2024-01-01T10:00:00Z"
}
```

#### PATCH /users/:id
Update user information.

**Headers:**
- Authorization: Bearer <token>

**Request Body:**
```json
{
  "user": {
    "weight": 78,
    "height": 180
  }
}
```

### Exercises

#### GET /exercises
List all available exercises.

**Query Parameters:**
- `page` (optional): Page number for pagination
- `per_page` (optional): Items per page (default: 20)
- `muscle_group` (optional): Filter by muscle group
- `equipment` (optional): Filter by equipment type

**Response:**
```json
{
  "exercises": [
    {
      "id": 98,
      "name": "Barbell Bench Press",
      "muscle_group": "chest",
      "equipment": "barbell",
      "difficulty": "intermediate"
    },
    {
      "id": 99,
      "name": "Dumbbell Shoulder Press",
      "muscle_group": "shoulders",
      "equipment": "dumbbell",
      "difficulty": "beginner"
    }
  ],
  "meta": {
    "current_page": 1,
    "total_pages": 10,
    "total_count": 200
  }
}
```

#### GET /exercises/:id
Get exercise details.

**Response:**
```json
{
  "id": 98,
  "name": "Barbell Bench Press",
  "muscle_group": "chest",
  "equipment": "barbell",
  "difficulty": "intermediate",
  "instructions": "Lie on bench, grip bar at shoulder width...",
  "video_url": "https://example.com/videos/bench-press.mp4"
}
```

### Routines

#### GET /routines
List user's workout routines.

**Headers:**
- Authorization: Bearer <token>

**Response:**
```json
{
  "routines": [
    {
      "id": 1,
      "name": "Upper Body Strength",
      "description": "Focus on chest, back, and shoulders",
      "difficulty": "intermediate",
      "duration": 60,
      "exercises_count": 8,
      "created_at": "2024-01-10T10:00:00Z"
    }
  ]
}
```

#### GET /routines/:id
Get routine details with exercises.

**Headers:**
- Authorization: Bearer <token>

**Response:**
```json
{
  "id": 1,
  "name": "Upper Body Strength",
  "description": "Focus on chest, back, and shoulders",
  "difficulty": "intermediate",
  "duration": 60,
  "routine_exercises": [
    {
      "id": 1,
      "exercise_id": 98,
      "exercise_name": "Barbell Bench Press",
      "sets": 4,
      "reps": 10,
      "rest_time": 90,
      "order": 1,
      "group_type": "regular"
    }
  ]
}
```

#### POST /routines
Create a new routine.

**Headers:**
- Authorization: Bearer <token>

**Request Body:**
```json
{
  "routine": {
    "name": "Leg Day",
    "description": "Lower body workout",
    "difficulty": "intermediate",
    "duration": 45,
    "routine_exercises_attributes": [
      {
        "exercise_id": 150,
        "sets": 4,
        "reps": 12,
        "rest_time": 60,
        "order": 1
      }
    ]
  }
}
```

#### POST /routines/:routine_id/exercises
Add exercise to routine.

**Headers:**
- Authorization: Bearer <token>

**Request Body:**
```json
{
  "routine_exercise": {
    "exercise_id": 200,
    "sets": 3,
    "reps": 15,
    "rest_time": 45,
    "order": 2
  }
}
```

### Workouts

#### GET /workouts
List user's workouts.

**Headers:**
- Authorization: Bearer <token>

**Query Parameters:**
- `status` (optional): Filter by status (in_progress, completed, abandoned)
- `date_from` (optional): Filter workouts from date
- `date_to` (optional): Filter workouts to date

**Response:**
```json
{
  "workouts": [
    {
      "id": 1,
      "name": "Upper Body Strength",
      "workout_type": "routine_based",
      "status": "completed",
      "started_at": "2024-01-15T10:00:00Z",
      "completed_at": "2024-01-15T11:00:00Z",
      "total_duration_seconds": 3600,
      "total_volume": 5000,
      "total_sets_completed": 24
    }
  ]
}
```

#### POST /workouts
Start a routine-based workout.

**Headers:**
- Authorization: Bearer <token>

**Request Body:**
```json
{
  "workout": {
    "routine_id": 1
  }
}
```

#### POST /workouts/free
Start a free-style workout.

**Headers:**
- Authorization: Bearer <token>

**Request Body:**
```json
{
  "workout": {
    "name": "Quick Chest Workout"
  }
}
```

#### PUT /workouts/:id/pause
Pause active workout.

**Headers:**
- Authorization: Bearer <token>

**Request Body:**
```json
{
  "reason": "Water break"
}
```

#### PUT /workouts/:id/resume
Resume paused workout.

**Headers:**
- Authorization: Bearer <token>

#### PUT /workouts/:id/complete
Complete workout with feedback.

**Headers:**
- Authorization: Bearer <token>

**Request Body:**
```json
{
  "workout_rating": 8,
  "notes": "Great workout, increased weight on bench press",
  "total_duration_seconds": 3600
}
```

**Parameters:**
- `workout_rating` (integer, optional): Rating from 1-10
- `notes` (string, optional): Workout feedback notes
- `total_duration_seconds` (integer, required): Total workout duration in seconds as measured by frontend timer

### Workout Exercises

#### POST /workout/exercises/:id/record_set
Record a completed set.

**Headers:**
- Authorization: Bearer <token>

**Request Body:**
```json
{
  "set": {
    "weight": 80,
    "reps": 10,
    "rpe": 8,
    "notes": "Good form maintained"
  }
}
```

#### PUT /workout/exercises/:id/complete
Mark exercise as completed.

**Headers:**
- Authorization: Bearer <token>

### Workout Sets

#### PUT /workout/exercises/:exercise_id/sets/:id/start
Start a set timer.

**Headers:**
- Authorization: Bearer <token>

#### PUT /workout/exercises/:exercise_id/sets/:id/complete
Complete a started set.

**Headers:**
- Authorization: Bearer <token>

**Request Body:**
```json
{
  "weight": 100,
  "reps": 8,
  "rpe": 9
}
```

### Personal Records

#### GET /personal_records
Get user's personal records.

**Headers:**
- Authorization: Bearer <token>

**Response:**
```json
{
  "personal_records": [
    {
      "id": 1,
      "exercise_id": 98,
      "exercise_name": "Barbell Bench Press",
      "record_type": "max_weight",
      "value": 120,
      "achieved_at": "2024-01-15T10:30:00Z",
      "workout_id": 1
    }
  ]
}
```

#### GET /personal_records/by_exercise/:exercise_id
Get personal records for specific exercise.

**Headers:**
- Authorization: Bearer <token>

### User Stats

#### GET /user_stats
Get user's workout statistics.

**Headers:**
- Authorization: Bearer <token>

**Response:**
```json
{
  "total_workouts": 50,
  "total_volume": 250000,
  "total_duration_hours": 75,
  "current_streak": 5,
  "longest_streak": 15,
  "favorite_exercises": [
    {
      "exercise_id": 98,
      "exercise_name": "Barbell Bench Press",
      "times_performed": 45
    }
  ],
  "weekly_stats": {
    "workouts": 4,
    "volume": 20000,
    "duration_hours": 6
  }
}
```

### AI Workout Generation

#### POST /api/v1/ai/workout_routines
Generate personalized workout routine using AI.

**Note:** This endpoint uses API key authentication instead of JWT.

**Headers:**
- X-API-Key: <api_key>

**Request Body:**
```json
{
  "age": 25,
  "gender": "male",
  "weight": 80,
  "height": 180,
  "experience_level": "intermediate",
  "equipment": ["barbell", "dumbbell", "cables"],
  "preferences": "Focus on strength building, prefer compound movements",
  "frequency_per_week": 4,
  "time_per_session": 60,
  "goal": "Build muscle and increase strength"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "explanation": "Esta rutina está diseñada para maximizar el desarrollo muscular...",
    "routine": {
      "days": [
        {
          "day": "Monday",
          "routine": {
            "name": "Upper Body Push",
            "description": "Chest, shoulders, and triceps focus",
            "difficulty": "intermediate",
            "duration": 60,
            "routine_exercises_attributes": [
              {
                "exercise_id": 98,
                "sets": 4,
                "reps": 8,
                "rest_time": 120,
                "order": 1
              }
            ]
          }
        }
      ]
    },
    "generated_at": "2024-01-15T10:00:00Z"
  }
}
```

## Error Responses

The API returns consistent error responses:

### 400 Bad Request
```json
{
  "error": "Bad Request",
  "message": "Invalid parameters provided"
}
```

### 401 Unauthorized
```json
{
  "error": "Unauthorized",
  "message": "Invalid or expired token"
}
```

### 404 Not Found
```json
{
  "error": "Not Found",
  "message": "Resource not found"
}
```

### 422 Unprocessable Entity
```json
{
  "errors": {
    "field_name": ["validation error message"]
  }
}
```

### 500 Internal Server Error
```json
{
  "error": "Internal Server Error",
  "message": "An unexpected error occurred"
}
```

## Rate Limiting

The API implements rate limiting using Rack::Attack:
- 100 requests per minute per IP for general endpoints
- 10 requests per minute per IP for authentication endpoints
- 5 requests per minute per user for AI generation endpoints

## Pagination

List endpoints support pagination with these parameters:
- `page`: Page number (default: 1)
- `per_page`: Items per page (default: 20, max: 100)

Pagination metadata is included in responses:
```json
{
  "data": [...],
  "meta": {
    "current_page": 1,
    "total_pages": 5,
    "total_count": 100,
    "per_page": 20
  }
}
``` 