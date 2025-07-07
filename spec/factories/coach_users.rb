FactoryBot.define do
  factory :coach_user do
    association :coach, factory: :user, role: :coach
    association :user,  factory: :user, role: :user
  end
end 