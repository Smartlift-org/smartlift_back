class CreateChallenges < ActiveRecord::Migration[7.1]
  def change
    create_table :challenges do |t|
      t.references :coach, null: false, foreign_key: { to_table: :users }
      t.string :name, null: false
      t.text :description
      t.integer :difficulty_level, default: 1
      t.datetime :start_date, null: false
      t.datetime :end_date, null: false
      t.boolean :is_active, default: true
      t.integer :estimated_duration_minutes

      t.timestamps
    end

    add_index :challenges, [:coach_id, :is_active]
    add_index :challenges, [:start_date, :end_date]
    add_index :challenges, [:coach_id, :name]
  end
end
