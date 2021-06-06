/*:


&nbsp;

[< Previous](@previous)           [Home](Introduction)           [Next >](@next)
# Continuations for interfacing async tasks with synchronous code

[SE-0300](https://github.com/apple/swift-evolution/blob/main/proposals/0300-continuation.md) introduces new functions to help us adapt older, completion handler-style APIs to modern async code.

For example, this function returns its values asynchronously using a completion handler:
*/
func fetchLatestNews(completion: @escaping ([String]) -> Void) {
    DispatchQueue.main.async {
        completion(["Swift 5.5 release", "Apple acquires Apollo"])
    }
}
/*:
If you wanted to use that using async/await you might be able to rewrite the function, but there are various reasons why that might not be possible – it might come from an external library, for example.

Continuations allow us to create a shim between the completion handler and async functions so that we wrap up the older code in a more modern API. For example, the `withCheckedContinuation()` function creates a new continuation that can run whatever code you want, then call `resume(returning:)` to send a value back whenever you’re ready – even if that’s part of a completion handler closure.

So, we could make a second `fetchLatestNews()` function that is async, wrapping around the older completion handler function:
*/
func fetchLatestNews() async -> [String] {
    await withCheckedContinuation { continuation in
        fetchLatestNews { items in
            continuation.resume(returning: items)
        }
    }
}
/*:
With that in place we can now get our original functionality in an async function, like this:
*/
func printNews() async {
    let items = await fetchLatestNews()
    
    for item in items {
        print(item)
    }
}
/*:
The term “checked” continuation means that Swift is performing runtime checks on our behalf: are we calling `resume()` once and only once? This is important, because if you never resume the continuation then you will leak resources, but if you call it twice then you’re likely to hit problems. 

**Important:** To be crystal clear, you *must* resume your continuation exactly once. 

As there is a runtime performance cost of checking your continuations, Swift also provides a `withUnsafeContinuation()` function that works in exactly the same way except does *not* perform runtime checks on your behalf. This means Swift won’t warn you if you forget to resume the continuation, and if you call it twice then the behavior is undefined. 

Because these two functions are called in the same way, you can switch between them easily. So, it seems likely people will use `withCheckedContinuation()` while writing their functions so Swift will emit warnings and even trigger crashes if the continuations are used incorrectly, but some may then switch over to `withUnsafeContinuation()` as they prepare to ship if they are affected by the runtime performance cost of checked continuations.

&nbsp;

[< Previous](@previous)           [Home](Introduction)           [Next >](@next)
*/