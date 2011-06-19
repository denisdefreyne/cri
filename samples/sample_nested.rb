# encoding: utf-8

$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib')
require 'cri'

super_cmd = Cri::Command.define do
  name        'super'
  usage       'does something super'
  summary     'does super stuff'
  description 'This command does super stuff.'

  option    :a, :aaa, 'opt a', :argument => :optional
  required  :b, :bbb, 'opt b'
  optional  :c, :ccc, 'opt c'
  flag      :d, :ddd, 'opt d'
  forbidden :e, :eee, 'opt e'
end

super_cmd.define_command do
  name        'sub'
  usage       'does something subby'
  summary     'does subby stuff'
  description 'This command does subby stuff.'

  option    :m, :mmm, 'opt m', :argument => :optional
  required  :n, :nnn, 'opt n'
  optional  :o, :ooo, 'opt o'
  flag      :p, :ppp, 'opt p'
  forbidden :q, :qqq, 'opt q'

  run do |opts, args|
    $stdout.puts "Sub-awesome!"

    $stdout.puts args.join(',')

    opts_strings = []
    opts.each_pair { |k,v| opts_strings << "#{k}=#{v}" }
    $stdout.puts opts_strings.join(',')
  end
end

puts super_cmd.help
super_cmd.run(ARGV)
