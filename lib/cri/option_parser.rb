# frozen_string_literal: true

module Cri
  # Cri::OptionParser is used for parsing command-line options.
  #
  # Option definitions are hashes with the keys `:short`, `:long` and
  # `:argument` (optionally `:description` but this is not used by the
  # option parser, only by the help generator). `:short` is the short,
  # one-character option, without the `-` prefix. `:long` is the long,
  # multi-character option, without the `--` prefix. `:argument` can be
  # :required (if an argument should be provided to the option), :optional
  # (if an argument may be provided) or :forbidden (if an argument should
  # not be provided).
  #
  # A sample array of definition hashes could look like this:
  #
  #     [
  #       { :short => 'a', :long => 'all',  :argument => :forbidden, :multiple => true },
  #       { :short => 'p', :long => 'port', :argument => :required, :multiple => false },
  #     ]
  #
  # For example, the following command-line options (which should not be
  # passed as a string, but as an array of strings):
  #
  #     foo -xyz -a hiss -s -m please --level 50 --father=ani -n luke squeak
  #
  # with the following option definitions:
  #
  #     [
  #       { :short => 'x', :long => 'xxx',    :argument => :forbidden },
  #       { :short => 'y', :long => 'yyy',    :argument => :forbidden },
  #       { :short => 'z', :long => 'zzz',    :argument => :forbidden },
  #       { :short => 'a', :long => 'all',    :argument => :forbidden },
  #       { :short => 's', :long => 'stuff',  :argument => :optional  },
  #       { :short => 'm', :long => 'more',   :argument => :optional  },
  #       { :short => 'l', :long => 'level',  :argument => :required  },
  #       { :short => 'f', :long => 'father', :argument => :required  },
  #       { :short => 'n', :long => 'name',   :argument => :required  }
  #     ]
  #
  # will be translated into:
  #
  #     {
  #       :arguments => [ 'foo', 'hiss', 'squeak' ],
  #       :options => {
  #         :xxx    => true,
  #         :yyy    => true,
  #         :zzz    => true,
  #         :all    => true,
  #         :stuff  => true,
  #         :more   => 'please',
  #         :level  => '50',
  #         :father => 'ani',
  #         :name   => 'luke'
  #       }
  #     }
  class OptionParser
    # Error that will be raised when an unknown option is encountered.
    class IllegalOptionError < Cri::Error
    end

    # Error that will be raised when an option with an invalid or
    # non-transformable value is encountered.
    class IllegalOptionValueError < Cri::Error
      attr_reader :definition
      attr_reader :value

      def initialize(definition, value)
        @definition = definition
        @value      = value
      end

      def message
        name = @definition[:long] ? '--' + @definition[:long] : '-' + @definition[:short]
        "invalid value #{value.inspect} for #{name} option"
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

    # @return [Array] The arguments that have already been parsed, including
    #   the -- separator.
    attr_reader :raw_arguments

    # The options and arguments that have not yet been processed. If the
    # parser wasn’t stopped (using {#stop}), this list will be empty.
    #
    # @return [Array] The not yet parsed options and arguments.
    attr_reader :unprocessed_arguments_and_options

    # Parses the command-line arguments. See the instance `parse` method for
    # details.
    #
    # @param [Array<String>] arguments_and_options An array containing the
    #   command-line arguments (will probably be `ARGS` for a root command)
    #
    # @param [Array<Hash>] option_defns An array of option definitions
    #
    # @return [Cri::OptionParser] The option parser self
    def self.parse(arguments_and_options, option_defns)
      new(arguments_and_options, option_defns).run
    end

    # Creates a new parser with the given options/arguments and definitions.
    #
    # @param [Array<String>] arguments_and_options An array containing the
    #   command-line arguments (will probably be `ARGS` for a root command)
    #
    # @param [Array<Hash>] option_defns An array of option option_defns
    def initialize(arguments_and_options, option_defns)
      @unprocessed_arguments_and_options = arguments_and_options.dup
      @option_defns = option_defns

      @options       = {}
      @raw_arguments = []

      @running = false
      @no_more_options = false
    end

    # Returns the arguments that have already been parsed.
    #
    # If the parser was stopped before it finished, this will not contain all
    # options and `unprocessed_arguments_and_options` will contain what is
    # left to be processed.
    #
    # @return [Array] The already parsed arguments.
    def arguments
      @raw_arguments.reject { |a| a == '--' }.freeze
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
    # @return [Cri::OptionParser] The option parser self
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

      add_defaults

      self
    ensure
      @running = false
    end

    private

    def add_defaults
      @option_defns.each { |d| add_default_option(d) }
    end

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
      option_defn = @option_defns.find { |d| d[:long] == option_key }
      raise IllegalOptionError.new(option_key) if option_defn.nil?

      if %i[required optional].include?(option_defn[:argument])
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
        option_defn = @option_defns.find { |d| d[:short] == option_key }
        raise IllegalOptionError.new(option_key) if option_defn.nil?

        if %i[required optional].include?(option_defn[:argument])
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
        if option_defn[:argument] == :optional && option_defn[:default]
          option_value = option_defn[:default]
        elsif option_defn[:argument] == :required
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

      if option_defn[:multiple]
        options[key] ||= []
        options[key] << value
      else
        options[key] = value
      end

      delegate&.option_added(key, value, self)
    end

    def add_default_option(option_defn)
      key = key_for(option_defn)
      return if options.key?(key)

      value = option_defn[:default]
      return unless value

      add_option(option_defn, value, transform: false)
    end

    def transform_value(option_defn, value)
      transformer = option_defn[:transform]

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
      (option_defn[:long] || option_defn[:short]).to_sym
    end

    def add_argument(value)
      @raw_arguments << value

      unless value == '--'
        delegate&.argument_added(value, self)
      end
    end
  end
end
