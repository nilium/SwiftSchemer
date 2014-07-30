//
// Copyright Noel Cower 2014.
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file ../LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
//

import Cocoa
import SnowKit


let kQSelectorDataColumn = "selector"


class QSelectorTableSource: NSObject, NSTableViewDataSource {

    var scheme: QScheme? = nil
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
            NSLog("Attempt to access row \(row) of undefined column '\(unknownColumn)' from selector data source; returning nil")
            return nil
        }
    }


    func tableView(tableView: NSTableView!, setObjectValue object: AnyObject!, forTableColumn tableColumn: NSTableColumn!, row: Int) {
        if !rule {
            NSLog("Attempt to set row \(row) of column \(tableColumn.identifier) to \(object) when rule is undefined")
            assert(false)
            return
        }

        switch tableColumn.identifier as String {
        case kQSelectorDataColumn where object is NSString:
            rule!.selectors[row] = object as NSString
            notify(QSchemeChangedNotification, from: scheme)
        case kQSelectorDataColumn:
            NSLog("Attempt to write non-NSString value [\(object)] to selector at row \(row)")
            assert(false)
        case let unknownColumn:
            NSLog("Attempt to write object [\(object)] to row \(row) of undefined column '\(unknownColumn)' from selector data source")
        }
    }

}


// MARK: Drag & Drop

let kQSelectorPasteType = "net.spifftastic.SwiftSchemer.SelectorPaste"


internal func pasteItemToSelectorPropertyList(obj: AnyObject) -> NSDictionary {
    return (obj as NSPasteboardItem).propertyListForType(kQSelectorPasteType) as NSDictionary
}


extension QSelectorTableSource {

    func tableView(
        tableView: NSTableView!,
        acceptDrop info: NSDraggingInfo!,
        row: Int,
        dropOperation: NSTableViewDropOperation
        ) -> Bool
    {
        if dropOperation == .On || !rule {
            return false
        }

        var newRow = row
        let mask = info.draggingSourceOperationMask()
        let source: AnyObject? = info.draggingSource()
        let pasteboard = info.draggingPasteboard()

        let items = pasteboard.readObjectsForClasses([NSPasteboardItem.self],
            options: [NSPasteboardURLReadingContentsConformToTypesKey: [kQSelectorPasteType]])
            .map(pasteItemToSelectorPropertyList)

        let indices = NSMutableIndexSet()

        if mask &== .Move && source === tableView {
            for item in items {
                let itemRow: Int = item["row"] as NSNumber

                indices.addIndex(itemRow)
                if itemRow < row {
                    newRow -= 1
                }
            }
        }

        var newSelectors = rule!.selectors.withoutIndices(indices)
        let pastedSelectors: [String] = items.map { $0["selector"] as NSString }

        if newRow >= newSelectors.count {
            newSelectors += pastedSelectors
        } else {
            newSelectors.replaceRange(newRow ..< newRow, with: pastedSelectors)
        }

        rule!.selectors = newSelectors

        notify(QSchemeChangedNotification, from: scheme)

        return true
    }


    func tableView(
        tableView: NSTableView!,
        validateDrop info: NSDraggingInfo!,
        proposedRow row: Int,
        proposedDropOperation dropOperation: NSTableViewDropOperation
        ) -> NSDragOperation
    {
        if !rule {
            return .None
        }

        if dropOperation != .Above {
            tableView.setDropRow(row, dropOperation: .Above)
        }

        if row >= 0 && row <= rule!.selectors.count {
            let source: AnyObject? = info.draggingSource()
            let mask = info.draggingSourceOperationMask()

            if mask == .Copy || (source !== tableView && mask &== .Copy) {
                return .Copy
            } else if mask &== .Move && source === tableView {
                return .Move
            }
        }

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
