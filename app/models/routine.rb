class Routine < ApplicationRecord
  belongs_to :user
  has_many :routine_exercises, dependent: :destroy
  has_many :exercises, through: :routine_exercises

  accepts_nested_attributes_for :routine_exercises, allow_destroy: true

  validates :name, presence: true, uniqueness: { scope: :user_id, case_sensitive: false }
  validates :description, presence: true, length: { minimum: 10, maximum: 1000 }
  validates :level, presence: true, inclusion: { in: %w[beginner intermediate expert] }
  validates :duration, presence: true, numericality: { 
    greater_than: 0,
    less_than_or_equal_to: 180,
    message: "must be between 1 and 180 minutes"
  }

  # Serialization
  def as_json(options = {})
    {
      id: id,
      name: name,
      description: description,
      level: level,
      duration: duration,
      formatted_created_at: formatted_created_at,
      formatted_updated_at: formatted_updated_at,
      routine_exercises: routine_exercises.includes(:exercise).order(:order).map do |re|
        {
          id: re.id,
          routine_id: re.routine_id,
          exercise_id: re.exercise_id,
          sets: re.sets,
          reps: re.reps,
          rest_time: re.rest_time,
          order: re.order,
          formatted_created_at: re.created_at.strftime("%Y-%m-%d %H:%M:%S"),
          formatted_updated_at: re.updated_at.strftime("%Y-%m-%d %H:%M:%S"),
          exercise: {
            id: re.exercise.id,
            name: re.exercise.name,
            equipment: re.exercise.equipment,
            category: re.exercise.category,
            level: re.exercise.level,
            primary_muscles: re.exercise.primary_muscles,
            secondary_muscles: re.exercise.secondary_muscles,
            image_urls: re.exercise.image_urls,
            level_value: re.exercise.level_value,
            has_equipment: re.exercise.has_equipment?
          }
        }
      end
    }
  end

  def formatted_created_at
    created_at.strftime("%Y-%m-%d %H:%M:%S")
  end

  def formatted_updated_at
    updated_at.strftime("%Y-%m-%d %H:%M:%S")
  end

  # Scopes for common searches
  scope :by_level, ->(level) { where(level: level) }
  scope :by_duration, ->(duration) { where("duration <= ?", duration) }
  scope :by_muscle_group, ->(muscle) {
    joins(:exercises)
    .where("? = ANY(exercises.primary_muscles) OR ? = ANY(exercises.secondary_muscles)", muscle, muscle)
    .distinct
  }

  # Method for text search
  def self.search(query)
    where("name ILIKE ? OR description ILIKE ?", "%#{query}%", "%#{query}%")
  end
end 