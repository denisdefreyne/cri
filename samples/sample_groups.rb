# encoding: utf-8

$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib')
require 'cri'

class SampleGroupsRunner < Cri::CommandRunner

  def run
    if files.empty?
      puts "Checking out all files (revision #{revision})"
    else
      files.each do |file|
        puts "Checking out file #{file} (revision #{revision})"
      end
    end
  end

  private

  def files
    if argument_groups.size == 2
      argument_groups[1]
    else
      arguments.select do |a|
        File.file?(a)
      end
    end
  end

  def revision
    if argument_groups.size == 2
      potential_revisions = argument_groups[0]
    else
      potential_revisions = arguments.select do |a|
        !File.file?(a)
      end
    end

    if potential_revisions.size > 1
      $stderr.puts "Expected 0 or 1 revisions, got #{potential_revisions.size}"
      exit 1
    end

    potential_revisions[0] || 'HEAD'
  end

end

command = Cri::Command.define do
  name        'checkout'
  usage       'usage: checkout [<revision>] -- [<file>]'
  summary     'pretends to be git checkout'
  description <<-EOS
Demonstrates the usage of argument groups to disambiguate between positional
arguments.
EOS

  runner SampleGroupsRunner
end

# checkout foo
# checkout foo --
# checkout -- foo
# checkout foo bar
# checkout foo -- bar
command.run(ARGV)
