require 'rails_helper'

RSpec.describe ApiStatusController, type: :controller do
  describe 'GET #index' do
    it 'returns online status and endpoints' do
      get :index
      expect(response).to be_successful
      json = JSON.parse(response.body)
      expect(json['status']).to eq('online')
      expect(json['endpoints']).to be_a(Hash)
    end
  end
end 