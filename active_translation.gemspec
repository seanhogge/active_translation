require_relative "lib/active_translation/version"

Gem::Specification.new do |spec|
  spec.name        = "active_translation"
  spec.version     = ActiveTranslation::VERSION
  spec.authors     = [ "Sean Hogge" ]
  spec.email       = [ "sean@seanhogge.com" ]
  spec.homepage    = "https://github.com/seanhogge/activetranslation"
  spec.summary     = "Easily translate specific attributes of any ActiveRecord model"
  spec.description = "Easily translate specific attributes of any ActiveRecord model"
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/seanhogge/activetranslation"
  spec.metadata["changelog_uri"] = "https://github.com/seanhogge/activetranslation"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 7"
  spec.add_dependency "activerecord", ">= 7"
  spec.add_dependency "faraday"
  # spec.add_dependency "faraday_middleware"
  spec.add_dependency "googleauth"
end
