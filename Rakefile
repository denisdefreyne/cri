##### Requirements

# Rake etc
require 'rake'
require 'minitest/unit'

# Cri itself
$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + '/lib'))
require 'cri'

##### Testing

desc 'Runs all tests'
task :test do
  ENV['QUIET'] ||= 'true'

  $LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__)))

  MiniTest::Unit.autorun

  test_files = Dir['test/test_*.rb']
  test_files.each { |f| require f }
end

task :default => :test
