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
    assert_equal 'does stuff', command.summary
    assert_equal 'This command does a lot of stuff.', command.description

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

  def test_subcommand
    # Define
    dsl = Cri::CommandDSL.new
    dsl.instance_eval do
      name 'super'
      subcommand do |c|
        c.name 'sub'
      end
    end
    command = dsl.command

    # Check
    assert_equal 'super', command.name
    assert_equal 1,       command.subcommands.size
    assert_equal 'sub',   command.subcommands.to_a[0].name
  end

  def test_aliases
    # Define
    dsl = Cri::CommandDSL.new
    dsl.instance_eval do
      aliases :moo, :aah
    end
    command = dsl.command

    # Check
    assert_equal %w( aah moo ), command.aliases.sort
  end

  def test_runner
    # Define
    dsl = Cri::CommandDSL.new
    dsl.instance_eval <<-EOS
      class Cri::CommandDSLTestCaseCommandRunner < Cri::CommandRunner
        def run
          $works = arguments[0]
        end
      end

      runner Cri::CommandDSLTestCaseCommandRunner
EOS
    command = dsl.command

    # Check
    $works = false
    command.run(%w( certainly ))
    assert_equal 'certainly', $works
  end

end
