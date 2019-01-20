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
require 'zeitwerk'

inflector_class = Class.new(Zeitwerk::Inflector) do
  def camelize(basename, _abspath)
    case basename
    when 'command_dsl'
      'CommandDSL'
    else
      super
    end
  end
end

loader = Zeitwerk::Loader.for_gem
loader.inflector = inflector_class.new
loader.setup
