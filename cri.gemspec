# encoding: utf-8

$LOAD_PATH.unshift(File.expand_path('../lib/', __FILE__))
require 'cri'

Gem::Specification.new do |s|
  s.name        = 'cri'
  s.version     = Cri::VERSION
  s.homepage    = 'http://stoneship.org/software/cri/' # TODO CREATE A WEB SITE YOU SILLY PERSON
  s.summary     = 'a library for building easy-to-use commandline tools'
  s.description = 'Cri allows building easy-to-use commandline interfaces with support for subcommands.'

  s.author = 'Denis Defreyne'
  s.email  = 'denis.defreyne@stoneship.org'

  s.files              = Dir['[A-Z]*'] +
                         Dir['{lib,test}/**/*'] +
                         [ 'cri.gemspec', '.gemtest' ]
  s.require_paths      = [ 'lib' ]

  s.rdoc_options     = [ '--main', 'README.md' ]
  s.extra_rdoc_files = [ 'ChangeLog', 'LICENSE', 'README.md', 'NEWS.md' ]
end
