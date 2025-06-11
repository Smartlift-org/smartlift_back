class Exercise < ApplicationRecord
    # Validaciones
    validates :name, presence: true, uniqueness: true
    validates :difficulty, inclusion: { in: %w[beginner intermediate advanced] }
    validates :force, inclusion: { in: %w[pull push static] }, allow_nil: true
    validates :mechanic, inclusion: { in: %w[compound isolation] }, allow_nil: true
    validates :category, presence: true
    validates :id, numericality: { 
        only_integer: true,
        greater_than_or_equal_to: 98,
        less_than_or_equal_to: 970,
        message: "must be between 98 and 970"
    }

    # Scopes para búsquedas comunes
    scope :by_category, ->(category) { where(category: category) }
    scope :by_difficulty, ->(difficulty) { where(difficulty: difficulty) }
    scope :by_equipment, ->(equipment) { where(equipment: equipment) }
    scope :by_force, ->(force) { where(force: force) }
    scope :by_mechanic, ->(mechanic) { where(mechanic: mechanic) }
    scope :by_primary_muscle, ->(muscle) { where("? = ANY(primary_muscles)", muscle) }
    scope :by_secondary_muscle, ->(muscle) { where("? = ANY(secondary_muscles)", muscle) }

    # Método para búsqueda por texto
    def self.search(query)
        where("name ILIKE ? OR instructions ILIKE ?", "%#{query}%", "%#{query}%")
    end

    # Serialización JSON personalizada
    def as_json(options = {})
        super(options).merge(
            image_urls: image_urls,
            difficulty_level: difficulty_level,
            has_equipment: has_equipment?
        )
    end

    def difficulty_level
        case difficulty
        when "beginner" then 1
        when "intermediate" then 2
        when "advanced" then 3
        end
    end

    def has_equipment?
        equipment != "body only"
    end

    def image_urls
        images.map do |image|
            "https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/dist/images/#{image}"
        end
    end
end
