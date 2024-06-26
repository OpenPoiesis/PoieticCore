//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 04/09/2023.
//

import Foundation
import XCTest
@testable import PoieticCore

final class GraphTests: XCTestCase {
    var design: Design!
    var frame: MutableFrame!
    
    override func setUp() {
        design = Design()
        frame = design.deriveFrame()
    }
    
    func testBasic() throws {
        let n1 = design.createSnapshot(TestNodeType)
        let n2 = design.createSnapshot(TestNodeType)
        let u1 = design.createSnapshot(TestType)
        let e1 = design.createSnapshot(TestEdgeType, structure: .edge(n1.id, n2.id))

        frame.insert(n1)
        frame.insert(n2)
        frame.insert(u1)
        frame.insert(e1)

        XCTAssertEqual(frame.nodes.count, 2)
        XCTAssertTrue(frame.nodes.contains(where: {$0.id == n1.id}))
        XCTAssertTrue(frame.nodes.contains(where: {$0.id == n2.id}))
        
        XCTAssertEqual(frame.edges.count, 1)
        XCTAssertTrue(frame.edges.contains(where: {$0.id == e1.id}))

    }
}
