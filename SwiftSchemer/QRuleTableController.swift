//
// Copyright Noel Cower 2014.
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file ../LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
//

import Cocoa
import SnowKit


let kQSelectedRuleChanged = "kQSelectedRuleChanged"
let kQSelectedRuleInfo = "rule"

private let kQRuleColumnName = "rule_name"
private let kQRuleColumnForeground = "rule_foreground"
private let kQRuleColumnBackground = "rule_background"
private let kQRuleColumnFlags = "rule_flags"


class QRuleTableController: NSObject, NSTableViewDelegate {

    @IBOutlet weak var table: NSTableView? = nil {
        didSet(previous) {
            if let p = previous { disconnectTableView(p) }
            if let t = table { connectTableView(t) }
        }
    }

    var scheme: QScheme? = nil {
        didSet {
            source.scheme = scheme
            table?.reloadData()
        }
    }

    let source = QRuleTableSource()


    func disconnectTableView(view: NSTableView) {
        view.setDelegate(nil)
        view.setDataSource(nil)
        view.target = nil
        view.action = nil
        view.doubleAction = nil
    }


    func connectTableView(view: NSTableView) {
        view.target = self
        view.action = nil
        view.doubleAction = "doubleClickedTableView:"
        view.setDelegate(self)
        view.setDataSource(source)
    }


    func doubleClickedTableView(view: NSTableView) {
        // TODO: Trigger editing of rule label if label is double-clicked.
    }


    func tableView(tableView: NSTableView!, viewForTableColumn tableColumn: NSTableColumn!, row: Int) -> NSView! {
        if !scheme {
            return nil
        }

        if let view = tableView.makeViewWithIdentifier(tableColumn.identifier, owner: self) as? NSControl {
            bindView(view, toRule: scheme!.rules[row], forColumn: tableColumn)
            return view
        }
        return nil
    }


    // Calls the assign(color) block with the color from the given colorWell.
    // Returns a block that can be passed as the bound action for a color well.
    func updateRowWithColor(assign: (NSColor) -> Void) -> (NSColorWell) -> Void {
        return { [weak self] colorWell in
            if let con = self {
                if !con.table {
                    return
                }

                let row = con.table!.rowForView(colorWell)
                if row == -1 {
                    return
                }

                assign(colorWell.color)

                if let nameColumn = con.table!.tableColumnWithIdentifier(kQRuleColumnName)? {
                    if let columnIndex = indexOfObject(con.table!.tableColumns!, nameColumn) {
                        con.table!.reloadDataForRowIndexes(NSIndexSet(index: row), columnIndexes: NSIndexSet(index: columnIndex))
                    }
                }
            }
        }
    }


    /// Hooks up a view to its column and rule.
    func bindView(view: NSControl, toRule rule: QSchemeRule, forColumn column: NSTableColumn) {
        switch column.identifier {
        case kQRuleColumnName:
            let text: NSTextField = view as NSTextField
            text.stringValue = rule.name

        case kQRuleColumnBackground:
            let well: NSColorWell = view as NSColorWell
            well.color = rule.background
            bindAction(well, updateRowWithColor { rule.background = $0 })

        case kQRuleColumnForeground:
            let well: NSColorWell = view as NSColorWell
            well.color = rule.foreground
            bindAction(well, updateRowWithColor { rule.foreground = $0 })

        case kQRuleColumnFlags:
            view.target = self
            view.action = "updateRuleFlags:"

            assert(view as? NSSegmentedControl, "Column view must be an NSSegmentedControl")
            let seg: NSSegmentedControl! = view as? NSSegmentedControl
            seg.setSelected(contains(rule.flags, { $0.isBold }), forSegment: 0)
            seg.setSelected(contains(rule.flags, { $0.isItalic }), forSegment: 0)
            seg.setSelected(contains(rule.flags, { $0.isUnderline }), forSegment: 0)

        case let unknownIdent:
            debugPrint("Unrecognized rule table column specified: \(unknownIdent)")
        }
    }


    func tableViewSelectionDidChange(note: NSNotification!) {
        if let view = note.object as? NSTableView {
            let indices = view.selectedRowIndexes
            let selectedRule = indices.count != 1 ? nil : scheme?.rules[indices.firstIndex]
            let info: [NSObject: AnyObject]? =
            selectedRule
                ? [kQSelectedRuleInfo: selectedRule!]
                : nil

            notify(kQSelectedRuleChanged, from: self, info: info)
        }
    }

}
