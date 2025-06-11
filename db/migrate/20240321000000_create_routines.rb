class CreateRoutines < ActiveRecord::Migration[7.1]
  def change
    create_table :routines do |t|
      t.string :name, null: false
      t.text :description, null: false
      t.string :difficulty, null: false
      t.integer :duration, null: false
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :routines, [:user_id, :name], unique: true
  end
end 