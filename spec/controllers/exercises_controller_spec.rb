require 'rails_helper'

RSpec.describe ExercisesController, type: :controller do
  let(:user) { create(:user) }
  let(:exercise) { create(:exercise, user: user) }
  let(:valid_attributes) do
    attributes_for(:exercise)
  end
  let(:invalid_attributes) do
    { name: '', category: '', level: '', instructions: '' }
  end

  before { authenticate_user(user) }

  describe 'GET #index' do
    it 'returns a successful response' do
      get :index
      expect(response).to be_successful
    end
  end

  describe 'GET #show' do
    it 'returns a successful response' do
      get :show, params: { id: exercise.id }
      expect(response).to be_successful
    end
    it 'returns 404 for non-existent exercise' do
      get :show, params: { id: 99999 }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST #create' do
    context 'with valid parameters' do
      it 'creates a new exercise' do
        expect {
          post :create, params: { exercise: valid_attributes }
        }.to change(Exercise, :count).by(1)
      end
      it 'returns created status' do
        post :create, params: { exercise: valid_attributes }
        expect(response).to have_http_status(:created)
      end
    end
    context 'with invalid parameters' do
      it 'does not create a new exercise' do
        expect {
          post :create, params: { exercise: invalid_attributes }
        }.not_to change(Exercise, :count)
      end
      it 'returns unprocessable entity status' do
        post :create, params: { exercise: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'PATCH #update' do
    context 'with valid parameters' do
      it 'updates the exercise' do
        patch :update, params: { id: exercise.id, exercise: { name: 'Updated' } }
        exercise.reload
        expect(exercise.name).to eq('Updated')
      end
    end
    context 'with invalid parameters' do
      it 'does not update the exercise' do
        patch :update, params: { id: exercise.id, exercise: { name: '' } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'destroys the exercise' do
      exercise_to_delete = create(:exercise, user: user)
      expect {
        delete :destroy, params: { id: exercise_to_delete.id }
      }.to change(Exercise, :count).by(-1)
    end
    it 'returns no content status' do
      exercise_to_delete = create(:exercise, user: user)
      delete :destroy, params: { id: exercise_to_delete.id }
      expect(response).to have_http_status(:no_content)
    end
  end
end 