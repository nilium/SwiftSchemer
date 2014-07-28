//
//  RawMask.swift
//  SwiftSchemer
//
//  Created by Noel Cower on 07/27/14.
//  Copyright (c) 2014 Noel Cower. All rights reserved.
//

import Foundation


operator infix &== { associativity none precedence 130 }


@infix func &== <T: RawRepresentable where T.RawType: UnsignedInteger>(lhs: T, rhs: T) -> Bool {
    let rhsRaw: T.RawType = rhs.toRaw()
    let lhsRaw: T.RawType = lhs.toRaw()
    return (lhsRaw & rhsRaw) == rhsRaw
}
