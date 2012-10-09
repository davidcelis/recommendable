require 'active_support'

require 'recommendable/version'
require 'recommendable/configuration'
require 'recommendable/helpers'

require 'recommendable/rater'
require 'recommendable/ratable'

module Recommendable
  class << self
    def redis() config.redis end

    def query(klass, ids)
        Recommendable::Helpers::Queriers.send(Recommendable.config.orm, klass, ids)
      rescue NoMethodError
        warn 'Your ORM is not currently supported. Please open an issue at https://github.com/davidcelis/recommendable'
    end

    def enqueue(user_id)
      user_id = user_id.id if user_id.is_a?(Recommendable.config.user_class)

      if defined?(::Sidekiq)
        require 'recommendable/workers/sidekiq'
        Recommendable::Workers::Sidekiq.perform_async(user_id)
      elsif defined?(::Resque)
        require 'recommendable/workers/resque'
        Resque.enqueue(Recommendable::Workers::Resque, user_id)
      elsif defined?(::Delayed::Job)
        require 'recommendable/workers/delayed_job'
        Delayed::Job.enqueue(Recommendable::Workers::DelayedJob.new(user_id))
      elsif defined?(::Rails::Queueing)
        require 'recommendable/workers/rails'
        unless Rails.queue.any? { |w| w.user_id == user_id }
          Rails.queue.push(Recommendable::Workers::Rails.new(user_idid))
          Rails.application.queue_consumer.start
        end
      end
    end
  end
end

require 'recommendable/orm/active_record' if defined?(ActiveRecord::Base)
require 'recommendable/orm/data_mapper' if defined?(DataMapper::Resource)
require 'recommendable/orm/mongoid' if defined?(Mongoid::Document)
require 'recommendable/orm/mongo_mapper' if defined?(MongoMapper::Document)
