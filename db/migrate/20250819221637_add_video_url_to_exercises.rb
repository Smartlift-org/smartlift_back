class AddVideoUrlToExercises < ActiveRecord::Migration[7.1]
  def change
    add_column :exercises, :video_url, :string
    add_index :exercises, :video_url
  end
end
