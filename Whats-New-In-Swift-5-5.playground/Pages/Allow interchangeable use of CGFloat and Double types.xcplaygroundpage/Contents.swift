/*:


&nbsp;

[< Previous](@previous)           [Home](Introduction)           [Next >](@next)
# Allow interchangeable use of `CGFloat` and `Double` types

[SE-0307](https://github.com/apple/swift-evolution/blob/main/proposals/0307-allow-interchangeable-use-of-double-cgfloat-types.md) introduces a small but important quality of life improvement: Swift is able to implicitly convert between `CGFloat` and `Double` in most places where it is needed.

In its simplest form, this means we can add a `CGFloat` and a `Double` together to produce a new `Double`, like this:
*/
let first: CGFloat = 42
let second: Double = 19
let result = first + second
print(result)
/*:
Swift implements this by inserting an implicit initializer as needed, and it will always prefer `Double` if it’s possible. More importantly, none of this is achieved by rewriting existing APIs: technically things like `scaleEffect()` in SwiftUI still work with `CGFloat`, but Swift quietly bridges this to `Double`.

&nbsp;

[< Previous](@previous)           [Home](Introduction)           [Next >](@next)
*/