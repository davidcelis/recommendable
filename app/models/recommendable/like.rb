module Recommendable
  class Like < ActiveRecord::Base
    self.table_name = 'recommendable_likes'

    belongs_to :user, :class_name => Recommendable.user_class.to_s
    belongs_to :likeable, :polymorphic => true
    
    validates :user_id, :uniqueness => { :scope => [:likeable_id, :likeable_type],
                                         :message => "has already liked this item" }
  end
end
