//
// Copyright Noel Cower 2014.
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file ../LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
//

import Cocoa


private func isBaseRulesDictionary(obj: AnyObject!) -> Bool {
    if let plist = obj as? QPropertyList {
        if plist["settings"]? {
            return plist.count == 1
        }
    }

    return false
}


private func getBaseRuleDictionary(settings: NSArray) -> QPropertyList? {
    let index = settings.indexOfObjectPassingTest() { (obj, _, _) -> Bool in
        isBaseRulesDictionary(obj)
    }

    if index == NSNotFound {
        return nil
    }

    return settings[index] as? QPropertyList
}


private func getSyntaxRuleDictionaries(settings: NSArray) -> [QPropertyList] {
    let pred = NSPredicate(block: { (obj, _) -> Bool in
            obj as? QPropertyList && !isBaseRulesDictionary(obj)
        })
    return settings.filteredArrayUsingPredicate(pred).filter { $0 is QPropertyList }.map { $0 as QPropertyList }
}


internal let blackColor = NSColor.blackColor().colorUsingSchemeColorSpace()
internal let unsetColor = whiteColor(white: 0.0, alpha: 0.0)


/* Inherits from NSObject for KVO */
class QScheme: NSObject {

    class var colorProperties: [String] {
        return [
            "viewportBackground",
            "viewportForeground",
            "gutterBackground",
            "gutterForeground",
            "findHighlightBackground",
            "findHighlightForeground",
            "invisiblesForeground",
            "lineHighlight",
            "caretForeground",
            "selectionFill",
            "selectionBorder",
            "inactiveSelectionFill",
            ]
    }


    // Document's revision tracker
    var revisionTracker = QRevisionTracker()

    // Viewport colors (i.e., default background/foreground)
    var viewportBackground: NSColor = blackColor {
        didSet { revisionTracker.addRevision { self.viewportBackground = oldValue } }
    }

    var viewportForeground: NSColor = whiteColor() {
        didSet { revisionTracker.addRevision { self.viewportForeground = oldValue } }
    }


    // Gutter colors
    var gutterBackground: NSColor = unsetColor {
        didSet { revisionTracker.addRevision { self.gutterBackground = oldValue } }
    }

    var gutterForeground: NSColor = unsetColor {
        didSet { revisionTracker.addRevision { self.gutterForeground = oldValue } }
    }


    // Find highlight colors
    var findHighlightBackground: NSColor = unsetColor {
        didSet { revisionTracker.addRevision { self.findHighlightBackground = oldValue } }
    }

    var findHighlightForeground: NSColor = unsetColor {
        didSet { revisionTracker.addRevision { self.findHighlightForeground = oldValue } }
    }


    // Editor colors
    var invisiblesForeground: NSColor = whiteColor(white: 0.75) {
        didSet { revisionTracker.addRevision { self.invisiblesForeground = oldValue } }
    }

    var lineHighlight: NSColor = blackColor.colorWithAlphaComponent(0.07) {
        didSet { revisionTracker.addRevision { self.lineHighlight = oldValue } }
    }

    var caretForeground: NSColor = blackColor {
        didSet { revisionTracker.addRevision { self.caretForeground = oldValue } }
    }


    // Selection colors
    var selectionFill: NSColor = NSColor.selectedTextBackgroundColor().colorUsingSchemeColorSpace() {
        didSet { revisionTracker.addRevision { self.selectionFill = oldValue } }
    }

    var selectionBorder: NSColor = NSColor.selectedTextBackgroundColor().colorUsingSchemeColorSpace().colorWithAlphaComponent(0.0) {
        didSet { revisionTracker.addRevision { self.selectionBorder = oldValue } }
    }

    var inactiveSelectionFill: NSColor = NSColor.selectedTextBackgroundColor().colorUsingSchemeColorSpace().colorWithAlphaComponent(0.5) {
        didSet { revisionTracker.addRevision { self.inactiveSelectionFill = oldValue } }
    }


    var rules: [QSchemeRule] = [] {
        didSet { revisionTracker.addRevision { self.rules = oldValue } }
    }


