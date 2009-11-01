##### Requirements

# Rake etc
require 'rake'
require 'minitest/unit'

# Cri itself
$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + '/lib'))
require 'cri'

##### Packaging

begin
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name        = "cri"
    s.summary     = "Cri is a library for building easy-to-use commandline tools."
    s.description = "Cri is a library for building easy-to-use commandline tools."

    s.authors     = [ 'Denis Defreyne' ]
    s.email       = "denis.defreyne@stoneship.org"

    s.files       = FileList['[A-Z]*', 'lib/**/*']
  end
rescue LoadError
  warn "Jeweler (or a dependency) is not available. Install it with `gem install jeweler`"
end

##### Testing

desc 'Runs all tests'
task :test do
  ENV['QUIET'] ||= 'true'

  $LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + '/..'))

  MiniTest::Unit.autorun

  test_files = Dir['test/test_*.rb']
  test_files.each { |f| require f }
end

task :default => :test
