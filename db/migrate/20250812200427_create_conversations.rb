class CreateConversations < ActiveRecord::Migration[7.1]
  def change
    create_table :conversations do |t|
      t.references :user, null: false, foreign_key: true
      t.references :coach, null: false, foreign_key: { to_table: :users }
      t.string :status, default: 'active'
      t.datetime :last_message_at

      t.timestamps
    end
    
    add_index :conversations, [:user_id, :coach_id], unique: true
    add_index :conversations, :last_message_at
  end
end
