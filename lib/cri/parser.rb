# frozen_string_literal: true

module Cri
  # Cri::Parser is used for parsing command-line options and arguments.
  class Parser
    # Error that will be raised when an unknown option is encountered.
    class IllegalOptionError < Cri::Error
    end

    # Error that will be raised when an option with an invalid or
    # non-transformable value is encountered.
    class IllegalOptionValueError < Cri::Error
      attr_reader :definition
      attr_reader :value

      def initialize(definition, value)
        super("invalid value #{value.inspect} for #{definition.formatted_name} option")

        @value = value
        @definition = definition
      end
    end

    # Error that will be raised when an option without argument is
    # encountered.
    class OptionRequiresAnArgumentError < Cri::Error
    end

    # The delegate to which events will be sent. The following methods will
    # be send to the delegate:
    #
    # * `option_added(key, value, cmd)`
    # * `argument_added(argument, cmd)`
    #
    # @return [#option_added, #argument_added] The delegate
    attr_accessor :delegate

    # The options that have already been parsed.
    #
    # If the parser was stopped before it finished, this will not contain all
    # options and `unprocessed_arguments_and_options` will contain what is
    # left to be processed.
    #
    # @return [Hash] The already parsed options.
    attr_reader :options

    # The options and arguments that have not yet been processed. If the
    # parser wasn’t stopped (using {#stop}), this list will be empty.
    #
    # @return [Array] The not yet parsed options and arguments.
    attr_reader :unprocessed_arguments_and_options

    # Creates a new parser with the given options/arguments and definitions.
    #
    # @param [Array<String>] arguments_and_options An array containing the
    #   command-line arguments (will probably be `ARGS` for a root command)
    #
    # @param [Array<Cri::OptionDefinition>] option_defns An array of option
    #   definitions
    #
    # @param [Array<Cri::ParamDefinition>] param_defns An array of parameter
    #   definitions
    def initialize(arguments_and_options, option_defns, param_defns, explicitly_no_params)
      @unprocessed_arguments_and_options = arguments_and_options.dup
      @option_defns = option_defns
      @param_defns = param_defns
      @explicitly_no_params = explicitly_no_params

      @options       = {}
      @raw_arguments = []

      @running = false
      @no_more_options = false
    end

    # @return [Boolean] true if the parser is running, false otherwise.
    def running?
      @running
    end

    # Stops the parser. The parser will finish its current parse cycle but
    # will not start parsing new options and/or arguments.
    #
    # @return [void]
    def stop
      @running = false
    end

    # Parses the command-line arguments into options and arguments.
    #
    # During parsing, two errors can be raised:
    #
    # @raise IllegalOptionError if an unrecognised option was encountered,
    #   i.e. an option that is not present in the list of option definitions
    #
    # @raise OptionRequiresAnArgumentError if an option was found that did not
    #   have a value, even though this value was required.
    #
    # @return [Cri::Parser] The option parser self
    def run
      @running = true

      while running?
        # Get next item
        e = @unprocessed_arguments_and_options.shift
        break if e.nil?

        if e == '--'
          handle_dashdash(e)
        elsif e =~ /^--./ && !@no_more_options
          handle_dashdash_option(e)
        elsif e =~ /^-./ && !@no_more_options
          handle_dash_option(e)
        else
          add_argument(e)
        end
      end

      self
    ensure
      @running = false
    end

    # @return [Cri::ArgumentList] The list of arguments that have already been
    #   parsed, excluding the -- separator.
    def gen_argument_list
      ArgumentList.new(@raw_arguments, @explicitly_no_params, @param_defns)
    end

    private

    def handle_dashdash(elem)
      add_argument(elem)
      @no_more_options = true
    end

    def handle_dashdash_option(elem)
      # Get option key, and option value if included
      if elem =~ /^--([^=]+)=(.+)$/
        option_key   = Regexp.last_match[1]
        option_value = Regexp.last_match[2]
      else
        option_key    = elem[2..-1]
        option_value  = nil
      end

      # Find definition
      option_defn = @option_defns.find { |d| d.long == option_key }
      raise IllegalOptionError.new(option_key) if option_defn.nil?

      if %i[required optional].include?(option_defn.argument)
        # Get option value if necessary
        if option_value.nil?
          option_value = find_option_value(option_defn, option_key)
        end

        # Store option
        add_option(option_defn, option_value)
      else
        # Store option
        add_option(option_defn, true)
      end
    end

    def handle_dash_option(elem)
      # Get option keys
      option_keys = elem[1..-1].scan(/./)

      # For each key
      option_keys.each do |option_key|
        # Find definition
        option_defn = @option_defns.find { |d| d.short == option_key }
        raise IllegalOptionError.new(option_key) if option_defn.nil?

        if %i[required optional].include?(option_defn.argument)
          # Get option value
          option_value = find_option_value(option_defn, option_key)

          # Store option
          add_option(option_defn, option_value)
        else
          # Store option
          add_option(option_defn, true)
        end
      end
    end

    def find_option_value(option_defn, option_key)
      option_value = @unprocessed_arguments_and_options.shift
      if option_value.nil? || option_value =~ /^-/
        if option_defn.argument == :optional && option_defn.default
          option_value = option_defn.default
        elsif option_defn.argument == :required
          raise OptionRequiresAnArgumentError.new(option_key)
        else
          @unprocessed_arguments_and_options.unshift(option_value)
          option_value = true
        end
      end
      option_value
    end

    def add_option(option_defn, value, transform: true)
      key = key_for(option_defn)

      value = transform ? transform_value(option_defn, value) : value

      if option_defn.multiple
        options[key] ||= []
        options[key] << value
      else
        options[key] = value
      end

      delegate&.option_added(key, value, self)
    end

    def transform_value(option_defn, value)
      transformer = option_defn.transform

      if transformer
        begin
          transformer.call(value)
        rescue StandardError
          raise IllegalOptionValueError.new(option_defn, value)
        end
      else
        value
      end
    end

    def key_for(option_defn)
      (option_defn.long || option_defn.short).to_sym
    end

    def add_argument(value)
      @raw_arguments << value

      unless value == '--'
        delegate&.argument_added(value, self)
      end
    end
  end
end
