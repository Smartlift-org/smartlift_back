module WorkoutTrackable
  extend ActiveSupport::Concern

  included do
    validates :status, presence: true
    scope :active, -> { where(status: ['in_progress', 'paused']) }
    scope :completed, -> { where(status: 'completed') }
    scope :abandoned, -> { where(status: 'abandoned') }
  end

  def active?
    ['in_progress', 'paused'].include?(status)
  end

  def completed?
    status == 'completed'
  end

  def abandoned?
    status == 'abandoned'
  end

  def paused?
    status == 'paused'
  end

  def in_progress?
    status == 'in_progress'
  end
end 