# encoding: utf-8

$LOAD_PATH.unshift(File.expand_path('../lib/', __FILE__))
require 'cri/version'

Gem::Specification.new do |s|
  s.name        = 'cri'
  s.version     = Cri::VERSION
  s.homepage    = 'http://stoneship.org/software/cri/' # TODO CREATE A WEB SITE YOU SILLY PERSON
  s.summary     = 'a library for building easy-to-use commandline tools'
  s.description = 'Cri allows building easy-to-use commandline interfaces with support for subcommands.'
  s.license     = 'MIT'

  s.author = 'Denis Defreyne'
  s.email  = 'denis.defreyne@stoneship.org'

  s.files              = Dir['[A-Z]*'] +
                         Dir['{lib,test}/**/*'] +
                         [ 'cri.gemspec' ]
  s.require_paths      = [ 'lib' ]

  s.add_dependency('colored', '~> 1.2')

  s.add_development_dependency('rake',     '~> 10.1')
  s.add_development_dependency('minitest', '~> 5.3')
  s.add_development_dependency('yard',     '~> 0.8')

  s.rdoc_options     = [ '--main', 'README.adoc' ]
  s.extra_rdoc_files = [ 'LICENSE', 'README.adoc', 'NEWS.md' ]
end
