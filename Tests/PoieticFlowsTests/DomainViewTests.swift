//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 07/06/2023.
//

import XCTest
@testable import PoieticFlows
@testable import PoieticCore


final class TestDomainView: XCTestCase {
    // TODO: Split to Compiler and DomainView test cases
    
    var db: ObjectMemory!
    var frame: MutableFrame!
    var graph: MutableGraph!
    
    override func setUp() {
        db = ObjectMemory()
        frame = db.deriveFrame()
        graph = frame.mutableGraph
    }
    
    func testCollectNames() throws {
        graph.createNode(FlowsMetamodel.Stock,
                         components: [FormulaComponent(name:"a",expression:"0")])
        graph.createNode(FlowsMetamodel.Stock,
                         components: [FormulaComponent(name:"b",expression:"0")])
        graph.createNode(FlowsMetamodel.Stock,
                         components: [FormulaComponent(name:"c",expression:"0")])
        // TODO: Check using violation checker
        
        let view = DomainView(graph)
        
        let names = try view.collectNames()
        
        XCTAssertNotNil(names["a"])
        XCTAssertNotNil(names["b"])
        XCTAssertNotNil(names["c"])
        XCTAssertEqual(names.count, 3)
    }
    
    func testValidateDuplicateName() throws {
        let c1 = graph.createNode(FlowsMetamodel.Stock,
                                  components:[FormulaComponent(name:"things",expression:"0")])
        let c2 = graph.createNode(FlowsMetamodel.Stock,
                                  components: [FormulaComponent(name:"things",expression:"0")])
        graph.createNode(FlowsMetamodel.Stock,
                         components: [FormulaComponent(name:"a",expression:"0")])
        graph.createNode(FlowsMetamodel.Stock,
                         components: [FormulaComponent(name:"b",expression:"0")])
        
        // TODO: Check using violation checker
        
        let view = DomainView(graph)
        
        XCTAssertThrowsError(try view.collectNames()) {
            guard let error = $0 as? DomainError else {
                XCTFail("Expected DomainError")
                return
            }

            XCTAssertNotNil(error.issues[c1])
            XCTAssertNotNil(error.issues[c2])
            XCTAssertEqual(error.issues.count, 2)
        }
    }
    
    func testCompileExpressions() throws {
        throw XCTSkip("Conflicts with input validation, this test requires attention.")
#if false
        let names: [String:ObjectID] = [
            "a": 1,
            "b": 2,
        ]
        
        let l = graph.createNode(FlowsMetamodel.Stock,
                                 components: [FormulaComponent(name: "l",
                                                      expression: "sqrt(a*a + b*b)")])
        let view = DomainView(graph)

        let exprs = try view.compileExpressions(names: names)
        
        let varRefs = Set(exprs[l]!.allVariables)
        
        XCTAssertTrue(varRefs.contains(.object(1)))
        XCTAssertTrue(varRefs.contains(.object(2)))
        XCTAssertEqual(varRefs.count, 2)
#endif
    }
   
    func testCompileExpressionInvalidInput() throws {
        let names: [String:ObjectID] = [:]
        
        let broken = graph.createNode(FlowsMetamodel.Stock,
                                 components: [FormulaComponent(name: "broken",
                                                      expression: "price")])
        let view = DomainView(graph)
        
        XCTAssertThrowsError(try view.compileExpressions(names: names)) {
            guard let error = $0 as? DomainError else {
                XCTFail("Expected DomainError")
                return
            }

            XCTAssertEqual(error.issues.count, 1)
            guard let issue = error.issues.first else {
                XCTFail("Expected exactly one issue")
                return
            }
            let (key, issues) = issue
            XCTAssertEqual(key, broken)
            XCTAssertEqual(issues,[.unknownParameter("price")])

        }
    }

    
    func testSortedNodes() throws {
        // a -> b -> c
        
        let c = graph.createNode(FlowsMetamodel.Auxiliary,
                                 components: [FormulaComponent(name:"c",expression:"b")])
        let b = graph.createNode(FlowsMetamodel.Auxiliary,
                                 components: [FormulaComponent(name:"b",expression:"a")])
        let a = graph.createNode(FlowsMetamodel.Auxiliary,
                                 components: [FormulaComponent(name:"a",expression:"0")])
        
        
        graph.createEdge(FlowsMetamodel.Parameter,
                         origin: a,
                         target: b,
                         components: [])
        graph.createEdge(FlowsMetamodel.Parameter,
                         origin: b,
                         target: c,
                         components: [])
        
        let view = DomainView(graph)
        let sortedNodes = try view.sortNodes(nodes: [b, c, a])
        
        if sortedNodes.isEmpty {
            XCTFail("Sorted expression nodes must not be empty")
            return
        }
        
        XCTAssertEqual(sortedNodes.count, 3)
        XCTAssertEqual(sortedNodes[0].id, a)
        XCTAssertEqual(sortedNodes[1].id, b)
        XCTAssertEqual(sortedNodes[2].id, c)
    }
    
    func testUnusedInputs() throws {
        let used = graph.createNode(FlowsMetamodel.Auxiliary,
                                    components: [FormulaComponent(name:"used",expression:"0")])
        let unused = graph.createNode(FlowsMetamodel.Auxiliary,
                                      components: [FormulaComponent(name:"unused",expression:"0")])
        let tested = graph.createNode(FlowsMetamodel.Auxiliary,
                                      components: [FormulaComponent(name:"tested",expression:"used")])
        
        graph.createEdge(FlowsMetamodel.Parameter,
                         origin: used,
                         target: tested,
                         components: [])
        graph.createEdge(FlowsMetamodel.Parameter,
                         origin: unused,
                         target: tested,
                         components: [])
        
        let view = DomainView(graph)
        
        // TODO: Get the required list from the compiler
        let issues = view.validateInputs(nodeID: tested,
                                         required: ["used"])
        
        XCTAssertEqual(issues.count, 1)
        XCTAssertEqual(issues[0], .unusedInput("unused"))
    }
    
    func testUnknownParameters() throws {
        let known = graph.createNode(FlowsMetamodel.Auxiliary,
                                     components: [FormulaComponent(name:"known",expression:"0")])
        let tested = graph.createNode(FlowsMetamodel.Auxiliary,
                                      components: [FormulaComponent(name:"tested",expression:"known + unknown")])
        
        graph.createEdge(FlowsMetamodel.Parameter,
                         origin: known,
                         target: tested,
                         components: [])
        
        let view = DomainView(graph)
        
        let issues = view.validateInputs(nodeID: tested,
                                         required:["known", "unknown"])
        XCTAssertEqual(issues.count, 1)
        XCTAssertEqual(issues[0], .unknownParameter("unknown"))
    }
    
    func testFlowFillsAndDrains() throws {
        let flow = graph.createNode(FlowsMetamodel.Flow,
                                    components: [FormulaComponent(name:"f",expression:"1")])
        let source = graph.createNode(FlowsMetamodel.Stock,
                                      components: [FormulaComponent(name:"source",expression:"0")])
        let sink = graph.createNode(FlowsMetamodel.Stock,
                                    components: [FormulaComponent(name:"sink",expression:"0")])
        
        graph.createEdge(FlowsMetamodel.Drains,
                         origin: source,
                         target: flow,
                         components: [])
        graph.createEdge(FlowsMetamodel.Fills,
                         origin: flow,
                         target: sink,
                         components: [])
        
        let view = DomainView(graph)
        
        XCTAssertEqual(view.flowFills(flow), sink)
        XCTAssertEqual(view.flowDrains(flow), source)
    }
}
