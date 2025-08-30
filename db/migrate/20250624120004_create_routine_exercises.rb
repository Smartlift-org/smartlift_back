class CreateRoutineExercises < ActiveRecord::Migration[7.1]
  def change
    create_table :routine_exercises do |t|
      t.references :routine, null: false, foreign_key: true
      t.references :exercise, null: false, foreign_key: true
      t.integer :sets, null: false
      t.integer :reps, null: false
      t.integer :rest_time, default: 0, null: false
      t.integer :order, null: false
      t.string :group_type, default: "regular"
      t.integer :group_order
      t.decimal :weight, precision: 8, scale: 2

      t.timestamps
    end

    add_index :routine_exercises, [ :routine_id, :exercise_id, :order ],
              unique: true,
              name: 'index_routine_exercises_on_routine_id_and_exercise_id_and_order'
    add_index :routine_exercises, [ :routine_id, :group_type, :group_order ],
              name: 'idx_on_routine_id_group_type_group_order_6af3f864b1'
  end
end
