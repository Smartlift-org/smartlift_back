# 🎯 TICKET #001: AI-Powered Workout Routine Generation

**Status:** 📋 Ready for Development  
**Priority:** 🔥 High  
**Estimated Time:** 12-16 hours  
**Sprint:** TBD  
**Assigned To:** TBD  
**Reviewer:** TBD  

---

## 🧾 **Title**
**Integrate AI-powered Workout Routine Generation**

---

## 📋 **Description**

Implement a backend service in Ruby on Rails that generates a weekly workout routine using a language model (GPT-based). The service should accept user fitness data, send a structured prompt to an external prediction API, and return a JSON routine along with an explanation in Spanish.

This feature will allow users to get personalized workout routines based on their fitness profile, available equipment, and goals, powered by AI and using the existing exercise database.

---

## 🎯 **Goal**

Create an endpoint that:

1. ✅ Accepts user fitness data as JSON input
2. ✅ Builds a formatted prompt (in English, with preferences/goal in Spanish)
3. ✅ Sends the prompt to an AI inference API (e.g., Replicate/OpenRouter)
4. ✅ Parses the AI response to extract:
   * A `<explicacion>` block in Spanish
   * A `<json>` block with the weekly routine
5. ✅ Returns both blocks to the frontend or stores them if needed
6. ✅ Validates exercise IDs against the existing exercise database
7. ✅ Handles errors gracefully with proper HTTP status codes

---

## 🔗 **API Endpoint**

```
POST /api/v1/ai/workout_routines
```

**Headers:**
```
Content-Type: application/json
Authorization: Bearer <jwt_token> (if authentication required)
```

---

## 📥 **Expected Input (JSON)**

```json
{
  "age": 30,
  "gender": "male", // "male", "female", "other"
  "weight": 80, // in kg
  "height": 175, // in cm
  "experience_level": "intermediate", // "beginner", "intermediate", "advanced"
  "equipment": ["dumbbell", "bodyweight"], // array of available equipment
  "preferences": "No cardio, solo tren superior", // user preferences in Spanish
  "frequency_per_week": 3, // 1-7 days
  "time_per_session": 45, // minutes per session
  "goal": "ganar masa muscular" // fitness goal in Spanish
}
```

---

## 🧠 **Prompt Template**

```text
You are a professional fitness trainer. Create a weekly workout routine based on the following user profile:

Age: {age}
Gender: {gender}
Weight: {weight}kg
Height: {height}cm
Experience level: {experience_level}
Available equipment: {equipment}
Preferences: {preferences}
Training frequency: {frequency_per_week} days per week
Session duration: {time_per_session} minutes
Goal: {goal}

IMPORTANT INSTRUCTIONS:
1. Use only exercise IDs from the provided exercise catalog
2. Create realistic sets, reps, and rest times based on the user's experience level
3. Ensure the routine matches the available equipment
4. Respect the session duration limit
5. Provide an explanation in Spanish
6. Return the response in the exact format specified below

FORMAT YOUR RESPONSE EXACTLY AS FOLLOWS:

<explicacion>
[Write a detailed explanation in Spanish about why this routine was designed this way, considering the user's goals, experience level, and preferences. Include tips and recommendations.]
</explicacion>

<json>
{
  "days": [
    {
      "day": "Monday",
      "routine": {
        "name": "Upper Body Strength",
        "description": "Focus on chest, shoulders and triceps",
        "difficulty": "intermediate",
        "duration": 45,
        "routine_exercises_attributes": [
          {
            "exercise_id": 12,
            "sets": 4,
            "reps": 10,
            "rest_time": 60,
            "order": 1
          }
        ]
      }
    }
  ]
}
</json>
```

---

## 🌐 **External AI API Integration**

**Endpoint:** `POST http://localhost:4000/api/v1/prediction/53773a52-4eac-42b8-a5d0-4f9aa5e20529`

**Request Headers:**
```
Content-Type: application/json
```

**Request Body:**
```json
{
  "question": "<formatted_prompt_here>"
}
```

