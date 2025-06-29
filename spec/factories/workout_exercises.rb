FactoryBot.define do
  factory :workout_exercise do
    association :workout
    association :exercise
    association :routine_exercise
    sequence(:order) { |n| n }
    group_type { 'regular' }
    target_sets { 3 }
    target_reps { 10 }
    suggested_weight { 50.0 }
    notes { 'Test exercise notes' }

    trait :regular do
      group_type { 'regular' }
      group_order { nil }
    end

    trait :superset do
      group_type { 'superset' }
      group_order { 1 }
    end

    trait :circuit do
      group_type { 'circuit' }
      group_order { 1 }
    end

    trait :completed do
      completed_at { Time.current }
    end

    trait :with_sets do
      after(:create) do |workout_exercise|
        create_list(:workout_set, 3, exercise: workout_exercise)
      end
    end

    trait :with_completed_sets do
      after(:create) do |workout_exercise|
        create_list(:workout_set, 3, :completed, exercise: workout_exercise)
      end
    end

    trait :free_style do
      routine_exercise { nil }
    end
  end
end 