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
    ///     - structure: Structural component of the new object that must match the object type.
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
                               attributes: [String:Variant]=[:],
                               components: [any Component]=[],
                               structure: StructuralComponent? = nil,
                               state: VersionState = .stable) -> ObjectSnapshot {
        // TODO: Check for existence and register with list of all snapshots.
        // TODO: This should include the snapshot into the list of snapshots.
        // TODO: Handle wrong IDs.
        
        let actualID = allocateID(required: id)
        let actualSnapshotID = allocateID(required: snapshotID)

        let actualStructure: StructuralComponent
        switch type.structuralType {
        case .unstructured:
            precondition(structure == nil || structure == .unstructured,
                         "Structural component mismatch for type \(type.name). Got: \(structure!.type) expected: \(type.structuralType)")
            actualStructure = .unstructured
        case .node:
            precondition(structure == nil || structure == .node,
                         "Structural component mismatch for type \(type.name). Got: \(structure!.type) expected: \(type.structuralType)")
            actualStructure = .node
        case .edge:
            guard let structure else {
                fatalError("Structural component of type `edge` is required to be provided for type \(type.name).")
            }
            
            precondition(structure.type == .edge,
                         "Structural component mismatch for type \(type.name). Got: \(structure.type) expected: \(type.structuralType)")

            actualStructure = structure
        }
        var actualAttributes = attributes
        
        // Add required components as described by the object type.
        //
        for attribute in type.attributes {
            if actualAttributes[attribute.name] == nil {
                actualAttributes[attribute.name] = attribute.defaultValue
            }
        }

        let snapshot = ObjectSnapshot(id: actualID,
                                      snapshotID: actualSnapshotID,
                                      type: type,
                                      structure: actualStructure,
                                      attributes: actualAttributes,
                                      components: components)

        snapshot.state = state
        
        self._allSnapshots[actualSnapshotID] = snapshot
        
        return snapshot
    }
    
    @available(*, deprecated, message: "Use the designated initialiser createSnapshot or merge with foreign object")
    public func createSnapshot(_ record: ForeignObject) throws -> ObjectSnapshot {
        // Readability alias
        let info = record.info
        let attributes = record.attributes.dictionary
        
        let typeName = try info.stringValue(for: "type")
        guard let type = metamodel.objectType(name: typeName) else {
            throw MemoryStoreError.unknownObjectType(typeName)
        }
        
        let structure: StructuralComponent
        switch type.structuralType {
        case .unstructured:
            structure = .unstructured
        case .node:
            structure = .node
        case .edge:
            structure = .edge(try info.IDValue(for: "origin"),
                              try info.IDValue(for: "target"))
        }
        
        let id = allocateID(required: try info.IDValue(for: "id"))
        let snapshotID = allocateID(required: try info.IDValue(for: "snapshot_id"))
        
        let snapshot = ObjectSnapshot(id: id,
                                      snapshotID: snapshotID,
                                      type: type,
                                      attributes: attributes)
        
        snapshot.structure = structure
        snapshot.parent = try info.IDValueIfPresent(for: "parent")
        
        self._allSnapshots[snapshotID] = snapshot

        return snapshot
    }


    
    /// Create a new snapshot version
    ///
    public func deriveSnapshot(_ originalID: SnapshotID) -> ObjectSnapshot {
        guard let original = _allSnapshots[originalID] else {
            fatalError("Trying to derive a snapshot (\(originalID)) that does not belong to a memory")

        }

        let derivedSnapshotID: SnapshotID = allocateID()
        let derived = ObjectSnapshot(id: original.id,
                                     snapshotID: derivedSnapshotID,
                                     type: original.type,
                                     structure: original.structure)
        derived.attributes = original.attributes
        derived.components = original.components
        derived.children = original.children
        derived.parent = original.parent
        return derived
    }
}
