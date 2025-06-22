require 'rails_helper'

RSpec.describe Workout::ExercisesController, type: :controller do
  let(:user) { create(:user) }
  let(:routine) { create(:routine, user: user) }
  let(:workout) { create(:workout, user: user, routine: routine) }
  let(:exercise) { create(:exercise) }
  let(:workout_exercise) { create(:workout_exercise, workout: workout, exercise: exercise) }

  before do
    allow(controller).to receive(:authenticate_user!)
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe 'GET #index' do
    let!(:exercises) { create_list(:workout_exercise, 3, workout: workout) }

    it 'returns all workout exercises' do
      get :index, params: { workout_id: workout.id }
      expect(response).to have_http_status(:success)
      expect(assigns(:exercises)).to match_array(exercises)
    end

    it 'orders exercises by order field' do
      exercise1 = create(:workout_exercise, workout: workout, order: 2)
      exercise2 = create(:workout_exercise, workout: workout, order: 1)
      
      get :index, params: { workout_id: workout.id }
      ordered_exercises = assigns(:exercises)
      expect(ordered_exercises.first).to eq(exercise2)
      expect(ordered_exercises.second).to eq(exercise1)
    end

    it 'includes sets data' do
      exercise_with_sets = create(:workout_exercise, :with_sets, workout: workout)
      get :index, params: { workout_id: workout.id }
      expect(assigns(:exercises)).to include(exercise_with_sets)
    end
  end

  describe 'GET #show' do
    it 'returns the requested exercise' do
      get :show, params: { workout_id: workout.id, id: workout_exercise.id }
      expect(response).to have_http_status(:success)
      expect(assigns(:exercise)).to eq(workout_exercise)
    end

    it 'returns not found for non-existent exercise' do
      expect {
        get :show, params: { workout_id: workout.id, id: 999999 }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe 'POST #create' do
    context 'with valid parameters' do
      let(:valid_attributes) {
        {
          exercise_id: exercise.id,
          target_sets: 3,
          target_reps: 10,
          suggested_weight: 50.0,
          group_type: 'regular'
        }
      }

      it 'creates a new workout exercise' do
        expect {
          post :create, params: { workout_id: workout.id, workout_exercise: valid_attributes }
        }.to change(WorkoutExercise, :count).by(1)
      end

      it 'returns created status' do
        post :create, params: { workout_id: workout.id, workout_exercise: valid_attributes }
        expect(response).to have_http_status(:created)
      end

      it 'sets automatic order' do
        existing_exercise = create(:workout_exercise, workout: workout, order: 5)
        post :create, params: { workout_id: workout.id, workout_exercise: valid_attributes }
        
        created_exercise = WorkoutExercise.last
        expect(created_exercise.order).to eq(6)
      end

      it 'allows creating superset exercises' do
        superset_attributes = valid_attributes.merge(
          group_type: 'superset',
          group_order: 1
        )
        
        post :create, params: { workout_id: workout.id, workout_exercise: superset_attributes }
        created_exercise = WorkoutExercise.last
        expect(created_exercise.group_type).to eq('superset')
        expect(created_exercise.group_order).to eq(1)
      end
    end

    context 'with invalid parameters' do
      it 'returns unprocessable entity when exercise is missing' do
        invalid_attributes = { target_sets: 3, target_reps: 10 }
        post :create, params: { workout_id: workout.id, workout_exercise: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns error when superset already has 2 exercises' do
        create(:workout_exercise, :superset, workout: workout, group_order: 1)
        create(:workout_exercise, :superset, workout: workout, group_order: 1)
        
        invalid_attributes = {
          exercise_id: exercise.id,
          group_type: 'superset',
          group_order: 1
        }
        
        post :create, params: { workout_id: workout.id, workout_exercise: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'PUT #update' do
    context 'with valid parameters' do
      let(:new_attributes) {
        {
          target_sets: 4,
          target_reps: 12,
          suggested_weight: 60.0,
          notes: 'Updated notes'
        }
      }

      it 'updates the exercise' do
        put :update, params: { 
          workout_id: workout.id, 
          id: workout_exercise.id, 
          workout_exercise: new_attributes 
        }
        
        workout_exercise.reload
        expect(workout_exercise.target_sets).to eq(4)
        expect(workout_exercise.target_reps).to eq(12)
        expect(workout_exercise.suggested_weight).to eq(60.0)
        expect(workout_exercise.notes).to eq('Updated notes')
      end

      it 'returns success status' do
        put :update, params: { 
          workout_id: workout.id, 
          id: workout_exercise.id, 
          workout_exercise: new_attributes 
        }
        expect(response).to have_http_status(:success)
      end
    end

    context 'with invalid parameters' do
      it 'returns unprocessable entity for invalid data' do
        invalid_attributes = { target_sets: -1 }
        put :update, params: { 
          workout_id: workout.id, 
          id: workout_exercise.id, 
          workout_exercise: invalid_attributes 
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'POST #record_set' do
    context 'with valid parameters' do
      let(:set_attributes) {
        {
          weight: 80.0,
          reps: 12,
          rpe: 8,
          set_type: 'normal'
        }
      }

      it 'creates a new completed set' do
        expect {
          post :record_set, params: { 
            workout_id: workout.id, 
            id: workout_exercise.id, 
            set: set_attributes 
          }
        }.to change(WorkoutSet, :count).by(1)
      end

      it 'marks the set as completed' do
        post :record_set, params: { 
          workout_id: workout.id, 
          id: workout_exercise.id, 
          set: set_attributes 
        }
        
        created_set = WorkoutSet.last
        expect(created_set.completed).to be_truthy
        expect(created_set.completed_at).to be_present
      end

      it 'returns created status' do
        post :record_set, params: { 
          workout_id: workout.id, 
          id: workout_exercise.id, 
          set: set_attributes 
        }
        expect(response).to have_http_status(:created)
      end

      it 'handles drop set data' do
        drop_set_attributes = set_attributes.merge(
          set_type: 'drop_set',
          drop_set_weight: 60.0,
          drop_set_reps: 10
        )
        
        post :record_set, params: { 
          workout_id: workout.id, 
          id: workout_exercise.id, 
          set: drop_set_attributes 
        }
        
        created_set = WorkoutSet.last
        expect(created_set.set_type).to eq('drop_set')
        expect(created_set.drop_set_weight).to eq(60.0)
        expect(created_set.drop_set_reps).to eq(10)
      end


    end

    context 'with invalid parameters' do
      it 'returns unprocessable entity for invalid set data' do
        invalid_attributes = { weight: -10, reps: 0 }
        post :record_set, params: { 
          workout_id: workout.id, 
          id: workout_exercise.id, 
          set: invalid_attributes 
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'PUT #finalize' do
    let(:workout_exercise_with_sets) { 
      create(:workout_exercise, :with_completed_sets, workout: workout, target_sets: 3) 
    }

    it 'finalizes the exercise' do
      put :finalize, params: { 
        workout_id: workout.id, 
        id: workout_exercise_with_sets.id 
      }
      
      expect(response).to have_http_status(:success)
      workout_exercise_with_sets.reload
      expect(workout_exercise_with_sets.completed_as_prescribed).to_not be_nil
    end

    it 'sets completed_as_prescribed based on performance' do
      # Setup sets that match the target
      workout_exercise_with_sets.sets.each do |set|
        set.update!(reps: workout_exercise_with_sets.target_reps)
      end
      
      put :finalize, params: { 
        workout_id: workout.id, 
        id: workout_exercise_with_sets.id 
      }
      
      workout_exercise_with_sets.reload
      expect(workout_exercise_with_sets.completed_as_prescribed).to be_truthy
    end

    context 'when exercise is not ready to finalize' do
      let(:incomplete_exercise) { create(:workout_exercise, workout: workout) }

      it 'returns bad request' do
        put :finalize, params: { 
          workout_id: workout.id, 
          id: incomplete_exercise.id 
        }
        expect(response).to have_http_status(:bad_request)
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'deletes the exercise' do
      exercise_to_delete = create(:workout_exercise, workout: workout)
      expect {
        delete :destroy, params: { 
          workout_id: workout.id, 
          id: exercise_to_delete.id 
        }
      }.to change(WorkoutExercise, :count).by(-1)
    end

    it 'returns success status' do
      delete :destroy, params: { 
        workout_id: workout.id, 
        id: workout_exercise.id 
      }
      expect(response).to have_http_status(:success)
    end

    it 'also deletes associated sets' do
      exercise_with_sets = create(:workout_exercise, :with_sets, workout: workout)
      expect {
        delete :destroy, params: { 
          workout_id: workout.id, 
          id: exercise_with_sets.id 
        }
      }.to change(WorkoutSet, :count).by(-3) # Assuming factory creates 3 sets
    end
  end

  describe 'authentication and authorization' do
    let(:other_user) { create(:user) }
    let(:other_workout) { create(:workout, user: other_user) }
    let(:other_exercise) { create(:workout_exercise, workout: other_workout) }

    it 'prevents access to other users exercises' do
      expect {
        get :show, params: { workout_id: other_workout.id, id: other_exercise.id }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'prevents creating exercises in other users workouts' do
      expect {
        post :create, params: { 
          workout_id: other_workout.id, 
          workout_exercise: { exercise_id: exercise.id } 
        }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe 'inactive workout validation' do
    let(:completed_workout) { create(:workout, :completed, user: user) }
    let(:completed_exercise) { create(:workout_exercise, workout: completed_workout) }

    it 'prevents modifications to completed workout exercises' do
      put :update, params: { 
        workout_id: completed_workout.id, 
        id: completed_exercise.id, 
        workout_exercise: { target_sets: 5 } 
      }
      expect(response).to have_http_status(:bad_request)
    end

    it 'prevents recording sets in completed workouts' do
      post :record_set, params: { 
        workout_id: completed_workout.id, 
        id: completed_exercise.id, 
        set: { weight: 80, reps: 10 } 
      }
      expect(response).to have_http_status(:bad_request)
    end
  end
end 