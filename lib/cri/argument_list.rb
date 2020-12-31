# frozen_string_literal: true

module Cri
  # A list of arguments, which can be indexed using either a number or a symbol.
  class ArgumentList
    # Error that will be raised when an incorrect number of arguments is given.
    class ArgumentCountMismatchError < Cri::Error
      def initialize(expected_count, actual_count)
        super("incorrect number of arguments given: expected #{expected_count}, but got #{actual_count}")
      end
    end

    include Enumerable

    def initialize(raw_arguments, explicitly_no_params, param_defns)
      @raw_arguments = raw_arguments
      @explicitly_no_params = explicitly_no_params
      @param_defns = param_defns

      load
    end

    def [](key)
      case key
      when Symbol
        @arguments_hash[key]
      when Integer
        @arguments_array[key]
      else
        raise ArgumentError, "argument lists can be indexed using a Symbol or an Integer, but not a #{key.class}"
      end
    end

    def each
      return to_enum(__method__) unless block_given?

      @arguments_array.each { |e| yield(e) }
      self
    end

    def method_missing(sym, *args, &block)
      if @arguments_array.respond_to?(sym)
        @arguments_array.send(sym, *args, &block)
      else
        super
      end
    end

    def respond_to_missing?(sym, include_private = false)
      @arguments_array.respond_to?(sym) || super
    end

    def load
      @arguments_array = []
      @arguments_hash = {}

      arguments_array = @raw_arguments.reject { |a| a == '--' }.freeze

      if !@explicitly_no_params && @param_defns.empty?
        # No parameters defined; ignore
        @arguments_array = arguments_array
        return
      end

      if arguments_array.size != @param_defns.size
        raise ArgumentCountMismatchError.new(@param_defns.size, arguments_array.size)
      end

      arguments_array.zip(@param_defns).each do |(arg, param_defn)|
        arg = param_defn.transform ? param_defn.transform.call(arg) : arg
        @arguments_hash[param_defn.name.to_sym] = arg
        @arguments_array << arg
      end
    end
  end
end
