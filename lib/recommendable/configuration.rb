module Recommendable
  class Configuration
    # False if you want to kee
    attr_accessor :redis
    attr_accessor :expire_keys_in
    attr_accessor :auto_enqueue
    attr_accessor :queue_name
  end

  class << self
    def configure
      yield configuration
    end

    def configuration
      @configuration ||= Configuration.new
    end
  end
end
