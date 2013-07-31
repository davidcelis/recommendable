require 'recommendable/rater/liker'
require 'recommendable/rater/disliker'
require 'recommendable/rater/hider'
require 'recommendable/rater/bookmarker'
require 'recommendable/rater/recommender'
require 'hooks'

module Recommendable
  module Rater
    extend ActiveSupport::Concern

    module ClassMethods
      def recommends(*things)
        Recommendable.configure do |config|
          config.ratable_classes = []
          config.user_class      = self
        end

        things.each { |thing| thing.to_s.classify.constantize.make_recommendable! }

        class_eval do
          include Liker
          include Disliker
          include Hider
          include Bookmarker
          include Recommender
          include Hooks

          case
          when defined?(Sequel::Model) && ancestors.include?(Sequel::Model)
            def before_destroy
              super
              remove_from_recommendable!
            end
          when defined?(ActiveRecord::Base)            && ancestors.include?(ActiveRecord::Base),
               defined?(Mongoid::Document)             && ancestors.include?(Mongoid::Document),
               defined?(MongoMapper::Document)         && ancestors.include?(MongoMapper::Document),
               defined?(MongoMapper::EmbeddedDocument) && ancestors.include?(MongoMapper::EmbeddedDocument)
            before_destroy :remove_from_recommendable!
          when defined?(DataMapper::Resource) && ancestors.include?(DataMapper::Resource)
            before :destroy, :remove_from_recommendable!
          else
            warn "Model #{self} is not using a supported ORM. You must handle removal from Redis manually when destroying instances."
          end

          define_hooks :before_like,     :after_like,     :before_unlike,     :after_unlike,
                       :before_dislike,  :after_dislike,  :before_undislike,  :after_undislike,
                       :before_hide,     :after_hide,     :before_unhide,     :after_unhide,
                       :before_bookmark, :after_bookmark, :before_unbookmark, :after_unbookmark

          before_like    lambda { |obj| undislike(obj) || unhide(obj) }
          before_dislike lambda { |obj| unlike(obj)    || unhide(obj) }

          %w[like unlike dislike undislike].each do |action|
            send("after_#{action}", lambda { |obj|
              Recommendable::Helpers::Calculations.update_score_for(obj.class, obj.id)
              Recommendable.enqueue(self.id) if Recommendable.config.auto_enqueue
            })
          end

          %w[like dislike hide bookmark].each do |action|
            send("after_#{action}", lambda { |obj| unrecommend(obj) })
          end

          def method_missing(method, *args, &block)
            if method.to_s =~ /\A((?:dis)?liked|hidden|bookmarked)_(.+)_in_common_with\z/
              begin
                send("#{$1}_in_common_with", $2.classify.constantize, *args)
              rescue NameError
                super
              end
            elsif method.to_s =~ /\A((?:dis)?liked|hidden|bookmarked)_(.+)_count\z/
              begin
                send("#{$1}_count_for", $2.classify.constantize, *args)
              rescue NameError
                super
              end
            elsif method.to_s =~ /\A((?:dis)?liked|hidden|bookmarked)_(.+)_ids\z/
              begin
                send("#{$1}_ids_for", $2.classify.constantize, *args)
              rescue NameError
                super
              end
            elsif method.to_s =~ /\A((?:dis)?liked|hidden|bookmarked|recommended)_(.+)\z/
              begin
                send("#{$1}_for", $2.classify.constantize, *args)
              rescue NameError
                super
              end
            else
              super
            end
          end

          def respond_to?(method, include_private = false)
            if method.to_s =~ /\A((?:dis)?liked|hidden|bookmarked)_(.+)_in_common_with\z/ ||
               method.to_s =~ /\A((?:dis)?liked|hidden|bookmarked)_(.+)_ids\z/ ||
               method.to_s =~ /\A((?:dis)?liked|hidden|bookmarked|recommended)_(.+)\z/
              begin
                true if $2.classify.constantize.recommendable?
              rescue NameError
                false
              end
            else
              super
            end
          end

          def rated?(obj)
            likes?(obj) || dislikes?(obj)
          end

          def rated_anything?
            likes_count > 0 || dislikes_count > 0
          end

          def unrate(obj)
            unlike(obj) || undislike(obj) || unhide(obj)
            unbookmark(obj)
          end
        end
      end
    end
  end
end
