module Recommendable
  class Ignore < ActiveRecord::Base
    belongs_to :user, :class_name => Recommendable.user_class.to_s
    belongs_to :ignoreable, :polymorphic => :true
    
    validates :user_id, :uniqueness => { :scope => [:ignoreable_id, :ignoreable_type],
                                         :message => "has already liked this item" }
  end
end
