module Recommendable
  class Like < ActiveRecord::Base
    self.table_name = 'recommendable_likes'
    attr_accessible :user_id, :likeable_id, :likeable_type

    belongs_to :user, :class_name => Recommendable.user_class.to_s, :foreign_key => :user_id
    belongs_to :likeable, :polymorphic => true, :foreign_key => :likeable_id
    
    validates :user_id, :uniqueness => { :scope => [:likeable_id, :likeable_type],
                                         :message => "has already liked this item" },
                        :presence => true
    validates_presence_of :likeable_id
    validates_presence_of :likeable_type

    def likeable_type=(sType)
      super sType.to_s.classify.constantize.base_class.to_s
    end
  end
end
