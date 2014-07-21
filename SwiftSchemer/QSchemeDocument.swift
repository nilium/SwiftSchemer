//
// Copyright Noel Cower 2014.
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file ../LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
//

import Cocoa
import SnowKit


class QSchemeDocument: NSDocument {

    @IBOutlet weak var colorControllerView: NSView!
    var editorColorController: QSchemeEditorColorController? = nil
    var scheme: QScheme = QScheme() {
        didSet {
            if let con = editorColorController {
                con.scheme = scheme
            }

            if let con = ruleController? {
                con.scheme = scheme
            }

            if let con = selectorController? {
                con.selectedRule = nil
            }
        }
    }

    @IBOutlet var selectorController: QSelectorTableController!

    var selectedRuleObserver = QNotificationObserver.None
    @IBOutlet var ruleController: QRuleTableController! {
        didSet(previous) {
            disconnectObserver(&selectedRuleObserver)

            if !(ruleController?) {
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


    init() {
        super.init()

        // TODO: Remove dummy data
        let rule = QSchemeRule()
        rule.selectors = ["foo.bar.baz", "wimbleton", "entity.name.function"]
        scheme.rules += rule
        scheme.rules += QSchemeRule()
        scheme.rules += QSchemeRule()
        scheme.rules += QSchemeRule()
        scheme.rules += QSchemeRule()
    }


    deinit {
        disconnectObserver(&selectedRuleObserver)
    }


    override func windowControllerDidLoadNib(aController: NSWindowController) {
        super.windowControllerDidLoadNib(aController)
        loadColorControllerForScheme(scheme)

        ruleController.scheme = scheme
    }


    override class func autosavesInPlace() -> Bool {
        return true
    }


    override var windowNibName: String {
        return "SchemeDocument"
    }


    override func dataOfType(typeName: String?, error outError: NSErrorPointer) -> NSData? {
        // TODO: Handle tmTheme saving (use URL-based read/save)
        // Insert code here to write your document to data of the specified type.
        // If outError != nil, ensure that you create and set an appropriate error when
        // returning nil.
        // You can also choose to override fileWrapperOfType:error:,
        // writeToURL:ofType:error:, or
        // writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
        outError.memory = NSError.errorWithDomain(NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
        return nil
    }


    override func readFromData(data: NSData?, ofType typeName: String?, error outError: NSErrorPointer) -> Bool {
        // TODO: Handle tmTheme loading (use URL-based read/save)
        // Insert code here to read your document from the given data of the
        // specified type. If outError != nil, ensure that you create and set
        // an appropriate error when returning false.
        // You can also choose to override readFromFileWrapper:ofType:error:
        // or readFromURL:ofType:error: instead.
        // If you override either of these, you should also override
        // -isEntireFileLoaded to return NO if the contents are lazily loaded.
        outError.memory = NSError.errorWithDomain(NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
        return false
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

