module Recommendable
  class Dislike < ActiveRecord::Base
    belongs_to :user, :class_name => Recommendable.user_class.to_s
    belongs_to :dislikeable, :polymorphic => :true
    
    validates_uniqueness_of :dislikeable_id, :scope => [:user_id, :dislikeable_type],
                            :message => "already exists for this item"
  end
end