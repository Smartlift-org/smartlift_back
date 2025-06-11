class CreateCoachUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :coach_users do |t|
      t.references :coach, null: false, foreign_key: { to_table: :users }
      t.references :user, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :coach_users, [ :coach_id, :user_id ], unique: true
  end
end
