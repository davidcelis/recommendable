module Recommendable
  class Ignore < ActiveRecord::Base
    self.table_name = 'recommendable_ignores'
    attr_accessible :user_id, :ignorable_id, :ignorable_type

    belongs_to :user, :class_name => Recommendable.user_class.to_s, :foreign_key => :user_id
    belongs_to :ignorable, :polymorphic => true
    
    validates :user_id, :uniqueness => { :scope => [:ignorable_id, :ignorable_type],
                                         :message => "has already ignored this item" },
                        :presence => true
    validates_presence_of :ignorable_id
    validates_presence_of :ignorable_type
    
    def ignorable_type=(sType)
      super sType.to_s.classify.constantize.base_class.to_s
    end
  end
end
