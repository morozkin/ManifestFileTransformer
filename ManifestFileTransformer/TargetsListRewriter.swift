//
//  TargetsListRewriter.swift
//  ManifestFileTransformer
//
//  Created by Denis on 18.03.2018.
//  Copyright © 2018 Denis Morozov. All rights reserved.
//

import SwiftSyntax

final class TargetsListRewriter: SyntaxRewriter {
    
    enum Mode {
        // NOTE: String type will be replaced with the Target type
        case add(target: String)
        case remove(targetName: String)
        case rename(from: String, to: String)
    }
    
    private let mode: Mode
    
    init(mode: Mode) {
        self.mode = mode
    }
    
    override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
        if let packageIdentifier = node.calledExpression as? IdentifierExprSyntax, packageIdentifier.identifier.text == "Package" {
            var areTargetsPresented = false
            for argument in node.argumentList {
                if let label = argument.label, label.text == "targets" {
                    areTargetsPresented = true
                }
            }
            
            // If targets parameter isn't presented then add it with an empty array value
            if !areTargetsPresented, case .add(_) = mode {
                return super.visit(TargetsListSyntaxBuilder.buildFunctionCallExprWithTargetsParameter(from: node))
            }
        }
        
        return super.visit(node)
    }
    
    override func visit(_ node: FunctionCallArgumentSyntax) -> Syntax {
        if let packageConsrtuctorCallExpr = node.parent?.parent as? FunctionCallExprSyntax,
            let packageIndetifierExpr = packageConsrtuctorCallExpr.calledExpression as? IdentifierExprSyntax,
            packageIndetifierExpr.identifier.text == "Package",
            let label = node.label,
            label.text == "targets",
            let targetsList = node.expression as? ArrayExprSyntax {
            
            switch mode {
            case let .add(target):
                return node.withExpression(
                    TargetsListSyntaxBuilder.buildArrayExpr(from: targetsList, withNewTarget: target)
                )
            case let .remove(targetName):
                return node.withExpression(
                    TargetsListSyntaxBuilder.buildArrayExpr(from: targetsList, without: targetName)
                )
            case let .rename(oldName, newName):
                return node.withExpression(
                    TargetsListSyntaxBuilder.buildArrayExpr(from: targetsList,
                                                            withRenamedTargetFrom: oldName,
                                                            to: newName)
                )
            }
        }
        
        return super.visit(node)
    }
    
}
