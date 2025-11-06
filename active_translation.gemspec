require_relative "lib/active_translation/version"

Gem::Specification.new do |spec|
  spec.name        = "active_translation"
  spec.version     = ActiveTranslation::VERSION
  spec.authors     = [ "Sean Hogge" ]
  spec.email       = [ "sean@seanhogge.com" ]
  spec.homepage    = "https://github.com/seanhogge/active_translation"
  spec.summary     = "Easily translate specific attributes of any ActiveRecord model"
  spec.description = "Easily translate specific attributes of any ActiveRecord model"
  spec.license     = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/seanhogge/active_translation"
  spec.metadata["changelog_uri"] = "https://github.com/seanhogge/active_translation"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.required_ruby_version = ">= 3.3"

  spec.add_dependency "rails", ">= 7.0", "< 9"
  spec.add_dependency "activerecord", ">= 7.0", "< 9"
  spec.add_dependency "faraday", "~> 2.0", ">= 2.7.0"
  spec.add_dependency "googleauth", "~> 1.0", ">= 1.4.0"
end
