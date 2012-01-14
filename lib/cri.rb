# encoding: utf-8

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

  # The current Cri version.
  VERSION = '2.1.0'

  autoload 'Command',           'cri/command'
  autoload 'CommandDSL',        'cri/command_dsl'
  autoload 'CommandRunner',     'cri/command_runner'
  autoload 'OptionParser',      'cri/option_parser'

end

require 'set'

require 'cri/core_ext'
