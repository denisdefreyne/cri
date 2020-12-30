# frozen_string_literal: true

require 'helper'

module Cri
  class ParserTestCase < Cri::TestCase
    def test_parse_without_options
      input = %w[foo bar baz]
      opt_defns = []

      parser = Cri::Parser.new(input, opt_defns, [], false).run

      assert_equal({}, parser.options)
      assert_equal(%w[foo bar baz], parser.gen_argument_list.to_a)
    end

    def test_parse_with_invalid_option
      input = %w[foo -x]
      opt_defns = []

      assert_raises(Cri::Parser::IllegalOptionError) do
        Cri::Parser.new(input, opt_defns, [], false).run
      end
    end

    def test_parse_with_unused_options
      input = %w[foo]
      opt_defns = [
        { long: 'aaa', short: 'a', argument: :forbidden },
      ].map { |hash| make_opt_defn(hash) }

      parser = Cri::Parser.new(input, opt_defns, [], false).run

      assert(!parser.options[:aaa])
    end

    def test_parse_with_long_valueless_option
      input = %w[foo --aaa bar]
      opt_defns = [
        { long: 'aaa', short: 'a', argument: :forbidden },
      ].map { |hash| make_opt_defn(hash) }

      parser = Cri::Parser.new(input, opt_defns, [], false).run

      assert(parser.options[:aaa])
      assert_equal(%w[foo bar], parser.gen_argument_list.to_a)
    end

    def test_parse_with_long_valueful_option
      input = %w[foo --aaa xxx bar]
      opt_defns = [
        { long: 'aaa', short: 'a', argument: :required },
      ].map { |hash| make_opt_defn(hash) }

      parser = Cri::Parser.new(input, opt_defns, [], false).run

      assert_equal({ aaa: 'xxx' }, parser.options)
      assert_equal(%w[foo bar], parser.gen_argument_list.to_a)
    end

    def test_parse_with_long_valueful_equalsign_option
      input = %w[foo --aaa=xxx bar]
      opt_defns = [
        { long: 'aaa', short: 'a', argument: :required },
      ].map { |hash| make_opt_defn(hash) }

      parser = Cri::Parser.new(input, opt_defns, [], false).run

      assert_equal({ aaa: 'xxx' }, parser.options)
      assert_equal(%w[foo bar], parser.gen_argument_list.to_a)
    end

    def test_parse_with_long_valueful_option_with_missing_value
      input = %w[foo --aaa]
      opt_defns = [
        { long: 'aaa', short: 'a', argument: :required },
      ].map { |hash| make_opt_defn(hash) }

      assert_raises(Cri::Parser::OptionRequiresAnArgumentError) do
        Cri::Parser.new(input, opt_defns, [], false).run
      end
    end

    def test_parse_with_two_long_valueful_options
      input = %w[foo --all --port 2]
      opt_defns = [
        { long: 'all',  short: 'a', argument: :required },
        { long: 'port', short: 'p', argument: :required },
      ].map { |hash| make_opt_defn(hash) }

      assert_raises(Cri::Parser::OptionRequiresAnArgumentError) do
        Cri::Parser.new(input, opt_defns, [], false).run
      end
    end

    def test_parse_with_long_valueless_option_with_optional_value
      input = %w[foo --aaa]
      opt_defns = [
        { long: 'aaa', short: 'a', argument: :optional },
      ].map { |hash| make_opt_defn(hash) }

      parser = Cri::Parser.new(input, opt_defns, [], false).run

      assert(parser.options[:aaa])
      assert_equal(['foo'], parser.gen_argument_list.to_a)
    end

    def test_parse_with_long_valueful_option_with_optional_value
      input = %w[foo --aaa xxx]
      opt_defns = [
        { long: 'aaa', short: 'a', argument: :optional },
      ].map { |hash| make_opt_defn(hash) }

      parser = Cri::Parser.new(input, opt_defns, [], false).run

      assert_equal({ aaa: 'xxx' }, parser.options)
      assert_equal(['foo'], parser.gen_argument_list.to_a)
    end

    def test_parse_with_long_valueless_option_with_optional_value_and_more_options
      input = %w[foo --aaa -b -c]
      opt_defns = [
        { long: 'aaa', short: 'a', argument: :optional  },
        { long: 'bbb', short: 'b', argument: :forbidden },
        { long: 'ccc', short: 'c', argument: :forbidden },
      ].map { |hash| make_opt_defn(hash) }

      parser = Cri::Parser.new(input, opt_defns, [], false).run

      assert(parser.options[:aaa])
      assert(parser.options[:bbb])
      assert(parser.options[:ccc])
      assert_equal(['foo'], parser.gen_argument_list.to_a)
    end

    def test_parse_with_short_valueless_options
      input = %w[foo -a bar]
      opt_defns = [
        { long: 'aaa', short: 'a', argument: :forbidden },
      ].map { |hash| make_opt_defn(hash) }

      parser = Cri::Parser.new(input, opt_defns, [], false).run

      assert(parser.options[:aaa])
      assert_equal(%w[foo bar], parser.gen_argument_list.to_a)
    end

    def test_parse_with_short_valueful_option_with_missing_value
      input = %w[foo -a]
      opt_defns = [
        { long: 'aaa', short: 'a', argument: :required },
      ].map { |hash| make_opt_defn(hash) }

      assert_raises(Cri::Parser::OptionRequiresAnArgumentError) do
        Cri::Parser.new(input, opt_defns, [], false).run
      end
    end

    def test_parse_with_short_combined_valueless_options
      input = %w[foo -abc bar]
      opt_defns = [
        { long: 'aaa', short: 'a', argument: :forbidden },
        { long: 'bbb', short: 'b', argument: :forbidden },
        { long: 'ccc', short: 'c', argument: :forbidden },
      ].map { |hash| make_opt_defn(hash) }

      parser = Cri::Parser.new(input, opt_defns, [], false).run

      assert(parser.options[:aaa])
      assert(parser.options[:bbb])
      assert(parser.options[:ccc])
      assert_equal(%w[foo bar], parser.gen_argument_list.to_a)
    end

    def test_parse_with_short_combined_valueful_options_with_missing_value
      input = %w[foo -abc bar qux]
      opt_defns = [
        { long: 'aaa', short: 'a', argument: :required  },
        { long: 'bbb', short: 'b', argument: :forbidden },
        { long: 'ccc', short: 'c', argument: :forbidden },
      ].map { |hash| make_opt_defn(hash) }

      parser = Cri::Parser.new(input, opt_defns, [], false).run

      assert_equal('bar', parser.options[:aaa])
      assert(parser.options[:bbb])
      assert(parser.options[:ccc])
      assert_equal(%w[foo qux], parser.gen_argument_list.to_a)
    end

    def test_parse_with_two_short_valueful_options
      input = %w[foo -a -p 2]
      opt_defns = [
        { long: 'all',  short: 'a', argument: :required },
        { long: 'port', short: 'p', argument: :required },
      ].map { |hash| make_opt_defn(hash) }

      assert_raises(Cri::Parser::OptionRequiresAnArgumentError) do
        Cri::Parser.new(input, opt_defns, [], false).run
      end
    end

    def test_parse_with_short_valueless_option_with_optional_value
      input = %w[foo -a]
      opt_defns = [
        { long: 'aaa', short: 'a', argument: :optional },
      ].map { |hash| make_opt_defn(hash) }

      parser = Cri::Parser.new(input, opt_defns, [], false).run

      assert(parser.options[:aaa])
      assert_equal(['foo'], parser.gen_argument_list.to_a)
    end

    def test_parse_with_short_valueful_option_with_optional_value
      input = %w[foo -a xxx]
      opt_defns = [
        { long: 'aaa', short: 'a', argument: :optional },
      ].map { |hash| make_opt_defn(hash) }

      parser = Cri::Parser.new(input, opt_defns, [], false).run

      assert_equal({ aaa: 'xxx' }, parser.options)
      assert_equal(['foo'], parser.gen_argument_list.to_a)
    end

    def test_parse_with_short_valueless_option_with_optional_value_and_more_options
      input = %w[foo -a -b -c]
      opt_defns = [
        { long: 'aaa', short: 'a', argument: :optional  },
        { long: 'bbb', short: 'b', argument: :forbidden },
        { long: 'ccc', short: 'c', argument: :forbidden },
      ].map { |hash| make_opt_defn(hash) }

      parser = Cri::Parser.new(input, opt_defns, [], false).run

      assert(parser.options[:aaa])
      assert(parser.options[:bbb])
      assert(parser.options[:ccc])
      assert_equal(['foo'], parser.gen_argument_list.to_a)
    end

    def test_parse_with_single_hyphen
      input = %w[foo - bar]
      opt_defns = []

      parser = Cri::Parser.new(input, opt_defns, [], false).run

      assert_equal({}, parser.options)
      assert_equal(['foo', '-', 'bar'], parser.gen_argument_list.to_a)
    end

    def test_parse_with_end_marker
      input = %w[foo bar -- -x --yyy -abc]
      opt_defns = []

      parser = Cri::Parser.new(input, opt_defns, [], false).run

      assert_equal({}, parser.options)
      assert_equal(['foo', 'bar', '-x', '--yyy', '-abc'], parser.gen_argument_list.to_a)
    end

    def test_parse_with_end_marker_between_option_key_and_value
      input = %w[foo --aaa -- zzz]
      opt_defns = [
        { long: 'aaa', short: 'a', argument: :required },
      ].map { |hash| make_opt_defn(hash) }

      assert_raises(Cri::Parser::OptionRequiresAnArgumentError) do
        Cri::Parser.new(input, opt_defns, [], false).run
      end
    end

    def test_parse_with_multiple_options
      input = %w[foo -o test -o test2 -v -v -v]
      opt_defns = [
        { long: 'long', short: 'o', argument: :required, multiple: true },
        { long: 'verbose', short: 'v', multiple: true },
      ].map { |hash| make_opt_defn(hash) }

      parser = Cri::Parser.new(input, opt_defns, [], false).run

      assert_equal(%w[test test2], parser.options[:long])
      assert_equal(3, parser.options[:verbose].size)
    end

    def test_parse_with_default_required_no_value
      input = %w[foo -a]
      opt_defns = [
        { long: 'animal', short: 'a', argument: :required, default: 'donkey' },
      ].map { |hash| make_opt_defn(hash) }

      assert_raises(Cri::Parser::OptionRequiresAnArgumentError) do
        Cri::Parser.new(input, opt_defns, [], false).run
      end
    end

    def test_parse_with_default_required_value
      input = %w[foo -a giraffe]
      opt_defns = [
        { long: 'animal', short: 'a', argument: :required, default: 'donkey' },
      ].map { |hash| make_opt_defn(hash) }

      parser = Cri::Parser.new(input, opt_defns, [], false).run

      assert_equal({ animal: 'giraffe' }, parser.options)
      assert_equal(['foo'], parser.gen_argument_list.to_a)
    end

    def test_parse_with_default_optional_no_value
      input = %w[foo -a]
      opt_defns = [
        { long: 'animal', short: 'a', argument: :optional, default: 'donkey' },
      ].map { |hash| make_opt_defn(hash) }

      parser = Cri::Parser.new(input, opt_defns, [], false).run

      assert_equal({ animal: 'donkey' }, parser.options)
      assert_equal(['foo'], parser.gen_argument_list.to_a)
    end

    def test_parse_with_default_optional_value
      input = %w[foo -a giraffe]
      opt_defns = [
        { long: 'animal', short: 'a', argument: :optional, default: 'donkey' },
      ].map { |hash| make_opt_defn(hash) }

      parser = Cri::Parser.new(input, opt_defns, [], false).run

      assert_equal({ animal: 'giraffe' }, parser.options)
      assert_equal(['foo'], parser.gen_argument_list.to_a)
    end

    def test_parse_with_default_optional_value_and_arg
      input = %w[foo -a gi raffe]
      opt_defns = [
        { long: 'animal', short: 'a', argument: :optional, default: 'donkey' },
      ].map { |hash| make_opt_defn(hash) }

      parser = Cri::Parser.new(input, opt_defns, [], false).run

      assert_equal({ animal: 'gi' }, parser.options)
      assert_equal(%w[foo raffe], parser.gen_argument_list.to_a)
    end

    def test_parse_with_combined_required_options
      input = %w[foo -abc xxx yyy zzz]
      opt_defns = [
        { long: 'aaa', short: 'a', argument: :forbidden },
        { long: 'bbb', short: 'b', argument: :required },
        { long: 'ccc', short: 'c', argument: :required },
      ].map { |hash| make_opt_defn(hash) }

      parser = Cri::Parser.new(input, opt_defns, [], false).run

      assert_equal({ aaa: true, bbb: 'xxx', ccc: 'yyy' }, parser.options)
      assert_equal(%w[foo zzz], parser.gen_argument_list.to_a)
    end

    def test_parse_with_combined_optional_options
      input = %w[foo -abc xxx yyy zzz]
      opt_defns = [
        { long: 'aaa', short: 'a', argument: :forbidden },
        { long: 'bbb', short: 'b', argument: :optional },
        { long: 'ccc', short: 'c', argument: :required },
      ].map { |hash| make_opt_defn(hash) }

      parser = Cri::Parser.new(input, opt_defns, [], false).run

      assert_equal({ aaa: true, bbb: 'xxx', ccc: 'yyy' }, parser.options)
      assert_equal(%w[foo zzz], parser.gen_argument_list.to_a)
    end

    def test_parse_with_combined_optional_options_with_missing_value
      input = %w[foo -abc xxx]
      opt_defns = [
        { long: 'aaa', short: 'a', argument: :forbidden },
        { long: 'bbb', short: 'b', argument: :required },
        { long: 'ccc', short: 'c', argument: :optional, default: 'c default' },
      ].map { |hash| make_opt_defn(hash) }

      parser = Cri::Parser.new(input, opt_defns, [], false).run

      assert_equal({ aaa: true, bbb: 'xxx', ccc: 'c default' }, parser.options)
      assert_equal(%w[foo], parser.gen_argument_list.to_a)
    end

    def test_parse_with_transform_proc
      input = %w[--port 123]
      opt_defns = [
        { long: 'port', short: 'p', argument: :required, transform: ->(x) { Integer(x) } },
      ].map { |hash| make_opt_defn(hash) }

      parser = Cri::Parser.new(input, opt_defns, [], false).run

      assert_equal({ port: 123 }, parser.options)
      assert_equal([], parser.gen_argument_list.to_a)
    end

    def test_parse_with_transform_method
      input = %w[--port 123]
      opt_defns = [
        { long: 'port', short: 'p', argument: :required, transform: method(:Integer) },
      ].map { |hash| make_opt_defn(hash) }

      parser = Cri::Parser.new(input, opt_defns, [], false).run

      assert_equal({ port: 123 }, parser.options)
      assert_equal([], parser.gen_argument_list.to_a)
    end

    def test_parse_with_transform_object
      port = Class.new do
        def call(str)
          Integer(str)
        end
      end.new

      input = %w[--port 123]
      opt_defns = [
        { long: 'port', short: 'p', argument: :required, transform: port },
      ].map { |hash| make_opt_defn(hash) }

      parser = Cri::Parser.new(input, opt_defns, [], false).run

      assert_equal({ port: 123 }, parser.options)
      assert_equal([], parser.gen_argument_list.to_a)
    end

    def test_parse_with_transform_exception
      input = %w[--port one_hundred_and_twenty_three]
      opt_defns = [
        { long: 'port', short: 'p', argument: :required, transform: method(:Integer) },
      ].map { |hash| make_opt_defn(hash) }

      exception = assert_raises(Cri::Parser::IllegalOptionValueError) do
        Cri::Parser.new(input, opt_defns, [], false).run
      end
      assert_equal('invalid value "one_hundred_and_twenty_three" for --port option', exception.message)
    end

    def test_parse_with_param_defns
      input       = %w[localhost]
      param_defns = [
        { name: 'host', transform: nil },
      ].map { |hash| Cri::ParamDefinition.new(**hash) }

      parser = Cri::Parser.new(input, [], param_defns, false).run
      assert_equal({}, parser.options)
      assert_equal('localhost', parser.gen_argument_list[0])
      assert_equal('localhost', parser.gen_argument_list[:host])
    end

    def test_parse_with_param_defns_too_few_args
      input       = []
      param_defns = [
        { name: 'host', transform: nil },
      ].map { |hash| Cri::ParamDefinition.new(**hash) }

      parser = Cri::Parser.new(input, [], param_defns, false).run
      exception = assert_raises(Cri::ArgumentList::ArgumentCountMismatchError) do
        parser.gen_argument_list
      end
      assert_equal('incorrect number of arguments given: expected 1, but got 0', exception.message)
    end

    def test_parse_with_param_defns_too_many_args
      input       = %w[localhost oink]
      param_defns = [
        { name: 'host', transform: nil },
      ].map { |hash| Cri::ParamDefinition.new(**hash) }

      parser = Cri::Parser.new(input, [], param_defns, false).run
      exception = assert_raises(Cri::ArgumentList::ArgumentCountMismatchError) do
        parser.gen_argument_list
      end
      assert_equal('incorrect number of arguments given: expected 1, but got 2', exception.message)
    end

    def test_parse_with_param_defns_invalid_key
      input       = %w[localhost]
      param_defns = [
        { name: 'host', transform: nil },
      ].map { |hash| Cri::ParamDefinition.new(**hash) }

      parser = Cri::Parser.new(input, [], param_defns, false).run

      exception = assert_raises(ArgumentError) do
        parser.gen_argument_list['oink']
      end
      assert_equal('argument lists can be indexed using a Symbol or an Integer, but not a String', exception.message)
    end

    def test_parse_with_param_defns_two_params
      input       = %w[localhost example.com]
      param_defns = [
        { name: 'source', transform: nil },
        { name: 'target', transform: nil },
      ].map { |hash| Cri::ParamDefinition.new(**hash) }

      parser = Cri::Parser.new(input, [], param_defns, false).run
      assert_equal({}, parser.options)
      assert_equal('localhost', parser.gen_argument_list[0])
      assert_equal('localhost', parser.gen_argument_list[:source])
      assert_equal('example.com', parser.gen_argument_list[1])
      assert_equal('example.com', parser.gen_argument_list[:target])
    end

    def make_opt_defn(hash)
      Cri::OptionDefinition.new(
        short: hash.fetch(:short, nil),
        long: hash.fetch(:long, nil),
        desc: hash.fetch(:desc, nil),
        argument: hash.fetch(:argument, nil),
        multiple: hash.fetch(:multiple, nil),
        block: hash.fetch(:block, nil),
        hidden: hash.fetch(:hidden, nil),
        default: hash.fetch(:default, nil),
        transform: hash.fetch(:transform, nil),
      )
    end
  end
end
