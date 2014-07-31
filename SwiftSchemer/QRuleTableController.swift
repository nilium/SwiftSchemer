//
// Copyright Noel Cower 2014.
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file ../LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
//

import Cocoa
import SnowKit


// I don't know why, but this line needs to be here or Swift will begin to
// complain that NSTextField, NSSegmentedControl, and NSColorWell do not
// conform to QControlBindingProtocol -- which, normally, it doesn't, except
// that I've provided this conformance in QControlBinding.swift via an
// extension. So it seems like Swift doesn't know that NSControl exists here,
// but there's something odd about how it's deciding this code is
// valid/invalid.
//
// See, this line's at the top of the file. If I put it below any bindAction
// call, all bindAction calls after the declaration are valid, but all before
// the first introduction of NSControl are invalid. This is clearly some sort
// of strange compiler bug and maybe an optimization goof where it just won't
// pull in a type it's not aware of.
//
// The end result, at any rate, is that this line is required in order for any
// calls to bindAction to work, because otherwise Swift won't check supertypes
// -- namely NSControl -- for protocol conformance.
let _: NSControl?
// So yeah, point of this is, I'm not crazy.


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
    "flagsCounter": kQRuleColumnFlags,
]


class QRuleTableController: NSObject {

    /// Block type for observing a rule.
    typealias RuleObserverBlock = (String, QSchemeRule, NSDictionary) -> ()


    /// Override indicating whether the table view's reloadData method should
    /// be called. If true, reloadData should be called, if false, something
    /// else _must_ notify the table view of updates to its data.
    private var needsUpdate: Bool = true

    /// Buttons for adding new rules and removing selected rules
    @IBOutlet weak var addRemoveButtons: NSSegmentedControl? = nil

    /// The table view the controller is so-named for.
    @IBOutlet weak var table: NSTableView? = nil {
        didSet(previous) {
            if let p = previous { disconnectTableView(p) }
            if let t = table { connectTableView(t) }
        }
    }

    /// Key-value observers for observing the scheme and its rules
    var ruleObservers: [QKeyValueObserver] = []

    /// The color scheme to display the rules of.
    var scheme: QScheme? = nil {
        didSet {
            source.scheme = scheme
            reloadData()
        }
    }

    /// The NSTableViewDataSource for the table view.
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


    func refreshColumnNames() {
        if !scheme { return }

        if let table = self.table {
            table.backgroundColor = scheme!.viewportBackground

            let rows = NSIndexSet(indexesInRange: NSRange(0 ..< table.numberOfRows))
            if rows.count == 0 { return }

            let columnNameIndex = table.columnWithIdentifier(kQRuleColumnName)
            if columnNameIndex == -1 { return }

            let columnNameIndexSet = NSIndexSet(index: columnNameIndex)
            table.reloadDataForRowIndexes(rows, columnIndexes: columnNameIndexSet)
        }
    }


    func observerForRule(rule: QSchemeRule, row: Int) -> RuleObserverBlock {
        let rowIndex = NSIndexSet(index: row)

        return { [weak self] key, _, _ in
            let definedSelf: QRuleTableController! = self
            if !definedSelf { return }

            let table: NSTableView! = definedSelf.table
            if !table { return }

            let column = QRuleKeysToColumns[key]
            let columnIndex = table.columnWithIdentifier(column)
            if columnIndex == -1 { return }

            let columnIndices = NSMutableIndexSet(index: columnIndex)
            let nameIndex = table.columnWithIdentifier(kQRuleColumnName)
            if nameIndex != -1 {
                columnIndices.addIndex(nameIndex)
            }

            table.reloadDataForRowIndexes(rowIndex, columnIndexes: columnIndices)
        }
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

        definedTable.backgroundColor = definedScheme.viewportBackground
        for key in ["viewportBackground", "viewportForeground"] {
            ruleObservers += observeKeyPath(key, ofObject: definedScheme, options: []) { [weak self] _, _, _ in
                self?.refreshColumnNames()
                return
            }
        }

        ruleObservers += observeKeyPath("rules", ofObject: definedScheme, options: []) { [weak self] _, _, _ in
            self?.reloadData()
            return
        }

        if needsUpdate {
            definedTable.reloadData()
        }

        for (row, rule) in enumerate(definedScheme.rules) {
            let block = observerForRule(rule, row: row)

            for (key, column) in QRuleKeysToColumns {
                ruleObservers += observeKeyPath(key, ofObject: rule, options: [], block)
            }
        }
    }

}


