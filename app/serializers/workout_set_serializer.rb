class WorkoutSetSerializer < ActiveModel::Serializer
  attributes :id,
             :workout_exercise_id,
             :set_number,
             :set_type,
             :weight,
             :reps,
             :rpe,
             :rest_time_seconds,
             :completed,
             :started_at,
             :completed_at,
             :notes,
             :drop_set_weight,
             :drop_set_reps,
             :is_personal_record,
             :pr_type,
             :created_at,
             :updated_at

  # Calculated attributes
  def volume
    object.volume
  end

  def duration
    object.duration
  end

  attributes :volume, :duration
end 