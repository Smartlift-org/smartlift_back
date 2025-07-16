class Routine < ApplicationRecord
  belongs_to :user
  has_many :routine_exercises, dependent: :destroy
  has_many :exercises, through: :routine_exercises

  accepts_nested_attributes_for :routine_exercises, allow_destroy: true

  validates :name, presence: true, uniqueness: { scope: :user_id, case_sensitive: false }
  validates :description, presence: true, length: { minimum: 10, maximum: 1000 }
  validates :difficulty, presence: true, inclusion: { in: %w[beginner intermediate advanced] }
  validates :duration, presence: true, numericality: { 
    greater_than: 0,
    less_than_or_equal_to: 180,
    message: "must be between 1 and 180 minutes"
  }

  # Crea una copia profunda de la rutina, incluyendo ejercicios si se especifica
  # @param include [Symbol, nil] Si es :routine_exercises, clona también los ejercicios asociados
  # @return [Routine] Una nueva instancia de Routine que es copia del original
  def deep_clone(include: nil)
    clone = self.dup
    
    if include == :routine_exercises
      self.routine_exercises.each do |exercise|
        clone_exercise = exercise.dup
        clone.routine_exercises << clone_exercise
      end
    end
    
    clone
  end

  # Serialization
  def as_json(options = {})
    super(options.merge(
      except: [:user_id, :created_at, :updated_at],
      methods: [:formatted_created_at, :formatted_updated_at]
    )).merge(
      user: {
        id: user.id,
        first_name: user.first_name,
        last_name: user.last_name
      },
      routine_exercises: routine_exercises.includes(:exercise).map do |re|
        {
          id: re.id,
          exercise_id: re.exercise_id,
          sets: re.sets,
          reps: re.reps,
          rest_time: re.rest_time,
          order: re.order,
          exercise: {
            id: re.exercise.id,
            name: re.exercise.name,
            primary_muscles: re.exercise.primary_muscles,
            images: re.exercise.images,
            difficulty_level: re.exercise.difficulty_level,
          }
        }
      end
    )
  end

  def formatted_created_at
    created_at.strftime("%Y-%m-%d %H:%M:%S")
  end

  def formatted_updated_at
    updated_at.strftime("%Y-%m-%d %H:%M:%S")
  end
end 