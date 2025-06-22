require 'rails_helper'

RSpec.describe WorkoutTrackable, type: :model do
  let(:user) { create(:user) }
  let(:routine) { create(:routine, user: user) }

  describe 'when included in a model' do
    subject { create(:workout, :skip_validation, user: user, routine: routine, status: 'in_progress') }

    it 'adds status validation' do
      expect(subject).to validate_presence_of(:status)
    end

    describe 'scopes' do
      let!(:in_progress_workout) { create(:workout, :skip_validation, user: user, status: 'in_progress') }
      let!(:paused_workout) { create(:workout, :skip_validation, user: user, status: 'paused') }
      let!(:completed_workout) { create(:workout, :skip_validation, user: user, status: 'completed') }
      let!(:abandoned_workout) { create(:workout, :skip_validation, user: user, status: 'abandoned') }

      describe '.active' do
        it 'returns workouts that are in progress or paused' do
          active_workouts = Workout.active
          expect(active_workouts).to include(in_progress_workout, paused_workout)
          expect(active_workouts).not_to include(completed_workout, abandoned_workout)
        end
      end

      describe '.completed' do
        it 'returns only completed workouts' do
          completed_workouts = Workout.completed
          expect(completed_workouts).to include(completed_workout)
          expect(completed_workouts).not_to include(in_progress_workout, paused_workout, abandoned_workout)
        end
      end

      describe '.abandoned' do
        it 'returns only abandoned workouts' do
          abandoned_workouts = Workout.abandoned
          expect(abandoned_workouts).to include(abandoned_workout)
          expect(abandoned_workouts).not_to include(in_progress_workout, paused_workout, completed_workout)
        end
      end
    end

    describe 'instance methods' do
      describe '#active?' do
        it 'returns true for in_progress status' do
          workout = create(:workout, :skip_validation, user: user, status: 'in_progress')
          expect(workout.active?).to be_truthy
        end

        it 'returns true for paused status' do
          workout = create(:workout, :skip_validation, user: user, status: 'paused')
          expect(workout.active?).to be_truthy
        end

        it 'returns false for completed status' do
          workout = create(:workout, :skip_validation, user: user, status: 'completed')
          expect(workout.active?).to be_falsey
        end

        it 'returns false for abandoned status' do
          workout = create(:workout, :skip_validation, user: user, status: 'abandoned')
          expect(workout.active?).to be_falsey
        end
      end

      describe '#completed?' do
        it 'returns true for completed status' do
          workout = create(:workout, :skip_validation, user: user, status: 'completed')
          expect(workout.completed?).to be_truthy
        end

        it 'returns false for other statuses' do
          %w[in_progress paused abandoned].each do |status|
            workout = create(:workout, :skip_validation, user: user, status: status)
            expect(workout.completed?).to be_falsey
          end
        end
      end

      describe '#abandoned?' do
        it 'returns true for abandoned status' do
          workout = create(:workout, :skip_validation, user: user, status: 'abandoned')
          expect(workout.abandoned?).to be_truthy
        end

        it 'returns false for other statuses' do
          %w[in_progress paused completed].each do |status|
            workout = create(:workout, :skip_validation, user: user, status: status)
            expect(workout.abandoned?).to be_falsey
          end
        end
      end

      describe '#paused?' do
        it 'returns true for paused status' do
          workout = create(:workout, :skip_validation, user: user, status: 'paused')
          expect(workout.paused?).to be_truthy
        end

        it 'returns false for other statuses' do
          %w[in_progress completed abandoned].each do |status|
            workout = create(:workout, :skip_validation, user: user, status: status)
            expect(workout.paused?).to be_falsey
          end
        end
      end

      describe '#in_progress?' do
        it 'returns true for in_progress status' do
          workout = create(:workout, :skip_validation, user: user, status: 'in_progress')
          expect(workout.in_progress?).to be_truthy
        end

        it 'returns false for other statuses' do
          %w[paused completed abandoned].each do |status|
            workout = create(:workout, :skip_validation, user: user, status: status)
            expect(workout.in_progress?).to be_falsey
          end
        end
      end
    end
  end

  describe 'status transitions' do
    let(:workout) { create(:workout, :skip_validation, user: user, status: 'in_progress') }

    it 'correctly identifies status changes' do
      expect(workout.in_progress?).to be_truthy
      expect(workout.active?).to be_truthy

      workout.update!(status: 'paused')
      expect(workout.paused?).to be_truthy
      expect(workout.active?).to be_truthy

      workout.update!(status: 'completed')
      expect(workout.completed?).to be_truthy
      expect(workout.active?).to be_falsey

      workout.update!(status: 'abandoned')
      expect(workout.abandoned?).to be_truthy
      expect(workout.active?).to be_falsey
    end
  end
end 