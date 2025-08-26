class CreateUserPrivacySettings < ActiveRecord::Migration[7.1]
  def change
    create_table :user_privacy_settings, if_not_exists: true do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.boolean :show_name, default: true, null: false
      t.boolean :show_profile_picture, default: true, null: false
      t.boolean :show_workout_count, default: true, null: false
      t.boolean :show_join_date, default: false, null: false
      t.boolean :show_personal_records, default: false, null: false
      t.boolean :show_favorite_exercises, default: false, null: false
      t.boolean :is_profile_public, default: false, null: false

      t.timestamps
    end

    add_index :user_privacy_settings, :is_profile_public
  end
end
