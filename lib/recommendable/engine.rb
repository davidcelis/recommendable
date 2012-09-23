module Recommendable
  class Engine < ::Rails::Engine
    isolate_namespace Recommendable
    engine_name "recommendable"

    class << self
      attr_accessor :root

      def root
        @root ||= Pathname.new File.expand_path('../../', __FILE__)
      end
    end
  end
end
