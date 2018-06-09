# frozen_string_literal: true

require 'helper'

module Cri
  class BasicRootTestCase < Cri::TestCase
    def test_run_with_help
      cmd = Cri::Command.new_basic_root

      stdout, _stderr = capture_io_while do
        err = assert_raises SystemExit do
          cmd.run(%w[-h])
        end
        assert_equal 0, err.status
      end

      assert stdout =~ /COMMANDS.*\n.*help.*show help/
    end

    def test_run_with_help_no_exit
      cmd = Cri::Command.new_basic_root

      stdout, _stderr = capture_io_while do
        cmd.run(%w[-h], {}, hard_exit: false)
      end

      assert stdout =~ /COMMANDS.*\n.*help.*show help/
    end
  end
end
