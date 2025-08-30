# Frontend Developer Guide: Workout System

## 📋 **Overview**

This guide explains how the SmartLift workout system works from a frontend perspective. It covers user flows, API endpoints, data structures, and UI/UX considerations for implementing the workout tracking features.

## 🏋️ **What is a Workout?**

A **Workout** is an active training session where users:
1. Follow a pre-planned routine OR create exercises on-the-fly
2. Track exercises, sets, reps, and weights in real-time
3. Can pause/resume the session with zero friction
4. Get instant personal record notifications (weight and reps PRs)
5. Rate their workout experience when finished (simple 1-10 scale)

## 🔄 **Workout Lifecycle**

```
CREATE → IN_PROGRESS → [PAUSED] → COMPLETED
                   ↓
                 ABANDONED
```

### **States Explained:**
- **`in_progress`**: Active workout, user is training
- **`paused`**: Temporarily stopped (bathroom, phone call, etc.)
- **`completed`**: Successfully finished with feedback
- **`abandoned`**: User quit without completing

## 👤 **User Journey & Flows**

### **Flow 1: Starting a Routine-Based Workout**
```
1. User browses routines → GET /routines
2. User selects routine → GET /routines/:id
3. User starts workout → POST /workouts { routine_id: X }
4. System copies routine exercises → automatic
5. Workout screen loads → GET /workouts/:id/exercises
```

### **Flow 2: Starting a Free-Style Workout**
```
1. User clicks "Free Workout" → POST /workouts/free { name: "Cardio Day" }
2. Empty workout created → workout_type: "free_style"
3. User adds exercises manually → POST /workouts/:id/exercises
```

### **Flow 3: Active Workout Session**
```
1. User performs exercise
2. User records set → POST /workouts/:id/exercises/:exercise_id/record_set
3. Repeat for all sets/exercises
4. User completes workout → PUT /workouts/:id/complete
5. User rates workout → { workout_rating: 8, notes: "Great session!" }
```

## 🔌 **API Endpoints**

### **Workout Management**
```http
# Create routine-based workout
POST /workouts
Body: { "routine_id": 123 }

# Create free-style workout  
POST /workouts/free
Body: { "name": "Upper Body Day" }

# Get workout details
GET /workouts/:id

# List user's workouts
GET /workouts

# Pause workout (ultra-simple)
PUT /workouts/:id/pause
Body: {} // No body required - instant pause

# Resume workout (ultra-simple)  
PUT /workouts/:id/resume
Body: {} // No body required - instant resume

# Complete workout with simple rating
PUT /workouts/:id/complete
Body: { 
  "workout_rating": 8,     // Required: 1-10 scale
  "notes": "New PR! 💪"    // Optional: user notes
}

# Abandon workout
PUT /workouts/:id/abandon
```

### **Exercise Management**
```http
# Get workout exercises
GET /workouts/:id/exercises

# Add exercise to workout
POST /workouts/:id/exercises
Body: {
  "exercise_id": 456,
  "target_sets": 3,
  "target_reps": 10,
  "suggested_weight": 60.5
}

# Update exercise
PUT /workouts/:id/exercises/:exercise_id
Body: { "target_sets": 4 }

# Remove exercise
DELETE /workouts/:id/exercises/:exercise_id

# Record a set
POST /workouts/:id/exercises/:exercise_id/record_set
Body: {
  "weight": 65.0,
  "reps": 8,
  "rpe": 7.5,
  "set_type": "normal"
}

# Mark exercise as completed
PUT /workouts/:id/exercises/:exercise_id/complete
```

## 📊 **Data Structures**

### **Workout Object** 
```json
{
  "id": 123,
  "user_id": 456,
  "routine_id": 789,
  "workout_type": "routine_based",
  "status": "in_progress",
  "name": "Push Day",
  "started_at": "2024-01-15T10:00:00Z",
  "completed_at": null,
  "workout_rating": null,     // 1-10 scale (only when completed)
  "notes": null,              // Optional completion notes
  "total_volume": 0,          // Sum of weight × reps for all sets
  "total_sets_completed": 0,
  "total_exercises_completed": 0,
  "total_duration_seconds": null,  // Simple: completed_at - started_at
  "average_rpe": null         // Average RPE across all sets
}
```

