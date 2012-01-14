# encoding: utf-8

module Cri

  # Cri::Command represents a command that can be executed on the commandline.
  # It is also used for the commandline tool itself.
  class Command

    # Delegate used for partitioning the list of arguments and options. This
    # delegate will stop the parser as soon as the first argument, i.e. the
    # command, is found.
    #
    # @api private
    class OptionParserPartitioningDelegate

      # Returns the last parsed argument, which, in this case, will be the
      # first argument, which will be either nil or the command name.
      #
      # @return [String] The last parsed argument.
      attr_reader :last_argument

      # Called when an option is parsed.
      #
      # @param [Symbol] key The option key (derived from the long format)
      #
      # @param value The option value
      #
      # @param [Cri::OptionParser] option_parser The option parser
      #
      # @return [void]
      def option_added(key, value, option_parser)
      end

      # Called when an argument is parsed.
      #
      # @param [String] argument The argument
      #
      # @param [Cri::OptionParser] option_parser The option parser
      #
      # @return [void]
      def argument_added(argument, option_parser)
        @last_argument = argument
        option_parser.stop
      end

    end

    # @return [Cri::Command, nil] This command’s supercommand, or nil if the
    #   command has no supercommand
    attr_accessor :supercommand

    # @return [Set<Cri::Command>] This command’s subcommands
    attr_accessor :commands
    alias_method :subcommands, :commands

    # @return [String] The name
    attr_accessor :name

    # @return [Array<String>] A list of aliases for this command that can be
    #   used to invoke this command
    attr_accessor :aliases

    # @return [String] The short description (“summary”)
    attr_accessor :summary

    # @return [String] The long description (“description”)
    attr_accessor :description

    # @return [String] The usage, without the “usage:” prefix and without the
    #   supercommands’ names.
    attr_accessor :usage

    # @return [Array<Hash>] The list of option definitions
    attr_accessor :option_definitions

    # @return [Proc] The block that should be executed when invoking this
    #   command (ignored for commands with subcommands)
    attr_accessor :block

    # Creates a new command using the DSL. If a string is given, the command
    # will be defined using the string; if a block is given, the block will be
    # used instead.
    #
    # If the block has one parameter, the block will be executed in the same
    # context with the command DSL as its parameter. If the block has no
    # parameters, the block will be executed in the context of the DSL.
    #
    # @param [String, nil] The string containing the command’s definition
    #
    # @return [Cri::Command] The newly defined command
    def self.define(string=nil, filename=nil, &block)
      dsl = Cri::CommandDSL.new
      if string
        args = filename ? [ string, filename ] : [ string ]
        dsl.instance_eval(*args)
      elsif [ -1, 0 ].include? block.arity
        dsl.instance_eval(&block)
      else
        block.call(dsl)
      end
      dsl.command
    end

    # Returns a new command that has support for the `-h`/`--help` option and
    # also has a `help` subcommand. It is intended to be modified (adding
    # name, summary, description, other subcommands, …)
    #
    # @return [Cri::Command] A basic root command
    def self.new_basic_root
      filename = File.dirname(__FILE__) + '/commands/basic_root.rb'
      self.define(File.read(filename))
    end

    # Returns a new command that implements showing help.
    #
    # @return [Cri::Command] A basic help command
    def self.new_basic_help
      filename = File.dirname(__FILE__) + '/commands/basic_help.rb'
      self.define(File.read(filename))
    end

    def initialize
      @aliases            = Set.new
      @commands           = Set.new
      @option_definitions = Set.new
    end

    # Modifies the command using the DSL.
    #
    # If the block has one parameter, the block will be executed in the same
    # context with the command DSL as its parameter. If the block has no
    # parameters, the block will be executed in the context of the DSL.
    #
    # @return [Cri::Command] The command itself
    def modify(&block)
      dsl = Cri::CommandDSL.new(self)
      if [ -1, 0 ].include? block.arity
        dsl.instance_eval(&block)
      else
        block.call(dsl)
      end
      self
    end

    # @return [Hash] The option definitions for the command itself and all its
    #   ancestors
    def global_option_definitions
      res = Set.new
      res.merge(option_definitions)
      res.merge(supercommand.global_option_definitions) if supercommand
      res
    end

    # Adds the given command as a subcommand to the current command.
    #
    # @param [Cri::Command] command The command to add as a subcommand
    #
    # @return [void]
    def add_command(command)
      @commands << command
      command.supercommand = self
    end

    # Defines a new subcommand for the current command using the DSL.
    #
    # @param [String, nil] name The name of the subcommand, or nil if no name
    #   should be set (yet)
    #
    # @return [Cri::Command] The subcommand
    def define_command(name=nil, &block)
      # Execute DSL
      dsl = Cri::CommandDSL.new
      dsl.name name unless name.nil?
      if [ -1, 0 ].include? block.arity
        dsl.instance_eval(&block)
      else
        block.call(dsl)
      end

      # Create command
      cmd = dsl.command
      self.add_command(cmd)
      cmd
    end

    # Returns the commands that could be referred to with the given name. If
    # the result contains more than one command, the name is ambiguous.
    #
    # @param [String] name The full, partial or aliases name of the command
    #
    # @return [Array<Cri::Command>] A list of commands matching the given name
    def commands_named(name)
      # Find by exact name or alias
      @commands.each do |cmd|
        found = cmd.name == name || cmd.aliases.include?(name)
        return [ cmd ] if found
      end

      # Find by approximation
      @commands.select do |cmd|
        cmd.name[0, name.length] == name
      end
    end

    # Returns the command with the given name. This method will display error
    # messages and exit in case of an error (unknown or ambiguous command).
    #
    # The name can be a full command name, a partial command name (e.g. “com”
    # for “commit”) or an aliased command name (e.g. “ci” for “commit”).
    #
    # @param [String] name The full, partial or aliases name of the command
    #
    # @return [Cri::Command] The command with the given name
    def command_named(name)
      commands = commands_named(name)

      if commands.size < 1
        $stderr.puts "#{self.name}: unknown command '#{name}'\n"
        exit 1
      elsif commands.size > 1
        $stderr.puts "#{self.name}: '#{name}' is ambiguous:"
        $stderr.puts "  #{commands.map { |c| c.name }.sort.join(' ') }"
        exit 1
      else
        commands[0]
      end
    end

    # Runs the command with the given commandline arguments.
    #
    # @param [Array<String>] opts_and_args A list of unparsed arguments
    #
    # @param [Hash] parent_opts A hash of options already handled by the
    #   supercommand
    #
    # @return [void]
    def run(opts_and_args, parent_opts={})
      if subcommands.empty?
        # Parse
        parser = Cri::OptionParser.new(
          opts_and_args, global_option_definitions)
        self.handle_parser_errors_while { parser.run }
        local_opts  = parser.options
        global_opts = parent_opts.merge(parser.options)
        args = parser.arguments

        # Handle options
        handle_options(local_opts)

        # Execute
        if @block.nil?
          raise NotImplementedError,
            "No implementation available for '#{self.name}'"
        end
        block.call(global_opts, args, self)
      else
        # Parse up to command name
        stuff = partition(opts_and_args)
        opts_before_cmd, cmd_name, opts_and_args_after_cmd = *stuff

        # Handle options
        handle_options(opts_before_cmd)

        # Get command
        if cmd_name.nil?
          $stderr.puts "#{name}: no command given"
          exit 1
        end
        command = command_named(cmd_name)

        # Run
        command.run(opts_and_args_after_cmd, opts_before_cmd)
      end
    end

    # @return [String] The help text for this command
    def help
      text = ''

      # Append usage
      if usage
        path = [ self.supercommand ]
        path.unshift(path[0].supercommand) until path[0].nil?
        full_usage = path[1..-1].map { |c| c.name + ' ' }.join + usage
        text << "usage: #{full_usage}\n"
      end

      # Append aliases
      unless aliases.empty?
        text << "\n"
        text << "aliases: #{aliases.join(' ')}\n"
      end

      # Append short description
      if summary
        text << "\n"
        text << summary + "\n"
      end

      # Append long description
      if description
        text << "\n"
        text << description.wrap_and_indent(78, 4) + "\n"
      end

      # Append subcommands
      unless self.commands.empty?
        text << "\n"
        text << (self.supercommand ? 'subcommands' : 'commands') << ":\n"
        text << "\n"
        length = self.commands.inject(0) { |m,c| [ m, c.name.size ].max }
        self.commands.each do |cmd|
          text << sprintf("    %-#{length+4}s %s\n",
            cmd.name,
            cmd.summary)
        end
      end

      # Append options
      groups = { 'options' => self.option_definitions }
      if self.supercommand
        groups["options for #{self.supercommand.name}"] = self.supercommand.global_option_definitions
      end
      length = groups.values.inject(&:+).inject(0) { |m,o| [ m, o[:long].size ].max }
      groups.each_pair do |name, defs|
        unless defs.empty?
          text << "\n"
          text << "#{name}:\n"
          text << "\n"
          defs.sort { |x,y| x[:long] <=> y[:long] }.each do |opt_def|
            text << sprintf(
              "    -%1s --%-#{length+4}s %s\n",
              opt_def[:short],
              opt_def[:long],
              opt_def[:desc])
          end
        end
      end

      # Return text
      text
    end

    # Compares this command's name to the other given command's name.
    def <=>(other)
      self.name <=> other.name
    end

  protected

    def handle_options(opts)
      opts.each_pair do |key, value|
        opt_def = global_option_definitions.find { |o| o[:long] == key.to_s }
        block = opt_def[:block]
        block.call(value, self) if block
      end
    end

    def partition(opts_and_args)
      # Parse
      delegate = Cri::Command::OptionParserPartitioningDelegate.new
      parser = Cri::OptionParser.new(opts_and_args, global_option_definitions)
      parser.delegate = delegate
      self.handle_parser_errors_while { parser.run }
      parser

      # Extract
      [
        parser.options,
        delegate.last_argument,
        parser.unprocessed_arguments_and_options
      ]
    end

    def handle_parser_errors_while(&block)
      begin
        block.call
      rescue Cri::OptionParser::IllegalOptionError => e
        $stderr.puts "#{name}: illegal option -- #{e}"
        exit 1
      rescue Cri::OptionParser::OptionRequiresAnArgumentError => e
        $stderr.puts "#{name}: option requires an argument -- #{e}"
        exit 1
      end
    end

  end

end
