class CreateChallengeAttempts < ActiveRecord::Migration[7.1]
  def change
    create_table :challenge_attempts do |t|
      t.references :challenge, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :completion_time_seconds
      t.datetime :started_at
      t.datetime :completed_at
      t.integer :status, default: 0
      t.boolean :is_best_attempt, default: false
      t.json :exercise_times

      t.timestamps
    end

    add_index :challenge_attempts, [:challenge_id, :user_id]
    add_index :challenge_attempts, [:challenge_id, :completion_time_seconds]
    add_index :challenge_attempts, [:user_id, :is_best_attempt]
    add_index :challenge_attempts, [:challenge_id, :is_best_attempt, :completion_time_seconds], name: 'index_challenge_attempts_for_leaderboard'
  end
end
