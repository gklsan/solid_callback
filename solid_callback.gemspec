# frozen_string_literal: true

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require_relative "lib/solid_callback/version"

Gem::Specification.new do |spec|
  spec.name = "solid_callback"
  spec.version = SolidCallback::VERSION
  spec.authors = ["Gokul (gklsan)"]
  spec.email = ["pgokulmca@gmail.com"]

  spec.summary = "SolidCallback adds powerful method interception capabilities to your Ruby classes with near-zero overhead. Clean, flexible, and unobtrusive."
  spec.description = "SolidCallback adds powerful method interception capabilities to your Ruby classes with near-zero overhead. Clean, flexible, and unobtrusive."
  spec.homepage = "https://github.com/gklsan/solid_callback"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.3.0"

  spec.metadata = {
    'source_code_uri' => "https://github.com/gklsan/solid_callback",
    'changelog_uri' => "https://github.com/gklsan/solid_callback/releases",
    'bug_tracker_uri' => "https://github.com/gklsan/solid_callback/issues",
    'documentation_uri'  => "https://rubydoc.info/github/gklsan/solid_callback"
  }

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "yard", "~> 0.9"

  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html
end
