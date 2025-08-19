class AddVideoUrlToExercises < ActiveRecord::Migration[7.1]
  def change
    unless column_exists?(:exercises, :video_url)
      add_column :exercises, :video_url, :string
    end
    
    unless index_exists?(:exercises, :video_url)
      add_index :exercises, :video_url
    end
  end
end
