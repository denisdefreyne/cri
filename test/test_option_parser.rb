class Cri::OptionParserTest < MiniTest::Unit::TestCase

  def test_parse_without_options
    input       = %w( foo bar baz )
    definitions = []

    result = Cri::OptionParser.parse(input, definitions)

    assert_equal({},                      result[:options])
    assert_equal([ 'foo', 'bar', 'baz' ], result[:arguments])
  end

  def test_parse_with_invalid_option
    input       = %w( foo -x )
    definitions = []

    result = nil

    assert_raises(Cri::OptionParser::IllegalOptionError) do
      result = Cri::OptionParser.parse(input, definitions)
    end
  end

  def test_parse_without_options
    input       = %w( foo )
    definitions = [
      { :long => 'aaa', :short => 'a', :argument => :forbidden }
    ]

    result = Cri::OptionParser.parse(input, definitions)

    assert(!result[:options][:aaa])
  end

  def test_parse_with_long_valueless_option
    input       = %w( foo --aaa bar )
    definitions = [
      { :long => 'aaa', :short => 'a', :argument => :forbidden }
    ]

    result = Cri::OptionParser.parse(input, definitions)

    assert(result[:options][:aaa])
    assert_equal([ 'foo', 'bar' ], result[:arguments])
  end

  def test_parse_with_long_valueful_option
    input       = %w( foo --aaa xxx bar )
    definitions = [
      { :long => 'aaa', :short => 'a', :argument => :required }
    ]

    result = Cri::OptionParser.parse(input, definitions)

    assert_equal({ :aaa => 'xxx' },  result[:options])
    assert_equal([ 'foo', 'bar' ], result[:arguments])
  end

  def test_parse_with_long_valueful_equalsign_option
    input       = %w( foo --aaa=xxx bar )
    definitions = [
      { :long => 'aaa', :short => 'a', :argument => :required }
    ]

    result = Cri::OptionParser.parse(input, definitions)

    assert_equal({ :aaa => 'xxx' },  result[:options])
    assert_equal([ 'foo', 'bar' ], result[:arguments])
  end

  def test_parse_with_long_valueful_option_with_missing_value
    input       = %w( foo --aaa )
    definitions = [
      { :long => 'aaa', :short => 'a', :argument => :required }
    ]

    result = nil

    assert_raises(Cri::OptionParser::OptionRequiresAnArgumentError) do
      result = Cri::OptionParser.parse(input, definitions)
    end
  end

  def test_parse_with_two_long_valueful_options
    input       = %w( foo --all --port 2 )
    definitions = [
      { :long => 'all',  :short => 'a', :argument => :required  },
      { :long => 'port', :short => 'p', :argument => :required }
    ]

    result = nil

    assert_raises(Cri::OptionParser::OptionRequiresAnArgumentError) do
      result = Cri::OptionParser.parse(input, definitions)
    end
  end

  def test_parse_with_long_valueless_option_with_optional_value
    input       = %w( foo --aaa )
    definitions = [
      { :long => 'aaa', :short => 'a', :argument => :optional }
    ]

    result = Cri::OptionParser.parse(input, definitions)

    assert(result[:options][:aaa])
    assert_equal([ 'foo' ], result[:arguments])
  end

  def test_parse_with_long_valueful_option_with_optional_value
    input       = %w( foo --aaa xxx )
    definitions = [
      { :long => 'aaa', :short => 'a', :argument => :optional }
    ]

    result = Cri::OptionParser.parse(input, definitions)

    assert_equal({ :aaa => 'xxx' },  result[:options])
    assert_equal([ 'foo' ], result[:arguments])
  end

  def test_parse_with_long_valueless_option_with_optional_value_and_more_options
    input       = %w( foo --aaa -b -c )
    definitions = [
      { :long => 'aaa', :short => 'a', :argument => :optional  },
      { :long => 'bbb', :short => 'b', :argument => :forbidden },
      { :long => 'ccc', :short => 'c', :argument => :forbidden }
    ]

    result = Cri::OptionParser.parse(input, definitions)

    assert(result[:options][:aaa])
    assert(result[:options][:bbb])
    assert(result[:options][:ccc])
    assert_equal([ 'foo' ], result[:arguments])
  end

  def test_parse_with_short_valueless_options
    input       = %w( foo -a bar )
    definitions = [
      { :long => 'aaa', :short => 'a', :argument => :forbidden }
    ]

    result = Cri::OptionParser.parse(input, definitions)

    assert(result[:options][:aaa])
    assert_equal([ 'foo', 'bar' ], result[:arguments])
  end

  def test_parse_with_short_valueful_option_with_missing_value
    input       = %w( foo -a )
    definitions = [
      { :long => 'aaa', :short => 'a', :argument => :required }
    ]

    result = nil

    assert_raises(Cri::OptionParser::OptionRequiresAnArgumentError) do
      result = Cri::OptionParser.parse(input, definitions)
    end
  end

  def test_parse_with_short_combined_valueless_options
    input       = %w( foo -abc bar )
    definitions = [
      { :long => 'aaa', :short => 'a', :argument => :forbidden },
      { :long => 'bbb', :short => 'b', :argument => :forbidden },
      { :long => 'ccc', :short => 'c', :argument => :forbidden }
    ]

    result = Cri::OptionParser.parse(input, definitions)

    assert(result[:options][:aaa])
    assert(result[:options][:bbb])
    assert(result[:options][:ccc])
    assert_equal([ 'foo', 'bar' ], result[:arguments])
  end

  def test_parse_with_short_combined_valueful_options_with_missing_value
    input       = %w( foo -abc bar )
    definitions = [
      { :long => 'aaa', :short => 'a', :argument => :required  },
      { :long => 'bbb', :short => 'b', :argument => :forbidden },
      { :long => 'ccc', :short => 'c', :argument => :forbidden }
    ]

    result = nil

    assert_raises(Cri::OptionParser::OptionRequiresAnArgumentError) do
      result = Cri::OptionParser.parse(input, definitions)
    end
  end

  def test_parse_with_two_short_valueful_options
    input       = %w( foo -a -p 2 )
    definitions = [
      { :long => 'all',  :short => 'a', :argument => :required  },
      { :long => 'port', :short => 'p', :argument => :required }
    ]

    result = nil

    assert_raises(Cri::OptionParser::OptionRequiresAnArgumentError) do
      result = Cri::OptionParser.parse(input, definitions)
    end
  end

  def test_parse_with_short_valueless_option_with_optional_value
    input       = %w( foo -a )
    definitions = [
      { :long => 'aaa', :short => 'a', :argument => :optional }
    ]

    result = Cri::OptionParser.parse(input, definitions)

    assert(result[:options][:aaa])
    assert_equal([ 'foo' ], result[:arguments])
  end

  def test_parse_with_short_valueful_option_with_optional_value
    input       = %w( foo -a xxx )
    definitions = [
      { :long => 'aaa', :short => 'a', :argument => :optional }
    ]

    result = Cri::OptionParser.parse(input, definitions)

    assert_equal({ :aaa => 'xxx' },  result[:options])
    assert_equal([ 'foo' ], result[:arguments])
  end

  def test_parse_with_short_valueless_option_with_optional_value_and_more_options
    input       = %w( foo -a -b -c )
    definitions = [
      { :long => 'aaa', :short => 'a', :argument => :optional  },
      { :long => 'bbb', :short => 'b', :argument => :forbidden },
      { :long => 'ccc', :short => 'c', :argument => :forbidden }
    ]

    result = Cri::OptionParser.parse(input, definitions)

    assert(result[:options][:aaa])
    assert(result[:options][:bbb])
    assert(result[:options][:ccc])
    assert_equal([ 'foo' ], result[:arguments])
  end

  def test_parse_with_end_marker
    input       = %w( foo bar -- -x --yyy -abc )
    definitions = []

    result = Cri::OptionParser.parse(input, definitions)

    assert_equal({},                                      result[:options])
    assert_equal([ 'foo', 'bar', '-x', '--yyy', '-abc' ], result[:arguments])
  end

  def test_parse_with_end_marker_between_option_key_and_value
    input       = %w( foo --aaa -- zzz )
    definitions = [
      { :long => 'aaa', :short => 'a', :argument => :required }
    ]

    assert_raises(Cri::OptionParser::OptionRequiresAnArgumentError) do
      result = Cri::OptionParser.parse(input, definitions)
    end
  end

end
