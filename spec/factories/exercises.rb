FactoryBot.define do
  factory :exercise do
    sequence(:id) { |n| (98 + (n % 873)) } # Ensures IDs are between 98 and 970
    sequence(:name) { |n| "Exercise #{n}" }
    equipment { ["barbell", "dumbbell", "kettlebell", "bodyweight", "machine", "cable"].sample }
    category { ["strength", "cardio", "flexibility", "balance"].sample }
<<<<<<< HEAD
=======
    difficulty { "beginner" }
>>>>>>> develop
    instructions { Faker::Lorem.paragraphs(number: 3).join("\n") }
    primary_muscles { ["chest", "back", "legs", "shoulders", "arms", "core"].sample(2) }
    secondary_muscles { ["chest", "back", "legs", "shoulders", "arms", "core"].sample(2) }
    force { ["pull", "push", "static"].sample }
    mechanic { ["compound", "isolation"].sample }
    images { ["exercise1.jpg", "exercise2.jpg"] }
<<<<<<< HEAD
    level { "beginner" }

    trait :intermediate do
      level { "intermediate" }
    end

    trait :advanced do
      level { "advanced" }
=======

    trait :intermediate do
      difficulty { "intermediate" }
    end

    trait :advanced do
      difficulty { "advanced" }
>>>>>>> develop
    end
  end
end 