# frozen_string_literal: true

$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib')
require 'cri'

command = Cri::Command.define do
  name        'moo'
  usage       'usage: moo [options]'
  summary     'does stuff'
  description <<~DESC
    This command does a lot of stuff. I really mean a lot. Well actually I am
    lying. It doesn’t do that much. In fact, it barely does anything. It’s merely
    a sample command to show off Cri!
  DESC

  option    :a,  :aaa,   'opt a', argument: :optional
  required  :b,  :bbb,   'opt b'
  optional  :c,  :ccc,   'opt c'
  flag      :d,  :ddd,   'opt d'
  forbidden :e,  :eee,   'opt e'
  flag      :f,  :fff,   'opt f', hidden: true
  flag      :g,  :ggg,   'this is an option with a very long description that should reflow nicely'
  flag      :s,  nil,    'option with only a short form'
  flag      nil, 'long', 'option with only a long form'
  optional  :i,  :iii,   'opt i', default: 'donkey'

  run do |opts, args|
    puts 'Executing!'
    p(opts: opts, args: args)
  end
end

puts command.help
command.run(ARGV)
