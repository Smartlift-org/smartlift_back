class AddGroupFieldsToRoutineExercises < ActiveRecord::Migration[7.1]
  def change
    # These fields were already added in CreateRoutineExercises migration
    # This migration is kept for historical purposes but does nothing
    # Fields: group_type, group_order, weight and index already exist
  end
end 