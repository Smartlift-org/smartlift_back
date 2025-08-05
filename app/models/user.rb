class User < ApplicationRecord
    has_secure_password

    # Active Storage for profile picture
    has_one_attached :profile_picture

    enum :role, { user: 0, coach: 1, admin: 2 }

    # Relationships for coaches
    has_many :coach_users, foreign_key: :coach_id, dependent: :destroy
    has_many :users, through: :coach_users

    # Relationships for users
    has_many :user_coaches, class_name: "CoachUser", foreign_key: :user_id, dependent: :destroy
    has_many :coaches, through: :user_coaches

    has_one :user_stat, dependent: :destroy
    has_many :routines, dependent: :destroy
    has_many :workouts, dependent: :destroy

    # Activity tracking scopes
    scope :inactive_since, ->(days) {
      where("last_activity_at < ? OR last_activity_at IS NULL", days.days.ago)
    }

    validates :email, presence: true,
              uniqueness: { message: "ya está en uso" },
              format: { with: /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i,
                       message: "debe tener un formato válido" }
    validates :first_name, presence: true
    validates :last_name, presence: true
    validates :role, presence: true
    validates :profile_picture_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "debe ser una URL válida" }, allow_blank: true
    validate :role_must_be_valid

    before_validation :set_default_role, on: :create

    # Method to get profile picture URL
    def profile_picture_url_with_fallback
      if profile_picture.attached?
        Rails.application.routes.url_helpers.rails_blob_url(profile_picture, host: Rails.application.config.action_mailer.default_url_options[:host])
      else
        profile_picture_url # Fallback to the old URL field
      end
    end

    private
    def role_must_be_valid
      if role.present? && !User.roles.keys.include?(role)
        errors.add(:role, "Debe ser 'Usuario', 'Entrenador' o 'Administrador'")
      end
    end

    def set_default_role
      self.role ||= :user
    end
end
