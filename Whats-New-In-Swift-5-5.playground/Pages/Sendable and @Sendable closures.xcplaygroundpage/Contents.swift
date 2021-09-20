/*:


&nbsp;

[< Previous](@previous)           [Home](Introduction)           [Next >](@next)
# Sendable and @Sendable closures

[SE-0302](https://github.com/apple/swift-evolution/blob/main/proposals/0302-concurrent-value-and-concurrent-closures.md) adds support for “sendable” data, which is data that can safely be transferred to another thread. This is accomplished through a new `Sendable` protocol, and an `@Sendable` attribute for functions.

Many things are inherently safe to send across threads:

- All of Swift’s core value types, including `Bool`, `Int`, `String`, and similar.
- Optionals, where the wrapped data is a value type.
- Standard library collections that contain value types, such as `Array<String>` or `Dictionary<Int, String>`.
- Tuples where the elements are all value types.
- Metatypes, such as `String.self`.

These have been updated to conform to the `Sendable` protocol.

As for custom types, it depends what you’re making:

- Actors automatically conform to `Sendable` because they handle their synchronization internally.
- Custom structs and enums you define will also automatically conform to `Sendable` if they contain only values that also conform to `Sendable`, similar to how `Codable` works.
- Custom classes can conform to `Sendable` as long as they either inherits from `NSObject` or from nothing at all, all properties are constant and themselves conform to `Sendable`, and they are marked as `final` to stop further inheritance.

Swift lets us use the `@Sendable` attribute on functions or closure to mark them as working concurrently, and will enforce various rules to stop us shooting ourself in the foot. For example, the operation we pass into the `Task` initializer is marked `@Sendable`, which means this kind of code is allowed because the value captured by `Task` is a constant:
*/
func printScore() async { 
    let score = 1
    
    Task { print(score) }
    Task { print(score) }
}
/*:
However, that code would *not* be allowed if `score` were a variable, because it could be accessed by one of the tasks while the other was changing its value.

You can mark your own functions and closures using `@Sendable`, which will enforce similar rules around captured values:
*/
import Foundation 

func runLater(_ function: @escaping @Sendable () -> Void) -> Void {
    DispatchQueue.global().asyncAfter(deadline: .now() + 3, execute: function)
}
/*:

&nbsp;

[< Previous](@previous)           [Home](Introduction)           [Next >](@next)
*/