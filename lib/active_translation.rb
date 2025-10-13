require "active_translation/version"
require "active_translation/engine"
require "active_translation/configuration"
require "active_translation/translatable"
require "active_translation/translation_job"
require "faraday"
require "googleauth"

module ActiveTranslation
  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end
  end
end
