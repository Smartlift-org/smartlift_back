#!/bin/bash

# Test script for AI Workout Routine endpoint with Docker Compose
# This script tests the AI endpoint when Rails is running in Docker

echo "🚀 Testing SmartLift AI Workout Routine Generation (Docker)"
echo "=========================================================="

# Default to localhost:3002 (Docker Compose mapped port)
BASE_URL=${BASE_URL:-"http://localhost:3002"}

echo "📍 Using base URL: $BASE_URL"
echo ""

# Test data
REQUEST_BODY='{
  "age": 28,
  "gender": "male",
  "weight": 75,
  "height": 178,
  "experience_level": "intermediate",
  "equipment": ["barbell", "dumbbell"],
  "preferences": "Enfoque en ejercicios compuestos",
  "frequency_per_week": 4,
  "time_per_session": 60,
  "goal": "ganar masa muscular y fuerza"
}'

echo "📤 Sending request to: $BASE_URL/api/v1/ai/workout_routines"
echo "📝 Request body:"
echo "$REQUEST_BODY" | jq '.' 2>/dev/null || echo "$REQUEST_BODY"
echo ""
echo "⏳ Waiting for AI response (this may take 10-20 seconds)..."
echo ""

# Make the request
response=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/api/v1/ai/workout_routines" \
  -H "Content-Type: application/json" \
  -d "$REQUEST_BODY")

# Extract HTTP status code and response body
http_code=$(echo "$response" | tail -n1)
response_body=$(echo "$response" | sed '$d')

echo "📥 Response received!"
echo "📊 HTTP Status Code: $http_code"
echo ""

# Pretty print the response if jq is available
if command -v jq &> /dev/null; then
    echo "📄 Response body:"
    echo "$response_body" | jq '.'
else
    echo "📄 Response body:"
    echo "$response_body"
fi

echo ""
echo "=========================================================="

# Provide helpful information based on status code
case $http_code in
    200)
        echo "✅ Success! AI workout routine generated successfully."
        ;;
    400)
        echo "❌ Bad Request - Check your input parameters."
        ;;
    503)
        echo "❌ Service Unavailable - AI service might be down or unreachable."
        echo "💡 Make sure the AI service is running on your host machine at port 3000."
        ;;
    500)
        echo "❌ Internal Server Error - Check Rails logs for details."
        echo "💡 Run: docker compose logs web"
        ;;
    *)
        echo "❓ Unexpected status code: $http_code"
        ;;
esac

echo ""
echo "🔍 To view Rails logs: docker compose logs -f web"
echo "🔍 To check AI service URL config: docker compose exec web rails runner 'puts AiApiClient::AI_SERVICE_URL'" 