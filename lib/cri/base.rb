module Cri

  # Cri::Base is the central class representing a commandline tool. It has a
  # list of commands.
  class Base

    # The CLI's list of commands (should also contain the help command)
    attr_reader :commands

    # The CLI's help command (required)
    attr_accessor :help_command

    # Creates a new instance of the commandline tool.
    def initialize(tool_name)
      @tool_name = tool_name

      @commands = []
    end

    # Parses the given commandline arguments and executes the requested
    # command.
    def run(args)
      # Check arguments
      if args.length == 0
        @help_command.run([], [])
        exit 1
      end

      # Partition options
      opts_before_command         = []
      command_name                = nil
      opts_and_args_after_command = []
      stage = 0
      args.each do |arg|
        # Update stage if necessary
        stage = 1 if stage == 0 && !is_option?(arg)

        # Add
        opts_before_command << arg         if stage == 0
        command_name = arg                 if stage == 1
        opts_and_args_after_command << arg if stage == 2

        # Update stage if necessary
        stage = 2 if stage == 1
      end

      # Handle options before command
      begin
        parsed_arguments = Cri::OptionParser.parse(opts_before_command, global_option_definitions)
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
      if command.nil?
        $stderr.puts "no such command: #{command_name}"
        exit 1
      end

      # Parse arguments
      option_definitions = command.option_definitions + global_option_definitions
      begin
        parsed_arguments = Cri::OptionParser.parse(opts_and_args_after_command, option_definitions)
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

    # Returns the command with the given name.
    def command_named(name)
      # Find by exact name or alias
      command = @commands.find { |c| c.name == name or c.aliases.include?(name) }
      return command unless command.nil?

      # Find by approximation
      commands = @commands.select { |c| c.name[0, name.length] == name }
      if commands.length > 1
        $stderr.puts "#{@tool_name}: '#{name}' is ambiguous:"
        $stderr.puts "  #{commands.map { |c| c.name }.join(' ') }"
        exit 1
      elsif commands.length == 0
        $stderr.puts "#{@tool_name}: unknown command '#{name}'\n"
        show_help
        exit 1
      else
        return commands[0]
      end
    end

    # Shows the help text for the given command, or shows the general help
    # text if no command is given.
    def show_help(command=nil)
      if command.nil?
        @help_command.run([], [])
      else
        @help_command.run([], [ command.name ])
      end
    end

    # Returns the list of global option definitions.
    def global_option_definitions
      []
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

  end

end
