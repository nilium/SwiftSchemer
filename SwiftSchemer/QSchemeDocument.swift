//
// Copyright Noel Cower 2014.
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file ../LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
//

import Cocoa
import SnowKit


internal let QSchemeChangedNotification = "QSchemeChangedNotification"
internal let kQCannotWritePListException = "QCannotWritePropertyList"


class QSchemeDocument: NSDocument {

    @IBOutlet weak var colorControllerView: NSView!
    var editorColorController: QSchemeEditorColorController? = nil
    var schemeChangedObserver = QNotificationObserver.None
    var scheme: QScheme = QScheme() {
        didSet {
            scheme.revisionTracker = QRevisionTracker(undoManager)

            schemeChangedObserver.disconnect()
            schemeChangedObserver =
                observeNotification(sentBy: scheme, named: QSchemeChangedNotification) { [weak self] _ in
                    self?.updateChangeCount(.ChangeDone)
                    return
            }

            if let con = editorColorController {
                con.scheme = scheme
            }

            if let con = ruleController? {
                con.scheme = scheme
            }

            if let con = selectorController? {
                con.scheme = scheme
                con.selectedRule = nil
            }
        }
    }

    @IBOutlet var selectorController: QSelectorTableController!

    var selectedRuleObserver = QNotificationObserver.None
    @IBOutlet var ruleController: QRuleTableController! {
        didSet(previous) {
            disconnectObserver(&selectedRuleObserver)

            if ruleController == nil {
                return
            }

            // Use weak self here -- unowned self crashes for unknown reasons
            // at the moment. Haven't yet verified if the crash is with my code
            // or Swift's unowned retain count behavior yet. This is one of the
            // rare cases where I may actually get to blame the language or
            // compiler for a bug.
            selectedRuleObserver = observeNotification(
                sentBy: ruleController!,
                named: kQSelectedRuleChanged,
                updateSelectedRuleBlock
            )
        }
    }


    var updateSelectedRuleBlock: (NSNotification!) -> Void {
        return { [weak self] note in
            if let selCon = self?.selectorController? {
                selCon.selectedRule = note.userInfo?[kQSelectedRuleInfo] as? QSchemeRule
            }
        }
    }


    override init() {
        super.init()
        scheme = QScheme()
        scheme.revisionTracker = QRevisionTracker(undoManager)
    }


    deinit {
        selectedRuleObserver.disconnect()
        schemeChangedObserver.disconnect()
    }


    override func windowControllerDidLoadNib(aController: NSWindowController) {
        super.windowControllerDidLoadNib(aController)
        loadColorControllerForScheme(scheme)

        ruleController.scheme = scheme
        selectorController.scheme = scheme
        selectorController.selectedRule = nil
    }


    override class func autosavesInPlace() -> Bool {
        return true
    }


    override class func usesUbiquitousStorage() -> Bool {
        return false
    }


    override var windowNibName: String {
        return "SchemeDocument"
    }


    override func writeToURL(url: NSURL!, ofType typeName: String!, error outError: NSErrorPointer) -> Bool {
        var plist = scheme.toPropertyList()
        var name = url.lastPathComponent.stringByDeletingPathExtension
        plist["name"] = name

        let nsPList: NSDictionary = plist
        if !nsPList.writeToURL(url, atomically: false) {
            outError.memory = NSError(domain: kQCannotWritePListException, code: 3, userInfo: [
                "url": url,
                "type": typeName
                ])
            return false
        }

        return true
    }


    override func readFromURL(url: NSURL!, ofType typeName: String!, error outError: NSErrorPointer) -> Bool {
        let plist: QPropertyList = NSDictionary(contentsOfURL: url)
        scheme = QScheme(propertyList: plist)
        return true
    }


    /// Loads the SchemeEditorColors view and swaps out its placeholder with
    /// itself. The scheme will then have its colors hooked up to the view.
    private func loadColorControllerForScheme(scheme: QScheme) {
        if editorColorController == nil {
            let vc = QSchemeEditorColorController(
                scheme: self.scheme,
                nibName: "SchemeEditorColors",
                bundle: NSBundle.mainBundle()
            )

            colorControllerView.replaceInSuperviewWithView(vc.view, preservingConstraints: true)

            editorColorController = vc
            colorControllerView = vc.view
        }
    }

}
