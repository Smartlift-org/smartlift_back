FactoryBot.define do
  factory :workout_set do
    association :exercise, factory: :workout_exercise
    sequence(:set_number) { |n| n }
    set_type { 'normal' }
    weight { 50.0 }
    reps { 10 }
    rpe { 7.0 }
    rest_time_seconds { 90 }
    completed { false }
    notes { 'Test set notes' }

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
      rpe { 10 }
    end

    trait :drop_set do
      set_type { 'drop_set' }
      drop_set_weight { 40.0 }
      drop_set_reps { 8 }
    end

    trait :completed do
      completed { true }
      completed_at { Time.current }
      started_at { 2.minutes.ago }
    end

    trait :in_progress do
      completed { false }
      started_at { 1.minute.ago }
    end

    trait :personal_record do
      is_personal_record { true }
      pr_type { 'weight' }
      completed { true }
      completed_at { Time.current }
    end

    trait :weight_pr do
      is_personal_record { true }
      pr_type { 'weight' }
      weight { 100.0 }
      completed { true }
      completed_at { Time.current }
    end

    trait :reps_pr do
      is_personal_record { true }
      pr_type { 'reps' }
      reps { 15 }
      completed { true }
      completed_at { Time.current }
    end

    trait :volume_pr do
      is_personal_record { true }
      pr_type { 'volume' }
      weight { 80.0 }
      reps { 12 }
      completed { true }
      completed_at { Time.current }
    end
  end
end 