class WorkoutSetSerializer < ActiveModel::Serializer
  attributes :id,
             :workout_exercise_id,
             :set_number,
             :set_type,
             :weight,
             :reps,
             :completed,
             :completed_at,
             :created_at,
             :updated_at

  # Calculated attributes
  def volume
    object.volume
  end

  attributes :volume
end
