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

flag :v, :verbose, 'show more detailed help'
flag :c, :nocolor, 'disable color in the help output'

run do |opts, args, cmd|
  if cmd.supercommand.nil?
    raise NoHelpAvailableError,
      "No help available because the help command has no supercommand"
  end

  is_verbose = opts.fetch(:verbose, false)
  is_color   = ! opts.fetch(:nocolor, false)

  if args.empty?
    puts cmd.supercommand.help(:verbose => is_verbose, :color => is_color)
  elsif args.size == 1
    puts cmd.supercommand.command_named(args[0]).help(:verbose => is_verbose, :color => is_color)
  else
    $stderr.puts cmd.usage
    exit 1
  end
end
