module Recommendable
  class Version
    MAJOR = 2
    MINOR = 2
    PATCH = 2

    def self.to_s
      [MAJOR, MINOR, PATCH].join('.')
    end
  end

  VERSION = Version.to_s.freeze
end
