require 'rails_helper'

RSpec.describe Workout::SetsController, type: :controller do
  let(:user) { create(:user) }
  let(:workout) { create(:workout, user: user) }
  let(:workout_exercise) { create(:workout_exercise, workout: workout) }
  let(:workout_set) { create(:workout_set, exercise: workout_exercise) }

  before do
    allow(controller).to receive(:authenticate_user!)
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe 'GET #index' do
    let!(:sets) { create_list(:workout_set, 4, exercise: workout_exercise) }

    it 'returns all sets for the exercise' do
      get :index, params: { 
        workout_id: workout.id, 
        exercise_id: workout_exercise.id 
      }
      expect(response).to have_http_status(:success)
      expect(assigns(:sets)).to match_array(sets)
    end

    it 'orders sets by set_number' do
      set1 = create(:workout_set, exercise: workout_exercise, set_number: 3)
      set2 = create(:workout_set, exercise: workout_exercise, set_number: 1)
      
      get :index, params: { 
        workout_id: workout.id, 
        exercise_id: workout_exercise.id 
      }
      
      ordered_sets = assigns(:sets)
      expect(ordered_sets.first.set_number).to be <= ordered_sets.last.set_number
    end
  end

  describe 'GET #show' do
    it 'returns the requested set' do
      get :show, params: { 
        workout_id: workout.id, 
        exercise_id: workout_exercise.id, 
        id: workout_set.id 
      }
      expect(response).to have_http_status(:success)
      expect(assigns(:set)).to eq(workout_set)
    end

    it 'returns not found for non-existent set' do
      expect {
        get :show, params: { 
          workout_id: workout.id, 
          exercise_id: workout_exercise.id, 
          id: 999999 
        }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe 'POST #create' do
    context 'with valid parameters' do
      let(:valid_attributes) {
        {
          weight: 80.0,
          reps: 10,
          rpe: 8,
          set_type: 'normal',
          rest_time_seconds: 120
        }
      }

      it 'creates a new set' do
        expect {
          post :create, params: { 
            workout_id: workout.id, 
            exercise_id: workout_exercise.id, 
            set: valid_attributes 
          }
        }.to change(WorkoutSet, :count).by(1)
      end

      it 'returns created status' do
        post :create, params: { 
          workout_id: workout.id, 
          exercise_id: workout_exercise.id, 
          set: valid_attributes 
        }
        expect(response).to have_http_status(:created)
      end

      it 'sets automatic set_number' do
        existing_set = create(:workout_set, exercise: workout_exercise, set_number: 2)
        post :create, params: { 
          workout_id: workout.id, 
          exercise_id: workout_exercise.id, 
          set: valid_attributes 
        }
        
        created_set = WorkoutSet.last
        expect(created_set.set_number).to eq(3)
      end

      it 'creates drop sets correctly' do
        drop_set_attributes = valid_attributes.merge(
          set_type: 'drop_set',
          drop_set_weight: 60.0,
          drop_set_reps: 12
        )
        
        post :create, params: { 
          workout_id: workout.id, 
          exercise_id: workout_exercise.id, 
          set: drop_set_attributes 
        }
        
        created_set = WorkoutSet.last
        expect(created_set.set_type).to eq('drop_set')
        expect(created_set.drop_set_weight).to eq(60.0)
        expect(created_set.drop_set_reps).to eq(12)
      end
    end

    context 'with invalid parameters' do
      it 'returns unprocessable entity for invalid data' do
        invalid_attributes = { weight: -10, reps: 0 }
        post :create, params: { 
          workout_id: workout.id, 
          exercise_id: workout_exercise.id, 
          set: invalid_attributes 
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns error for drop set without drop set data' do
        invalid_attributes = {
          weight: 80,
          reps: 10,
          set_type: 'drop_set'
          # Missing drop_set_weight and drop_set_reps
        }
        
        post :create, params: { 
          workout_id: workout.id, 
          exercise_id: workout_exercise.id, 
          set: invalid_attributes 
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'PUT #update' do
    context 'with valid parameters' do
      let(:new_attributes) {
        {
          weight: 85.0,
          reps: 12,
          rpe: 9,
          notes: 'Updated set notes'
        }
      }

      it 'updates the set' do
        put :update, params: { 
          workout_id: workout.id, 
          exercise_id: workout_exercise.id, 
          id: workout_set.id, 
          set: new_attributes 
        }
        
        workout_set.reload
        expect(workout_set.weight).to eq(85.0)
        expect(workout_set.reps).to eq(12)
        expect(workout_set.rpe).to eq(9)
        expect(workout_set.notes).to eq('Updated set notes')
      end

      it 'returns success status' do
        put :update, params: { 
          workout_id: workout.id, 
          exercise_id: workout_exercise.id, 
          id: workout_set.id, 
          set: new_attributes 
        }
        expect(response).to have_http_status(:success)
      end
    end

    context 'with invalid parameters' do
      it 'returns unprocessable entity for invalid data' do
        invalid_attributes = { weight: -5 }
        put :update, params: { 
          workout_id: workout.id, 
          exercise_id: workout_exercise.id, 
          id: workout_set.id, 
          set: invalid_attributes 
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'when set is already completed' do
      let(:completed_set) { create(:workout_set, :completed, exercise: workout_exercise) }

      it 'prevents updates to completed sets' do
        put :update, params: { 
          workout_id: workout.id, 
          exercise_id: workout_exercise.id, 
          id: completed_set.id, 
          set: { weight: 100 } 
        }
        expect(response).to have_http_status(:bad_request)
      end
    end
  end

  describe 'PUT #start' do
    it 'starts the set' do
      put :start, params: { 
        workout_id: workout.id, 
        exercise_id: workout_exercise.id, 
        id: workout_set.id 
      }
      
      expect(response).to have_http_status(:success)
      workout_set.reload
      expect(workout_set.started_at).to be_present
    end

    context 'when set is already started' do
      let(:started_set) { create(:workout_set, exercise: workout_exercise, started_at: Time.current) }

      it 'returns bad request' do
        put :start, params: { 
          workout_id: workout.id, 
          exercise_id: workout_exercise.id, 
          id: started_set.id 
        }
        expect(response).to have_http_status(:bad_request)
      end
    end
  end

  describe 'PUT #complete' do
    context 'with valid completion data' do
      let(:completion_attributes) {
        {
          weight: 82.5,
          reps: 11,
          rpe: 8,
          rest_time_seconds: 150
        }
      }

      it 'completes the set' do
        put :complete, params: { 
          workout_id: workout.id, 
          exercise_id: workout_exercise.id, 
          id: workout_set.id,
          set: completion_attributes
        }
        
        expect(response).to have_http_status(:success)
        workout_set.reload
        expect(workout_set.completed).to be_truthy
        expect(workout_set.completed_at).to be_present
        expect(workout_set.weight).to eq(82.5)
        expect(workout_set.reps).to eq(11)
        expect(workout_set.rpe).to eq(8)
      end

      it 'handles drop set completion' do
        drop_set = create(:workout_set, :drop_set, exercise: workout_exercise)
        drop_set_completion = completion_attributes.merge(
          drop_set_weight: 65.0,
          drop_set_reps: 8
        )
        
        put :complete, params: { 
          workout_id: workout.id, 
          exercise_id: workout_exercise.id, 
          id: drop_set.id,
          set: drop_set_completion
        }
        
        drop_set.reload
        expect(drop_set.drop_set_weight).to eq(65.0)
        expect(drop_set.drop_set_reps).to eq(8)
      end


    end

    context 'when set is already completed' do
      let(:completed_set) { create(:workout_set, :completed, exercise: workout_exercise) }

      it 'returns bad request' do
        put :complete, params: { 
          workout_id: workout.id, 
          exercise_id: workout_exercise.id, 
          id: completed_set.id,
          set: {
            weight: 80,
            reps: 10
          }
        }
        expect(response).to have_http_status(:bad_request)
      end
    end

    context 'with invalid completion data' do
      it 'returns unprocessable entity' do
        put :complete, params: { 
          workout_id: workout.id, 
          exercise_id: workout_exercise.id, 
          id: workout_set.id,
          set: {
            weight: -10,
            reps: 0
          }
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'PUT #mark_as_completed' do
    it 'marks the set as completed without changing data' do
      original_weight = workout_set.weight
      original_reps = workout_set.reps
      
      put :mark_as_completed, params: { 
        workout_id: workout.id, 
        exercise_id: workout_exercise.id, 
        id: workout_set.id 
      }
      
      expect(response).to have_http_status(:success)
      workout_set.reload
      expect(workout_set.completed).to be_truthy
      expect(workout_set.completed_at).to be_present
      expect(workout_set.weight).to eq(original_weight)
      expect(workout_set.reps).to eq(original_reps)
    end

    context 'when set is already completed' do
      let(:completed_set) { create(:workout_set, :completed, exercise: workout_exercise) }

      it 'returns bad request' do
        put :mark_as_completed, params: { 
          workout_id: workout.id, 
          exercise_id: workout_exercise.id, 
          id: completed_set.id 
        }
        expect(response).to have_http_status(:bad_request)
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'deletes the set' do
      set_to_delete = create(:workout_set, exercise: workout_exercise)
      expect {
        delete :destroy, params: { 
          workout_id: workout.id, 
          exercise_id: workout_exercise.id, 
          id: set_to_delete.id 
        }
      }.to change(WorkoutSet, :count).by(-1)
    end

    it 'returns success status' do
      delete :destroy, params: { 
        workout_id: workout.id, 
        exercise_id: workout_exercise.id, 
        id: workout_set.id 
      }
      expect(response).to have_http_status(:success)
    end

    context 'when set is completed' do
      let(:completed_set) { create(:workout_set, :completed, exercise: workout_exercise) }

      it 'prevents deletion of completed sets' do
        delete :destroy, params: { 
          workout_id: workout.id, 
          exercise_id: workout_exercise.id, 
          id: completed_set.id 
        }
        expect(response).to have_http_status(:bad_request)
      end
    end
  end

  describe 'authentication and authorization' do
    let(:other_user) { create(:user) }
    let(:other_workout) { create(:workout, user: other_user) }
    let(:other_exercise) { create(:workout_exercise, workout: other_workout) }
    let(:other_set) { create(:workout_set, exercise: other_exercise) }

    it 'prevents access to other users sets' do
      expect {
        get :show, params: { 
          workout_id: other_workout.id, 
          exercise_id: other_exercise.id, 
          id: other_set.id 
        }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'prevents creating sets in other users workouts' do
      expect {
        post :create, params: { 
          workout_id: other_workout.id, 
          exercise_id: other_exercise.id, 
          set: { weight: 80, reps: 10 } 
        }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe 'inactive workout validation' do
    let(:completed_workout) { create(:workout, :completed, user: user) }
    let(:completed_exercise) { create(:workout_exercise, workout: completed_workout) }
    let(:completed_workout_set) { create(:workout_set, exercise: completed_exercise) }

    it 'prevents modifications to sets in completed workouts' do
      put :update, params: { 
        workout_id: completed_workout.id, 
        exercise_id: completed_exercise.id, 
        id: completed_workout_set.id, 
        set: { weight: 100 } 
      }
      expect(response).to have_http_status(:bad_request)
    end

    it 'prevents completing sets in completed workouts' do
      put :complete, params: { 
        workout_id: completed_workout.id, 
        exercise_id: completed_exercise.id, 
        id: completed_workout_set.id,
        set: {
          weight: 80,
          reps: 10
        }
      }
      expect(response).to have_http_status(:bad_request)
    end
  end

  describe 'personal record detection' do
    let(:exercise_model) { create(:exercise) }
    let(:workout_exercise) { create(:workout_exercise, workout: workout, exercise: exercise_model) }
    
    it 'detects weight personal record when workout is completed' do
      # Setup previous best
      previous_workout = create(:workout, :completed, user: user)
      previous_exercise = create(:workout_exercise, workout: previous_workout, exercise: exercise_model)
      create(:workout_set, :completed, exercise: previous_exercise, weight: 80, set_type: 'normal')

      # Complete new PR set
      pr_set = create(:workout_set, exercise: workout_exercise, set_type: 'normal')
      put :complete, params: { 
        workout_id: workout.id, 
        exercise_id: workout_exercise.id, 
        id: pr_set.id,
        actual_weight: 90,
        actual_reps: 10
      }
      
      # Complete the workout to trigger PR detection
      workout.complete!
      
      pr_set.reload
      expect(pr_set.is_personal_record).to be_truthy
      expect(pr_set.pr_type).to eq('weight')
    end
  end
end 