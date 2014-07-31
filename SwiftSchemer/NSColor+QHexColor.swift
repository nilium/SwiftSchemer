//
// Copyright Noel Cower 2014.
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file ../LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
//

import Cocoa


private let AlphaEpsilon: CGFloat = 1.0 / 255.0


extension NSColor {

    /// Returns the receiver in the color space expected for color schemes.
    func colorUsingSchemeColorSpace() -> NSColor {
        return colorUsingColorSpaceName(NSDeviceRGBColorSpace)
    }


    /// Returns a [CGFloat] of components held by the color. If it's not
    /// possible to get the components (or does not have components), this will
    /// likely raise an exception, which cannot be handled because not
    /// everything plays nice with Swift.
    var unsafeComponents: [CGFloat] {
        let count = numberOfComponents
        if count <= 0 {
            return []
        }
        var result = [CGFloat](count: count, repeatedValue: 0.0)
        self.getComponents(&result)
        return result
    }


    /// Linearly interpolates from the receiver color to toColor by alpha and
    /// returns the resulting color.
    func lerp(toColor: NSColor, alpha: CGFloat) -> NSColor {
        let rhsColor = toColor.colorUsingColorSpace(colorSpace)
        var lhsComponents = self.unsafeComponents
        var rhsComponents = rhsColor.unsafeComponents
        let gamma = max(min(alpha, 0.0), 1.0)
        let beta = 1.0 - gamma
        let numComponents = countElements(lhsComponents)

        for index in 0 ..< numComponents {
            lhsComponents[index] = lhsComponents[index]*beta + rhsComponents[index]*gamma
        }

        return NSColor(colorSpace: colorSpace, components: lhsComponents, count: numComponents)
    }


    /// Converts the receiver to a hex color string (`#RRGGBB` or `#RRGGBBAA`).
    /// The alpha component is ignored if 0xFF.
    func toHexString() -> String {
        let RGBFormat = "#%0.2hhx%0.2hhx%0.2hhx"
        let RGBAFormat = "#%0.2hhx%0.2hhx%0.2hhx%0.2hhx"

        let color = colorUsingSchemeColorSpace()

        let r = floatToOctet(color.redComponent)
        let g = floatToOctet(color.greenComponent)
        let b = floatToOctet(color.blueComponent)
        let a = floatToOctet(color.alphaComponent)

        if (a >= 255) {
            return String(format: RGBFormat, r, g, b)
        } else {
            return String(format: RGBAFormat, r, g, b, a)
        }
    }


    /// Creates and returns an NSColor for a hex color string in the expected
    /// color scheme color space.
    /// Only accepts forms `#RRGGBB` and `#RRGGBBAA`.
    class func fromHexString(hexString: String) -> NSColor? {
        var colorInt32: UInt32 = 0
        var colorInt: UInt
        let scanner = NSScanner(string: hexString)

        if !scanner.scanString("#", intoString: nil) {
            return nil
        }

        if !scanner.scanHexInt(&colorInt32) {
            return nil
        }

        colorInt = UInt(colorInt32)
        var a: CGFloat = 1.0
        if countElements(hexString) > 7 {
            a = octetToFloat(colorInt)
            colorInt >>= 8
        }

        let b = octetToFloat(colorInt)
        let g = octetToFloat(colorInt >> 8)
        let r = octetToFloat(colorInt >> 16)

        return NSColor(deviceRed: r, green: g, blue: b, alpha: a)
    }


    /// Gets whether the color would be visible in a color scheme.
    func isVisible() -> Bool {
        return alphaComponent >= AlphaEpsilon
    }

}
