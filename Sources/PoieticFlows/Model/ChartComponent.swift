//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 11/09/2023.
//

import PoieticCore

public struct ChartComponent: Component {
    public static var componentDescription = ComponentDescription(
        name: "Chart",
        attributes: [
//            AttributeDescription(
//                name: "chartType",
//                type: .string,
//                abstract: "Chart type"),
        ]
    )

    public var value: Double

    public init() {
        self.value = 0
    }

    public func attribute(forKey key: PoieticCore.AttributeKey) -> PoieticCore.AttributeValue? {
        switch key {
        case "value": return ForeignValue(value)
        default: return nil
        }
    }
    
    public mutating func setAttribute(value: PoieticCore.AttributeValue, forKey key: PoieticCore.AttributeKey) throws {
        switch key {
        case "value": self.value = try value.doubleValue()
        default:
            throw AttributeError.unknownAttribute(name: key,
                                                  type: String(describing: type(of: self)))
        }
    }
}

// TODO: [EXPERIMENTAL] The following is experimental
/// Object representing a chart.
///
/// - ToDo: This is experimental.
///
public struct Chart {
    public let node: ObjectSnapshot
    public let component: ChartComponent
    public let series: [ObjectSnapshot]
    
    public init(node: ObjectSnapshot, component: ChartComponent, series: [ObjectSnapshot]) {
        self.node = node
        self.component = component
        self.series = series
    }
    
}

public struct ChartSeries {
    public let node: ObjectSnapshot
    var name: String { node.name! }
}
extension StockFlowView {
    public var charts: [Chart] {
        let nodes = graph.selectNodes(HasComponentPredicate(ChartComponent.self))
        var charts: [Chart] = []
        for node in nodes {
            let component: ChartComponent = node[ChartComponent.self]!
            let hood = graph.hood(node.id,
                                  selector: NeighborhoodSelector(
                                    predicate: IsTypePredicate(FlowsMetamodel.ChartSeries),
                                    direction: .outgoing))
            let series = hood.nodes.map { $0.snapshot }
            let chart = Chart(node: node.snapshot,
                              component: component,
                              series: series)
            charts.append(chart)
        }
        return charts
    }
}