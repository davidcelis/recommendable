module Recommendable
  class Like < ActiveRecord::Base
    self.table_name = 'recommendable_likes'
    attr_accessible :user_id, :likeable_id, :likeable_type

    belongs_to :user, :class_name => Recommendable.user_class.to_s, :foreign_key => :user_id
    belongs_to :likeable, :polymorphic => true
    
    validates :user_id, :uniqueness => { :scope => [:likeable_id, :likeable_type],
                                         :message => "has already liked this item" }
  end
end
