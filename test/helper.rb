# encoding: utf-8

require 'stringio'

class Cri::TestCase < MiniTest::Unit::TestCase

  def capture_io_while(&block)
    $orig_stdout = $stdout
    $orig_stderr = $stderr

    $stdout = StringIO.new
    $stderr = StringIO.new

    block.call

    [ $stdout.string, $stderr.string ]
  ensure
    $stdout = $orig_stdout
    $stderr = $orig_stderr
  end

  def lines(string)
    string.scan(/^.*\n/).map { |s| s.chomp }
  end

end
