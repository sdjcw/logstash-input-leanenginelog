Gem::Specification.new do |s|

  s.name            = 'logstash-input-file'
  s.version         = '1.0.2.1'
  s.licenses        = ['Apache License (2.0)']
  s.summary         = "Stream events from LeanEngine logs."
  s.description     = "This gem is a logstash plugin required to be installed on top of the Logstash core pipeline using $LS_HOME/bin/plugin install gemname. This gem is not a stand-alone program"
  s.authors         = ["wchen"]
  s.email           = 'wchen@leancloud.rocks'
  s.homepage        = "http://leancloud.cn"
  s.require_paths = ["lib"]

  # Files
  s.files = `git ls-files`.split($\)+::Dir.glob('vendor/*')

  # Tests
  s.test_files = s.files.grep(%r{^(test|spec|features)/})

  # Special flag to let us know this is actually a logstash plugin
  s.metadata = { "logstash_plugin" => "true", "logstash_group" => "input" }

  # Gem dependencies
  s.add_runtime_dependency "logstash-core", '>= 1.4.0', '< 2.0.0.alpha0'

  s.add_runtime_dependency 'logstash-codec-plain'
  s.add_runtime_dependency 'addressable'
  s.add_runtime_dependency 'filewatch', ['>= 0.6.7', '~> 0.6']

  s.add_development_dependency 'stud', ['~> 0.0.19']
  s.add_development_dependency 'logstash-devutils', '= 0.0.15'
  s.add_development_dependency 'logstash-codec-json'
end

