# encoding: utf-8

class Cri::CoreExtTestCase < Cri::TestCase

  def test_string_to_paragraphs
    original = "Lorem ipsum dolor sit amet,\nconsectetur adipisicing.\n\n" +
               "Sed do eiusmod\ntempor incididunt ut labore."

    expected = [ "Lorem ipsum dolor sit amet, consectetur adipisicing.",
                 "Sed do eiusmod tempor incididunt ut labore." ]

    actual = original.to_paragraphs
    assert_equal expected, actual
  end

  def test_string_wrap_and_indent_without_indent
    original = "Lorem ipsum dolor sit amet, consectetur adipisicing elit, " +
               "sed do eiusmod tempor incididunt ut labore et dolore " + 
               "magna aliqua."

    expected = "Lorem ipsum dolor sit amet, consectetur\n" +
               "adipisicing elit, sed do eiusmod tempor\n" +
               "incididunt ut labore et dolore magna\n" +
               "aliqua."

    actual = original.wrap_and_indent(40, 0)
    assert_equal expected, actual
  end

  def test_string_wrap_and_indent_with_indent
    original = "Lorem ipsum dolor sit amet, consectetur adipisicing elit, " +
               "sed do eiusmod tempor incididunt ut labore et dolore " + 
               "magna aliqua."

    expected = "    Lorem ipsum dolor sit amet,\n" +
               "    consectetur adipisicing elit, sed\n" +
               "    do eiusmod tempor incididunt ut\n" +
               "    labore et dolore magna aliqua."

    actual = original.wrap_and_indent(36, 4)
    assert_equal expected, actual
  end

  def test_string_wrap_and_indent_with_multiple_lines
    original = "Lorem ipsum dolor sit\namet, consectetur adipisicing elit, " +
               "sed do\neiusmod tempor incididunt ut\nlabore et dolore " + 
               "magna\naliqua."

    expected = "    Lorem ipsum dolor sit amet,\n" +
               "    consectetur adipisicing elit, sed\n" +
               "    do eiusmod tempor incididunt ut\n" +
               "    labore et dolore magna aliqua."

    actual = original.wrap_and_indent(36, 4)
    assert_equal expected, actual
  end

end
