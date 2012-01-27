module Recommendable
  class Dislike < ActiveRecord::Base
    belongs_to :user, :class_name => Recommendable.user_class.to_s
    belongs_to :dislikeable, :polymorphic => :true
    
    validates :user_id, :uniqueness => { :scope => [:dislikeable_id, :dislikeable_type],
                                         :message => "has already disliked this item" }
  end
end
