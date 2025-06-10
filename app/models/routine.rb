class Routine < ApplicationRecord
  belongs_to :user
  has_many :routine_exercises, dependent: :destroy
  has_many :exercises, through: :routine_exercises

  validates :name, presence: true
  validates :description, presence: true
  validates :difficulty, inclusion: { in: %w[beginner intermediate advanced] }
  validates :duration, numericality: { greater_than: 0 }

  # Serialization
  def as_json(options = {})
    super(options).merge(
      exercises: exercises.as_json(methods: [:image_urls, :difficulty_level, :has_equipment?])
    )
  end
end 