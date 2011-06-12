module Cri

  # Cri::Base is the central class representing a commandline tool. It has a
  # list of commands.
  class Base

    # TODO document
    class OptionParserDelegate

      # TODO document
      attr_reader :last_argument

      # TODO document
      def option_added(key, value, option_parser)
      end

      # TODO document
      def argument_added(argument, option_parser)
        @last_argument = argument
        option_parser.stop
      end

    end

    # The CLI's list of commands (should also contain the help command)
    attr_reader :commands

    # Creates a new instance of the commandline tool.
    def initialize(tool_name)
      @tool_name = tool_name

      @commands = []
    end

    # TODO document
    def help_command
      @help_command || command_named('help')
    end

    # TODO document
    def help_command=(command)
      @help_command = command
    end

    # Parses the given commandline arguments and executes the requested
    # command.
    def run(args)
      # Check arguments
      if args.length == 0
        help_command.run([], [])
        exit 1
      end

      # Partition
      opts_before_command, command_name, opts_and_args_after_command = *partition(args)

      # Handle options before command
      begin
        parsed_arguments = Cri::OptionParser.parse(
          opts_before_command,
          global_option_definitions)
      rescue Cri::OptionParser::IllegalOptionError => e
        $stderr.puts "illegal option -- #{e}"
        exit 1
      end
      parsed_arguments[:options].keys.each do |option|
        handle_option(option)
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
      global_options = global_option_definitions.map { |o| o[:long] }
      global_options.delete_if { |o| !parsed_arguments[:options].keys.include?(o.to_sym) }
      global_options.each { |o| handle_option(o.to_sym) }

      if parsed_arguments[:options].has_key?(:help)
        # Show help for this command
        show_help(command)
      else
        # Run command
        command.run(parsed_arguments[:options], parsed_arguments[:arguments])
      end
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
    def handle_option(option)
      false
    end

  private

    # Returns true if the given string is an option (i.e. -foo or --foo),
    # false otherwise.
    def is_option?(string)
      string =~ /^-/
    end

    def partition(args)
      # Parse
      delegate = Cri::Base::OptionParserDelegate.new
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
