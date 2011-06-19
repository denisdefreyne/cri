module Cri

  # The current Cri version.
  VERSION = '1.1'

  autoload 'Base',              'cri/base'
  autoload 'Command',           'cri/command'
  autoload 'OptionParser',      'cri/option_parser'

end

require 'cri/core_ext'
