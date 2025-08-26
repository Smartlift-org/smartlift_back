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

ActiveRecord::Schema[7.1].define(version: 2025_08_24_235500) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_trgm"
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "coach_users", force: :cascade do |t|
    t.bigint "coach_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["coach_id", "user_id"], name: "index_coach_users_on_coach_id_and_user_id", unique: true
    t.index ["coach_id"], name: "index_coach_users_on_coach_id"
    t.index ["user_id"], name: "index_coach_users_on_user_id"
  end

  create_table "conversations", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "coach_id", null: false
    t.string "status", default: "active"
    t.datetime "last_message_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["coach_id"], name: "index_conversations_on_coach_id"
    t.index ["last_message_at"], name: "index_conversations_on_last_message_at"
    t.index ["user_id", "coach_id"], name: "index_conversations_on_user_id_and_coach_id", unique: true
    t.index ["user_id"], name: "index_conversations_on_user_id"
  end

  create_table "exercises", force: :cascade do |t|
    t.string "name"
    t.text "instructions"
    t.string "primary_muscles", default: [], array: true
    t.string "level"
    t.string "images", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "video_url"
    t.index ["images"], name: "index_exercises_on_images", using: :gin
    t.index ["level"], name: "index_exercises_on_level"
    t.index ["video_url"], name: "index_exercises_on_video_url"
  end

  create_table "messages", force: :cascade do |t|
    t.bigint "conversation_id", null: false
    t.bigint "sender_id", null: false
    t.text "content", null: false
    t.string "message_type", default: "text"
    t.datetime "read_at"
    t.json "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["conversation_id", "created_at"], name: "index_messages_on_conversation_id_and_created_at"
    t.index ["conversation_id"], name: "index_messages_on_conversation_id"
    t.index ["sender_id", "created_at"], name: "index_messages_on_sender_id_and_created_at"
    t.index ["sender_id"], name: "index_messages_on_sender_id"
  end

  create_table "routine_exercises", force: :cascade do |t|
    t.bigint "routine_id", null: false
    t.bigint "exercise_id", null: false
    t.integer "sets", null: false
    t.integer "reps", null: false
    t.integer "rest_time", default: 0, null: false
    t.integer "order", null: false
    t.string "group_type", default: "regular"
    t.integer "group_order"
    t.decimal "weight", precision: 8, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["exercise_id"], name: "index_routine_exercises_on_exercise_id"
    t.index ["routine_id", "exercise_id", "order"], name: "index_routine_exercises_on_routine_id_and_exercise_id_and_order", unique: true
    t.index ["routine_id", "group_type", "group_order"], name: "idx_on_routine_id_group_type_group_order_6af3f864b1"
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
    t.string "source_type", default: "manual", null: false
    t.boolean "ai_generated", default: false, null: false
    t.string "validation_status", default: "pending", null: false
    t.integer "validated_by_id"
    t.datetime "validated_at"
    t.text "validation_notes"
    t.json "ai_prompt_data"
    t.index ["ai_generated"], name: "index_routines_on_ai_generated"
    t.index ["source_type"], name: "index_routines_on_source_type"
    t.index ["user_id", "name"], name: "index_routines_on_user_id_and_name", unique: true
    t.index ["user_id"], name: "index_routines_on_user_id"
    t.index ["validated_by_id"], name: "index_routines_on_validated_by_id"
    t.index ["validation_status"], name: "index_routines_on_validation_status"
  end

  create_table "user_privacy_settings", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.boolean "show_name", default: true, null: false
    t.boolean "show_profile_picture", default: true, null: false
    t.boolean "show_workout_count", default: true, null: false
    t.boolean "show_join_date", default: false, null: false
    t.boolean "show_personal_records", default: false, null: false
    t.boolean "show_favorite_exercises", default: false, null: false
    t.boolean "is_profile_public", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["is_profile_public"], name: "index_user_privacy_settings_on_is_profile_public"
    t.index ["user_id"], name: "index_user_privacy_settings_on_user_id", unique: true
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
    t.string "password_reset_token"
    t.datetime "password_reset_sent_at"
    t.string "profile_picture_url"
    t.datetime "last_activity_at"
    t.string "expo_push_token"
    t.boolean "push_notifications_enabled", default: true
    t.index ["expo_push_token"], name: "index_users_on_expo_push_token"
    t.index ["last_activity_at"], name: "index_users_on_last_activity_at"
    t.index ["password_reset_token"], name: "index_users_on_password_reset_token", unique: true
  end

  create_table "workout_exercises", force: :cascade do |t|
    t.bigint "workout_id", null: false
    t.bigint "exercise_id", null: false
    t.bigint "routine_exercise_id"
    t.integer "order", null: false
    t.string "group_type", default: "regular", null: false
    t.integer "group_order"
    t.integer "target_sets"
    t.integer "target_reps"
    t.decimal "suggested_weight", precision: 8, scale: 2
    t.text "notes"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["exercise_id"], name: "index_workout_exercises_on_exercise_id"
    t.index ["routine_exercise_id"], name: "index_workout_exercises_on_routine_exercise_id"
    t.index ["workout_id", "exercise_id"], name: "index_workout_exercises_on_workout_id_and_exercise_id"
    t.index ["workout_id", "group_type", "group_order"], name: "idx_on_workout_id_group_type_group_order_94bdfc90ac"
    t.index ["workout_id", "group_type", "group_order"], name: "idx_workout_exercises_group"
    t.index ["workout_id", "order"], name: "idx_workout_exercises_order"
    t.index ["workout_id", "order"], name: "index_workout_exercises_on_workout_id_and_order", unique: true
    t.index ["workout_id"], name: "index_workout_exercises_on_workout_id"
  end

  create_table "workout_sets", force: :cascade do |t|
    t.bigint "workout_exercise_id", null: false
    t.integer "set_number", null: false
    t.string "set_type", default: "normal", null: false
    t.decimal "weight", precision: 8, scale: 2
    t.integer "reps"
    t.boolean "completed", default: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["completed"], name: "index_workout_sets_on_completed"
    t.index ["created_at"], name: "idx_workout_sets_created_at"
    t.index ["set_type", "completed"], name: "idx_workout_sets_type_completed"
    t.index ["weight", "workout_exercise_id"], name: "idx_workout_sets_weight_exercise", where: "((completed = true) AND ((set_type)::text = 'normal'::text))"
    t.index ["workout_exercise_id", "completed"], name: "idx_workout_sets_exercise_completed"
    t.index ["workout_exercise_id", "set_number"], name: "index_workout_sets_on_workout_exercise_id_and_set_number", unique: true
    t.index ["workout_exercise_id"], name: "index_workout_sets_on_workout_exercise_id"
  end

  create_table "workouts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "routine_id"
    t.string "status", default: "in_progress", null: false
    t.datetime "started_at", null: false
    t.datetime "completed_at"
    t.text "notes"
    t.decimal "total_volume", precision: 10, scale: 2
    t.integer "total_sets_completed"
    t.integer "total_exercises_completed"
    t.decimal "average_rpe", precision: 3, scale: 1
    t.integer "total_duration_seconds"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "workout_type", default: 0, null: false
    t.string "name"
    t.integer "workout_rating"
    t.index ["completed_at"], name: "index_workouts_on_completed_at"
    t.index ["routine_id"], name: "index_workouts_on_routine_id"
    t.index ["started_at"], name: "index_workouts_on_started_at"
    t.index ["user_id", "status"], name: "index_workouts_on_user_id_and_status"
    t.index ["user_id", "workout_type"], name: "index_workouts_on_user_id_and_workout_type"
    t.index ["user_id"], name: "index_workouts_on_user_id"
    t.index ["workout_type"], name: "index_workouts_on_workout_type"
    t.check_constraint "workout_rating >= 1 AND workout_rating <= 10", name: "workout_rating_range"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "coach_users", "users"
  add_foreign_key "coach_users", "users", column: "coach_id"
  add_foreign_key "conversations", "users"
  add_foreign_key "conversations", "users", column: "coach_id"
  add_foreign_key "messages", "conversations"
  add_foreign_key "messages", "users", column: "sender_id"
  add_foreign_key "routine_exercises", "exercises"
  add_foreign_key "routine_exercises", "routines"
  add_foreign_key "routines", "users"
  add_foreign_key "routines", "users", column: "validated_by_id"
  add_foreign_key "user_privacy_settings", "users"
  add_foreign_key "user_stats", "users"
  add_foreign_key "workout_exercises", "exercises"
  add_foreign_key "workout_exercises", "routine_exercises"
  add_foreign_key "workout_exercises", "workouts"
  add_foreign_key "workout_sets", "workout_exercises"
  add_foreign_key "workouts", "routines"
  add_foreign_key "workouts", "users"
end
