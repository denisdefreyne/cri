# encoding: utf-8

$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib')
require 'cri'

command = Cri::Command.define do
  name        'moo'
  usage       'usage: moo [options]'
  summary     'does stuff'
  description <<-EOS
This command does a lot of stuff. I really mean a lot. Well actually I am
lying. It doesn’t do that much. In fact, it barely does anything. It’s merely
a sample command to show off Cri!
EOS

  option    :a, :aaa, 'opt a', :argument => :optional
  required  :b, :bbb, 'opt b'
  optional  :c, :ccc, 'opt c'
  flag      :d, :ddd, 'opt d'
  forbidden :e, :eee, 'opt e'

  run do |opts, args|
    puts "Executing!"
    p({ :opts => opts, :args => args })
  end
end

puts command.help
command.run(ARGV)
