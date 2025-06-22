require 'rails_helper'

RSpec.describe WorkoutExercise, type: :model do
  let(:user) { create(:user) }
  let(:routine) { create(:routine, user: user) }
  let(:workout) { create(:workout, user: user, routine: routine) }
  let(:exercise) { create(:exercise) }

  describe 'associations' do
    it { should belong_to(:workout) }
    it { should belong_to(:exercise) }
    it { should belong_to(:routine_exercise).optional }
    it { should have_many(:sets).class_name('WorkoutSet').dependent(:destroy) }
  end

  describe 'validations' do
    subject { build(:workout_exercise, workout: workout, exercise: exercise) }

    it { should validate_numericality_of(:order).only_integer.is_greater_than(0) }
    it { should validate_inclusion_of(:group_type).in_array(WorkoutExercise::EXERCISE_GROUPS.keys) }
    it { should validate_numericality_of(:target_sets).only_integer.is_greater_than(0).allow_nil }
    it { should validate_numericality_of(:target_reps).only_integer.is_greater_than(0).allow_nil }
    it { should validate_numericality_of(:suggested_weight).is_greater_than(0).allow_nil }

    context 'when group_type is not regular' do
      subject { build(:workout_exercise, :superset, workout: workout, exercise: exercise) }
      it { should validate_numericality_of(:group_order).only_integer.is_greater_than(0) }
    end

    context 'when group_type is regular' do
      subject { build(:workout_exercise, :regular, workout: workout, exercise: exercise) }
      it { should_not validate_presence_of(:group_order) }
    end
  end

  describe 'scopes' do
    let!(:exercise1) { create(:workout_exercise, workout: workout, order: 1) }
    let!(:exercise2) { create(:workout_exercise, workout: workout, order: 2) }
    let!(:superset_ex1) { create(:workout_exercise, :superset, workout: workout, order: 3) }
    let!(:circuit_ex1) { create(:workout_exercise, :circuit, workout: workout, order: 4) }

    describe '.ordered' do
      it 'returns exercises ordered by order' do
        expect(WorkoutExercise.ordered).to eq([exercise1, exercise2, superset_ex1, circuit_ex1])
      end
    end

    describe '.supersets' do
      it 'returns only superset exercises' do
        expect(WorkoutExercise.supersets).to include(superset_ex1)
        expect(WorkoutExercise.supersets).not_to include(exercise1, exercise2, circuit_ex1)
      end
    end

    describe '.circuits' do
      it 'returns only circuit exercises' do
        expect(WorkoutExercise.circuits).to include(circuit_ex1)
        expect(WorkoutExercise.circuits).not_to include(exercise1, exercise2, superset_ex1)
      end
    end
  end

  describe 'callbacks' do
    describe 'on create' do
      it 'sets default order' do
        existing_exercise = create(:workout_exercise, workout: workout, order: 5)
        new_exercise = create(:workout_exercise, workout: workout, order: nil)
        expect(new_exercise.order).to eq(6)
      end

      it 'sets default group_order for non-regular exercises' do
        superset1 = create(:workout_exercise, :superset, workout: workout, group_order: nil)
        superset2 = create(:workout_exercise, :superset, workout: workout, group_order: nil)
        expect(superset1.group_order).to eq(1)
        expect(superset2.group_order).to eq(2)
      end

      it 'validates superset size' do
        superset1 = create(:workout_exercise, :superset, workout: workout, group_order: 1)
        superset2 = create(:workout_exercise, :superset, workout: workout, group_order: 1)
        superset3 = build(:workout_exercise, :superset, workout: workout, group_order: 1)
        
        expect(superset3).not_to be_valid
        expect(superset3.errors[:group_type]).to include("can only have 2 exercises in a superset")
      end
    end
  end

  describe 'instance methods' do
    let(:workout_exercise) { create(:workout_exercise, :with_completed_sets, workout: workout, target_sets: 3, target_reps: 10) }

    describe '#completed_sets_count' do
      it 'returns the number of completed sets' do
        expect(workout_exercise.completed_sets_count).to eq(3)
      end
    end

    describe '#total_volume' do
      it 'calculates total volume from completed sets' do
        workout_exercise.sets.each { |set| set.update!(weight: 50, reps: 10) }
        expect(workout_exercise.total_volume).to eq(1500) # 3 sets * 50kg * 10 reps
      end
    end

    describe '#average_weight' do
      it 'calculates average weight from completed sets' do
        workout_exercise.sets[0].update!(weight: 40)
        workout_exercise.sets[1].update!(weight: 50)
        workout_exercise.sets[2].update!(weight: 60)
        expect(workout_exercise.average_weight).to eq(50.0)
      end
    end

    describe '#average_reps' do
      it 'calculates average reps from completed sets' do
        workout_exercise.sets[0].update!(reps: 8)
        workout_exercise.sets[1].update!(reps: 10)
        workout_exercise.sets[2].update!(reps: 12)
        expect(workout_exercise.average_reps).to eq(10.0)
      end
    end

    describe '#average_rpe' do
      it 'calculates average RPE from completed sets' do
        workout_exercise.sets[0].update!(rpe: 6)
        workout_exercise.sets[1].update!(rpe: 8)
        workout_exercise.sets[2].update!(rpe: 10)
        expect(workout_exercise.average_rpe).to eq(8.0)
      end
    end

    describe '#completed_as_prescribed?' do
      context 'when all sets match targets' do
        it 'returns true' do
          workout_exercise.sets.each { |set| set.update!(reps: 10, weight: workout_exercise.suggested_weight) }
          expect(workout_exercise.completed_as_prescribed?).to be_truthy
        end
      end

      context 'when sets do not match targets' do
        it 'returns false' do
          workout_exercise.sets.first.update!(reps: 8) # Different from target
          expect(workout_exercise.completed_as_prescribed?).to be_falsey
        end
      end

      context 'when not all target sets are completed' do
        it 'returns false' do
          workout_exercise.sets.last.update!(completed: false)
          expect(workout_exercise.completed_as_prescribed?).to be_falsey
        end
      end
    end

    describe '#completed?' do
      it 'returns true when target sets are completed' do
        expect(workout_exercise.completed?).to be_truthy
      end

      it 'returns false when target sets are not completed' do
        workout_exercise.sets.last.update!(completed: false)
        expect(workout_exercise.completed?).to be_falsey
      end
    end

    describe '#in_progress?' do
      it 'returns true when some sets are completed but not all' do
        workout_exercise.sets.last.update!(completed: false)
        expect(workout_exercise.in_progress?).to be_truthy
      end

      it 'returns false when no sets are completed' do
        workout_exercise.sets.each { |set| set.update!(completed: false) }
        expect(workout_exercise.in_progress?).to be_falsey
      end
    end

    describe 'group type methods' do
      it '#regular? returns true for regular exercises' do
        regular_exercise = create(:workout_exercise, :regular, workout: workout)
        expect(regular_exercise.regular?).to be_truthy
      end

      it '#superset? returns true for superset exercises' do
        superset_exercise = create(:workout_exercise, :superset, workout: workout)
        expect(superset_exercise.superset?).to be_truthy
      end

      it '#circuit? returns true for circuit exercises' do
        circuit_exercise = create(:workout_exercise, :circuit, workout: workout)
        expect(circuit_exercise.circuit?).to be_truthy
      end
    end

    describe '#group_exercises' do
      it 'returns only itself for regular exercises' do
        regular_exercise = create(:workout_exercise, :regular, workout: workout)
        expect(regular_exercise.group_exercises).to eq([regular_exercise])
      end

      it 'returns all exercises in the same superset group' do
        superset1 = create(:workout_exercise, :superset, workout: workout, group_order: 1)
        superset2 = create(:workout_exercise, :superset, workout: workout, group_order: 1)
        expect(superset1.group_exercises).to contain_exactly(superset1, superset2)
      end
    end

    describe '#record_set' do
      let(:workout_exercise) { create(:workout_exercise, workout: workout) }

      it 'creates a new completed set' do
        expect {
          workout_exercise.record_set(weight: 80, reps: 12, rpe: 8)
        }.to change(workout_exercise.sets, :count).by(1)

        new_set = workout_exercise.sets.last
        expect(new_set.weight).to eq(80)
        expect(new_set.reps).to eq(12)
        expect(new_set.rpe).to eq(8)
        expect(new_set.completed).to be_truthy
      end
    end

    describe '#finalize!' do
      it 'sets completed_as_prescribed flag' do
        workout_exercise = create(:workout_exercise, :with_completed_sets, workout: workout)
        allow(workout_exercise).to receive(:completed_as_prescribed?).and_return(true)
        
        workout_exercise.finalize!
        expect(workout_exercise.completed_as_prescribed).to be_truthy
      end
    end
  end

  describe '#calculate_suggested_weight' do
    let(:workout_exercise) { create(:workout_exercise, workout: workout, exercise: exercise) }
    let(:previous_workout) { create(:workout, :completed, user: user) }

    it 'returns increased weight based on previous successful performance' do
      previous_exercise = create(:workout_exercise, workout: previous_workout, exercise: exercise)
      create(:workout_set, :completed, exercise: previous_exercise, weight: 80, set_type: 'normal')

      expected_weight = 80 * 1.025
      expect(workout_exercise.calculate_suggested_weight).to be_within(0.1).of(expected_weight)
    end

    it 'returns nil when no previous data exists' do
      expect(workout_exercise.calculate_suggested_weight).to be_nil
    end
  end
end 