**Expected Response:**
```html
<explicacion>
Esta rutina fue diseñada en base a tu nivel intermedio y tu objetivo de ganar masa muscular...
</explicacion>

<json>
{
  "days": [
    {
      "day": "Monday",
      "routine": {
        "name": "Upper Body Strength",
        "description": "Focus on chest, shoulders and triceps",
        "difficulty": "intermediate",
        "duration": 45,
        "routine_exercises_attributes": [
          {
            "exercise_id": 12,
            "sets": 4,
            "reps": 10,
            "rest_time": 60,
            "order": 1
          }
        ]
      }
    }
  ]
}
</json>
```

---

## 📤 **API Response Format**

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "explanation": "Esta rutina fue diseñada...",
    "routine": {
      "days": [
        {
          "day": "Monday",
          "routine": {
            "name": "Upper Body Strength",
            "description": "Focus on chest, shoulders and triceps",
            "difficulty": "intermediate",
            "duration": 45,
            "routine_exercises_attributes": [
              {
                "exercise_id": 12,
                "sets": 4,
                "reps": 10,
                "rest_time": 60,
                "order": 1
              }
            ]
          }
        }
      ]
    },
    "generated_at": "2024-12-25T10:30:00Z"
  }
}
```

**Error Responses:**
```json
// 400 Bad Request
{
  "success": false,
  "error": "Validation failed",
  "details": {
    "age": ["is required and must be between 13 and 100"],
    "equipment": ["must include at least one valid equipment type"]
  }
}

// 422 Unprocessable Entity
{
  "success": false,
  "error": "AI service returned invalid response",
  "details": "Could not parse JSON block from AI response"
}

