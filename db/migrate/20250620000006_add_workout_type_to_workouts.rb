class AddWorkoutTypeToWorkouts < ActiveRecord::Migration[7.1]
  def change
    add_column :workouts, :workout_type, :integer, default: 0, null: false
    add_column :workouts, :name, :string
    
    add_index :workouts, :workout_type
    add_index :workouts, [:user_id, :workout_type]
    
    # Make routine_id nullable for free-style workouts
    change_column_null :workouts, :routine_id, true
  end
end 