require 'rails_helper'

RSpec.describe RoutineExercisesController, type: :controller do
  let(:user) { create(:user) }
  let(:routine) { create(:routine, user: user) }
  let(:exercise) { create(:exercise) }
  let(:valid_attributes) do
    {
      exercise_id: exercise.id,
      sets: 3,
      reps: 12,
      rest_time: 60,
      order: 1
    }
  end

  let(:invalid_attributes) do
    {
      exercise_id: exercise.id,
      sets: -1,
      reps: 0,
      rest_time: -1,
      order: 0
    }
  end

  before do
    authenticate_user(user)
  end

  describe 'POST #create' do
    context 'with valid parameters' do
      it 'creates a new routine exercise' do
        expect {
          post :create, params: { 
            routine_id: routine.id,
            routine_exercise: valid_attributes
          }
        }.to change(RoutineExercise, :count).by(1)
      end

      it 'returns created status' do
        post :create, params: { 
          routine_id: routine.id,
          routine_exercise: valid_attributes
        }
        expect(response).to have_http_status(:created)
      end
    end

    context 'with invalid parameters' do
      it 'does not create a new routine exercise' do
        expect {
          post :create, params: { 
            routine_id: routine.id,
            routine_exercise: invalid_attributes
          }
        }.not_to change(RoutineExercise, :count)
      end

      it 'returns unprocessable entity status' do
        post :create, params: { 
          routine_id: routine.id,
          routine_exercise: invalid_attributes
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'with non-existent routine' do
      it 'returns not found status' do
        post :create, params: { 
          routine_id: 999,
          routine_exercise: valid_attributes
        }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'DELETE #destroy' do
    let!(:routine_exercise) { create(:routine_exercise, routine: routine) }

    it 'destroys the routine exercise' do
      expect {
        delete :destroy, params: { 
          routine_id: routine.id,
          id: routine_exercise.id
        }
      }.to change(RoutineExercise, :count).by(-1)
    end

    it 'returns no content status' do
      delete :destroy, params: { 
        routine_id: routine.id,
        id: routine_exercise.id
      }
      expect(response).to have_http_status(:no_content)
    end

    context 'with non-existent routine exercise' do
      it 'returns not found status' do
        delete :destroy, params: { 
          routine_id: routine.id,
          id: 999
        }
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end 