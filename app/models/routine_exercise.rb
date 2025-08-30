class RoutineExercise < ApplicationRecord
  belongs_to :routine
  belongs_to :exercise
  has_many :workout_exercises, dependent: :destroy

  EXERCISE_GROUPS = {
    "regular" => "Single exercise",
    "superset" => "Two exercises performed back-to-back",
    "circuit" => "Multiple exercises in sequence"
  }.freeze

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
  validates :group_type, inclusion: { in: EXERCISE_GROUPS.keys }
  validates :group_order, numericality: { only_integer: true, greater_than: 0 }, if: -> { group_type != "regular" }
  validates :weight, numericality: { greater_than: 0 }, allow_nil: true

  before_validation :set_default_group_type, on: :create
  before_validation :set_default_group_order, on: :create

  scope :ordered, -> { order(:order) }
  scope :by_group, -> { order(:group_type, :group_order, :order) }
  scope :supersets, -> { where(group_type: "superset") }
  scope :circuits, -> { where(group_type: "circuit") }

  def as_json(options = {})
    super(options.merge(
      except: [ :created_at, :updated_at ],
      methods: [ :formatted_created_at, :formatted_updated_at ]
    )).merge(
      exercise: {
        id: exercise.id,
        name: exercise.name,
        primary_muscles: exercise.primary_muscles,
        images: exercise.images,
        difficulty_level: exercise.difficulty_level
      }
    )
  end

  def formatted_created_at
    created_at.strftime("%Y-%m-%d %H:%M:%S")
  end

  def formatted_updated_at
    updated_at.strftime("%Y-%m-%d %H:%M:%S")
  end

  def regular?
    group_type == "regular"
  end

  def superset?
    group_type == "superset"
  end

  def circuit?
    group_type == "circuit"
  end

  private

  def set_default_group_type
    self.group_type ||= "regular"
  end

  def set_default_group_order
    return if group_type == "regular" || group_order.present?

    last_group_order = routine.routine_exercises
      .where(group_type: group_type)
      .maximum(:group_order) || 0
    self.group_order = last_group_order + 1
  end
end
