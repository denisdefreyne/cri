# encoding: utf-8

class Cri::CommandTestCase < Cri::TestCase

  def simple_cmd
    Cri::Command.define do
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
        $stdout.puts "Awesome!"

        $stdout.puts args.join(',')

        opts_strings = []
        opts.each_pair { |k,v| opts_strings << "#{k}=#{v}" }
        $stdout.puts opts_strings.join(',')
      end
    end
  end

  def test_invoke_simple_without_opts_or_args
    out, err = capture_io_while do
      simple_cmd.run(%w())
    end

    assert_equal [ 'Awesome!', '', '' ], lines(out)
    assert_equal [], lines(err)
  end

  def test_invoke_simple_with_args
    out, err = capture_io_while do
      simple_cmd.run(%w(abc xyz))
    end

    assert_equal [ 'Awesome!', 'abc,xyz', '' ], lines(out)
    assert_equal [], lines(err)
  end

  def test_invoke_simple_with_opts
    out, err = capture_io_while do
      simple_cmd.run(%w(-a -b x))
    end

    assert_equal [ 'Awesome!', '', 'aaa=true,bbb=x' ], lines(out)
    assert_equal [], lines(err)
  end

  def test_invoke_simple_with_missing_opt_arg
    out, err = capture_io_while do
      assert_raises SystemExit do
        simple_cmd.run(%w( -b ))
      end
    end

    assert_equal "", out
    assert_equal "option requires an argument -- b\n", err
  end

end
