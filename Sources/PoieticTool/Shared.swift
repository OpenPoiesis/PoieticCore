//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 06/01/2022.
//

import Foundation
import ArgumentParser
import PoieticCore
import PoieticFlows
import SystemPackage

enum ToolError: Error, CustomStringConvertible {
    case malformedLocation(String)
    case unableToCreateFile(Error)
    
    case unknownSolver(String)
    case unknownObjectName(String)
    case compilationError
    
    case malformedObjectReference(String)
    case unknownObject(String)
    
    public var description: String {
        switch self {
        case .malformedLocation(let value):
            return "Malformed location: \(value)"
        case .unableToCreateFile(let value):
            return "Unable to create file. Reason: \(value)"
        case .unknownSolver(let value):
            return "Unknown solver '\(value)'"
        case .unknownObjectName(let value):
            return "Unknown object with name '\(value)'"
        case .compilationError:
            return "Design compilation failed"
        case .malformedObjectReference(let value):
            return "Malformed object reference '\(value). Use either object ID or object identifier."
        case .unknownObject(let value):
            return "Unknown object with reference: \(value)"
        }
    }
}

let defaultDatabase = "Design.poietic"
let databaseEnvironment = "POIETIC_DESIGN"

/// Get the database URL. The database location can be specified by options,
/// environment variable or as a default name, in respective order.
func databaseURL(options: Options) throws -> URL {
    let location: String
    let env = ProcessInfo.processInfo.environment
    
    if let path = options.database {
        location = path
    }
    else if let path = env[databaseEnvironment] {
        location = path
    }
    else {
        location = defaultDatabase
    }
    
    if let url = URL(string: location) {
        if url.scheme == nil {
            return URL(fileURLWithPath: location, isDirectory: true)
        }
        else {
            return url
        }
    }
    else {
        throw ToolError.malformedLocation(location)
    }
}

/// Create a new empty memory.
///
func createMemory(options: Options) -> ObjectMemory {
    return ObjectMemory(metamodel: FlowsMetamodel.self)
}

/// Opens a graph from a package specified in the options.
///
func openMemory(options: Options) throws -> ObjectMemory {
    let memory: ObjectMemory = ObjectMemory(metamodel: FlowsMetamodel.self)
    let dataURL = try databaseURL(options: options)

    try memory.restoreAll(from: dataURL)
    
    return memory
}

/// Finalize operations on graph and save the graph to its store.
///
func closeMemory(memory: ObjectMemory, options: Options) throws {
    let dataURL = try databaseURL(options: options)

    try memory.saveAll(to: dataURL)
}

/// Align values to the right, padding all values to the width of the longest
/// string.
///
func alignRightToWidest(_ values: [String]) -> [String] {
    let keys = values.map { $0.count }
    let width = keys.max() ?? 0
    
    var result: [String] = []
    
    for value in values {
        let padding = String(repeating: " ", count: width - value.count)
        let padded = padding + value
        result.append(padded)
    }
    return result
}

extension String {
    /// Returns a right-aligned string padded with `padding` to the desired
    /// width `width`.
    ///
    public func alignRight(_ width: Int, padding: String = " ") -> String {
        // TODO: Allow leght of padding to be more than one character
        let repeats = width - self.count
        return String(repeating: padding, count: repeats) + self
    }
}

extension FrameBase {
    public func object(named name: String) -> ObjectSnapshot? {
        for object in snapshots {
            guard let component: ExpressionComponent = object[ExpressionComponent.self] else {
                continue
            }
            if component.name == name {
                return object
            }
        }
        return nil
    }
}