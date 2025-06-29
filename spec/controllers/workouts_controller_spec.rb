require 'rails_helper'

RSpec.describe WorkoutsController, type: :controller do
  let(:user) { create(:user) }
  let(:routine) { create(:routine, user: user) }
  let(:workout) { create(:workout, user: user, routine: routine) }

  before do
    allow(controller).to receive(:authenticate_user!)
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe 'POST #create' do
    context 'with valid parameters' do
      let(:valid_attributes) { { routine_id: routine.id } }

      it 'creates a new workout' do
        expect {
          post :create, params: { workout: valid_attributes }
        }.to change(Workout, :count).by(1)
      end

      it 'returns created status' do
        post :create, params: { workout: valid_attributes }
        expect(response).to have_http_status(:created)
      end

      it 'sets started_at timestamp' do
        post :create, params: { workout: valid_attributes }
        created_workout = Workout.last
        expect(created_workout.started_at).to be_present
      end

      it 'copies exercises from routine' do
        create_list(:routine_exercise, 3, routine: routine)
        post :create, params: { workout: valid_attributes }
        created_workout = Workout.last
        expect(created_workout.exercises.count).to eq(3)
      end
    end

    context 'with invalid parameters' do
      it 'returns unprocessable entity when routine is missing' do
        post :create, params: { workout: { routine_id: nil } }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns error when user already has active workout' do
        create(:workout, user: user, status: 'in_progress')
        post :create, params: { workout: { routine_id: routine.id } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'POST #create_free' do
    context 'with valid parameters' do
      let(:valid_attributes) { { name: 'My Free Workout' } }

      it 'creates a new free-style workout' do
        expect {
          post :create_free, params: { workout: valid_attributes }
        }.to change(Workout, :count).by(1)
      end

      it 'sets workout_type to free_style' do
        post :create_free, params: { workout: valid_attributes }
        created_workout = Workout.last
        expect(created_workout.workout_type).to eq('free_style')
      end

      it 'does not copy exercises' do
        post :create_free, params: { workout: valid_attributes }
        created_workout = Workout.last
        expect(created_workout.exercises.count).to eq(0)
      end

      it 'returns created status' do
        post :create_free, params: { workout: valid_attributes }
        expect(response).to have_http_status(:created)
      end
    end

    context 'with invalid parameters' do
      it 'returns unprocessable entity when name is missing' do
        post :create_free, params: { workout: { name: '' } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'GET #index' do
    let!(:workouts) { create_list(:workout, 3, user: user) }

    it 'returns all user workouts' do
      get :index
      expect(response).to have_http_status(:success)
      expect(assigns(:workouts)).to match_array(workouts)
    end

    it 'orders workouts by most recent first' do
      travel_to 2.days.ago do
        @old_workout = create(:workout, user: user)
      end
      travel_to 1.day.ago do
        @new_workout = create(:workout, user: user)
      end
      
      get :index
      ordered_workouts = assigns(:workouts).where(id: [@old_workout.id, @new_workout.id])
      expect(ordered_workouts.first).to eq(@new_workout)
    end

    it 'includes exercises data' do
      workout_with_data = create(:workout, :with_exercises, user: user)
      get :index
      expect(assigns(:workouts)).to include(workout_with_data)
    end
  end

  describe 'GET #show' do
    it 'returns the requested workout' do
      get :show, params: { id: workout.id }
      expect(response).to have_http_status(:success)
      expect(assigns(:workout)).to eq(workout)
    end

    it 'returns not found for non-existent workout' do
      expect {
        get :show, params: { id: 999999 }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe 'PUT #pause' do
    context 'with active workout' do
      let(:workout) { create(:workout, user: user, status: 'in_progress') }

      it 'pauses the workout' do
        put :pause, params: { id: workout.id }
        expect(response).to have_http_status(:success)
        expect(workout.reload.status).to eq('paused')
      end
    end

    context 'with inactive workout' do
      let(:workout) { create(:workout, user: user, status: 'completed') }

      it 'returns bad request' do
        put :pause, params: { id: workout.id }
        expect(response).to have_http_status(:bad_request)
      end
    end

    context 'when pause fails' do
      let(:workout) { create(:workout, user: user, status: 'paused') }

      it 'returns unprocessable entity' do
        put :pause, params: { id: workout.id }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'PUT #resume' do
    context 'with paused workout' do
      let(:workout) { create(:workout, user: user, status: 'paused') }

      it 'resumes the workout' do
        put :resume, params: { id: workout.id }
        expect(response).to have_http_status(:success)
        expect(workout.reload.status).to eq('in_progress')
      end
    end

    context 'with non-paused workout' do
      let(:workout) { create(:workout, user: user, status: 'in_progress') }

      it 'returns unprocessable entity' do
        put :resume, params: { id: workout.id }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'PUT #complete' do
    context 'with active workout' do
      let(:workout) { create(:workout, :with_exercises, user: user, status: 'in_progress') }

      it 'completes the workout' do
        put :complete, params: { 
          id: workout.id,
          perceived_intensity: 8,
          energy_level: 7,
          mood: 'great'
        }
        expect(response).to have_http_status(:success)
        expect(workout.reload.status).to eq('completed')
      end

      it 'updates completion parameters' do
        put :complete, params: { 
          id: workout.id,
          perceived_intensity: 8,
          energy_level: 7,
          mood: 'great',
          notes: 'Excellent workout!'
        }
        
        workout.reload
        expect(workout.perceived_intensity).to eq(8)
        expect(workout.energy_level).to eq(7)
        expect(workout.mood).to eq('great')
        expect(workout.notes).to eq('Excellent workout!')
      end

      it 'sets completed_at timestamp' do
        put :complete, params: { id: workout.id }
        expect(workout.reload.completed_at).to be_present
      end
    end

    context 'with inactive workout' do
      let(:workout) { create(:workout, user: user, status: 'completed') }

      it 'returns bad request' do
        put :complete, params: { id: workout.id }
        expect(response).to have_http_status(:bad_request)
      end
    end

    context 'when completion fails' do
      let(:workout) { create(:workout, user: user, status: 'in_progress') }

      it 'returns unprocessable entity with error messages' do
        # Mock the complete! method to return false and set up errors
        allow_any_instance_of(Workout).to receive(:complete!).and_return(false)
        
        put :complete, params: { id: workout.id }
        expect(response).to have_http_status(:unprocessable_entity)
        response_body = JSON.parse(response.body)
        expect(response_body).to have_key('errors')
      end
    end
  end

  describe 'PUT #abandon' do
    context 'with active workout' do
      let(:workout) { create(:workout, user: user, status: 'in_progress') }

      it 'abandons the workout' do
        put :abandon, params: { id: workout.id }
        expect(response).to have_http_status(:success)
        expect(workout.reload.status).to eq('abandoned')
      end

      it 'sets completed_at timestamp' do
        put :abandon, params: { id: workout.id }
        expect(workout.reload.completed_at).to be_present
      end
    end

    context 'with completed workout' do
      let(:workout) { create(:workout, user: user, status: 'completed') }

      it 'returns unprocessable entity' do
        put :abandon, params: { id: workout.id }
        expect(response).to have_http_status(:unprocessable_entity)
        response_body = JSON.parse(response.body)
        expect(response_body['error']).to eq('Cannot abandon a completed workout')
      end
    end

    context 'when abandon fails' do
      let(:workout) { create(:workout, user: user, status: 'in_progress') }

      before do
        allow_any_instance_of(Workout).to receive(:abandon!).and_return(false)
      end

      it 'returns unprocessable entity' do
        put :abandon, params: { id: workout.id }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'authentication' do
    it 'requires authentication for all actions' do
      expect(controller).to receive(:authenticate_user!).and_call_original
      get :index
    end
  end

  describe 'authorization' do
    let(:other_user) { create(:user) }
    let(:other_workout) { create(:workout, user: other_user) }

    it 'prevents access to other users workouts' do
      expect {
        get :show, params: { id: other_workout.id }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end 