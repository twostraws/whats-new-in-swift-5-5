/*:


&nbsp;

[< Previous](@previous)           [Home](Introduction)           [Next >](@next)
# Codable synthesis for enums with associated values

[SE-0295](https://github.com/apple/swift-evolution/blob/main/proposals/0295-codable-synthesis-for-enums-with-associated-values.md) upgrades Swift’s `Codable` system to support writing enums with associated values. Previously enums were only supported if they conformed to `RawRepresentable`, but this extends support to general enums as well as enum cases with any number of `Codable` associated values.

For example, we could define a `Weather` enum like this one:
*/
enum Weather: Codable {
    case sun
    case wind(speed: Int)
    case rain(amount: Int, chance: Int)
}
/*:
That has one simple case, one case with a single associated values, and a third case with two associated values – all are integers, but you could use strings or other `Codable` types.

With that enum defined, we can create an array of weather to make a forecast, then use `JSONEncoder` or similar and convert the result to a printable string:
*/
import Foundation

let forecast: [Weather] = [
    .sun,
    .wind(speed: 10),
    .sun,
    .rain(amount: 5, chance: 50)
]

do {
    let result = try JSONEncoder().encode(forecast)
    let jsonString = String(decoding: result, as: UTF8.self)
    print(jsonString)
} catch {
    print("Encoding error: \(error.localizedDescription)")
}
/*:
Behind the scenes, this is implemented using multiple `CodingKey` enums capable of handling the nested structure that results from having values attached to enum cases, which means writing your own custom coding methods to do the same is a little more work.

&nbsp;

[< Previous](@previous)           [Home](Introduction)           [Next >](@next)
*/