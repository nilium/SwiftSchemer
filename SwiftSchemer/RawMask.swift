//
// Copyright Noel Cower 2014.
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file ../LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
//

import Foundation


infix operator &== { associativity none precedence 130 }


func &== <T: RawRepresentable where T.Raw: UnsignedIntegerType>(lhs: T, rhs: T) -> Bool {
    let rhsRaw: T.Raw = rhs.toRaw()
    let lhsRaw: T.Raw = lhs.toRaw()
    return (lhsRaw & rhsRaw) == rhsRaw
}
