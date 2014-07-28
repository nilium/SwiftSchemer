//
// Copyright Noel Cower 2014.
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file ../LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
//

import Cocoa
import SnowKit


let kQSelectorDataColumn = "selector"


class QSelectorTableSource: NSObject, NSTableViewDataSource {

    var rule: QSchemeRule? = nil


    func numberOfRowsInTableView(tableView: NSTableView!) -> Int {
        let count = rule?.selectors.count ~| 0
        return count
    }


    func tableView(tableView: NSTableView!, objectValueForTableColumn tableColumn: NSTableColumn!, row: Int) -> AnyObject! {
        switch tableColumn.identifier as String {
        case kQSelectorDataColumn:
            return rule?.selectors[row]
        case let unknownColumn:
            debugPrint("Attempt to access row \(row) of undefined column '\(unknownColumn)' from selector data source; returning nil")
            return nil
        }
    }


    func tableView(tableView: NSTableView!, setObjectValue object: AnyObject!, forTableColumn tableColumn: NSTableColumn!, row: Int) {
        if !rule {
            debugPrint("Attempt to set row \(row) of column \(tableColumn.identifier) to \(object) when rule is undefined")
            assert(false)
            return
        }

        switch tableColumn.identifier as String {
        case kQSelectorDataColumn where object is NSString:
            rule!.selectors[row] = object as NSString
        case kQSelectorDataColumn:
            debugPrint("Attempt to write non-NSString value [\(object)] to selector at row \(row)")
            assert(false)
        case let unknownColumn:
            debugPrint("Attempt to write object [\(object)] to row \(row) of undefined column '\(unknownColumn)' from selector data source")
        }
    }

}


// MARK: Drag & Drop

let kQSelectorPasteType = "net.spifftastic.SwiftSchemer.SelectorPaste"


extension QSelectorTableSource {

    func tableView(
        tableView: NSTableView!,
        acceptDrop info: NSDraggingInfo!,
        row: Int,
        dropOperation: NSTableViewDropOperation
        ) -> Bool
    {
        return false
    }


    func tableView(
        tableView: NSTableView!,
        validateDrop info: NSDraggingInfo!,
        proposedRow row: Int,
        proposedDropOperation dropOperation: NSTableViewDropOperation
        ) -> NSDragOperation
    {
        return .None
    }


    func tableView(tableView: NSTableView!, pasteboardWriterForRow row: Int) -> NSPasteboardWriting! {
        if let rule = self.rule {
            let item = NSPasteboardItem()
            let plist: NSDictionary = [
                "selector": rule.selectors[row].bridgeToObjectiveC(),
                "row": row.bridgeToObjectiveC()
            ]
            item.setPropertyList(plist, forType: kQSelectorPasteType)
            return item
        }
        return nil
    }

}
