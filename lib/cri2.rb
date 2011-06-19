# encoding: utf-8

module Cri2

  # The current Cri version.
  VERSION = '2.0a1'

  autoload 'Command',           'cri2/command'
  autoload 'CommandDSL',        'cri2/command_dsl'
  autoload 'OptionParser',      'cri2/option_parser'

end

require 'set'

require 'cri2/core_ext'
