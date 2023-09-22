//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 19/06/2023.
//

import XCTest
@testable import PoieticCore

class TestPersistentRecord: XCTestCase {
    // TODO: This seems to be testing some obsolete functionality or a functionality that has been moved
    var memory: ObjectMemory!

    override func setUp() {
        self.memory = ObjectMemory(metamodel: TestMetamodel.self)
    }

    func testFromRecord() throws {
        let record = ForeignRecord([
            "object_id": ForeignValue(10),
            "snapshot_id": ForeignValue(20),
            "structure": ForeignValue("node"),
            "type": ForeignValue("Stock"),
        ])
        
        let obj: ObjectSnapshot = try memory.createSnapshot(record: record)
        
        XCTAssertEqual(obj.id, 10)
        XCTAssertEqual(obj.snapshotID, 20)
        XCTAssertEqual(obj.structure, .node)
        XCTAssertIdentical(obj.type, TestMetamodel.Stock)
    }

    func testFromRecordEdge() throws {
        let record = ForeignRecord([
            "object_id": ForeignValue(10),
            "snapshot_id": ForeignValue(20),
            "structure": ForeignValue("edge"),
            "origin": ForeignValue("30"),
            "target": ForeignValue("40"),
            "type": ForeignValue("Stock"),
        ])
        
        let obj: ObjectSnapshot = try memory.createSnapshot(record: record)
        
        XCTAssertEqual(obj.id, 10)
        XCTAssertEqual(obj.snapshotID, 20)
        XCTAssertEqual(obj.structure, .edge(30, 40))
        XCTAssertIdentical(obj.type, TestMetamodel.Stock)
    }

    
    func testComponentToRecord() throws {
        let component = IntegerComponent(value: 10)
        let result = component.foreignRecord()

        let record = ForeignRecord(["value": ForeignValue(10)])

        XCTAssertEqual(result, record)
    }

    func testComponentFromRecord()throws  {
        let record = ForeignRecord([ "value": ForeignValue(10) ])

        let component = try IntegerComponent(record: record)

        XCTAssertEqual(component.value, 10)
    }
    
    func testSnapshotWithComponent() throws {
        let record = ForeignRecord([
            "object_id": ForeignValue(10),
            "snapshot_id": ForeignValue(20),
            "structural_type": ForeignValue("node"),
            "type": ForeignValue("Stock"),
        ])

        let components: [String: ForeignRecord] = [
            "Integer": ForeignRecord(["value": ForeignValue(10)])
        ]
        
        let obj: ObjectSnapshot = try memory.createSnapshot(record: record,
                                                            components: components)

        XCTAssertEqual(IntegerComponent(value: 10), obj[IntegerComponent.self])
    }
}

final class JSONFileStoreTests: XCTestCase {
    /**
    Creates a URL for a temporary file on disk. Registers a teardown block to
    delete a file at that URL (if one exists) during test teardown.
    */
    func temporaryFileURL() -> URL {
        let fm = FileManager()
        // Create a URL for an unique file in the system's temporary directory.
        let directory = fm.temporaryDirectory.path
        let filename = UUID().uuidString
        let fileURL = URL(fileURLWithPath: directory).appendingPathComponent(filename)
        
        // Add a teardown block to delete any file at `fileURL`.
        addTeardownBlock {
            do {
                let fileManager = FileManager.default
                // Check that the file exists before trying to delete it.
                if fileManager.fileExists(atPath: fileURL.path) {
                    // Perform the deletion.
                    try fileManager.removeItem(at: fileURL)
                    // Verify that the file no longer exists after the deletion.
                    XCTAssertFalse(fileManager.fileExists(atPath: fileURL.path))
                }
            } catch {
                // Treat any errors during file deletion as a test failure.
                XCTFail("Error while deleting temporary file: \(error)")
            }
        }
        
        // Return the temporary file URL for use in a test method.
        return fileURL
    }
    var db: ObjectMemory!
    var frame: MutableFrame!
    var graph: MutableGraph!
    
    override func setUp() {
        db = ObjectMemory()
        frame = db.createFrame()
        graph = frame.mutableGraph
        
        let flow = graph.createNode(TestMetamodel.Flow,
                                    name: nil,
                                    components: [IntegerComponent(value: 10)])
        let source = graph.createNode(TestMetamodel.Stock,
                                      name: nil,
                                    components: [IntegerComponent(value: 20)])
        let sink = graph.createNode(TestMetamodel.Stock,
                                    name:nil,
                                    components: [IntegerComponent(value: 30)])
        
        graph.createEdge(TestMetamodel.Arrow,
                         origin: source,
                         target: flow, components: [])
        graph.createEdge(TestMetamodel.Arrow,
                         origin: flow,
                         target: sink, components: [])
        do {
            try db.accept(frame)
        }
        catch {
            fatalError("Failed to accept frame: \(error)")
        }
    }
    
    func testEmpty(){
        XCTAssertEqual(1, 1)
    }

    func testRestore() throws {
//        let tmpURL = temporaryFileURL()
       
//        let writer = try JSONFilePackageWriter(url: tmpURL)
//        db.write(writer)

//        let reader = JSONFilePackageReader(tmpURL)
//        let restored = ObjectMemory(metamodel=Metamodel,
//                                store=load_store)
//        self.assertEqual(len(list(self.db.snapshots)),
//                         len(list(restored.snapshots)))
//
//        other_frame = restored.frame(self.frame.version)
//
//        for snapshot in self.frame.snapshots:
//            other = other_frame.object(snapshot.id)
//            if snapshot != other:
//                # import pdb; pdb.set_trace()
//                pass
//
//            self.assertEqual(snapshot, other)
//
//        tmpdir.cleanup()

    }
    
}
