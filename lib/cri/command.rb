# encoding: utf-8

module Cri

  # Cri::Command represents a command that can be executed on the commandline.
  # It is an abstract superclass for all commands.
  class Command

    attr_accessor :base

    # @todo document
    def verify
      # TODO implement
      errors = []
      errors << "name is nil" if @name.nil?
      errors
    end

    # @todo document
    def name(arg=nil)
      if arg.nil?
        @name or raise NotImplementedError,
          "This command does not have a name"
      else
        @name = arg
      end
    end

    # @todo document
    def aliases(*args)
      if args.empty?
        @aliases ||= []
      else
        @aliases = args
      end
    end

    # @todo document
    def short_desc(arg=nil)
      if arg.nil?
        @short_desc or raise NotImplementedError,
          "This command does not have a short description"
      else
        @short_desc = arg
      end
    end

    # @todo document
    def long_desc(arg=nil)
      if arg.nil?
        @long_desc
      else
        @long_desc = arg
      end
    end

    # @todo document
    def usage(arg=nil)
      if arg.nil?
        @usage or raise NotImplementedError,
          "This command does not have a usage"
      else
        @usage = arg
      end
    end

    # @todo document
    def option_definitions
      @option_definitions ||= []
    end

    # @todo document
    def option(short, long, desc, params={})
      requiredness = params.fetch(:argument) do
        raise ArgumentError,
          "Expected an :argument parameter (:required, :forbidden, :optional)"
      end

      add_option(short, long, desc, requiredness)
    end

    # @todo document
    def required(short, long, desc)
      add_option(short, long, desc, :required)
    end

    # @todo document
    def flag(short, long, desc)
      add_option(short, long, desc, :forbidden)
    end
    alias_method :forbidden, :flag

    # @todo document
    def optional(short, long, desc)
      add_option(short, long, desc, :optional)
    end

    # @todo document
    def run(*args, &block)
      if args.empty? && block
        # set block
        if block.arity != 2
          raise ArgumentError,
            "The block given to Cri::Command#run expects exactly two args"
        end
        @block = block
      elsif args.size == 2
        # run
        if @block.nil?
          raise RuntimeError,
            "This command does not have anything to execute"
        end
        @block.call(*args)
      else
        raise ArgumentError,
          "You are calling Cri::Command#run in a weird way. Kittens cry. :("
      end
    end

    # @return [String] The help text for this command
    def help
      text = ''

      # Append usage
      text << usage + "\n"

      # Append aliases
      unless aliases.empty?
        text << "\n"
        text << "aliases: #{aliases.join(' ')}\n"
      end

      # Append short description
      text << "\n"
      text << short_desc + "\n"

      # Append long description
      text << "\n"
      text << long_desc.wrap_and_indent(78, 4) + "\n"

      # Append options
      all_option_definitions = base.global_option_definitions + option_definitions
      unless all_option_definitions.empty?
        text << "\n"
        text << "options:\n"
        text << "\n"
        all_option_definitions.sort { |x,y| x[:long] <=> y[:long] }.each do |opt_def|
          text << sprintf("    -%1s --%-10s %s\n", opt_def[:short], opt_def[:long], opt_def[:desc])
        end
      end

      # Return text
      text
    end

    # Compares this command's name to the other given command's name.
    def <=>(other)
      self.name <=> other.name
    end

  private

    # @todo document
    def add_option(short, long, desc, argument)
      option_definitions << {
        :short    => short.to_s,
        :long     => long.to_s,
        :desc     => desc,
        :argument => argument }
    end

  end

end
