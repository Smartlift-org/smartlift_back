require 'rails_helper'

RSpec.describe RoutineExercise, type: :model do
  describe "associations" do
    it { should belong_to(:routine) }
    it { should belong_to(:exercise) }
  end

  describe "validations" do
    subject { build(:routine_exercise) }

    it { should validate_presence_of(:sets) }
    it { should validate_presence_of(:reps) }
    it { should validate_presence_of(:rest_time) }
    it { should validate_presence_of(:order) }

    it "validates sets is between 1 and 20" do
      should validate_numericality_of(:sets)
        .is_greater_than(0)
        .is_less_than_or_equal_to(20)
        .with_message("must be between 1 and 20")
    end

    it "validates reps is between 1 and 100" do
      should validate_numericality_of(:reps)
        .is_greater_than(0)
        .is_less_than_or_equal_to(100)
        .with_message("must be between 1 and 100")
    end

    it "validates rest_time is between 0 and 600" do
      should validate_numericality_of(:rest_time)
        .is_greater_than_or_equal_to(0)
        .is_less_than_or_equal_to(600)
        .with_message("must be between 0 and 600 seconds")
    end

    it "validates order is greater than 0" do
      should validate_numericality_of(:order)
        .is_greater_than(0)
        .with_message("must be greater than 0")
    end
  end

  describe "uniqueness" do
    subject { build(:routine_exercise) }
    it { should validate_uniqueness_of(:order).scoped_to(:routine_id).with_message("must be unique within the routine. Please use the next available order number.") }
  end
end 