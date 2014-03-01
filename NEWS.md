Cri News
========

2.5.0
-----

* Made the default help command handle subcommands
* Added `#raw` method to argument arrays, returning all arguments including `--`

2.4.1
-----

* Fixed ordering of option groups on Ruby 1.8.x (#14, #15)
* Fixed ordering of commands when --verbose is passed (#16, #18)

2.4.0
-----

* Allowed either short or long option to be, eh, optional [Ken Coar]
* Fixed wrap-and-indent behavior [Ken Coar]
* Moved version information into `cri/version`

2.3.0
-----

* Added colors
* Added support for marking commands as hidden

2.2.1
-----

* Made command help sort subcommands

2.2.0
-----

* Allowed commands with subcommands to have a run block

2.1.0
-----

* Added support for runners
* Split up local/global command options

2.0.2
-----

* Added command filename to stack traces

2.0.1
-----

* Sorted ambiguous command names
* Restored compatibility with Ruby 1.8.x

2.0.0
-----

* Added DSL
* Added support for nested commands

1.0.1
-----

* Made gem actually include code. D'oh.

1.0.0
-----

* Initial release!
