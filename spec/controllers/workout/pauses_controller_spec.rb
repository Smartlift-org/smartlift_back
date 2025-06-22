require 'rails_helper'

RSpec.describe Workout::PausesController, type: :controller do
  let(:user) { create(:user) }
  let(:workout) { create(:workout, user: user) }
  let(:workout_pause) { create(:workout_pause, workout: workout) }

  before do
    allow(controller).to receive(:authenticate_user!)
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe 'GET #index' do
    let!(:pauses) { create_list(:workout_pause, 3, workout: workout) }

    it 'returns all pauses for the workout' do
      get :index, params: { workout_id: workout.id }
      expect(response).to have_http_status(:success)
      expect(assigns(:pauses)).to match_array(pauses)
    end

    it 'orders pauses by paused_at desc' do
      pause1 = create(:workout_pause, workout: workout, paused_at: 2.hours.ago)
      pause2 = create(:workout_pause, workout: workout, paused_at: 1.hour.ago)
      
      get :index, params: { workout_id: workout.id }
      ordered_pauses = assigns(:pauses)
      expect(ordered_pauses.first.paused_at).to be >= ordered_pauses.last.paused_at
    end

    it 'includes both active and completed pauses' do
      active_pause = create(:workout_pause, :active, workout: workout)
      completed_pause = create(:workout_pause, :completed, workout: workout)
      
      get :index, params: { workout_id: workout.id }
      expect(assigns(:pauses)).to include(active_pause, completed_pause)
    end
  end

  describe 'GET #show' do
    it 'returns the requested pause' do
      get :show, params: { workout_id: workout.id, id: workout_pause.id }
      expect(response).to have_http_status(:success)
      expect(assigns(:pause)).to eq(workout_pause)
    end

    it 'returns not found for non-existent pause' do
      expect {
        get :show, params: { workout_id: workout.id, id: 999999 }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe 'POST #create' do
    context 'with valid parameters' do
      let(:valid_attributes) {
        {
          reason: 'Water break'
        }
      }

      it 'creates a new pause' do
        expect {
          post :create, params: { 
            workout_id: workout.id, 
            pause: valid_attributes 
          }
        }.to change(WorkoutPause, :count).by(1)
      end

      it 'returns created status' do
        post :create, params: { 
          workout_id: workout.id, 
          pause: valid_attributes 
        }
        expect(response).to have_http_status(:created)
      end

      it 'sets paused_at timestamp' do
        post :create, params: { 
          workout_id: workout.id, 
          pause: valid_attributes 
        }
        
        created_pause = WorkoutPause.last
        expect(created_pause.paused_at).to be_present
      end

      it 'sets workout status to paused' do
        workout.update!(status: 'in_progress')
        post :create, params: { 
          workout_id: workout.id, 
          pause: valid_attributes 
        }
        
        expect(workout.reload.status).to eq('paused')
      end
    end

    context 'with invalid parameters' do
      it 'returns unprocessable entity when reason is missing' do
        post :create, params: { 
          workout_id: workout.id, 
          pause: { reason: '' } 
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'when workout is not active' do
      let(:completed_workout) { create(:workout, :completed, user: user) }

      it 'returns bad request' do
        post :create, params: { 
          workout_id: completed_workout.id, 
          pause: { reason: 'Cannot pause completed workout' } 
        }
        expect(response).to have_http_status(:bad_request)
      end
    end

    context 'when workout is already paused' do
      before do
        workout.update!(status: 'paused')
        create(:workout_pause, :active, workout: workout)
      end

      it 'returns bad request' do
        post :create, params: { 
          workout_id: workout.id, 
          pause: { reason: 'Already paused' } 
        }
        expect(response).to have_http_status(:bad_request)
      end
    end
  end

  describe 'PUT #resume' do
    let(:active_pause) { create(:workout_pause, :active, workout: workout) }

    before do
      workout.update!(status: 'paused')
    end

    it 'resumes the pause' do
      put :resume, params: { 
        workout_id: workout.id, 
        id: active_pause.id 
      }
      
      expect(response).to have_http_status(:success)
      active_pause.reload
      expect(active_pause.resumed_at).to be_present
      expect(active_pause.duration_seconds).to be_present
    end

    it 'sets workout status back to in_progress' do
      put :resume, params: { 
        workout_id: workout.id, 
        id: active_pause.id 
      }
      
      expect(workout.reload.status).to eq('in_progress')
    end

    context 'when pause is already completed' do
      let(:completed_pause) { create(:workout_pause, :completed, workout: workout) }

      it 'returns bad request' do
        put :resume, params: { 
          workout_id: workout.id, 
          id: completed_pause.id 
        }
        expect(response).to have_http_status(:bad_request)
      end
    end

    context 'when workout is not paused' do
      before do
        workout.update!(status: 'in_progress')
      end

      it 'returns bad request' do
        put :resume, params: { 
          workout_id: workout.id, 
          id: active_pause.id 
        }
        expect(response).to have_http_status(:bad_request)
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'deletes the pause' do
      pause_to_delete = create(:workout_pause, workout: workout)
      expect {
        delete :destroy, params: { 
          workout_id: workout.id, 
          id: pause_to_delete.id 
        }
      }.to change(WorkoutPause, :count).by(-1)
    end

    it 'returns success status' do
      delete :destroy, params: { 
        workout_id: workout.id, 
        id: workout_pause.id 
      }
      expect(response).to have_http_status(:success)
    end

    context 'when deleting an active pause' do
      let(:active_pause) { create(:workout_pause, :active, workout: workout) }

      before do
        workout.update!(status: 'paused')
      end

      it 'resumes the workout' do
        delete :destroy, params: { 
          workout_id: workout.id, 
          id: active_pause.id 
        }
        
        expect(workout.reload.status).to eq('in_progress')
      end
    end

    context 'when pause is completed' do
      let(:completed_pause) { create(:workout_pause, :completed, workout: workout) }

      it 'prevents deletion of completed pauses' do
        delete :destroy, params: { 
          workout_id: workout.id, 
          id: completed_pause.id 
        }
        expect(response).to have_http_status(:bad_request)
      end
    end
  end

  describe 'GET #current' do
    context 'when workout has an active pause' do
      let!(:active_pause) { create(:workout_pause, :active, workout: workout) }
      
      before do
        workout.update!(status: 'paused')
      end

      it 'returns the current active pause' do
        get :current, params: { workout_id: workout.id }
        expect(response).to have_http_status(:success)
        expect(assigns(:pause)).to eq(active_pause)
      end
    end

    context 'when workout has no active pause' do
      it 'returns not found' do
        get :current, params: { workout_id: workout.id }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'authentication and authorization' do
    let(:other_user) { create(:user) }
    let(:other_workout) { create(:workout, user: other_user) }
    let(:other_pause) { create(:workout_pause, workout: other_workout) }

    it 'prevents access to other users pauses' do
      expect {
        get :show, params: { workout_id: other_workout.id, id: other_pause.id }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'prevents creating pauses in other users workouts' do
      expect {
        post :create, params: { 
          workout_id: other_workout.id, 
          pause: { reason: 'Unauthorized pause' } 
        }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe 'pause duration tracking' do
    it 'tracks pause duration correctly' do
      freeze_time = Time.current
      travel_to freeze_time

      post :create, params: { 
        workout_id: workout.id, 
        pause: { reason: 'Timed break' } 
      }
      
      created_pause = WorkoutPause.last
      expect(created_pause.paused_at).to be_within(1.second).of(freeze_time)
      
      # Advance time and resume
      travel_to freeze_time + 5.minutes
      
      put :resume, params: { 
        workout_id: workout.id, 
        id: created_pause.id 
      }
      
      created_pause.reload
      expect(created_pause.duration_seconds).to be_within(5.seconds).of(5.minutes.to_i)
      
      travel_back
    end
  end

  describe 'real-world scenarios' do
    it 'handles multiple pause/resume cycles' do
      workout.update!(status: 'in_progress')
      
      # First pause
      post :create, params: { 
        workout_id: workout.id, 
        pause: { reason: 'Water break' } 
      }
      first_pause = WorkoutPause.last
      
      # Resume
      put :resume, params: { 
        workout_id: workout.id, 
        id: first_pause.id 
      }
      
      # Second pause
      post :create, params: { 
        workout_id: workout.id, 
        pause: { reason: 'Phone call' } 
      }
      second_pause = WorkoutPause.last
      
      # Resume again
      put :resume, params: { 
        workout_id: workout.id, 
        id: second_pause.id 
      }
      
      expect(workout.reload.status).to eq('in_progress')
      expect(workout.pauses.count).to eq(2)
      expect(workout.pauses.all?(&:completed?)).to be_truthy
    end
  end
end 