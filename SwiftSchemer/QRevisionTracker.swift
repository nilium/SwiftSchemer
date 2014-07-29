//
//  QRevisionTracker.swift
//  SwiftSchemer
//
//  Created by Noel Cower on 07/28/14.
//  Copyright (c) 2014 Noel Cower. All rights reserved.
//

import Cocoa


/// Wrapper around a weak reference to any QHasUndoManager.
class QRevisionTracker {

    @objc class BlockRevision {

        let block: () -> ()


        init(block: () -> ()) {
            self.block = block
        }


        func invoke(receiver: AnyObject!) {
            assert(receiver === self, "Invalid receiver for block revision")
            block()
        }

    }


    weak var trackingParent: NSDocument?


    /// Adds a revision to the
    func addRevision(op: () -> ()) {
        if let parent = trackingParent {
            if let manager = parent.undoManager {
                let rev = BlockRevision(op)
                // target isn't retained, but object is, so pass it for both
                manager.registerUndoWithTarget(rev, selector: "invoke:", object: rev)
            } else {
                fatalError("No undo manager available while parent is still accessible")
            }
        }
    }


    init(parent: NSDocument?) {
        trackingParent = parent
    }


    init() {
        trackingParent = nil
    }

}


// MARK: revisionTracker property for existing classes

extension NSDocument {
    var revisionTracker: QRevisionTracker {
        return QRevisionTracker(parent: self)
    }
}
