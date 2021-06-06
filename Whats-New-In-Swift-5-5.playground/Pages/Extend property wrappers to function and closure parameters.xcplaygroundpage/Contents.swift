/*:


&nbsp;

[< Previous](@previous)           [Home](Introduction)           [Next >](@next)
# Extend property wrappers to function and closure parameters

[SE-0293](https://github.com/apple/swift-evolution/blob/main/proposals/0293-extend-property-wrappers-to-function-and-closure-parameters.md) extends property wrappers so they can be applied to parameters for functions and closures. Parameters passed this way are still immutable unless you take a copy of them, and you are still able to access the underlying property wrapper type using a leading underscore if you want.

As an example, we could write a function that accepts an integer and prints it out:
*/
func setScore1(to score: Int) {
    print("Setting score to \(score)")
}
/*:
When that’s called we can pass it any range of values, like this:
*/
setScore1(to: 50)
setScore1(to: -50)
setScore1(to: 500)
/*:
If we wanted our scores to lie only within the range 0...100 we could write a simple property wrapper that clamps numbers as they are created:
*/
@propertyWrapper
struct Clamped<T: Comparable> {
    let wrappedValue: T
    
    init(wrappedValue: T, range: ClosedRange<T>) {
        self.wrappedValue = min(max(wrappedValue, range.lowerBound), range.upperBound)
    }
}
/*:
Now we can write and call a new function using that wrapper:
*/
func setScore2(@Clamped(range: 0...100) to score: Int) {
    print("Setting score to \(score)")
}

setScore2(to: 50)
setScore2(to: -50)
setScore2(to: 500)
/*:
Calling `setScore2()` with the same input values as before will print different output, because the numbers will get clamped to 50, 0, 100.

**Tip:** Our property wrapper is trivial because parameters passed into a function are immutable – we don’t need to handle re-clamping the wrapped value when it changes because it won’t change. However, you can make your property wrappers as complex as you need; they work just as they would with properties or local variables.

&nbsp;

[< Previous](@previous)           [Home](Introduction)           [Next >](@next)
*/