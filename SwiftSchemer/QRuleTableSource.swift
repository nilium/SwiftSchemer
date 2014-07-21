//
// Copyright Noel Cower 2014.
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file ../LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
//

import Cocoa
import SnowKit


class QRuleTableSource: NSObject, NSTableViewDataSource {

    var scheme: QScheme?


    func tableView(tableView: NSTableView!, objectValueForTableColumn tableColumn: NSTableColumn!, row: Int) -> AnyObject! {
        // As in the Obj-C version of Schemer, this returns nil because I don't
        // want the tableview calling setObjectValue: with the result of this
        // method -- allowing it to do so just makes life difficult.
        return nil
    }


    func numberOfRowsInTableView(tableView: NSTableView!) -> Int {
        return scheme?.rules.count ~| 0
    }

}
