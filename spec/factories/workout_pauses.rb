FactoryBot.define do
  factory :workout_pause do
    association :workout
    paused_at { Time.current }
    reason { 'Rest break' }

    trait :active do
      resumed_at { nil }
      duration_seconds { nil }
    end

    trait :completed do
      resumed_at { Time.current + 5.minutes }
      duration_seconds { 300 }
    end

    trait :short_break do
      reason { 'Water break' }
      resumed_at { Time.current + 2.minutes }
      duration_seconds { 120 }
    end

    trait :long_break do
      reason { 'Emergency pause' }
      resumed_at { Time.current + 15.minutes }
      duration_seconds { 900 }
    end
  end
end 