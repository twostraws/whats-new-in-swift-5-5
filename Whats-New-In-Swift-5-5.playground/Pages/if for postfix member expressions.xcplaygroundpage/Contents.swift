/*:


&nbsp;

[< Previous](@previous)           [Home](Introduction)           [Next >](@next)
# `#if` for postfix member expressions

[SE-0308](https://github.com/apple/swift-evolution/blob/main/proposals/0308-postfix-if-config-expressions.md) allows Swift to use `#if` conditions with postfix member expressions. This sounds a bit obscure, but it solves a problem commonly seen with SwiftUI: you can now optionally add modifiers to a view.

For example, this change allows us to create a text view with two different font sizes depending on whether we’re using iOS or another platform:
*/
import SwiftUI

Text("Welcome")
#if os(iOS)
    .font(.largeTitle)
#else
    .font(.headline)
#endif
/*:
You can nest these if you want, although it’s a bit hard on your eyes:
*/
Text("Welcome")
#if os(iOS)
    .font(.largeTitle)
    #if DEBUG
        .foregroundColor(.red)
    #endif
#else
    .font(.headline)
#endif
/*:
You could use wildly different postfix expressions if you wanted:
*/
let result = [1, 2, 3]
#if os(iOS)
    .count
#else
    .reduce(0, +)
#endif

print(result)
/*:
Technically you could make `result` end up as two completely different types if you wanted, but that seems like a bad idea. What you *definitely* can’t do is use other kinds of expressions such as using `+ [4]` instead of `.count` – if it doesn’t start with `.` then it’s not a postfix member expression.

&nbsp;

[< Previous](@previous)           [Home](Introduction)           [Next >](@next)
*/