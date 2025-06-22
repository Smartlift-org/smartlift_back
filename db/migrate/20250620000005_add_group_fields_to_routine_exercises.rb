class AddGroupFieldsToRoutineExercises < ActiveRecord::Migration[7.1]
  def change
    add_column :routine_exercises, :group_type, :string, default: 'regular'
    add_column :routine_exercises, :group_order, :integer
    add_column :routine_exercises, :weight, :decimal, precision: 8, scale: 2

    add_index :routine_exercises, [:routine_id, :group_type, :group_order]
  end
end 