class CreateRoutineExercises < ActiveRecord::Migration[7.1]
  def change
    create_table :routine_exercises do |t|
      t.references :routine, null: false, foreign_key: true
      t.references :exercise, null: false, foreign_key: true
      t.integer :sets, null: false
      t.integer :reps, null: false
      t.integer :rest_time, null: false, default: 0
      t.integer :order, null: false

      t.timestamps
    end

    add_index :routine_exercises, [:routine_id, :exercise_id, :order], unique: true
  end
end 