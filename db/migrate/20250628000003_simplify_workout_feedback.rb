class SimplifyWorkoutFeedback < ActiveRecord::Migration[7.1]
  def up
    # Add the new simplified workout rating field
    add_column :workouts, :workout_rating, :integer
    
    # Migrate existing data: convert perceived_intensity to workout_rating
    # Use perceived_intensity as the primary indicator since it's most similar to overall rating
    execute <<-SQL
      UPDATE workouts 
      SET workout_rating = CASE 
        WHEN perceived_intensity IS NOT NULL THEN perceived_intensity
        WHEN energy_level IS NOT NULL THEN energy_level
        ELSE NULL
      END
      WHERE completed_at IS NOT NULL
    SQL
    
    # Remove the old complex fields
    remove_column :workouts, :perceived_intensity
    remove_column :workouts, :energy_level  
    remove_column :workouts, :mood
    
    # Add validation constraint
    add_check_constraint :workouts, 'workout_rating >= 1 AND workout_rating <= 10', name: 'workout_rating_range'
  end
  
  def down
    # Restore the old fields
    add_column :workouts, :perceived_intensity, :integer
    add_column :workouts, :energy_level, :integer
    add_column :workouts, :mood, :string
    
    # Migrate data back
    execute <<-SQL
      UPDATE workouts 
      SET 
        perceived_intensity = workout_rating,
        energy_level = workout_rating
      WHERE workout_rating IS NOT NULL
    SQL
    
    # Remove the simplified field
    remove_check_constraint :workouts, name: 'workout_rating_range'
    remove_column :workouts, :workout_rating
  end
end