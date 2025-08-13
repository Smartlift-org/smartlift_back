class Api::V1::TrainersController < ApplicationController
  before_action :authorize_request
  before_action :ensure_trainer_role
  before_action :set_trainer, only: [ :show, :members, :inactive_members, :assign_member, :unassign_member, :dashboard, :available_users, :list_routines, :assign_routine, :update_member_routine ]

  def show
    render json: {
      id: @trainer.id,
      name: "#{@trainer.first_name} #{@trainer.last_name}",
      email: @trainer.email,
      members_count: @trainer.users.count
    }
  end

  def members
    authorize_trainer_access!(@trainer.id)
    return if performed?

    members = @trainer.users.preload(:user_stat, :workouts)

    if params[:search].present?
      search_term = "%#{params[:search].downcase}%"
      members = members.where(
        "LOWER(first_name) LIKE ? OR LOWER(last_name) LIKE ? OR LOWER(email) LIKE ?",
        search_term, search_term, search_term
      )
    end

    if params[:status].present?
      case params[:status]
      when "active"
        members = members.joins(:workouts)
                        .where(workouts: { created_at: 30.days.ago.. })
                        .group("users.id")
      when "inactive"
        active_member_ids = User.joins(:workouts)
                               .where(workouts: { created_at: 30.days.ago.. })
                               .group("users.id")
                               .pluck(:id)
        members = members.where.not(id: active_member_ids)
      end
    end

    members = members.left_joins(:workouts)
                    .group("users.id")
                    .order("MAX(workouts.created_at) DESC NULLS LAST, users.created_at DESC")
    page = params[:page] || 1
    per_page = [ params[:per_page]&.to_i || 20, 100 ].min

    paginated_members = members.page(page).per(per_page)

    members_data = paginated_members.map do |member|
      MemberSummarySerializer.new(member).as_json
    end

    render json: {
      members: members_data,
      pagination: {
        current_page: paginated_members.current_page,
        total_pages: paginated_members.total_pages,
        total_count: paginated_members.total_count,
        per_page: paginated_members.limit_value
      },
      filters_applied: {
        search: params[:search],
        status: params[:status]
      }
    }
  end

  def inactive_members
    authorize_trainer_access!(@trainer.id)
    return if performed?

    # Simple query using the new scope and index
    members = @trainer.users.inactive_since(30)
                          .includes(:user_stat)
                          .order(:last_activity_at)

    if params[:search].present?
      search_term = "%#{params[:search].downcase}%"
      members = members.where(
        "LOWER(first_name) LIKE ? OR LOWER(last_name) LIKE ? OR LOWER(email) LIKE ?",
        search_term, search_term, search_term
      )
    end

    page = params[:page] || 1
    per_page = [ params[:per_page]&.to_i || 20, 100 ].min

    paginated_members = members.page(page).per(per_page)

    members_data = paginated_members.map do |member|
      MemberSummarySerializer.new(member).as_json
    end

    render json: {
      members: members_data,
      pagination: {
        current_page: paginated_members.current_page,
        total_pages: paginated_members.total_pages,
        total_count: paginated_members.total_count,
        per_page: paginated_members.limit_value
      },
      filters_applied: {
        search: params[:search]
      }
    }
  end

  def assign_member
    authorize_trainer_access!(@trainer.id)
    return if performed?

    begin
      member = User.find(params[:user_id])
    rescue ActiveRecord::RecordNotFound
      return render json: { error: "Usuario no encontrado" }, status: :not_found
    end

    unless member.user?
      return render json: { error: "Error al asignar socio", details: [ "El usuario no es un socio válido" ] },
                    status: :unprocessable_entity
    end

    existing_assignment = CoachUser.find_by(coach: @trainer, user: member)
    if existing_assignment
      return render json: {
        error: "Este usuario ya está asignado a este entrenador",
        member: basic_member_info(member)
      }, status: :unprocessable_entity
    end

    begin
      coach_user = CoachUser.create!(coach: @trainer, user: member)

      render json: {
        message: "Socio asignado exitosamente",
        assignment: {
          id: coach_user.id,
          trainer_id: @trainer.id,
          trainer_name: "#{@trainer.first_name} #{@trainer.last_name}",
          member: basic_member_info(member),
          assigned_at: coach_user.created_at
        }
      }, status: :created

    rescue ActiveRecord::RecordInvalid => e
      render json: {
        error: "Error al asignar socio",
        details: e.record.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def unassign_member
    authorize_trainer_access!(@trainer.id)
    return if performed?

    begin
      member = User.user.find(params[:user_id])
    rescue ActiveRecord::RecordNotFound
      return render json: { error: "Usuario no encontrado" }, status: :not_found
    end

    assignment = CoachUser.find_by(coach: @trainer, user: member)
    unless assignment
      return render json: {
        error: "Este usuario no está asignado a este entrenador",
        member: basic_member_info(member)
      }, status: :not_found
    end

    assignment.destroy!

    render json: {
      message: "Socio desasignado exitosamente",
      unassigned: {
        trainer_id: @trainer.id,
        trainer_name: "#{@trainer.first_name} #{@trainer.last_name}",
        member: basic_member_info(member),
        unassigned_at: Time.current
      }
    }, status: :ok
  end

  def available_users
    authorize_trainer_access!(@trainer.id)
    return if performed?

    assigned_user_ids = @trainer.users.pluck(:id)
    available_users = User.where(role: "user")
                          .where.not(id: assigned_user_ids)

    if params[:search].present?
      search_term = "%#{params[:search].downcase}%"
      available_users = available_users.where(
        "LOWER(first_name) LIKE ? OR LOWER(last_name) LIKE ? OR LOWER(email) LIKE ?",
        search_term, search_term, search_term
      )
    end

    available_users = available_users.order(created_at: :desc)

    page = params[:page] || 1
    per_page = [ params[:per_page]&.to_i || 20, 100 ].min

    paginated_users = available_users.page(page).per(per_page)

    users_data = paginated_users.map do |user|
      {
        id: user.id,
        first_name: user.first_name,
        last_name: user.last_name,
        email: user.email,
        created_at: user.created_at
      }
    end

    render json: {
      available_users: users_data,
      pagination: {
        current_page: paginated_users.current_page,
        total_pages: paginated_users.total_pages,
        total_count: paginated_users.total_count,
        per_page: paginated_users.limit_value
      }
    }
  end

  def dashboard
    authorize_trainer_access!(@trainer.id)
    return if performed?

    # Obtener la última actualización de workouts
    last_workout_update = Workout.joins(:user)
                                .where(users: { id: @trainer.users.select(:id) })
                                .maximum(:updated_at) || Time.current

    # Obtener la última actualización de asignaciones de miembros
    last_member_assignment = CoachUser.where(coach_id: @trainer.id)
                                      .maximum(:updated_at) || Time.current

    # Usar el más reciente de los dos para la clave de caché
    last_update = [ last_workout_update, last_member_assignment ].max
    Rails.logger.info "[TRAINER_DASHBOARD] Last updates - workout: #{last_workout_update}, member: #{last_member_assignment}"

    cache_key = "trainer_dashboard_#{@trainer.id}_#{last_update.to_i}"

    dashboard_data = Rails.cache.fetch(cache_key, expires_in: 30.minutes) do
      Rails.logger.info "[TRAINER_DASHBOARD] Cache miss for trainer_id: #{@trainer.id}, generating dashboard data"

      members = @trainer.users.preload(:user_stat, :workouts)

      {
        overview: calculate_overview_stats(members),
        activity_metrics: calculate_activity_metrics(members),
        performance_trends: calculate_performance_trends(members),
        member_distribution: calculate_member_distribution(members),
        recent_activity: get_recent_activity(members),
        top_performers: get_top_performers(members),
        generated_at: Time.current
      }
    end

    Rails.logger.info "[TRAINER_DASHBOARD] Serving dashboard for trainer_id: #{@trainer.id} (#{@trainer.users.count} members)"

    render json: {
      trainer: {
        id: @trainer.id,
        name: "#{@trainer.first_name} #{@trainer.last_name}",
        email: @trainer.email
      },
      dashboard: dashboard_data,
      cache_info: {
        cached: true,
        generated_at: dashboard_data[:generated_at]
      },
      generated_at: dashboard_data[:generated_at]
    }
  end

  def list_routines
    authorize_trainer_access!(@trainer.id)
    return if performed?

    @routines = @trainer.routines

    @routines = @routines.where(difficulty: params[:difficulty]) if params[:difficulty].present?

    @routines = @routines.order(created_at: :desc)

    page = params[:page] || 1
    per_page = [ params[:per_page]&.to_i || 20, 100 ].min

    paginated_routines = @routines.page(page).per(per_page)

    render json: {
      routines: paginated_routines,
      pagination: {
        current_page: paginated_routines.current_page,
        total_pages: paginated_routines.total_pages,
        total_count: paginated_routines.total_count,
        per_page: paginated_routines.limit_value
      },
      filters_applied: {
        difficulty: params[:difficulty]
      }
    }
  end

  def assign_routine
    authorize_trainer_access!(@trainer.id)
    return if performed?

    member = @trainer.users.find(params[:user_id])
    routine = Routine.find(params[:routine_id])

    new_routine = routine.deep_clone(include: :routine_exercises)
    new_routine.user = member
    new_routine.name = params[:custom_name].presence || "#{routine.name} (Asignada por #{@trainer.first_name})"

    if new_routine.save
      render json: new_routine, status: :created
    else
      render json: { errors: new_routine.errors.full_messages }, status: :unprocessable_entity
    end
  end


  def assign_routine
    authorize_trainer_access!(@trainer.id)
    return if performed?

    member = User.find_by(id: params[:user_id])
    unless member && CoachUser.exists?(coach: @trainer, user: member)
      return render json: { error: "Usuario no encontrado o no asignado a este entrenador" }, status: :not_found
    end

    routine = @trainer.routines.find_by(id: params[:routine_id])
    unless routine
      return render json: { error: "Rutina no encontrada" }, status: :not_found
    end

    new_routine = routine.deep_clone(include: :routine_exercises)
    new_routine.user = member
    new_routine.name = params[:custom_name].presence || "#{routine.name} (Asignada por #{@trainer.first_name})"

    if new_routine.save
      render json: new_routine, status: :created
    else
      render json: { errors: new_routine.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update_member_routine
    authorize_trainer_access!(@trainer.id)
    return if performed?

    begin
      member = User.find(params[:user_id])
    rescue ActiveRecord::RecordNotFound
      return render json: { error: "Usuario no encontrado" }, status: :not_found
    end

    unless CoachUser.exists?(coach: @trainer, user: member)
      return render json: { error: "El usuario no está asignado a este entrenador" },
                    status: :forbidden
    end


    begin
      routine = Routine.find(params[:routine_id])
    rescue ActiveRecord::RecordNotFound
      return render json: { error: "No se encontró la rutina especificada" }, status: :not_found
    end

    unless routine.user_id == member.id
      return render json: { error: "La rutina no pertenece a este usuario" },
                    status: :forbidden
    end

    if routine.update(routine_params)
      render json: {
        routine: routine.as_json(include: :routine_exercises),
        message: "Rutina actualizada exitosamente"
      }
    else
      render json: { error: "Error al actualizar la rutina", details: routine.errors.full_messages },
                  status: :unprocessable_entity
    end
  end

  private

  def set_trainer
    @trainer = User.coach.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Entrenador no encontrado" }, status: :not_found
  end

  def ensure_trainer_role
    unless current_user.coach?
      render json: { error: "Acceso denegado. Solo entrenadores pueden acceder a esta funcionalidad." },
             status: :forbidden
    end
  end

  def authorize_trainer_access!(trainer_id)
    unless current_user.id == trainer_id.to_i
      render json: { error: "No tienes permisos para acceder a los datos de este entrenador." },
             status: :forbidden and return
    end
  end

  def basic_member_info(member)
    {
      id: member.id,
      name: "#{member.first_name} #{member.last_name}",
      email: member.email,
      role: member.role,
      created_at: member.created_at
    }
  end

  def calculate_overview_stats(members)
    total_members = members.count
    active_members = members.joins(:workouts)
                          .where(workouts: { created_at: 30.days.ago.. })
                          .distinct
                          .count

    total_workouts = Workout.joins(:user)
                           .where(user: members)
                           .count

    total_workouts_this_month = Workout.joins(:user)
                                      .where(user: members)
                                      .where(created_at: Date.current.beginning_of_month..)
                                      .count

    completed_workouts = Workout.joins(:user)
                               .where(user: members, status: "completed")
                               .count

    {
      total_members: total_members,
      active_members: active_members,
      inactive_members: total_members - active_members,
      activity_rate: total_members > 0 ? ((active_members.to_f / total_members) * 100).round(1) : 0,
      total_workouts: total_workouts,
      total_workouts_this_month: total_workouts_this_month,
      completed_workouts: completed_workouts,
      completion_rate: total_workouts > 0 ? ((completed_workouts.to_f / total_workouts) * 100).round(1) : 0
    }
  end

  def calculate_activity_metrics(members)
    weekly_activity = []
    8.times do |i|
      week_start = i.weeks.ago.beginning_of_week
      week_end = i.weeks.ago.end_of_week

      workouts_count = Workout.joins(:user)
                             .where(user: members)
                             .where(created_at: week_start..week_end)
                             .count

      weekly_activity << {
        week: week_start.strftime("%Y-W%U"),
        week_start: week_start,
        workouts_count: workouts_count
      }
    end

    avg_workouts_per_member = members.count > 0 ?
      (Workout.joins(:user).where(user: members).count.to_f / members.count).round(1) : 0

    {
      weekly_activity: weekly_activity.reverse,
      avg_workouts_per_member: avg_workouts_per_member,
      most_active_day: calculate_most_active_day(members),
      peak_hours: calculate_peak_hours(members)
    }
  end

  def calculate_performance_trends(members)
    monthly_ratings = []
    6.times do |i|
      month_start = i.months.ago.beginning_of_month
      month_end = i.months.ago.end_of_month

      avg_rating = Workout.joins(:user)
                         .where(user: members)
                         .where(created_at: month_start..month_end)
                         .where.not(workout_rating: nil)
                         .average(:workout_rating)

      monthly_ratings << {
        month: month_start.strftime("%Y-%m"),
        month_name: month_start.strftime("%B %Y"),
        avg_rating: avg_rating ? avg_rating.round(1) : nil
      }
    end

    pr_trend = []
    6.times do |i|
      month_start = i.months.ago.beginning_of_month
      month_end = i.months.ago.end_of_month

      pr_count = 0  # Personal record functionality removed during optimization

      pr_trend << {
        month: month_start.strftime("%Y-%m"),
        month_name: month_start.strftime("%B %Y"),
        personal_records: pr_count
      }
    end

    {
      monthly_ratings: monthly_ratings.reverse,
      personal_records_trend: pr_trend.reverse,
      avg_session_duration: calculate_avg_session_duration(members),
      progress_indicators: calculate_progress_indicators(members)
    }
  end

  def calculate_member_distribution(members)
    experience_distribution = members.joins(:user_stat)
                                   .group("user_stats.experience_level")
                                   .count
    goal_distribution = members.joins(:user_stat)
                              .group("user_stats.fitness_goal")
                              .count

    activity_distribution = members.joins(:user_stat)
                                  .group("user_stats.activity_level")
                                  .count
    age_ranges = {
      "18-25" => 0, "26-35" => 0, "36-45" => 0, "46-55" => 0, "55+" => 0
    }

    members.joins(:user_stat).where.not(user_stats: { age: nil }).find_each do |member|
      age = member.user_stat.age
      case age
      when 18..25 then age_ranges["18-25"] += 1
      when 26..35 then age_ranges["26-35"] += 1
      when 36..45 then age_ranges["36-45"] += 1
      when 46..55 then age_ranges["46-55"] += 1
      else age_ranges["55+"] += 1
      end
    end

    {
      experience_levels: experience_distribution,
      fitness_goals: goal_distribution,
      activity_levels: activity_distribution,
      age_ranges: age_ranges
    }
  end

  def get_recent_activity(members)
    recent_workouts = Workout.joins(:user)
                            .where(user: members)
                            .order("workouts.created_at DESC")
                            .limit(10)
                            .includes(:user)

    recent_workouts.map do |workout|
      {
        id: workout.id,
        member: {
          id: workout.user.id,
          name: "#{workout.user.first_name} #{workout.user.last_name}"
        },
        type: workout.workout_type || "workout",
        status: workout.status,
        duration: workout.total_duration_seconds,
        rating: workout.workout_rating,
        created_at: workout.created_at,
        completed_at: workout.completed_at
      }
    end
  end

  def get_top_performers(members)
    consistency_leaders = members.left_joins(:workouts)
                               .where(workouts: { created_at: 30.days.ago.. })
                               .group("users.id")
                               .order(Arel.sql("COUNT(workouts.id) DESC"))
                               .limit(5)
                               .includes(:user_stat)

    pr_leaders = User.none  # Personal record functionality removed during optimization

    {
      consistency_leaders: consistency_leaders.map { |member| top_performer_info(member) },
      pr_leaders: pr_leaders.map { |member| top_performer_info(member) }
    }
  end

  def calculate_most_active_day(members)
    day_counts = Workout.joins(:user)
                       .where(user: members)
                       .where("workouts.created_at >= ?", 30.days.ago)
                       .group("EXTRACT(DOW FROM workouts.created_at)")
                       .count

    return nil if day_counts.empty?

    day_names = %w[Domingo Lunes Martes Miércoles Jueves Viernes Sábado]
    most_active_dow = day_counts.max_by { |_, count| count }.first

    {
      day: day_names[most_active_dow.to_i],
      workout_count: day_counts[most_active_dow]
    }
  end

  def calculate_peak_hours(members)
    hour_counts = Workout.joins(:user)
                        .where(user: members)
                        .where("workouts.created_at >= ?", 30.days.ago)
                        .group("EXTRACT(HOUR FROM workouts.created_at)")
                        .count

    return [] if hour_counts.empty?

    hour_counts.map do |hour, count|
      {
        hour: "#{hour.to_i}:00",
        workout_count: count
      }
    end.sort_by { |h| h[:workout_count] }.reverse.first(3)
  end

  def calculate_avg_session_duration(members)
    avg_duration = Workout.joins(:user)
                         .where(user: members, status: "completed")
                         .where.not(total_duration_seconds: nil)
                         .average(:total_duration_seconds)

    avg_duration ? avg_duration.to_i : nil
  end

  def calculate_progress_indicators(members)
    total_volume = Workout.joins(:user)
                         .where(user: members, status: "completed")
                         .sum(:total_volume)

    avg_workout_rating = Workout.joins(:user)
                               .where(user: members)
                               .where.not(workout_rating: nil)
                               .average(:workout_rating)

    total_personal_records = 0  # Personal record functionality removed during optimization

    {
      total_volume_lifted: total_volume || 0,
      avg_workout_satisfaction: avg_workout_rating ? avg_workout_rating.round(1) : nil,
      total_personal_records: total_personal_records,
      member_retention_rate: calculate_retention_rate(members)
    }
  end

  def calculate_retention_rate(members)
    return 0 if members.empty?

    active_last_month = members.joins(:workouts)
                              .where(workouts: { created_at: 30.days.ago.. })
                              .distinct
                              .count

    ((active_last_month.to_f / members.count) * 100).round(1)
  end

  def top_performer_info(member)
    workouts_30_days = member.workouts.where(created_at: 30.days.ago..).count
    recent_prs = 0  # Personal record functionality removed during optimization

    {
      id: member.id,
      name: "#{member.first_name} #{member.last_name}",
      email: member.email,
      recent_workouts: workouts_30_days,
      recent_personal_records: recent_prs,
      consistency_score: calculate_member_consistency(member)
    }
  end

  def calculate_member_consistency(member)
    weeks_with_workouts = 0
    8.times do |i|
      week_start = i.weeks.ago.beginning_of_week
      week_end = i.weeks.ago.end_of_week

      if member.workouts.where(created_at: week_start..week_end).exists?
        weeks_with_workouts += 1
      end
    end

    ((weeks_with_workouts.to_f / 8) * 100).round(1)
  end

  def routine_params
    params.require(:routine).permit(
      :name,
      :description,
      :difficulty,
      routine_exercises_attributes: [
        :id,
        :name,
        :description,
        :sets,
        :reps,
        :duration_seconds,
        :rest_seconds,
        :weight,
        :position,
        :_destroy # Permite eliminar ejercicios existentes
      ]
    )
  end
end
