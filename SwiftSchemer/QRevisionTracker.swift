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
            if actionName != nil && newValue != nil {
                NSLog("Discarding unused action name \(actionName)")
            }
        }
    }


    func addRevision(name: String, op: () -> ()) {
        actionName = name
        addRevision(op)
    }


    /// Adds a revision closure to the undo manager.
    ///
    /// :param: op The revision operation. If this is recorded normally or
    ///     within a redo revision, it's an undo operation. Otherwise, if
    ///     recorded inside an undo operation, it's a redo operation, per
    ///     normal NSUndoManager behavior.
    func addRevision(op: () -> ()) {
        if let manager = self.manager? {
            let rev = QBlockRevision(op)
            // target isn't retained, but object is, so pass it for both
            manager.registerUndoWithTarget(rev, selector: "invoke:", object: rev)
            if let name = actionName {
                manager.setActionName(name)
            }
        } else {
            NSLog("No undo manager available -- discarding revision")
        }
        actionName = nil
    }


    func group(name: String, op: (QRevisionTracker) -> ()) {
        actionName = name
        group(op)
    }


    /// Groups any revisions that occur inside the given block in an undo
    /// grouping.
    ///
    /// :param: op The block to group operations inside of.
    func group(op: (QRevisionTracker) -> ()) {
        if let manager = self.manager? {
            manager.beginUndoGrouping()
            op(self)
            manager.endUndoGrouping()
            if let name = actionName {
                manager.setActionName(name)
            }
        } else {
            NSLog("No undo manager available -- discarding grouping")
            op(self)
        }
        actionName = nil
    }


    init(_ undoManager: NSUndoManager?) {
        manager = undoManager
    }


    init() {
        manager = nil
    }

}
