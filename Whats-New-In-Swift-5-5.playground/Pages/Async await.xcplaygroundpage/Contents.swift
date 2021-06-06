/*:


&nbsp;

[< Previous](@previous)           [Home](Introduction)           [Next >](@next)
# Async await

[SE-0296](https://github.com/apple/swift-evolution/blob/main/proposals/0296-async-await.md) introduces asynchronous (async) functions into Swift, allowing us to run complex asynchronous code almost is if it were synchronous. This is done in two steps: marking async functions with the new `async` keyword, then calling them using the `await` keyword, similar to other languages such as C# and JavaScript.

To see how async/await helps the language, it’s helpful to look at how we solved the same problem previously. Completion handlers are commonly used in Swift code to allow us to send back values after a function returns, but they had tricky syntax  as you’ll see.

For example, if we wanted to write code that fetched 100,000 weather records from a server, processes them to calculate the average temperature over time, then uploaded the resulting average back to a server, we might have written this:
*/
func fetchWeatherHistory(completion: @escaping ([Double]) -> Void) {
    // Complex networking code here; we'll just send back 100,000 random temperatures
    DispatchQueue.global().async {
        let results = (1...100_000).map { _ in Double.random(in: -10...30) }
        completion(results)
    }
}
    
func calculateAverageTemperature(for records: [Double], completion: @escaping (Double) -> Void) {
    // Sum our array then divide by the array size
    DispatchQueue.global().async {
        let total = records.reduce(0, +)
        let average = total / Double(records.count)
        completion(average)
    }
}
    
func upload(result: Double, completion: @escaping (String) -> Void) {
    // More complex networking code; we'll just send back "OK"
    DispatchQueue.global().async {
        completion("OK")
    }
}
/*:
I’ve substituted actual networking code with fake values because the networking part isn’t relevant here. What matters is that each of those functions can take some time to run, so rather than blocking execution of the function and returning a value directly we instead use a completion closure to send something back only when we’re ready.

When it comes to using that code, we need to call them one by one in a chain, providing completion closures for each one to continue the chain, like this:
*/
fetchWeatherHistory { records in
    calculateAverageTemperature(for: records) { average in
        upload(result: average) { response in
            print("Server response: \(response)")
        }
    }
}
/*:
Hopefully you can see the problems with this approach:

- It’s possible for those functions to call their completion handler more than once, or forget to call it entirely.
- The parameter syntax `@escaping (String) -> Void` can be hard to read.
- At the call site we end up with a so-called pyramid of doom, with code increasingly indented for each completion handler.
- Until Swift 5.0 added the `Result` type, it was harder to send back errors with completion handlers.

From Swift 5.5, we can now clean up our functions by marking them as asynchronously returning a value rather than relying on completion handlers, like this:
*/
func fetchWeatherHistory() async -> [Double] {
    (1...100_000).map { _ in Double.random(in: -10...30) }
}
    
func calculateAverageTemperature(for records: [Double]) async -> Double {
    let total = records.reduce(0, +)
    let average = total / Double(records.count)
    return average
}
    
func upload(result: Double) async -> String {
    "OK"
}
/*:
That has already removed a lot of the syntax around returning values asynchronously, but at the call site it’s even cleaner:
*/
func processWeather() async {
    let records = await fetchWeatherHistory()
    let average = await calculateAverageTemperature(for: records)
    let response = await upload(result: average)
    print("Server response: \(response)")
}
/*:
As you can see, all the closures and indenting have gone, making for what is sometimes called “straight-line code” – apart from the `await` keywords, it looks just like synchronous code.

There are some straightforward, specific rules about the way async functions work:

- Synchronous functions cannot simply call async functions directly – it wouldn’t make sense, so Swift will throw an error.
- Async functions can call other async functions, but they can also call regular synchronous functions if they need to.
- If you have async and synchronous functions that can be called in the same way, Swift will prefer whichever one matches your current context – if the call site is currently async then Swift will call the async function, otherwise it will call the synchronous function. 

That last point is important, because it allows library authors to provide both synchronous and asynchronous versions of their code without having to name the async functions specially.

The addition of `async`/`await` fits perfectly alongside `try`/`catch`, meaning that async functions and initializers can throw errors if needed. The only proviso here is that Swift enforces a particular order for the keywords, and that order is *reversed* between call site and function.

For example, we might have functions that attempt to fetch a number of users from a server, and save them to disk, both of which might fail by throwing errors:
*/
enum UserError: Error {
    case invalidCount, dataTooLong
}
    
func fetchUsers(count: Int) async throws -> [String] {
    if count > 3 {
        // Don't attempt to fetch too many users
        throw UserError.invalidCount
    }
    
    // Complex networking code here; we'll just send back up to `count` users
    return Array(["Antoni", "Karamo", "Tan"].prefix(count))
}
    
func save(users: [String]) async throws -> String {
    let savedUsers = users.joined(separator: ",")
    
    if savedUsers.count > 32 {
        throw UserError.dataTooLong
    } else {
        // Actual saving code would go here
        return "Saved \(savedUsers)!"
    }
}
/*:
As you can see, both those functions are marked `async throws` – they are asynchronous functions, and they might throw errors.

When it comes to *calling* them the order of keywords is flipped to `try await` rather than `await try`, like this:
*/
func updateUsers() async {
    do {
        let users = try await fetchUsers(count: 3)
        let result = try await save(users: users)
        print(result)
    } catch {
        print("Oops!")
    }
}
/*:
So, “asynchronous, throwing” in the function definition, but “throwing, asynchronous” at the call site – think of it as unwinding a stack. Not only does `try await` read a little more naturally than `await try`, but it’s also more reflective of what’s actually happening: we’re waiting for some work to complete, and when it *does* complete it might end up throwing.

With async/await now in Swift itself, the `Result` type introduced in Swift 5.0 becomes much less important as one of its primary benefits was improving completion handlers. That doesn’t mean `Result` is useless, because it’s still the best way to store the result of an operation for later evaluation.

**Important:** Making a function asynchronous doesn’t mean it magically runs concurrently with other code, which means unless you specify otherwise calling multiple async functions will still run them sequentially.

All the `async` functions you’ve seen so far have in turn been called by other `async` functions, which is intentional: taken by itself this Swift Evolution proposal does not actually provide any way to run asynchronous code from a synchronous context. Instead, this functionality is defined in a separate Structured Concurrency proposal, although hopefully we’ll see some major updates to Foundation too.

&nbsp;

[< Previous](@previous)           [Home](Introduction)           [Next >](@next)
*/