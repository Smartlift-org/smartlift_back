# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "🌱 Starting database seeding..."
puts "Environment: #{Rails.env}"

begin
  # Create default coach user
  coach = User.find_or_create_by!(email: "coach@smartlift.com") do |user|
    user.password = "password123"
    user.password_confirmation = "password123"
    user.first_name = "Demo"
    user.last_name = "Coach"
    user.role = "coach"
  end

  puts "✅ Created coach: #{coach.email} (ID: #{coach.id}, Role: #{coach.role})"

  # Create default basic user
  basic_user = User.find_or_create_by!(email: "user@smartlift.com") do |user|
    user.password = "password123"
    user.password_confirmation = "password123"
    user.first_name = "Demo"
    user.last_name = "User"
    user.role = "user"
  end

  puts "✅ Created basic user: #{basic_user.email} (ID: #{basic_user.id}, Role: #{basic_user.role})"

  # Create default admin user
  admin = User.find_or_create_by!(email: "admin@smartlift.com") do |user|
    user.password = "password123"
    user.password_confirmation = "password123"
    user.first_name = "Demo"
    user.last_name = "Admin"
    user.role = "admin"
  end

  puts "✅ Created admin: #{admin.email} (ID: #{admin.id}, Role: #{admin.role})"

  # Verify users were created
  total_users = User.count
  admin_count = User.admin.count
  coach_count = User.coach.count
  user_count = User.user.count

  puts "📊 Database stats:"
  puts "   Total users: #{total_users}"
  puts "   Admins: #{admin_count}"
  puts "   Coaches: #{coach_count}"
  puts "   Basic users: #{user_count}"

  puts "🎉 Database seeding completed successfully!"

rescue => e
  puts "❌ Error during seeding: #{e.message}"
  puts "❌ Backtrace: #{e.backtrace.first(5).join('\n')}"
  raise e
end
