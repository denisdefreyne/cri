# frozen_string_literal: true

require 'helper'

module Cri
  class HelpRendererTestCase < Cri::TestCase
    # NOTE: Additional test cases are in test_command.rb

    def help_for(cmd)
      io = StringIO.new
      Cri::HelpRenderer.new(cmd, io: io).render
    end

    def test_simple
      expected = <<~HELP
        NAME
            help - show help

        USAGE
            help [command_name]

        DESCRIPTION
            Show help for the given command, or show general help. When no command is
            given, a list of available commands is displayed, as well as a list of
            global command-line options. When a command is given, a command
            description, as well as command-specific command-line options, are shown.

        OPTIONS
            -v --verbose      show more detailed help
      HELP

      cmd = Cri::Command.new_basic_help
      assert_equal(expected, help_for(cmd))
    end

    def test_with_defaults
      cmd = Cri::Command.define do
        name 'build'
        optional nil, :'with-animal', 'Add animal', default: 'giraffe'
      end

      help = help_for(cmd)

      assert_match(/^       --with-animal\[=<value>\]      Add animal \(default: giraffe\)$/, help)
    end

    def test_with_summary
      cmd = Cri::Command.define do
        name 'build'
        summary 'do some buildage'

        optional nil, :'with-animal', 'Add animal', default: 'giraffe'
      end

      help = help_for(cmd)

      assert_match(/^NAME\n    build - do some buildage\n$/, help)
    end

    def test_without_summary
      cmd = Cri::Command.define do
        name 'build'

        optional nil, :'with-animal', 'Add animal', default: 'giraffe'
      end

      help = help_for(cmd)

      assert_match(/^NAME\n    build\n$/, help)
    end
  end
end
