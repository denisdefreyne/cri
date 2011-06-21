# encoding: utf-8

class Cri::BasicHelpTestCase < Cri::TestCase

  def test_run_without_supercommand
    cmd = Cri::Command.new_basic_help

    assert_raises Cri::NoHelpAvailableError do
      cmd.run([])
    end
  end

  def test_run_with_supercommand
    cmd = Cri::Command.define do
      name 'meh'
    end

    help_cmd = Cri::Command.new_basic_help
    cmd.add_command(help_cmd)

    help_cmd.run([])
  end

end
