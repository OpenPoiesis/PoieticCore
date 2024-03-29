//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 06/06/2023.
//

import XCTest
@testable import PoieticCore

final class ObjectMemoryTests: XCTestCase {
    func testEmpty() throws {
        let db = ObjectMemory()
        
        XCTAssertNil(db.currentFrameID)
        
        let frame = db.deriveFrame()
        
        try db.accept(frame)
        
        XCTAssertFalse(frame.state.isMutable)
        XCTAssertTrue(db.containsFrame(frame.id))
    }
    
    func testSimpleAccept() throws {
        let db = ObjectMemory()
        
        let frame = db.deriveFrame()
        let a = frame.create(TestType)
        let b = frame.create(TestType)
        
        XCTAssertTrue(frame.contains(a))
        XCTAssertTrue(frame.contains(b))
        XCTAssertTrue(frame.hasChanges)
        XCTAssertEqual(db.versionHistory.count, 0)
        
        try db.accept(frame)
        
        XCTAssertEqual(db.versionHistory, [frame.id])
        XCTAssertEqual(db.currentFrame.id, frame.id)
        XCTAssertTrue(db.currentFrame.contains(a))
        XCTAssertTrue(db.currentFrame.contains(b))
    }
    
    func testMakeObjectFrozenAfterAccept() throws {
        let db = ObjectMemory()
        let frame = db.deriveFrame()
        let a = frame.create(TestType)
        try db.accept(frame)
        
        let obj = db.currentFrame.object(a)
        XCTAssertEqual(obj.state, VersionState.validated)
    }
    
    func testDiscard() throws {
        let db = ObjectMemory()
        let frame = db.deriveFrame()
        let _ = frame.create(TestType)
        
        db.discard(frame)
        
        XCTAssertEqual(db.versionHistory.count, 0)
        XCTAssertEqual(frame.state, VersionState.validated)
    }
    
    func testRemoveObject() throws {
        let db = ObjectMemory()
        let originalFrame = db.deriveFrame()
        
        let a = originalFrame.create(TestType)
        try db.accept(originalFrame)
        
        let originalVersion = db.currentFrameID
        
        let removalFrame = db.deriveFrame()
        XCTAssertTrue(db.currentFrame.contains(a))
        removalFrame.removeCascading(a)
        XCTAssertTrue(removalFrame.hasChanges)
        XCTAssertFalse(removalFrame.contains(a))
        
        try db.accept(removalFrame)
        XCTAssertEqual(db.currentFrame.id, removalFrame.id)
        XCTAssertFalse(db.currentFrame.contains(a))
        
        let original2 = db.frame(originalVersion!)!
        XCTAssertTrue(original2.contains(a))
    }
    
    
    func testUndo() throws {
        let db = ObjectMemory()
        try db.accept(db.createFrame())
        let v0 = db.currentFrameID!
        
        let frame1 = db.deriveFrame()
        let a = frame1.create(TestType)
        try db.accept(frame1)
        
        let frame2 = db.deriveFrame()
        let b = frame2.create(TestType)
        try db.accept(frame2)
        
        XCTAssertTrue(db.currentFrame.contains(a))
        XCTAssertTrue(db.currentFrame.contains(b))
        XCTAssertEqual(db.versionHistory, [v0, frame1.id, frame2.id])
        
        db.undo(to: frame1.id)
        
        XCTAssertEqual(db.currentFrameID, frame1.id)
        XCTAssertEqual(db.undoableFrames, [v0])
        XCTAssertEqual(db.redoableFrames, [frame2.id])
        
        db.undo(to: v0)
        
        XCTAssertEqual(db.currentFrameID, v0)
        XCTAssertEqual(db.undoableFrames, [])
        XCTAssertEqual(db.redoableFrames, [frame1.id, frame2.id])
        
        XCTAssertFalse(db.currentFrame.contains(a))
        XCTAssertFalse(db.currentFrame.contains(b))
    }
    
    func testUndoComponent() throws {
        let db = ObjectMemory()
        
        let frame1 = db.deriveFrame()
        let a = frame1.create(TestType, components: [TestComponent(text: "before")])
        try db.accept(frame1)
        
        let frame2 = db.deriveFrame()
        let obj = frame2.mutableObject(a)
        obj[TestComponent.self] = TestComponent(text: "after")
        
        try db.accept(frame2)
        
        db.undo(to: frame1.id)
        let altered = db.currentFrame.object(a)
        XCTAssertEqual(altered[TestComponent.self]!.text, "before")
    }
    func testUndoProperty() throws {
        let db = ObjectMemory()
        
        let frame1 = db.deriveFrame()
        let a = frame1.create(TestType, attributes: ["text": "before"])
        try db.accept(frame1)
        
        let frame2 = db.deriveFrame()
        let obj = frame2.mutableObject(a)
        obj["text"] = "after"
        
        try db.accept(frame2)
        
        db.undo(to: frame1.id)
        let altered = db.currentFrame.object(a)
        XCTAssertEqual(altered["text"], "before")
    }

