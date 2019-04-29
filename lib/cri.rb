# frozen_string_literal: true

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

require_relative 'cri/version'
require_relative 'cri/argument_list'
require_relative 'cri/command'
require_relative 'cri/string_formatter'
require_relative 'cri/command_dsl'
require_relative 'cri/command_runner'
require_relative 'cri/help_renderer'
require_relative 'cri/option_definition'
require_relative 'cri/parser'
require_relative 'cri/param_definition'
require_relative 'cri/platform'
