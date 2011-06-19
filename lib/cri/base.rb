# encoding: utf-8

module Cri

  # Cri::Base is the central class representing a commandline tool. It has a
  # list of commands.
  class Base

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

    # @return [Array<Cri::Command>] The list of loaded commands
    attr_reader :commands

    # @param [String] tool_name The name of the commandline tool
    def initialize(tool_name)
      @tool_name = tool_name

      @commands = []
    end

    # @todo document
    def define_command(name=nil, &block)
      command = Cri::Command.new
      command.name name unless name.nil?
      command.instance_eval(&block)
      command.verify
      add_command(command)
      command
    end

    # Returns the help command. If the help command was set using
    # {#help_command=}, this one will be returned. Otherwise, the command with
    # name `"help"` will be returned.
    #
    # @return [Cri::Command] The help command
    def help_command
      @help_command ||= command_named('help')
    end

    # Sets the help command.
    #
    # @param [Cri::Command] command The command to use for help
    #
    # @return [void]
    def help_command=(command)
      @help_command = command
    end

    # Parses the given commandline arguments and executes the requested
    # command.
    #
    # @param [Array<String>] args The list of options and arguments
    #
    # @return [void]
    def run(args)
      # Check arguments
      if args.length == 0
        help_command.run([], [])
        exit 1
      end

      # Partition
      opts_before_command, command_name, opts_and_args_after_command = *partition(args)

      # Handle options before command
      opts_before_command.each_pair do |key, value|
        safe_handle_option(key, value)
      end

      # Get command
      if command_name.nil?
        $stderr.puts "no command given"
        exit 1
      end
      command = command_named(command_name)

      # Parse arguments
      option_definitions = command.option_definitions + global_option_definitions
      begin
        parsed_arguments = Cri::OptionParser.parse(
          opts_and_args_after_command,
          option_definitions)
      rescue Cri::OptionParser::IllegalOptionError => e
        $stderr.puts "illegal option -- #{e}"
        exit 1
      rescue Cri::OptionParser::OptionRequiresAnArgumentError => e
        $stderr.puts "option requires an argument -- #{e}"
        exit 1
      end

      # Handle global options
      opts_after_command = parsed_arguments[:options].dup
      opts_after_command.delete_if { |k,v| opts_before_command.keys.include?(k) }
      opts_after_command.each_pair { |k,v| safe_handle_option(k, v, command) }

      # Run command
      command.run(
        parsed_arguments[:options],
        parsed_arguments[:arguments])
    end

    # Returns the commands that could be referred to with the given name. If
    # the result contains more than one command, the name is ambiguous.
    def commands_named(name)
      # Find by exact name or alias
      command = @commands.find { |c| c.name == name or c.aliases.include?(name) }
      return [ command ] unless command.nil?

      # Find by approximation
      @commands.select { |c| c.name[0, name.length] == name }
    end

    # Returns the command with the given name.
    def command_named(name)
      commands = commands_named(name)

      if commands.empty?
        $stderr.puts "#{@tool_name}: unknown command '#{name}'\n"
        show_help unless name == 'help' # ugly
        exit 1
      elsif commands.size > 1
        $stderr.puts "#{@tool_name}: '#{name}' is ambiguous:"
        $stderr.puts "  #{commands.map { |c| c.name }.join(' ') }"
        exit 1
      else
        commands[0]
      end
    end

    # Shows the help text for the given command, or shows the general help
    # text if no command is given.
    def show_help(command=nil)
      if command
        puts command.help
      elsif help_command
        help_command.run([], [])
      else
        puts "No help available."
      end
    end

    # Returns the list of global option definitions.
    def global_option_definitions
      [
        {
          :long => 'help', :short => 'h', :argument => :forbidden,
          :desc => 'show this help message and quit'
        }
      ]
    end

    # Adds the given command to the list of commands. Adding a command will
    # also cause the command's +base+ to be set to this instance.
    def add_command(command)
      @commands << command
      command.base = self
    end

    # Handles the given option.
    def handle_option(key, value, command)
      case key
        when :help
          show_help(command)
          exit 0
      end
    end

    # TODO document
    def safe_handle_option(key, value, command=nil)
      if self.method(:handle_option).arity == 1
        handle_option(key)
      else
        handle_option(key, value, command)
      end
    end

  private

    # Returns true if the given string is an option (i.e. -foo or --foo),
    # false otherwise.
    def is_option?(string)
      string =~ /^-/
    end

    # Partitions the list of options and arguments into a list of options
    # before the command name, the command name itself, and the remaining
    # options and arguments.
    def partition(args)
      # Parse
      delegate = Cri::Base::OptionParserPartitioningDelegate.new
      parser = Cri::OptionParser.new(args, global_option_definitions)
      parser.delegate = delegate
      parser.run

      # Extract
      [
        parser.options,
        delegate.last_argument,
        parser.unprocessed_arguments_and_options
      ]
    end

  end

end
