//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 06/06/2023.
//

extension Trait {
    public static let Position = Trait(
        name: "Position",
        attributes: [
            Attribute("position", type: .point, default: ForeignValue(Point(0,0))),
            Attribute("z_index", type: .int, default: ForeignValue(0)),
        ]
    )
}

extension ObjectSnapshot {
    /// Get position of the object.
    ///
    /// The position is retrieved from the `position` attribute, if it is
    /// present. If the object has no `position` attribute, then `nil` is
    /// returned.
    ///
    /// If the value of the `position` attribute is not convertible to a point,
    /// then `nil` is returned as well.
    ///
    public var position: Point? {
        get {
            if let value = attribute(forKey: "position") {
                return try? value.pointValue()
            }
            else {
                return nil
            }
        }
        set(point) {
            if let point {
                setAttribute(value: .atom(.point(point)), forKey: "position")
            }
            else {
                removeAttribute(forKey: "position")
            }
        }
        
    }
}
