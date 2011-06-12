class Cri::BaseTest < MiniTest::Unit::TestCase

  def test_define_command
    # Define
    base = Cri::Base.new('sample')
    command = base.define_command('moo') do
      usage      'dunno whatever'
      short_desc 'does stuff'
      long_desc  'This command does a lot of stuff.'

      option    :a, :aaa, 'opt a', :argument => :optional
      required  :b, :bbb, 'opt b'
      optional  :c, :ccc, 'opt c'
      flag      :d, :ddd, 'opt d'
      forbidden :e, :eee, 'opt e'

      run do |args, definitions|
        $did_it_work = :probably
      end
    end

    # Run
    $did_it_work = :sadly_not
    command.run([], [])
    assert_equal :probably, $did_it_work

    # Check
    found_command = base.command_named('moo')
    assert_equal command, found_command
    refute command.nil?
    assert_equal 'moo', command.name
    assert_equal 'dunno whatever', command.usage
    assert_equal 'does stuff', command.short_desc
    assert_equal 'This command does a lot of stuff.', command.long_desc

    # Check options
    require 'set'
    expected_option_definitions = Set.new([
        { :short => :a, :long => :aaa, :desc => 'opt a', :argument => :optional  },
        { :short => :b, :long => :bbb, :desc => 'opt b', :argument => :required  },
        { :short => :c, :long => :ccc, :desc => 'opt c', :argument => :optional  },
        { :short => :d, :long => :ddd, :desc => 'opt d', :argument => :forbidden },
        { :short => :e, :long => :eee, :desc => 'opt e', :argument => :forbidden }
      ])
    actual_option_definitions = Set.new(command.option_definitions)
    assert_equal expected_option_definitions, actual_option_definitions
  end

end
