class SimplifyPersonalRecords < ActiveRecord::Migration[7.1]
  def up
    # Remove stored PR fields - calculate on-demand instead
    remove_column :workout_sets, :is_personal_record if column_exists?(:workout_sets, :is_personal_record)
    remove_column :workout_sets, :pr_type if column_exists?(:workout_sets, :pr_type)

    # Remove PR-related indexes
    remove_index :workout_sets, [ :is_personal_record, :pr_type ] if index_exists?(:workout_sets, [ :is_personal_record, :pr_type ])
    remove_index :workout_sets, :is_personal_record if index_exists?(:workout_sets, :is_personal_record)
  end

  def down
    # Restore PR tracking fields
    add_column :workout_sets, :is_personal_record, :boolean, default: false
    add_column :workout_sets, :pr_type, :string

    # Restore indexes
    add_index :workout_sets, :is_personal_record
    add_index :workout_sets, [ :is_personal_record, :pr_type ]
  end
end
