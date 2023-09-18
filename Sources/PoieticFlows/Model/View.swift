//
//  StockFlowView.swift
//
//
//  Created by Stefan Urbanek on 06/06/2023.
//

import PoieticCore


/// Status of a parameter.
///
/// The status is provided by the function ``StockFlowView/parameters(_:required:)``.
///
public enum ParameterStatus:Equatable {
    case missing
    case unused(node: ObjectID, edge: ObjectID)
    case used(node: ObjectID, edge: ObjectID)
}


/// View of Stock-and-Flow domain-specific aspects of the design.
///
/// The domain view provides higher level view of the design through higher
/// level concepts as defined in the ``FlowsMetamodel``.
///
public class StockFlowView {
    // TODO: Consolidate queries in metamodel and this domain view - move them here(?)
    /// Graph that the view projects.
    ///
    public let graph: Graph
    public let frame: Frame
    
    /// Create a new view on top of a graph.
    ///
    public init(_ graph: Graph) {
        // TODO: Use only frame, not a graph
        self.graph = graph
        self.frame = graph.frame
    }
    
    /// A list of nodes that are part of the simulation. The simulation nodes
    /// correspond to the simulation variables, where one node corresponds to
    /// exactly one simulation variable and vice-versa.
    ///
    /// - SeeAlso: ``SimulationVariable``, ``CompiledModel``
    ///
    public var simulationNodes: [Node] {
        graph.selectNodes(
            HasComponentPredicate(FormulaComponent.self)
                .or(HasComponentPredicate(GraphicalFunctionComponent.self)))
    }

    // TODO: Use component filter directly here
    /// List of expression nodes in the graph.
    ///
    @available(*, deprecated, message: "Use simulationNodes instead")
//    public var expressionNodes: [Node] {
//        // TODO: Use tuple (Node, Component) instead of just Node
//        graph.selectNodes(HasComponentPredicate(FormulaComponent.self))
//    }
    
    @available(*, deprecated, message: "Use simulationNodes instead")
    public var graphicalFunctionNodes: [Node] {
        // TODO: Use tuple (Node, Component) instead of just Node
        graph.selectNodes(HasComponentPredicate(GraphicalFunctionComponent.self))
    }
    
    public var flowNodes: [Node] {
        graph.selectNodes(IsTypePredicate(FlowsMetamodel.Flow))
    }
   
    /// Predicate that matches all objects that have a name through
    /// NamedComponent.
    ///
    public var namedObjects: [(ObjectSnapshot, String)] {
        frame.filter(component: NameComponent.self).map {
            return ($0.0, $0.1.name)
        }
    }

    /// List of all nodes that hold a simulation state and are therefore part
    /// of the state vector.
    ///
    /// - SeeAlso: ``StateVector``
    ///
    public var stateNodes: [Node] {
        // For now we have only nodes with a formula component.
        graph.selectNodes(HasComponentPredicate(FormulaComponent.self))
    }

    
    // Parameter queries
    // ---------------------------------------------------------------------
    //
    /// Predicate that matches all edges that represent parameter connections.
    ///
    public var parameterEdges: [Edge] {
        graph.selectEdges(IsTypePredicate(FlowsMetamodel.Parameter))
    }
    /// A neighbourhood for incoming parameters of a node.
    ///
    /// Focus node is a node where we would like to see nodes that
    /// are parameters for the node of focus.
    ///
    public func incomingParameters(_ nodeID: ObjectID) -> Neighborhood {
        graph.hood(nodeID,
                   selector: NeighborhoodSelector(
                    predicate: IsTypePredicate(FlowsMetamodel.Parameter),
                    direction: .incoming
                )
        )
    }

    // Fills/drains queries
    // ---------------------------------------------------------------------
    //
    /// Predicate for an edge that fills a stocks. It originates in a flow,
    /// and terminates in a stock.
    ///
    public var fillsEdges: [Edge] {
        graph.selectEdges(IsTypePredicate(FlowsMetamodel.Fills))
    }

