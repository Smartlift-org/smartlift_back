# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2025_06_03_145139) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "coach_users", force: :cascade do |t|
    t.bigint "coach_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["coach_id", "user_id"], name: "index_coach_users_on_coach_id_and_user_id", unique: true
    t.index ["coach_id"], name: "index_coach_users_on_coach_id"
    t.index ["user_id"], name: "index_coach_users_on_user_id"
  end

  create_table "exercises", force: :cascade do |t|
    t.string "name"
    t.string "equipment"
    t.string "category"
    t.string "difficulty"
    t.text "instructions"
    t.string "primary_muscles", default: [], array: true
    t.string "secondary_muscles", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "force"
    t.string "mechanic"
    t.string "level"
    t.string "images", default: [], array: true
    t.index ["force"], name: "index_exercises_on_force"
    t.index ["images"], name: "index_exercises_on_images", using: :gin
    t.index ["level"], name: "index_exercises_on_level"
    t.index ["mechanic"], name: "index_exercises_on_mechanic"
  end

  create_table "routine_exercises", force: :cascade do |t|
    t.bigint "routine_id", null: false
    t.bigint "exercise_id", null: false
    t.integer "sets", null: false
    t.integer "reps", null: false
    t.integer "rest_time", default: 0, null: false
    t.integer "order", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["exercise_id"], name: "index_routine_exercises_on_exercise_id"
    t.index ["routine_id", "exercise_id", "order"], name: "index_routine_exercises_on_routine_id_and_exercise_id_and_order", unique: true
    t.index ["routine_id"], name: "index_routine_exercises_on_routine_id"
  end

  create_table "routines", force: :cascade do |t|
    t.string "name", null: false
    t.text "description", null: false
    t.string "difficulty", null: false
    t.integer "duration", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "name"], name: "index_routines_on_user_id_and_name", unique: true
    t.index ["user_id"], name: "index_routines_on_user_id"
  end

  create_table "user_stats", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.decimal "height", precision: 5, scale: 2
    t.decimal "weight", precision: 5, scale: 2
    t.integer "age"
    t.string "gender", limit: 50
    t.string "fitness_goal", limit: 100
    t.string "experience_level", limit: 50
    t.integer "available_days"
    t.string "equipment_available", limit: 100
    t.string "activity_level", limit: 50
    t.string "physical_limitations", limit: 100
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_user_stats_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "email"
    t.string "password_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "role"
  end

  add_foreign_key "coach_users", "users"
  add_foreign_key "coach_users", "users", column: "coach_id"
  add_foreign_key "routine_exercises", "exercises"
  add_foreign_key "routine_exercises", "routines"
  add_foreign_key "routines", "users"
  add_foreign_key "user_stats", "users"
end
