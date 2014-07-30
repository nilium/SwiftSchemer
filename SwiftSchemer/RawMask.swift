//
// Copyright Noel Cower 2014.
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file ../LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
//

import Foundation


operator infix &== { associativity none precedence 130 }


@infix func &== <T: RawRepresentable where T.RawType: UnsignedInteger>(lhs: T, rhs: T) -> Bool {
    let rhsRaw: T.RawType = rhs.toRaw()
    let lhsRaw: T.RawType = lhs.toRaw()
    return (lhsRaw & rhsRaw) == rhsRaw
}
