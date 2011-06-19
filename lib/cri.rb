# encoding: utf-8

module Cri

  # The current Cri version.
  VERSION = '1.1'

  autoload 'Base',              'cri/base'
  autoload 'Command',           'cri/command'
  autoload 'CommandDSL',        'cri/command_dsl'
  autoload 'OptionParser',      'cri/option_parser'

end

require 'set'

require 'cri/core_ext'
