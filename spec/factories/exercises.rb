FactoryBot.define do
  factory :exercise do
    sequence(:name) { |n| "Exercise #{n}" }
    level { "beginner" }
    instructions { Faker::Lorem.paragraphs(number: 3).join("\n") }
    primary_muscles { ["chest", "back", "legs", "shoulders", "arms", "core"].sample(2) }
    images { ["exercise1.jpg", "exercise2.jpg"] }

    trait :intermediate do
      level { "intermediate" }
    end

    trait :advanced do
      level { "advanced" }
    end
  end
end 