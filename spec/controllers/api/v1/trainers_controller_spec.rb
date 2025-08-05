require 'rails_helper'

RSpec.describe Api::V1::TrainersController, type: :controller do
  let(:trainer) { create(:user, role: :coach, first_name: 'Carlos', last_name: 'Trainer') }
  let(:regular_user) { create(:user, role: :user) }
  let(:member1) { create(:user, role: :user, first_name: 'Juan', last_name: 'Socio') }
  let(:member2) { create(:user, role: :user, first_name: 'Maria', last_name: 'Miembro') }
  let(:other_trainer) { create(:user, role: :coach) }

  before do
    # Create coach-user relationships
    create(:coach_user, coach: trainer, user: member1)
    create(:coach_user, coach: trainer, user: member2)
    
    # Create some workouts for activity data
    create(:workout, user: member1, status: 'completed', created_at: 1.week.ago)
    create(:workout, user: member2, status: 'in_progress', created_at: 2.days.ago)
  end

  describe 'GET #show' do
    context 'when authenticated as trainer' do
      before { allow(controller).to receive(:current_user).and_return(trainer) }

      it 'returns trainer information' do
        get :show, params: { id: trainer.id }
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        
        expect(json_response['name']).to eq('Carlos Trainer')
        expect(json_response['email']).to eq(trainer.email)
        expect(json_response['members_count']).to eq(2)
      end
    end

    context 'when authenticated as regular user' do
      before { allow(controller).to receive(:current_user).and_return(regular_user) }

      it 'returns forbidden status' do
        get :show, params: { id: trainer.id }
        
        expect(response).to have_http_status(:forbidden)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to include('Solo entrenadores')
      end
    end

    context 'when trainer not found' do
      before { allow(controller).to receive(:current_user).and_return(trainer) }

      it 'returns not found status' do
        get :show, params: { id: 99999 }
        
        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Entrenador no encontrado')
      end
    end
  end

  describe 'GET #members' do
    context 'when authenticated as the trainer' do
      before { allow(controller).to receive(:current_user).and_return(trainer) }

      it 'returns list of members' do
        get :members, params: { id: trainer.id }
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        
        expect(json_response['members'].length).to eq(2)
        expect(json_response['pagination']['total_count']).to eq(2)
        
        member_names = json_response['members'].map { |m| m['name'] }
        expect(member_names).to include('Juan Socio', 'Maria Miembro')
      end

      it 'includes member activity data' do
        get :members, params: { id: trainer.id }
        
        json_response = JSON.parse(response.body)
        first_member = json_response['members'].first
        
        expect(first_member).to have_key('activity')
        expect(first_member['activity']).to have_key('total_workouts')
        expect(first_member['activity']).to have_key('recent_workouts')
        expect(first_member['activity']).to have_key('activity_status')
      end

      it 'supports search filtering' do
        get :members, params: { id: trainer.id, search: 'Juan' }
        
        json_response = JSON.parse(response.body)
        expect(json_response['members'].length).to eq(1)
        expect(json_response['members'].first['name']).to eq('Juan Socio')
        expect(json_response['filters_applied']['search']).to eq('Juan')
      end

      it 'supports pagination' do
        get :members, params: { id: trainer.id, page: 1, per_page: 1 }
        
        json_response = JSON.parse(response.body)
        expect(json_response['members'].length).to eq(1)
        expect(json_response['pagination']['current_page']).to eq(1)
        expect(json_response['pagination']['total_pages']).to eq(2)
        expect(json_response['pagination']['per_page']).to eq(1)
      end

      it 'supports status filtering for active members' do
        get :members, params: { id: trainer.id, status: 'active' }
        
        json_response = JSON.parse(response.body)
        expect(json_response['filters_applied']['status']).to eq('active')
        # Should return members with recent workouts
        expect(json_response['members'].length).to be >= 1
      end
    end

    context 'when authenticated as different trainer' do
      before { allow(controller).to receive(:current_user).and_return(other_trainer) }

      it 'returns forbidden status' do
        get :members, params: { id: trainer.id }
        
        expect(response).to have_http_status(:forbidden)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to include('No tienes permisos')
      end
    end

    context 'when authenticated as regular user' do
      before { allow(controller).to receive(:current_user).and_return(regular_user) }

      it 'returns forbidden status' do
        get :members, params: { id: trainer.id }
        
        expect(response).to have_http_status(:forbidden)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to include('Solo entrenadores')
      end
    end

    context 'when not authenticated' do
      before { allow(controller).to receive(:current_user).and_return(nil) }

      it 'returns unauthorized status' do
        get :members, params: { id: trainer.id }
        
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'authorization' do
    it 'validates trainer role before accessing endpoints' do
      allow(controller).to receive(:current_user).and_return(regular_user)
      
      get :show, params: { id: trainer.id }
      expect(response).to have_http_status(:forbidden)
      
      get :members, params: { id: trainer.id }
      expect(response).to have_http_status(:forbidden)
    end

    it 'validates trainer can only access own data' do
      allow(controller).to receive(:current_user).and_return(other_trainer)
      
      get :members, params: { id: trainer.id }
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST #assign_member' do
    let(:unassigned_user) { create(:user, role: :user, first_name: 'Carlos', last_name: 'Nuevo') }

    context 'when authenticated as the trainer' do
      before { allow(controller).to receive(:current_user).and_return(trainer) }

      it 'assigns a member successfully' do
        post :assign_member, params: { id: trainer.id, user_id: unassigned_user.id }
        
        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        
        expect(json_response['message']).to eq('Socio asignado exitosamente')
        expect(json_response['assignment']['member']['name']).to eq('Carlos Nuevo')
        expect(json_response['assignment']['trainer_id']).to eq(trainer.id)
        
        # Verify the assignment was created in database
        expect(CoachUser.exists?(coach: trainer, user: unassigned_user)).to be true
      end

      it 'returns error when user not found' do
        post :assign_member, params: { id: trainer.id, user_id: 99999 }
        
        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Usuario no encontrado')
      end

      it 'returns error when user already assigned' do
        post :assign_member, params: { id: trainer.id, user_id: member1.id }
        
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to include('ya está asignado')
        expect(json_response['member']['name']).to eq('Juan Socio')
      end

      it 'returns error when trying to assign a coach' do
        coach_user = create(:user, role: :coach)
        post :assign_member, params: { id: trainer.id, user_id: coach_user.id }
        
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Error al asignar socio')
      end
    end

    context 'when authenticated as different trainer' do
      before { allow(controller).to receive(:current_user).and_return(other_trainer) }

      it 'returns forbidden status' do
        post :assign_member, params: { id: trainer.id, user_id: unassigned_user.id }
        
        expect(response).to have_http_status(:forbidden)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to include('No tienes permisos')
      end
    end
  end

  describe 'DELETE #unassign_member' do
    context 'when authenticated as the trainer' do
      before { allow(controller).to receive(:current_user).and_return(trainer) }

      it 'unassigns a member successfully' do
        delete :unassign_member, params: { id: trainer.id, user_id: member1.id }
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        
        expect(json_response['message']).to eq('Socio desasignado exitosamente')
        expect(json_response['unassigned']['member']['name']).to eq('Juan Socio')
        expect(json_response['unassigned']['trainer_id']).to eq(trainer.id)
        
        # Verify the assignment was removed from database
        expect(CoachUser.exists?(coach: trainer, user: member1)).to be false
      end

      it 'returns error when user not found' do
        delete :unassign_member, params: { id: trainer.id, user_id: 99999 }
        
        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Usuario no encontrado')
      end

      it 'returns error when user not assigned to trainer' do
        unassigned_user = create(:user, role: :user)
        delete :unassign_member, params: { id: trainer.id, user_id: unassigned_user.id }
        
        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to include('no está asignado')
        expect(json_response['member']['id']).to eq(unassigned_user.id)
      end
    end

    context 'when authenticated as different trainer' do
      before { allow(controller).to receive(:current_user).and_return(other_trainer) }

      it 'returns forbidden status' do
        delete :unassign_member, params: { id: trainer.id, user_id: member1.id }
        
        expect(response).to have_http_status(:forbidden)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to include('No tienes permisos')
      end
    end
  end

  describe 'GET #dashboard' do
    context 'when authenticated as the trainer' do
      before { allow(controller).to receive(:current_user).and_return(trainer) }

      it 'returns dashboard data successfully' do
        get :dashboard, params: { id: trainer.id }
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        
        expect(json_response).to have_key('trainer')
        expect(json_response).to have_key('dashboard')
        expect(json_response).to have_key('generated_at')
        
        expect(json_response['trainer']['id']).to eq(trainer.id)
        expect(json_response['trainer']['name']).to eq('Carlos Trainer')
      end

      it 'includes overview statistics' do
        get :dashboard, params: { id: trainer.id }
        
        json_response = JSON.parse(response.body)
        overview = json_response['dashboard']['overview']
        
        expect(overview).to have_key('total_members')
        expect(overview).to have_key('active_members')
        expect(overview).to have_key('inactive_members')
        expect(overview).to have_key('activity_rate')
        expect(overview).to have_key('total_workouts')
        expect(overview).to have_key('completed_workouts')
        expect(overview).to have_key('completion_rate')
        
        expect(overview['total_members']).to eq(2)
      end

      it 'includes activity metrics' do
        get :dashboard, params: { id: trainer.id }
        
        json_response = JSON.parse(response.body)
        activity_metrics = json_response['dashboard']['activity_metrics']
        
        expect(activity_metrics).to have_key('weekly_activity')
        expect(activity_metrics).to have_key('avg_workouts_per_member')
        expect(activity_metrics).to have_key('most_active_day')
        expect(activity_metrics).to have_key('peak_hours')
        
        expect(activity_metrics['weekly_activity']).to be_an(Array)
        expect(activity_metrics['weekly_activity'].length).to eq(8)
      end

      it 'includes performance trends' do
        get :dashboard, params: { id: trainer.id }
        
        json_response = JSON.parse(response.body)
        performance = json_response['dashboard']['performance_trends']
        
        expect(performance).to have_key('monthly_ratings')
        expect(performance).to have_key('personal_records_trend')
        expect(performance).to have_key('avg_session_duration')
        expect(performance).to have_key('progress_indicators')
        
        expect(performance['monthly_ratings']).to be_an(Array)
        expect(performance['monthly_ratings'].length).to eq(6)
      end

      it 'includes member distribution data' do
        get :dashboard, params: { id: trainer.id }
        
        json_response = JSON.parse(response.body)
        distribution = json_response['dashboard']['member_distribution']
        
        expect(distribution).to have_key('experience_levels')
        expect(distribution).to have_key('fitness_goals')
        expect(distribution).to have_key('activity_levels')
        expect(distribution).to have_key('age_ranges')
        
        expect(distribution['age_ranges']).to be_a(Hash)
        expect(distribution['age_ranges']).to have_key('18-25')
      end

      it 'includes recent activity' do
        get :dashboard, params: { id: trainer.id }
        
        json_response = JSON.parse(response.body)
        recent_activity = json_response['dashboard']['recent_activity']
        
        expect(recent_activity).to be_an(Array)
        expect(recent_activity.length).to be <= 10
        
        if recent_activity.any?
          activity = recent_activity.first
          expect(activity).to have_key('id')
          expect(activity).to have_key('member')
          expect(activity).to have_key('status')
          expect(activity).to have_key('created_at')
        end
      end

      it 'includes top performers' do
        get :dashboard, params: { id: trainer.id }
        
        json_response = JSON.parse(response.body)
        top_performers = json_response['dashboard']['top_performers']
        
        expect(top_performers).to have_key('consistency_leaders')
        expect(top_performers).to have_key('pr_leaders')
        
        expect(top_performers['consistency_leaders']).to be_an(Array)
        expect(top_performers['pr_leaders']).to be_an(Array)
        
        if top_performers['consistency_leaders'].any?
          leader = top_performers['consistency_leaders'].first
          expect(leader).to have_key('id')
          expect(leader).to have_key('name')
          expect(leader).to have_key('recent_workouts')
          expect(leader).to have_key('consistency_score')
        end
      end

      it 'calculates activity rate correctly' do
        get :dashboard, params: { id: trainer.id }
        
        json_response = JSON.parse(response.body)
        overview = json_response['dashboard']['overview']
        
        total_members = overview['total_members']
        active_members = overview['active_members']
        activity_rate = overview['activity_rate']
        
        expected_rate = total_members > 0 ? ((active_members.to_f / total_members) * 100).round(1) : 0
        expect(activity_rate).to eq(expected_rate)
      end

      it 'calculates completion rate correctly' do
        get :dashboard, params: { id: trainer.id }
        
        json_response = JSON.parse(response.body)
        overview = json_response['dashboard']['overview']
        
        total_workouts = overview['total_workouts']
        completed_workouts = overview['completed_workouts']
        completion_rate = overview['completion_rate']
        
        expected_rate = total_workouts > 0 ? ((completed_workouts.to_f / total_workouts) * 100).round(1) : 0
        expect(completion_rate).to eq(expected_rate)
      end
    end

    context 'when authenticated as different trainer' do
      before { allow(controller).to receive(:current_user).and_return(other_trainer) }

      it 'returns forbidden status' do
        get :dashboard, params: { id: trainer.id }
        
        expect(response).to have_http_status(:forbidden)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to include('No tienes permisos')
      end
    end

    context 'when authenticated as regular user' do
      before { allow(controller).to receive(:current_user).and_return(regular_user) }

      it 'returns forbidden status' do
        get :dashboard, params: { id: trainer.id }
        
        expect(response).to have_http_status(:forbidden)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to include('Solo entrenadores')
      end
    end

    context 'when trainer not found' do
      before { allow(controller).to receive(:current_user).and_return(trainer) }

      it 'returns not found status' do
        get :dashboard, params: { id: 99999 }
        
        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Entrenador no encontrado')
      end
    end

    context 'with extensive test data' do
      let(:member3) { create(:user, role: :user, first_name: 'Ana', last_name: 'García') }
      let(:member4) { create(:user, role: :user, first_name: 'Luis', last_name: 'López') }

      before do
        allow(controller).to receive(:current_user).and_return(trainer)
        
        # Add more members
        create(:coach_user, coach: trainer, user: member3)
        create(:coach_user, coach: trainer, user: member4)
        
        # Create user stats for distribution testing
        create(:user_stat, user: member3, age: 25, experience_level: 'beginner', fitness_goal: 'lose_weight')
        create(:user_stat, user: member4, age: 35, experience_level: 'advanced', fitness_goal: 'build_muscle')
        
        # Create more workouts for better statistics
        create(:workout, user: member3, status: 'completed', workout_rating: 8, created_at: 5.days.ago)
        create(:workout, user: member4, status: 'completed', workout_rating: 9, created_at: 3.days.ago)
        create(:workout, user: member3, status: 'in_progress', created_at: 1.day.ago)
      end

      it 'returns accurate statistics with more data' do
        get :dashboard, params: { id: trainer.id }
        
        json_response = JSON.parse(response.body)
        overview = json_response['dashboard']['overview']
        
        expect(overview['total_members']).to eq(4)
        expect(overview['active_members']).to be >= 2
        expect(overview['total_workouts']).to be >= 5
      end

      it 'calculates age distribution correctly' do
        get :dashboard, params: { id: trainer.id }
        
        json_response = JSON.parse(response.body)
        age_ranges = json_response['dashboard']['member_distribution']['age_ranges']
        
        expect(age_ranges['18-25']).to eq(1)
        expect(age_ranges['26-35']).to eq(1)
      end

      it 'calculates experience distribution correctly' do
        get :dashboard, params: { id: trainer.id }
        
        json_response = JSON.parse(response.body)
        experience_levels = json_response['dashboard']['member_distribution']['experience_levels']
        
        expect(experience_levels['beginner']).to eq(1)
        expect(experience_levels['advanced']).to eq(1)
      end
    end
  end

  describe 'member assignment validation' do
    before { allow(controller).to receive(:current_user).and_return(trainer) }

    it 'maintains referential integrity' do
      initial_count = CoachUser.count
      
      post :assign_member, params: { id: trainer.id, user_id: member1.id }
      expect(CoachUser.count).to eq(initial_count) # No new assignment (already exists)
      
      unassigned_user = create(:user, role: :user)
      post :assign_member, params: { id: trainer.id, user_id: unassigned_user.id }
      expect(CoachUser.count).to eq(initial_count + 1) # New assignment created
      
      delete :unassign_member, params: { id: trainer.id, user_id: unassigned_user.id }
      expect(CoachUser.count).to eq(initial_count) # Assignment removed
    end
  end

  describe 'GET #inactive_members' do
    let(:active_member) { create(:user, role: :user, first_name: 'Active', last_name: 'Member') }
    let(:inactive_member) { create(:user, role: :user, first_name: 'Inactive', last_name: 'Member') }

    before do
      # Set up coach-member relationships
      create(:coach_user, coach: trainer, user: active_member)
      create(:coach_user, coach: trainer, user: inactive_member)

      # Set activity dates
      active_member.update!(last_activity_at: 1.week.ago)
      inactive_member.update!(last_activity_at: 35.days.ago) # Inactive (>30 days)

      allow(controller).to receive(:current_user).and_return(trainer)
    end

    context 'when authenticated as trainer' do
      it 'returns only inactive members' do
        get :inactive_members, params: { id: trainer.id }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)

        expect(json_response['members'].length).to eq(1)
        expect(json_response['members'].first['name']).to eq('Inactive Member')
      end

      it 'supports search functionality' do
        get :inactive_members, params: { id: trainer.id, search: 'Inactive' }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)

        expect(json_response['members'].length).to eq(1)
        expect(json_response['members'].first['name']).to eq('Inactive Member')
      end

      it 'supports pagination' do
        get :inactive_members, params: { id: trainer.id, page: 1, per_page: 10 }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)

        expect(json_response['pagination']).to be_present
        expect(json_response['pagination']['current_page']).to eq(1)
        expect(json_response['pagination']['per_page']).to eq(10)
      end
    end

    context 'when accessing another trainer\'s data' do
      let(:other_trainer) { create(:user, role: :coach) }

      before { allow(controller).to receive(:current_user).and_return(other_trainer) }

      it 'returns forbidden status' do
        get :inactive_members, params: { id: trainer.id }

        expect(response).to have_http_status(:forbidden)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to include('No tienes permisos')
      end
    end
  end
end
