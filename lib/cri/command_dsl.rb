# encoding: utf-8

module Cri

  # @todo Document
  class CommandDSL

    def initialize
      @command = Cri::Command.new
    end

    # @todo Document
    def build_command
      @command.freeze
      @command
    end

    # @todo Document
    def name(arg)
      @command.name = arg
    end

    # @todo Document
    def aliases(*args)
      @command.aliases = args.flatten
    end

    # @todo Document
    def summary(arg)
      @command.short_desc = arg
    end

    # @todo Document
    def description(arg)
      @command.long_desc = arg
    end

    # @todo Document
    def usage(arg)
      @command.usage = arg
    end

    # @todo Document
    def option(short, long, desc, params={})
      requiredness = params[:argument] || :forbidden
      self.add_option(short, long, desc, requiredness)
    end
    alias_method :opt, :option

    # @todo Document
    def required(short, long, desc)
      self.add_option(short, long, desc, :required)
    end

    # @todo Document
    def flag(short, long, desc)
      self.add_option(short, long, desc, :forbidden)
    end
    alias_method :forbidden, :flag

    # @todo Document
    def optional(short, long, desc)
      self.add_option(short, long, desc, :optional)
    end

    # @todo Document
    def run(&block)
      if block.arity != 2
        raise ArgumentError,
          "The block given to Cri::Command#run expects exactly two args"
      end

      @command.block = block
    end

  protected

    # @todo Document
    def add_option(short, long, desc, argument)
      @command.option_definitions << {
        :short    => short.to_s,
        :long     => long.to_s,
        :desc     => desc,
        :argument => argument }
    end

  end

end
