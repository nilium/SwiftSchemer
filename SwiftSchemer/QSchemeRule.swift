//
// Copyright Noel Cower 2014.
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file ../LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
//

import Cocoa
import SnowKit


let kQPropertyListSettingsKey = "settings"
private let whitespaceSet = NSCharacterSet.whitespaceAndNewlineCharacterSet()


enum QRuleFlag {

    case Bold
    case Italic
    case Underline
    case Unknown(named: String)


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


private func convertRuleFlags(list: String?) -> [QRuleFlag] {
    let splitList = list?.componentsSeparatedByString(" ")

    if !splitList {
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
            return QRuleFlag.Unknown(named: entry)
        }
    }
}


/* Inherits from NSObject for KVO */
class QSchemeRule: NSObject {

    var name = "Unnamed Rule"
    var selectors = [String]()
    var foreground = NSColor(white:0.0, alpha:0.0)
    var background = NSColor(white:1.0, alpha:0.0)
    var flags: [QRuleFlag] = []


    init(propertyList: QPropertyList) {
        super.init()

        if let settings = (propertyList["settings"] as? NSDictionary) as? QPropertyList {
            assignColorFromPList(&foreground, settings, "foreground")
            assignColorFromPList(&background, settings, "background")
        }

        name = propertyList["name"]? as? NSString ~| name

        self.flags = convertRuleFlags(propertyList["fontStyle"] as? NSString)
        if let scope: String = propertyList["scope"]? as? NSString {
            let splitScope = split(scope as String, {$0 == ","}, allowEmptySlices: false)
            selectors = splitScope.map { $0.stringByTrimmingCharactersInSet(whitespaceSet) }
        }
    }


    init(rule: QSchemeRule) {
        name = rule.name
        selectors = [String](rule.selectors)
        foreground = rule.foreground
        background = rule.background
    }


    init() {
        /* nop */
    }


    func toPropertyList() -> QPropertyList {
        let flagsString = " ".join(flags.map { $0.name })

        var plist: QPropertyList = [
            "name": name,
            "selectors": "",
            "flags": flagsString,
        ]

        putColorIfVisible(&plist, "foreground", foreground)
        putColorIfVisible(&plist, "background", foreground)

        return plist
    }

}
