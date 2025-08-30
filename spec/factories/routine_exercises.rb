FactoryBot.define do
  factory :routine_exercise do
    association :routine
    association :exercise
    sets { 3 }
    reps { 12 }
    rest_time { 60 }
    sequence(:order) { |n| n }

    trait :with_long_rest do
      rest_time { 120 }
    end

    trait :with_high_volume do
      sets { 5 }
      reps { 15 }
    end
  end
end
