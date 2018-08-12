# frozen_string_literal: true

$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib')
require 'cri'

command = Cri::Command.define do
  name        'sync'
  usage       '[options] source target'
  summary     'syncronises two locations'
  description 'bla bla'

  flag :v, :verbose, 'be verbose'
  param :source
  param :target

  run do |opts, args|
    puts 'Executing!'
    p(opts: opts, args: args)
  end
end

puts command.help
command.run(ARGV)
