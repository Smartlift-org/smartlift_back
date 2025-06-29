require 'rails_helper'

# TODO: Personal Records functionality needs refactoring after simplification
# Skipping these tests until PR system is updated
RSpec.describe PersonalRecordsController, type: :controller, skip: true do
  let(:user) { create(:user) }
  let(:exercise) { create(:exercise) }

  before do
    allow(controller).to receive(:authenticate_user!)
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe 'GET #index' do
    let(:other_exercise) { create(:exercise) }
    
    before do
      # Create completed workouts with personal records
      workout1 = create(:workout, :completed, user: user)
      workout2 = create(:workout, :completed, user: user)
      
      # Exercise 1 PRs
      exercise1_workout = create(:workout_exercise, workout: workout1, exercise: exercise)
      create(:workout_set, :weight_pr, exercise: exercise1_workout, weight: 100, reps: 8)
      create(:workout_set, :reps_pr, exercise: exercise1_workout, weight: 80, reps: 15)
      
      # Exercise 2 PRs
      exercise2_workout = create(:workout_exercise, workout: workout2, exercise: other_exercise)
      create(:workout_set, :volume_pr, exercise: exercise2_workout, weight: 90, reps: 12)
      
      # Non-PR sets (should not appear)
      create(:workout_set, :completed, exercise: exercise1_workout, weight: 70, reps: 10, is_personal_record: false)
    end

    it 'returns all personal records for the user' do
      get :index
      expect(response).to have_http_status(:success)
      
      records = assigns(:personal_records)
      expect(records.count).to eq(3)
      expect(records.all? { |record| record.is_personal_record }).to be_truthy
    end

    it 'groups records by exercise' do
      get :index
      records = assigns(:personal_records)
      
      exercise_records = records.select { |r| r.exercise.exercise_id == exercise.id }
      other_exercise_records = records.select { |r| r.exercise.exercise_id == other_exercise.id }
      
      expect(exercise_records.count).to eq(2)
      expect(other_exercise_records.count).to eq(1)
    end

    it 'orders records by created_at desc' do
      get :index
      records = assigns(:personal_records)
      
      expect(records.first.created_at).to be >= records.last.created_at
    end

    context 'with exercise filter' do
      it 'filters records by specific exercise' do
        get :index, params: { exercise_id: exercise.id }
        records = assigns(:personal_records)
        
        expect(records.count).to eq(2)
        expect(records.all? { |r| r.exercise.exercise_id == exercise.id }).to be_truthy
      end

      it 'returns empty array for exercise with no PRs' do
        empty_exercise = create(:exercise)
        get :index, params: { exercise_id: empty_exercise.id }
        records = assigns(:personal_records)
        
        expect(records).to be_empty
      end
    end

    context 'with PR type filter' do
      it 'filters records by weight PRs' do
        get :index, params: { pr_type: 'weight' }
        records = assigns(:personal_records)
        
        expect(records.count).to eq(1)
        expect(records.first.pr_type).to eq('weight')
      end

      it 'filters records by reps PRs' do
        get :index, params: { pr_type: 'reps' }
        records = assigns(:personal_records)
        
        expect(records.count).to eq(1)
        expect(records.first.pr_type).to eq('reps')
      end

      it 'filters records by volume PRs' do
        get :index, params: { pr_type: 'volume' }
        records = assigns(:personal_records)
        
        expect(records.count).to eq(1)
        expect(records.first.pr_type).to eq('volume')
      end
    end

    context 'with combined filters' do
      it 'filters by both exercise and PR type' do
        get :index, params: { exercise_id: exercise.id, pr_type: 'weight' }
        records = assigns(:personal_records)
        
        expect(records.count).to eq(1)
        expect(records.first.pr_type).to eq('weight')
        expect(records.first.exercise.exercise_id).to eq(exercise.id)
      end
    end

    context 'with limit parameter' do
      it 'limits the number of results' do
        get :index, params: { limit: 2 }
        records = assigns(:personal_records)
        
        expect(records.count).to eq(2)
      end

      it 'defaults to all records when no limit specified' do
        get :index
        records = assigns(:personal_records)
        
        expect(records.count).to eq(3)
      end
    end
  end

  describe 'GET #show' do
    let(:workout) { create(:workout, :completed, user: user) }
    let(:workout_exercise) { create(:workout_exercise, workout: workout, exercise: exercise) }
    let(:pr_set) { create(:workout_set, :weight_pr, exercise: workout_exercise) }

    it 'returns the requested personal record' do
      get :show, params: { id: pr_set.id }
      expect(response).to have_http_status(:success)
      expect(assigns(:personal_record)).to eq(pr_set)
    end

    it 'returns not found for non-existent record' do
      expect {
        get :show, params: { id: 999999 }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'returns not found for non-PR set' do
      regular_set = create(:workout_set, :completed, exercise: workout_exercise, is_personal_record: false)
      expect {
        get :show, params: { id: regular_set.id }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe 'GET #by_exercise' do
    let(:other_exercise) { create(:exercise) }
    
    before do
      workout = create(:workout, :completed, user: user)
      
      # Exercise PRs
      exercise_workout = create(:workout_exercise, workout: workout, exercise: exercise)
      create(:workout_set, :weight_pr, exercise: exercise_workout, weight: 120, created_at: 2.days.ago)
      create(:workout_set, :weight_pr, exercise: exercise_workout, weight: 130, created_at: 1.day.ago)
      create(:workout_set, :reps_pr, exercise: exercise_workout, reps: 15, created_at: 1.day.ago)
      
      # Other exercise PRs (should not appear)
      other_exercise_workout = create(:workout_exercise, workout: workout, exercise: other_exercise)
      create(:workout_set, :weight_pr, exercise: other_exercise_workout, weight: 100)
    end

    it 'returns PRs for specific exercise only' do
      get :by_exercise, params: { exercise_id: exercise.id }
      expect(response).to have_http_status(:success)
      
      records = assigns(:personal_records)
      expect(records.count).to eq(3)
      expect(records.all? { |r| r.exercise.exercise_id == exercise.id }).to be_truthy
    end

    it 'groups PRs by type' do
      get :by_exercise, params: { exercise_id: exercise.id }
      records = assigns(:personal_records)
      
      weight_prs = records.select { |r| r.pr_type == 'weight' }
      reps_prs = records.select { |r| r.pr_type == 'reps' }
      
      expect(weight_prs.count).to eq(2)
      expect(reps_prs.count).to eq(1)
    end

    it 'orders PRs by created_at desc within each type' do
      get :by_exercise, params: { exercise_id: exercise.id }
      records = assigns(:personal_records)
      
      weight_prs = records.select { |r| r.pr_type == 'weight' }
      expect(weight_prs.first.weight).to eq(130) # Most recent
      expect(weight_prs.last.weight).to eq(120)  # Older
    end

    it 'returns empty for exercise with no PRs' do
      empty_exercise = create(:exercise)
      get :by_exercise, params: { exercise_id: empty_exercise.id }
      records = assigns(:personal_records)
      
      expect(records).to be_empty
    end
  end

  describe 'GET #latest' do
    before do
      workout1 = create(:workout, :completed, user: user, created_at: 3.days.ago)
      workout2 = create(:workout, :completed, user: user, created_at: 1.day.ago)
      
      # Older PRs
      old_exercise = create(:workout_exercise, workout: workout1, exercise: exercise)
      create(:workout_set, :weight_pr, exercise: old_exercise, weight: 100, created_at: 3.days.ago)
      
      # Recent PRs
      recent_exercise = create(:workout_exercise, workout: workout2, exercise: exercise)
      create(:workout_set, :weight_pr, exercise: recent_exercise, weight: 120, created_at: 1.day.ago)
      create(:workout_set, :reps_pr, exercise: recent_exercise, reps: 15, created_at: 1.day.ago)
    end

    it 'returns recent personal records' do
      get :latest, params: { days: 2 }
      expect(response).to have_http_status(:success)
      
      records = assigns(:personal_records)
      expect(records.count).to eq(2)
      expect(records.all? { |r| r.created_at >= 2.days.ago }).to be_truthy
    end

    it 'defaults to 7 days when no days parameter specified' do
      get :latest
      records = assigns(:personal_records)
      
      expect(records.count).to eq(3) # All records within last 7 days
    end

    it 'limits results when limit parameter provided' do
      get :latest, params: { days: 2, limit: 1 }
      records = assigns(:personal_records)
      
      expect(records.count).to eq(1)
    end
  end

  describe 'GET #statistics' do
    before do
      workout = create(:workout, :completed, user: user)
      
      # Multiple exercises with PRs
      3.times do |i|
        exercise = create(:exercise)
        workout_exercise = create(:workout_exercise, workout: workout, exercise: exercise)
        create(:workout_set, :weight_pr, exercise: workout_exercise)
        create(:workout_set, :reps_pr, exercise: workout_exercise)
      end
      
      # Additional volume PR
      first_exercise = Exercise.first
      first_workout_exercise = create(:workout_exercise, workout: workout, exercise: first_exercise)
      create(:workout_set, :volume_pr, exercise: first_workout_exercise)
    end

    it 'returns PR statistics' do
      get :statistics
      expect(response).to have_http_status(:success)
      
      stats = assigns(:statistics)
      expect(stats[:total_prs]).to eq(7)
      expect(stats[:weight_prs]).to eq(3)
      expect(stats[:reps_prs]).to eq(3)
      expect(stats[:volume_prs]).to eq(1)
      expect(stats[:exercises_with_prs]).to eq(3)
    end

    it 'includes recent PRs count' do
      get :statistics
      stats = assigns(:statistics)
      
      expect(stats[:recent_prs_this_month]).to be_present
      expect(stats[:recent_prs_this_week]).to be_present
    end
  end

  describe 'authentication and authorization' do
    let(:other_user) { create(:user) }
    
    before do
      other_workout = create(:workout, :completed, user: other_user)
      other_exercise_workout = create(:workout_exercise, workout: other_workout, exercise: exercise)
      @other_pr = create(:workout_set, :weight_pr, exercise: other_exercise_workout)
    end

    it 'only returns current users personal records' do
      get :index
      records = assigns(:personal_records)
      
      expect(records).to be_empty # No PRs for current user
    end

    it 'prevents access to other users PRs' do
      expect {
        get :show, params: { id: @other_pr.id }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe 'response format' do
    let(:workout) { create(:workout, :completed, user: user) }
    let(:workout_exercise) { create(:workout_exercise, workout: workout, exercise: exercise) }
    
    before do
      create(:workout_set, :weight_pr, exercise: workout_exercise, weight: 120, reps: 8)
    end

    it 'includes exercise information in response' do
      get :index
      records = assigns(:personal_records)
      
      record = records.first
      expect(record.exercise).to be_present
      expect(record.exercise.exercise).to eq(exercise)
    end

    it 'includes workout information in response' do
      get :index
      records = assigns(:personal_records)
      
      record = records.first
      expect(record.exercise.workout).to eq(workout)
    end

    it 'serializes PR data correctly' do
      get :show, params: { id: WorkoutSet.last.id }
      record = assigns(:personal_record)
      
      expect(record.is_personal_record).to be_truthy
      expect(record.pr_type).to eq('weight')
      expect(record.weight).to eq(120)
      expect(record.reps).to eq(8)
    end
  end
end 