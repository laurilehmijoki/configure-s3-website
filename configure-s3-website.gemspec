require File.join([File.dirname(__FILE__),'lib','configure-s3-website','version.rb'])
spec = Gem::Specification.new do |s|
  s.name = 'configure-s3-website'
  s.version = ConfigureS3Website::VERSION
  s.author = 'Lauri Lehmijoki'
  s.email = 'lauri.lehmijoki@iki.fi'
  s.homepage = 'https://github.com/laurilehmijoki/configure-s3-website'
  s.platform = Gem::Platform::RUBY
  s.summary = 'Configure your AWS S3 bucket to function as a web site'
  s.bindir = 'bin'

  s.add_dependency 'deep_merge', '~> 1.0.0'
  s.add_dependency 'aws-sdk', '~> 2'

  s.add_development_dependency 'rspec', '~> 3'
  s.add_development_dependency 'rspec-expectations', '~> 3'
  s.add_development_dependency 'rake', '~> 0.9.0'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {spec}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
