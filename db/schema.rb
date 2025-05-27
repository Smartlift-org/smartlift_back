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

ActiveRecord::Schema[8.0].define(version: 2025_05_26_233247) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

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

  create_table "users", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "email"
    t.string "password_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end
end
