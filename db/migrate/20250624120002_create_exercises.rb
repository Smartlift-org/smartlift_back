class CreateExercises < ActiveRecord::Migration[7.1]
  def change
    create_table :exercises do |t|
      t.string :name
      t.string :equipment
      t.string :category
      t.string :difficulty
      t.text :instructions
      t.string :primary_muscles, default: [], array: true
      t.string :secondary_muscles, default: [], array: true
      t.string :force
      t.string :mechanic
      t.string :level
      t.string :images, default: [], array: true

      t.timestamps
    end

    add_index :exercises, :force
    add_index :exercises, :level
    add_index :exercises, :mechanic
    add_index :exercises, :images, using: :gin
  end
end 