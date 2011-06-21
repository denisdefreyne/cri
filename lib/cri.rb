# encoding: utf-8

module Cri

  # @todo Document
  class Error < ::StandardError
  end

  # @todo Document
  class NotImplementedError < Error
  end

  # @todo Document
  class NoHelpAvailableError < Error
  end

  # The current Cri version.
  VERSION = '2.0a3'

  autoload 'Command',           'cri/command'
  autoload 'CommandDSL',        'cri/command_dsl'
  autoload 'OptionParser',      'cri/option_parser'

end

require 'set'

require 'cri/core_ext'
