# frozen_string_literal: true

flag :h, :help, 'show help for this command' do |_value, cmd|
  puts cmd.help
  raise CriExitException.new(is_error: false)
end

subcommand Cri::Command.new_basic_help
