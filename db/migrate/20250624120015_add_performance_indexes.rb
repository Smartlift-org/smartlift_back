class AddPerformanceIndexes < ActiveRecord::Migration[7.1]
  def change
    # Índices para WorkoutSet queries frecuentes
    add_index :workout_sets, [ :workout_exercise_id, :completed ], name: 'idx_workout_sets_exercise_completed'
    add_index :workout_sets, [ :is_personal_record, :pr_type ], name: 'idx_workout_sets_pr'
    add_index :workout_sets, [ :set_type, :completed ], name: 'idx_workout_sets_type_completed'

    # Índices para WorkoutExercise queries frecuentes
    add_index :workout_exercises, [ :workout_id, :group_type, :group_order ], name: 'idx_workout_exercises_group'
    add_index :workout_exercises, [ :workout_id, :order ], name: 'idx_workout_exercises_order'

    # Índices adicionales para Personal Records queries
    add_index :workout_sets, [ :created_at ], name: 'idx_workout_sets_created_at'
    add_index :workout_sets, [ :weight, :workout_exercise_id ], name: 'idx_workout_sets_weight_exercise', where: 'completed = true AND set_type = \'normal\''
  end
end
