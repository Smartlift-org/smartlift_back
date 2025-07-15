class CreateExercises < ActiveRecord::Migration[7.1]
  def change
    create_table :exercises do |t|
      t.string :name
      t.text :instructions
      t.string :primary_muscles, default: [], array: true
      t.string :level
      t.string :images, default: [], array: true

      t.timestamps
    end

    add_index :exercises, :level
    add_index :exercises, :images, using: :gin
  end
end 