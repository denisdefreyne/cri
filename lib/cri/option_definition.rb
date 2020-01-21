# frozen_string_literal: true

module Cri
  # The definition of an option.
  class OptionDefinition
    attr_reader :short
    attr_reader :long
    attr_reader :desc
    attr_reader :argument
    attr_reader :multiple
    attr_reader :block
    attr_reader :hidden
    attr_reader :default
    attr_reader :transform

    def initialize(short:, long:, desc:, argument:, multiple:, block:, hidden:, default:, transform:)
      @short     = short
      @long      = long
      @desc      = desc
      @argument  = argument
      @multiple  = multiple
      @block     = block
      @hidden    = hidden
      @default   = default
      @transform = transform

      if @short.nil? && @long.nil?
        raise ArgumentError, 'short and long options cannot both be nil'
      end

      if @default && @argument == :forbidden
        raise ArgumentError, 'a default value cannot be specified for flag options'
      end

      @default = false if @argument == :forbidden
    end

    def to_h
      {
        short: @short,
        long: @long,
        desc: @desc,
        argument: @argument,
        multiple: @multiple,
        block: @block,
        hidden: @hidden,
        default: @default,
        transform: @transform,
      }
    end

    def formatted_name
      @long ? '--' + @long : '-' + @short
    end
  end
end
