//
// Copyright Noel Cower 2014.
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file ../LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
//

import Cocoa


class QAppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(notification: NSNotification!) {
        // TODO: Remove after I stop screwing with constraints.
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: "NSConstraintBasedLayoutVisualizeMutuallyExclusiveConstraints")
    }

}
