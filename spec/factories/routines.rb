FactoryBot.define do
  factory :routine do
    association :user
    sequence(:name) { |n| "Routine #{n}" }
    description { "A great workout routine" }
<<<<<<< HEAD
    level { "beginner" }
    duration { 45 }

    trait :intermediate do
      level { "intermediate" }
    end

    trait :advanced do
      level { "advanced" }
=======
    difficulty { "beginner" }
    duration { 45 }

    trait :intermediate do
      difficulty { "intermediate" }
    end

    trait :advanced do
      difficulty { "advanced" }
>>>>>>> develop
    end

    trait :with_exercises do
      after(:create) do |routine|
        create_list(:routine_exercise, 3, routine: routine)
      end
    end
  end
end 