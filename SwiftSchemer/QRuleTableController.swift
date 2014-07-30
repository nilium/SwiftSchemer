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


private let QRuleKeysToColumns = [
    "name": kQRuleColumnName,
    "foreground": kQRuleColumnForeground,
    "background": kQRuleColumnBackground,
]


class QRuleTableController: NSObject, NSTableViewDelegate {

    @IBOutlet weak var addRemoveButtons: NSSegmentedControl? = nil

    @IBOutlet weak var table: NSTableView? = nil {
        didSet(previous) {
            if let p = previous { disconnectTableView(p) }
            if let t = table { connectTableView(t) }
        }
    }

    var ruleObservers: [QKeyValueObserver] = []
    var scheme: QScheme? = nil {
        didSet {
            source.scheme = scheme
            reloadData()
        }
    }

    let source = QRuleTableSource()


    deinit {
        disconnectObservers(&ruleObservers)
    }


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

        view.registerForDraggedTypes([kQRulePasteType, kQSelectorPasteType])
        view.setDraggingSourceOperationMask(.Move | .Copy, forLocal: true)
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


    func reloadData() {
        disconnectObservers(&ruleObservers)

        // Assign two weak variables to auto-unwrapping optionals
        let definedTable: NSTableView! = self.table
        let definedScheme: QScheme! = self.scheme

        // Note: !(a && b) does not compile because it's a compiler bug.
        if !definedTable || !definedScheme {
            return
        }

        ruleObservers += observeKeyPath("rules", ofObject: definedScheme, options: []) { [weak self] _, _, _ in
            self?.reloadData()
            return
        }

        definedTable.reloadData()

        for (row, rule) in enumerate(definedScheme.rules) {
            let rowIndex = NSIndexSet(index: row)

            for (key, column) in QRuleKeysToColumns {
                ruleObservers += observeKeyPath(key, ofObject: rule, options: []) { [weak self] _, _, _ in
                    let definedSelf: QRuleTableController! = self
                    if !definedSelf { return }

                    let table: NSTableView! = definedSelf.table
                    if !table { return }

                    let columnIndex = table.columnWithIdentifier(column)
                    if columnIndex == -1 { return }

                    table.reloadDataForRowIndexes(rowIndex, columnIndexes: NSIndexSet(index: columnIndex))
                }
            }
        }
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
            seg.setSelected(contains(rule.flags, { $0.isItalic }), forSegment: 1)
            seg.setSelected(contains(rule.flags, { $0.isUnderline }), forSegment: 2)

        case let unknownIdent:
            NSLog("Unrecognized rule table column specified: \(unknownIdent)")
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

            removeButtonEnabled = indices.count > 0
        }
    }


    func removeSelectedRules() {
        assert(scheme, "Scheme may not be nil")
        assert(table, "Table may not be nil")

        var newRules = scheme!.rules
        table!.selectedRowIndexes.enumerateIndexesWithOptions(.Reverse) { index, _ in
            newRules.removeAtIndex(index)
            return
        }
        scheme!.rules = newRules
    }


    func addNewRule() {
    }


    var removeButtonEnabled: Bool {
        get { return addRemoveButtons?.isEnabledForSegment(1) ~| false }
        set { addRemoveButtons?.setEnabled(newValue, forSegment: 1) }
    }

}
