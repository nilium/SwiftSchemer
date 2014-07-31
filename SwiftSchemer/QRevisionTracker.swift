//
// Copyright Noel Cower 2014.
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file ../LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
//

import Cocoa


/// A thin class wrapper around a closure so it can be passed to an
/// NSUndoManager.
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


/// Wrapper around a weak reference to any NSUndoManager.
@objc class QRevisionTracker {

    weak var manager: NSUndoManager?
    var actionName: String? = nil {
        willSet {
            if actionName && newValue {
                NSLog("Discarding unused action name \(actionName)")
            }
        }
    }


    func addRevision(name: String, op: () -> ()) {
        actionName = name
        addRevision(op)
    }


    /// Adds a revision closure to the undo manager.
    func addRevision(op: () -> ()) {
        if let manager = self.manager? {
            let rev = QBlockRevision(op)
            // target isn't retained, but object is, so pass it for both
            manager.registerUndoWithTarget(rev, selector: "invoke:", object: rev)
            manager.setActionName(actionName)
        } else {
            NSLog("No undo manager available -- discarding revision")
        }
        actionName = nil
    }


    init(parent: NSDocument) {
        manager = parent.undoManager
    }


    init() {
        manager = nil
    }

}
