# encoding: utf-8

module Cri

  class HelpRenderer

    def initialize(cmd, params={})
      @cmd        = cmd
      @is_verbose = params.fetch(:verbose, false)
    end

    def render
      text = ''

      append_summary(text)
      append_usage(text)
      append_description(text)
      append_subcommands(text)
      append_options(text)

      text
    end

    private

    def append_summary(text)
      return if @cmd.summary.nil?

      text << "name".formatted_as_title << "\n"
      text << "    #{@cmd.name.formatted_as_command} - #{@cmd.summary}" << "\n"
      unless @cmd.aliases.empty?
        text << "    aliases: " << @cmd.aliases.map { |a| a.formatted_as_command }.join(' ') << "\n"
      end
    end

    def append_usage(text)
      return if @cmd.usage.nil?

      path = [ @cmd.supercommand ]
      path.unshift(path[0].supercommand) until path[0].nil?
      formatted_usage = @cmd.usage.gsub(/^([^\s]+)/) { |m| m.formatted_as_command }
      full_usage = path[1..-1].map { |c| c.name.formatted_as_command + ' ' }.join + formatted_usage

      text << "\n"
      text << "usage".formatted_as_title << "\n"
      text << full_usage.wrap_and_indent(78, 4) << "\n"
    end

    def append_description(text)
      return if @cmd.description.nil?

      text << "\n"
      text << "description".formatted_as_title << "\n"
      text << @cmd.description.wrap_and_indent(78, 4) + "\n"
    end

    def append_subcommands(text)
      return if @cmd.subcommands.empty?

      text << "\n"
      text << (@cmd.supercommand ? 'subcommands' : 'commands').formatted_as_title
      text << "\n"

      shown_subcommands = @cmd.subcommands.select { |c| !c.hidden? || @is_verbose }
      length = shown_subcommands.map { |c| c.name.formatted_as_command.size }.max

      # Command
      shown_subcommands.sort_by { |cmd| cmd.name }.each do |cmd|
        text << sprintf("    %-#{length+4}s %s\n",
          cmd.name.formatted_as_command,
          cmd.summary)
      end

      # Hidden notice
      if !@is_verbose
        diff = @cmd.subcommands.size - shown_subcommands.size
        case diff
        when 0
        when 1
          text << "    (1 hidden command omitted; show it with --verbose)\n"
        else
          text << "    (#{diff} hidden commands omitted; show them with --verbose)\n"
        end
      end
    end

    def append_options(text)
      groups = { 'options' => @cmd.option_definitions }
      if @cmd.supercommand
        groups["options for #{@cmd.supercommand.name}"] = @cmd.supercommand.global_option_definitions
      end
      length = groups.values.inject(&:+).map { |o| o[:long].to_s.size }.max
      groups.keys.sort.each do |name|
        defs = groups[name]
        append_option_group(text, name, defs, length)
      end
    end

    def append_option_group(text, name, defs, length)
      return if defs.empty?

      text << "\n"
      text << "#{name}".formatted_as_title
      text << "\n"

      ordered_defs = defs.sort_by { |x| x[:short] || x[:long] }
      ordered_defs.each do |opt_def|
        text << format_opt_def(opt_def, length)
        text << opt_def[:desc] << "\n"
      end
    end

    def format_opt_def(opt_def, length)
      opt_text = sprintf(
          "    %-2s %-#{length+6}s",
          opt_def[:short] ? ('-' + opt_def[:short]) : '',
          opt_def[:long]  ? ('--' + opt_def[:long]) : '')
      opt_text.formatted_as_option
    end

  end

end
