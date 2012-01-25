require 'rails/generators'
module Recommendable
  module Generators
    class InstallGenerator < Rails::Generators::Base
      class_option "no-migrate", :type => :boolean
      class_option "user-class", :type => :string
      class_option "redis-host", :type => :string
      class_option "redis-port", :type => :int
      class_option "redis-socket", :type => :string
      
      source_root File.expand_path("../install/templates", __FILE__)
      
      def add_recommendable_initializer
        path = "#{Rails.root}/config/initializers/recommendable.rb"
        if File.exists?(path)
          puts "Skipping config/initializers/recommendable.rb creation; file already exists!"
        else
          puts "Adding Recommendable initializer (config/initializers/recommendable.rb)"
          template "initializer.rb", path
        end
      end
      
      def run_migrations
        unless options["no-migrate"]
          puts "Running rake db:migrate"
          `rake db:migrate`
        end
      end
      
      def finished
        puts "Done! Recommendable has been successfully installed. Please configure it in config/intializers/recommendable.rb"
      end
      
      private
      
      def user_class
        @user_class.to_sym || :user
      end
      
      def redis_host
        @redis_host || "127.0.0.1"
      end
      
      def redis_port
        @redis_port || 6379
      end
      
      def redis_socket
        @redis_socket || "/tmp/redis.sock"
      end
    end
  end
end