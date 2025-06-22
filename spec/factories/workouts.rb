FactoryBot.define do
  factory :workout do
    association :user
    association :routine
    workout_type { 'routine_based' }
    status { 'in_progress' }
    started_at { Time.current }
    perceived_intensity { rand(1..10) }
    energy_level { rand(1..10) }
    mood { 'good' }
    notes { 'Test workout notes' }
    skip_active_workout_validation { true }

    trait :routine_based do
      workout_type { 'routine_based' }
      association :routine
    end

    trait :free_style do
      workout_type { 'free_style' }
      name { 'Free Style Workout' }
      routine { nil }
    end

    trait :completed do
      status { 'completed' }
      completed_at { Time.current }
      total_duration_seconds { 3600 }
      total_volume { 1000.0 }
      total_sets_completed { 12 }
      total_exercises_completed { 4 }
      average_rpe { 7.5 }
      followed_routine { true }
    end

    trait :paused do
      status { 'paused' }
    end

    trait :abandoned do
      status { 'abandoned' }
      completed_at { Time.current }
    end

    trait :in_progress do
      status { 'in_progress' }
    end

    trait :with_exercises do
      after(:create) do |workout|
        create_list(:workout_exercise, 3, workout: workout)
      end
    end

    trait :with_pauses do
      after(:create) do |workout|
        create_list(:workout_pause, 2, workout: workout)
      end
    end

    trait :skip_validation do
      skip_active_workout_validation { true }
    end
  end
end 