    /// Selector for an edge originating in a flow and ending in a stock denoting
    /// which stock the flow fills. There must be only one of such edges
    /// originating in a flow.
    ///
    /// Neighbourhood of stocks around the flow.
    ///
    ///     Flow --(Fills)--> Stock
    ///      ^                  ^
    ///      |                  +--- Neighbourhood (only one)
    ///      |
    ///      *Node of interest*
    ///
    public func fills(_ nodeID: ObjectID) -> Neighborhood {
        graph.hood(nodeID,
                   selector: NeighborhoodSelector(
                    predicate: IsTypePredicate(FlowsMetamodel.Fills),
                    direction: .outgoing
                )
        )
    }

    /// Selector for edges originating in a flow and ending in a stock denoting
    /// the inflow from multiple flows into a single stock.
    ///
    ///     Flow --(Fills)--> Stock
    ///      ^                  ^
    ///      |                  +--- *Node of interest*
    ///      |
    ///      Neighbourhood (many)
    ///
    public func inflows(_ nodeID: ObjectID) -> Neighborhood {
        graph.hood(nodeID,
                   selector: NeighborhoodSelector(
                    predicate: IsTypePredicate(FlowsMetamodel.Fills),
                    direction: .incoming
                )
        )
    }
    /// Selector for an edge originating in a stock and ending in a flow denoting
    /// which stock the flow drains. There must be only one of such edges
    /// ending in a flow.
    ///
    /// Neighbourhood of stocks around the flow.
    ///
    ///     Stock --(Drains)--> Flow
    ///      ^                    ^
    ///      |                    +--- Node of interest
    ///      |
    ///      Neighbourhood (only one)
    ///
    ///
    public func drains(_ nodeID: ObjectID) -> Neighborhood {
        graph.hood(nodeID,
                   selector: NeighborhoodSelector(
                    predicate: IsTypePredicate(FlowsMetamodel.Drains),
                    direction: .incoming
                )
        )
    }
    /// Selector for edges originating in a stock and ending in a flow denoting
    /// the outflow from the stock to multiple flows.
    ///
    ///
    ///     Stock --(Drains)--> Flow
    ///      ^                    ^
    ///      |                    +--- Neighbourhood (many)
    ///      |
    ///      Node of interest
    ///
    ///
    public func outflows(_ nodeID: ObjectID) -> Neighborhood {
        graph.hood(nodeID,
                   selector: NeighborhoodSelector(
                    predicate: IsTypePredicate(FlowsMetamodel.Drains),
                    direction: .incoming
                )
        )
    }

    /// Predicate for an edge that drains from a stocks. It originates in a
    /// stock and terminates in a flow.
    ///
    public var drainsEdges: [Edge] {
        graph.selectEdges(IsTypePredicate(FlowsMetamodel.Drains))
    }
    
    /// List of all edges that denotes an implicit flow between
    /// two stocks.
    ///
    /// Implicit flow is an edge between two stocks connected by a flow
    /// where one stocks fills the flow and another stock drains the flow.
    ///
    /// ```
    ///              Drains           Fills
    ///    Stock a ==========> Flow =========> Stock b
    ///       |                                  ^
    ///       +----------------------------------+
    ///                   implicit flow
    ///
    /// ```
    ///
    /// Implicit flows are created by the compiler, they are not supposed to be
    /// created by the user.
    ///
    /// - SeeAlso: ``StockFlowView/implicitFills(_:)``,
    /// ``StockFlowView/implicitDrains(_:)``,
    /// ``StockFlowView/sortedStocksByImplicitFlows(_:)``
    ///
    public var implicitFlowEdges: [Edge] {
        graph.selectEdges(IsTypePredicate(FlowsMetamodel.ImplicitFlow))
    }

    
    /// A list of variable references to their corresponding objects.
    ///
    public func objectVariableReferences(names: [String:ObjectID]) -> [String:VariableReference] {
        var references: [String:VariableReference] = [:]
        for (name, id) in names {
            references[name] = .object(id)
        }
        return references
    }
    public func builtinReferences(names: [String:ObjectID]) -> [String:VariableReference] {
        var references: [String:VariableReference] = [:]
        for (name, id) in names {
            references[name] = .object(id)
        }
        return references
    }
   
