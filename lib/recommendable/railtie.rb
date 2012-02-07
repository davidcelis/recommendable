module Recommendable
  class Railtie < Rails::Railtie
    ActiveRecord::Base.send :include, Recommendable::ActsAsRecommendedTo
    ActiveRecord::Base.send :include, Recommendable::ActsAsRecommendable

    # Force load models if in a non-development environment and not caching classes
    config.after_initialize do |app|
      force_load_models if !Rails.env.development? && !app.config.cache_classes
    end

    def self.force_load_models
      Dir["#{ Rails.root }/app/models/**/*.rb"].each { |m| load m }
    end
  end
end
