module Recommendable
  class StashedItem < ActiveRecord::Base
    belongs_to :user, :class_name => Recommendable.user_class.to_s
    belongs_to :stashable, :polymorphic => :true
    
    validates :user_id, :uniqueness => { :scope => [:stashable_id, :stashable_type],
                                         :message => "has already stashed this item" }
  end
end