### **WorkoutExercise Object**
```json
{
  "id": 789,
  "workout_id": 123,
  "exercise_id": 456,
  "routine_exercise_id": 321,
  "order": 1,
  "group_type": "regular",
  "group_order": null,
  "target_sets": 3,
  "target_reps": 10,
  "suggested_weight": 60.0,
  "notes": null,
  "started_at": null,
  "completed_at": null,
  "exercise": {
    "id": 456,
    "name": "Bench Press",
    "equipment": "barbell",
    "category": "strength",
    "primary_muscles": ["chest", "triceps"],
    "secondary_muscles": ["shoulders"],
    "image_urls": ["https://..."]
  },
  "sets": []
}
```

### **WorkoutSet Object**
```json
{
  "id": 999,
  "workout_exercise_id": 789,
  "set_number": 1,
  "set_type": "normal",
  "weight": 65.0,
  "reps": 8,
  "rpe": 7.5,
  "rest_time_seconds": 120,
  "completed": true,
  "started_at": "2024-01-15T10:05:00Z",
  "completed_at": "2024-01-15T10:07:00Z",
  "notes": null,
  "drop_set_weight": null,     // For drop sets only
  "drop_set_reps": null,       // For drop sets only
  "volume": 520.0,             // weight × reps (calculated)
  "duration": 120,             // completed_at - started_at (calculated) 
  "is_personal_record": true,  // Calculated on-demand
  "pr_type": "weight",         // "weight", "reps", or "first_time"
  "pr_description": "New weight PR! Previous best: 60kg"
}
```

## 🎨 **UI/UX Considerations**

### **Workout Screen Layout**
```
┌─────────────────────────────────┐
│ 🏋️ Push Day            [⏸️][⏹️] │
│ Started: 10:00 AM                │
│ Duration: 00:45:30               │
├─────────────────────────────────┤
│ Exercise 1: Bench Press         │
│ Target: 3 sets × 10 reps        │
│ ┌─────┬─────┬─────┬─────┬─────┐ │
│ │Set 1│Set 2│Set 3│     │     │ │
│ │65kg │70kg │75kg│     │     │ │
│ │8reps│6reps│8rep│     │     │ │
│ │ ✅  │ ✅  │🏆PR│     │     │ │
│ └─────┴─────┴─────┴─────┴─────┘ │
│                                 │
│ 📊 Record Set:                  │
│ Weight: [75] kg (Prev: 70kg)    │
│ Reps: [8]                       │
│ RPE: [7] (optional)             │
│ Set Type: [Normal ▼]            │
│ [Record Set] 🎯                 │
│                                 │
│ 🎉 New Weight PR! +5kg          │
└─────────────────────────────────┘
```

### **Key UI Elements**

**1. Workout Header**
- Workout name/routine name
- Current status indicator
- Timer showing elapsed time
- Pause/Resume/Stop buttons

**2. Exercise Cards**
- Exercise name and image
- Target sets/reps display
- Progress visualization
- Set recording interface

**3. Set Recording**
- Weight input (with previous weight suggestion)
- Reps input
- Optional RPE slider (1-10)
- Set type selector (normal/warm-up/failure/drop-set)

**4. Rest Timer**
- Countdown timer between sets
- Customizable rest time
- Skip rest option

### **Set Types Explained**
- **`normal`**: Regular working set (counts for volume)
- **`warm_up`**: Preparatory set (lighter weight)
- **`failure`**: Set taken to muscle failure
- **`drop_set`**: Weight reduction within same set

## 🔄 **Real-Time Features**

### **Auto-Save**
- Sets are saved immediately when recorded
- No "save workout" button needed
- Offline support recommended

### **Progress Tracking**
- Visual progress bars for each exercise
- Set completion checkmarks
- Total volume calculations
- Personal record notifications

### **Personal Records Detection**
**🔥 PRs are calculated on-demand in real-time!** No pre-computed fields.

