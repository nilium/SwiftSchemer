//
// Copyright Noel Cower 2014.
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file ../LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
//

import Cocoa
import SnowKit


let kQPropertyListSettingsKey = "settings"
private let whitespaceSet = NSCharacterSet.whitespaceAndNewlineCharacterSet()


enum QRuleFlag: Equatable {

    case Bold
    case Italic
    case Underline
    case Unknown(String)


    var name: String {
        switch self {
        case .Bold: return "bold"
        case .Italic: return "italic"
        case .Underline: return "underline"
        case let .Unknown(name): return name
        }
    }


    var isBold: Bool {
        switch self {
        case .Bold: return true
        default: return false
        }
    }


    var isItalic: Bool {
        switch self {
        case .Italic: return true
        default: return false
        }
    }


    var isUnderline: Bool {
        switch self {
        case .Underline: return true
        default: return false
        }
    }


    var isUnknown: Bool {
        switch self {
        case .Unknown: return true
        default: return false
        }
    }

}


func == (lhs: QRuleFlag, rhs: QRuleFlag) -> Bool {
    return (lhs.isBold && rhs.isBold)
    || (lhs.isItalic && rhs.isItalic)
    || (lhs.isUnderline && rhs.isUnderline)
    || (lhs.isUnknown && rhs.isUnknown && lhs.name == rhs.name)
}


private func convertRuleFlags(list: String?) -> [QRuleFlag] {
    let splitList = list?.componentsSeparatedByString(" ")

    if splitList == nil {
        return []
    }

    return splitList!.map { entry in
        switch entry.lowercaseString {
        case "bold":
            return QRuleFlag.Bold
        case "italic":
            return QRuleFlag.Italic
        case "underline":
            return QRuleFlag.Underline
        default:
            return QRuleFlag.Unknown(entry)
        }
    }
}


/* Inherits from NSObject for KVO */
class QSchemeRule: NSObject {

    var revisionTracker = QRevisionTracker()

    var name: NSString = "Unnamed Rule" {
        didSet { revisionTracker.addRevision("rule name change") { self.name = oldValue } }
    }

    var selectors: [String] = [] {
        didSet {
            revisionTracker.addRevision { self.selectors = oldValue }
        }
    }

    var foreground: NSColor = NSColor(white:0.0, alpha:0.0) {
        didSet { revisionTracker.addRevision("foreground color change") { self.foreground = oldValue } }
    }

    var background: NSColor = NSColor(white:1.0, alpha:0.0) {
        didSet { revisionTracker.addRevision("background color change") { self.background = oldValue } }
    }

    var flags: [QRuleFlag] = [] {
        didSet {
            revisionTracker.addRevision("rule style change") { self.flags = oldValue }
            flagsCounter = flagsCounter &+ 1
        }
    }

    private(set) var flagsCounter: Int = 0


    init(propertyList: QPropertyList) {
        super.init()

        if let settings = propertyList["settings"] as? NSDictionary {
            assignColorFromPList(&foreground, settings, "foreground")
            assignColorFromPList(&background, settings, "background")
            self.flags = convertRuleFlags(settings["fontStyle"] as? NSString)
        }

        name = propertyList["name"] as? NSString ?? name

        if let scope: String = propertyList["scope"] as? NSString {
            let splitScope = split(scope, {$0 == ","}, allowEmptySlices: false)
            selectors = splitScope.map { $0.stringByTrimmingCharactersInSet(whitespaceSet) }
        }
    }


    init(rule: QSchemeRule) {
        revisionTracker = rule.revisionTracker
        name = rule.name
        selectors = [String](rule.selectors)
        foreground = rule.foreground
        background = rule.background
    }


    override init() {
        super.init()
    }


    func toPropertyList() -> QPropertyList {
        var plist: QPropertyList = [
            "name": name,
            "scope": ", ".join(selectors)
        ]

        var settings = QPropertyList()

        putColorIfVisible(&settings, "foreground", foreground)
        putColorIfVisible(&settings, "background", background)

        if !flags.isEmpty {
            let flagsString = " ".join(flags.map { $0.name })
            settings["fontStyle"] = flagsString
        }

        plist["settings"] = settings

        return plist
    }

}
