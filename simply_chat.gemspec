# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'simply_chat/version'

Gem::Specification.new do |spec|
  spec.name          = "simply_chat"
  spec.version       = SimplyChat::VERSION
  spec.authors       = ["Tyler Lichten"]
  spec.email         = ["tlich10@gmail.com"]

  spec.summary       = %q{Builds a simple chatroom for users to chat.}
  spec.description   = %q{Builds a simple chatroom for users to chat.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "thor"
  spec.add_runtime_dependency "actioncable", github: "rails/actioncable"
  spec.add_runtime_dependency "puma"
  spec.add_runtime_dependency "sprockets", ">=3.0.0.beta"
  spec.add_runtime_dependency "sprockets-es6"

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "generator_spec"
end
