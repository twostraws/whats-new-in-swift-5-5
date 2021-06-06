/*:


&nbsp;

[< Previous](@previous)           [Home](Introduction)           [Next >](@next)
# Structured concurrency

[SE-0304](https://github.com/apple/swift-evolution/blob/main/proposals/0304-structured-concurrency.md) introduces a whole range of approaches to execute, cancel, and monitor concurrent operations in Swift, and builds upon the work introduced by async/await and async sequences.

For easier demonstration purposes, here are a couple of example functions we can work with – an async function to simulate fetching a certain number of weather readings for a particular location, and a synchronous function to calculate which number lies at a particular position in the Fibonacci sequence:
*/
enum LocationError: Error {
    case unknown
}
    
func getWeatherReadings(for location: String) async throws -> [Double] {
    switch location {
    case "London":
        return (1...100).map { _ in Double.random(in: 6...26) }
    case "Rome":
        return (1...100).map { _ in Double.random(in: 10...32) }
    case "San Francisco":
        return (1...100).map { _ in Double.random(in: 12...20) }
    default:
        throw LocationError.unknown
    }
}
    
func fibonacci(of number: Int) -> Int {
    var first = 0
    var second = 1
    
    for _ in 0..<number {
        let previous = first
        first = second
        second = previous + first
    }
    
    return first
}
/*:
The simplest async approach introduced by structured concurrency is the ability to use the `@main` attribute to go immediately into an async context, which is done simply by marking the `main()` method with `async`, like this:
*/
@main
struct Main {
    static func main() async throws {
        let readings = try await getWeatherReadings(for: "London")
        print("Readings are: \(readings)")
    }
}
/*:
**Tip:** Before release, it should also be possible to run async code directly in main.swift, without using the `@main` attribute.

The main changes introduced by structured concurrency are backed by two new types, `Task` and `TaskGroup`, which allow us to run concurrent operations either individually or in a coordinated way. 

In its simplest form, you can start concurrent work by creating a new `Task` object and passing it the operation you want to run. This will start running on a background thread immediately, and you can use `await` to wait for its finished value to come back.

So, we might call `fibonacci(of:)` many times on a background thread, in order to calculate the first 50 numbers in the sequence:
*/
func printFibonacciSequence() async {
    let task1 = Task { () -> [Int] in
        var numbers = [Int]()
    
        for i in 0..<50 {
            let result = fibonacci(of: i)
            numbers.append(result)
        }
    
        return numbers
    }
    
    let result1 = await task1.value
    print("The first 50 numbers in the Fibonacci sequence are: \(result1)")
}
/*:
As you can see, I’ve needed to explicitly write `Task { () -> [Int] in` so that Swift understands that the task is going to return, but if your task code is simpler that isn’t needed. For example, we could have written this and gotten exactly the same result:
*/
let task1 = Task {
    (0..<50).map(fibonacci)
}
   
