class Exercise < ApplicationRecord
    # Validaciones actualizadas para el import de free-exercise-db
    validates :name, presence: true, uniqueness: true
    validates :level, inclusion: { in: %w[beginner intermediate expert] }, allow_nil: true
    validates :video_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "must be a valid URL" }, allow_blank: true
    # Removemos la validación de id numérico ya que el JSON usa strings como identificadores

    # Scopes para búsquedas comunes
    scope :by_level, ->(level) { where(level: level) }
    scope :by_primary_muscle, ->(muscle) { where("? = ANY(primary_muscles)", muscle) }

    # Método para búsqueda por texto
    def self.search(query)
        where("name ILIKE ? OR instructions ILIKE ?", "%#{query}%", "%#{query}%")
    end

    # Serialización JSON personalizada
    def as_json(options = {})
        super(options).merge(
            difficulty_level: difficulty_level,
        )
    end

    def difficulty_level
        case level
        when "beginner" then 1
        when "intermediate" then 2
        when "expert" then 3
        end
    end
end
