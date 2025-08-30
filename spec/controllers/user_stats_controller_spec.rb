require 'rails_helper'

RSpec.describe UserStatsController, type: :controller do
  let(:user) { User.create(email: 'test@example.com', password: 'password', first_name: 'Test', last_name: 'User') }
  let(:other_user) { User.create(email: 'other@example.com', password: 'password', first_name: 'Other', last_name: 'User') }

  before do
    authenticate_user(user)
  end

  describe 'GET #index' do
    context 'when user has stats' do
      let!(:user_stat) { UserStat.create(user: user, height: 180.5, weight: 75.0, age: 30, gender: 'male', fitness_goal: 'lose weight', experience_level: 'beginner', available_days: 3, equipment_available: 'dumbbells', activity_level: 'moderate', physical_limitations: 'none') }

      it 'returns the user stats' do
        get :index
        expect(response).to be_successful
        expect(JSON.parse(response.body)['id']).to eq(user_stat.id)
      end
    end

    context 'when user has no stats' do
      it 'returns not found' do
        get :index
        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)['error']).to eq('No user stats found')
      end
    end
  end

  describe 'GET #complete' do
    context 'when user is authenticated' do
      it 'returns complete stats structure' do
        get :complete
        expect(response).to be_successful

        json_response = JSON.parse(response.body)
        expect(json_response).to include('profile', 'performance', 'analytics', 'personal_records')
      end

      context 'when user has no data' do
        it 'returns empty stats' do
          get :complete

          json_response = JSON.parse(response.body)
          expect(json_response['profile']).to eq({})
          expect(json_response['performance']).to eq({})
          expect(json_response['analytics']).to eq({})
          expect(json_response['personal_records']['message']).to eq('No hay PRs registrados')
        end
      end

      context 'when user has profile data' do
        let!(:user_stat) { UserStat.create(user: user, height: 180.5, weight: 75.0, age: 30, gender: 'male', fitness_goal: 'lose weight', experience_level: 'beginner', available_days: 3, equipment_available: 'dumbbells', activity_level: 'moderate', physical_limitations: 'none') }

        it 'returns profile data' do
          get :complete

          json_response = JSON.parse(response.body)
          expect(json_response['profile']['weight']).to eq(75.0)
          expect(json_response['profile']['height']).to eq(180.5)
          expect(json_response['profile']['age']).to eq(30)
        end
      end

      context 'when user has workout data' do
        let!(:user_stat) { UserStat.create(user: user, weight: 70.0) }
        let!(:workout) { create(:workout, :completed, user: user) }
        let!(:exercise) { create(:workout_exercise, workout: workout) }
        let!(:set) { create(:workout_set, :completed, exercise: exercise, weight: 80, reps: 8, rpe: 7) }

        it 'returns analytics data' do
          get :complete

          json_response = JSON.parse(response.body)
          expect(json_response['analytics']).not_to be_empty
          expect(json_response['analytics']['intensity_distribution']).to include('heavy')
        end
      end

      context 'when user has personal records' do
        let!(:workout) { create(:workout, :completed, user: user) }
        let!(:exercise) { create(:workout_exercise, workout: workout) }
        let!(:pr_set) { create(:workout_set, :weight_pr, exercise: exercise, weight: 100, reps: 5) }

        it 'returns performance data' do
          # Create user_stat for the authenticated user
          UserStat.create!(user: user, weight: 70.0, experience_level: 'beginner', activity_level: 'moderate', physical_limitations: 'none')
          
          get :complete

          json_response = JSON.parse(response.body)
          expect(json_response['performance']).not_to be_empty
          expect(json_response['performance']['one_rep_maxes']).not_to be_empty
          expect(json_response['performance']['relative_strength']).not_to be_empty
          expect(json_response['performance']['top_exercises']).to be_an(Array)
        end

        it 'returns personal records data' do
          get :complete

          json_response = JSON.parse(response.body)
          expect(json_response['personal_records']).not_to include('message')
          expect(json_response['personal_records']).to include('recent', 'by_exercise', 'statistics')
        end
      end
    end
  end

  describe 'POST #create' do
    let(:valid_attributes) do
      {
        user_stat: {
          height: 180.5,
          weight: 75.0,
          age: 30,
          gender: 'male',
          fitness_goal: 'lose weight',
          experience_level: 'beginner',
          available_days: 3,
          equipment_available: 'dumbbells',
          activity_level: 'moderate',
          physical_limitations: 'none'
        }
      }
    end

    context 'when user has no stats' do
      it 'creates a new UserStat' do
        expect {
          post :create, params: valid_attributes
        }.to change(UserStat, :count).by(1)
      end

      it 'renders a JSON response with the new user_stat' do
        post :create, params: valid_attributes
        expect(response).to have_http_status(:created)
        expect(response.content_type).to match(a_string_including('application/json'))
      end
    end

    context 'when user already has stats' do
      before do
        UserStat.create(user: user, height: 180.5, weight: 75.0, age: 30, gender: 'male', fitness_goal: 'lose weight', experience_level: 'beginner', available_days: 3, equipment_available: 'dumbbells', activity_level: 'moderate', physical_limitations: 'none')
      end

      it 'does not create a new UserStat' do
        expect {
          post :create, params: valid_attributes
        }.not_to change(UserStat, :count)
      end

      it 'returns unprocessable entity' do
        post :create, params: valid_attributes
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['error']).to eq('User stats already exist')
      end
    end

    context 'with invalid params' do
      it 'renders a JSON response with errors' do
        post :create, params: { user_stat: { experience_level: 'invalid' } }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to match(a_string_including('application/json'))
      end
    end
  end

  describe 'PATCH #update' do
    let(:user_stat) { UserStat.create(user: user, height: 180.5, weight: 75.0, age: 30, gender: 'male', fitness_goal: 'lose weight', experience_level: 'beginner', available_days: 3, equipment_available: 'dumbbells', activity_level: 'moderate', physical_limitations: 'none') }
    let(:new_attributes) { { user_stat: { height: 185.0 } } }

    context 'when updating own stats' do
      it 'updates the requested user_stat' do
        patch :update, params: { id: user_stat.id }.merge(new_attributes)
        user_stat.reload
        expect(user_stat.height).to eq(185.0)
      end

      it 'renders a JSON response with the user_stat' do
        patch :update, params: { id: user_stat.id }.merge(new_attributes)
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to match(a_string_including('application/json'))
      end
    end

    context 'when updating other user stats' do
      let(:other_user_stat) { UserStat.create(user: other_user, height: 180.5, weight: 75.0, age: 30, gender: 'male', fitness_goal: 'lose weight', experience_level: 'beginner', available_days: 3, equipment_available: 'dumbbells', activity_level: 'moderate', physical_limitations: 'none') }

      it 'returns not found' do
        patch :update, params: { id: other_user_stat.id }.merge(new_attributes)
        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)['error']).to eq('No user stats found')
      end
    end

    context 'with invalid params' do
      it 'renders a JSON response with errors' do
        patch :update, params: { id: user_stat.id, user_stat: { experience_level: 'invalid' } }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to match(a_string_including('application/json'))
      end
    end
  end
end