    // TODO: Remove the `required` and compute here. Expensive, but useful for the caller.
    // TODO: The `required` should belong to the node itself.
    // TODO: Rename to formulaParameters as this makes sense for formulas only
    /// Function to get a map between parameter names and their status.
    ///
    public func parameters(_ nodeID: ObjectID,
                           required: [String]) -> [String:ParameterStatus] {
        let incomingHood = incomingParameters(nodeID)
        var unseen: Set<String> = Set(required)
        var result: [String: ParameterStatus] = [:]

        for edge in incomingHood.edges {
            let node = graph.node(edge.origin)
            let name = node.name!
            if unseen.contains(name) {
                result[name] = .used(node: node.id, edge: edge.id)
                unseen.remove(name)
            }
            else {
                result[name] = .unused(node: node.id, edge: edge.id)
            }
        }
        
        for name in unseen {
            result[name] = .missing
        }

        return result
    }

    /// Sort the nodes based on their parameter dependency.
    ///
    /// The function returns nodes that are sorted in the order of computation.
    /// If the parameter connections are valid and there are no cycles, then
    /// the nodes in the returned list can be safely computed in the order as
    /// returned.
    ///
    /// - Throws: ``GraphCycleError`` when cycle was detected.
    ///
    public func sortedNodesByParameter(_ nodes: [ObjectID]) throws -> [Node] {
        let sorted = try graph.topologicalSort(nodes, edges: parameterEdges)
        
        let result: [Node] = sorted.map {
            graph.node($0)
        }
        
        return result
    }
    
    /// Sort given list of stocks by the order of their implicit flows.
    ///
    /// Imagine that we replace the flow nodes with a direct edge between
    /// the stocks that the flow connects. The drained stock comes before the
    /// filled stock.
    ///
    /// - SeeAlso: ``implicitFills(_:)``,
    ///   ``implicitDrains(_:)``,
    ///   ``Compiler/updateImplicitFlows()``
    public func sortedStocksByImplicitFlows(_ nodes: [ObjectID]) throws -> [Node] {
        let sorted = try graph.topologicalSort(nodes, edges: implicitFlowEdges)
        
        let result: [Node] = sorted.map {
            graph.node($0)
        }
        
        return result
    }
    
    /// Get a node that the given flow fills.
    ///
    /// The flow fills a node, usually a stock, if there is an edge
    /// from the flow node to the node being filled.
    ///
    /// - Returns: ID of the node being filled, or `nil` if there is no
    ///   fill edge outgoing from the flow.
    /// - Precondition: The object with the ID `flowID` must be a flow
    /// (``FlowsMetamodel/Flow``)
    ///
    /// - SeeAlso: ``flowDrains(_:)``,
    ///
    public func flowFills(_ flowID: ObjectID) -> ObjectID? {
        let flowNode = graph.node(flowID)
        // TODO: Do we need to check it here? We assume model is valid.
        precondition(flowNode.type === FlowsMetamodel.Flow)
        
        if let node = fills(flowID).nodes.first {
            return node.id
        }
        else {
            return nil
        }
    }
    
    /// Get a node that the given flow drains.
    ///
    /// The flow drains a node, usually a stock, if there is an edge
    /// from the drained node to the flow node.
    ///
    /// - Returns: ID of the node being drained, or `nil` if there is no
    ///   drain edge incoming to the flow.
    /// - Precondition: The object with the ID `flowID` must be a flow
    /// (``FlowsMetamodel/Flow``)
    ///
    /// - SeeAlso: ``flowDrains(_:)``,
    ///
    public func flowDrains(_ flowID: ObjectID) -> ObjectID? {
        let flowNode = graph.node(flowID)
        // TODO: Do we need to check it here? We assume model is valid.
        precondition(flowNode.type === FlowsMetamodel.Flow)
        
        if let node = drains(flowID).nodes.first {
            return node.id
        }
        else {
            return nil
        }
    }
    
