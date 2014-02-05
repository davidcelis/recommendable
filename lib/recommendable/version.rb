module Recommendable
  class Version
    MAJOR = 3
    MINOR = 0
    PATCH = 0

    def self.to_s
      [MAJOR, MINOR, PATCH].join('.')
    end
  end

  VERSION = Version.to_s.freeze
end
