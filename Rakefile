# encoing: utf-8

##### Requirements

# Rake etc
require 'rake'
require 'minitest/unit'

# Cri itself
$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + '/lib'))
require 'cri'

##### Documentation

require 'yard'

YARD::Rake::YardocTask.new(:doc) do |yard|
  yard.files   = Dir['lib/**/*.rb']
  yard.options = [
    '--markup',        'markdown',
    '--readme',        'README.md',
    '--files',         'NEWS.md,LICENSE',
    '--output-dir',    'doc/yardoc',
  ]
end

##### Testing

desc 'Runs all tests'
task :test do
  ENV['QUIET'] ||= 'true'

  $LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__)))

  MiniTest::Unit.autorun

  require 'test/helper.rb'

  test_files = Dir['test/test_*.rb']
  test_files.each { |f| require f }
end

task :default => :test
