module Recommendable
  class StashedItem < ActiveRecord::Base
    self.table_name = 'recommendable_stashed_items'
    attr_accessible :user_id, :stashable_id, :stashable_type

    belongs_to :user, :class_name => Recommendable.user_class.to_s, :foreign_key => :user_id
    belongs_to :stashable, :polymorphic => :true
    
    validates :user_id, :uniqueness => { :scope => [:stashable_id, :stashable_type],
                                         :message => "has already stashed this item" }
  end
end
