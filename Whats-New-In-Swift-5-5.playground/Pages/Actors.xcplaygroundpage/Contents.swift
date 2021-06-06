/*:


&nbsp;

[< Previous](@previous)           [Home](Introduction)           [Next >](@next)
# Actors

[SE-0306](https://github.com/apple/swift-evolution/blob/main/proposals/0306-actors.md) introduces actors, which are conceptually similar to classes that are safe to use in concurrent environments. This is possible because Swift ensures that mutable state inside your actor is only ever accessed by a single thread at any given time, which helps eliminate a variety of serious bugs right at the compiler level.

To demonstrate the problem actors solve, consider this Swift code that creates a `RiskyCollector` class able to trade cards from their deck with another collector:
*/
class RiskyCollector {
    var deck: Set<String>
    
    init(deck: Set<String>) {
        self.deck = deck
    }
    
    func send(card selected: String, to person: RiskyCollector) -> Bool {
        guard deck.contains(selected) else { return false }
    
        deck.remove(selected)
        person.transfer(card: selected)
        return true
    }
    
    func transfer(card: String) {
        deck.insert(card)
    }
}
/*:
In a single-threaded environment that code is safe: we check whether our deck contains the card in question, remove it, then add it to the other collector’s deck. However, in a multi-threaded environment our code has a potential race condition, which is a problem whereby the results of the code will vary as two separate parts of our code run side by side.

If we call `send(card:to:)` more than once at the same time, the following chain of events can happen:

1. The first thread checks whether the card is in the deck, and it is so it continues.
2. The second thread also checks whether the card is in the deck, and it is so it continues.
3. The first thread removes the card from the deck and transfer it to the other person.
4. The second thread attempts to remove the card from the deck, but actually it’s already gone so nothing will happen. However, it still transfers the card to the other person.

In that situation one player loses a card while the other gains *two* cards, and if that card happened to be a Black Lotus from Magic the Gathering then you’ve got a big problem!

Actors solve this problem by introducing *actor isolation*: stored properties and methods cannot be read from outside the actor object unless they are performed asynchronously, and stored properties cannot be *written* from outside the actor object at all. The async behavior isn’t there for performance; instead it’s because Swift automatically places these requests into a queue that is processed sequentially to avoid race conditions.

So, we could rewrite out `RiskyCollector` class to be a `SafeCollector` actor, like this:
*/
actor SafeCollector {
    var deck: Set<String>
    
    init(deck: Set<String>) {
        self.deck = deck
    }
    
    func send(card selected: String, to person: SafeCollector) async -> Bool {
        guard deck.contains(selected) else { return false }
    
        deck.remove(selected)
        await person.transfer(card: selected)
        return true
    }
    
    func transfer(card: String) {
        deck.insert(card)
    }
}
/*:
There are several things to notice in that example:

1. Actors are created using the new `actor` keyword. This is a new concrete nominal type in Swift, joining structs, classes, and enums.
2. The `send()` method is marked with `async`, because it will need to suspend its work while waiting for the transfer to complete.
3. Although the `transfer(card:)` method is *not* marked with `async`, we still need to *call* it with `await` because it will wait until the other `SafeCollector` actor is able to handle the request.

To be clear, an actor can use its own properties and methods freely, asynchronously or otherwise, but when interacting with a different actor it must always be done asynchronously. With these changes Swift can ensure that all actor-isolated state is never accessed concurrently, and more importantly this is done at compile time so that safety is guaranteed.

Actors and classes have some similarities:

- Both are reference types, so they can be used for shared state.
- They can have methods, properties, initializers, and subscripts.
- They can conform to protocols and be generic.
- Any properties and methods that are static behave the same in both types, because they have no concept of `self` and therefore don’t get isolated.

Beyond actor isolation, there are two other important differences between actors and classes:

- Actors do not currently support inheritance, which makes their initializers much simpler – there is no need for convenience initializers, overriding, the `final` keyword, and more. This might change in the future.
- All actors implicitly conform to a new `Actor` protocol; no other concrete type can use this. This allows you to restrict other parts of your code so it can work only with actors.

The best way I’ve heard to explain how actors differ from classes is this: “actors pass messages, not memory.” So, rather than one actor poking directly around in another’s properties or calling their methods, we instead send a message asking for the data and let the Swift runtime handle it for us safely.

&nbsp;

[< Previous](@previous)           [Home](Introduction)           [Next >](@next)
*/