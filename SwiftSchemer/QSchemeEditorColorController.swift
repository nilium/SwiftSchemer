//
// Copyright Noel Cower 2014.
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file ../LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
//

import Cocoa
import SnowKit


class QSchemeEditorColorController: NSViewController {

    // The mountain of color well outlets for the base color options.
    @IBOutlet weak var viewBackWell: QAlphaColorWell!
    @IBOutlet weak var viewForeWell: QAlphaColorWell!

    @IBOutlet weak var gutterBackWell: QAlphaColorWell!
    @IBOutlet weak var gutterForeWell: QAlphaColorWell!

    @IBOutlet weak var findBackWell: QAlphaColorWell!
    @IBOutlet weak var findForeWell: QAlphaColorWell!

    @IBOutlet weak var caretWell: QAlphaColorWell!
    @IBOutlet weak var lineHLWell: QAlphaColorWell!
    @IBOutlet weak var invisiblesWell: QAlphaColorWell!

    @IBOutlet weak var selectionActiveWell: QAlphaColorWell!
    @IBOutlet weak var selectionInactiveWell: QAlphaColorWell!
    @IBOutlet weak var selectionBorderWell: QAlphaColorWell!


    var colorObserver: [QKeyValueObserver] = []
    /// Gets the controller's current scheme. May return nil.
    /// This is simply trying to cast the controller's representedObject to
    /// a QScheme when getting the value. When setting, it assigns the
    /// representedObject property.
    var scheme: QScheme! {
        set {
            disconnectObservers(&colorObserver)

            self.representedObject = newValue
            loadColorValues()

            if scheme == nil { return }

            colorObserver = QScheme.colorProperties.map { name in
                observeKeyPath(name, ofObject: self.scheme, options: []) { [weak self] _, _, _ in
                    self?.loadColorValues()
                    return
                }
            }
        }

        get {
            let represented: AnyObject? = self.representedObject
            return represented as? QScheme
        }
    }


    required init(scheme: QScheme, nibName: String?, bundle: NSBundle?) {
        assert(nibName != nil || bundle != nil, "At least nibName or bundle must be non-nil")
        super.init(nibName: nibName, bundle: bundle)
        self.scheme = scheme
    }


    required init(coder: NSCoder!) {
        super.init(coder: coder)
        // TODO: Add scheme serialization
        self.scheme = QScheme()
    }


    deinit {
        disconnectObservers(&colorObserver)
    }


    /// Set all well colors to those held by the scheme.
    func loadColorValues() {
        viewBackWell?.color = scheme.viewportBackground
        viewForeWell?.color = scheme.viewportForeground

        gutterBackWell?.color = scheme.gutterBackground
        gutterForeWell?.color = scheme.gutterForeground

        findBackWell?.color = scheme.findHighlightBackground
        findForeWell?.color = scheme.findHighlightForeground

        caretWell?.color = scheme.caretForeground
        lineHLWell?.color = scheme.lineHighlight
        invisiblesWell?.color = scheme.invisiblesForeground

        selectionActiveWell?.color = scheme.selectionFill
        selectionInactiveWell?.color = scheme.inactiveSelectionFill
        selectionBorderWell?.color = scheme.selectionBorder
    }


    override func loadView() {
        super.loadView()
        loadColorValues()
    }


    @IBAction func updateColor(sender: NSColorWell) {
        assert(viewBackWell != nil, "Cannot call updateColor until the controller's views are loaded")

        // What follows is not pretty, but happens to be fairly practical.
        switch sender {
        // Viewport colors
        case viewBackWell:
            scheme?.viewportBackground = sender.color
        case viewForeWell:
            scheme?.viewportForeground = sender.color

        // Gutter colors
        case gutterBackWell:
            scheme?.gutterBackground = sender.color
        case gutterForeWell:
            scheme?.gutterForeground = sender.color

        // Find highlights
        case findBackWell:
            scheme?.findHighlightBackground = sender.color
        case findForeWell:
            scheme?.findHighlightForeground = sender.color

        // Editor group
        case caretWell:
            scheme?.caretForeground = sender.color
        case lineHLWell:
            scheme?.lineHighlight = sender.color
        case invisiblesWell:
            scheme?.invisiblesForeground = sender.color

        // Selection colors
        case selectionActiveWell:
            scheme?.selectionFill = sender.color
        case selectionInactiveWell:
            scheme?.inactiveSelectionFill = sender.color
        case selectionBorderWell:
            scheme?.selectionBorder = sender.color

        default:
            NSLog("Received unrecognized color well as sender: \(sender)")
            return
        }

        if let scheme = self.scheme {
            notify(QSchemeChangedNotification, from: scheme)
        }
    }

}
