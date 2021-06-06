/*:


&nbsp;

[< Previous](@previous)           [Home](Introduction)           [Next >](@next)
# `lazy` now works in local contexts

The `lazy` keyword has always allowed us to write stored properties that are only calculated when first used, but from Swift 5.5 onwards we can use `lazy` locally inside a function to create values that work similarly.

This code demonstrates local `lazy` in action:
*/
func printGreeting(to: String) -> String {
    print("In printGreeting()")
    return "Hello, \(to)"
}
    
func lazyTest() {
    print("Before lazy")
    lazy var greeting = printGreeting(to: "Paul")
    print("After lazy")
    print(greeting)
}
    
lazyTest()
/*:
When that runs you’ll see “Before lazy” and “After lazy” printed first, followed by “In printGreeting()” then “Hello, Paul” – Swift only runs the `printGreeting(to:)` code when its result is accessed on the `print(greeting)` line.

In practice, this feature is going to be really helpful as a way of selectively running code when you have conditions in place: you can prepare the result of some work lazily, and only actual perform the work if it’s still needed later on.

&nbsp;

[< Previous](@previous)           [Home](Introduction)           [Next >](@next)
*/