    // Not permitted to change unless instantiating a new QScheme or a copy.
    let uuid: NSUUID


    init() {
        uuid = NSUUID.UUID()
    }


    init(propertyList: QPropertyList) {
        let settingsAry = propertyList["settings"] as? NSArray

        assert(settingsAry?, "Cannot initialize scheme without valid property list")

        let baseRules = getBaseRuleDictionary(settingsAry!)!
        let plistRules = getSyntaxRuleDictionaries(settingsAry!)

        if let uuidString = baseRules["uuid"] as? NSString {
            uuid = NSUUID(UUIDString: uuidString)
        } else {
            uuid = NSUUID.UUID()
        }

        if let settings = (baseRules["settings"] as? NSDictionary) as? QPropertyList {
            assignColorFromPList(&viewportBackground, settings, "background")
            assignColorFromPList(&viewportForeground, settings, "foreground")

            assignColorFromPList(&gutterBackground, settings, "gutter")
            assignColorFromPList(&gutterForeground, settings, "gutterForeground")

            assignColorFromPList(&findHighlightBackground, settings, "findHighlight")
            assignColorFromPList(&findHighlightForeground, settings, "findHighlightForeground")

            assignColorFromPList(&invisiblesForeground, settings, "invisibles")
            assignColorFromPList(&lineHighlight, settings, "lineHighlight")
            assignColorFromPList(&caretForeground, settings, "caret")

            assignColorFromPList(&selectionFill, settings, "selection")
            assignColorFromPList(&selectionBorder, settings, "selectionBorder")
            assignColorFromPList(&inactiveSelectionFill, settings, "inactiveSelection")
        }

        for plistRule in plistRules {
            rules += QSchemeRule(propertyList: plistRule)
        }
    }


    // Initializes a scheme by copying the colors/settings of another scheme.
    // A new UUID is generated unless one is provided here.
    init(scheme: QScheme, uuid: NSUUID? = nil) {
        viewportBackground = scheme.viewportBackground
        viewportForeground = scheme.viewportForeground

        gutterBackground = scheme.gutterBackground
        gutterForeground = scheme.gutterForeground

        findHighlightForeground = scheme.findHighlightForeground
        findHighlightBackground = scheme.findHighlightBackground

        invisiblesForeground = scheme.invisiblesForeground
        lineHighlight = scheme.lineHighlight
        caretForeground = scheme.caretForeground

        selectionFill = scheme.selectionFill
        selectionBorder = scheme.selectionBorder
        inactiveSelectionFill = scheme.inactiveSelectionFill

        if uuid? {
            self.uuid = uuid!
        } else {
            self.uuid = NSUUID.UUID()
        }
    }


    func toPropertyList() -> QPropertyList {
        var plist = [NSObject: AnyObject]()

        var baseRules = [QPropertyList]()
        var settings = [NSObject: AnyObject]()

        putColorIfVisible(&settings, "foreground", viewportForeground)
        putColorIfVisible(&settings, "background",
            viewportBackground.colorWithAlphaComponent(1.0))

        putColorIfVisible(&settings, "gutter", gutterBackground)
        putColorIfVisible(&settings, "gutterForeground", gutterForeground)

        putColorIfVisible(&settings, "findHighlightForeground", findHighlightForeground)
        putColorIfVisible(&settings, "findHighlight", findHighlightBackground)

        putColorIfVisible(&settings, "invisibles", invisiblesForeground)
        putColorIfVisible(&settings, "lineHighlight", lineHighlight)
        putColorIfVisible(&settings, "caret", caretForeground)

        putColorIfVisible(&settings, "selection", selectionFill)
        putColorIfVisible(&settings, "selectionBorder", selectionBorder)
        putColorIfVisible(&settings, "inactiveSelection", inactiveSelectionFill)

        baseRules += ["settings": settings]
        baseRules += rules.map { $0.toPropertyList() }

        plist["uuid"] = uuid.UUIDString
        plist["settings"] = baseRules

        return plist
    }

}
