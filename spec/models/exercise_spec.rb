require 'rails_helper'

RSpec.describe Exercise, type: :model do
  describe 'associations' do
    it { should belong_to(:user).optional }
    it { should have_many(:routine_exercises).dependent(:destroy) }
    it { should have_many(:routines).through(:routine_exercises) }
  end

  describe 'validations' do
    subject { build(:exercise) }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:category) }
    it { should validate_presence_of(:level) }
    it { should validate_presence_of(:instructions) }
  end
end 