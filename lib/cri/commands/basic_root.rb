# encoding: utf-8

option :h, :help, 'show help for this command' do |value, cmd|
  puts cmd.help
  exit 0
end
