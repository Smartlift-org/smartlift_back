class CreateWorkoutSets < ActiveRecord::Migration[7.1]
  def change
    create_table :workout_sets do |t|
      t.references :workout_exercise, null: false, foreign_key: true
      t.integer :set_number, null: false
      t.string :set_type, null: false, default: 'normal'
      t.decimal :weight, precision: 8, scale: 2
      t.integer :reps
      t.decimal :rpe, precision: 3, scale: 1
      t.integer :rest_time_seconds
      t.boolean :completed, default: false
      t.datetime :started_at
      t.datetime :completed_at
      t.text :notes
      t.decimal :drop_set_weight, precision: 8, scale: 2
      t.integer :drop_set_reps
      t.boolean :is_personal_record, default: false
      t.string :pr_type

      t.timestamps
    end

    add_index :workout_sets, [ :workout_exercise_id, :set_number ], unique: true
    add_index :workout_sets, :completed
    add_index :workout_sets, :is_personal_record
  end
end
