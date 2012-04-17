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
    t.integer  "ignorable_id"
    t.string   "ignorable_type"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
  end

  add_index "recommendable_ignores", ["ignorable_id"], :name => "index_recommendable_ignores_on_ignorable_id"
  add_index "recommendable_ignores", ["ignorable_type"], :name => "index_recommendable_ignores_on_ignorable_type"
  add_index "recommendable_ignores", ["user_id", "ignorable_id", "ignorable_type"], :name => "user_ignore_constraint", :unique => true

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

  create_table "recommendable_stashes", :force => true do |t|
    t.integer  "user_id"
    t.integer  "stashable_id"
    t.string   "stashable_type"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
  end

  add_index "recommendable_stashes", ["stashable_id"], :name => "index_recommendable_stashes_on_stashable_id"
  add_index "recommendable_stashes", ["stashable_type"], :name => "index_recommendable_stashes_on_stashable_type"
  add_index "recommendable_stashes", ["user_id", "stashable_id", "stashable_type"], :name => "user_stashed_constraint", :unique => true

  create_table "users", :force => true do |t|
    t.string   "username"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

end
