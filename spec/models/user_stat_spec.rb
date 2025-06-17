require 'rails_helper'

RSpec.describe UserStat, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'validations' do
    subject { build(:user_stat) }
    it { should validate_presence_of(:height) }
    it { should validate_presence_of(:weight) }
    it { should validate_presence_of(:age) }
    it { should validate_presence_of(:gender) }
    it { should validate_presence_of(:fitness_goal) }
    it { should validate_presence_of(:experience_level) }
    it { should validate_presence_of(:available_days) }
    it { should validate_presence_of(:equipment_available) }
    it { should validate_presence_of(:activity_level) }
    it { should validate_presence_of(:physical_limitations) }
  end
end 