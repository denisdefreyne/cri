# encoding: utf-8

name        'help'
usage       'help [command_name]'
summary     'show help'
description <<-EOS
Show help for the given command, or show general help. When no command is
given, a list of available commands is displayed, as well as a list of global
commandline options. When a command is given, a command description as well as
command-specific commandline options are shown.
EOS

run do |opts, args|
  if args.empty?
    puts self.supercommand.help
  elsif args.size == 1
    puts self.supercommand.command_named(args[0]).help
  else
    $stderr.puts self.usage
    exit 1
  end
end