// MARK: NSTableViewDelegate Implementation

extension QRuleTableController: NSTableViewDelegate {

    func tableView(tableView: NSTableView!, viewForTableColumn tableColumn: NSTableColumn!, row: Int) -> NSView! {
        if !scheme {
            return nil
        }

        if let view = tableView.makeViewWithIdentifier(tableColumn.identifier, owner: self) as? NSView {
            bindView(view, toRule: scheme!.rules[row], forColumn: tableColumn)
            return view
        }
        return nil
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

}


// MARK: Department of Observer-Trigger Data-Reload Mitigation

extension QRuleTableController {

    func shouldAutoUpdate(enabled: Bool, block: () -> ()) {
        let past = needsUpdate
        needsUpdate = enabled
        block()
        needsUpdate = past
    }

}


// MARK: Double-Click to Edit Name

extension QRuleTableController {

    func doubleClickedTableView(view: NSTableView) {
        let column = view.clickedColumn
        let row = view.clickedRow
        if column == -1 || row == -1 {
            return
        }

        if view.columnWithIdentifier(kQRuleColumnName) == column {
            view.editColumn(column, row: row, withEvent: nil, select: true)
        }
    }

}


// MARK: View Binding

private let QBoldSegmentIndex = 0
private let QItalicSegmentIndex = 1
private let QUnderlineSegmentIndex = 2


/// Style button segments with their associated indices and flags.
private let QStyleSegments: [(index: Int, flag: QRuleFlag)] = [
    (QBoldSegmentIndex, .Bold),
    (QItalicSegmentIndex, .Italic),
    (QUnderlineSegmentIndex, .Underline),
]


/// Converts a font to have, or not have, a given trait. Just a wrapper around
/// a font manager's convertFont:to(Not)?HaveTrait: methods.
private func convertFontWithTrait(hasTrait: Bool, #trait: NSFontTraitMask, #font: NSFont, #fontManager: NSFontManager) -> NSFont {
    if hasTrait {
        return fontManager.convertFont(font, toHaveTrait: trait)
    } else {
        return fontManager.convertFont(font, toNotHaveTrait: trait)
    }
}


/// Given a string, returns an NSAttributedString that has an underlined
/// attribute.
private func underlineString(str: String) -> NSAttributedString {
    return NSAttributedString(string: str, attributes: [
        NSUnderlineStyleAttributeName: NSUnderlineStyleSingle
        ])
}


extension QRuleTableController {

    func bindNameColumnView(text: NSTextField, toRule rule: QSchemeRule) {
        text.textColor = rule.foreground.isVisible()
            ? rule.foreground
            : (scheme!.viewportForeground)

        if rule.background.isVisible() {
            text.backgroundColor = rule.background
        } else {
            text.backgroundColor = scheme!.viewportBackground.colorWithAlphaComponent(0.5)
        }

        // Get rule's font style
        let (bold, italic, underline) = (
            contains(rule.flags, .Bold),
            contains(rule.flags, .Italic),
            contains(rule.flags, .Underline)
        )

        // Set the rule's bold/italic formatting via the font
        var font = NSFont.userFixedPitchFontOfSize(0.0)
        let fontManager = NSFontManager.sharedFontManager()
        font = convertFontWithTrait(bold, trait: .BoldFontMask, font: font, fontManager: fontManager)
        font = convertFontWithTrait(italic, trait: .ItalicFontMask, font: font, fontManager: fontManager)
        text.font = font

        // Apply underline formatting
        if underline {
            text.attributedStringValue = underlineString(rule.name)
        } else {
            text.stringValue = rule.name
        }

        bindAction(text) { sender in
            rule.name = sender.stringValue

            if underline {
                text.attributedStringValue = underlineString(rule.name)
            } else {
                text.stringValue = rule.name
            }
        }
    }


