class UserStatsController < ApplicationController
  before_action :set_user_stat, only: [:update]

  def index
    @user_stats = UserStat.all
    render json: @user_stats
  end

  def create
    @user_stat = UserStat.new(user_stat_params)
    if @user_stat.save
      render json: @user_stat, status: :created
    else
      render json: @user_stat.errors, status: :unprocessable_entity
    end
  end

  def update
    if @user_stat.update(user_stat_params)
      render json: @user_stat
    else
      render json: @user_stat.errors, status: :unprocessable_entity
    end
  end

  private

  def set_user_stat
    @user_stat = UserStat.find(params[:id])
  end

  def user_stat_params
    params.require(:user_stat).permit(:user_id, :height, :weight, :age, :gender, :fitness_goal, :experience_level, :available_days, :equipment_available, :activity_level, :physical_limitations)
  end
end 