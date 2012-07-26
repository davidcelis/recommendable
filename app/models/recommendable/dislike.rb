module Recommendable
  class Dislike < ActiveRecord::Base
    self.table_name = 'recommendable_dislikes'
    attr_accessible :user_id, :dislikeable_id, :dislikeable_type

    belongs_to :user, :class_name => Recommendable.user_class.to_s, :foreign_key => :user_id
    belongs_to :dislikeable, :polymorphic => true
    
    validates :user_id, :uniqueness => { :scope => [:dislikeable_id, :dislikeable_type],
                                         :message => "has already disliked this item" },
                        :presence => true
    validates_presence_of :dislikeable_id
    validates_presence_of :dislikeable_type

    def dislikeable_type=(sType)
      super sType.to_s.classify.constantize.base_class.to_s
    end
  end
end
