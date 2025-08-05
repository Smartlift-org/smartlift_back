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

  # Create test users with specific activity dates for testing inactive members
  puts "🔄 Setting up test users with specific activity dates..."
  
  test_users_data = [
    {
      email: "active@smartlift.com",
      first_name: "Active",
      last_name: "Member", 
      activity_date: 1.week.ago,
      status: "ACTIVE"
    },
    {
      email: "inactive@smartlift.com", 
      first_name: "Inactive",
      last_name: "Member",
      activity_date: 35.days.ago,
      status: "INACTIVE"
    },
    {
      email: "very.inactive@smartlift.com",
      first_name: "Very",
      last_name: "Inactive", 
      activity_date: 60.days.ago,
      status: "VERY INACTIVE"
    },
    {
      email: "new@smartlift.com",
      first_name: "New", 
      last_name: "Member",
      activity_date: nil,
      status: "NO ACTIVITY"
    }
  ]

  test_users = []
  test_users_data.each do |user_data|
    user = User.find_or_initialize_by(email: user_data[:email])
    
    # Set all attributes (create or update)
    user.assign_attributes(
      password: "password123",
      password_confirmation: "password123", 
      first_name: user_data[:first_name],
      last_name: user_data[:last_name],
      role: "user",
      last_activity_at: user_data[:activity_date]
    )
    
    user.save!
    test_users << user
    
    puts "✅ #{user_data[:status]}: #{user.first_name} #{user.last_name} (#{user_data[:activity_date] ? user_data[:activity_date].strftime('%Y-%m-%d') : 'nil'})"
  end

  # Create coach-user relationships
  test_users.each do |user|
    relationship = CoachUser.find_or_create_by!(coach: coach, user: user)
    puts "✅ Assigned #{user.first_name} #{user.last_name} to coach"
  end

  # Also assign basic_user to coach for completeness
  CoachUser.find_or_create_by!(coach: coach, user: basic_user)
  puts "✅ Assigned Demo User to coach"

  # Verify users were created
  total_users = User.count
  admin_count = User.admin.count
  coach_count = User.coach.count
  user_count = User.user.count

  # Populate last_activity_at for existing users based on workout history
  puts "🔄 Populating last_activity_at for existing users..."

  updated_count = 0
  User.includes(:workouts).find_each do |user|
    last_workout_date = user.workouts.maximum(:created_at)

    if last_workout_date && user.last_activity_at.blank?
      user.update_column(:last_activity_at, last_workout_date)
      updated_count += 1
    end
  end

  puts "✅ Updated #{updated_count} users with last_activity_at"

  puts "📊 Database stats:"
  puts "   Total users: #{total_users}"
  puts "   Admins: #{admin_count}"
  puts "   Coaches: #{coach_count}"
  puts "   Basic users: #{user_count}"
  puts "   Users with activity data: #{User.where.not(last_activity_at: nil).count}"

  puts "🎉 Database seeding completed successfully!"

rescue => e
  puts "❌ Error during seeding: #{e.message}"
  puts "❌ Backtrace: #{e.backtrace.first(5).join('\n')}"
  raise e
end
