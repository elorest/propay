# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'propay/version'

Gem::Specification.new do |spec|
  spec.name          = "propay"
  spec.version       = Propay::VERSION
  spec.authors       = ["Isaac Sloan"]
  spec.email         = ["isaac@isaacsloan.com"]
  spec.homepage    = "http://rubygems.org/gems/propay"
  spec.license       = "MIT"
  spec.summary     = %q{propay}
  spec.description = %q{propay}
  spec.add_dependency 'typhoeus'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  
  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
end
