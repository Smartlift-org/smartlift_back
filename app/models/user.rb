class User < ApplicationRecord
    has_secure_password
    validates :email, presence: true, 
              uniqueness: { message: "ya está en uso" },
              format: { with: /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i, 
                       message: "debe tener un formato válido" }
    validates :first_name, presence: true
    validates :last_name, presence: true

end