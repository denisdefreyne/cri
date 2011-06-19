# encoding: utf-8

option :h, :help, 'show help for this command' do |value|
  puts self.help
  exit 0
end

subcommand Cri::Command.new_basic_help
