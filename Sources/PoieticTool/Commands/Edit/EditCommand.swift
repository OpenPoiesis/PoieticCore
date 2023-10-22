//
//  InspectCommand.swift
//
//
//  Created by Stefan Urbanek on 29/06/2023.
//

import ArgumentParser
import PoieticCore
import PoieticFlows

extension PoieticTool {
    struct Edit: ParsableCommand {
        static var configuration
        = CommandConfiguration(
            abstract: "Edit an object or a selection of objects",
            subcommands: [
                SetAttribute.self,
                Undo.self,
                Redo.self,
                Add.self,
                NewConnection.self,
                Remove.self,
                AutoParameters.self,
                Layout.self,
            ]
        )
        
        @OptionGroup var options: Options
    }
}

