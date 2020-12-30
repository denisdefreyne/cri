# Cri

[![Gem](http://img.shields.io/gem/v/cri.svg)](http://rubygems.org/gems/cri)
[![Gem downloads](https://img.shields.io/gem/dt/cri.svg)](http://rubygems.org/gems/cri)
[![Travis](http://img.shields.io/travis/ddfreyne/cri.svg)](https://travis-ci.org/ddfreyne/cri)
[![Coveralls](http://img.shields.io/coveralls/ddfreyne/cri.svg)](https://coveralls.io/r/ddfreyne/cri)
[![Codeclimate](http://img.shields.io/codeclimate/github/ddfreyne/cri.svg)](https://codeclimate.com/github/ddfreyne/cri)
[![Inch](http://inch-ci.org/github/ddfreyne/cri.svg)](http://inch-ci.org/github/ddfreyne/cri/)

Cri is a library for building easy-to-use command-line tools with support for
nested commands.

## Requirements

Cri requires Ruby 2.5 or newer (including Ruby 3.x).

## Compatibility policy

Cri is guaranteed to be supported on any [officially supported Ruby version](https://www.ruby-lang.org/en/downloads/branches/), as well as the version of Ruby that comes by default on

- the last two [Ubuntu LTS releases](https://wiki.ubuntu.com/Releases)
- the last two major [macOS releases](https://en.wikipedia.org/wiki/MacOS_version_history)

## Usage

The central concept in Cri is the _command_, which has option definitions as
well as code for actually executing itself. In Cri, the command-line tool
itself is a command as well.

Here’s a sample command definition:

```ruby
command = Cri::Command.define do
  name        'dostuff'
  usage       'dostuff [options]'
  aliases     :ds, :stuff
  summary     'does stuff'
  description 'This command does a lot of stuff. I really mean a lot.'

  flag   :h,  :help,  'show help for this command' do |value, cmd|
    puts cmd.help
    exit 0
  end
  flag   nil, :more,  'do even more stuff'
  option :s,  :stuff, 'specify stuff to do', argument: :required

  run do |opts, args, cmd|
    stuff = opts.fetch(:stuff, 'generic stuff')
    puts "Doing #{stuff}!"

    if opts[:more]
      puts 'Doing it even more!'
    end
  end
end
```

To run this command, invoke the `#run` method with the raw arguments. For
example, for a root command (the command-line tool itself), the command could
be called like this:

```ruby
command.run(ARGV)
```

Each command has automatically generated help. This help can be printed using
`Cri::Command#help`; something like this will be shown:

```
usage: dostuff [options]

does stuff

    This command does a lot of stuff. I really mean a lot.

options:

    -h --help      show help for this command
       --more      do even more stuff
    -s --stuff     specify stuff to do
```

### General command metadata

Let’s disect the command definition and start with the first five lines:

```ruby
name        'dostuff'
usage       'dostuff [options]'
aliases     :ds, :stuff
summary     'does stuff'
description 'This command does a lot of stuff. I really mean a lot.'
```

These lines of the command definition specify the name of the command (or the
command-line tool, if the command is the root command), the usage, a list of
aliases that can be used to call this command, a one-line summary and a (long)
description. The usage should not include a “usage:” prefix nor the name of
the supercommand, because the latter will be automatically prepended.

Aliases don’t make sense for root commands, but for subcommands they do.

### Command-line options

The next few lines contain the command’s option definitions:

```ruby
flag   :h,  :help,  'show help for this command' do |value, cmd|
  puts cmd.help
  exit 0
end
flag   nil, :more,  'do even more stuff'
option :s,  :stuff, 'specify stuff to do', argument: :required
```

The most generic way of definition an option is using either `#option` or `#opt`. It takes the following arguments:

1. a short option name
2. a long option name
3. a description
4. optional extra parameters
   - `argument:` (default: `:forbidden`)
   - `transform:`
   - `default:`
   - `multiple:` (default: `false`)
5. optionally, a block

In more detail:

- The short option name is a symbol containing one character, to be used in single-dash options, e.g. `:f` (corresponds to `-f`). The long option name is a symbol containing a string, to be used in double-dash options, e.g. `:force` (corresponds to `--force`). Either the short or the long option name can be nil, but not both.

- The description is a short, one-line text that shows up in the command’s help. For example, the `-v`/`--version` option might have the description `show version information and quit`.

- The extra parameters, `argument:`, `multiple:`, `default:`, and `transform:`, are described in the sections below.

- The block, if given, will be executed when the option is found. The arguments to the block are the option value (`true` in case the option does not have an argument) and the command.

There are several convenience methods that are alternatives to `#option`/`#opt`:

- `#flag` sets `argument:` to `:forbidden`
- (**deprecated**) `#required` sets `argument:` to `:required` -- deprecated because `#required` suggests that the option is required, wich is incorrect; the _argument_ is required.)
- (**deprecated**) `#optional` sets `argument:` to `:optional` -- deprecated because `#optional` looks too similar to `#option`.

#### Forbidden, required, and optional arguments (`argument:`)

The `:argument` parameter can be set to `:forbidden`, `:required`, or `:optional`.

- `:forbidden` means that when the option is present, the value will be set to `true`, and `false` otherwise. For example:

  ```ruby
  option :f, :force, 'push with force', argument: :forbidden

  run do |opts, args, cmd|
    puts "Force? #{opts[:force]}"
  end
  ```

  ```sh
  % ./push mypackage.zip
  Force? false

  % ./push --force mypackage.zip
  Force? true
  ```

  `:argument` is set to `:forbidden` by default.

- `:required` means that the option must be followed by an argument, which will then be treated as the value for the option. It does not mean that the option itself is required. For example:

  ```ruby
  option :o, :output, 'specify output file', argument: :required
  option :f, :fast, 'fetch faster', argument: :forbidden

  run do |opts, args, cmd|
    puts "Output file: #{opts[:output]}"
  end
  ```

  ```sh
  % ./fetch http://example.com/source.zip
  Output file: nil

  % ./fetch --output example.zip http://example.com/source.zip
  Output file: example.zip

  % ./fetch http://example.com/source.zip --output
  fetch: option requires an argument -- output

  % ./fetch --output --fast http://example.com/source.zip
  fetch: option requires an argument -- output
  ```

- `:optional` means that the option can be followed by an argument. If it is, then the argument is treated as the value for the option; if it isn’t, the value for the option will be `true`. For example:

  ```ruby
  option :o, :output, 'specify output file', argument: :optional
  option :f, :fast, 'fetch faster', argument: :forbidden

  run do |opts, args, cmd|
    puts "Output file: #{opts[:output]}"
  end
  ```

  ```sh
  % ./fetch http://example.com/source.zip
  Output file: nil

  % ./fetch --output example.zip http://example.com/source.zip
  Output file: example.zip

  % ./fetch http://example.com/source.zip --output
  Output file: true

  % ./fetch --output --fast http://example.com/source.zip
  Output file: true
  ```

#### Transforming options (`transform:`)

The `:transform` parameter specifies how the value should be transformed. It takes any object that responds to `#call`:

```ruby
option :p, :port, 'set port', argument: :required,
  transform: -> (x) { Integer(x) }
```

The following example uses `#Integer` to transform a string into an integer:

```ruby
option :p, :port, 'set port', argument: :required, transform: method(:Integer)
```

The following example uses a custom object to perform transformation, as well as validation:

```ruby
class PortTransformer
  def call(str)
    raise ArgumentError unless str.is_a?(String)
    Integer(str).tap do |int|
      raise unless (0x0001..0xffff).include?(int)
    end
  end
end

option :p, :port, 'set port', argument: :required, transform: PortTransformer.new
```

Default values are not transformed:

```ruby
option :p, :port, 'set port', argument: :required, default: 8080, transform: PortTransformer.new
```

#### Options with default values (`default:`)

The `:default` parameter sets the option value that will be used if the option is passed without an argument or isn't passed at all:

```ruby
option :a, :animal, 'add animal', default: 'giraffe', argument: :optional
```

In the example above, the value for the `--animal` option will be the string
`"giraffe"`, unless otherwise specified:

```
OPTIONS
    -a --animal[=<value>]      add animal (default: giraffe)
```

If the option is not given on the command line, the `options` hash will not have key for this option, but will still have a default value:

```ruby
option :a, :animal, 'add animal', default: 'giraffe', argument: :required

run do |opts, args, cmd|
  puts "Animal = #{opts[:animal]}"
  puts "Option given? #{opts.key?(:animal)}"
end
```

```sh
% ./run --animal=donkey
Animal = donkey
Option given? true

% ./run --animal=giraffe
Animal = giraffe
Option given? true

% ./run
Animal = giraffe
Option given? false
```

This can be useful to distinguish between an explicitly-passed-in value and a default value. In the example above, the `animal` option is set to `giraffe` in the second and third cases, but it is possible to detect whether the value is a default or not.

#### Multivalued options (`multiple:`)

The `:multiple` parameter allows an option to be specified more than once on the command line. When set to `true`, multiple option valus are accepted, and the option values will be stored in an array.

For example, to parse the command line options string `-o foo.txt -o bar.txt`
into an array, so that `options[:output]` contains `[ 'foo.txt', 'bar.txt' ]`,
you can use an option definition like this:

```ruby
option :o, :output, 'specify output paths', argument: :required, multiple: true
```

This can also be used for flags (options without arguments). In this case, the
length of the options array is relevant.

For example, you can allow setting the verbosity level using `-v -v -v`. The
value of `options[:verbose].size` would then be the verbosity level (three in
this example). The option definition would then look like this:

```ruby
flag :v, :verbose, 'be verbose (use up to three times)', multiple: true
```

#### Skipping option parsing

If you want to skip option parsing for your command or subcommand, you can add
the `skip_option_parsing` method to your command definition and everything on your
command line after the command name will be passed to your command as arguments.

```ruby
command = Cri::Command.define do
  name        'dostuff'
  usage       'dostuff [args]'
  aliases     :ds, :stuff
  summary     'does stuff'
  description 'This command does a lot of stuff, but not option parsing.'

  skip_option_parsing

  run do |opts, args, cmd|
    puts args.inspect
  end
end
```

When executing this command with `dostuff --some=value -f yes`, the `opts` hash
that is passed to your `run` block will be empty and the `args` array will be
`["--some=value", "-f", "yes"]`.

### Argument parsing

Cri supports parsing arguments, as well as parsing options. To define the
parameters of a command, use `#param`, which takes a symbol containing the name
of the parameter. For example:

```ruby
command = Cri::Command.define do
  name        'publish'
  usage       'publish filename'
  summary     'publishes the given file'
  description 'This command does a lot of stuff, but not option parsing.'

  flag :q, :quick, 'publish quicker'
  param :filename

  run do |opts, args, cmd|
    puts "Publishing #{args[:filename]}…"
  end
end
```

The command in this example has one parameter named `filename`. This means that
the command takes a single argument, named `filename`.

As with options, parameter definitions take `transform:`, which can be used for transforming and validating arguments:

```ruby
param :port, transform: method(:Integer)
```

(_Why the distinction between argument and parameter?_ A parameter is a name, e.g. `filename`, while an argument is a value for a parameter, e.g. `kitten.jpg`.)

### Allowing arbitrary arguments

If no parameters are specified, Cri performs no argument parsing or validation;
any number of arguments is allowed.

```ruby
command = Cri::Command.define do
  name        'publish'
  usage       'publish [filename...]'
  summary     'publishes the given file(s)'
  description 'This command does a lot of stuff, but not option parsing.'

  flag :q, :quick, 'publish quicker'

  run do |opts, args, cmd|
    args.each do |arg|
      puts "Publishing #{arg}…"
    end
  end
end
```

```bash
% my-tool publish foo.zip bar.zip
Publishing foo.zip…
Publishing bar.zip…
%
```

### Forbidding any arguments

To explicitly specify that a command has no parameters, use `#no_params`:

```ruby
name        'reset'
usage       'reset'
summary     'resets the site'
description '…'
no_params

run do |opts, args, cmd|
  puts "Resetting…"
end
```

```
% my-tool reset x
reset: incorrect number of arguments given: expected 0, but got 1
% my-tool reset
Resetting…
%
```

A future version of Cri will likely make `#no_params` the default behavior.

### The run block

The last part of the command defines the execution itself:

```ruby
run do |opts, args, cmd|
  stuff = opts.fetch(:stuff, 'generic stuff')
  puts "Doing #{stuff}!"

  if opts[:more]
    puts 'Doing it even more!'
  end
end
```

The +Cri::CommandDSL#run+ method takes a block with the actual code to
execute. This block takes three arguments: the options, any arguments passed
to the command, and the command itself.

### The command runner

Instead of defining a run block, it is possible to declare a class, the _command runner_ class that will perform the actual execution of the command. This makes it easier to break up large run blocks into manageable pieces.

```ruby
name 'push'
option :f, :force, 'force'
param :filename

class MyRunner < Cri::CommandRunner
  def run
    puts "Pushing #{arguments[:filename]}…"
    puts "… with force!" if options[:force]
  end
end

runner MyRunner
```

To create a command runner, subclass `Cri::CommandRunner`, and define a `#run` method with no params. Inside the `#run` block, you can access `options` and `arguments`. Lastly, to connect the command to the command runner, call `#runner` with the class of the command runner.

Here is an example interaction with the example command, defined above:

```
% push
push: incorrect number of arguments given: expected 1, but got 0

% push a
Pushing a…

% push -f
push: incorrect number of arguments given: expected 1, but got 0

% push -f a
Pushing a…
… with force!
```

### Subcommands

Commands can have subcommands. For example, the `git` command-line tool would be
represented by a command that has subcommands named `commit`, `add`, and so on.
Commands with subcommands do not use a run block; execution will always be
dispatched to a subcommand (or none, if no subcommand is found).

To add a command as a subcommand to another command, use the
`Cri::Command#add_command` method, like this:

```ruby
root_cmd.add_command(cmd_add)
root_cmd.add_command(cmd_commit)
root_cmd.add_command(cmd_init)
```

You can also define a subcommand on the fly without creating a class first
using `Cri::Command#define_command` (name can be skipped if you set it inside
the block instead):

```ruby
root_cmd.define_command('add') do
  # option ...
  run do |opts, args, cmd|
    # ...
  end
end
```

You can specify a default subcommand. This subcommand will be executed when the
command has subcommands, and no subcommands are otherwise explicitly specified:

```ruby
default_subcommand 'compile'
```

### Loading commands from separate files

You can use `Cri::Command.load_file` to load a command from a file.

For example, given the file _commands/check.rb_ with the following contents:

```ruby
name        'check'
usage       'check'
summary     'runs all checks'
description '…'

run do |opts, args, cmd|
  puts "Running checks…"
end
```

To load this command:

```ruby
Cri::Command.load_file('commands/check.rb')
```

`Cri::Command.load_file` expects the file to be in UTF-8.

You can also use it to load subcommands:

```ruby
root_cmd = Cri::Command.load_file('commands/nanoc.rb')
root_cmd.add_command(Cri::Command.load_file('commands/comile.rb'))
root_cmd.add_command(Cri::Command.load_file('commands/view.rb'))
root_cmd.add_command(Cri::Command.load_file('commands/check.rb'))
```

#### Automatically inferring command names

Pass `infer_name: true` to `Cri::Command.load_file` to use the file basename as the name of the command.

For example, given a file _commands/check.rb_ with the following contents:

```ruby
usage       'check'
summary     'runs all checks'
description '…'

run do |opts, args, cmd|
  puts "Running checks…"
end
```

To load this command and infer the name:

```ruby
cmd = Cri::Command.load_file('commands/check.rb', infer_name: true)
```

`cmd.name` will be `check`, derived from the filename.

## Contributors

- Bart Mesuere
- Ken Coar
- Tim Sharpe
- Toon Willems

Thanks for Lee “injekt” Jarvis for [Slop](https://github.com/injekt/slop),
which has inspired the design of Cri 2.0.
