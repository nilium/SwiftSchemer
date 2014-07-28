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



// MARK: Drag & Drop

let kQRulePasteType = "net.spifftastic.Schemer.RulePaste"


internal func pasteItemToRulePropertyList(obj: AnyObject!) -> QPropertyList {
    return (obj as NSPasteboardItem).propertyListForType(kQRulePasteType) as NSDictionary
}


extension QRuleTableSource {


    func acceptRuleDrop(
        tableView: NSTableView!,
        info: NSDraggingInfo,
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

        let items = pasteboard.readObjectsForClasses([NSPasteboardItem.self],
            options: [NSPasteboardURLReadingContentsConformToTypesKey: [kQRulePasteType]])
            .map(pasteItemToRulePropertyList)

        if items.isEmpty {
            return false
        }

        let indicesToRemove = NSMutableIndexSet()

        if mask &== .Move && source === tableView {
            for item in items {
                let itemRow: Int = item["row"] as NSNumber

                indicesToRemove.addIndex(itemRow)
                if itemRow < row {
                    newRow -= 1
                }
            }
        }

        var newRules = scheme!.rules.withoutIndices(indicesToRemove)
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


    func acceptSelectorDrop(
        tableView: NSTableView!,
        info: NSDraggingInfo,
        row: Int,
        dropOperation: NSTableViewDropOperation
        ) -> Bool
    {
        if dropOperation != .On || !scheme {
            return false
        }

        var newRow = row
        let pasteboard = info.draggingPasteboard()
        let mask = info.draggingSourceOperationMask()

        let items = pasteboard.readObjectsForClasses([NSPasteboardItem.self],
            options: [NSPasteboardURLReadingContentsConformToTypesKey: [kQSelectorPasteType]])
            .map(pasteItemToSelectorPropertyList)

        let rule = scheme!.rules[row]
        var newSelectors = rule.selectors
        let pastedSelectors: [String] = items.map { $0["selector"] as NSString }

        newSelectors += pastedSelectors
        rule.selectors = newSelectors

        return true
    }


    func tableView(
        tableView: NSTableView!,
        acceptDrop info: NSDraggingInfo!,
        row: Int,
        dropOperation: NSTableViewDropOperation
        ) -> Bool
    {
        let pasteboard = info.draggingPasteboard()
        let types = pasteboard.types as [String]
        if types.count != 1 {
            NSLog("Rule table drop received no or mixed types: %@", types)
            return false
        }

        switch types[0] {
        case kQRulePasteType:
            return acceptRuleDrop(tableView, info: info, row: row, dropOperation: dropOperation)
        case kQSelectorPasteType:
            return acceptSelectorDrop(tableView, info: info, row: row, dropOperation: dropOperation)
        case let type:
            debugPrint("Unrecognized paste type: \(type)")
            return false
        }
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

        let mask = info.draggingSourceOperationMask()
        let pasteboard = info.draggingPasteboard()
        let source: AnyObject? = info.draggingSource()
        let types = pasteboard.types as [String]

        if types.count != 1 {
            return .None
        }

        switch types[0] {
        case kQRulePasteType:
            if dropOperation != .Above {
                tableView.setDropRow(row, dropOperation: .Above)
            }

            if row >= 0 && row <= scheme!.rules.count {
                if mask == .Copy || (source !== tableView && mask &== .Copy) {
                    return .Copy
                } else if mask &== .Move && source === tableView {
                    return .Move
                }
            }

        case kQSelectorPasteType:
            if dropOperation != .On {
                tableView.setDropRow(row, dropOperation: .On)
            }

            if mask &== .Copy && row >= 0 && row < scheme!.rules.count {
                return .Copy
            }

        case let type:
            debugPrint("Unrecognized paste type \(type)")
            return .None
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
