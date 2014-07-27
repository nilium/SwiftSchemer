//
// Copyright Noel Cower 2014.
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file ../LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
//

import Cocoa
import SnowKit


/// Type alias for property lists. Just a Swift NSDictionary.
typealias QPropertyList = [NSObject: AnyObject]


/// Converts an octet stored in a UInt's MSB to a CGFloat. Uses UInt to permit
/// for bitwise or-ing of the result with other octets. The MSB be be scaled to
/// a float in the range of 0 ... 1.0.
func octetToFloat(octet: UInt) -> CGFloat {
    return CGFloat(octet & 0xFF) / 255.0
}


/// Converts a CGFloat to an octet stored in a UInt's MSB (for bitwise or-ing).
/// The float should be in the range of 0.0 ... 1.0 and will be scaled to
/// 0 ... 255.
func floatToOctet(flt: CGFloat) -> UInt {
    return UInt(min(max(flt * 255.0, 0.0), 255.0)) & 0xFF
}


/// Wrapper around NSColor(white:alpha:) to get a white color in the color
/// space used by Schemer.
func whiteColor(white: CGFloat = 1.0, alpha: CGFloat = 1.0) -> NSColor {
    return NSColor(white: white, alpha: alpha).colorUsingSchemeColorSpace()
}


/// Assigns a hex color from plist[key], if defined. Otherwise, does nothing.
func assignColorFromPList(inout color: NSColor, plist: QPropertyList, key: String) {
    if let colorString = plist[key] as? NSString {
        color = NSColor.fromHexString(colorString) ~| color
    }
}


/// Assigns a hex color to plist[key] if the color has an alpha value >= 1/255.
/// If not visible, it is not stored in plist.
func putColorIfVisible(inout plist: QPropertyList, key: String, color: NSColor) {
    let alphaEpsilon: CGFloat = 1.0 / 255.0
    if (color.alphaComponent >= alphaEpsilon) {
        plist[key] = color.toHexString()
    }
}


// Monkey-patching find() because find() doesn't take a predicate and doesn't return anything useful.
// MARK: indexOf

/// Returns the index of the given object in the sequence. Looks for the
/// specific object, not a qualitatively equal object.
func indexOfObject<S: Sequence, T where T == S.GeneratorType.Element, T: AnyObject>(seq: S, item: T) -> Int? {
    return indexOf(seq) { $0 === item }
}


/// Returns the index of the first object in seq that is equal to item.
func indexOf<S: Sequence, T where T == S.GeneratorType.Element, T: Equatable>(seq: S, item: T) -> Int? {
    return indexOf(seq) { $0 == item }
}


/// Returns the index of the first object in seq that is equal to item, using
/// NSObject.isEqual.
func indexOf<S: Sequence, T where T == S.GeneratorType.Element, T: NSObjectProtocol>(seq: S, item: T) -> Int? {
    return indexOf(seq) { item.isEqual($0) }
}


/// Returns the index of the first object for which predicate(T) returns true.
func indexOf<S: Sequence, T, L where T == S.GeneratorType.Element, L: LogicValue>(seq: S, predicate: (T) -> L) -> Int? {
    for (i, e) in enumerate(seq) {
        if predicate(e) {
            return i
        }
    }
    return nil
}
