# frozen_string_literal: true

module Cri
  # The definition of a parameter.
  class ParamDefinition
    attr_reader :name
    attr_reader :transform

    def initialize(name:, transform:)
      @name = name
      @transform = transform
    end
  end
end
