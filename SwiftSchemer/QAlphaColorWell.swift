//
// Copyright Noel Cower 2014.
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file ../LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
//

import Cocoa


private let kQShowsAlphaKey = "q_AlphaColorWell_showsAlpha"


/// An NSColorWell that optionally displays an alpha value. All colors assigned
/// to or retrieved from QAlphaColorWell are in the color space used by color
/// schemes.
@IBDesignable
class QAlphaColorWell: NSColorWell {

    /// Whether the color well should allow and display alpha values. If true,
    /// the color panel displayed by it will include an opacity slider.
    /// If false, the color panel will not display alpha and the alpha
    /// component of any color dropped on the well will be set to 1.0.
    @IBInspectable var showsAlpha: Bool = false


    override init(frame: NSRect) {
        super.init(frame: frame)
    }


    required init(coder: NSCoder) {
        showsAlpha = coder.decodeBoolForKey(kQShowsAlphaKey)
        super.init(coder: coder)
    }


    override func encodeWithCoder(coder: NSCoder) {
        coder.encodeBool(showsAlpha, forKey: kQShowsAlphaKey)
        super.encodeWithCoder(coder)
    }


    override func activate(exclusive: Bool) {
        NSColorPanel.sharedColorPanel().showsAlpha = showsAlpha
        super.activate(exclusive)
    }


    override var color: NSColor! {
        get { return super.color.colorUsingSchemeColorSpace() }
        set {
            if showsAlpha {
                super.color = newValue.colorUsingSchemeColorSpace()
            } else {
                super.color = newValue.colorWithAlphaComponent(1.0).colorUsingSchemeColorSpace()
            }
        }
    }

}
