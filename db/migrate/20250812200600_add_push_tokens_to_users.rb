class AddPushTokensToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :expo_push_token, :string
    add_column :users, :push_notifications_enabled, :boolean, default: true
    
    add_index :users, :expo_push_token
  end
end
