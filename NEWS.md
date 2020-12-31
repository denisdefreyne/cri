# Cri News

## 2.15.11

Fixes:

- Added support for Ruby 3.0 (#111)

Changes:

- Dropped support for Ruby 2.3 and 2.4 (#112)

## 2.15.10

Fixes:

- Fixed warnings appearing in Ruby 2.7 (9a3d810)

## 2.15.9

Fixes:

- Fixed bug which could cause options from one command appear in other commands (#101, #102)

## 2.15.8

Fixes:

- Don’t explicitly set default values for options (#99)

This release reverts a backwards-incompatible change introduced in 2.15.7.

To illustrate this, compare the behavior of the following command in recent versions of Cri:

```ruby
option :f, :force, 'use force', argument: :forbidden

run do |opts, args, cmd|
  puts "Options = #{opts.inspect}"
  puts "Force? #{opts[:force]}"
  puts "Option given? #{opts.key?(:force)}"
end
```

In Cri 2.15.6, the default is not set in the options hash, so the value is `nil` and `#key?` returns false:

```sh
% ./run
Options = {}
Force? nil
Option given? false
```

This behavior was inconsistent with what was documented: flag options were (and still are) documented to default to `false` rather than `nil`.

In Cri 2.15.7, the default value is `false`, and explicitly set in the options hash (`#key?` returns `true`):

```sh
% ./run
Options = {:force=>false}
Force? false
Option given? true
```

This change made it impossible to detect options that were not explicitly specified, because the behavior of `#key?` also changed.

In Cri 2.15.8, the default value is also `false` (as in 2.15.7), but not explicitly set in the options hash (`#key?` returns `false`, as in 2.15.6):

```sh
% ./run
Options = {}
Force? false
Option given? false
```

This backwards-incompatible change was not intentional. To fix issue #94, a change in behavior was needed, but this change also affected other, previously-undefined behavior. The new behavior in 2.15.8 should fix the bug fixed in 2.15.7 (#94, #96), without causing the problems introduced in that version.

## 2.15.7

Fixes:

- Options with a forbidden argument now default to false, rather than nil (#94, #96)

## 2.15.6

Fixes:

- Fixed problem with help header not being shown if the summary is missing (#93)

## 2.15.5

Fixes:

- Restored compatibility with Ruby 2.3. (#91)

## 2.15.4

Fixes:

- Removed dependency on `colored`, which restores functionality to gems that `colored` breaks (e.g. `awesome_print`) (#89, #90)

## 2.15.3

Fixes:

- Made `ArgumentList#each` callable without a block, in which case it returns an `Enumerator` (mimicking `Array`) (#87, #88)

## 2.15.2

Fixes:

- Fixed option propagation for two levels or more (#85, #86)

## 2.15.1

Fixes:

- Made -h/--help not fail when parameters are defined for the command that -h/--help is called on (#76, #78)

Enhancements:

- Made `#option` raise an error when unrecognised parameters are passed to it (#77) [Marc-André Lafortune]

## 2.15.0

Features:

- Added support for parameter transformation (#72)

## 2.14.0

Features:

- Added `Cri::Command.load_file`

## 2.13.0

Features:

- Added support for explicitly specifying zero parameters using `#no_params` (#71)

## 2.12.0

Features:

- Added support for parameter naming and validation (#70)

## 2.11.0

Features:

- Added support for transforming option values (#68)

## 2.10.1

Fixes:

- Restored Ruby 2.1 compatibility (for now)

## 2.10.0

Features:

- Added support for skipping option parsing (#62) [Tim Sharpe]

This release drops support for Ruby 2.1, which is no longer supported.

## 2.9.1

Fixes:

- Made default values be always returned, even when not explicitly specified (#57, #58)

## 2.9.0

Features:

- Allowed specifying default option value (#55)

Enhancements:

- Added support for specifying values for combined options (#56)

## 2.8.0

Features:

- Allowed passing `hard_exit: false` to `Command#run` to prevent `SystemExit` (#51)
- Allowed specifying the default subcommand (#54)

## 2.7.1

Fixes:

- Fixed some grammatical mistakes

## 2.7.0

Features:

- Added support for hidden options (#43, #44) [Bart Mesuere]

Enhancements:

- Added option values to help output (#37, #40, #41)
- Made option descriptions wrap (#36, #45) [Bart Mesuere]

## 2.6.1

- Disable ANSI color codes when not supported (#31, #32)

## 2.6.0

- Added support for multi-valued options (#29) [Toon Willems]

## 2.5.0

- Made the default help command handle subcommands (#27)
- Added `#raw` method to argument arrays, returning all arguments including `--` (#22)

## 2.4.1

- Fixed ordering of option groups on Ruby 1.8.x (#14, #15)
- Fixed ordering of commands when --verbose is passed (#16, #18)

## 2.4.0

- Allowed either short or long option to be, eh, optional (#9, #10) [Ken Coar]
- Fixed wrap-and-indent behavior (#12) [Ken Coar]
- Moved version information into `cri/version`

## 2.3.0

- Added colors (#1)
- Added support for marking commands as hidden

## 2.2.1

- Made command help sort subcommands

## 2.2.0

- Allowed commands with subcommands to have a run block

## 2.1.0

- Added support for runners
- Split up local/global command options

## 2.0.2

- Added command filename to stack traces

## 2.0.1

- Sorted ambiguous command names
- Restored compatibility with Ruby 1.8.x

## 2.0.0

- Added DSL
- Added support for nested commands

## 1.0.1

- Made gem actually include code. D'oh.

## 1.0.0

- Initial release!
