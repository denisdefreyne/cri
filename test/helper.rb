# frozen_string_literal: true

require 'minitest'
require 'minitest/autorun'

require 'cri'

require 'stringio'

module Cri
  class TestCase < Minitest::Test
    def setup
      @orig_io = capture_io
    end

    def teardown
      uncapture_io(*@orig_io)
    end

    def capture_io_while
      orig_io = capture_io
      yield
      [$stdout.string, $stderr.string]
    ensure
      uncapture_io(*orig_io)
    end

    def lines(string)
      string.scan(/^.*\n/).map(&:chomp)
    end

    private

    def capture_io
      orig_stdout = $stdout
      orig_stderr = $stderr

      $stdout = StringIO.new
      $stderr = StringIO.new

      [orig_stdout, orig_stderr]
    end

    def uncapture_io(orig_stdout, orig_stderr)
      $stdout = orig_stdout
      $stderr = orig_stderr
    end
  end
end

# Unexpected system exit is unexpected
::Minitest::Test::PASSTHROUGH_EXCEPTIONS.delete(SystemExit)
