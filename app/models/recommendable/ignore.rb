module Recommendable
  class Ignore < ActiveRecord::Base
    self.table_name = 'recommendable_ignores'
    attr_accessible :user_id, :ignoreable_id, :ignoreable_type

    belongs_to :user, :class_name => Recommendable.user_class.to_s, :foreign_key => :user_id
    belongs_to :ignoreable, :polymorphic => true
    
    validates :user_id, :uniqueness => { :scope => [:ignoreable_id, :ignoreable_type],
                                         :message => "has already ignored this item" }
    def ignoreable_type=(sType)
      super sType.to_s.classify.constantize.base_class.to_s
    end
  end
end