Personal records are detected for:
- **Weight PR**: Heavier than any previous set for this exercise
- **Reps PR**: More reps at same or heavier weight than before  
- **First Time**: First time performing this exercise

```javascript
// Record a set - PRs are calculated automatically
POST /workouts/${workoutId}/exercises/${exerciseId}/record_set
{
  "weight": 75.0,
  "reps": 8,
  "rpe": 7
}

// Response includes calculated PR information
{
  "id": 123,
  "weight": 75.0,
  "reps": 8,
  "volume": 600.0,
  "is_personal_record": true,
  "pr_type": "weight", 
  "pr_description": "New weight PR! Previous best: 72.5kg"
}

// Show celebration in UI  
if (response.is_personal_record) {
  showPRCelebration(response.pr_type, response.pr_description);
}
```

**PR Types:**
- `"weight"` - New heaviest weight for this exercise
- `"reps"` - More reps at same/heavier weight
- `"first_time"` - First time doing this exercise

### **Rest Timer**
- Automatic timer starts after recording set
- Push notifications when rest is complete
- Customizable rest periods per exercise

## ⚠️ **Error Handling**

### **Common Error Scenarios**
```javascript
// Cannot record set on inactive workout
{
  "error": "Workout is not active",
  "code": 400
}

// Cannot start new workout (user has active workout)
{
  "error": "You already have an active workout",
  "code": 422
}

// Invalid set data
{
  "errors": ["Weight must be greater than 0"],
  "code": 422
}
```

### **Offline Considerations**
- Cache active workout data locally
- Queue set recordings when offline
- Sync when connection restored
- Show offline indicator

## 📱 **Mobile-Specific Features**

### **Screen Wake Lock**
- Keep screen awake during workouts
- Important for timer visibility

### **Quick Actions**
- Swipe gestures for common actions
- Voice input for weights/reps
- Haptic feedback for confirmations

### **Notifications**
- Rest timer completion
- Workout milestones
- Personal record achievements

## 🎯 **Workout Completion Flow**

### **Completion Criteria**
A workout can be completed when:
- At least one set has been recorded
- User explicitly chooses to finish
- Can complete from `in_progress` OR `paused` status

### **Completion API**
```http
PUT /workouts/:id/complete
{
  "workout_rating": 8,        // Required: 1-10 scale  
  "notes": "Great session!"   // Optional: user notes
}
```

### **Completion UI**
```
┌─────────────────────────────────┐
│ 🎉 Workout Complete!            │
├─────────────────────────────────┤
│ How was your workout?           │
│                                 │
│ 😞  😐  😊  😄  🤩             │
│ 1   3   5   7   10              │
│ └───────●───────────┘           │
│                                 │
│ Notes (optional):               │
│ ┌─────────────────────────────┐ │
│ │ Great session! New PR 💪    │ │
│ └─────────────────────────────┘ │
│                                 │
│ [Complete Workout] ✅           │
└─────────────────────────────────┘
```

### **Rating Interpretation**
- **1-3**: Poor workout (red indicators)
- **4-6**: Average workout (yellow indicators) 
- **7-8**: Good workout (green indicators)
- **9-10**: Excellent workout (gold indicators)

### **Workout Summary**
Show immediately after completion:
- **Total duration** (simple: end time - start time)
- **Total volume lifted** (sum of all normal sets)
- **Sets completed** (count of completed sets)
- **Exercises completed** (count of exercises with ≥1 set)
- **Personal records achieved** (calculated on-demand)
- **Rating given** (1-10 with description)
- **Average RPE** (if user tracked RPE)

```javascript
// Example summary data
{
  "workout_id": 123,
  "duration": "1h 23m",
  "total_volume": "2,450 kg",
  "sets_completed": 18,
  "exercises_completed": 6,
  "personal_records": 2,
  "rating": 8,
  "rating_description": "Good workout",
  "average_rpe": 7.2
}
```

## 🔢 **Calculations**

