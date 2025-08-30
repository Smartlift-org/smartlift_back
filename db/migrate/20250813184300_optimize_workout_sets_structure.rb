class OptimizeWorkoutSetsStructure < ActiveRecord::Migration[7.1]
  def up
    # Remove unnecessary columns that are always null or unused
    remove_column :workout_sets, :rpe, :decimal
    remove_column :workout_sets, :rest_time_seconds, :integer
    remove_column :workout_sets, :notes, :text
    remove_column :workout_sets, :drop_set_weight, :decimal
    remove_column :workout_sets, :drop_set_reps, :integer
    remove_column :workout_sets, :is_personal_record, :boolean
    remove_column :workout_sets, :pr_type, :string
    remove_column :workout_sets, :started_at, :datetime

    # Remove indexes that are no longer needed
    remove_index :workout_sets, :is_personal_record if index_exists?(:workout_sets, :is_personal_record)
    remove_index :workout_sets, [:is_personal_record, :pr_type] if index_exists?(:workout_sets, [:is_personal_record, :pr_type])

    # Update set_type enum to remove drop_set option
    # Note: This will fail if there are existing drop_set records
    # In production, you might want to migrate existing drop_set records to 'normal' first
    change_column_default :workout_sets, :set_type, 'normal'
  end

  def down
    # Add back the removed columns
    add_column :workout_sets, :rpe, :decimal, precision: 3, scale: 1
    add_column :workout_sets, :rest_time_seconds, :integer
    add_column :workout_sets, :notes, :text
    add_column :workout_sets, :drop_set_weight, :decimal, precision: 8, scale: 2
    add_column :workout_sets, :drop_set_reps, :integer
    add_column :workout_sets, :is_personal_record, :boolean, default: false
    add_column :workout_sets, :pr_type, :string
    add_column :workout_sets, :started_at, :datetime

    # Add back the indexes
    add_index :workout_sets, :is_personal_record
    add_index :workout_sets, [:is_personal_record, :pr_type], where: "is_personal_record = true"
  end
end
