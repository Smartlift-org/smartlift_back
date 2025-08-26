class AddPerformanceIndexes < ActiveRecord::Migration[7.1]
  def change
    # Índices para WorkoutSet queries frecuentes
    add_index :workout_sets, [ :workout_exercise_id, :completed ], name: 'idx_workout_sets_exercise_completed', if_not_exists: true
    add_index :workout_sets, [ :is_personal_record, :pr_type ], name: 'idx_workout_sets_pr', if_not_exists: true
    add_index :workout_sets, [ :set_type, :completed ], name: 'idx_workout_sets_type_completed', if_not_exists: true

    # Índices para WorkoutExercise queries frecuentes
    add_index :workout_exercises, [ :workout_id, :group_type, :group_order ], name: 'idx_workout_exercises_group', if_not_exists: true
    add_index :workout_exercises, [ :workout_id, :order ], name: 'idx_workout_exercises_order', if_not_exists: true

    # Índices adicionales para Personal Records queries
    add_index :workout_sets, [ :created_at ], name: 'idx_workout_sets_created_at', if_not_exists: true
    add_index :workout_sets, [ :weight, :workout_exercise_id ], name: 'idx_workout_sets_weight_exercise', where: 'completed = true AND set_type = \'normal\'', if_not_exists: true
  end
end