    /// Return a list of flows that fill a stock.
    ///
    /// Flow fills a stock if there is an edge of type ``FlowsMetamodel/Fills``
    /// that originates in the flow and ends in the stock.
    ///
    /// - Parameters:
    ///     - stockID: an ID of a node that must be a stock
    ///
    /// - Returns: List of object IDs of flow nodes that fill the
    ///   stock.
    ///
    /// - Precondition: `stockID` must be an ID of a node that is a stock.
    ///
    public func stockInflows(_ stockID: ObjectID) -> [ObjectID] {
        let stockNode = graph.node(stockID)
        // TODO: Do we need to check it here? We assume model is valid.
        precondition(stockNode.type === FlowsMetamodel.Stock)
        
        return inflows(stockID).nodes.map { $0.id }
    }
    
    /// Return a list of flows that drain a stock.
    ///
    /// A stock outflows are all flow nodes where there is an edge of type
    /// ``FlowsMetamodel/Drains`` that originates in the stock and ends in
    /// the flow.
    ///
    /// - Parameters:
    ///     - stockID: an ID of a node that must be a stock
    ///
    /// - Returns: List of object IDs of flow nodes that drain the
    ///   stock.
    ///
    /// - Precondition: `stockID` must be an ID of a node that is a stock.
    ///
    public func stockOutflows(_ stockID: ObjectID) -> [ObjectID] {
        let stockNode = graph.node(stockID)
        // TODO: Do we need to check it here? We assume model is valid.
        precondition(stockNode.type === FlowsMetamodel.Stock)
        
        return outflows(stockID).nodes.map { $0.id }
    }

    /// Return a list of stock nodes that the given stock fills.
    ///
    /// Stock fills another stock if there exist a flow node in between
    /// the two stocks and the flow drains stock `stockID`.
    ///
    /// In the following example, the returned list of stocks for the stock
    /// `a` would be `[b]`.
    ///
    /// ```
    ///              Drains           Fills
    ///    Stock a ----------> Flow ---------> Stock b
    ///
    /// ```
    ///
    /// - SeeAlso: ``StockFlowView/implicitDrains(_:)``,
    /// ``StockFlowView/sortedStocksByImplicitFlows(_:)``
    ///
    /// - Precondition: `stockID` must be an ID of a node that is a stock.
    ///
    public func implicitFills(_ stockID: ObjectID) -> [ObjectID] {
        let stockNode = graph.node(stockID)
        // TODO: Do we need to check it here? We assume model is valid.
        precondition(stockNode.type === FlowsMetamodel.Stock)
        
        let hood = graph.hood(stockID,
                              selector: NeighborhoodSelector(
                                predicate: IsTypePredicate(FlowsMetamodel.ImplicitFlow),
                                direction: .outgoing))
        
        return hood.nodes.map { $0.id }
    }

    /// Return a list of stock nodes that the given stock drains.
    ///
    /// Stock drains another stock if there exist a flow node in between
    /// the two stocks and the flow fills stock `stockID`
    ///
    /// In the following example, the returned list of stocks for the stock
    /// `b` would be `[a]`.
    ///
    /// ```
    ///              Drains           Fills
    ///    Stock a ----------> Flow ---------> Stock b
    ///
    /// ```
    ///
    /// - SeeAlso: ``StockFlowView/implicitFills(_:)``,
    /// ``StockFlowView/sortedStocksByImplicitFlows(_:)``
    ///
    /// - Precondition: `stockID` must be an ID of a node that is a stock.
    ///
    public func implicitDrains(_ stockID: ObjectID) -> [ObjectID] {
        let stockNode = graph.node(stockID)
        // TODO: Do we need to check it here? We assume model is valid.
        precondition(stockNode.type === FlowsMetamodel.Stock)
        
        let hood = graph.hood(stockID,
                              selector: NeighborhoodSelector(
                                predicate: IsTypePredicate(FlowsMetamodel.ImplicitFlow),
                                direction: .incoming))

        return hood.nodes.map { $0.id }
    }
}
