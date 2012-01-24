module Recommendable
  class Like < ActiveRecord::Base
    belongs_to :user, :class_name => Recommendable.user_class.to_s
    belongs_to :likeable, :polymorphic => :true
    
    validates_uniqueness_of :likeable_id, :scope => [:user_id, :likeable_type],
                            :message => "already exists for this item"
  end
end