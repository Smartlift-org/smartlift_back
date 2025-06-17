require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  let(:user) { create(:user) }
  let(:valid_attributes) { attributes_for(:user) }
  let(:invalid_attributes) { { email: '', password: '' } }

  describe 'POST #create' do
    it 'creates a new user with valid attributes' do
      expect {
        post :create, params: valid_attributes
      }.to change(User, :count).by(1)
    end
    it 'does not create a user with invalid attributes' do
      expect {
        post :create, params: invalid_attributes
      }.not_to change(User, :count)
    end
  end

  describe 'PATCH #update' do
    before { authenticate_user(user) }
    it 'updates the user with valid attributes' do
      patch :update, params: { id: user.id, first_name: 'Updated' }
      user.reload
      expect(user.first_name).to eq('Updated')
    end
    it 'does not update the user with invalid attributes' do
      patch :update, params: { id: user.id, email: '' }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'GET #profile' do
    before { authenticate_user(user) }
    it 'returns the user profile' do
      get :profile
      expect(response).to be_successful
      expect(JSON.parse(response.body)['email']).to eq(user.email)
    end
  end
end 