FactoryBot.define do
  factory :workout_set do
    association :exercise, factory: :workout_exercise
    sequence(:set_number) { |n| n }
    set_type { 'normal' }
    weight { 50.0 }
    reps { 10 }
    completed { false }

    trait :warm_up do
      set_type { 'warm_up' }
      weight { 30.0 }
      reps { 12 }
    end

    trait :normal do
      set_type { 'normal' }
    end

    trait :failure do
      set_type { 'failure' }
    end

    trait :completed do
      completed { true }
      completed_at { Time.current }
    end

    trait :in_progress do
      completed { false }
    end

    trait :heavy_weight do
      weight { 100.0 }
      completed { true }
      completed_at { Time.current }
    end

    trait :high_reps do
      reps { 15 }
      completed { true }
      completed_at { Time.current }
    end

    trait :high_volume do
      weight { 80.0 }
      reps { 12 }
      completed { true }
      completed_at { Time.current }
    end

    # Personal records traits - simplified to match current schema
    trait :personal_record do
      completed { true }
      completed_at { Time.current }
      weight { 100.0 }
      reps { 5 }
    end

    trait :weight_pr do
      completed { true }
      completed_at { Time.current }
      weight { 100.0 }
      reps { 5 }
    end

    trait :reps_pr do
      completed { true }
      completed_at { Time.current }
      weight { 80.0 }
      reps { 15 }
    end

    trait :volume_pr do
      completed { true }
      completed_at { Time.current }
      weight { 90.0 }
      reps { 12 }
    end
  end
end
