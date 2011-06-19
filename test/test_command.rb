# encoding: utf-8

class Cri::CommandTestCase < Cri::TestCase

  def simple_cmd
    Cri::Command.define do |c|
      c.name        'moo'
      c.usage       'dunno whatever'
      c.summary     'does stuff'
      c.description 'This command does a lot of stuff.'

      c.option    :a, :aaa, 'opt a', :argument => :optional do |value, cmd|
        $stdout.puts "#{cmd.name}:#{value}"
      end
      c.required  :b, :bbb, 'opt b'
      c.optional  :c, :ccc, 'opt c'
      c.flag      :d, :ddd, 'opt d'
      c.forbidden :e, :eee, 'opt e'

      c.run do |opts, args, c|
        $stdout.puts "Awesome #{c.name}!"

        $stdout.puts args.join(',')

        opts_strings = []
        opts.each_pair { |k,v| opts_strings << "#{k}=#{v}" }
        $stdout.puts opts_strings.join(',')
      end
    end
  end

  def bare_cmd
    Cri::Command.define do |c|
      c.name        'moo'

      c.run do |opts, args|
      end
    end
  end

  def nested_cmd
    super_cmd = Cri::Command.define do |c|
      c.name        'super'
      c.usage       'super [command] [options] [arguments]'
      c.summary     'does super stuff'
      c.description 'This command does super stuff.'

      c.option    :a, :aaa, 'opt a', :argument => :optional do |value, cmd|
        $stdout.puts "#{cmd.name}:#{value}"
      end
      c.required  :b, :bbb, 'opt b'
      c.optional  :c, :ccc, 'opt c'
      c.flag      :d, :ddd, 'opt d'
      c.forbidden :e, :eee, 'opt e'
    end

    super_cmd.define_command do |c|
      c.name        'sub'
      c.aliases     'sup'
      c.usage       'sub [options]'
      c.summary     'does subby stuff'
      c.description 'This command does subby stuff.'

      c.option    :m, :mmm, 'opt m', :argument => :optional
      c.required  :n, :nnn, 'opt n'
      c.optional  :o, :ooo, 'opt o'
      c.flag      :p, :ppp, 'opt p'
      c.forbidden :q, :qqq, 'opt q'

      c.run do |opts, args|
        $stdout.puts "Sub-awesome!"

        $stdout.puts args.join(',')

        opts_strings = []
        opts.each_pair { |k,v| opts_strings << "#{k}=#{v}" }
        $stdout.puts opts_strings.join(',')
      end
    end

    super_cmd.define_command do |c|
      c.name        'sink'
      c.usage       'sink thing_to_sink'
      c.summary     'sinks stuff'
      c.description 'Sinks stuff (like ships and the like).'

      c.run do |opts, args|
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

    assert_equal [ 'Awesome moo!', '', 'ccc=true,bbb=x' ], lines(out)
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
    assert_equal [ "super: 's' is ambiguous:", "  sub sink" ], lines(err)
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
    help = nested_cmd.subcommands.to_a[0].help

    assert_match /^usage: super sub \[options\]/, help
  end

  def test_help_for_bare_cmd
    bare_cmd.help
  end

  def test_modify
    cmd = Cri::Command.define do |c|
      c.name 'build'
    end
    assert_equal 'build', cmd.name

    cmd.modify do |c|
      c.name 'compile'
    end

    assert_equal 'compile', cmd.name
  end

  def test_new_basic_root
    cmd = Cri::Command.new_basic_root.modify do |c|
      c.name 'mytool'
    end

    # Check option definitions
    assert_equal 1, cmd.option_definitions.size
    opt_def = cmd.option_definitions.to_a[0]
    assert_equal 'help', opt_def[:long]

    # Check subcommand
    assert_equal 1,      cmd.subcommands.size
    assert_equal 'help', cmd.subcommands.to_a[0].name
  end

end
