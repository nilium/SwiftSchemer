//
// Copyright Noel Cower 2014.
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file ../LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
//

import Cocoa


@objc class QBlockRevision {

    let block: () -> ()


    init(block: () -> ()) {
        self.block = block
    }


    func invoke(receiver: AnyObject!) {
        assert(receiver === self, "Invalid receiver for block revision")
        block()
    }

}


/// Wrapper around a weak reference to any QHasUndoManager.
@objc class QRevisionTracker {

    weak var manager: NSUndoManager?


    /// Adds a revision to the
    func addRevision(op: () -> ()) {
//        if let parent = trackingParent {
            if let manager = self.manager? {
                let rev = QBlockRevision(op)
                // target isn't retained, but object is, so pass it for both
                manager.registerUndoWithTarget(rev, selector: "invoke:", object: rev)
            } else {
                fatalError("No undo manager available while parent is still accessible")
            }
//        }
    }


    init(parent: NSDocument) {
        manager = parent.undoManager
    }


    init() {
        manager = nil
    }

}
