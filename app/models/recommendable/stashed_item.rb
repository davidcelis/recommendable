module Recommendable
  class StashedItem < ActiveRecord::Base
    self.table_name = 'recommendable_stashed_items'

    belongs_to :user, :class_name => Recommendable.user_class.to_s, :foreign_key => :user_id
    belongs_to :stashable, :polymorphic => :true
    
    validates :user_id, :uniqueness => { :scope => [:stashable_id, :stashable_type],
                                         :message => "has already stashed this item" }
  end
end
