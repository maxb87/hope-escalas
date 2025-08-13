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

ActiveRecord::Schema[8.0].define(version: 2025_08_13_173846) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "patients", force: :cascade do |t|
    t.string "full_name", null: false
    t.integer "sex"
    t.date "birthday", null: false
    t.date "started_at"
    t.string "email", null: false
    t.string "cpf", null: false
    t.string "rg"
    t.integer "current_phone"
    t.integer "current_address"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cpf"], name: "index_patients_on_cpf", unique: true
    t.index ["deleted_at"], name: "index_patients_on_deleted_at"
    t.check_constraint "char_length(cpf::text) = 11 AND cpf::text ~ '^[0-9]{11}$'::text", name: "patients_cpf_format"
    t.check_constraint "char_length(full_name::text) >= 5", name: "patients_full_name_minlen"
    t.check_constraint "email::text ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$'::text", name: "patients_email_format"
  end

  create_table "professionals", force: :cascade do |t|
    t.string "full_name", null: false
    t.integer "sex"
    t.date "birthday", null: false
    t.date "started_at"
    t.string "email", null: false
    t.string "cpf", null: false
    t.string "rg"
    t.integer "current_phone"
    t.integer "current_address"
    t.string "professional_id"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cpf"], name: "index_professionals_on_cpf", unique: true
    t.index ["deleted_at"], name: "index_professionals_on_deleted_at"
    t.index ["email"], name: "index_professionals_on_email", unique: true
    t.check_constraint "char_length(cpf::text) = 11 AND cpf::text ~ '^[0-9]{11}$'::text", name: "professionals_cpf_format"
    t.check_constraint "char_length(full_name::text) >= 5", name: "professionals_full_name_minlen"
    t.check_constraint "email::text ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$'::text", name: "professionals_email_format"
  end

  create_table "psychometric_scale_items", force: :cascade do |t|
    t.bigint "psychometric_scale_id", null: false
    t.integer "item_number", null: false
    t.text "question_text", null: false
    t.jsonb "options", default: {}, null: false
    t.boolean "is_required", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["options"], name: "index_psychometric_scale_items_on_options", using: :gin
    t.index ["psychometric_scale_id", "item_number"], name: "index_scale_items_on_scale_and_number", unique: true
    t.index ["psychometric_scale_id"], name: "index_psychometric_scale_items_on_psychometric_scale_id"
  end

  create_table "psychometric_scales", force: :cascade do |t|
    t.string "name", null: false
    t.string "code", null: false
    t.text "description"
    t.string "version"
    t.boolean "is_active", default: true
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_psychometric_scales_on_code", unique: true
    t.index ["deleted_at"], name: "index_psychometric_scales_on_deleted_at"
    t.index ["is_active"], name: "index_psychometric_scales_on_is_active"
  end

  create_table "scale_requests", force: :cascade do |t|
    t.bigint "patient_id", null: false
    t.bigint "professional_id", null: false
    t.bigint "psychometric_scale_id", null: false
    t.integer "status", default: 0
    t.datetime "requested_at", null: false
    t.datetime "expires_at"
    t.text "notes"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_scale_requests_on_deleted_at"
    t.index ["expires_at"], name: "index_scale_requests_on_expires_at"
    t.index ["patient_id"], name: "index_scale_requests_on_patient_id"
    t.index ["professional_id"], name: "index_scale_requests_on_professional_id"
    t.index ["psychometric_scale_id"], name: "index_scale_requests_on_psychometric_scale_id"
    t.index ["requested_at"], name: "index_scale_requests_on_requested_at"
    t.index ["status"], name: "index_scale_requests_on_status"
  end

  create_table "scale_responses", force: :cascade do |t|
    t.bigint "scale_request_id", null: false
    t.bigint "patient_id", null: false
    t.bigint "psychometric_scale_id", null: false
    t.jsonb "answers", default: {}, null: false
    t.integer "total_score"
    t.string "interpretation"
    t.datetime "completed_at", null: false
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["answers"], name: "index_scale_responses_on_answers", using: :gin
    t.index ["completed_at"], name: "index_scale_responses_on_completed_at"
    t.index ["deleted_at"], name: "index_scale_responses_on_deleted_at"
    t.index ["patient_id"], name: "index_scale_responses_on_patient_id"
    t.index ["psychometric_scale_id"], name: "index_scale_responses_on_psychometric_scale_id"
    t.index ["scale_request_id"], name: "index_scale_responses_on_scale_request_id"
    t.index ["total_score"], name: "index_scale_responses_on_total_score"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "deleted_at"
    t.boolean "force_password_reset", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "account_type"
    t.bigint "account_id"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.index ["account_type", "account_id"], name: "index_users_on_account"
    t.index ["deleted_at"], name: "index_users_on_deleted_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  add_foreign_key "psychometric_scale_items", "psychometric_scales"
  add_foreign_key "scale_requests", "patients"
  add_foreign_key "scale_requests", "professionals"
  add_foreign_key "scale_requests", "psychometric_scales"
  add_foreign_key "scale_responses", "patients"
  add_foreign_key "scale_responses", "psychometric_scales"
  add_foreign_key "scale_responses", "scale_requests"
end
