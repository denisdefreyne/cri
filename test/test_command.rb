# frozen_string_literal: true

require 'helper'

module Cri
  class CommandTestCase < Cri::TestCase
    def simple_cmd
      Cri::Command.define do
        name        'moo'
        usage       'moo [options] arg1 arg2 ...'
        summary     'does stuff'
        description 'This command does a lot of stuff.'

        option :a, :aaa, 'opt a', argument: :optional do |value, cmd|
          $stdout.puts "#{cmd.name}:#{value}"
        end
        required  :b, :bbb, 'opt b'
        optional  :c, :ccc, 'opt c'
        flag      :d, :ddd, 'opt d'
        forbidden :e, :eee, 'opt e'
        required  :t, :transform, 'opt t', transform: method(:Integer)

        run do |opts, args, c|
          $stdout.puts "Awesome #{c.name}!"

          $stdout.puts args.join(',')

          opts_strings = []
          opts.each_pair { |k, v| opts_strings << "#{k}=#{v}" }
          $stdout.puts opts_strings.sort.join(',')
        end
      end
    end

    def bare_cmd
      Cri::Command.define do
        name 'moo'

        run do |_opts, _args|
        end
      end
    end

    def nested_cmd
      super_cmd = Cri::Command.define do
        name        'super'
        usage       'super [command] [options] [arguments]'
        summary     'does super stuff'
        description 'This command does super stuff.'

        option :a, :aaa, 'opt a', argument: :optional do |value, cmd|
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

        option    :m, :mmm, 'opt m', argument: :optional
        required  :n, :nnn, 'opt n'
        optional  :o, :ooo, 'opt o'
        flag      :p, :ppp, 'opt p'
        forbidden :q, :qqq, 'opt q'

        run do |opts, args|
          $stdout.puts 'Sub-awesome!'

          $stdout.puts args.join(',')

          opts_strings = []
          opts.each_pair { |k, v| opts_strings << "#{k}=#{v}" }
          $stdout.puts opts_strings.join(',')
        end
      end

      super_cmd.define_command do
        name        'sink'
        usage       'sink thing_to_sink'
        summary     'sinks stuff'
        description 'Sinks stuff (like ships and the like).'

        run do |_opts, _args|
        end
      end

      super_cmd
    end

    def nested_cmd_with_run_block
      super_cmd = Cri::Command.define do
        name        'super'
        usage       'super [command] [options] [arguments]'
        summary     'does super stuff'
        description 'This command does super stuff.'

        run do |_opts, _args|
          $stdout.puts 'super'
        end
      end

      super_cmd.define_command do
        name        'sub'
        aliases     'sup'
        usage       'sub [options]'
        summary     'does subby stuff'
        description 'This command does subby stuff.'

        run do |_opts, _args|
          $stdout.puts 'sub'
        end
      end

      super_cmd
    end

    def test_invoke_simple_without_opts_or_args
      out, err = capture_io_while do
        simple_cmd.run(%w[])
      end

      assert_equal ['Awesome moo!', '', ''], lines(out)
      assert_equal [], lines(err)
    end

    def test_invoke_simple_with_args
      out, err = capture_io_while do
        simple_cmd.run(%w[abc xyz])
      end

      assert_equal ['Awesome moo!', 'abc,xyz', ''], lines(out)
      assert_equal [], lines(err)
    end

    def test_invoke_simple_with_opts
      out, err = capture_io_while do
        simple_cmd.run(%w[-c -b x])
      end

      assert_equal ['Awesome moo!', '', 'bbb=x,ccc=true'], lines(out)
      assert_equal [], lines(err)
    end

    def test_invoke_simple_with_missing_opt_arg
      out, err = capture_io_while do
        err = assert_raises SystemExit do
          simple_cmd.run(%w[-b])
        end
        assert_equal 1, err.status
      end

      assert_equal [], lines(out)
      assert_equal ['moo: option requires an argument -- b'], lines(err)
    end

    def test_invoke_simple_with_missing_opt_arg_no_exit
      out, err = capture_io_while do
        simple_cmd.run(%w[-b], {}, hard_exit: false)
      end

      assert_equal [], lines(out)
      assert_equal ['moo: option requires an argument -- b'], lines(err)
    end

    def test_invoke_simple_with_illegal_opt
      out, err = capture_io_while do
        err = assert_raises SystemExit do
          simple_cmd.run(%w[-z])
        end
        assert_equal 1, err.status
      end

      assert_equal [], lines(out)
      assert_equal ['moo: unrecognised option -- z'], lines(err)
    end

    def test_invoke_simple_with_illegal_opt_no_exit
      out, err = capture_io_while do
        simple_cmd.run(%w[-z], {}, hard_exit: false)
      end

      assert_equal [], lines(out)
      assert_equal ['moo: unrecognised option -- z'], lines(err)
    end

    def test_invoke_simple_with_invalid_value_for_opt
      out, err = capture_io_while do
        err = assert_raises SystemExit do
          simple_cmd.run(%w[-t nope])
        end
        assert_equal 1, err.status
      end

      assert_equal [], lines(out)
      assert_equal ['moo: invalid value "nope" for --transform option'], lines(err)
    end

    def test_invoke_simple_with_invalid_value_for_opt_no_exit
      out, err = capture_io_while do
        simple_cmd.run(%w[-t nope], {}, hard_exit: false)
      end

      assert_equal [], lines(out)
      assert_equal ['moo: invalid value "nope" for --transform option'], lines(err)
    end

    def test_invoke_simple_with_opt_with_block
      out, err = capture_io_while do
        simple_cmd.run(%w[-a 123])
      end

      assert_equal ['moo:123', 'Awesome moo!', '', 'aaa=123'], lines(out)
      assert_equal [], lines(err)
    end

    def test_invoke_nested_without_opts_or_args
      out, err = capture_io_while do
        err = assert_raises SystemExit do
          nested_cmd.run(%w[])
        end
        assert_equal 1, err.status
      end

      assert_equal [], lines(out)
      assert_equal ['super: no command given'], lines(err)
    end

    def test_invoke_nested_without_opts_or_args_no_exit
      out, err = capture_io_while do
        nested_cmd.run(%w[], {}, hard_exit: false)
      end

      assert_equal [], lines(out)
      assert_equal ['super: no command given'], lines(err)
    end

    def test_invoke_nested_with_correct_command_name
      out, err = capture_io_while do
        nested_cmd.run(%w[sub])
      end

      assert_equal ['Sub-awesome!', '', ''], lines(out)
      assert_equal [], lines(err)
    end

    def test_invoke_nested_with_incorrect_command_name
      out, err = capture_io_while do
        err = assert_raises SystemExit do
          nested_cmd.run(%w[oogabooga])
        end
        assert_equal 1, err.status
      end

      assert_equal [], lines(out)
      assert_equal ["super: unknown command 'oogabooga'"], lines(err)
    end

    def test_invoke_nested_with_incorrect_command_name_no_exit
      out, err = capture_io_while do
        nested_cmd.run(%w[oogabooga], {}, hard_exit: false)
      end

      assert_equal [], lines(out)
      assert_equal ["super: unknown command 'oogabooga'"], lines(err)
    end

    def test_invoke_nested_with_ambiguous_command_name
      out, err = capture_io_while do
        err = assert_raises SystemExit do
          nested_cmd.run(%w[s])
        end
        assert_equal 1, err.status
      end

      assert_equal [], lines(out)
      assert_equal ["super: 's' is ambiguous:", '  sink sub'], lines(err)
    end

    def test_invoke_nested_with_ambiguous_command_name_no_exit
      out, err = capture_io_while do
        nested_cmd.run(%w[s], {}, hard_exit: false)
      end

      assert_equal [], lines(out)
      assert_equal ["super: 's' is ambiguous:", '  sink sub'], lines(err)
    end

    def test_invoke_nested_with_alias
      out, err = capture_io_while do
        nested_cmd.run(%w[sup])
      end

      assert_equal ['Sub-awesome!', '', ''], lines(out)
      assert_equal [], lines(err)
    end

    def test_invoke_nested_with_options_before_command
      out, err = capture_io_while do
        nested_cmd.run(%w[-a 666 sub])
      end

      assert_equal ['super:666', 'Sub-awesome!', '', 'aaa=666'], lines(out)
      assert_equal [], lines(err)
    end

    def test_invoke_nested_with_run_block
      out, err = capture_io_while do
        nested_cmd_with_run_block.run(%w[])
      end

      assert_equal ['super'], lines(out)
      assert_equal [], lines(err)

      out, err = capture_io_while do
        nested_cmd_with_run_block.run(%w[sub])
      end

      assert_equal ['sub'], lines(out)
      assert_equal [], lines(err)
    end

    def test_help_nested
      def $stdout.tty?
        true
      end

      help = nested_cmd.subcommands.find { |cmd| cmd.name == 'sub' }.help

      assert help.include?("USAGE\e[0m\e[0m\n    \e[32msuper\e[0m \e[32msub\e[0m [options]\n")
    end

    def test_help_with_and_without_colors
      def $stdout.tty?
        true
      end
      help_on_tty = simple_cmd.help
      def $stdout.tty?
        false
      end
      help_not_on_tty = simple_cmd.help

      assert_includes help_on_tty,     "\e[31mUSAGE\e[0m\e[0m\n    \e[32mmoo"
      assert_includes help_not_on_tty, "USAGE\n    moo"
    end

    def test_help_for_bare_cmd
      bare_cmd.help
    end

    def test_help_with_optional_options
      def $stdout.tty?
        true
      end

      cmd = Cri::Command.define do
        name 'build'
        flag :s,  nil,   'short'
        flag nil, :long, 'long'
      end
      help = cmd.help

      assert_match(/--long.*-s/m,                             help)
      assert_match(/^       \e\[33m--long\e\[0m      long$/,  help)
      assert_match(/^    \e\[33m-s\e\[0m             short$/, help)
    end

    def test_help_with_different_option_types_short_and_long
      def $stdout.tty?
        true
      end

      cmd = Cri::Command.define do
        name 'build'
        required :r, :required, 'required value'
        flag     :f, :flag,     'forbidden value'
        optional :o, :optional, 'optional value'
      end
      help = cmd.help

      assert_match(/^    \e\[33m-r\e\[0m \e\[33m--required\e\[0m=<value>        required value$/, help)
      assert_match(/^    \e\[33m-f\e\[0m \e\[33m--flag\e\[0m                    forbidden value$/, help)
      assert_match(/^    \e\[33m-o\e\[0m \e\[33m--optional\e\[0m\[=<value>\]      optional value$/, help)
    end

    def test_help_with_different_option_types_short
      def $stdout.tty?
        true
      end

      cmd = Cri::Command.define do
        name 'build'
        required :r, nil, 'required value'
        flag     :f, nil, 'forbidden value'
        optional :o, nil, 'optional value'
      end
      help = cmd.help

      assert_match(/^    \e\[33m-r\e\[0m <value>        required value$/, help)
      assert_match(/^    \e\[33m-f\e\[0m                forbidden value$/, help)
      assert_match(/^    \e\[33m-o\e\[0m \[<value>\]      optional value$/, help)
    end

    def test_help_with_different_option_types_long
      def $stdout.tty?
        true
      end

      cmd = Cri::Command.define do
        name 'build'
        required nil, :required, 'required value'
        flag     nil, :flag,     'forbidden value'
        optional nil, :optional, 'optional value'
      end
      help = cmd.help

      assert_match(/^       \e\[33m--required\e\[0m=<value>        required value$/, help)
      assert_match(/^       \e\[33m--flag\e\[0m                    forbidden value$/, help)
      assert_match(/^       \e\[33m--optional\e\[0m\[=<value>\]      optional value$/, help)
    end

    def test_help_with_multiple_groups
      help = nested_cmd.subcommands.find { |cmd| cmd.name == 'sub' }.help

      assert_match(/OPTIONS.*OPTIONS FOR SUPER/m, help)
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

    def test_help_with_wrapped_options
      def $stdout.tty?
        true
      end

      cmd = Cri::Command.define do
        name 'build'
        flag nil, :longflag, 'This is an option with a very long description that should be wrapped'
      end
      help = cmd.help

      assert_match(/^       \e\[33m--longflag\e\[0m      This is an option with a very long description that$/, help)
      assert_match(/^                       should be wrapped$/, help)
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
      opt_defn = cmd.option_definitions.to_a[0]
      assert_equal 'help', opt_defn.long

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

      assert_match(/mycommand.rb/, error.backtrace.join("\n"))
    end

    def test_hidden_commands_single
      cmd    = nested_cmd
      subcmd = simple_cmd
      cmd.add_command subcmd
      subcmd.modify do |c|
        c.name    'old-and-deprecated'
        c.summary 'does stuff the ancient, totally deprecated way'
        c.be_hidden
      end

      refute cmd.help.include?('hidden commands omitted')
      assert cmd.help.include?('hidden command omitted')
      refute cmd.help.include?('old-and-deprecated')

      refute cmd.help(verbose: true).include?('hidden commands omitted')
      refute cmd.help(verbose: true).include?('hidden command omitted')
      assert cmd.help(verbose: true).include?('old-and-deprecated')
    end

    def test_hidden_commands_multiple
      cmd = nested_cmd

      subcmd = simple_cmd
      cmd.add_command subcmd
      subcmd.modify do |c|
        c.name    'first'
        c.summary 'does stuff first'
      end

      subcmd = simple_cmd
      cmd.add_command subcmd
      subcmd.modify do |c|
        c.name    'old-and-deprecated'
        c.summary 'does stuff the old, deprecated way'
        c.be_hidden
      end

      subcmd = simple_cmd
      cmd.add_command subcmd
      subcmd.modify do |c|
        c.name    'ancient-and-deprecated'
        c.summary 'does stuff the ancient, reallydeprecated way'
        c.be_hidden
      end

      assert cmd.help.include?('hidden commands omitted')
      refute cmd.help.include?('hidden command omitted')
      refute cmd.help.include?('old-and-deprecated')
      refute cmd.help.include?('ancient-and-deprecated')

      refute cmd.help(verbose: true).include?('hidden commands omitted')
      refute cmd.help(verbose: true).include?('hidden command omitted')
      assert cmd.help(verbose: true).include?('old-and-deprecated')
      assert cmd.help(verbose: true).include?('ancient-and-deprecated')

      pattern = /ancient-and-deprecated.*first.*old-and-deprecated/m
      assert_match(pattern, cmd.help(verbose: true))
    end

    def test_run_with_raw_args
      cmd = Cri::Command.define do
        name 'moo'
        run do |_opts, args|
          puts "args=#{args.join(',')}"
        end
      end

      out, _err = capture_io_while do
        cmd.run(%w[foo -- bar])
      end
      assert_equal "args=foo,bar\n", out
    end

    def test_run_without_block
      cmd = Cri::Command.define do
        name 'moo'
      end

      assert_raises(Cri::NotImplementedError) do
        cmd.run([])
      end
    end

    def test_runner_with_raw_args
      cmd = Cri::Command.define do
        name 'moo'
        runner(Class.new(Cri::CommandRunner) do
          def run
            puts "args=#{arguments.join(',')}"
          end
        end)
      end

      out, _err = capture_io_while do
        cmd.run(%w[foo -- bar])
      end
      assert_equal "args=foo,bar\n", out
    end

    def test_compare
      foo = Cri::Command.define { name 'foo' }
      bar = Cri::Command.define { name 'bar' }
      qux = Cri::Command.define { name 'qux' }

      assert_equal [bar, foo, qux], [foo, bar, qux].sort
    end

    def test_default_subcommand
      subcommand = Cri::Command.define do
        name 'sub'

        run do |_opts, _args, _c|
          $stdout.puts 'I am the subcommand!'
        end
      end

      cmd = Cri::Command.define do
        name 'super'
        default_subcommand 'sub'
        subcommand subcommand
      end

      out, _err = capture_io_while do
        cmd.run([])
      end
      assert_equal "I am the subcommand!\n", out
    end

    def test_skip_option_parsing
      command = Cri::Command.define do
        name 'super'
        skip_option_parsing

        run do |_opts, args, _c|
          puts "args=#{args.join(',')}"
        end
      end

      out, _err = capture_io_while do
        command.run(['--test', '-a', 'arg'])
      end

      assert_equal "args=--test,-a,arg\n", out
    end

    def test_subcommand_skip_option_parsing
      super_cmd = Cri::Command.define do
        name 'super'

        option :a, :aaa, 'opt a', argument: :optional
      end

      super_cmd.define_command do
        name 'sub'

        skip_option_parsing

        run do |opts, args, _c|
          puts "opts=#{opts.inspect} args=#{args.join(',')}"
        end
      end

      out, _err = capture_io_while do
        super_cmd.run(['--aaa', 'test', 'sub', '--test', 'value'])
      end

      assert_equal "opts={:aaa=>\"test\"} args=--test,value\n", out
    end

    def test_wrong_number_of_args
      cmd = Cri::Command.define do
        name 'publish'
        param :filename
      end

      out, err = capture_io_while do
        err = assert_raises SystemExit do
          cmd.run([])
        end
        assert_equal 1, err.status
      end

      assert_equal [], lines(out)
      assert_equal ['publish: incorrect number of arguments given: expected 1, but got 0'], lines(err)
    end

    def test_no_params_zero_args
      dsl = Cri::CommandDSL.new
      dsl.instance_eval do
        name        'moo'
        usage       'dunno whatever'
        summary     'does stuff'
        description 'This command does a lot of stuff.'
        no_params

        run do |_opts, args|
        end
      end
      command = dsl.command

      command.run([])
    end

    def test_no_params_one_arg
      dsl = Cri::CommandDSL.new
      dsl.instance_eval do
        name        'moo'
        usage       'dunno whatever'
        summary     'does stuff'
        description 'This command does a lot of stuff.'
        no_params

        run do |_opts, args|
        end
      end
      command = dsl.command

      out, err = capture_io_while do
        err = assert_raises SystemExit do
          command.run(['a'])
        end
        assert_equal 1, err.status
      end

      assert_equal [], lines(out)
      assert_equal ['moo: incorrect number of arguments given: expected 0, but got 1'], lines(err)
    end

    def test_load_file
      Dir.mktmpdir('foo') do |dir|
        filename = "#{dir}/moo.rb"
        File.write(filename, <<~CMD)
          name        'moo'
          usage       'dunno whatever'
          summary     'does stuff'
          description 'This command does a lot of stuff.'
          no_params

          run do |_opts, args|
          end
        CMD

        cmd = Cri::Command.load_file(filename)
        assert_equal('moo', cmd.name)
      end
    end

    def test_load_file_infer_name_false
      Dir.mktmpdir('foo') do |dir|
        filename = "#{dir}/moo.rb"
        File.write(filename, <<~CMD)
          usage       'dunno whatever'
          summary     'does stuff'
          description 'This command does a lot of stuff.'
          no_params

          run do |_opts, args|
          end
        CMD

        cmd = Cri::Command.load_file(filename)
        assert_equal(nil, cmd.name)
      end
    end

    def test_load_file_infer_name
      Dir.mktmpdir('foo') do |dir|
        filename = "#{dir}/moo.rb"
        File.write(filename, <<~CMD)
          usage       'dunno whatever'
          summary     'does stuff'
          description 'This command does a lot of stuff.'
          no_params

          run do |_opts, args|
          end
        CMD

        cmd = Cri::Command.load_file(filename, infer_name: true)
        assert_equal('moo', cmd.name)
      end
    end

    def test_load_file_infer_name_double
      Dir.mktmpdir('foo') do |dir|
        filename = "#{dir}/moo.rb"
        File.write(filename, <<~CMD)
          name        'oink'
          usage       'dunno whatever'
          summary     'does stuff'
          description 'This command does a lot of stuff.'
          no_params

          run do |_opts, args|
          end
        CMD

        cmd = Cri::Command.load_file(filename, infer_name: true)
        assert_equal('moo', cmd.name)
      end
    end

    def test_required_args_with_dash_h
      dsl = Cri::CommandDSL.new
      dsl.instance_eval do
        name        'moo'
        usage       'dunno whatever'
        summary     'does stuff'
        description 'This command does a lot of stuff.'

        param :foo

        option :h, :help, 'show help' do
          $helped = true
          exit 0
        end
      end
      command = dsl.command

      $helped = false
      out, err = capture_io_while do
        assert_raises SystemExit do
          command.run(['-h'])
        end
      end
      assert $helped
      assert_equal [], lines(out)
      assert_equal [], lines(err)
    end

    def test_propagate_options_two_levels_down
      cmd_a = Cri::Command.define do
        name 'a'
        flag :t, :test, 'test'
      end

      cmd_b = cmd_a.define_command('b') do
      end

      cmd_b.define_command('c') do
        run do |opts, _args|
          puts "test? #{opts[:test].inspect}!"
        end
      end

      # test -t last
      out, err = capture_io_while do
        cmd_a.run(%w[b c -t])
      end
      assert_equal ['test? true!'], lines(out)
      assert_equal [], lines(err)

      # test -t mid
      out, err = capture_io_while do
        cmd_a.run(%w[b -t c])
      end
      assert_equal ['test? true!'], lines(out)
      assert_equal [], lines(err)

      # test -t first
      out, err = capture_io_while do
        cmd_a.run(%w[-t b c])
      end
      assert_equal ['test? true!'], lines(out)
      assert_equal [], lines(err)
    end

    def test_flag_defaults_to_false
      cmd = Cri::Command.define do
        name 'a'
        option :f, :force2, 'push with force', argument: :forbidden

        run do |opts, _args, _cmd|
          puts "Force? #{opts[:force2].inspect}! Key present? #{opts.key?(:force2)}!"
        end
      end

      out, err = capture_io_while do
        cmd.run(%w[])
      end
      assert_equal ['Force? false! Key present? false!'], lines(out)
      assert_equal [], lines(err)
    end

    def test_required_option_defaults_to_given_value
      cmd = Cri::Command.define do
        name 'a'
        option :a, :animal, 'specify animal', argument: :required, default: 'cow'

        run do |opts, _args, _cmd|
          puts "Animal = #{opts[:animal]}! Key present? #{opts.key?(:animal)}!"
        end
      end

      out, err = capture_io_while do
        cmd.run(%w[])
      end
      assert_equal ['Animal = cow! Key present? false!'], lines(out)
      assert_equal [], lines(err)
    end

    def test_optional_option_defaults_to_given_value
      cmd = Cri::Command.define do
        name 'a'
        option :a, :animal, 'specify animal', argument: :optional, default: 'cow'

        run do |opts, _args, _cmd|
          puts "Animal = #{opts[:animal]}"
        end
      end

      out, err = capture_io_while do
        cmd.run(%w[])
      end
      assert_equal ['Animal = cow'], lines(out)
      assert_equal [], lines(err)
    end

    def test_required_option_defaults_to_given_value_with_transform
      cmd = Cri::Command.define do
        name 'a'
        option :a, :animal, 'specify animal', argument: :required, transform: ->(a) { a.upcase }, default: 'cow'

        run do |opts, _args, _cmd|
          puts "Animal = #{opts[:animal]}"
        end
      end

      out, err = capture_io_while do
        cmd.run(%w[])
      end
      assert_equal ['Animal = cow'], lines(out)
      assert_equal [], lines(err)
    end

    def test_option_definitions_are_not_shared_across_commands
      root_cmd = Cri::Command.define do
        name 'root'
        option :r, :rrr, 'Rrr!', argument: :required
      end

      subcmd_a = root_cmd.define_command do
        name 'a'
        option :a, :aaa, 'Aaa!', argument: :required

        run do |_opts, _args, cmd|
          puts cmd.all_opt_defns.map(&:long).sort.join(',')
        end
      end

      subcmd_b = root_cmd.define_command do
        name 'b'
        option :b, :bbb, 'Bbb!', argument: :required

        run do |_opts, _args, cmd|
          puts cmd.all_opt_defns.map(&:long).sort.join(',')
        end
      end

      out, err = capture_io_while do
        subcmd_a.run(%w[])
      end
      assert_equal ['aaa,rrr'], lines(out)
      assert_equal [], lines(err)

      out, err = capture_io_while do
        subcmd_b.run(%w[])
      end
      assert_equal ['bbb,rrr'], lines(out)
      assert_equal [], lines(err)
    end
  end
end