    func testRedo() throws {
        let db = ObjectMemory()
        try db.accept(db.createFrame())
        let v0 = db.currentFrameID!
        
        let frame1 = db.deriveFrame()
        let a = frame1.create(TestType)
        try db.accept(frame1)
        
        let frame2 = db.deriveFrame()
        let b = frame2.create(TestType)
        try db.accept(frame2)
        
        db.undo(to: frame1.id)
        db.redo(to: frame2.id)
        
        XCTAssertTrue(db.currentFrame.contains(a))
        XCTAssertTrue(db.currentFrame.contains(b))
        
        XCTAssertEqual(db.currentFrameID, frame2.id)
        XCTAssertEqual(db.undoableFrames, [v0, frame1.id])
        XCTAssertEqual(db.redoableFrames, [])
        XCTAssertFalse(db.canRedo)
        
        db.undo(to: v0)
        db.redo(to: frame2.id)
        
        XCTAssertEqual(db.currentFrameID, frame2.id)
        XCTAssertEqual(db.undoableFrames, [v0, frame1.id])
        XCTAssertEqual(db.redoableFrames, [])
        XCTAssertFalse(db.canRedo)
        
        db.undo(to: v0)
        db.redo(to: frame1.id)
        
        XCTAssertEqual(db.currentFrameID, frame1.id)
        XCTAssertEqual(db.undoableFrames, [v0])
        XCTAssertEqual(db.redoableFrames, [frame2.id])
        XCTAssertTrue(db.canRedo)
        
        XCTAssertTrue(db.currentFrame.contains(a))
        XCTAssertFalse(db.currentFrame.contains(b))
    }
    
    func testRedoReset() throws {
        let db = ObjectMemory()
        try db.accept(db.createFrame())
        let v0 = db.currentFrameID!
        
        let frame1 = db.deriveFrame()
        let a = frame1.create(TestType)
        try db.accept(frame1)
        
        db.undo(to: v0)
        
        let frame2 = db.deriveFrame()
        let b = frame2.create(TestType)
        try db.accept(frame2)
        
        XCTAssertEqual(db.currentFrameID, frame2.id)
        XCTAssertEqual(db.versionHistory, [v0, frame2.id])
        XCTAssertEqual(db.undoableFrames, [v0])
        XCTAssertEqual(db.redoableFrames, [])
        
        XCTAssertFalse(db.currentFrame.contains(a))
        XCTAssertTrue(db.currentFrame.contains(b))
    }
    
    func testConstraintViolationAccept() throws {
        // TODO: Change this to non-graph constraint check
        let db = ObjectMemory()
        let frame = db.deriveFrame()
        let a = frame.createNode(TestNodeType)
        let b = frame.createNode(TestNodeType)
        
        let constraint = Constraint(name: "test",
                                    match: AnyPredicate(),
                                    requirement: RejectAll())
        
        // TODO: Test this separately
        try db.addConstraint(constraint)
        
        XCTAssertThrowsError(try db.accept(frame)) {
            
            guard let error = $0 as? FrameValidationError else {
                XCTFail("Expected FrameValidationError")
                return
            }
            
            XCTAssertEqual(error.violations.count, 1)
            let violation = error.violations[0]
            XCTAssertIdentical(violation.constraint, constraint)
            XCTAssertTrue(violation.objects.contains(a))
            XCTAssertTrue(violation.objects.contains(b))
        }
    }
    
    func testDefaultValueTrait() {
        let db = ObjectMemory()
        let frame = db.deriveFrame()
        let a = frame.create(TestTypeNoDefault)
        let obj_a = frame.object(a)
        XCTAssertNil(obj_a["text"])

        let b = frame.create(TestTypeWithDefault)
        let obj_b = frame.object(b)
        XCTAssertNotNil(obj_b["text"])
        XCTAssertEqual(obj_b["text"], "default")
    }
    func testDefaultValueTraitError() {
        let mem = ObjectMemory()
        let frame = mem.deriveFrame()
        let a = frame.create(TestTypeNoDefault)
        let _ = frame.object(a)

        let b = frame.create(TestTypeWithDefault)
        let _ = frame.object(b)

        XCTAssertThrowsError(try mem.accept(frame)) {
            
            guard let error = $0 as? FrameValidationError else {
                XCTFail("Expected FrameValidationError")
                return
            }
            
            XCTAssertEqual(error.violations.count, 0)
            XCTAssertEqual(error.typeErrors.count, 1)
            if let a_errors = error.typeErrors[a] {
                XCTAssertEqual(a_errors.first, .missingTraitAttribute("text", "Test"))
            }
            else {
                XCTFail("Expected errors for object 'a'")
            }
            XCTAssertNil(error.typeErrors[b])
        }
    }

}