### **Volume Calculation**
```javascript
// Per set (including drop sets)
if (set.set_type === 'drop_set') {
  volume = (weight × reps) + (drop_set_weight × drop_set_reps)
} else {
  volume = weight × reps
}

// Total workout volume (only normal sets count)
totalVolume = sum(all completed normal sets)

// Example: 3 sets of 70kg × 8 reps = 1,680kg total volume
```

### **Duration Calculation**
```javascript
// Simple total time from start to finish (pauses included)
duration = completed_at - started_at

// No complex pause tracking - keep it simple!
```

### **Personal Record Detection**
```javascript
// Weight PR: heavier than any previous set
const maxPreviousWeight = previousSets.reduce((max, set) => 
  Math.max(max, set.weight), 0)
const isWeightPR = currentWeight > maxPreviousWeight

// Reps PR: more reps at same or heavier weight  
const isRepsPR = previousSets.some(prevSet => 
  currentWeight >= prevSet.weight && currentReps > prevSet.reps)

// First time: no previous sets for this exercise
const isFirstTime = previousSets.length === 0
```

## 📈 **Analytics Endpoints**

```http
# User workout history
GET /workouts?status=completed&limit=20

# Personal records (calculated on-demand)
GET /personal_records
GET /personal_records/by_exercise/:exercise_id
GET /personal_records/recent      # Last month
GET /personal_records/latest?days=7&limit=10

# PR Statistics (all calculated dynamically)
GET /personal_records/statistics
# Returns:
{
  "total_prs": 145,
  "weight_prs": 89,
  "reps_prs": 51,
  "first_time_prs": 5,
  "exercises_with_prs": 23,
  "recent_prs_this_week": 4,
  "recent_prs_this_month": 12
}
```

## ⚡ **Important: On-Demand PR System**

**🚨 CRITICAL FOR FRONTEND DEVS:**

Personal records are **NOT stored in the database**. They are calculated in real-time when:
- Recording a new set (check if it's a PR)
- Fetching personal records endpoints
- Displaying workout summaries

**Performance Considerations:**
- PRs are calculated efficiently with indexed queries
- Frontend should cache PR results during active workout
- Show loading states when fetching PR statistics
- PR calculations happen server-side, not client-side

**Testing PR Logic:**
```javascript
// Test sequence for PR detection
1. Record baseline set: 50kg x 10 reps
2. Record weight PR: 55kg x 8 reps (should detect weight PR)
3. Record reps PR: 50kg x 12 reps (should detect reps PR) 
4. Record non-PR: 45kg x 8 reps (should not be PR)
```

## 🧪 **Testing Scenarios**

### **Happy Path**
1. Create routine-based workout
2. Record sets for all exercises  
3. Get PR notifications in real-time
4. Complete with rating (1-10)
5. Verify workout summary shows PRs

### **Edge Cases**
- Ultra-simple pause/resume (just status changes)
- Add/remove exercises mid-workout
- Record different set types (normal/warm_up/failure/drop_set)
- Handle network interruptions (cache workout state)
- Abandon workout (preserves recorded data)
- Empty notes on completion (should be allowed)

### **Performance**
- Large routines (10+ exercises)
- Long workouts (2+ hours) 
- Multiple rapid set recordings
- **PR calculation with large exercise history**
- Offline workout recording and sync

## 🔗 **Integration Points**

### **With Exercise Database**
- Exercise search and selection
- Exercise details and images
- Equipment filtering

### **With Routines**
- Routine selection and preview
- Template copying to workout

### **With User Profile**
- Previous weights suggestion
- Personal record tracking
- Workout history

---

## 💡 **Pro Tips for Implementation**

1. **Progressive Enhancement**: Start with basic set recording, add advanced features later
2. **Performance**: Minimize API calls during active workout
3. **UX**: Make common actions (record set) as fast as possible
4. **Persistence**: Save state frequently, users hate losing workout data
5. **Feedback**: Provide immediate visual feedback for all actions

## 🤝 **Backend Support**

The backend provides:
- ✅ Real-time set recording
- ✅ Automatic pause/resume tracking
- ✅ Personal record detection
- ✅ Volume calculations
- ✅ Data validation and error handling

Focus on creating a smooth, intuitive workout experience that encourages users to track consistently!