//
//  TargetsListSyntaxBuilder.swift
//  ManifestFileTransformer
//
//  Created by Denis on 18.03.2018.
//  Copyright © 2018 Denis Morozov. All rights reserved.
//

import SwiftSyntax

enum TargetsListSyntaxBuilder {
    
    static func buildArrayExpr(from arrayExpr: ArrayExprSyntax, withNewTarget target: String) -> ArrayExprSyntax {
        if arrayExpr.elements.count == 0 {
            return arrayExpr.withElements(
                arrayExpr.elements.appending(SyntaxFactory.makeArrayElement(expression: buildTestTargetExpr(),
                                                                            trailingComma: nil))
            )
        }
        
        var localArrayExpr = arrayExpr
        
        let lastArrayElementIndex = localArrayExpr.elements.count - 1
        if localArrayExpr.elements[lastArrayElementIndex].trailingComma == nil {
            let updatedLastArrayElement = SyntaxFactory.makeArrayElement(expression: localArrayExpr.elements[lastArrayElementIndex].expression,
                                                                         trailingComma: SyntaxFactory.makeCommaToken())
            localArrayExpr = localArrayExpr.withElements(
                localArrayExpr.elements
                    .removing(childAt: lastArrayElementIndex)
                    .inserting(updatedLastArrayElement, at: lastArrayElementIndex)
            )
        }
        
        return localArrayExpr.withElements(localArrayExpr.elements.appending(SyntaxFactory.makeArrayElement(expression: buildTestTargetExpr(),
                                                                                                            trailingComma: nil)))
    }
    
    static func buildArrayExpr(from arrayExpr: ArrayExprSyntax, without targetName: String) -> ArrayExprSyntax {
        for (i, arrayElement) in arrayExpr.elements.enumerated() {
            if let functionCallExpr = arrayElement.expression as? FunctionCallExprSyntax {
                
                let removeTargetAndReturnNewSyntaxExpression: () -> ArrayExprSyntax? = {
                    var isTargetForRemoving = false
                    for functionCallArgument in functionCallExpr.argumentList where functionCallArgument.label?.text == "name" {
                        if let stringLiteralExpr = functionCallArgument.expression as? StringLiteralExprSyntax,
                            stringLiteralExpr.stringLiteral.text == "\"\(targetName)\"" {
                            isTargetForRemoving = true
                        }
                    }
                    
                    if isTargetForRemoving {
                        return arrayExpr.withElements(arrayExpr.elements.removing(childAt: i))
                    }
                    
                    return nil
                }
                
                if let implicitMemberExpr = functionCallExpr.calledExpression as? ImplicitMemberExprSyntax,
                    implicitMemberExpr.name.text == "target" || implicitMemberExpr.name.text == "testTarget" {
                    if let newArrayExpr = removeTargetAndReturnNewSyntaxExpression() {
                        return newArrayExpr
                    }
                }
                
                if let memberAccessExpr = functionCallExpr.calledExpression as? MemberAccessExprSyntax,
                    memberAccessExpr.name.text == "target" || memberAccessExpr.name.text == "testTarget" {
                    if let newArrayExpr = removeTargetAndReturnNewSyntaxExpression() {
                        return newArrayExpr
                    }
                }
            }
        }
        
        return arrayExpr
    }
    
    static func buildArrayExpr(from arrayExpr: ArrayExprSyntax, withRenamedTargetFrom oldName: String, to newName: String) -> ArrayExprSyntax {
        for (i, arrayElement) in arrayExpr.elements.enumerated() {
            if let functionCallExpr = arrayElement.expression as? FunctionCallExprSyntax {
                
                let replaceOldNameAndReturnNewSyntaxExpression: () -> ArrayExprSyntax? = {
                    var newFunctionCallExprArgumentList: FunctionCallArgumentListSyntax?
                    for (i, functionCallArgument) in functionCallExpr.argumentList.enumerated() where functionCallArgument.label?.text == "name" {
                        if let stringLiteralExpr = functionCallArgument.expression as? StringLiteralExprSyntax, stringLiteralExpr.stringLiteral.text == "\"\(oldName)\"" {
                            newFunctionCallExprArgumentList = functionCallExpr.argumentList
                                .removing(childAt: i)
                                .inserting(functionCallArgument.withExpression(SyntaxFactory.makeStringLiteralExpr(newName)), at: i)
                            break
                        }
                    }
                    
                    if let newFunctionCallExprArgumentList = newFunctionCallExprArgumentList {
                        let newFunctionCallExpr = functionCallExpr.withArgumentList(newFunctionCallExprArgumentList)
                        let newArrayElement = arrayElement.withExpression(newFunctionCallExpr)
                        let newArrayElements = arrayExpr.elements.removing(childAt: i).inserting(newArrayElement, at: i)
                        return arrayExpr.withElements(newArrayElements)
                    }
                    
                    return nil
                }
                
                if let implicitMemberExpr = functionCallExpr.calledExpression as? ImplicitMemberExprSyntax,
                    implicitMemberExpr.name.text == "target" || implicitMemberExpr.name.text == "testTarget" {
                    if let newArrayExpr = replaceOldNameAndReturnNewSyntaxExpression() {
                        return newArrayExpr
                    }
                }
                
                if let memberAccessExpr = functionCallExpr.calledExpression as? MemberAccessExprSyntax,
                    memberAccessExpr.name.text == "target" || memberAccessExpr.name.text == "testTarget" {
                    if let newArrayExpr = replaceOldNameAndReturnNewSyntaxExpression() {
                        return newArrayExpr
                    }
                }
            }
        }
        
        return arrayExpr
    }
    
