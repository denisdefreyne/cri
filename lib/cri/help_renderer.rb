# frozen_string_literal: true

module Cri
  # The {HelpRenderer} class is responsible for generating a string containing
  # the help for a given command, intended to be printed on the command line.
  class HelpRenderer
    # The line width of the help output
    LINE_WIDTH = 78

    # The indentation of descriptions
    DESC_INDENT = 4

    # The spacing between an option name and option description
    OPT_DESC_SPACING = 6

    # Creates a new help renderer for the given command.
    #
    # @param [Cri::Command] cmd The command to generate the help for
    #
    # @option params [Boolean] :verbose true if the help output should be
    #   verbose, false otherwise.
    def initialize(cmd, **params)
      @cmd        = cmd
      @is_verbose = params.fetch(:verbose, false)
      @io         = params.fetch(:io, $stdout)
    end

    # @return [String] The help text for this command
    def render
      text = +''

      append_summary(text)
      append_usage(text)
      append_description(text)
      append_subcommands(text)
      append_options(text)

      text
    end

    private

    def fmt
      @fmt ||= Cri::StringFormatter.new
    end

    def append_summary(text)
      return if @cmd.name.nil?

      text << fmt.format_as_title('name', @io) << "\n"

      text << '    ' << fmt.format_as_command(@cmd.name, @io)
      if @cmd.summary
        text << ' - ' << @cmd.summary
      end
      text << "\n"

      unless @cmd.aliases.empty?
        text << '    aliases: ' << @cmd.aliases.map { |a| fmt.format_as_command(a, @io) }.join(' ') << "\n"
      end
    end

    def append_usage(text)
      return if @cmd.usage.nil?

      path = [@cmd.supercommand]
      path.unshift(path[0].supercommand) until path[0].nil?
      formatted_usage = @cmd.usage.gsub(/^([^\s]+)/) { |m| fmt.format_as_command(m, @io) }
      full_usage = path[1..-1].map { |c| fmt.format_as_command(c.name, @io) + ' ' }.join + formatted_usage

      text << "\n"
      text << fmt.format_as_title('usage', @io) << "\n"
      text << fmt.wrap_and_indent(full_usage, LINE_WIDTH, DESC_INDENT) << "\n"
    end

    def append_description(text)
      return if @cmd.description.nil?

      text << "\n"
      text << fmt.format_as_title('description', @io) << "\n"
      text << fmt.wrap_and_indent(@cmd.description, LINE_WIDTH, DESC_INDENT) + "\n"
    end

    def append_subcommands(text)
      return if @cmd.subcommands.empty?

      text << "\n"
      text << fmt.format_as_title(@cmd.supercommand ? 'subcommands' : 'commands', @io)
      text << "\n"

      shown_subcommands = @cmd.subcommands.select { |c| !c.hidden? || @is_verbose }
      length = shown_subcommands.map { |c| fmt.format_as_command(c.name, @io).size }.max

      # Command
      shown_subcommands.sort_by(&:name).each do |cmd|
        text <<
          format(
            "    %<name>-#{length + DESC_INDENT}s %<summary>s\n",
            name: fmt.format_as_command(cmd.name, @io),
            summary: cmd.summary,
          )
      end

      # Hidden notice
      unless @is_verbose
        diff = @cmd.subcommands.size - shown_subcommands.size
        if diff == 1
          text << "    (1 hidden command omitted; show it with --verbose)\n"
        elsif diff > 1
          text << "    (#{diff} hidden commands omitted; show them with --verbose)\n"
        end
      end
    end

    def length_for_opt_defns(opt_defns)
      opt_defns.map do |opt_defn|
        string = +''

        # Always pretend there is a short option
        string << '-X'

        if opt_defn.long
          string << ' --' + opt_defn.long
        end

        case opt_defn.argument
        when :required
          string << '=<value>'
        when :optional
          string << '=[<value>]'
        end

        string.size
      end.max
    end

    def append_options(text)
      groups = { 'options' => @cmd.option_definitions }
      if @cmd.supercommand
        groups["options for #{@cmd.supercommand.name}"] = @cmd.supercommand.global_option_definitions
      end
      length = length_for_opt_defns(groups.values.inject(&:+))
      groups.keys.sort.each do |name|
        defs = groups[name]
        append_option_group(text, name, defs, length)
      end
    end

    def append_option_group(text, name, defs, length)
      return if defs.empty?

      text << "\n"
      text << fmt.format_as_title(name.to_s, @io)
      text << "\n"

      ordered_defs = defs.sort_by { |x| x.short || x.long }
      ordered_defs.reject(&:hidden).each do |opt_defn|
        text << format_opt_defn(opt_defn, length)
        desc = opt_defn.desc + (opt_defn.default ? " (default: #{opt_defn.default})" : '')
        text << fmt.wrap_and_indent(desc, LINE_WIDTH, length + OPT_DESC_SPACING + DESC_INDENT, true) << "\n"
      end
    end

    def short_value_postfix_for(opt_defn)
      value_postfix =
        case opt_defn.argument
        when :required
          '<value>'
        when :optional
          '[<value>]'
        end

      if value_postfix
        opt_defn.long ? '' : ' ' + value_postfix
      else
        ''
      end
    end

    def long_value_postfix_for(opt_defn)
      value_postfix =
        case opt_defn.argument
        when :required
          '=<value>'
        when :optional
          '[=<value>]'
        end

      if value_postfix
        opt_defn.long ? value_postfix : ''
      else
        ''
      end
    end

    def format_opt_defn(opt_defn, length)
      short_value_postfix = short_value_postfix_for(opt_defn)
      long_value_postfix = long_value_postfix_for(opt_defn)

      opt_text = +''
      opt_text_len = 0
      if opt_defn.short
        opt_text << fmt.format_as_option('-' + opt_defn.short, @io)
        opt_text << short_value_postfix
        opt_text << ' '
        opt_text_len += 1 + opt_defn.short.size + short_value_postfix.size + 1
      else
        opt_text << '   '
        opt_text_len += 3
      end
      opt_text << fmt.format_as_option('--' + opt_defn.long, @io) if opt_defn.long
      opt_text << long_value_postfix
      opt_text_len += 2 + opt_defn.long.size if opt_defn.long
      opt_text_len += long_value_postfix.size

      '    ' + opt_text + ' ' * (length + OPT_DESC_SPACING - opt_text_len)
    end
  end
end
