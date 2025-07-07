FactoryBot.define do
  factory :user_stat do
    association :user
    height { 170 }
    weight { 70 }
    age { 30 }
    gender { 'male' }
    fitness_goal { 'lose_weight' }
    experience_level { 'beginner' }
    available_days { 3 }
    equipment_available { 'basic' }
    activity_level { 'moderate' }
    physical_limitations { 'none' }
  end
end 