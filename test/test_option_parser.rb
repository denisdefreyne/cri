class Cri::OptionParserTest < MiniTest::Unit::TestCase

  def test_parse_without_options
    input       = %w( foo bar baz )
    definitions = []

    result = nil

    result = Cri::OptionParser.parse(input, definitions)

    assert_equal({},                      result[:options])
    assert_equal([ 'foo', 'bar', 'baz' ], result[:arguments])
  end

  def test_parse_without_options
    input       = %w( foo -x )
    definitions = []

    result = nil

    assert_raises(Cri::OptionParser::IllegalOptionError) do
      result = Cri::OptionParser.parse(input, definitions)
    end
  end

  def test_parse_with_long_valueless_option
    input       = %w( foo --aaa bar )
    definitions = [
      { :long => 'aaa', :short => 'a', :argument => :forbidden }
    ]

    result = nil

    result = Cri::OptionParser.parse(input, definitions)

    assert_equal({ :aaa => nil },  result[:options])
    assert_equal([ 'foo', 'bar' ], result[:arguments])
  end

  def test_parse_with_long_valueful_option
    input       = %w( foo --aaa xxx bar )
    definitions = [
      { :long => 'aaa', :short => 'a', :argument => :required }
    ]

    result = nil

    result = Cri::OptionParser.parse(input, definitions)

    assert_equal({ :aaa => 'xxx' },  result[:options])
    assert_equal([ 'foo', 'bar' ], result[:arguments])
  end

  def test_parse_with_long_valueful_equalsign_option
    input       = %w( foo --aaa=xxx bar )
    definitions = [
      { :long => 'aaa', :short => 'a', :argument => :required }
    ]

    result = nil

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

  def test_parse_with_short_valueless_options
    input       = %w( foo -a bar )
    definitions = [
      { :long => 'aaa', :short => 'a', :argument => :forbidden }
    ]

    result = nil

    result = Cri::OptionParser.parse(input, definitions)

    assert_equal({ :aaa => nil },  result[:options])
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

    result = nil

    result = Cri::OptionParser.parse(input, definitions)

    assert_equal({ :aaa => nil, :bbb => nil, :ccc => nil },  result[:options])
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

  def test_parse_with_end_marker
    input       = %w( foo bar -- -x --yyy -abc )
    definitions = []

    result = nil

    result = Cri::OptionParser.parse(input, definitions)

    assert_equal({},                                      result[:options])
    assert_equal([ 'foo', 'bar', '-x', '--yyy', '-abc' ], result[:arguments])
  end

end
