class Exercise < ApplicationRecord
    belongs_to :user, optional: true
    has_many :routine_exercises, dependent: :destroy
    has_many :routines, through: :routine_exercises

    # Validaciones
    validates :name, presence: true, uniqueness: true
    validates :level, inclusion: { in: %w[beginner intermediate expert] }, allow_nil: true
    validates :force, inclusion: { in: %w[pull push static] }, allow_nil: true
    validates :mechanic, inclusion: { in: %w[compound isolation] }, allow_nil: true
    validates :category, presence: true
    validates :instructions, presence: true, allow_blank: true
    
    # ID validation only for predefined exercises (those without user_id)
    # validates :id, numericality: { 
    #     only_integer: true,
    #     # greater_than_or_equal_to: 98,
    #     # less_than_or_equal_to: 970,
    #     # message: "must be between 98 and 970"
    # }, if: :predefined?

    # Scopes para búsquedas comunes
    scope :by_category, ->(category) { where(category: category) }
    scope :by_difficulty, ->(difficulty) { where(difficulty: difficulty) }
    scope :by_equipment, ->(equipment) { where(equipment: equipment) }
    scope :by_force, ->(force) { where(force: force) }
    scope :by_mechanic, ->(mechanic) { where(mechanic: mechanic) }
    scope :by_primary_muscle, ->(muscle) { where("? = ANY(primary_muscles)", muscle) }
    scope :by_secondary_muscle, ->(muscle) { where("? = ANY(secondary_muscles)", muscle) }
    scope :predefined, -> { where(user_id: nil) }
    scope :user_created, -> { where.not(user_id: nil) }

    # Método para búsqueda por texto
    def self.search(query)
        where("name ILIKE ? OR instructions ILIKE ?", "%#{query}%", "%#{query}%")
    end

    # Serialización JSON personalizada
    def as_json(options = {})
        super(options).merge(
            image_urls: image_urls,
            level_value: level_value,
            has_equipment: has_equipment?,
            is_predefined: predefined?
        )
    end


    def level_value
        case level
        when "beginner" then 1
        when "intermediate" then 2
        when "expert" then 3
    end

    def has_equipment?
        equipment != "body only"
    end

    def image_urls
        images.map do |image|
            "https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/dist/images/#{image}"
        end
    end

    def predefined?
        user_id.nil?
    end
end
