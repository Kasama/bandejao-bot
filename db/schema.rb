# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170312023427) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "schedules", force: :cascade do |t|
    t.integer "user_id"
    t.integer "chat_id",  limit: 8, null: false
    t.string  "cronwhen"
    t.string  "command"
  end

  create_table "users", force: :cascade do |t|
    t.string   "username"
    t.string   "first_name"
    t.string   "last_name"
    t.datetime "created_at",                                                                                                                                           null: false
    t.datetime "updated_at",                                                                                                                                           null: false
    t.text     "preferences", default: "---\n:campus: :campus_de_sao_carlos\n:restaurant: :restaurante_area1\n:campus_alias: São Carlos\n:restaurant_alias: Área 1\n"
  end

  add_index "users", ["id"], name: "index_users_on_id", using: :btree
  add_index "users", ["username"], name: "index_users_on_username", using: :btree

  add_foreign_key "schedules", "users"
end
