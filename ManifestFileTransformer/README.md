# ManifestFileTransformer

This project shows how we can mechanically edit `Package.swift` file with the help of `libSyntax`, more specific with its Swift version `SwiftSyntax`.

There is only a possibility for modifying package targets but the ways for modifying another parts of the package are similar.

All modification related work is done by the `TargetsListRewriter` class which is a subclass of `SyntaxRewriter`.

It has three working modes:

```swift
enum Mode {
// NOTE: String type will be replaced with the Target type
case add(target: String)
case remove(targetName: String)
case rename(from: String, to: String)
}
```

Remove and rename options operates with the target name while add option operates with the Target type (I pass `String` type for now but it can be replaced with the appropriate type and expression building will be performed based on the data passed to this option).

Remove and rename options don’t have any effect if the target with the given name isn’t presented in the targets list of the parsed `Package.swift` file.

While adding a new target a check for presence of the targets argument in the `Package` initializer is performed. If there is no targets argument, it will be added to the right position based on the order in `Package` init method.
