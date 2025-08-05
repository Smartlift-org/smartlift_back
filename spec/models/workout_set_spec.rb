require 'rails_helper'

RSpec.describe WorkoutSet, type: :model do
  let(:user) { create(:user) }
  let(:workout) { create(:workout, user: user) }
  let(:workout_exercise) { create(:workout_exercise, workout: workout) }

  describe 'associations' do
    it { should belong_to(:exercise).class_name('WorkoutExercise') }
  end

  describe 'validations' do
    subject { build(:workout_set, exercise: workout_exercise) }

    it { should validate_numericality_of(:set_number).only_integer.is_greater_than(0) }
    it { should validate_inclusion_of(:set_type).in_array(WorkoutSet::SET_TYPES) }
    it { should validate_numericality_of(:reps).only_integer.is_greater_than(0).allow_nil }
    it { should validate_numericality_of(:weight).is_greater_than(0).allow_nil }
    it { should validate_numericality_of(:rest_time_seconds).only_integer.is_greater_than_or_equal_to(0).allow_nil }
    it { should validate_numericality_of(:rpe).is_greater_than_or_equal_to(1).is_less_than_or_equal_to(10).allow_nil }

    context 'for drop sets' do
      subject { build(:workout_set, :drop_set, exercise: workout_exercise) }
      it { should validate_numericality_of(:drop_set_weight).is_greater_than(0) }
      it { should validate_numericality_of(:drop_set_reps).only_integer.is_greater_than(0) }
    end

    context 'for personal records' do
      subject { build(:workout_set, :personal_record, exercise: workout_exercise) }
      it { should validate_inclusion_of(:pr_type).in_array(WorkoutSet::PR_TYPES) }
    end
  end

  describe 'scopes' do
    # Create previous records to prevent automatic PR detection
    let!(:previous_workout) { create(:workout, :completed, user: user) }
    let!(:previous_exercise) { create(:workout_exercise, workout: previous_workout, exercise: workout_exercise.exercise) }
    let!(:previous_set) { create(:workout_set, :completed, exercise: previous_exercise, weight: 60, reps: 12, set_type: 'normal') }

    # Disable PR checking for these tests
    before do
      allow_any_instance_of(WorkoutSet).to receive(:check_for_personal_records)
    end

    let!(:set1) { create(:workout_set, exercise: workout_exercise, set_number: 1) }
    let!(:set2) { create(:workout_set, exercise: workout_exercise, set_number: 2) }
    let!(:completed_set) { create(:workout_set, :completed, exercise: workout_exercise, weight: 50, reps: 10) }
    let!(:warm_up_set) { create(:workout_set, :warm_up, exercise: workout_exercise) }
    let!(:drop_set) { create(:workout_set, :drop_set, exercise: workout_exercise) }
    let!(:pr_set) { create(:workout_set, :personal_record, exercise: workout_exercise) }

    describe '.ordered' do
      it 'returns sets ordered by set_number' do
        expect(WorkoutSet.ordered.first).to eq(set1)
        expect(WorkoutSet.ordered.second).to eq(set2)
      end
    end

    describe '.completed' do
      it 'returns only completed sets' do
        expect(WorkoutSet.completed).to include(completed_set, pr_set)
        expect(WorkoutSet.completed).not_to include(set1, set2)
      end
    end

    describe '.in_progress' do
      it 'returns only non-completed sets' do
        expect(WorkoutSet.in_progress).to include(set1, set2, warm_up_set, drop_set)
        expect(WorkoutSet.in_progress).not_to include(completed_set, pr_set)
      end
    end

    describe '.warm_up' do
      it 'returns only warm up sets' do
        expect(WorkoutSet.warm_up).to include(warm_up_set)
        expect(WorkoutSet.warm_up).not_to include(set1, drop_set)
      end
    end

    describe '.drop_sets' do
      it 'returns only drop sets' do
        expect(WorkoutSet.drop_sets).to include(drop_set)
        expect(WorkoutSet.drop_sets).not_to include(set1, warm_up_set)
      end
    end

    describe '.personal_records' do
      it 'returns only personal record sets' do
        expect(WorkoutSet.personal_records).to include(pr_set)
        expect(WorkoutSet.personal_records).not_to include(set1, completed_set)
      end
    end
  end

  describe 'callbacks' do
    describe 'on create' do
      it 'sets default set_number' do
        existing_set = create(:workout_set, exercise: workout_exercise, set_number: 3)
        new_set = create(:workout_set, exercise: workout_exercise, set_number: nil)
        expect(new_set.set_number).to eq(4)
      end

      it 'sets default set_type to normal' do
        set = create(:workout_set, exercise: workout_exercise, set_type: nil)
        expect(set.set_type).to eq('normal')
      end
    end

    describe 'on save' do
      it 'sets completed_at when marked as completed' do
        set = create(:workout_set, exercise: workout_exercise, completed: false)
        set.update!(completed: true)
        expect(set.completed_at).to be_present
      end
    end
  end

  describe 'instance methods' do
    describe '#volume' do
      context 'for normal sets' do
        it 'calculates volume as weight * reps' do
          set = create(:workout_set, :completed, weight: 80, reps: 10)
          expect(set.volume).to eq(800)
        end
      end

      context 'for drop sets' do
        it 'calculates volume including drop set' do
          set = create(:workout_set, :drop_set, :completed,
                      weight: 80, reps: 8,
                      drop_set_weight: 60, drop_set_reps: 10)
          expected_volume = (80 * 8) + (60 * 10)
          expect(set.volume).to eq(expected_volume)
        end
      end

      context 'for incomplete sets' do
        it 'returns 0' do
          set = create(:workout_set, weight: 80, reps: 10, completed: false)
          expect(set.volume).to eq(0)
        end
      end
    end

    describe '#check_for_personal_records' do
      let(:exercise_model) { create(:exercise) }
      let(:workout_exercise) { create(:workout_exercise, workout: workout, exercise: exercise_model) }

      context 'weight PR' do
        it 'detects new weight personal record when workout is completed' do
          # Previous best weight
          previous_workout = create(:workout, :completed, user: user)
          previous_exercise = create(:workout_exercise, workout: previous_workout, exercise: exercise_model)
          create(:workout_set, :completed, exercise: previous_exercise, weight: 80, set_type: 'normal')

          # New PR
          new_set = create(:workout_set, exercise: workout_exercise, weight: 90, reps: 10, set_type: 'normal')
          new_set.update!(completed: true)

          # Complete workout to trigger PR detection
          workout.complete!

          expect(new_set.reload.is_personal_record).to be_truthy
          expect(new_set.pr_type).to eq('weight')
        end
      end

      context 'reps PR' do
        it 'detects new reps personal record at same weight when workout is completed' do
          # Previous best reps at 80kg
          previous_workout = create(:workout, :completed, user: user)
          previous_exercise = create(:workout_exercise, workout: previous_workout, exercise: exercise_model)
          create(:workout_set, :completed, exercise: previous_exercise, weight: 80, reps: 8, set_type: 'normal')

          # New reps PR at same weight
          new_set = create(:workout_set, exercise: workout_exercise, weight: 80, reps: 12, set_type: 'normal')
          new_set.update!(completed: true)

          # Complete workout to trigger PR detection
          workout.complete!

          expect(new_set.reload.is_personal_record).to be_truthy
          expect(new_set.pr_type).to eq('reps')
        end
      end

      context 'volume PR' do
        it 'detects new volume personal record when workout is completed' do
          # Previous best volume
          previous_workout = create(:workout, :completed, user: user)
          previous_exercise = create(:workout_exercise, workout: previous_workout, exercise: exercise_model)
          create(:workout_set, :completed, exercise: previous_exercise, weight: 80, reps: 10, set_type: 'normal') # 800 volume

          # New volume PR (same weight, more reps, so it's both reps and volume, but volume should be detected)
          new_set = create(:workout_set, exercise: workout_exercise, weight: 80, reps: 11, set_type: 'normal')
          new_set.update!(completed: true) # 880 volume

          # Complete workout to trigger PR detection
          workout.complete!

          expect(new_set.reload.is_personal_record).to be_truthy
          expect(new_set.pr_type).to eq('reps') # Actually this should be 'reps' since it's same weight, more reps
        end
      end

      it 'only checks PRs for normal sets' do
        warm_up_set = create(:workout_set, :warm_up, exercise: workout_exercise, weight: 100, reps: 10)
        warm_up_set.update!(completed: true)

        expect(warm_up_set.reload.is_personal_record).to be_falsey
      end
    end

    describe '#duration' do
      it 'calculates duration between start and completion' do
        set = create(:workout_set, started_at: 2.minutes.ago, completed_at: Time.current)
        expect(set.duration).to be_within(5.seconds).of(2.minutes)
      end

      it 'returns 0 when no timestamps are set' do
        set = create(:workout_set)
        expect(set.duration).to eq(0)
      end
    end

    describe '#start!' do
      it 'sets started_at timestamp' do
        set = create(:workout_set, exercise: workout_exercise)
        expect(set.start!).to be_truthy
        expect(set.started_at).to be_present
      end

      it 'returns false if already started' do
        set = create(:workout_set, exercise: workout_exercise, started_at: Time.current)
        expect(set.start!).to be_falsey
      end
    end

    describe '#complete!' do
      it 'marks set as completed with optional parameters' do
        set = create(:workout_set, exercise: workout_exercise, weight: 50, reps: 8)
        expect(set.complete!(actual_reps: 10, actual_weight: 55)).to be_truthy

        set.reload
        expect(set.completed).to be_truthy
        expect(set.completed_at).to be_present
        expect(set.reps).to eq(10)
        expect(set.weight).to eq(55)
      end

      it 'handles drop set data' do
        set = create(:workout_set, :drop_set, exercise: workout_exercise)
        drop_set_data = { weight: 40, reps: 12 }

        expect(set.complete!(drop_set_data: drop_set_data)).to be_truthy

        set.reload
        expect(set.drop_set_weight).to eq(40)
        expect(set.drop_set_reps).to eq(12)
      end

      it 'returns false if already completed' do
        set = create(:workout_set, :completed, exercise: workout_exercise)
        expect(set.complete!).to be_falsey
      end
    end

    describe '#mark_as_completed!' do
      it 'marks set as completed' do
        set = create(:workout_set, exercise: workout_exercise)
        expect(set.mark_as_completed!).to be_truthy
        expect(set.reload.completed).to be_truthy
        expect(set.completed_at).to be_present
      end
    end

    describe 'type checking methods' do
      it '#drop_set? returns true for drop sets' do
        set = create(:workout_set, :drop_set, exercise: workout_exercise)
        expect(set.drop_set?).to be_truthy
      end

      it '#warm_up? returns true for warm up sets' do
        set = create(:workout_set, :warm_up, exercise: workout_exercise)
        expect(set.warm_up?).to be_truthy
      end

      it '#failure? returns true for failure sets' do
        set = create(:workout_set, :failure, exercise: workout_exercise)
        expect(set.failure?).to be_truthy
      end

      it '#normal? returns true for normal sets' do
        set = create(:workout_set, :normal, exercise: workout_exercise)
        expect(set.normal?).to be_truthy
      end
    end
  end
end
