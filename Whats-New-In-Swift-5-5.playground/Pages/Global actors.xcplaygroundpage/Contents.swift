/*:


&nbsp;

[< Previous](@previous)           [Home](Introduction)           [Next >](@next)
# Global actors 

[SE-0316](https://github.com/apple/swift-evolution/blob/main/proposals/0316-global-actors.md) allows global state to be isolated from data races by using actors.

Although in theory this could result in many global actors, the main benefit at least right now is the introduction of an `@MainActor` global actor you can use to mark properties and methods that should be accessed only on the main thread.

As an example, we might have a class to handle data storage in our app, and for safety reasons we refuse to write out change to persistent storage unless we’re on the main thread: 
*/
import Foundation 

class OldDataController {
    func save() -> Bool {
        guard Thread.isMainThread else {
            return false
        }
    
        print("Saving data…")
        return true
    }
}
/*:
That works, but with `@MainActor` we can guarantee that `save()` is always called on the main thread as if we specifically ran it using `DispatchQueue.main`:
*/
class NewDataController {
    @MainActor func save() {
        print("Saving data…")
    }
}
/*:
That’s all it takes – Swift will make sure whenever you call `save()` on a data controller, that work will happen on the main thread.

- important:  Because we’re pushing work through an actor, you must call `save()` using `await`, `async let`, or similar.

`@MainActor` is a global actor wrapper around the underlying `MainActor` struct, which is helpful because it has a static `run()` method that lets us schedule work to be run. This will execute your code on the main thread, optionally sending back a result.

&nbsp;

[< Previous](@previous)           [Home](Introduction)           [Next >](@next)
*/