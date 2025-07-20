# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "🌱 Starting database seeding..."

# Create default coach user
coach = User.find_or_create_by!(email: "coach@smartlift.com") do |user|
  user.password = "password123"
  user.password_confirmation = "password123"
  user.first_name = "Demo"
  user.last_name = "Coach"
  user.role = "coach"
end

puts "✅ Created coach: #{coach.email}"

# Create default basic user
basic_user = User.find_or_create_by!(email: "user@smartlift.com") do |user|
  user.password = "password123"
  user.password_confirmation = "password123"
  user.first_name = "Demo"
  user.last_name = "User"
  user.role = "user"
end

puts "✅ Created basic user: #{basic_user.email}"

# Create default admin user
admin = User.find_or_create_by!(email: "admin@smartlift.com") do |user|
  user.password = "password123"
  user.password_confirmation = "password123"
  user.first_name = "Demo"
  user.last_name = "Admin"
  user.role = "admin"
end

puts "✅ Created admin: #{admin.email}"

puts "🎉 Database seeding completed!"
