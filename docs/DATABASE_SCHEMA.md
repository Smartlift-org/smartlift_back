# SmartLift API Database Schema

## Overview

The SmartLift API uses PostgreSQL as its primary database. The schema is designed to efficiently track workouts, exercises, user progress, and support AI-generated routines.

## Entity Relationship Diagram

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Users     │────<│  Workouts   │>────│  Routines   │
└─────────────┘     └─────────────┘     └─────────────┘
      │                    │                    │
      │                    │                    │
      ▼                    ▼                    ▼
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│ User Stats  │     │  Workout    │     │  Routine    │
│             │     │ Exercises   │     │ Exercises   │
└─────────────┘     └─────────────┘     └─────────────┘
                           │                    │
                           │                    │
                           ▼                    ▼
                    ┌─────────────┐     ┌─────────────┐
                    │  Workout    │     │ Exercises   │
                    │    Sets     │     │             │
                    └─────────────┘     └─────────────┘
                           │
                           ▼
                    ┌─────────────┐
                    │  Workout    │
                    │   Pauses    │
                    └─────────────┘
```

## Tables

### users

Primary user account information.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK, NOT NULL | Primary key |
| email | string | NOT NULL, UNIQUE | User email |
| password_digest | string | NOT NULL | Encrypted password |
| name | string | | User's display name |
| role | string | DEFAULT 'member' | User role (member/trainer/admin) |
| age | integer | | User's age |
| gender | string | | User's gender |
| weight | float | | Weight in kg |
| height | float | | Height in cm |
| created_at | datetime | NOT NULL | Record creation timestamp |
| updated_at | datetime | NOT NULL | Record update timestamp |

**Indexes:**
- `index_users_on_email` (UNIQUE)

### exercises

Master list of all available exercises.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK, NOT NULL | Primary key (98-970 range) |
| name | string | NOT NULL | Exercise name |
| muscle_group | string | | Primary muscle group |
| equipment | string | | Required equipment |
| difficulty | string | | Difficulty level |
| instructions | text | | How to perform |
| video_url | string | | Instructional video URL |
| created_at | datetime | NOT NULL | Record creation timestamp |
| updated_at | datetime | NOT NULL | Record update timestamp |

**Indexes:**
- `index_exercises_on_muscle_group`
- `index_exercises_on_equipment`

### routines

Workout routine templates.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK, NOT NULL | Primary key |
| user_id | bigint | FK, NOT NULL | Creator/owner |
| name | string | NOT NULL | Routine name |
| description | text | | Routine description |
| difficulty | string | | Difficulty level |
| duration | integer | | Estimated duration (minutes) |
| is_public | boolean | DEFAULT false | Shareable routine |
| created_at | datetime | NOT NULL | Record creation timestamp |
| updated_at | datetime | NOT NULL | Record update timestamp |

**Indexes:**
- `index_routines_on_user_id`
- `index_routines_on_is_public`

### routine_exercises

Exercises within a routine.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK, NOT NULL | Primary key |
| routine_id | bigint | FK, NOT NULL | Parent routine |
| exercise_id | bigint | FK, NOT NULL | Exercise reference |
| sets | integer | | Target sets |
| reps | integer | | Target reps |
| weight | float | | Suggested weight (kg) |
| rest_time | integer | | Rest between sets (seconds) |
| order | integer | | Exercise order |
| group_type | string | DEFAULT 'regular' | regular/superset/circuit |
| group_order | integer | | Order within group |
| notes | text | | Exercise-specific notes |
| created_at | datetime | NOT NULL | Record creation timestamp |
| updated_at | datetime | NOT NULL | Record update timestamp |

**Indexes:**
- `index_routine_exercises_on_routine_id`
- `index_routine_exercises_on_exercise_id`
- `index_routine_exercises_on_routine_id_and_order`

### workouts

Individual workout sessions.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK, NOT NULL | Primary key |
| user_id | bigint | FK, NOT NULL | User performing workout |
| routine_id | bigint | FK | Source routine (optional) |
| workout_type | integer | DEFAULT 0 | 0=routine_based, 1=free_style |
| name | string | | Workout name (for free workouts) |
| status | string | NOT NULL | in_progress/paused/completed/abandoned |
| started_at | datetime | | Workout start time |
| completed_at | datetime | | Workout completion time |
| total_duration_seconds | integer | | Total duration (excluding pauses) |
| total_volume | float | | Total weight × reps |
| total_sets_completed | integer | | Completed sets count |
| total_exercises_completed | integer | | Completed exercises count |
| average_rpe | float | | Average rate of perceived exertion |
| workout_rating | integer | | User's overall workout rating (1-10) |
| notes | text | | Workout notes |
| created_at | datetime | NOT NULL | Record creation timestamp |
| updated_at | datetime | NOT NULL | Record update timestamp |

**Indexes:**
- `index_workouts_on_user_id`
- `index_workouts_on_routine_id`
- `index_workouts_on_status`
- `index_workouts_on_user_id_and_status`
- `index_workouts_on_completed_at`

### workout_exercises

Exercises performed in a workout.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK, NOT NULL | Primary key |
| workout_id | bigint | FK, NOT NULL | Parent workout |
| exercise_id | bigint | FK, NOT NULL | Exercise performed |
| routine_exercise_id | bigint | FK | Link to routine exercise |
| order | integer | | Exercise order |
| group_type | string | DEFAULT 'regular' | regular/superset/circuit |
| group_order | integer | | Order within group |
| target_sets | integer | | Target number of sets |
| target_reps | integer | | Target reps per set |
| suggested_weight | float | | Suggested weight (kg) |
| completed_sets_count | integer | DEFAULT 0 | Actual completed sets |
| total_volume | float | | Total weight × reps for exercise |
| average_rpe | float | | Average RPE across sets |
| status | string | DEFAULT 'pending' | pending/in_progress/completed |
| started_at | datetime | | When exercise started |
| completed_at | datetime | | When exercise completed |
| notes | text | | Exercise-specific notes |
| created_at | datetime | NOT NULL | Record creation timestamp |
| updated_at | datetime | NOT NULL | Record update timestamp |

**Indexes:**
- `index_workout_exercises_on_workout_id`
- `index_workout_exercises_on_exercise_id`
- `index_workout_exercises_on_workout_id_and_order`

### workout_sets

Individual sets within a workout exercise.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK, NOT NULL | Primary key |
| workout_exercise_id | bigint | FK, NOT NULL | Parent workout exercise |
| set_number | integer | NOT NULL | Set number (1, 2, 3...) |
| set_type | string | DEFAULT 'normal' | normal/warmup/drop/failure |
| target_reps | integer | | Target reps for this set |
| weight | float | | Weight used (kg) |
| reps | integer | | Actual reps completed |
| rpe | integer | | Rate of perceived exertion (1-10) |
| rest_time | integer | | Rest after set (seconds) |
| status | string | DEFAULT 'pending' | pending/in_progress/completed/skipped |
| started_at | datetime | | Set start time |
| completed_at | datetime | | Set completion time |
| duration_seconds | integer | | Set duration |
| notes | text | | Set-specific notes |
| created_at | datetime | NOT NULL | Record creation timestamp |
| updated_at | datetime | NOT NULL | Record update timestamp |

**Indexes:**
- `index_workout_sets_on_workout_exercise_id`
- `index_workout_sets_on_workout_exercise_id_and_set_number` (UNIQUE)
- `index_workout_sets_on_completed_at`
- `index_workout_sets_on_status`

### workout_pauses

Pause tracking for workouts.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK, NOT NULL | Primary key |
| workout_id | bigint | FK, NOT NULL | Parent workout |
| paused_at | datetime | NOT NULL | When pause started |
| resumed_at | datetime | | When workout resumed |
| duration_seconds | integer | | Pause duration |
| reason | string | | Reason for pause |
| created_at | datetime | NOT NULL | Record creation timestamp |
| updated_at | datetime | NOT NULL | Record update timestamp |

**Indexes:**
- `index_workout_pauses_on_workout_id`
- `index_workout_pauses_on_paused_at`

### user_stats

Aggregated user statistics.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK, NOT NULL | Primary key |
| user_id | bigint | FK, NOT NULL, UNIQUE | User reference |
| total_workouts | integer | DEFAULT 0 | Total completed workouts |
| total_volume | float | DEFAULT 0 | Total weight lifted (kg) |
| total_duration_minutes | integer | DEFAULT 0 | Total workout time |
| current_streak | integer | DEFAULT 0 | Current workout streak |
| longest_streak | integer | DEFAULT 0 | Longest workout streak |
| last_workout_at | datetime | | Last workout date |
| favorite_exercise_id | bigint | FK | Most performed exercise |
| personal_records_count | integer | DEFAULT 0 | Total PRs achieved |
| created_at | datetime | NOT NULL | Record creation timestamp |
| updated_at | datetime | NOT NULL | Record update timestamp |

**Indexes:**
- `index_user_stats_on_user_id` (UNIQUE)

### coach_users

Relationship between trainers and members.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK, NOT NULL | Primary key |
| coach_id | bigint | FK, NOT NULL | Trainer user ID |
| user_id | bigint | FK, NOT NULL | Member user ID |
| status | string | DEFAULT 'active' | active/inactive |
| started_at | datetime | | Relationship start date |
| ended_at | datetime | | Relationship end date |
| created_at | datetime | NOT NULL | Record creation timestamp |
| updated_at | datetime | NOT NULL | Record update timestamp |

**Indexes:**
- `index_coach_users_on_coach_id`
- `index_coach_users_on_user_id`
- `index_coach_users_on_coach_id_and_user_id` (UNIQUE)

## Personal Records (Future Table)

Planned table for tracking personal records.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK, NOT NULL | Primary key |
| user_id | bigint | FK, NOT NULL | User reference |
| exercise_id | bigint | FK, NOT NULL | Exercise reference |
| workout_id | bigint | FK | Workout where achieved |
| workout_set_id | bigint | FK | Specific set reference |
| record_type | string | NOT NULL | max_weight/max_reps/max_volume |
| value | float | NOT NULL | Record value |
| previous_value | float | | Previous record value |
| achieved_at | datetime | NOT NULL | When record was set |
| created_at | datetime | NOT NULL | Record creation timestamp |
| updated_at | datetime | NOT NULL | Record update timestamp |

## Database Conventions

### Naming Conventions
- Tables: plural, snake_case (e.g., `workout_exercises`)
- Columns: singular, snake_case (e.g., `user_id`)
- Foreign keys: `<table>_id` (e.g., `workout_id`)
- Join tables: alphabetical order (e.g., `exercises_routines`)

### Data Types
- IDs: `bigint` (for future scaling)
- Timestamps: `datetime` with timezone
- Money/Weight: `float` (consider `decimal` for precision)
- Status fields: `string` with validations

### Performance Considerations
- Index all foreign keys
- Composite indexes for common query patterns
- Partial indexes for filtered queries
- Consider partitioning for large tables (workouts, workout_sets)

### Data Integrity
- Foreign key constraints at database level
- NOT NULL constraints for required fields
- UNIQUE constraints for business rules
- Check constraints for valid ranges

## Migration Best Practices

1. **Always include rollback logic**
   ```ruby
   def up
     add_column :users, :timezone, :string
   end
   
   def down
     remove_column :users, :timezone
   end
   ```

2. **Add indexes in separate migrations for large tables**
   ```ruby
   # Migration 1: Add column
   add_column :workouts, :total_volume, :float
   
   # Migration 2: Add index
   add_index :workouts, :total_volume
   ```

3. **Use database transactions**
   ```ruby
   def change
     ActiveRecord::Base.transaction do
       # Multiple operations
     end
   end
   ```

4. **Consider data migrations separately**
   ```ruby
   # Structure migration
   add_column :users, :role, :string
   
   # Data migration (separate file)
   User.update_all(role: 'member')
   ```

## Future Schema Considerations

### Planned Tables
- `personal_records` - Track user PRs
- `notifications` - User notifications
- `social_posts` - Social feed
- `workout_templates` - Shareable workout templates
- `exercise_videos` - Custom exercise videos
- `nutrition_logs` - Nutrition tracking

### Potential Optimizations
- Materialized views for statistics
- Read replicas for heavy queries
- Table partitioning for time-series data
- Archive old workout data 