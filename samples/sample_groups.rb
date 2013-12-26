# encoding: utf-8

$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib')
require 'cri'

# Some example symbolic names for revisions. These would come from git in real
# life, but this is only example.
$REVISIONS = %w(
  HEAD
  master
  v1.0
  release/1.0.x
  0f1e2d3c
)

class SampleGroupsRunner < Cri::CommandRunner

  def run
    unless [ 1, 2 ].include?(argument_groups.size)
      $stderr.puts "Expected 1 or 2 argument groups, not #{argument_groups.size}"
      exit 1
    end

    unless categorised_ambiguous_arguments[:unknown].empty?
      $stderr.puts 'Found arguments that are neither files nor revisions: ' +
                   categorised_ambiguous_arguments[:unknown].join(', ')
      exit 1
    end

    unless categorised_ambiguous_arguments[:ambiguous].empty?
      $stderr.puts 'Found arguments that are both files and revisions: ' +
                   categorised_ambiguous_arguments[:ambiguous].join(', ')
      exit 1
    end

    files     = definitely_files     + categorised_ambiguous_arguments[:files]
    revisions = definitely_revisions + categorised_ambiguous_arguments[:revisions]

    if revisions.size > 1
      $stderr.puts "Expected 0 or 1 revisions, got #{revisions.size}"
      exit 1
    end
    revision = revisions[0]

    if files.empty?
      puts "Checking out all files (revision #{revision})"
    else
      files.each do |file|
        puts "Checking out file #{file} (revision #{revision})"
      end
    end
  end

  private

  def definitely_revisions
    @_definitely_revisions ||=
      (argument_groups.size == 2 ? argument_groups[0] : [])
  end

  def definitely_files
    @_definitely_files ||=
      (argument_groups.size == 2 ? argument_groups[1] : [])
  end

  def ambiguous_arguments
    @_ambiguous_arguments ||=
      (argument_groups.size == 1 ? arguments : [])
  end

  def categorised_ambiguous_arguments
    @_categorised_ambiguous_arguments ||= begin
      memo = {
        :ambiguous => [],
        :files     => [],
        :revisions => [],
        :unknown   => [],
      }

      ambiguous_arguments.each do |arg|
        if possible_file?(arg)
          if possible_revision?(arg)
            memo[:ambiguous] << arg
          else
            memo[:files] << arg
          end
        else
          if possible_revision?(arg)
            memo[:revisions] << arg
          else
            memo[:unknown] << arg
          end
        end
      end

      memo
    end
  end

  def possible_file?(f)
    File.file?(f)
  end

  def possible_revision?(r)
    $REVISIONS.include?(r)
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

command.run(ARGV)
