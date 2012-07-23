require 'recommendable/engine'
require 'recommendable/helpers'
require 'recommendable/acts_as_recommended_to'
require 'recommendable/acts_as_recommendable'
require 'recommendable/exceptions'
require 'recommendable/railtie' if defined?(Rails)
require 'recommendable/version'
require 'hooks'
require 'sidekiq/middleware/client/unique_jobs' if defined?(Sidekiq)
require 'sidekiq/middleware/server/unique_jobs' if defined?(Sidekiq)

module Recommendable
  mattr_accessor :redis, :user_class
  mattr_writer :recommendable_classes
  
  def self.recommendable_classes
    @@recommendable_classes ||= []
  end

  def self.enqueue(user_id)
    if defined? Sidekiq
      SidekiqWorker.perform_async user_id
    elsif defined? Resque
      Resque.enqueue ResqueWorker, user_id
    elsif defined? Delayed::Job
      Delayed::Job.enqueue DelayedJobWorker.new(user_id)
    elsif defined? Rails::Queueing
      unless Rails.queue.any? { |w| w.user_id == user_id }
        Rails.queue.push RailsWorker.new(user_id)
        Rails.application.queue_consumer.start
      end
    end
  end
end
