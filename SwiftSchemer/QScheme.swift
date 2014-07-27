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

    var viewportBackground = blackColor
    var viewportForeground = whiteColor()

    var gutterBackground = unsetColor
    var gutterForeground = unsetColor

    var findHighlightBackground = unsetColor
    var findHighlightForeground = unsetColor

    var invisiblesForeground: NSColor = whiteColor(white: 0.75)
    var lineHighlight: NSColor = blackColor.colorWithAlphaComponent(0.07)
    var caretForeground: NSColor = blackColor

    var selectionFill: NSColor =
        NSColor.selectedTextBackgroundColor()
            .colorUsingSchemeColorSpace()

    var selectionBorder: NSColor =
        NSColor.selectedTextBackgroundColor()
            .colorUsingSchemeColorSpace()
            .colorWithAlphaComponent(0.0)

    var inactiveSelectionFill: NSColor =
        NSColor.selectedTextBackgroundColor()
            .colorUsingSchemeColorSpace()
            .colorWithAlphaComponent(0.5)

    var rules = [QSchemeRule]()

    let uuid: NSUUID


    init() {
        uuid = NSUUID.UUID()
    }


    init(propertyList: NSDictionary) {
        let settingsAry = propertyList["settings"]? as? NSArray

        assert(settingsAry?, "Cannot initialize scheme without valid property list")

        let baseRules = getBaseRuleDictionary(settingsAry!)!
        let rules = getSyntaxRuleDictionaries(settingsAry!)

        if let uuidString = baseRules["uuid"]? as? NSString {
            uuid = NSUUID(UUIDString: uuidString)
        } else {
            uuid = NSUUID.UUID()
        }

        assignColorFromPList(&viewportBackground, baseRules, "background")
        assignColorFromPList(&viewportForeground, baseRules, "foreground")

        assignColorFromPList(&gutterBackground, baseRules, "gutterBackground")
        assignColorFromPList(&gutterForeground, baseRules, "gutterForeground")

        assignColorFromPList(&findHighlightBackground, baseRules, "findHighlight")
        assignColorFromPList(&findHighlightForeground, baseRules, "findHighlightForeground")

        assignColorFromPList(&invisiblesForeground, baseRules, "invisibles")
        assignColorFromPList(&lineHighlight, baseRules, "lineHighlight")
        assignColorFromPList(&caretForeground, baseRules, "caret")

        assignColorFromPList(&selectionFill, baseRules, "selection")
        assignColorFromPList(&selectionBorder, baseRules, "selectionBorder")
        assignColorFromPList(&inactiveSelectionFill, baseRules, "inactiveSelection")
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

        putColorIfVisible(&settings, "gutterForeground", gutterForeground)
        putColorIfVisible(&settings, "gutterBackground", gutterBackground)

        putColorIfVisible(&settings, "findHighlightForeground", findHighlightForeground)
        putColorIfVisible(&settings, "findHighlight", findHighlightBackground)

        putColorIfVisible(&settings, "invisibles", invisiblesForeground)
        putColorIfVisible(&settings, "lineHighlight", lineHighlight)
        putColorIfVisible(&settings, "caret", caretForeground)

        putColorIfVisible(&settings, "selection", selectionFill)
        putColorIfVisible(&settings, "selectionBorder", selectionBorder)
        putColorIfVisible(&settings, "inactiveSelection", inactiveSelectionFill)

        baseRules.append(settings)

        for rule in rules {
            baseRules.append(rule.toPropertyList())
        }

        return plist
    }

}
