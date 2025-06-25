class MakeRoutineOptionalInWorkouts < ActiveRecord::Migration[7.1]
  def change
    change_column_null :workouts, :routine_id, true
  end
end 