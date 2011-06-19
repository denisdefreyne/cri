# encoding: utf-8

module Cri

  # Cri::Command represents a command that can be executed on the commandline.
  # It is an abstract superclass for all commands.
  class Command

    # @todo Document
    attr_accessor :base

    # @todo Document
    attr_accessor :name

    # @todo Document
    attr_accessor :aliases

    # @todo Document
    attr_accessor :short_desc

    # @todo Document
    attr_accessor :long_desc

    # @todo Document
    attr_accessor :usage

    # @todo Document
    attr_accessor :option_definitions

    # @todo Document
    attr_accessor :block

    def initialize
      @aliases            = Set.new
      @option_definitions = Set.new
    end

    # @todo Document
    def run(options, arguments)
      if @block.nil?
        raise RuntimeError,
          "This command does not have anything to execute"
      end

      @block.call(options, arguments)
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

  end

end
