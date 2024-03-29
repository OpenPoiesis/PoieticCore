//
//  Variant+Comparison.swift
//
//  Comparison rules for Variant and its wrapped types VariantAtom and
//  VariantArray
//
//  Created by Stefan Urbanek on 06/03/2024.
//

extension VariantAtom {
    public static func <(lhs: VariantAtom, rhs: VariantAtom) throws -> Bool {
        switch (lhs, rhs) {
        case let (.int(lvalue), .int(rvalue)): return lvalue < rvalue
        case let (.int(lvalue), .double(rvalue)): return Double(lvalue) < rvalue
        case let (.double(lvalue), .int(rvalue)): return lvalue < Double(rvalue)
        case let (.double(lvalue), .double(rvalue)): return lvalue < rvalue
        case let (.string(lvalue), .string(rvalue)): return lvalue.lexicographicallyPrecedes(rvalue)
        default:
            throw ValueError.notComparableTypes(.atom(lhs.valueType), .atom(rhs.valueType))
        }
    }
    public static func <=(lhs: VariantAtom, rhs: VariantAtom) throws -> Bool {
        switch (lhs, rhs) {
        case let (.int(lvalue), .int(rvalue)): return lvalue <= rvalue
        case let (.int(lvalue), .double(rvalue)): return Double(lvalue) <= rvalue
        case let (.double(lvalue), .int(rvalue)): return lvalue <= Double(rvalue)
        case let (.double(lvalue), .double(rvalue)): return lvalue <= rvalue
        case let (.string(lvalue), .string(rvalue)):
            return lvalue == rvalue || lvalue.lexicographicallyPrecedes(rvalue)
        default:
            throw ValueError.notComparableTypes(.atom(lhs.valueType), .atom(rhs.valueType))
        }
    }

    public static func >(lhs: VariantAtom, rhs: VariantAtom) throws -> Bool {
        switch (lhs, rhs) {
        case let (.int(lvalue), .int(rvalue)): return lvalue > rvalue
        case let (.int(lvalue), .double(rvalue)): return Double(lvalue) > rvalue
        case let (.double(lvalue), .int(rvalue)): return lvalue > Double(rvalue)
        case let (.double(lvalue), .double(rvalue)): return lvalue > rvalue
        case let (.string(lvalue), .string(rvalue)): return rvalue.lexicographicallyPrecedes(lvalue)
        default:
            throw ValueError.notComparableTypes(.atom(lhs.valueType), .atom(rhs.valueType))
        }
    }
    public static func >=(lhs: VariantAtom, rhs: VariantAtom) throws -> Bool {
        switch (lhs, rhs) {
        case let (.int(lvalue), .int(rvalue)): return lvalue >= rvalue
        case let (.int(lvalue), .double(rvalue)): return Double(lvalue) >= rvalue
        case let (.double(lvalue), .int(rvalue)): return lvalue >= Double(rvalue)
        case let (.double(lvalue), .double(rvalue)): return lvalue >= rvalue
        case let (.string(lvalue), .string(rvalue)):
            return lvalue == rvalue || rvalue.lexicographicallyPrecedes(lvalue)
        default:
            throw ValueError.notComparableTypes(.atom(lhs.valueType), .atom(rhs.valueType))
        }
    }
    public static func ==(lhs: VariantAtom, rhs: VariantAtom) -> Bool {
        switch (lhs, rhs) {
        case let (.int(lvalue), .int(rvalue)): return lvalue == rvalue
        case let (.int(lvalue), .double(rvalue)): return Double(lvalue) == rvalue
        case let (.double(lvalue), .int(rvalue)): return lvalue == Double(rvalue)
        case let (.double(lvalue), .double(rvalue)): return lvalue == rvalue
        case let (.string(lvalue), .string(rvalue)): return lvalue == rvalue
        case let (.bool(lvalue), .bool(rvalue)): return lvalue == rvalue
        case let (.point(lvalue), .point(rvalue)): return lvalue == rvalue
        default:
            return false
        }
    }

    public static func !=(lhs: VariantAtom, rhs: VariantAtom) -> Bool {
        switch (lhs, rhs) {
        case let (.int(lvalue), .int(rvalue)): return lvalue != rvalue
        case let (.int(lvalue), .double(rvalue)): return Double(lvalue) != rvalue
        case let (.double(lvalue), .int(rvalue)): return lvalue != Double(rvalue)
        case let (.double(lvalue), .double(rvalue)): return lvalue != rvalue
        case let (.string(lvalue), .string(rvalue)): return lvalue != rvalue
        case let (.bool(lvalue), .bool(rvalue)): return lvalue != rvalue
        case let (.point(lvalue), .point(rvalue)): return lvalue != rvalue
        default:
            return true
        }
    }
}
extension VariantArray {
    public static func <(lhs: VariantArray, rhs: VariantArray) throws -> Bool {
        throw ValueError.notComparableTypes(.array(lhs.itemType), .array(rhs.itemType))
    }
    public static func <=(lhs: VariantArray, rhs: VariantArray) throws -> Bool {
    throw ValueError.notComparableTypes(.array(lhs.itemType), .array(rhs.itemType))
    }

