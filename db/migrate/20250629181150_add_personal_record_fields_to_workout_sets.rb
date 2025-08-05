class AddPersonalRecordFieldsToWorkoutSets < ActiveRecord::Migration[7.1]
  def change
    add_column :workout_sets, :is_personal_record, :boolean, default: false
    add_column :workout_sets, :pr_type, :string

    add_index :workout_sets, :is_personal_record
    add_index :workout_sets, [ :is_personal_record, :pr_type ], where: "is_personal_record = true"
  end
end
