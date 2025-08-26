class AddAiFieldsToRoutines < ActiveRecord::Migration[7.1]
  def change
    add_column :routines, :source_type, :string, default: 'manual', null: false
    add_column :routines, :ai_generated, :boolean, default: false, null: false
    add_column :routines, :validation_status, :string, default: 'pending', null: false
    add_column :routines, :validated_by_id, :integer, null: true
    add_column :routines, :validated_at, :datetime, null: true
    add_column :routines, :validation_notes, :text, null: true
    add_column :routines, :ai_prompt_data, :json, null: true

    # Add foreign key for validator (trainer)
    add_foreign_key :routines, :users, column: :validated_by_id

    # Add indexes for performance
    add_index :routines, :source_type, if_not_exists: true
    add_index :routines, :ai_generated, if_not_exists: true
    add_index :routines, :validation_status, if_not_exists: true
    add_index :routines, :validated_by_id, if_not_exists: true
  end
end
