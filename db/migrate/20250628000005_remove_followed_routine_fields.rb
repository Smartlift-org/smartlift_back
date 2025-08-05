class RemoveFollowedRoutineFields < ActiveRecord::Migration[7.1]
  def up
    # Remove followed_routine tracking from workouts
    remove_column :workouts, :followed_routine if column_exists?(:workouts, :followed_routine)

    # Remove completed_as_prescribed tracking from workout_exercises
    remove_column :workout_exercises, :completed_as_prescribed if column_exists?(:workout_exercises, :completed_as_prescribed)
  end

  def down
    # Restore the fields
    add_column :workouts, :followed_routine, :boolean
    add_column :workout_exercises, :completed_as_prescribed, :boolean, default: false
  end
end
