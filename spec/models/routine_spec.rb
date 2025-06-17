require 'rails_helper'

RSpec.describe Routine, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should have_many(:routine_exercises).dependent(:destroy) }
    it { should have_many(:exercises).through(:routine_exercises) }
  end

  describe 'validations' do
    subject { build(:routine) }

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:description) }
    it { should validate_presence_of(:level) }
    it { should validate_presence_of(:duration) }

    it "validates name uniqueness scoped to user" do
      should validate_uniqueness_of(:name).scoped_to(:user_id).case_insensitive
    end

    it "validates description length" do
      should validate_length_of(:description).is_at_least(10).is_at_most(1000)
    end

    it "validates level inclusion" do
      should validate_inclusion_of(:level).in_array(%w[beginner intermediate advanced])
    end

    it "validates duration is between 1 and 180 minutes" do
      should validate_numericality_of(:duration)
        .is_greater_than(0)
        .is_less_than_or_equal_to(180)
        .with_message("must be between 1 and 180 minutes")
    end
  end

  describe 'uniqueness' do
    subject { create(:routine) }
    it { should validate_uniqueness_of(:name).scoped_to(:user_id).case_insensitive }
  end

  describe 'nested attributes' do
    it { should accept_nested_attributes_for(:routine_exercises).allow_destroy(true) }
  end
end 