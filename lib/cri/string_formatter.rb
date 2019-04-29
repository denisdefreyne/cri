# frozen_string_literal: true

module Cri
  # Used for formatting strings (e.g. converting to paragraphs, wrapping,
  # formatting as title)
  #
  # @api private
  class StringFormatter
    # Extracts individual paragraphs (separated by two newlines).
    #
    # @param [String] str The string to format
    #
    # @return [Array<String>] A list of paragraphs in the string
    def to_paragraphs(str)
      lines = str.scan(/([^\n]+\n|[^\n]*$)/).map { |l| l[0].strip }

      paragraphs = [[]]
      lines.each do |line|
        if line.empty?
          paragraphs << []
        else
          paragraphs.last << line
        end
      end

      paragraphs.reject(&:empty?).map { |p| p.join(' ') }
    end

    # Word-wraps and indents the string.
    #
    # @param [String] str The string to format
    #
    # @param [Number] width The maximal width of each line. This also includes
    #   indentation, i.e. the actual maximal width of the text is
    #   `width`-`indentation`.
    #
    # @param [Number] indentation The number of spaces to indent each line.
    #
    # @param [Boolean] first_line_already_indented Whether or not the first
    #   line is already indented
    #
    # @return [String] The word-wrapped and indented string
    def wrap_and_indent(str, width, indentation, first_line_already_indented = false)
      indented_width = width - indentation
      indent = ' ' * indentation
      # Split into paragraphs
      paragraphs = to_paragraphs(str)

      # Wrap and indent each paragraph
      text = paragraphs.map do |paragraph|
        # Initialize
        lines = []
        line = ''

        # Split into words
        paragraph.split(/\s/).each do |word|
          # Begin new line if it's too long
          if (line + ' ' + word).length >= indented_width
            lines << line
            line = ''
          end

          # Add word to line
          line += (line == '' ? '' : ' ') + word
        end
        lines << line

        # Join lines
        lines.map { |l| indent + l }.join("\n")
      end.join("\n\n")

      if first_line_already_indented
        text[indentation..-1]
      else
        text
      end
    end

    # @param [String] str The string to format
    #
    # @return [String] The string, formatted to be used as a title in a section
    #   in the help
    def format_as_title(str, io)
      if Cri::Platform.color?(io)
        bold(red(str.upcase))
      else
        str.upcase
      end
    end

    # @param [String] str The string to format
    #
    # @return [String] The string, formatted to be used as the name of a command
    #   in the help
    def format_as_command(str, io)
      if Cri::Platform.color?(io)
        green(str)
      else
        str
      end
    end

    # @param [String] str The string to format
    #
    # @return [String] The string, formatted to be used as an option definition
    #   of a command in the help
    def format_as_option(str, io)
      if Cri::Platform.color?(io)
        yellow(str)
      else
        str
      end
    end

    def red(str)
      "\e[31m#{str}\e[0m"
    end

    def green(str)
      "\e[32m#{str}\e[0m"
    end

    def yellow(str)
      "\e[33m#{str}\e[0m"
    end

    def bold(str)
      "\e[1m#{str}\e[0m"
    end
  end
end