/*:
Again, the task starts running as soon as it’s created, and the `printFibonacciSequence()` function will continue running on whichever thread it was while the Fibonacci numbers are being calculated.

**Tip:** Our task's operation is a non-escaping closure because the task immediately runs it rather than storing it for later, which means if you use `Task` inside a class or a struct you don’t need to use `self` to access properties or methods.

When it comes to reading the finished numbers, `await task1.value` will make sure execution of `printFibonacciSequence()` pauses until the task’s output is ready, at which point it will be returned. If you don’t actually care what the task returns – if you just want the code to start running and finish whenever – you don’t need to store the task anywhere.

For task operations that throw uncaught errors, reading your task’s `value` property will automatically also throw errors. So, we could write a function that performs two pieces of work at the same time then waits for them both to complete:
*/
func runMultipleCalculations() async throws {
    let task1 = Task {
        (0..<50).map(fibonacci)
    }
    
    let task2 = Task {
        try await getWeatherReadings(for: "Rome")
    }
    
    let result1 = await task1.value
    let result2 = try await task2.value
    print("The first 50 numbers in the Fibonacci sequence are: \(result1)")
    print("Rome weather readings are: \(result2)")
}
/*:
Swift provides us with the built-in task priorities of `high`, `default`, `low`, and `background`. The code above doesn’t specifically set one so it will get `default`, but we could have said something like `Task(priority: .high)` to customize that. If you’re writing just for Apple’s platforms, you can also use the more familiar priorities of `userInitiated` in place of high, and `utility` in place of `low`, but you *can’t* access `userInteractive` because that is reserved for the main thread.

As well as just running operations, `Task` also provides us with a handful of static methods to control the way our code runs:

- Calling `Task.sleep()` will cause the current task to sleep for a specific number of nanoseconds. Until something better comes along, this means writing 1_000_000_000 to mean 1 second.
- Calling `Task.checkCancellation()` will check whether someone has asked for this task to be cancelled by calling its `cancel()` method, and if so throw a `CancellationError`.
- Calling `Task.yield()` will suspend the current task for a few moments in order to give some time to any tasks that might be waiting, which is particularly important if you’re doing intensive work in a loop.

You can see both sleeping and cancellation in the following code example, which puts a task to sleep for one second then cancels it before it completes:
*/
func cancelSleepingTask() async {
    let task = Task { () -> String in
        print("Starting")
        await Task.sleep(1_000_000_000)
        try Task.checkCancellation()
        return "Done"
    }
    
    // The task has started, but we'll cancel it while it sleeps
    task.cancel()
    
    do {
        let result = try await task.value
        print("Result: \(result)")
    } catch {
        print("Task was cancelled.")
    }
}
/*:
In that code, `Task.checkCancellation()` will realize the task has been cancelled and immediately throw `CancellationError`, but that won’t reach us until we attempt to read `task.value`.

**Tip:** Use `task.result` to get a `Result` value containing the task’s success and failure values. For example, in the code above we’d get back a `Result<String, Error>`. This does *not* require a `try` call because you still need to handle the success or failure case.

For more complex work, you should create *task groups* instead – collections of tasks that work together to produce a finished value.

To minimize the risk of programmers using task groups in dangerous ways, they don’t have a simple public initializer. Instead, task groups are created using functions such as `withTaskGroup()`: call this with the body of work you want done, and you’ll be passed in the task group instance to work with. Once inside the group you can add work using the `async()` method, and it will start executing immediately.

**Important:** You should not attempt to copy that task group outside the body of `withTaskGroup()` – the compiler can’t stop you, but you’re just going to make problems for yourself.

To see a simple example of how task groups work – along with demonstrating an important point of how they order their operations, try this:
*/
func printMessage() async {
    let string = await withTaskGroup(of: String.self) { group -> String in
        group.async { "Hello" }
        group.async { "From" }
        group.async { "A" }
        group.async { "Task" }
        group.async { "Group" }

        var collected = [String]()

        for await value in group {
            collected.append(value)
        }

        return collected.joined(separator: " ")
    }

    print(string)
}
/*:
That creates a task group designed to produce one finished string, then queues up several closures using the `async()` method of the task group. Each of those closures returns a single string, which then gets collected into an array of strings, before being joined into one single string and returned for printing.

**Tip:** All tasks in a task group must return the same type of data, so for complex work you might find yourself needing to return an enum with associated values in order to get exactly what you want. A simpler alternative is introduced in a separate Async Let Bindings proposal.

Each call to `async()` can be any kind of function you like, as long as it results in a string. However, although task groups automatically wait for all the child tasks to complete before returning, when that code runs it’s a bit of a toss up what it will print because the child tasks can complete in any order – we’re as likely to get “Hello From Task Group A” as we are “Hello A Task Group From”, for example.

If your task group is executing code that might throw, you can either handle the error directly inside the group or let it bubble up outside the group to be handled there. That latter option is handled using a different function, `withThrowingTaskGroup()`, which must be called with `try` if you haven’t caught all the errors you throw.

For example, this next code sample calculates weather readings for several locations in a single group, then returns the overall average for all locations:
*/
func printAllWeatherReadings() async {
    do {
        print("Calculating average weather…")

        let result = try await withThrowingTaskGroup(of: [Double].self) { group -> String in
            group.async {
                try await getWeatherReadings(for: "London")
            }

            group.async {
                try await getWeatherReadings(for: "Rome")
            }

            group.async {
                try await getWeatherReadings(for: "San Francisco")
            }

            // Convert our array of arrays into a single array of doubles
            let allValues = try await group.reduce([], +)
                
            // Calculate the mean average of all our doubles
            let average = allValues.reduce(0, +) / Double(allValues.count)
            return "Overall average temperature is \(average)"
        }

        print("Done! \(result)")
    } catch {
        print("Error calculating data.")
    }
}
/*:
In that instance, each of the calls to `async()` is identical apart from the location string being passed in, so you can use something like `for location in ["London", "Rome", "San Francisco"] {` to call `async()` in a loop.

Task groups have a `cancelAll()` method that cancels any tasks inside the group, but using `async()` afterwards will continue to add work to the group. As an alternative, you can use `asyncUnlessCancelled()` to skip adding work if the group has been cancelled – check its returned Boolean to see whether the work was added successfully or not.

&nbsp;

[< Previous](@previous)           [Home](Introduction)           [Next >](@next)
*/