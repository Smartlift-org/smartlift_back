require 'rails_helper'

RSpec.describe Workout, type: :model do
  let(:user) { create(:user) }
  let(:routine) { create(:routine, user: user) }

  describe 'associations' do
    it { should belong_to(:user).required }
    
    context 'for free-style workouts' do
      subject { build(:workout, :free_style) }
      it { should belong_to(:routine).optional }
    end

    it { should have_many(:exercises).class_name('WorkoutExercise').dependent(:destroy) }
    it { should have_many(:pauses).class_name('WorkoutPause').dependent(:destroy) }
    it { should have_many(:performed_exercises).through(:exercises).source(:exercise) }
  end

  describe 'validations' do
    context 'for routine-based workouts' do
      subject { build(:workout, :routine_based, user: user, routine: routine) }

      it { should validate_presence_of(:routine) }
      it { should validate_inclusion_of(:status).in_array(Workout::STATUSES) }
      it { should validate_inclusion_of(:perceived_intensity).in_range(1..10).allow_nil }
      it { should validate_inclusion_of(:energy_level).in_range(1..10).allow_nil }
    end

    context 'for free-style workouts' do
      subject { build(:workout, :free_style, user: user) }

      it { should validate_presence_of(:name) }
      it { should_not validate_presence_of(:routine) }
    end

    it 'validates one active workout per user' do
      create(:workout, user: user, status: 'in_progress', skip_active_workout_validation: true)
      new_workout = build(:workout, user: user, skip_active_workout_validation: false)
      expect(new_workout).not_to be_valid
      expect(new_workout.errors[:base]).to include('You already have an active workout')
    end
  end

  describe 'enums' do
    it { should define_enum_for(:workout_type).with_values(routine_based: 0, free_style: 1) }
  end

  describe 'scopes' do
    let!(:routine_workout) { create(:workout, :routine_based, :skip_validation, user: user) }
    let!(:free_workout) { create(:workout, :free_style, :skip_validation, user: user) }
    let!(:completed_workout) { create(:workout, :completed, :skip_validation, user: user) }
    let!(:paused_workout) { create(:workout, :paused, :skip_validation, user: user) }

    describe '.recent' do
      it 'orders workouts by created_at desc' do
        expect(Workout.recent.first).to eq(paused_workout)
      end
    end

    describe '.with_routine' do
      it 'returns only routine-based workouts' do
        expect(Workout.with_routine).to include(routine_workout)
        expect(Workout.with_routine).not_to include(free_workout)
      end
    end

    describe '.free_workouts' do
      it 'returns only free-style workouts' do
        expect(Workout.free_workouts).to include(free_workout)
        expect(Workout.free_workouts).not_to include(routine_workout)
      end
    end

    describe '.active' do
      it 'returns workouts that are in progress or paused' do
        expect(Workout.active).to include(routine_workout, free_workout, paused_workout)
        expect(Workout.active).not_to include(completed_workout)
      end
    end

    describe '.completed' do
      it 'returns only completed workouts' do
        expect(Workout.completed).to include(completed_workout)
        expect(Workout.completed).not_to include(routine_workout, free_workout, paused_workout)
      end
    end
  end

  describe 'callbacks' do
    context 'on create' do
      it 'sets default status' do
        workout = create(:workout, user: user, routine: routine, status: nil)
        expect(workout.status).to eq('in_progress')
      end

      it 'sets started_at' do
        workout = create(:workout, user: user, routine: routine, started_at: nil)
        expect(workout.started_at).to be_present
      end

      it 'sets default workout_type based on routine presence' do
        routine_workout = create(:workout, user: user, routine: routine)
        expect(routine_workout.workout_type).to eq('routine_based')

        free_workout = create(:workout, :free_style, :skip_validation, user: user)
        expect(free_workout.workout_type).to eq('free_style')
      end

      it 'copies routine exercises for routine-based workouts' do
        create_list(:routine_exercise, 3, routine: routine)
        workout = create(:workout, user: user, routine: routine)
        expect(workout.exercises.count).to eq(3)
      end

      it 'does not copy exercises for free-style workouts' do
        workout = create(:workout, :free_style, user: user)
        expect(workout.exercises.count).to eq(0)
      end
    end
  end

  describe 'state methods' do
    let(:workout) { create(:workout, user: user, routine: routine) }

    describe '#pause!' do
      it 'pauses an active workout' do
        expect(workout.pause!('Rest break')).to be_truthy
        expect(workout.reload.status).to eq('paused')
        expect(workout.pauses.last.reason).to eq('Rest break')
      end

      it 'returns false if workout is not active' do
        workout.update!(status: 'completed')
        expect(workout.pause!('Rest break')).to be_falsey
      end

      it 'returns false if workout is already paused' do
        workout.update!(status: 'paused')
        expect(workout.pause!('Rest break')).to be_falsey
      end
    end

    describe '#resume!' do
      before { workout.pause!('Rest break') }

      it 'resumes a paused workout' do
        expect(workout.resume!).to be_truthy
        expect(workout.reload.status).to eq('in_progress')
        expect(workout.pauses.last.resumed_at).to be_present
      end

      it 'returns false if workout is not paused' do
        workout.update!(status: 'in_progress')
        expect(workout.resume!).to be_falsey
      end
    end

    describe '#complete!' do
      let(:workout_with_exercises) { create(:workout, :with_exercises, user: user, routine: routine) }

      it 'completes an active workout' do
        allow(workout_with_exercises).to receive(:calculate_totals)
        expect(workout_with_exercises.complete!).to be_truthy
        expect(workout_with_exercises.reload.status).to eq('completed')
        expect(workout_with_exercises.completed_at).to be_present
      end

      it 'returns false if workout is not active' do
        workout.update!(status: 'abandoned')
        expect(workout.complete!).to be_falsey
      end
    end

    describe '#abandon!' do
      it 'abandons a workout' do
        expect(workout.abandon!).to be_truthy
        expect(workout.reload.status).to eq('abandoned')
        expect(workout.completed_at).to be_present
      end

      it 'returns false if workout is already completed' do
        workout.update!(status: 'completed')
        expect(workout.abandon!).to be_falsey
      end
    end
  end

  describe 'duration methods' do
    let(:workout) { create(:workout, user: user, routine: routine, started_at: 1.hour.ago) }

    describe '#total_pause_duration' do
      it 'calculates total pause duration' do
        pause1 = create(:workout_pause, workout: workout, resumed_at: Time.current + 5.minutes)
        pause1.update!(duration_seconds: 300)
        pause2 = create(:workout_pause, workout: workout, resumed_at: Time.current + 3.minutes)
        pause2.update!(duration_seconds: 180)
        expect(workout.total_pause_duration).to eq(480)
      end
    end

    describe '#actual_duration' do
      it 'calculates duration excluding pauses' do
        pause = create(:workout_pause, workout: workout, resumed_at: Time.current + 10.minutes)
        pause.update!(duration_seconds: 600)
        expected_duration = 1.hour - 10.minutes
        expect(workout.actual_duration).to be_within(5.seconds).of(expected_duration)
      end
    end
  end

  describe 'display methods' do
    describe '#display_name' do
      it 'returns routine name for routine-based workouts' do
        workout = create(:workout, :routine_based, user: user, routine: routine)
        expect(workout.display_name).to eq(routine.name)
      end

      it 'returns workout name for free-style workouts' do
        workout = create(:workout, :free_style, user: user, name: 'My Custom Workout')
        expect(workout.display_name).to eq('My Custom Workout')
      end

      it 'returns default name when no name is set' do
        workout = build(:workout, :free_style, user: user)
        workout.name = nil
        workout.skip_active_workout_validation = true
        workout.save!(validate: false) # Skip validations to allow nil name
        expect(workout.display_name).to eq('Untitled Workout')
      end
    end

    describe '#has_exercises?' do
      it 'returns true when workout has exercises' do
        workout = create(:workout, :with_exercises, user: user, routine: routine)
        expect(workout.has_exercises?).to be_truthy
      end

      it 'returns false when workout has no exercises' do
        workout = create(:workout, :free_style, user: user)
        expect(workout.has_exercises?).to be_falsey
      end
    end
  end
end 