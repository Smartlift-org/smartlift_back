class CreateWorkouts < ActiveRecord::Migration[7.1]
  def change
    create_table :workouts do |t|
      t.references :user, null: false, foreign_key: true
      t.references :routine, null: false, foreign_key: true
      t.string :status, null: false, default: 'in_progress'
      t.datetime :started_at, null: false
      t.datetime :completed_at
      t.integer :perceived_intensity
      t.integer :energy_level
      t.string :mood
      t.text :notes
      t.decimal :total_volume, precision: 10, scale: 2
      t.integer :total_sets_completed
      t.integer :total_exercises_completed
      t.decimal :average_rpe, precision: 3, scale: 1
      t.boolean :followed_routine
      t.integer :total_duration_seconds

      t.timestamps
    end

    add_index :workouts, [ :user_id, :status ]
    add_index :workouts, :started_at
    add_index :workouts, :completed_at
  end
end
