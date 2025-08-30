require 'rails_helper'

RSpec.describe UserStatsService do
  let(:user) { create(:user) }
  let(:service) { described_class.new(user) }

  describe '#complete_stats' do
    context 'when user has no data' do
      it 'returns empty stats' do
        result = service.complete_stats

        expect(result[:profile]).to eq({})
        expect(result[:performance]).to eq({})
        expect(result[:analytics]).to eq({})
        expect(result[:personal_records][:message]).to eq('No hay PRs registrados')
      end
    end

    context 'when user has basic profile data' do
      let!(:user_stat) { create(:user_stat, user: user, weight: 70.0, height: 175.0, age: 25) }

      it 'returns profile data' do
        result = service.complete_stats

        expect(result[:profile][:weight]).to eq(70.0)
        expect(result[:profile][:height]).to eq(175.0)
        expect(result[:profile][:age]).to eq(25)
        expect(result[:performance]).to eq({})
        expect(result[:analytics]).to eq({})
      end
    end

    context 'when user has workout data but no PRs' do
      let!(:user_stat) { create(:user_stat, user: user, weight: 70.0) }
      let!(:workout) { create(:workout, :completed, user: user) }
      let!(:exercise) { create(:workout_exercise, workout: workout) }
      let!(:set) { create(:workout_set, :completed, exercise: exercise, weight: 80, reps: 8, rpe: 7) }

      it 'returns analytics data but no performance data' do
        result = service.complete_stats

        expect(result[:analytics]).not_to be_empty
        expect(result[:analytics][:intensity_distribution]).to include(:heavy)
        expect(result[:performance]).to eq({})
        expect(result[:personal_records][:message]).to eq('No hay PRs registrados')
      end
    end

    context 'when user has personal records' do
      let!(:user_stat) { create(:user_stat, user: user, weight: 70.0) }
      let!(:workout) { create(:workout, :completed, user: user) }
      let!(:exercise) { create(:workout_exercise, workout: workout) }
      let!(:pr_set) { create(:workout_set, :weight_pr, exercise: exercise, weight: 100, reps: 5) }

      it 'calculates 1RM correctly using Brzycki formula' do
        result = service.complete_stats

        # Fórmula Brzycki: 100 / (1.0278 - 0.0278 * 5) = 100 / 0.8888 = 112.5
        one_rm = result[:performance][:one_rep_maxes].values.first
        expect(one_rm).to be_within(0.1).of(112.5)
      end

      it 'calculates relative strength' do
        result = service.complete_stats

        # 112.5 / 70.0 = 1.61
        relative_strength = result[:performance][:relative_strength].values.first
        expect(relative_strength).to be_within(0.01).of(1.61)
      end

      it 'returns top exercises with PRs' do
        result = service.complete_stats

        expect(result[:performance][:top_exercises]).to be_an(Array)
        expect(result[:performance][:top_exercises].length).to be <= 5
        expect(result[:performance][:top_exercises].first).to include(
          :exercise_name, :exercise_id, :pr_weight, :pr_reps, :pr_type, :one_rep_max, :relative_strength, :pr_date
        )
      end

      it 'returns personal records data' do
        result = service.complete_stats

        expect(result[:personal_records]).not_to include(:message)
        expect(result[:personal_records]).to include(:recent, :by_exercise, :statistics)
      end
    end

    context 'when user has multiple PRs for same exercise' do
      let!(:user_stat) { create(:user_stat, user: user, weight: 70.0) }
      let!(:workout1) { create(:workout, :completed, user: user, created_at: 1.week.ago) }
      let!(:workout2) { create(:workout, :completed, user: user, created_at: 1.day.ago) }
      let!(:exercise) { create(:workout_exercise, workout: workout1) }
      let!(:exercise2) { create(:workout_exercise, workout: workout2, exercise: exercise.exercise) }
      let!(:old_pr) { create(:workout_set, :weight_pr, exercise: exercise, weight: 90, reps: 5, created_at: 1.week.ago) }
      let!(:new_pr) { create(:workout_set, :weight_pr, exercise: exercise2, weight: 100, reps: 5, created_at: 1.day.ago) }

      it 'uses the most recent PR for calculations' do
        result = service.complete_stats

        # Should use the newer PR (100kg) for 1RM calculation
        one_rm = result[:performance][:one_rep_maxes].values.first
        expect(one_rm).to be_within(0.1).of(112.5) # Based on 100kg, not 90kg
      end
    end
  end

  describe '#calculate_1rm_brzycki' do
    it 'calculates 1RM correctly for different rep ranges' do
      # Test cases with known results using actual Brzycki formula
      # 1RM = weight / (1.0278 - 0.0278 × reps)
      expect(service.send(:calculate_1rm_brzycki, 100, 5)).to be_within(0.1).of(112.5)
      expect(service.send(:calculate_1rm_brzycki, 80, 10)).to be_within(0.1).of(106.7)
      expect(service.send(:calculate_1rm_brzycki, 120, 3)).to be_within(0.1).of(127.1)
    end

    it 'returns nil for invalid inputs' do
      expect(service.send(:calculate_1rm_brzycki, nil, 5)).to be_nil
      expect(service.send(:calculate_1rm_brzycki, 100, nil)).to be_nil
      expect(service.send(:calculate_1rm_brzycki, 0, 5)).to be_nil
      expect(service.send(:calculate_1rm_brzycki, 100, 0)).to be_nil
    end
  end

  describe '#calculate_intensity_distribution' do
    let!(:user_stat) { create(:user_stat, user: user) }
    let!(:workout) { create(:workout, :completed, user: user) }
    let!(:exercise) { create(:workout_exercise, workout: workout) }

    it 'calculates RPE distribution correctly' do
      # Create sets with different RPE values
      create(:workout_set, :completed, exercise: exercise, rpe: 2) # light
      create(:workout_set, :completed, exercise: exercise, rpe: 5) # moderate
      create(:workout_set, :completed, exercise: exercise, rpe: 7) # heavy
      create(:workout_set, :completed, exercise: exercise, rpe: 9) # maximal

      result = service.complete_stats
      distribution = result[:analytics][:intensity_distribution]

      expect(distribution[:light]).to eq(25.0)
      expect(distribution[:moderate]).to eq(25.0)
      expect(distribution[:heavy]).to eq(25.0)
      expect(distribution[:maximal]).to eq(25.0)
    end

    it 'returns empty distribution when no RPE data' do
      create(:workout_set, :completed, exercise: exercise, rpe: nil)

      result = service.complete_stats
      distribution = result[:analytics][:intensity_distribution]

      expect(distribution.values.sum).to eq(0)
    end
  end

  describe '#calculate_volume_trends' do
    let!(:user_stat) { create(:user_stat, user: user) }

    it 'calculates volume trends correctly' do
      # Create workouts in different periods
      create(:workout, :completed, user: user, total_volume: 1000, created_at: 15.days.ago)
      create(:workout, :completed, user: user, total_volume: 1200, created_at: 10.days.ago)
      create(:workout, :completed, user: user, total_volume: 800, created_at: 45.days.ago)

      result = service.complete_stats
      trends = result[:analytics][:volume_trends]

      expect(trends[:current_period_volume]).to eq(2200)
      expect(trends[:previous_period_volume]).to eq(800)
      expect(trends[:percentage_change]).to eq(175.0)
      expect(trends[:trend]).to eq('increasing')
    end

    it 'handles no previous volume' do
      create(:workout, :completed, user: user, total_volume: 1000, created_at: 15.days.ago)

      result = service.complete_stats
      trends = result[:analytics][:volume_trends]

      expect(trends[:percentage_change]).to be_nil
      expect(trends[:trend]).to be_nil
    end
  end

  describe '#calculate_frequency_patterns' do
    let!(:user_stat) { create(:user_stat, user: user) }

    it 'calculates frequency patterns correctly' do
      # Create workouts on different days
      create(:workout, :completed, user: user, created_at: 1.day.ago)
      create(:workout, :completed, user: user, created_at: 3.days.ago)
      create(:workout, :completed, user: user, created_at: 7.days.ago)

      result = service.complete_stats
      patterns = result[:analytics][:frequency_patterns]

      expect(patterns[:workouts_per_week]).to be_within(0.1).of(0.75) # 3 workouts / 4 weeks
      expect(patterns[:consistency_score]).to be > 0
    end
  end
end
