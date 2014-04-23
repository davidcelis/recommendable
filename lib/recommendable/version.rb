module Recommendable
  class Version
    MAJOR = 2
    MINOR = 1
    PATCH = 4

    def self.to_s
      [MAJOR, MINOR, PATCH].join('.')
    end
  end

  VERSION = Version.to_s.freeze
end
