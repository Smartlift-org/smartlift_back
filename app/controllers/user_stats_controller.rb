class UserStatsController < ApplicationController
  def index
    @user_stat = current_user.user_stat
    if @user_stat
      render json: @user_stat
    else
      render json: { error: "No user stats found" }, status: :not_found
    end
  end

  def create
    if current_user.user_stat.present?
      render json: { error: "User stats already exist" }, status: :unprocessable_entity
      return
    end

    @user_stat = current_user.build_user_stat(user_stat_params)
    if @user_stat.save
      render json: @user_stat, status: :created
    else
      render json: @user_stat.errors, status: :unprocessable_entity
    end
  end

  def update
    @user_stat = current_user.user_stat
    if @user_stat.nil?
      render json: { error: "No user stats found" }, status: :not_found
      return
    end

    if @user_stat.update(user_stat_params)
      render json: @user_stat
    else
      render json: @user_stat.errors, status: :unprocessable_entity
    end
  end

  private

  def user_stat_params
    params.require(:user_stat).permit(:height, :weight, :age, :gender, :fitness_goal, :experience_level, :available_days, :equipment_available, :activity_level, :physical_limitations)
  end
end 