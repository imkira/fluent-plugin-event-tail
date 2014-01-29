# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |gem|
  gem.name          = "fluent-plugin-event-tail"
  gem.version       = "0.0.2"
  gem.authors       = ["Mario Freitas"]
  gem.email         = ["imkira@gmail.com"]
  gem.description   = %q{fluentd input plugin derived from in_tail and inspired by in_forward for reading [tag, time, record] messages from a file}
  gem.summary       = %q{fluentd input plugin for reading [tag, time, record] messages from a file}
  gem.homepage      = "https://github.com/imkira/fluent-plugin-event-tail"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_runtime_dependency "fluentd"
  gem.add_development_dependency "bundler"
  gem.add_development_dependency "rake"
end
