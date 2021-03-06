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

ActiveRecord::Schema.define(version: 20131223224254) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "uuid-ossp"

  create_table "claims", id: :uuid, default: "uuid_generate_v4()", force: true do |t|
    t.integer  "member_id",          limit: 8
    t.decimal  "rate"
    t.integer  "points",             limit: 8
    t.decimal  "xrp_disbursed"
    t.string   "transaction_hash"
    t.string   "transaction_status"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "rolled_over",                  default: false
  end

  create_table "users", force: true do |t|
    t.string   "username"
    t.string   "ripple_address"
    t.integer  "member_id",         limit: 8
    t.string   "verification_code"
    t.boolean  "eligible"
    t.integer  "points_claimed",    limit: 8
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "initial_run_time",  limit: 8
    t.integer  "initial_points",    limit: 8
    t.integer  "total_points",      limit: 8
    t.integer  "total_time",        limit: 8
    t.boolean  "funded",                      default: false
  end

  add_index "users", ["member_id"], name: "index_users_on_member_id", unique: true, using: :btree

end
