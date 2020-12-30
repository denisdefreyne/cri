# frozen_string_literal: true

require_relative 'lib/cri/version'

Gem::Specification.new do |s|
  s.name        = 'cri'
  s.version     = Cri::VERSION
  s.homepage    = 'https://github.com/ddfreyne/cri'
  s.summary     = 'a library for building easy-to-use command-line tools'
  s.description = 'Cri allows building easy-to-use command-line interfaces with support for subcommands.'
  s.license     = 'MIT'

  s.author = 'Denis Defreyne'
  s.email  = 'denis.defreyne@stoneship.org'

  s.files = Dir['[A-Z]*'] + Dir['{lib,test}/**/*'] + ['cri.gemspec']
  s.require_paths = ['lib']

  s.required_ruby_version = '>= 2.5'

  s.rdoc_options     = ['--main', 'README.md']
  s.extra_rdoc_files = ['LICENSE', 'README.md', 'NEWS.md']
end
