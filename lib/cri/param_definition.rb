# frozen_string_literal: true

module Cri
  # The definition of a parameter.
  class ParamDefinition
    attr_reader :name

    def initialize(name:)
      @name = name
    end
  end
end
