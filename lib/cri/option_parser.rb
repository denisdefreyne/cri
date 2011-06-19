# encoding: utf-8

module Cri

  # Cri::OptionParser is used for parsing commandline options.
  class OptionParser

    # Superclass for generic option parser errors.
    class GenericError < StandardError
    end

    # Error that will be raised when an unknown option is encountered.
    class IllegalOptionError < Cri::OptionParser::GenericError
    end

    # Error that will be raised when an option without argument is
    # encountered.
    class OptionRequiresAnArgumentError < Cri::OptionParser::GenericError
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

    # The arguments that have already been parsed.
    #
    # If the parser was stopped before it finished, this will not contain all
    # options and `unprocessed_arguments_and_options` will contain what is
    # left to be processed.
    #
    # @return [Array] The already parsed arguments.
    attr_reader :arguments

    # The options and arguments that have not yet been processed. If the
    # parser wasn’t stopped (using {#stop}), this list will be empty.
    #
    # @return [Array] The not yet parsed options and arguments.
    attr_reader :unprocessed_arguments_and_options

    # Parses the commandline arguments. See the instance `parse` method for
    # details.
    def self.parse(arguments_and_options, definitions)
      self.new(arguments_and_options, definitions).run
    end

    # Creates a new parser with the given options/arguments and definitions.
    #
    # @param [Array<String>] arguments_and_options An array containing the
    #   commandline arguments
    #
    # @param [Array<Hash>] definitions An array of option definitions
    def initialize(arguments_and_options, definitions)
      @unprocessed_arguments_and_options = arguments_and_options.dup
      @definitions = definitions

      @options   = {}
      @arguments = []

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

    # Parses the commandline arguments into options and arguments
    #
    # +arguments_and_options+ is an array of commandline arguments and
    # options. This will usually be +ARGV+.
    #
    # +definitions+ contains a list of hashes defining which options are
    # allowed and how they will be handled. Such a hash has three keys:
    #
    # :short:: The short name of the option, e.g. +a+. Do not include the '-'
    #          prefix.
    #
    # :long:: The long name of the option, e.g. +all+. Do not include the '--'
    #         prefix.
    #
    # :argument:: Whether this option's argument is required (:required),
    #             optional (:optional) or forbidden (:forbidden).
    #
    # A sample array of definition hashes could look like this:
    #
    #     [
    #       { :short => 'a', :long => 'all',  :argument => :forbidden },
    #       { :short => 'p', :long => 'port', :argument => :required  },
    #     ]
    #
    # During parsing, two errors can be raised:
    #
    # IllegalOptionError:: An unrecognised option was encountered, i.e. an
    #                      option that is not present in the list of option
    #                      definitions.
    #
    # OptionRequiresAnArgumentError:: An option was found that did not have a
    #                                 value, even though this value was
    #                                 required.
    #
    # What will be returned, is a hash with two keys, :arguments and :options.
    # The :arguments value contains a list of arguments, and the :options
    # value contains a hash with key-value pairs for each option. Options
    # without values will have a +nil+ value instead.
    #
    # For example, the following commandline options (which should not be
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
    def run
      @running = true

      while running?
        # Get next item
        e = @unprocessed_arguments_and_options.shift
        break if e.nil?

        # Handle end-of-options marker
        if e == '--'
          @no_more_options = true
        # Handle incomplete options
        elsif e =~ /^--./ and !@no_more_options
          # Get option key, and option value if included
          if e =~ /^--([^=]+)=(.+)$/
            option_key   = $1
            option_value = $2
          else
            option_key    = e[2..-1]
            option_value  = nil
          end

          # Find definition
          definition = @definitions.find { |d| d[:long] == option_key }
          raise IllegalOptionError.new(option_key) if definition.nil?

          if [ :required, :optional ].include?(definition[:argument])
            # Get option value if necessary
            if option_value.nil?
              option_value = @unprocessed_arguments_and_options.shift
              if option_value.nil? || option_value =~ /^-/
                if definition[:argument] == :required
                  raise OptionRequiresAnArgumentError.new(option_key)
                else
                  @unprocessed_arguments_and_options.unshift(option_value)
                  option_value = true
                end
              end
            end

            # Store option
            add_option(definition[:long].to_sym, option_value)
          else
            # Store option
            add_option(definition[:long].to_sym, true)
          end
        # Handle -xyz options
        elsif e =~ /^-./ and !@no_more_options
          # Get option keys
          option_keys = e[1..-1].scan(/./)

          # For each key
          option_keys.each do |option_key|
            # Find definition
            definition = @definitions.find { |d| d[:short] == option_key }
            raise IllegalOptionError.new(option_key) if definition.nil?

            if option_keys.length > 1 and definition[:argument] == :required
              # This is a combined option and it requires an argument, so complain
              raise OptionRequiresAnArgumentError.new(option_key)
            elsif [ :required, :optional ].include?(definition[:argument])
              # Get option value
              option_value = @unprocessed_arguments_and_options.shift
              if option_value.nil? || option_value =~ /^-/
                if definition[:argument] == :required
                  raise OptionRequiresAnArgumentError.new(option_key)
                else
                  @unprocessed_arguments_and_options.unshift(option_value)
                  option_value = true
                end
              end

              # Store option
              add_option(definition[:long].to_sym, option_value)
            else
              # Store option
              add_option(definition[:long].to_sym, true)
            end
          end
        # Handle normal arguments
        else
          add_argument(e)
        end
      end

      { :options => options, :arguments => arguments }
    ensure
      @running = false
    end

  private

    def add_option(key, value)
      options[key] = value
      delegate.option_added(key, value, self) unless delegate.nil?
    end

    def add_argument(value)
      arguments << value
      delegate.argument_added(value, self) unless delegate.nil?
    end

  end

end
