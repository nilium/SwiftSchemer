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


let kQRulePasteType = "net.spifftastic.Schemer.RulePaste"


private func objectIsRulePaste(obj: AnyObject!) -> Bool {
    if let pasteItem = obj as? NSPasteboardItem {
        return pasteItem.types.bridgeToObjectiveC().containsObject(kQRulePasteType)
    }
    return false
}


private func pasteItemToRulePropertyList(obj: AnyObject!) -> QPropertyList {
    return (obj as NSPasteboardItem).propertyListForType(kQRulePasteType) as NSDictionary
}


extension QRuleTableSource {

    func tableView(
        tableView: NSTableView!,
        acceptDrop info: NSDraggingInfo!,
        row: Int,
        dropOperation: NSTableViewDropOperation
        ) -> Bool
    {
        if dropOperation == .On || !scheme {
            return false
        }

        var newRow = row
        let mask = info.draggingSourceOperationMask()
        let source: AnyObject? = info.draggingSource()
        let pasteboard = info.draggingPasteboard()

        let items = pasteboard.readObjectsForClasses([NSPasteboardItem.self], options: nil)
            .filter(objectIsRulePaste)
            .map(pasteItemToRulePropertyList)

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

        var newRules = scheme!.rules.withoutIndices(indices)
        let pastedRules = items.map { QSchemeRule(propertyList: $0["rule"] as NSDictionary) }

        if newRow >= newRules.count {
            newRules += pastedRules
        } else {
            newRules.replaceRange(newRow ..< newRow, with: pastedRules)
        }

        scheme!.rules = newRules
        tableView.reloadData()

        return true
    }


    func tableView(
        tableView: NSTableView!,
        validateDrop info: NSDraggingInfo!,
        proposedRow row: Int,
        proposedDropOperation dropOperation: NSTableViewDropOperation
        ) -> NSDragOperation
    {
        if !scheme {
            return .None
        }

        if dropOperation != .Above {
            tableView.setDropRow(row, dropOperation: .Above)
        }

        if row >= 0 && row <= scheme!.rules.count {
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
        if let scheme = self.scheme {
            let item = NSPasteboardItem()
            let plist: NSDictionary = [
                "row": row.bridgeToObjectiveC(),
                "rule": scheme.rules[row].toPropertyList().bridgeToObjectiveC()
            ]

            item.setPropertyList(plist, forType: kQRulePasteType)
            return item
        }
        return nil
    }

}
