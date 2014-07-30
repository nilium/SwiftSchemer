//
// Copyright Noel Cower 2014.
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file ../LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
//

import Cocoa
import SnowKit


private let QSelectorTagAdd = 0
private let QSelectorTagRemove = 1


class QSelectorTableController: NSObject, NSTableViewDelegate {

    /// selectorTable data source
    let dataSource = QSelectorTableSource()

    var needsUpdate: Bool = true
    var scheme: QScheme? = nil {
        didSet {
            dataSource.scheme = scheme
        }
    }

    var selectorsObserver = QKeyValueObserver.None
    var selectedRule: QSchemeRule? = nil {
        didSet (previous) {
            selectorsObserver.disconnect()
            dataSource.rule = selectedRule
            selectorTable?.reloadData()
            addButtonEnabled = selectedRule != nil

            if previous !== selectedRule {
                selectorTable?.deselectAll(self)
            }

            if let rule = selectedRule {
                selectorsObserver = observeKeyPath("selectors", ofObject: rule, options: []) { [weak self] _, _, _ in
                    if self?.needsUpdate ~| false {
                        self?.selectorTable?.reloadData()
                    }
                }
            }
        }
    }

    @IBOutlet weak var selectorTable: NSTableView? = nil {
        didSet (previous) {
            if let p = previous { disconnectTableView(p) }
            if let n = selectorTable { connectTableView(n) }
        }
    }

    @IBOutlet weak var addRemoveButtons: NSSegmentedControl? {
        didSet {
            addButtonEnabled = selectedRule != nil
            removeButtonEnabled = (selectorTable?.selectedRowIndexes.count ~| 0) > 0
        }
    }


    deinit {
        selectorsObserver.disconnect()
    }


    func disconnectTableView(table: NSTableView) {
        table.setDelegate(nil)
        table.setDataSource(nil)
    }


    func connectTableView(table: NSTableView) {
        table.setDelegate(self)
        table.setDataSource(dataSource)
        table.reloadData()

        table.registerForDraggedTypes([kQSelectorPasteType])
        table.setDraggingSourceOperationMask(.Move | .Copy, forLocal: true)
    }


    @IBAction func pressAddRemove(sender: NSSegmentedControl) {
        assert(selectedRule != nil, "attempt to add/remove when rule is nil")
        assert(selectorTable != nil, "attempt to add/remove when table is nil")

        let table = selectorTable!

        let seg = sender.selectedSegment
        let cell = sender.selectedCell() as NSSegmentedCell
        let tag = cell.tagForSegment(seg)

        switch tag {
        case QSelectorTagAdd:
            needsUpdate = false

            let newRow = selectedRule!.selectors.count
            selectedRule!.selectors += "selector"

            table.beginUpdates()
            table.insertRowsAtIndexes(NSIndexSet(index: newRow), withAnimation: NSTableViewAnimationOptions.EffectNone)
            table.endUpdates()
            table.scrollRowToVisible(newRow + 1)
            table.editColumn(0, row: newRow, withEvent: nil, select: true)

            needsUpdate = true

        case QSelectorTagRemove:
            needsUpdate = false

            let indices = selectorTable!.selectedRowIndexes

            table.beginUpdates()
            selectorTable?.removeRowsAtIndexes(indices, withAnimation: NSTableViewAnimationOptions.SlideRight)
            table.endUpdates()

            var newSelectors = self.selectedRule!.selectors
            indices.enumerateIndexesWithOptions(.Reverse) { i, _ in
                newSelectors.removeAtIndex(i)
                return
            }
            self.selectedRule!.selectors = newSelectors

            needsUpdate = true

        default:
            assert(false, "Invalid segment tag")
        }
    }


    // Properties for adjusting the add/removed segments of addRemoveButtons.
    // Getters for both will return false if the buttons haven't been loaded,
    // setters will do nothing if unloaded.
    var addButtonEnabled: Bool {
        get { return addRemoveButtons?.isEnabledForSegment(0) ~| false }
        set { addRemoveButtons?.setEnabled(newValue, forSegment: 0) }
    }


    var removeButtonEnabled: Bool {
        get { return addRemoveButtons?.isEnabledForSegment(1) ~| false }
        set { addRemoveButtons?.setEnabled(newValue, forSegment: 1) }
    }


    func tableViewSelectionDidChange(notification: NSNotification!) {
        if let table = selectorTable {
            removeButtonEnabled = table.selectedRowIndexes.count > 0
        }
    }

}
