//
//  main.swift
//  ManifestFileTransformer
//
//  Created by Denis on 09.03.2018.
//  Copyright © 2018 Denis Morozov. All rights reserved.
//

import SwiftSyntax

let sourceFileSyntax = SourceFileSyntaxFactory.makeTestSourceFileSyntax()

let addTargetRewriter = TargetsListRewriter(mode: .add(target: "NewTarget"))
var rewrittenSourceFileSyntax = addTargetRewriter.visit(sourceFileSyntax)

let removeTargetRewriter = TargetsListRewriter(mode: .remove(targetName: "UtilityTests"))
rewrittenSourceFileSyntax = removeTargetRewriter.visit(rewrittenSourceFileSyntax)

let renameTargetRewriter = TargetsListRewriter(mode: .rename(from: "PackageDescription",
                                                             to: "PackageDescription3"))
rewrittenSourceFileSyntax = renameTargetRewriter.visit(rewrittenSourceFileSyntax)

print("\n//======== Original =========\n")
print(sourceFileSyntax)

print("\n//======== Modified =========\n")
print(rewrittenSourceFileSyntax)