    func bindRuleColumnFlagsView(view: NSSegmentedControl, toRule rule: QSchemeRule) {
        for (index, flag) in QStyleSegments {
            view.setSelected(contains(rule.flags, flag), forSegment: index)
        }

        bindAction(view) { view in
            rule.flags = QStyleSegments
                .filter { index, _ in view.isSelectedForSegment(index) }
                .map { _, flag in flag }
                + rule.flags.filter { $0.isUnknown }
        }
    }


    /// Hooks up a view to its column and rule.
    func bindView(view: NSView, toRule rule: QSchemeRule, forColumn column: NSTableColumn) {
        switch column.identifier {
        case kQRuleColumnName where view is NSTextField:
            bindNameColumnView(view as NSTextField, toRule: rule)

        case kQRuleColumnBackground where view is NSColorWell:
            let well: NSColorWell = view as NSColorWell
            well.color = rule.background

            bindAction(well, updateRowWithColor { rule.background = $0 })

        case kQRuleColumnForeground where view is NSColorWell:
            let well: NSColorWell = view as NSColorWell
            well.color = rule.foreground

            bindAction(well, updateRowWithColor { rule.foreground = $0 })

        case kQRuleColumnFlags where view is NSSegmentedControl:
            bindRuleColumnFlagsView(view as NSSegmentedControl, toRule: rule)

        case kQRuleColumnName, kQRuleColumnBackground, kQRuleColumnForeground, kQRuleColumnFlags:
            NSLog("Got an expected column but an unexpected view type: \(view.className)")

        case let unknownIdent:
            NSLog("Unrecognized rule table column specified: \(unknownIdent)")
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

}


// MARK: Add / Remove Rule Buttons

private let QRuleTagAdd = 0
private let QRuleTagRemove = 1


extension QRuleTableController {

    var removeButtonEnabled: Bool {
        get { return addRemoveButtons?.isEnabledForSegment(1) ~| false }
        set { addRemoveButtons?.setEnabled(newValue, forSegment: 1) }
    }


    @IBAction func addRemoveButtonPressed(sender: NSSegmentedControl) {
        let seg = sender.selectedSegment
        let cell = sender.selectedCell() as NSSegmentedCell
        let tag = cell.tagForSegment(seg)

        shouldAutoUpdate(false) {
            switch tag {
            case QRuleTagAdd:
                self.addNewRule()
            case QRuleTagRemove:
                self.removeSelectedRules()
            case let unknown:
                NSLog("Unrecognized button tag \(unknown)")
            }
        }
    }


    func removeSelectedRules() {
        assert(scheme, "Scheme may not be nil")
        assert(table, "Table may not be nil")

        var newRules = scheme!.rules
        let rows = table!.selectedRowIndexes
        rows.enumerateIndexesWithOptions(.Reverse) { index, _ in
            newRules.removeAtIndex(index)
            return
        }
        scheme!.rules = newRules
        table!.removeRowsAtIndexes(rows, withAnimation: .SlideLeft)
    }


    func addNewRule() {
        assert(scheme, "Scheme may not be nil")
        assert(table, "Table may not be nil")

        if let scheme = self.scheme {
            scheme.rules += QSchemeRule()
            let newRowIndex = table!.numberOfRows
            let newRowIndexSet = NSIndexSet(index: newRowIndex)
            table!.insertRowsAtIndexes(newRowIndexSet, withAnimation: .EffectNone)
            table!.scrollRowToVisible(newRowIndex)

            let nameColumn = table!.columnWithIdentifier(kQRuleColumnName)
            if nameColumn != -1 {
                table!.selectRowIndexes(newRowIndexSet, byExtendingSelection: false)
                table!.editColumn(nameColumn, row: newRowIndex, withEvent: nil, select: true)
            }
        }
    }

}
