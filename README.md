SwiftSchemer
============

This is a port of my [Schemer] app to the Swift programming language. I intend
for it to serve as a means of learning Swift, including how to more or less do
the same sort of horrible things I'd do in Scala (see QControlBinding.swift).

It's a work in progress and currently only works with dummy data loaded for
new documents -- loading and saving is not yet implemented, though this is
admittedly only because I haven't written those ~10-15 lines of code yet.

Unlike Schemer, this makes no use of Cocoa bindings and does not currently
make any use of typical Cocoa KVO and instead makes heavy use of Swift's
properties (namely didSet/willSet and get/set) to react to changes accordingly.
Aside from that, the code is currently fairly simple if we just ignore
QControlBinding.swift.

[Schemer]: https://github.com/nilium/schemer


Dependencies
------------

SwiftSchemer currently depends on the [SnowKit] framework. Right now, this is
hard-wired to a local build of that, so I'll need to see about setting up a
submodule to include in the project.

[SnowKit]: https://github.com/nilium/SnowKit


Contributing
------------

Want to contribute? Cool. Just try to follow the same general style as the
rest of the code and you're fine. Bear in mind that, right now, I'm working
all over the code to get this to where Schemer already is, so the chance of
seeing a merge conflict is high, so try to limit changes to a small area to
reduce conflict size until there's some parity with Schemer.

Also make sure to update copyright notices and release changes-to-be-merged
under the same license (below).

(Also try not to commit anything that modifies the Xcode project files unless
it's absolutely necessary -- those _will_ have conflicts.)


License
-------

SwiftSchemer is distributed under the Boost Software License, Version 1.0.
See accompanying file LICENSE_1_0.txt or copy at
<http://www.boost.org/LICENSE_1_0.txt>.
