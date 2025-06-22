class Exercise < ApplicationRecord
    # Validaciones actualizadas para el import de free-exercise-db
    validates :name, presence: true, uniqueness: true
    validates :level, inclusion: { in: %w[beginner intermediate expert] }, allow_nil: true
    validates :force, inclusion: { in: %w[pull push static] }, allow_nil: true
    validates :mechanic, inclusion: { in: %w[compound isolation] }, allow_nil: true
    validates :category, presence: true
    # Removemos la validación de id numérico ya que el JSON usa strings como identificadores

    # Scopes para búsquedas comunes
    scope :by_category, ->(category) { where(category: category) }
    scope :by_level, ->(level) { where(level: level) }
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
        case level
        when "beginner" then 1
        when "intermediate" then 2
        when "expert" then 3
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
