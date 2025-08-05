class CreateWorkoutExercises < ActiveRecord::Migration[7.1]
  def change
    create_table :workout_exercises do |t|
      t.references :workout, null: false, foreign_key: true
      t.references :exercise, null: false, foreign_key: true
      t.references :routine_exercise, null: true, foreign_key: true
      t.integer :order, null: false
      t.string :group_type, null: false, default: 'regular'
      t.integer :group_order
      t.integer :target_sets
      t.integer :target_reps
      t.decimal :suggested_weight, precision: 8, scale: 2
      t.text :notes
      t.datetime :started_at
      t.datetime :completed_at
      t.boolean :completed_as_prescribed, default: false

      t.timestamps
    end

    add_index :workout_exercises, [ :workout_id, :order ], unique: true
    add_index :workout_exercises, [ :workout_id, :group_type, :group_order ]
    add_index :workout_exercises, [ :workout_id, :exercise_id ]
  end
end
