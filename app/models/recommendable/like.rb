module Recommendable
  class Like < ActiveRecord::Base
    belongs_to :user, :class_name => Recommendable.user_class.to_s
    belongs_to :likeable, :polymorphic => :true
    
    validates :user_id, :uniqueness => { :scope => [:likeable_id, :likeable_type],
                                         :message => "has already liked this item" }
    validates :likeable_type, :inclusion => { :in => Recommendable.recommendable_classes.map(&:to_s),
                                      :message => "has not been declared as recommendable yet!" }
  end
end