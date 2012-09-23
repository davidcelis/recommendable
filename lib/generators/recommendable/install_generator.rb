require 'rails/generators'

module Recommendable
  module Generators
    class InstallGenerator < Rails::Generators::Base
      argument     :redis_host,   :type => :string,  :default => "localhost",       :desc => "The hostname your redis server is running on."
      argument     :redis_port,   :type => :string,  :default => "6379",            :desc => "The port your redis server is running on."
      class_option :redis_socket, :type => :string,                                 :desc => "Indicates the UNIX socket your redis server is running on (if it is)."
      class_option :no_migrate,   :type => :boolean, :default => false,             :desc => "Skip migrations. The Like and Dislike tables will not be created."

      source_root File.expand_path("../templates", __FILE__)

      def add_recommendable_initializer
        path = "#{Rails.root}/config/initializers/recommendable.rb"
        if File.exists?(path)
          puts "Skipping config/initializers/recommendable.rb creation; file already exists!"
        else
          puts "Adding Recommendable initializer (config/initializers/recommendable.rb)"
          template "initializer.rb", path
        end
      end

      def install_migrations
        puts "Copying migrations..."
        Dir.chdir(Rails.root) { puts `rake recommendable:install:migrations` }
      end

      def run_migrations
        unless options[:no_migrate]
          puts "Running rake db:migrate"
          puts `rake db:migrate`
        end
      end

      def finished
        puts "Done! Recommendable has been successfully installed. Please configure it in config/intializers/recommendable.rb"
      end
    end
  end
end