    private static func buildTestTargetExpr() -> FunctionCallExprSyntax {
        return FunctionCallExprSyntax { builder in
            builder.useCalledExpression(
                ImplicitMemberExprSyntax { builder in
                    builder.useDot(SyntaxFactory.makePrefixPeriodToken(leadingTrivia: .newlines(1) + .spaces(8), trailingTrivia: .zero))
                    builder.useName(SyntaxFactory.makeIdentifier("target"))
                }
            )
            
            builder.useLeftParen(SyntaxFactory.makeLeftParenToken())
            builder.useRightParen(SyntaxFactory.makeRightParenToken())
            
            builder.addFunctionCallArgument(
                FunctionCallArgumentSyntax { builder in
                    builder.useLabel(SyntaxFactory.makeIdentifier("name", leadingTrivia: .newlines(1) + .spaces(12), trailingTrivia: .zero))
                    builder.useColon(SyntaxFactory.makeColonToken(leadingTrivia: .zero, trailingTrivia: .spaces(1)))
                    builder.useExpression(SyntaxFactory.makeStringLiteralExpr("NewTarget"))
                    builder.useTrailingComma(SyntaxFactory.makeCommaToken())
                }
            )
            
            builder.addFunctionCallArgument(
                FunctionCallArgumentSyntax { builder in
                    builder.useLabel(SyntaxFactory.makeIdentifier("dependencies",
                                                                  leadingTrivia: .newlines(1) + .spaces(12),
                                                                  trailingTrivia: .zero))
                    
                    builder.useColon(SyntaxFactory.makeColonToken(leadingTrivia: .zero, trailingTrivia: .spaces(1)))
                    
                    builder.useExpression(SyntaxFactory.makeArrayExpr(leftSquare: SyntaxFactory.makeLeftSquareBracketToken(),
                                                                      elements: SyntaxFactory.makeArrayElementList([]),
                                                                      rightSquare: SyntaxFactory.makeRightSquareBracketToken()))
                }
            )
        }
    }
    
    static func buildFunctionCallExprWithTargetsParameter(from functionCallExpr: FunctionCallExprSyntax) -> FunctionCallExprSyntax {
        let existingOptionalConstructorArguments = functionCallExpr.argumentList
            .compactMap { $0.label?.text }
            .filter { $0 != "name" }
        
        if existingOptionalConstructorArguments.contains("targets") {
            return functionCallExpr
        }
        
        let priorToTargetsConstructorArguments = ["pkgConfig", "providers", "products", "dependencies"]
        
        // Initial position right after the name argument
        var targetsArgumentPosition = 1
        for priorArgument in priorToTargetsConstructorArguments where existingOptionalConstructorArguments.contains(priorArgument) {
            targetsArgumentPosition += 1
        }
    
        return functionCallExpr.withArgumentList(
            functionCallExpr.argumentList.inserting(
                FunctionCallArgumentSyntax { builder in
                    let label = SyntaxFactory.makeIdentifier("targets",
                                                             leadingTrivia: .newlines(1) + .spaces(4),
                                                             trailingTrivia: .zero)
                    
                    let colon = SyntaxFactory.makeColonToken(leadingTrivia: .zero, trailingTrivia: .spaces(1))
                    
                    let expression = SyntaxFactory.makeArrayExpr(leftSquare: SyntaxFactory.makeLeftSquareBracketToken(),
                                                                 elements: SyntaxFactory.makeArrayElementList([]),
                                                                 rightSquare: SyntaxFactory.makeRightSquareBracketToken())
                    
                    let trailingComma = SyntaxFactory.makeCommaToken()
                    
                    builder.useLabel(label)
                    builder.useColon(colon)
                    builder.useExpression(expression)
                    builder.useTrailingComma(trailingComma)
                },
                at: targetsArgumentPosition)
        )
    }
    
}
