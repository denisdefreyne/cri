# encoding: utf-8

class Cri::CommandTestCase < Cri::TestCase

  def simple_cmd
    Cri::Command.define do
      name        'moo'
      usage       'dunno whatever'
      summary     'does stuff'
      description 'This command does a lot of stuff.'

      option    :a, :aaa, 'opt a', :argument => :optional do |value|
        $stdout.puts "#{name}:#{value}"
      end
      required  :b, :bbb, 'opt b'
      optional  :c, :ccc, 'opt c'
      flag      :d, :ddd, 'opt d'
      forbidden :e, :eee, 'opt e'

      run do |opts, args|
        $stdout.puts "Awesome #{name}!"

        $stdout.puts args.join(',')

        opts_strings = []
        opts.each_pair { |k,v| opts_strings << "#{k}=#{v}" }
        $stdout.puts opts_strings.join(',')
      end
    end
  end

  def nested_cmd
    super_cmd = Cri::Command.define do
      name        'super'
      usage       'does something super'
      summary     'does super stuff'
      description 'This command does super stuff.'

      option    :a, :aaa, 'opt a', :argument => :optional do |value|
        $stdout.puts "#{name}:#{value}"
      end
      required  :b, :bbb, 'opt b'
      optional  :c, :ccc, 'opt c'
      flag      :d, :ddd, 'opt d'
      forbidden :e, :eee, 'opt e'
    end

    super_cmd.define_command do
      name        'sub'
      aliases     'sup'
      usage       'does something subby'
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

  def test_modify
    cmd = Cri::Command.define do
      name 'build'
    end
    assert_equal 'build', cmd.name

    cmd.modify do
      name 'compile'
    end

    assert_equal 'compile', cmd.name
  end

end
