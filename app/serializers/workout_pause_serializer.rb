class WorkoutPauseSerializer < ActiveModel::Serializer
  attributes :id,
             :workout_id,
             :paused_at,
             :resumed_at,
             :reason,
             :duration_seconds,
             :created_at,
             :updated_at

  # Calculated attributes
  def duration
    object.duration
  end

  def active?
    object.active?
  end

  def completed?
    object.completed?
  end

  attributes :duration, :active?, :completed?
end 