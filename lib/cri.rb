require 'cri/version'

# The namespace for Cri, a library for building easy-to-use command-line tools
# with support for nested commands.
module Cri
  # A generic error class for all Cri-specific errors.
  class Error < ::StandardError
  end

  # Error that will be raised when an implementation for a method or command
  # is missing. For commands, this may mean that a run block is missing.
  class NotImplementedError < Error
  end

  # Error that will be raised when no help is available because the help
  # command has no supercommand for which to show help.
  class NoHelpAvailableError < Error
  end
end

require 'set'

require 'cri/core_ext'
require 'cri/argument_array'
require 'cri/command'
require 'cri/string_formatter'
require 'cri/command_dsl'
require 'cri/command_runner'
require 'cri/help_renderer'
require 'cri/option_parser'
require 'cri/platform'
