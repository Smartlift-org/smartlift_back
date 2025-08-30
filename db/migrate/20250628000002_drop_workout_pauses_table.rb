class DropWorkoutPausesTable < ActiveRecord::Migration[7.1]
  def up
    # Remove foreign key constraint first
    remove_foreign_key :workout_pauses, :workouts if foreign_key_exists?(:workout_pauses, :workouts)

    # Drop the table
    drop_table :workout_pauses if table_exists?(:workout_pauses)
  end

  def down
    # Recreate the workout_pauses table
    create_table :workout_pauses do |t|
      t.references :workout, null: false, foreign_key: true
      t.datetime :paused_at, null: false
      t.datetime :resumed_at
      t.string :reason, null: false
      t.integer :duration_seconds
      t.timestamps
    end

    # Add indexes
    add_index :workout_pauses, :paused_at
    add_index :workout_pauses, [ :workout_id, :paused_at ]
  end
end
