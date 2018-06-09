# frozen_string_literal: true

module Cri
  module CoreExtensions
  end
end

require_relative 'core_ext/string'

class String
  include Cri::CoreExtensions::String
end
