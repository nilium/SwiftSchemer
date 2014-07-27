//
// Copyright Noel Cower 2014.
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file ../LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
//

import Cocoa


/// Protocol for anything that can receive a bound action.
@objc public protocol QControlBindingProtocol {
    var target: AnyObject! { get set }
    var action: Selector { get set }
}


// Extensions for various AppKit classes to indicate they can receive bound
// actions.
extension NSControl: QControlBindingProtocol {}
extension NSActionCell: QControlBindingProtocol {}
extension NSStatusItem: QControlBindingProtocol {}
extension NSMenuItem: QControlBindingProtocol {}
extension NSToolbarItem: QControlBindingProtocol {}
extension NSFontManager: QControlBindingProtocol {}


extension NSObject {

    /// Returns whether the object has a bound action. If the receiver doesn't
    /// conform to QControlBindingProtocol, this will always return false. This
    /// returns true regardless of the type of the bound object (i.e., if the
    /// binding is non-nil, it will return true even if the binding is not a
    /// QControlBinding object).
    public var hasBoundAction: Bool {
        if self is QControlBindingProtocol {
            let obj: AnyObject? = objc_getAssociatedObject(self, kQActionBindingPtr)
            return !(!obj)
        }
        return false
    }


    /// removes any action bound to this object by bindAction. Returns true if
    /// an action was unbound, otherwise false. If the receiver doesn't conform
    /// to QControlBindingProtocol, this will always return false.
    public func removeBoundAction() -> Bool {
        if self is QControlBindingProtocol {
            return unbindAction(self as QControlBindingProtocol)
        }
        return false
    }

}


/// The associated object policy used for bound actions.
private let kQActionBindingPolicy = objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC)
/// The source variable for kQActionBindingPtr.
private var kQActionBindingSource: Int = 0xabad1dea
/// The key used to store bound action receivers as associated objects.
private let kQActionBindingPtr = ConstUnsafePointer<()>(withUnsafePointer(&kQActionBindingSource, { $0 }))


/// The receiver for bound actions.
private class QControlBinding: NSObject {

    internal typealias ActionBlock = (AnyObject?) -> Void

    private let block: ActionBlock


    internal init(block: ActionBlock) {
        self.block = block
    }


    internal func performedAction(sender: AnyObject!) {
        block(sender)
    }

}


/// Binds a control's action and target to the given block. The block receives
/// the sender of the action as its only parameter. If the action fires and
/// the sender is either nil or not of the type the block is bound to, it isn't
/// called.
public func bindAction<T: QControlBindingProtocol>(control: T, block: (T) -> Void) {
    // In order to avoid angering the compiler by making QControlBinding a
    // generic class, wrap the existing block in a block to do a cast from
    // AnyObject to T.
    let target = QControlBinding() { sender in
        assert(sender, "sender was nil")
        assert(sender as? T, "could not cast action sender to T")
        if let casted = sender as? T {
            block(casted)
        }
    }

    objc_setAssociatedObject(control, kQActionBindingPtr, target, kQActionBindingPolicy)
    control.action = "performedAction:"
    control.target = target
}


/// Unbinds any action currently bound to the given control. The control's
/// target is set to nil if and only if the control's bound object is its
/// target, otherwise it's left alone. Any bound object will still be discarded
/// regardless of whether it's still the target.
///
/// Returns whether the control had a bound QControlBinding instance to discard.
/// The object is not discarded if it is not a QControlBinding instance.
public func unbindAction<T: QControlBindingProtocol>(control: T) -> Bool {
    var hadObject = false
    if let obj: AnyObject? = objc_getAssociatedObject(control, kQActionBindingPtr) {
        hadObject = true
        if control.target === obj {
            control.target = nil
        }
    }
    objc_setAssociatedObject(control, kQActionBindingPtr, nil, kQActionBindingPolicy)
    return hadObject
}
