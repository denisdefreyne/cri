# frozen_string_literal: true

module Cri
  # The command DSL is a class that is used for building and modifying
  # commands.
  class CommandDSL
    # Error that will be raised when specifying a parameter after the command is
    # already declared as taken no params.
    class AlreadySpecifiedAsNoParams < Cri::Error
      def initialize(param, command)
        super("Attempted to specify a parameter #{param.inspect} to the command #{command.name.inspect}, which is already specified as taking no params. Suggestion: remove the #no_params call.")
      end
    end

    # Error that will be raised when declaring the command as taking no
    # parameters, when the command is already declared with parameters.
    class AlreadySpecifiedWithParams < Cri::Error
      def initialize(command)
        super("Attempted to declare the command #{command.name.inspect} as taking no parameters, but some parameters are already declared for this command. Suggestion: remove the #no_params call.")
      end
    end

    # @return [Cri::Command] The built command
    attr_reader :command

    # Creates a new DSL, intended to be used for building a single command. A
    # {CommandDSL} instance is not reusable; create a new instance if you want
    # to build another command.
    #
    # @param [Cri::Command, nil] command The command to modify, or nil if a
    #   new command should be created
    def initialize(command = nil)
      @command = command || Cri::Command.new
    end

    # Adds a subcommand to the current command. The command can either be
    # given explicitly, or a block can be given that defines the command.
    #
    # @param [Cri::Command, nil] command The command to add as a subcommand,
    #   or nil if the block should be used to define the command that will be
    #   added as a subcommand
    #
    # @return [void]
    def subcommand(command = nil, &block)
      if command.nil?
        command = Cri::Command.define(&block)
      end

      @command.add_command(command)
    end

    # Sets the name of the default subcommand, i.e. the subcommand that will
    # be executed if no subcommand is explicitly specified. This is `nil` by
    # default, and will typically only be set for the root command.
    #
    # @param [String, nil] name The name of the default subcommand
    #
    # @return [void]
    def default_subcommand(name)
      @command.default_subcommand_name = name
    end

    # Sets the command name.
    #
    # @param [String] arg The new command name
    #
    # @return [void]
    def name(arg)
      @command.name = arg
    end

    # Sets the command aliases.
    #
    # @param [String, Symbol, Array] args The new command aliases
    #
    # @return [void]
    def aliases(*args)
      @command.aliases = args.flatten.map(&:to_s)
    end

    # Sets the command summary.
    #
    # @param [String] arg The new command summary
    #
    # @return [void]
    def summary(arg)
      @command.summary = arg
    end

    # Sets the command description.
    #
    # @param [String] arg The new command description
    #
    # @return [void]
    def description(arg)
      @command.description = arg
    end

    # Sets the command usage. The usage should not include the “usage:”
    # prefix, nor should it include the command names of the supercommand.
    #
    # @param [String] arg The new command usage
    #
    # @return [void]
    def usage(arg)
      @command.usage = arg
    end

    # Marks the command as hidden. Hidden commands do not show up in the list of
    # subcommands of the parent command, unless --verbose is passed (or
    # `:verbose => true` is passed to the {Cri::Command#help} method). This can
    # be used to mark commands as deprecated.
    #
    # @return [void]
    def be_hidden
      @command.hidden = true
    end

    # Skips option parsing for the command. Allows option-like arguments to be
    # passed in, avoiding the {Cri::Parser} validation.
    #
    # @return [void]
    def skip_option_parsing
      @command.all_opts_as_args = true
    end

    # Adds a new option to the command. If a block is given, it will be
    # executed when the option is successfully parsed.
    #
    # @param [String, Symbol, nil] short The short option name
    #
    # @param [String, Symbol, nil] long The long option name
    #
    # @param [String] desc The option description
    #
    # @option params [:forbidden, :required, :optional] :argument Whether the
    #   argument is forbidden, required or optional
    #
    # @option params [Boolean] :multiple Whether or not the option should
    #   be multi-valued
    #
    # @option params [Boolean] :hidden Whether or not the option should
    #   be printed in the help output
    #
    # @return [void]
    def option(short, long, desc,
               argument: :forbidden,
               multiple: false,
               hidden: false,
               default: nil,
               transform: nil,
               &block)
      @command.option_definitions << Cri::OptionDefinition.new(
        short: short&.to_s,
        long: long&.to_s,
        desc: desc,
        argument: argument,
        multiple: multiple,
        hidden: hidden,
        default: default,
        transform: transform,
        block: block,
      )
    end
    alias opt option

    # Defines a new parameter for the command.
    #
    # @param [Symbol] name The name of the parameter
    def param(name, transform: nil)
      if @command.explicitly_no_params?
        raise AlreadySpecifiedAsNoParams.new(name, @command)
      end

      @command.parameter_definitions << Cri::ParamDefinition.new(
        name: name,
        transform: transform,
      )
    end

    def no_params
      if @command.parameter_definitions.any?
        raise AlreadySpecifiedWithParams.new(@command)
      end

      @command.explicitly_no_params = true
    end

    # Adds a new option with a required argument to the command. If a block is
    # given, it will be executed when the option is successfully parsed.
    #
    # @param [String, Symbol, nil] short The short option name
    #
    # @param [String, Symbol, nil] long The long option name
    #
    # @param [String] desc The option description
    #
    # @option params [Boolean] :multiple Whether or not the option should
    #   be multi-valued
    #
    # @option params [Boolean] :hidden Whether or not the option should
    #   be printed in the help output
    #
    # @return [void]
    #
    # @deprecated
    #
    # @see #option
    def required(short, long, desc, **params, &block)
      params = params.merge(argument: :required)
      option(short, long, desc, **params, &block)
    end

    # Adds a new option with a forbidden argument to the command. If a block
    # is given, it will be executed when the option is successfully parsed.
    #
    # @param [String, Symbol, nil] short The short option name
    #
    # @param [String, Symbol, nil] long The long option name
    #
    # @param [String] desc The option description
    #
    # @option params [Boolean] :multiple Whether or not the option should
    #   be multi-valued
    #
    # @option params [Boolean] :hidden Whether or not the option should
    #   be printed in the help output
    #
    # @return [void]
    #
    # @see #option
    def flag(short, long, desc, **params, &block)
      params = params.merge(argument: :forbidden)
      option(short, long, desc, **params, &block)
    end
    alias forbidden flag

    # Adds a new option with an optional argument to the command. If a block
    # is given, it will be executed when the option is successfully parsed.
    #
    # @param [String, Symbol, nil] short The short option name
    #
    # @param [String, Symbol, nil] long The long option name
    #
    # @param [String] desc The option description
    #
    # @option params [Boolean] :multiple Whether or not the option should
    #   be multi-valued
    #
    # @option params [Boolean] :hidden Whether or not the option should
    #   be printed in the help output
    #
    # @return [void]
    #
    # @deprecated
    #
    # @see #option
    def optional(short, long, desc, **params, &block)
      params = params.merge(argument: :optional)
      option(short, long, desc, **params, &block)
    end

    # Sets the run block to the given block. The given block should have two
    # or three arguments (options, arguments, and optionally the command).
    # Calling this will override existing run block or runner declarations
    # (using {#run} and {#runner}, respectively).
    #
    # @yieldparam [Hash<Symbol,Object>] opts A map of option names, as defined
    #   in the option definitions, onto strings (when single-valued) or arrays
    #   (when multi-valued)
    #
    # @yieldparam [Array<String>] args A list of arguments
    #
    # @return [void]
    def run(&block)
      unless [2, 3].include?(block.arity)
        raise ArgumentError,
              'The block given to Cri::Command#run expects two or three args'
      end

      @command.block = block
    end

    # Defines the runner class for this command. Calling this will override
    # existing run block or runner declarations (using {#run} and {#runner},
    # respectively).
    #
    # @param [Class<CommandRunner>] klass The command runner class (subclass
    #   of {CommandRunner}) that is used for executing this command.
    #
    # @return [void]
    def runner(klass)
      run do |opts, args, cmd|
        klass.new(opts, args, cmd).call
      end
    end
  end
end
