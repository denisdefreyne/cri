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

    def initialize(params = {})
      @short     = params.fetch(:short)
      @long      = params.fetch(:long)
      @desc      = params.fetch(:desc)
      @argument  = params.fetch(:argument)
      @multiple  = params.fetch(:multiple)
      @block     = params.fetch(:block)
      @hidden    = params.fetch(:hidden)
      @default   = params.fetch(:default)
      @transform = params.fetch(:transform)

      if @short.nil? && @long.nil?
        raise ArgumentError, 'short and long options cannot both be nil'
      end

      if @default && @argument == :forbidden
        raise ArgumentError, 'a default value cannot be specified for flag options'
      end
    end

    def [](key)
      case key
      when :short
        @short
      when :long
        @long
      when :desc
        @desc
      when :argument
        @argument
      when :multiple
        @multiple
      when :block
        @block
      when :hidden
        @hidden
      when :default
        @default
      when :transform
        @transform
      else
        raise ArgumentError, "unknown key: #{key.inspect}"
      end
    end

    def to_h
      {
        short:     @short,
        long:      @long,
        desc:      @desc,
        argument:  @argument,
        multiple:  @multiple,
        block:     @block,
        hidden:    @hidden,
        default:   @default,
        transform: @transform,
      }
    end
  end
end
