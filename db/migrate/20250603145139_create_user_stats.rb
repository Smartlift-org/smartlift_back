class CreateUserStats < ActiveRecord::Migration[8.0]
  def change
    create_table :user_stats do |t|
      t.references :user, null: false, foreign_key: true
      t.decimal :height, precision: 5, scale: 2
      t.decimal :weight, precision: 5, scale: 2
      t.integer :age
      t.string :gender, limit: 50
      t.string :fitness_goal, limit: 100
      t.string :experience_level, limit: 50
      t.integer :available_days
      t.string :equipment_available, limit: 100
      t.string :activity_level, limit: 50
      t.string :physical_limitations, limit: 100

      t.timestamps
    end
  end
end
