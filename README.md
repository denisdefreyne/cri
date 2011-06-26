Cri
===

Cri is a library for building easy-to-use commandline tools with support for
nested commands.

Usage
-----

The central concept in Cri is the _command_, which has option definitions as
well as code for actually executing itself. In Cri, the commandline tool
itself is a command as well.

Here’s a sample command definition:

	command = Cri::Command.define do
	  name        'dostuff'
	  usage       'dostuff [options]'
	  summary     'does stuff'
	  description 'This command does a lot of stuff. I really mean a lot.'

	  flag   :h, :help,  'show help for this command' do |value, cmd|
	    puts cmd.help
	    exit 0
	  end
	  flag   :m, :more,  'do even more stuff'
	  option :s, :stuff, 'specify stuff to do', :argument => :required

	  run do |opts, args, cmd|
	    stuff = opts[:stuff] || 'generic stuff'
	    puts "Doing #{stuff}!"

	    if opts[:more]
	      puts 'Doing it even more!'
	    end
	  end
	end

To run this command, invoke the `#run` method with the raw arguments. For
example, for a root command (the commandline tool itself), the command could
be called like this:

	command.run(ARGS)

Each command has automatically generated help. This help can be printed using
{Cri::Command#help}; something like this will be shown:

	usage: dostuff [options]

	does stuff

	    This command does a lot of stuff. I really mean a lot.

	options:

	    -h --help      show help for this command
	    -m --more      do even more stuff
	    -s --stuff     specify stuff to do

Let’s disect the command definition and start with the first four lines:

	name        'dostuff'
	usage       'dostuff [options]'
	summary     'does stuff'
	description 'This command does a lot of stuff. I really mean a lot.'

The first four lines of the command definition specify the name of the command
(or the commandline tool, if the command is the root command), the usage, a
one-line summary and a (long) description. The usage should not include a
“usage:” prefix nor the name of the supercommand, because the latter will be
automatically prepended.

The next few lines contain the command’s option definitions:

	flag   :h, :help,  'show help for this command' do |value, cmd|
	  puts cmd.help
	  exit 0
	end
	flag   :m, :more,  'do even more stuff'
	option :s, :stuff, 'specify stuff to do', :argument => :required

Options can be defined using the following methods:

* {Cri::CommandDSL#option} or * {Cri::CommandDSL#opt}
* {Cri::CommandDSL#flag} (implies forbidden argument)
* {Cri::CommandDSL#required} (implies required argument)
* {Cri::CommandDSL#optional} (implies optional argument)

Each of the above methods also take a block, which will be executed when the
option is found. The argument to the block are the option value (`true` in
case the option does not have an argument) and the command.

The last part of the command defines the execution itself:

	run do |opts, args, cmd|
	  stuff = opts[:stuff] || 'generic stuff'
	  puts "Doing #{stuff}!"

	  if opts[:more]
	    puts 'Doing it even more!'
	  end
	end

The {Cri::CommandDSL#run} method takes a block with the actual code to
execute. This block takes three arguments: the options, any arguments passed
to the command, and the command itself.

Contributors
------------

(In alphabetical order)

* Toon Willems

Thanks for Lee “injekt” Jarvis for [Slop][1], which has inspired the design of Cri 2.0.

[1]: https://github.com/injekt/slop
