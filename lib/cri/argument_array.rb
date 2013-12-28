# encoding: utf-8

module Cri

  class ArgumentArray < Array

    def initialize(raw_arguments)
      super(raw_arguments.reject { |a| '--' == a })
      @raw_arguments = raw_arguments
    end

    def raw
      @raw_arguments
    end

  end

end
