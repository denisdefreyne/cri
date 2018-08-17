# frozen_string_literal: true

$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib')
require 'cri'

cmd = Cri::Command.new_basic_root.modify do
  name        'nanoc'
  usage       'nanoc [options] [command] [options]'
  summary     'manages and builds static web sites'
  description 'nanoc is a tool for building static sites.'
end

cmd.define_command do
  name        'compile'
  usage       'compile [options]'
  summary     'compiles a web site'
  description 'This loads all data, compiles it and writes it to the disk.'
  no_params

  run do |_opts, _args|
    puts 'Compiling…'
    sleep 1
    puts 'Done.'
  end
end

cmd.run(ARGV)
