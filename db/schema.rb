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

ActiveRecord::Schema[8.1].define(version: 2026_08_05_200008) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "activity_logs", force: :cascade do |t|
    t.date "activity_date", null: false
    t.integer "activity_type", null: false
    t.datetime "created_at", null: false
    t.decimal "distance_km", precision: 6, scale: 2
    t.string "evidence_url"
    t.boolean "evidence_valid", default: false, null: false
    t.uuid "import_batch_id"
    t.bigint "participant_id", null: false
    t.decimal "raw_points", precision: 6, scale: 2, default: "0.0", null: false
    t.integer "source", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["import_batch_id"], name: "index_activity_logs_on_import_batch_id"
    t.index ["participant_id", "activity_date"], name: "index_activity_logs_on_participant_id_and_activity_date"
    t.index ["participant_id"], name: "index_activity_logs_on_participant_id"
  end

  create_table "criteria", force: :cascade do |t|
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.integer "criterion_type", default: 0, null: false
    t.string "name", null: false
    t.integer "position", null: false
    t.datetime "updated_at", null: false
    t.decimal "weight", precision: 5, scale: 4, null: false
    t.index ["code"], name: "index_criteria_on_code", unique: true
    t.index ["position"], name: "index_criteria_on_position", unique: true
  end

  create_table "criterion_scores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "criterion_id", null: false
    t.decimal "normalized_value", precision: 8, scale: 4, null: false
    t.string "notes"
    t.bigint "participant_id", null: false
    t.decimal "raw_value", precision: 10, scale: 2
    t.datetime "updated_at", null: false
    t.index ["criterion_id"], name: "index_criterion_scores_on_criterion_id"
    t.index ["participant_id", "criterion_id"], name: "index_criterion_scores_on_participant_id_and_criterion_id", unique: true
    t.index ["participant_id"], name: "index_criterion_scores_on_participant_id"
  end

  create_table "events", force: :cascade do |t|
    t.integer "bonus_cardio_target", default: 3, null: false
    t.integer "bonus_strength_target", default: 2, null: false
    t.datetime "created_at", null: false
    t.integer "daily_point_cap", default: 4, null: false
    t.date "end_date", null: false
    t.integer "fun_sport_point_target", default: 4, null: false
    t.decimal "long_run_target_km", precision: 6, scale: 2, default: "10.0", null: false
    t.integer "max_consecutive_cardio_days", default: 3, null: false
    t.string "name", null: false
    t.date "start_date", null: false
    t.integer "streak_penalty_per_violation", default: 25, null: false
    t.integer "target_cardio", default: 24, null: false
    t.integer "target_strength", default: 16, null: false
    t.integer "total_weeks", default: 4, null: false
    t.datetime "updated_at", null: false
    t.integer "weekly_cardio_target", default: 2, null: false
    t.integer "weekly_strength_target", default: 1, null: false
  end

  create_table "participants", force: :cascade do |t|
    t.string "alternative_code", null: false
    t.datetime "created_at", null: false
    t.string "department"
    t.bigint "event_id", null: false
    t.string "name", null: false
    t.string "nip", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["event_id", "alternative_code"], name: "index_participants_on_event_id_and_alternative_code", unique: true
    t.index ["event_id", "nip"], name: "index_participants_on_event_id_and_nip", unique: true
    t.index ["event_id"], name: "index_participants_on_event_id"
    t.index ["user_id"], name: "index_participants_on_user_id"
  end

  create_table "ranking_results", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "d_negative", precision: 12, scale: 8, null: false
    t.decimal "d_positive", precision: 12, scale: 8, null: false
    t.bigint "participant_id", null: false
    t.decimal "preference_value", precision: 8, scale: 4, null: false
    t.integer "rank", null: false
    t.bigint "topsis_run_id", null: false
    t.datetime "updated_at", null: false
    t.index ["participant_id"], name: "index_ranking_results_on_participant_id"
    t.index ["topsis_run_id", "participant_id"], name: "index_ranking_results_on_topsis_run_id_and_participant_id", unique: true
    t.index ["topsis_run_id", "rank"], name: "index_ranking_results_on_topsis_run_id_and_rank"
    t.index ["topsis_run_id"], name: "index_ranking_results_on_topsis_run_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "topsis_runs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "decision_matrix", default: {}, null: false
    t.bigint "event_id", null: false
    t.datetime "executed_at", null: false
    t.bigint "executed_by_id"
    t.jsonb "ideal_negative", default: {}, null: false
    t.jsonb "ideal_positive", default: {}, null: false
    t.jsonb "normalized_matrix", default: {}, null: false
    t.datetime "updated_at", null: false
    t.jsonb "weighted_matrix", default: {}, null: false
    t.jsonb "weights_snapshot", default: {}, null: false
    t.index ["event_id", "executed_at"], name: "index_topsis_runs_on_event_id_and_executed_at"
    t.index ["event_id"], name: "index_topsis_runs_on_event_id"
    t.index ["executed_by_id"], name: "index_topsis_runs_on_executed_by_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "name", null: false
    t.string "password_digest", null: false
    t.integer "role", default: 2, null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "activity_logs", "participants"
  add_foreign_key "criterion_scores", "criteria"
  add_foreign_key "criterion_scores", "participants"
  add_foreign_key "participants", "events"
  add_foreign_key "participants", "users"
  add_foreign_key "ranking_results", "participants"
  add_foreign_key "ranking_results", "topsis_runs"
  add_foreign_key "sessions", "users"
  add_foreign_key "topsis_runs", "events"
  add_foreign_key "topsis_runs", "users", column: "executed_by_id"
end
