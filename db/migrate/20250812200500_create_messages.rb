class CreateMessages < ActiveRecord::Migration[7.1]
  def change
    create_table :messages do |t|
      t.references :conversation, null: false, foreign_key: true
      t.references :sender, null: false, foreign_key: { to_table: :users }
      t.text :content, null: false
      t.string :message_type, default: 'text'
      t.datetime :read_at
      t.json :metadata

      t.timestamps
    end
    
    add_index :messages, [:conversation_id, :created_at]
    add_index :messages, [:sender_id, :created_at]
  end
end
