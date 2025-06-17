class CreateExercises < ActiveRecord::Migration[7.1]
  def change
    create_table :exercises do |t|
      t.string :name
      t.string :level
      t.string :force
      t.string :mechanic
      t.string :equipment
      t.string :category
      t.string :instructions, array: true, default: []
      t.string :primary_muscles, array: true, default: []
      t.string :secondary_muscles, array: true, default: []
      t.text :description
      t.string :images, array: true, default: []
      t.timestamps
    end
  end
end
