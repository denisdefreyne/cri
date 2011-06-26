# encoding: utf-8

module Cri::CoreExtensions

  module String

    # Extracts individual paragraphs (separated by two newlines).
    #
    # @return [Array<String>] A list of paragraphs in the string
    def to_paragraphs
      lines = self.scan(/([^\n]+\n|[^\n]*$)/).map { |s| s[0].strip }

      paragraphs = [ [] ]
      lines.each do |line|
        if line.empty?
          paragraphs << []
        else
          paragraphs.last << line
        end
      end

      paragraphs.reject { |p| p.empty? }.map { |p| p.join(' ') }
    end

    # Word-wraps and indents the string.
    #
    # @param [Number] width The maximal width of each line. This also includes
    #   indentation, i.e. the actual maximal width of the text is
    #   `width`-`indentation`.
    #
    # @param [Number] indentation The number of spaces to indent each line.
    #
    # @return [String] The word-wrapped and indented string
    def wrap_and_indent(width, indentation)
      # Split into paragraphs
      paragraphs = self.to_paragraphs

      # Wrap and indent each paragraph
      paragraphs.map do |paragraph|
        # Initialize
        lines = []
        line = ''

        # Split into words
        paragraph.split(/\s/).each do |word|
          # Begin new line if it's too long
          if (line + ' ' + word).length >= width
            lines << line
            line = ''
          end

          # Add word to line
          line += (line == '' ? '' : ' ' ) + word
        end
        lines << line

        # Join lines
        lines.map { |l| ' '*indentation + l }.join("\n")
      end.join("\n\n")
    end

  end

end
