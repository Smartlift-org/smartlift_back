class DropWorkoutPauses < ActiveRecord::Migration[7.1]
  def up
    drop_table :workout_pauses
  end

  def down
    create_table :workout_pauses do |t|
      t.references :workout, null: false, foreign_key: true
      t.datetime :paused_at, null: false
      t.datetime :resumed_at
      t.string :reason, null: false
      t.integer :duration_seconds

      t.timestamps
    end

    add_index :workout_pauses, [:workout_id, :paused_at]
    add_index :workout_pauses, :paused_at
  end
end