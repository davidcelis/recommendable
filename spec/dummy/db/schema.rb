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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120131195416) do

  create_table "bullies", :force => true do |t|
    t.string   "username"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "movies", :force => true do |t|
    t.string   "title"
    t.integer  "year"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "php_frameworks", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "recommendable_dislikes", :force => true do |t|
    t.integer  "user_id"
    t.integer  "dislikeable_id"
    t.string   "dislikeable_type"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
  end

  add_index "recommendable_dislikes", ["dislikeable_id"], :name => "index_recommendable_dislikes_on_dislikeable_id"
  add_index "recommendable_dislikes", ["dislikeable_type"], :name => "index_recommendable_dislikes_on_dislikeable_type"
  add_index "recommendable_dislikes", ["user_id", "dislikeable_id", "dislikeable_type"], :name => "user_dislike_constraint", :unique => true

  create_table "recommendable_ignores", :force => true do |t|
    t.integer  "user_id"
    t.integer  "ignoreable_id"
    t.string   "ignoreable_type"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  add_index "recommendable_ignores", ["ignoreable_id"], :name => "index_recommendable_ignores_on_ignoreable_id"
  add_index "recommendable_ignores", ["ignoreable_type"], :name => "index_recommendable_ignores_on_ignoreable_type"
  add_index "recommendable_ignores", ["user_id", "ignoreable_id", "ignoreable_type"], :name => "user_ignore_constraint", :unique => true

  create_table "recommendable_likes", :force => true do |t|
    t.integer  "user_id"
    t.integer  "likeable_id"
    t.string   "likeable_type"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  add_index "recommendable_likes", ["likeable_id"], :name => "index_recommendable_likes_on_likeable_id"
  add_index "recommendable_likes", ["likeable_type"], :name => "index_recommendable_likes_on_likeable_type"
  add_index "recommendable_likes", ["user_id", "likeable_id", "likeable_type"], :name => "user_like_constraint", :unique => true

  create_table "recommendable_stashed_items", :force => true do |t|
    t.integer  "user_id"
    t.integer  "stashable_id"
    t.string   "stashable_type"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
  end

  add_index "recommendable_stashed_items", ["stashable_id"], :name => "index_recommendable_stashed_items_on_stashable_id"
  add_index "recommendable_stashed_items", ["stashable_type"], :name => "index_recommendable_stashed_items_on_stashable_type"
  add_index "recommendable_stashed_items", ["user_id", "stashable_id", "stashable_type"], :name => "user_stashed_constraint", :unique => true

  create_table "users", :force => true do |t|
    t.string   "username"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

end
