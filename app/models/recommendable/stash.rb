module Recommendable
  class Stash < ActiveRecord::Base
    self.table_name = 'recommendable_stashes'
    attr_accessible :user_id, :stashable_id, :stashable_type

    belongs_to :user, :class_name => Recommendable.user_class.to_s, :foreign_key => :user_id
    belongs_to :stashable, :polymorphic => :true
    
    validates :user_id, :uniqueness => { :scope => [:stashable_id, :stashable_type],
                                         :message => "has already stashed this item" },
                        :presence => true
    validates_presence_of :stashable_id
    validates_presence_of :stashable_type
    
    def stashable_type=(sType)
      super sType.to_s.classify.constantize.base_class.to_s
    end
  end
end
