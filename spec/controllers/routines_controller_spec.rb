require 'rails_helper'

RSpec.describe RoutinesController, type: :controller do
  let(:user) { create(:user) }
  let(:exercise) { create(:exercise) }
  let(:valid_attributes) do
    {
      name: 'Full Body Workout',
      description: 'Complete workout for all muscle groups',
<<<<<<< HEAD
      level: 'intermediate',
=======
      difficulty: 'intermediate',
>>>>>>> develop
      duration: 60,
      routine_exercises_attributes: [
        {
          exercise_id: exercise.id,
          sets: 3,
          reps: 12,
          rest_time: 60,
          order: 1
        }
      ]
    }
  end

  let(:invalid_attributes) do
    {
      name: '',
      description: '',
<<<<<<< HEAD
      level: 'invalid',
=======
      difficulty: 'invalid',
>>>>>>> develop
      duration: -1
    }
  end

  before do
    authenticate_user(user)
  end

  describe 'GET #index' do
    it 'returns a successful response' do
      get :index
      expect(response).to be_successful
    end

<<<<<<< HEAD
    it 'filters routines by level' do
      create(:routine, user: user, level: 'beginner')
      create(:routine, user: user, level: 'advanced')

      get :index, params: { level: 'beginner' }
=======
    it 'filters routines by difficulty' do
      create(:routine, user: user, difficulty: 'beginner')
      create(:routine, user: user, difficulty: 'advanced')

      get :index, params: { difficulty: 'beginner' }
>>>>>>> develop
      expect(assigns(:routines).count).to eq(1)
    end

    it 'filters routines by duration' do
      create(:routine, user: user, duration: 30)
      create(:routine, user: user, duration: 90)

      get :index, params: { max_duration: 60 }
      expect(assigns(:routines).count).to eq(1)
    end
  end

  describe 'GET #show' do
    it 'returns a successful response' do
      routine = create(:routine, user: user)
      get :show, params: { id: routine.id }
      expect(response).to be_successful
    end

    it 'returns 404 for non-existent routine' do
      get :show, params: { id: 999 }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST #create' do
    context 'with valid parameters' do
      it 'creates a new routine' do
        expect {
          post :create, params: { routine: valid_attributes }
        }.to change(Routine, :count).by(1)
      end

      it 'creates routine exercises' do
        expect {
          post :create, params: { routine: valid_attributes }
        }.to change(RoutineExercise, :count).by(1)
      end

      it 'returns created status' do
        post :create, params: { routine: valid_attributes }
        expect(response).to have_http_status(:created)
      end
    end

    context 'with invalid parameters' do
      it 'does not create a new routine' do
        expect {
          post :create, params: { routine: invalid_attributes }
        }.not_to change(Routine, :count)
      end

      it 'returns unprocessable entity status' do
        post :create, params: { routine: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'PATCH #update' do
    let(:routine) { create(:routine, user: user) }

    context 'with valid parameters' do
      let(:new_attributes) do
        {
          name: 'Updated Workout',
          duration: 45
        }
      end

      it 'updates the routine' do
        patch :update, params: { id: routine.id, routine: new_attributes }
        routine.reload
        expect(routine.name).to eq('Updated Workout')
        expect(routine.duration).to eq(45)
      end

      it 'returns successful response' do
        patch :update, params: { id: routine.id, routine: new_attributes }
        expect(response).to be_successful
      end
    end

    context 'with invalid parameters' do
      it 'does not update the routine' do
        original_name = routine.name
        patch :update, params: { id: routine.id, routine: invalid_attributes }
        routine.reload
        expect(routine.name).to eq(original_name)
      end

      it 'returns unprocessable entity status' do
        patch :update, params: { id: routine.id, routine: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'destroys the routine' do
      routine = create(:routine, user: user)
      expect {
        delete :destroy, params: { id: routine.id }
      }.to change(Routine, :count).by(-1)
    end

    it 'returns no content status' do
      routine = create(:routine, user: user)
      delete :destroy, params: { id: routine.id }
      expect(response).to have_http_status(:no_content)
    end
  end
end 