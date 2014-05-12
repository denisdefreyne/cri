# encoding: utf-8

require 'cri/version'

# The namespace for Cri, a library for building easy-to-use commandline tools
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

  autoload 'Command',           'cri/command'
  autoload 'CommandDSL',        'cri/command_dsl'
  autoload 'CommandRunner',     'cri/command_runner'
  autoload 'HelpRenderer',      'cri/help_renderer'
  autoload 'OptionParser',      'cri/option_parser'

  # @return [Boolean] true if the current platform is Windows, false otherwise.
  def self.on_windows?
    !!(RUBY_PLATFORM =~ /windows|bccwin|cygwin|djgpp|mingw|mswin|wince/i)
  end

  # Checks whether colors can be enabled. For colors to be enabled, the given
  # IO should be a TTY, and, when on Windows, ::Win32::Console::ANSI needs to be
  # defined.
  #
  # @return [Boolean] True if colors should be enabled, false otherwise.
  def self.enable_colors?(io)
    if !io.tty?
      false
    elsif on_windows?
      defined?(::Win32::Console::ANSI)
    else
      true
    end
  end

end

require 'set'

require 'cri/core_ext'
require 'cri/argument_array'
