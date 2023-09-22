//
//  Memory+Creation.swift
//  
//
//  Created by Stefan Urbanek on 21/08/2023.
//

extension ObjectMemory {
    /// Designated function to create snapshots in the memory.
    ///
    /// - Parameters:
    ///     - id: Proposed object ID. If not provided, one will be generated.
    ///     - snapshotID: Proposed snapshot ID. If not provided, one will be generated.
    ///     - type: Object type.
    ///     - components: List of components to be set for the newly created object.
    ///     - structuralReferences: List of object references related to the structural object type.
    ///     - initialized: If set to `false` then the object is left uninitialised.
    ///       The Caller must finish initialisation and mark the snapshot
    ///       initialised before inserting it to a frame.
    ///
    /// The `structuralReferences` list must contain:
    ///
    /// - no references for ``StructuralType/unstructured`` and ``StructuralType/node``
    /// - two references for ``StructuralType/edge``: first for edge's origin,
    ///   second for edge's target.
    ///
    public func createSnapshot(_ type: ObjectType,
                               id: ObjectID? = nil,
                               snapshotID: SnapshotID? = nil,
                               components: [any Component]=[],
                               structuralReferences: [ObjectID]=[],
                               initialized: Bool = true) -> ObjectSnapshot {
        // TODO: Check for existence and register with list of all snapshots.
        // TODO: This should include the snapshot into the list of snapshots.
        // TODO: Handle wrong IDs.
        let actualID = allocateID(proposed: id)
        let actualSnapshotID = allocateID(proposed: snapshotID)

        let structure: StructuralComponent
        
        switch type.structuralType {
        case .unstructured:
            precondition(structuralReferences.isEmpty,
                         "Structural references provided for a structural type 'unstructured' without references.")
            structure = .unstructured
        case .node:
            precondition(structuralReferences.isEmpty,
                         "Structural references provided for a structural type 'node' without references.")
            structure = .node
        case .edge:
            precondition(structuralReferences.count == 2,
                         "Wrong number (\(structuralReferences.count) of structural references provided for a structural type 'edge', expected exactly two.")
            let origin = structuralReferences[0]
            let target = structuralReferences[1]

            structure = .edge(origin, target)
        }

        let snapshot = ObjectSnapshot(id: actualID,
                                      snapshotID: actualSnapshotID,
                                      type: type,
                                      structure: structure,
                                      components: components)

        if initialized {
            snapshot.makeInitialized()
        }
        return snapshot
    }
    /// Create a new unstructured snapshot.
    ///
    /// Create a new object snapshot that will be unstructured but open.
    /// The structure might be changed by the caller.
    ///
    /// The returned snapshot is unstable and must be made stable before
    /// assigned to a frame.
    ///
    public func allocateUnstructuredSnapshot(_ objectType: ObjectType,
                                 id: ObjectID? = nil,
                                 snapshotID: SnapshotID? = nil) -> ObjectSnapshot {
        let actualID: ObjectID = id ?? allocateID()
        let actualSnapshotID: SnapshotID = id ?? allocateID()

        let snapshot = ObjectSnapshot(id: actualID,
                                      snapshotID: actualSnapshotID,
                                      type: objectType,
                                      structure: .unstructured)
        return snapshot
    }

//    @available(*, deprecated, message: "Use alloc+initialize combo")
//    public convenience init(fromRecord record: ForeignRecord,
//                            components: [String:ForeignRecord]=[:]) throws {
//        // TODO: Handle wrong IDs
//        let id: ObjectID = try record.IDValue(for: "object_id")
//        let snapshotID: SnapshotID = try record.IDValue(for: "snapshot_id")
//        
//        let type: ObjectType
//        
//        if let typeName = try record.stringValueIfPresent(for: "type") {
//            if let objectType = metamodel.objectType(name: typeName) {
//                type = objectType
//            }
//            else {
//                fatalError("Unknown object type: \(typeName)")
//            }
//        }
//        else {
//            fatalError("No object type provided in the record")
//        }
//        
//        var componentInstances: [any Component] = []
//        
//        for (name, record) in components {
//            let type: Component.Type = persistableComponent(name: name)!
//            let component = try type.init(record: record)
//            componentInstances.append(component)
//        }
//        
//        let structuralType = try record.stringValueIfPresent(for: "structure") ?? "unstructured"
//        let structure: StructuralComponent
//        
//        switch structuralType {
//        case "unstructured":
//            structure = .unstructured
//        case "node":
//            structure = .node
//        case "edge":
//            let origin: ObjectID = try record.IDValue(for: "origin")
//            let target: ObjectID = try record.IDValue(for: "target")
//            structure = .edge(origin, target)
//        default:
//            fatalError("Unknown structural type: '\(structuralType)'")
//        }
//        
//        self.init(id: id,
//                  snapshotID: snapshotID,
//                  type: type,
//                  structure: structure,
//                  components: componentInstances)
//    }
   

    
}
