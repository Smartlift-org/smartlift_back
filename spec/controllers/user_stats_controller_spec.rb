require 'rails_helper'

RSpec.describe UserStatsController, type: :controller do
  describe 'GET #index' do
    it 'returns a successful response' do
      get :index
      expect(response).to be_successful
    end
  end

  describe 'POST #create' do
    let(:valid_attributes) { { user_id: 1, height: 180.5, weight: 75.0, age: 30, gender: 'male', fitness_goal: 'lose weight', experience_level: 'beginner', available_days: 3, equipment_available: 'dumbbells', activity_level: 'moderate', physical_limitations: 'none' } }

    context 'with valid params' do
      it 'creates a new UserStat' do
        expect {
          post :create, params: { user_stat: valid_attributes }
        }.to change(UserStat, :count).by(1)
      end

      it 'renders a JSON response with the new user_stat' do
        post :create, params: { user_stat: valid_attributes }
        expect(response).to have_http_status(:created)
        expect(response.content_type).to match(a_string_including('application/json'))
      end
    end

    context 'with invalid params' do
      it 'renders a JSON response with errors for the new user_stat' do
        post :create, params: { user_stat: { user_id: nil } }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to match(a_string_including('application/json'))
      end
    end
  end

  describe 'PATCH #update' do
    let(:user_stat) { UserStat.create(user_id: 1, height: 180.5, weight: 75.0, age: 30, gender: 'male', fitness_goal: 'lose weight', experience_level: 'beginner', available_days: 3, equipment_available: 'dumbbells', activity_level: 'moderate', physical_limitations: 'none') }
    let(:new_attributes) { { height: 185.0 } }

    context 'with valid params' do
      it 'updates the requested user_stat' do
        patch :update, params: { id: user_stat.id, user_stat: new_attributes }
        user_stat.reload
        expect(user_stat.height).to eq(185.0)
      end

      it 'renders a JSON response with the user_stat' do
        patch :update, params: { id: user_stat.id, user_stat: new_attributes }
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to match(a_string_including('application/json'))
      end
    end

    context 'with invalid params' do
      it 'renders a JSON response with errors for the user_stat' do
        patch :update, params: { id: user_stat.id, user_stat: { user_id: nil } }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to match(a_string_including('application/json'))
      end
    end
  end
end 