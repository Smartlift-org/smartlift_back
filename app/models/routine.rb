class Routine < ApplicationRecord
  belongs_to :user
  belongs_to :validated_by, class_name: "User", optional: true
  has_many :routine_exercises, dependent: :destroy
  has_many :exercises, through: :routine_exercises

  accepts_nested_attributes_for :routine_exercises, allow_destroy: true

  # Validations
  validates :name, presence: true, uniqueness: { scope: :user_id, case_sensitive: false }
  validates :description, presence: true, length: { minimum: 10, maximum: 1000 }
  validates :difficulty, presence: true, inclusion: { in: %w[beginner intermediate advanced] }
  validates :duration, presence: true, numericality: {
    greater_than: 0,
    less_than_or_equal_to: 180,
    message: "must be between 1 and 180 minutes"
  }
  validates :source_type, presence: true, inclusion: { in: %w[manual ai_generated] }
  validates :validation_status, presence: true, inclusion: { in: %w[pending approved rejected] }
  validates :validated_by, presence: true, if: -> { validation_status.in?(%w[approved rejected]) }
  validates :validated_at, presence: true, if: -> { validation_status.in?(%w[approved rejected]) }
  validate :validator_must_be_trainer, if: -> { validated_by.present? }

  # Scopes
  scope :ai_generated, -> { where(ai_generated: true) }
  scope :manual, -> { where(ai_generated: false) }
  scope :pending_validation, -> { where(validation_status: "pending") }
  scope :approved, -> { where(validation_status: "approved") }
  scope :rejected, -> { where(validation_status: "rejected") }
  scope :validated, -> { where(validation_status: %w[approved rejected]) }

  # Callbacks
  before_validation :set_ai_generated_flag
  before_validation :set_default_validation_status

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
      except: [ :user_id, :created_at, :updated_at ],
      methods: [ :formatted_created_at, :formatted_updated_at ]
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
            difficulty_level: re.exercise.difficulty_level
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

  # AI-specific methods
  def ai_generated?
    ai_generated == true
  end

  def pending_validation?
    validation_status == "pending"
  end

  def approved?
    validation_status == "approved"
  end

  def rejected?
    validation_status == "rejected"
  end

  def validate_routine!(trainer, notes = nil)
    update_columns(
      validation_status: "approved",
      validated_by_id: trainer.id,
      validated_at: Time.current,
      validation_notes: notes,
      updated_at: Time.current
    )
  end

  def reject_routine!(trainer, notes)
    update!(
      validation_status: "rejected",
      validated_by: trainer,
      validated_at: Time.current,
      validation_notes: notes
    )
  end

  private

  def set_ai_generated_flag
    self.ai_generated = (source_type == "ai_generated")
  end

  def set_default_validation_status
    if ai_generated? && validation_status.blank?
      self.validation_status = "pending"
    elsif !ai_generated? && validation_status.blank?
      self.validation_status = "approved"
    end
  end

  def validator_must_be_trainer
    unless validated_by&.role == "trainer"
      errors.add(:validated_by, "must be a trainer")
    end
  end
end