// 503 Service Unavailable
{
  "success": false,
  "error": "AI service temporarily unavailable",
  "details": "Please try again later"
}
```

---

## 🛠️ **Technical Implementation Tasks**

### **Phase 1: Core Infrastructure**
- [ ] **1.1** Create `AiWorkoutRoutinesController` in `app/controllers/api/v1/`
- [ ] **1.2** Add route to `config/routes.rb`: `namespace :api, defaults: { format: :json } do namespace :v1 do post 'ai/workout_routines', to: 'ai_workout_routines#create' end end`
- [ ] **1.3** Create service class `AiWorkoutRoutineService` in `app/services/`
- [ ] **1.4** Create `AiApiClient` service for external API communication

### **Phase 2: Validation & Processing**
- [ ] **2.1** Implement input validation with strong parameters
- [ ] **2.2** Create prompt builder method with template interpolation
- [ ] **2.3** Add exercise ID validation against existing `Exercise` model
- [ ] **2.4** Implement equipment validation against available equipment types

### **Phase 3: AI Integration**
- [ ] **3.1** Configure HTTP client for AI API calls (using `net/http` or `httparty` gem)
- [ ] **3.2** Implement timeout and retry logic for external API calls
- [ ] **3.3** Add response parsing for `<explicacion>` and `<json>` blocks
- [ ] **3.4** Implement fallback handling for malformed AI responses

### **Phase 4: Error Handling & Testing**
- [ ] **4.1** Add comprehensive error handling for all failure scenarios
- [ ] **4.2** Implement logging for AI API calls and responses
- [ ] **4.3** Write unit tests for service classes
- [ ] **4.4** Write integration tests for the controller endpoint
- [ ] **4.5** Add request/response examples to API documentation

### **Phase 5: Security & Performance**
- [ ] **5.1** Add rate limiting for AI endpoint (if needed)
- [ ] **5.2** Implement caching strategy for repeated requests
- [ ] **5.3** Add authentication if required
- [ ] **5.4** Validate and sanitize all user inputs

---

## 📁 **Files to Create/Modify**

### **New Files:**
```
app/controllers/api/v1/ai_workout_routines_controller.rb
app/services/ai_workout_routine_service.rb
app/services/ai_api_client.rb
spec/controllers/api/v1/ai_workout_routines_controller_spec.rb
spec/services/ai_workout_routine_service_spec.rb
spec/services/ai_api_client_spec.rb
```

### **Modified Files:**
```
config/routes.rb
Gemfile (if adding HTTP client gems)
```

---

## 🔍 **Technical Considerations**

### **Database Integration:**
- Use existing `Exercise` model for validation
- Exercise IDs in AI response must exist in the database
- Current database has 873+ exercises imported from free-exercise-db

### **Performance:**
- AI API calls may take 5-15 seconds
- Consider implementing async processing for better UX
- Add timeout limits (30-60 seconds)

### **Error Scenarios:**
1. **Invalid Input:** Age out of range, invalid equipment types
2. **AI Service Down:** External API unavailable
3. **Malformed Response:** AI returns invalid HTML/JSON
4. **Invalid Exercise IDs:** AI suggests non-existent exercises
5. **Timeout:** AI service takes too long to respond

### **Security:**
- Sanitize all user inputs to prevent prompt injection
- Validate exercise IDs to prevent database attacks
- Rate limit to prevent abuse

---

## 🧪 **Testing Strategy**

### **Unit Tests:**
- Service classes with mocked external API calls
- Input validation with various valid/invalid scenarios
- Response parsing with different AI response formats

### **Integration Tests:**
- Full controller flow with stubbed AI responses
- Error handling scenarios
- Authentication flow (if implemented)

### **Manual Testing:**
- Test with actual AI service during development
- Verify Spanish explanations are coherent
- Test with different user profiles and equipment combinations

---

## 📝 **Acceptance Criteria**

- [ ] ✅ Endpoint accepts JSON input with all required fields
- [ ] ✅ Input validation returns clear error messages
- [ ] ✅ AI prompt is correctly formatted and sent to external service
- [ ] ✅ AI response is parsed correctly to extract explanation and routine
- [ ] ✅ Exercise IDs are validated against the database
- [ ] ✅ Success response includes both explanation (Spanish) and routine (JSON)
- [ ] ✅ Error handling covers all major failure scenarios
- [ ] ✅ Response times are reasonable (< 60 seconds)
- [ ] ✅ Unit and integration tests achieve >90% coverage
- [ ] ✅ Documentation is updated with API endpoint details

---

## 🚀 **Future Enhancements**

1. **Routine Storage:** Save generated routines to user's profile
2. **Routine Customization:** Allow users to modify AI-generated routines
3. **Progress Tracking:** Integrate with existing workout tracking system
4. **Multiple AI Models:** Support different AI providers for comparison
5. **Caching:** Cache responses for identical user profiles
6. **Analytics:** Track popular equipment combinations and goals

---

## 📚 **Technical Analysis & Architecture Insights**

### **Current SmartLift API Structure Analysis:**

**Existing Models:**
- `Exercise` model with 873+ exercises from free-exercise-db
- `Routine` and `RoutineExercise` models for user-created routines
- `Workout`, `WorkoutExercise`, `WorkoutSet` models for tracking
- User authentication with JWT tokens

**Current API Patterns:**
- RESTful endpoints with JSON responses
- Nested resources (routines/exercises, workouts/sets)
- Strong parameter validation
- Serialized responses with computed fields

**Integration Points:**
- The AI-generated routine should use the same `routine_exercises_attributes` format as the existing `Routine` model
- Exercise IDs must reference existing exercises in the database
- Response format should be consistent with other API endpoints

### **Recommended Implementation Strategy:**

1. **Service-Oriented Architecture:**
   - Keep business logic in service classes
   - Thin controllers that delegate to services
   - Separate concerns: validation, AI communication, response parsing

2. **Error Handling Strategy:**
   - Use Rails' built-in error handling patterns
   - Return consistent error response format
   - Log detailed errors for debugging

3. **Testing Approach:**
   - Mock external AI API calls in tests
   - Use factories for test data generation
   - Test edge cases and error scenarios

---

## 📝 **Development Log**

**2024-12-25** - Diego Costa  
Ticket created with comprehensive technical analysis. Analyzed existing codebase structure including Exercise model (873+ exercises), Routine model with nested attributes, and current API patterns. Ready for development phase.

---

**Created:** 2024-12-25  
**Last Updated:** 2024-12-25 