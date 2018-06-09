# frozen_string_literal: true

$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib')
require 'cri'

super_cmd = Cri::Command.define do
  name        'super'
  usage       'does something super'
  summary     'does super stuff'
  description 'This command does super stuff.'

  option    :a, :aaa, 'opt a', argument: :optional
  required  :b, :bbb, 'opt b'
  flag      :d, :ddd, 'opt d'
  optional  :c, :ccc, 'opt c'
  forbidden :e, :eee, 'opt e'
end

super_cmd.define_command do
  name        'sub'
  usage       'does something subby'
  summary     'does subby stuff'
  description 'This command does subby stuff.'
  skip_option_parsing

  run do |opts, args|
    $stdout.puts 'in subcommand'

    $stdout.puts "arguments: #{args.inspect}"
    $stdout.puts "options:   #{opts.inspect}"
  end
end

super_cmd.add_command Cri::Command.new_basic_help

super_cmd.run(ARGV)
