# encoing: utf-8

require 'rake/testtask'
require 'rubocop/rake_task'
require 'yard'

YARD::Rake::YardocTask.new(:doc) do |yard|
  yard.files   = Dir['lib/**/*.rb']
  yard.options = [
    '--markup',        'markdown',
    '--readme',        'README.adoc',
    '--files',         'NEWS.md,LICENSE',
    '--output-dir',    'doc/yardoc'
  ]
end

Rake::TestTask.new(:test_unit) do |t|
  t.test_files = Dir['test/**/*_spec.rb'] + Dir['test/**/test_*.rb']
  t.libs << 'test'
end

RuboCop::RakeTask.new(:test_style) do |task|
  task.options = %w[--display-cop-names --format simple]
end

task test: %i[test_unit test_style]

task default: :test
