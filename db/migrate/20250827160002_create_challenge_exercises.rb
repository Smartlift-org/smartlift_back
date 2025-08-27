class CreateChallengeExercises < ActiveRecord::Migration[7.1]
  def change
    create_table :challenge_exercises do |t|
      t.references :challenge, null: false, foreign_key: true
      t.references :exercise, null: false, foreign_key: true
      t.integer :sets, null: false
      t.integer :reps, null: false
      t.integer :rest_time_seconds, default: 60
      t.integer :order_index, null: false
      t.text :notes

      t.timestamps
    end

    add_index :challenge_exercises, [:challenge_id, :order_index]
    add_index :challenge_exercises, [:challenge_id, :exercise_id]
  end
end
