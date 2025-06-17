require 'rails_helper'

RSpec.describe AuthController, type: :controller do
  let!(:user) { create(:user, email: 'test@example.com', password: 'password123') }

  describe 'POST #login' do
    it 'returns a token with valid credentials' do
      post :login, params: { email: 'test@example.com', password: 'password123' }
      expect(response).to be_successful
      expect(JSON.parse(response.body)).to have_key('token')
    end
    it 'returns error with invalid credentials' do
      post :login, params: { email: 'test@example.com', password: 'wrong' }
      expect(response).to have_http_status(:unauthorized)
    end
    it 'returns error with invalid email format' do
      post :login, params: { email: 'invalid', password: 'password123' }
      expect(response).to have_http_status(:unprocessable_entity)
    end
    it 'returns error with missing params' do
      post :login, params: { email: '', password: '' }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end 