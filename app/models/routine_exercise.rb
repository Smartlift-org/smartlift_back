class RoutineExercise < ApplicationRecord
  belongs_to :routine
  belongs_to :exercise

  validates :sets, presence: true, 
    numericality: { 
      greater_than: 0,
      less_than_or_equal_to: 20,
      message: "must be between 1 and 20"
    }
  validates :reps, presence: true, 
    numericality: { 
      greater_than: 0,
      less_than_or_equal_to: 100,
      message: "must be between 1 and 100"
    }
  validates :rest_time, presence: true, 
    numericality: { 
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: 600,
      message: "must be between 0 and 600 seconds"
    }
  validates :order, presence: true, 
    numericality: { 
      greater_than: 0,
      message: "must be greater than 0"
    }
  validates :order, uniqueness: { 
    scope: :routine_id,
    message: "must be unique within the routine. Please use the next available order number."
  }

  def as_json(options = {})
    super(options.merge(
      except: [:created_at, :updated_at],
      methods: [:formatted_created_at, :formatted_updated_at]
    )).merge(
      exercise: {
        id: exercise.id,
        name: exercise.name,
        equipment: exercise.equipment,
        category: exercise.category,
        difficulty: exercise.difficulty,
        primary_muscles: exercise.primary_muscles,
        secondary_muscles: exercise.secondary_muscles,
        image_urls: exercise.image_urls,
        difficulty_level: exercise.difficulty_level,
        has_equipment: exercise.has_equipment?
      }
    )
  end

  def formatted_created_at
    created_at.strftime("%Y-%m-%d %H:%M:%S")
  end

  def formatted_updated_at
    updated_at.strftime("%Y-%m-%d %H:%M:%S")
  end

end 