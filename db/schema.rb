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

ActiveRecord::Schema.define(version: 20170307010644) do

  create_table "schedules", force: :cascade do |t|
    t.integer "user_id"
    t.integer "chat_id",  limit: 8, null: false
    t.string  "cronwhen"
    t.string  "command"
  end

  create_table "users", id: false, force: :cascade do |t|
    t.integer  "id"
    t.string   "username"
    t.string   "first_name"
    t.string   "last_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "users", ["id"], name: "index_users_on_id"
  add_index "users", ["username"], name: "index_users_on_username"

end