    public static func >(lhs: VariantArray, rhs: VariantArray) throws -> Bool {
        throw ValueError.notComparableTypes(.array(lhs.itemType), .array(rhs.itemType))
    }
    public static func >=(lhs: VariantArray, rhs: VariantArray) throws -> Bool {
        throw ValueError.notComparableTypes(.array(lhs.itemType), .array(rhs.itemType))
    }
    public static func ==(lhs: VariantArray, rhs: VariantArray) -> Bool {
        switch (lhs, rhs) {
        case let (.int(lvalue), .int(rvalue)): return lvalue == rvalue
        case let (.int(lvalue), .double(rvalue)): return lvalue.map {Double($0)} == rvalue
        case let (.double(lvalue), .int(rvalue)): return lvalue == rvalue.map {Double($0)}
        case let (.double(lvalue), .double(rvalue)): return lvalue == rvalue
        case let (.string(lvalue), .string(rvalue)): return lvalue == rvalue
        case let (.bool(lvalue), .bool(rvalue)): return lvalue == rvalue
        case let (.point(lvalue), .point(rvalue)): return lvalue == rvalue
        default:
            return false
        }
    }

    public static func !=(lhs: VariantArray, rhs: VariantArray) -> Bool {
        switch (lhs, rhs) {
        case let (.int(lvalue), .int(rvalue)): return lvalue != rvalue
        case let (.int(lvalue), .double(rvalue)): return lvalue.map {Double($0)} != rvalue
        case let (.double(lvalue), .int(rvalue)): return lvalue == rvalue.map {Double($0)}
        case let (.double(lvalue), .double(rvalue)): return lvalue != rvalue
        case let (.string(lvalue), .string(rvalue)): return lvalue != rvalue
        case let (.bool(lvalue), .bool(rvalue)): return lvalue != rvalue
        case let (.point(lvalue), .point(rvalue)): return lvalue != rvalue
        default:
            return true
        }
    }
}

extension Variant {
    public static func <(lhs: Variant, rhs: Variant) throws -> Bool {
        switch (lhs, rhs) {
        case let (.atom(lvalue), .atom(rvalue)):
            return try lvalue < rvalue
        default:
            throw ValueError.notComparableTypes(lhs.valueType, rhs.valueType)
        }
    }
    public static func <=(lhs: Variant, rhs: Variant) throws -> Bool {
        switch (lhs, rhs) {
        case let (.atom(lvalue), .atom(rvalue)):
            return try lvalue <= rvalue
        default:
            throw ValueError.notComparableTypes(lhs.valueType, rhs.valueType)
        }
    }

    public static func >(lhs: Variant, rhs: Variant) throws -> Bool {
        switch (lhs, rhs) {
        case let (.atom(lvalue), .atom(rvalue)):
            return try lvalue > rvalue
        default:
            throw ValueError.notComparableTypes(lhs.valueType, rhs.valueType)
        }
    }
    public static func >=(lhs: Variant, rhs: Variant) throws -> Bool {
        switch (lhs, rhs) {
        case let (.atom(lvalue), .atom(rvalue)):
            return try lvalue >= rvalue
        default:
            throw ValueError.notComparableTypes(lhs.valueType, rhs.valueType)
        }
    }
    public static func ==(lhs: Variant, rhs: Variant) -> Bool {
        switch (lhs, rhs) {
        case let (.array(lvalue), .array(rvalue)):
            return lvalue == rvalue
        case (.array(_), .atom(_)):
            return false
        case (.atom(_), .array(_)):
            return false
        case let (.atom(lvalue), .atom(rvalue)):
            return lvalue == rvalue
        }
    }

    public static func !=(lhs: Variant, rhs: Variant) -> Bool {
        switch (lhs, rhs) {
        case let (.array(lvalue), .array(rvalue)):
            return lvalue != rvalue
        case (.array(_), .atom(_)):
            return false
        case (.atom(_), .array(_)):
            return false
        case let (.atom(lvalue), .atom(rvalue)):
            return lvalue != rvalue
        }
    }
}
