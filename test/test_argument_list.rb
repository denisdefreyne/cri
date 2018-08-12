# frozen_string_literal: true

require 'helper'

module Cri
  class ArgumentListTestCase < Cri::TestCase
    def test_empty
      args = Cri::ArgumentList.new([], [])

      assert_equal([], args.to_a)
      assert(args.empty?)
      assert_equal(0, args.size)
      assert_equal(nil, args[0])
      assert_equal(nil, args[:abc])
    end

    def test_no_param_defns
      args = Cri::ArgumentList.new(%w[a b c], [])

      assert_equal(%w[a b c], args.to_a)
      refute(args.empty?)
      assert_equal(3, args.size)
      assert_equal('a', args[0])
      assert_equal('b', args[1])
      assert_equal('c', args[2])
      assert_equal(nil, args[3])
      assert_equal(nil, args[:abc])
    end

    def test_enum
      args = Cri::ArgumentList.new(%w[a b c], [])

      assert_equal(%w[A B C], args.map(&:upcase))
    end

    def test_no_method_error
      args = Cri::ArgumentList.new(%w[a b c], [])

      refute args.respond_to?(:oink)
      assert_raises(NoMethodError, 'x') do
        args.oink
      end
    end

    def test_dash_dash
      args = Cri::ArgumentList.new(%w[a -- b -- c], [])

      assert_equal(%w[a b c], args.to_a)
    end

    def test_one_param_defn_matched
      param_defns = [Cri::ParamDefinition.new(name: 'filename')]
      args = Cri::ArgumentList.new(%w[notbad.jpg], param_defns)

      assert_equal(['notbad.jpg'], args.to_a)
      assert_equal(1, args.size)
      assert_equal('notbad.jpg', args[0])
      assert_equal('notbad.jpg', args[:filename])
    end

    def test_one_param_defn_too_many
      param_defns = [Cri::ParamDefinition.new(name: 'filename')]

      exception = assert_raises(Cri::ArgumentList::ArgumentCountMismatchError) do
        Cri::ArgumentList.new(%w[notbad.jpg verybad.jpg], param_defns)
      end
      assert_equal('incorrect number of arguments given: expected 1, but got 2', exception.message)
    end

    def test_one_param_defn_too_few
      param_defns = [Cri::ParamDefinition.new(name: 'filename')]

      exception = assert_raises(Cri::ArgumentList::ArgumentCountMismatchError) do
        Cri::ArgumentList.new(%w[], param_defns)
      end
      assert_equal('incorrect number of arguments given: expected 1, but got 0', exception.message)
    end
  end
end
