class User < ApplicationRecord
    has_secure_password

    enum :role, { user: 0, coach: 1 }

    # Relationships for coaches
    has_many :coach_users, foreign_key: :coach_id, dependent: :destroy
    has_many :users, through: :coach_users

    # Relationships for users
    has_many :user_coaches, class_name: "CoachUser", foreign_key: :user_id, dependent: :destroy
    has_many :coaches, through: :user_coaches

    has_one :user_stat, dependent: :destroy
    has_many :routines, dependent: :destroy

    validates :email, presence: true,
              uniqueness: { message: "ya está en uso" },
              format: { with: /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i,
                       message: "debe tener un formato válido" }
    validates :first_name, presence: true
    validates :last_name, presence: true
    validates :role, presence: true
    validate :role_must_be_valid

    before_validation :set_default_role, on: :create

    private
    def role_must_be_valid
      if role.present? && !User.roles.keys.include?(role)
        errors.add(:role, "Debe ser 'Usuario' o 'Entrenador'")
      end
    end

    def set_default_role
      self.role ||= :user
    end
end
