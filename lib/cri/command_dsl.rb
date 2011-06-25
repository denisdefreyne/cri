# encoding: utf-8

module Cri

  # @todo Document
  class CommandDSL

    def initialize(command=nil)
      @command = command || Cri::Command.new
    end

    # @todo Document
    def command
      @command
    end

    # @todo Document
    def subcommand(cmd=nil, &block)
      if cmd.nil?
        cmd = Cri::Command.define(&block)
      end

      @command.add_command(cmd)
    end

    # @todo Document
    def name(arg)
      @command.name = arg
    end

    # @todo Document
    def aliases(*args)
      @command.aliases = args.flatten.map { |a| a.to_s }
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
    def option(short, long, desc, params={}, &block)
      requiredness = params[:argument] || :forbidden
      self.add_option(short, long, desc, requiredness, block)
    end
    alias_method :opt, :option

    # @todo Document
    def required(short, long, desc, &block)
      self.add_option(short, long, desc, :required, block)
    end

    # @todo Document
    def flag(short, long, desc, &block)
      self.add_option(short, long, desc, :forbidden, block)
    end
    alias_method :forbidden, :flag

    # @todo Document
    def optional(short, long, desc, &block)
      self.add_option(short, long, desc, :optional, block)
    end

    # @todo Document
    def run(&block)
      unless block.arity != 2 || block.arity != 3
        raise ArgumentError,
          "The block given to Cri::Command#run expects two or three args"
      end

      @command.block = block
    end

  protected

    # @todo Document
    def add_option(short, long, desc, argument, block)
      @command.option_definitions << {
        :short    => short.to_s,
        :long     => long.to_s,
        :desc     => desc,
        :argument => argument,
        :block    => block }
    end

  end

end
