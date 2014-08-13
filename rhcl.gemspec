# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rhcl/version'

Gem::Specification.new do |spec|
  spec.name          = 'rhcl'
  spec.version       = Rhcl::VERSION
  spec.authors       = ['Genki Sugawara']
  spec.email         = ['sgwr_dts@yahoo.co.jp']
  spec.summary       = %q{Pure Ruby HCL parser}
  spec.description   = %q{Pure Ruby HCL parser}
  spec.homepage      = 'https://github.com/winebarrel/rhcl'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'deep_merge'
  spec.add_development_dependency 'bundler', '~> 1.5'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'racc'
  spec.add_development_dependency 'rspec', '>= 3.0.0'
end
