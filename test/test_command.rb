# encoding: utf-8

class Cri::CommandTestCase < Cri::TestCase

  def simple_cmd
    Cri::Command.define do
      name        'moo'
      usage       'dunno whatever'
      summary     'does stuff'
      description 'This command does a lot of stuff.'

      option    :a, :aaa, 'opt a', :argument => :optional do |value, cmd|
        $stdout.puts "#{cmd.name}:#{value}"
      end
      required  :b, :bbb, 'opt b'
      optional  :c, :ccc, 'opt c'
      flag      :d, :ddd, 'opt d'
      forbidden :e, :eee, 'opt e'

      run do |opts, args, c|
        $stdout.puts "Awesome #{c.name}!"

        $stdout.puts args.join(',')

        opts_strings = []
        opts.each_pair { |k,v| opts_strings << "#{k}=#{v}" }
        $stdout.puts opts_strings.sort.join(',')
      end
    end
  end

  def bare_cmd
    Cri::Command.define do
      name        'moo'

      run do |opts, args|
      end
    end
  end

  def nested_cmd
    super_cmd = Cri::Command.define do
      name        'super'
      usage       'super [command] [options] [arguments]'
      summary     'does super stuff'
      description 'This command does super stuff.'

      option    :a, :aaa, 'opt a', :argument => :optional do |value, cmd|
        $stdout.puts "#{cmd.name}:#{value}"
      end
      required  :b, :bbb, 'opt b'
      optional  :c, :ccc, 'opt c'
      flag      :d, :ddd, 'opt d'
      forbidden :e, :eee, 'opt e'
    end

    super_cmd.define_command do
      name        'sub'
      aliases     'sup'
      usage       'sub [options]'
      summary     'does subby stuff'
      description 'This command does subby stuff.'

      option    :m, :mmm, 'opt m', :argument => :optional
      required  :n, :nnn, 'opt n'
      optional  :o, :ooo, 'opt o'
      flag      :p, :ppp, 'opt p'
      forbidden :q, :qqq, 'opt q'

      run do |opts, args|
        $stdout.puts "Sub-awesome!"

        $stdout.puts args.join(',')

        opts_strings = []
        opts.each_pair { |k,v| opts_strings << "#{k}=#{v}" }
        $stdout.puts opts_strings.join(',')
      end
    end

    super_cmd.define_command do
      name        'sink'
      usage       'sink thing_to_sink'
      summary     'sinks stuff'
      description 'Sinks stuff (like ships and the like).'

      run do |opts, args|
        $stdout.puts "Sinking!"
      end
    end

    super_cmd
  end

  def test_invoke_simple_without_opts_or_args
    out, err = capture_io_while do
      simple_cmd.run(%w())
    end

    assert_equal [ 'Awesome moo!', '', '' ], lines(out)
    assert_equal [], lines(err)
  end

  def test_invoke_simple_with_args
    out, err = capture_io_while do
      simple_cmd.run(%w(abc xyz))
    end

    assert_equal [ 'Awesome moo!', 'abc,xyz', '' ], lines(out)
    assert_equal [], lines(err)
  end

  def test_invoke_simple_with_opts
    out, err = capture_io_while do
      simple_cmd.run(%w(-c -b x))
    end

    assert_equal [ 'Awesome moo!', '', 'bbb=x,ccc=true' ], lines(out)
    assert_equal [], lines(err)
  end

  def test_invoke_simple_with_missing_opt_arg
    out, err = capture_io_while do
      assert_raises SystemExit do
        simple_cmd.run(%w( -b ))
      end
    end

    assert_equal [], lines(out)
    assert_equal [ "moo: option requires an argument -- b" ], lines(err)
  end

  def test_invoke_simple_with_illegal_opt
    out, err = capture_io_while do
      assert_raises SystemExit do
        simple_cmd.run(%w( -z ))
      end
    end

    assert_equal [], lines(out)
    assert_equal [ "moo: illegal option -- z" ], lines(err)
  end

  def test_invoke_simple_with_opt_with_block
    out, err = capture_io_while do
      simple_cmd.run(%w( -a 123 ))
    end

    assert_equal [ 'moo:123', 'Awesome moo!', '', 'aaa=123' ], lines(out)
    assert_equal [], lines(err)
  end

  def test_invoke_nested_without_opts_or_args
    out, err = capture_io_while do
      assert_raises SystemExit do
        nested_cmd.run(%w())
      end
    end

    assert_equal [ ], lines(out)
    assert_equal [ 'super: no command given' ], lines(err)
  end

  def test_invoke_nested_with_correct_command_name
    out, err = capture_io_while do
      nested_cmd.run(%w( sub ))
    end

    assert_equal [ 'Sub-awesome!', '', '' ], lines(out)
    assert_equal [ ], lines(err)
  end

  def test_invoke_nested_with_incorrect_command_name
    out, err = capture_io_while do
      assert_raises SystemExit do
        nested_cmd.run(%w( oogabooga ))
      end
    end

    assert_equal [ ], lines(out)
    assert_equal [ "super: unknown command 'oogabooga'" ], lines(err)
  end

  def test_invoke_nested_with_ambiguous_command_name
    out, err = capture_io_while do
      assert_raises SystemExit do
        nested_cmd.run(%w( s ))
      end
    end

    assert_equal [ ], lines(out)
    assert_equal [ "super: 's' is ambiguous:", "  sink sub" ], lines(err)
  end

  def test_invoke_nested_with_alias
    out, err = capture_io_while do
      nested_cmd.run(%w( sup ))
    end

    assert_equal [ 'Sub-awesome!', '', '' ], lines(out)
    assert_equal [ ], lines(err)
  end

  def test_invoke_nested_with_options_before_command
    out, err = capture_io_while do
      nested_cmd.run(%w( -a 666 sub ))
    end

    assert_equal [ 'super:666', 'Sub-awesome!', '', 'aaa=666' ], lines(out)
    assert_equal [ ], lines(err)
  end

  def test_help_nested
    help = nested_cmd.subcommands.find { |cmd| cmd.name == 'sub' }.help

    assert_match /^usage: super sub \[options\]/, help
  end

  def test_help_for_bare_cmd
    bare_cmd.help
  end

  def test_modify_with_block_argument
    cmd = Cri::Command.define do |c|
      c.name 'build'
    end
    assert_equal 'build', cmd.name

    cmd.modify do |c|
      c.name 'compile'
    end

    assert_equal 'compile', cmd.name
  end

  def test_modify_without_block_argument
    cmd = Cri::Command.define do
      name 'build'
    end
    assert_equal 'build', cmd.name

    cmd.modify do
      name 'compile'
    end

    assert_equal 'compile', cmd.name
  end

  def test_new_basic_root
    cmd = Cri::Command.new_basic_root.modify do
      name 'mytool'
    end

    # Check option definitions
    assert_equal 1, cmd.option_definitions.size
    opt_def = cmd.option_definitions.to_a[0]
    assert_equal 'help', opt_def[:long]

    # Check subcommand
    assert_equal 1,      cmd.subcommands.size
    assert_equal 'help', cmd.subcommands.to_a[0].name
  end

  def test_define_with_block_argument
    cmd = Cri::Command.define do |c|
      c.name 'moo'
    end

    assert_equal 'moo', cmd.name
  end

  def test_define_without_block_argument
    cmd = Cri::Command.define do
      name 'moo'
    end

    assert_equal 'moo', cmd.name
  end

  def test_define_subcommand_with_block_argument
    cmd = bare_cmd
    cmd.define_command do |c|
      c.name 'baresub'
    end

    assert_equal 'baresub', cmd.subcommands.to_a[0].name
  end

  def test_define_subcommand_without_block_argument
    cmd = bare_cmd
    cmd.define_command do
      name 'baresub'
    end

    assert_equal 'baresub', cmd.subcommands.to_a[0].name
  end

  def test_backtrace_includes_filename
    error = assert_raises RuntimeError do
      Cri::Command.define('raise "boom"', 'mycommand.rb')
    end

    assert_match /mycommand.rb/, error.backtrace.join("\n")
  end

end
