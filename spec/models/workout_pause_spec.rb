require 'rails_helper'

RSpec.describe WorkoutPause, type: :model do
  let(:user) { create(:user) }
  let(:workout) { create(:workout, user: user) }

  describe 'associations' do
    it { should belong_to(:workout) }
  end

  describe 'validations' do
    subject { build(:workout_pause, workout: workout) }

    it { should validate_presence_of(:paused_at) }
    it { should validate_presence_of(:reason) }
    it { should validate_numericality_of(:duration_seconds).only_integer.is_greater_than_or_equal_to(0).allow_nil }

    context 'when resumed_at is present' do
      it 'validates resumed_at is after paused_at' do
        pause = build(:workout_pause, workout: workout, 
                     paused_at: Time.current, 
                     resumed_at: 1.minute.ago)
        expect(pause).not_to be_valid
        expect(pause.errors[:resumed_at]).to include('must be after paused_at')
      end
    end
  end

  describe 'scopes' do
    let!(:active_pause) { create(:workout_pause, :active, workout: workout) }
    let!(:completed_pause) { create(:workout_pause, :completed, workout: workout) }

    describe '.active' do
      it 'returns pauses without resumed_at' do
        expect(WorkoutPause.active).to include(active_pause)
        expect(WorkoutPause.active).not_to include(completed_pause)
      end
    end

    describe '.completed' do
      it 'returns pauses with resumed_at' do
        expect(WorkoutPause.completed).to include(completed_pause)
        expect(WorkoutPause.completed).not_to include(active_pause)
      end
    end
  end

  describe 'callbacks' do
    describe 'on save' do
      it 'calculates duration when resumed_at changes' do
        pause = create(:workout_pause, workout: workout, paused_at: 5.minutes.ago)
        pause.update!(resumed_at: Time.current)
        
        expect(pause.duration_seconds).to be_within(10).of(5.minutes.to_i)
      end
    end
  end

  describe 'instance methods' do
    describe '#duration' do
      context 'when pause is completed' do
        it 'calculates duration between paused_at and resumed_at' do
          pause = create(:workout_pause, 
                        paused_at: 10.minutes.ago, 
                        resumed_at: 5.minutes.ago)
          expect(pause.duration).to be_within(10.seconds).of(5.minutes)
        end
      end

      context 'when pause is active' do
        it 'calculates duration from paused_at to current time' do
          pause = create(:workout_pause, paused_at: 3.minutes.ago, resumed_at: nil)
          expect(pause.duration).to be_within(10.seconds).of(3.minutes)
        end
      end

      context 'when paused_at is not set' do
        it 'returns 0' do
          pause = build(:workout_pause, paused_at: nil)
          expect(pause.duration).to eq(0)
        end
      end
    end

    describe '#active?' do
      it 'returns true when resumed_at is nil' do
        pause = create(:workout_pause, :active, workout: workout)
        expect(pause.active?).to be_truthy
      end

      it 'returns false when resumed_at is present' do
        pause = create(:workout_pause, :completed, workout: workout)
        expect(pause.active?).to be_falsey
      end
    end

    describe '#completed?' do
      it 'returns true when resumed_at is present' do
        pause = create(:workout_pause, :completed, workout: workout)
        expect(pause.completed?).to be_truthy
      end

      it 'returns false when resumed_at is nil' do
        pause = create(:workout_pause, :active, workout: workout)
        expect(pause.completed?).to be_falsey
      end
    end
  end

  describe 'real-world scenarios' do
    it 'handles short water break' do
      pause = create(:workout_pause, :short_break, workout: workout)
      expect(pause.reason).to eq('Water break')
      expect(pause.duration_seconds).to eq(120)
      expect(pause.completed?).to be_truthy
    end

    it 'handles long emergency pause' do
      pause = create(:workout_pause, :long_break, workout: workout)
      expect(pause.reason).to eq('Emergency pause')
      expect(pause.duration_seconds).to eq(900)
      expect(pause.completed?).to be_truthy
    end

    it 'handles ongoing pause' do
      pause = create(:workout_pause, :active, workout: workout, paused_at: 2.minutes.ago)
      expect(pause.active?).to be_truthy
      expect(pause.duration).to be_within(10.seconds).of(2.minutes)
      expect(pause.duration_seconds).to be_nil
    end
  end
end 