# encoding: utf-8

class Cri::CommandDSLTestCase < Cri::TestCase

  def test_create_command
    # Define
    dsl = Cri::CommandDSL.new
    dsl.instance_eval do
      name        'moo'
      usage       'dunno whatever'
      summary     'does stuff'
      description 'This command does a lot of stuff.'

      option    :a, :aaa, 'opt a', :argument => :optional
      required  :b, :bbb, 'opt b'
      optional  :c, :ccc, 'opt c'
      flag      :d, :ddd, 'opt d'
      forbidden :e, :eee, 'opt e'

      run do |opts, args|
        $did_it_work = :probably
      end
    end
    command = dsl.command

    # Run
    $did_it_work = :sadly_not
    command.run(%w( -a x -b y -c -d -e ))
    assert_equal :probably, $did_it_work

    # Check
    assert_equal 'moo', command.name
    assert_equal 'dunno whatever', command.usage
    assert_equal 'does stuff', command.short_desc
    assert_equal 'This command does a lot of stuff.', command.long_desc

    # Check options
    expected_option_definitions = Set.new([
      { :short => 'a', :long => 'aaa', :desc => 'opt a', :argument => :optional,  :block => nil },
      { :short => 'b', :long => 'bbb', :desc => 'opt b', :argument => :required,  :block => nil },
      { :short => 'c', :long => 'ccc', :desc => 'opt c', :argument => :optional,  :block => nil },
      { :short => 'd', :long => 'ddd', :desc => 'opt d', :argument => :forbidden, :block => nil },
      { :short => 'e', :long => 'eee', :desc => 'opt e', :argument => :forbidden, :block => nil }
      ])
    actual_option_definitions = Set.new(command.option_definitions)
    assert_equal expected_option_definitions, actual_option_definitions
  end

end
