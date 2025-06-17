FactoryBot.define do
  factory :user_stat do
    association :user
    height { 180.5 }
    weight { 75.0 }
    age { 30 }
    gender { 'male' }
    fitness_goal { 'lose weight' }
    experience_level { 'beginner' }
    available_days { 3 }
    equipment_available { 'dumbbells' }
    activity_level { 'moderate' }
    physical_limitations { 'none' }
  end
end 