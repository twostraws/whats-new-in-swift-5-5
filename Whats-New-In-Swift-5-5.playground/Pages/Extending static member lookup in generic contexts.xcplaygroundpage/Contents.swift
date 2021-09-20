/*:


&nbsp;

[< Previous](@previous)           [Home](Introduction)
# Extending static member lookup in generic contexts

[SE-0299](https://github.com/apple/swift-evolution/blob/main/proposals/0299-extend-generic-static-member-lookup.md) allows Swift to perform static member lookup for members of protocols in generic functions, which sounds obscure but actually fixes a small but important legibility problem that hit SwiftUI particularly hard.

At this time SwiftUI hasn’t been updated to support this change, but if everything goes to plan we can stop writing this:
*/
import SwiftUI

Toggle("Example", isOn: .constant(true))
    .toggleStyle(SwitchToggleStyle())
/*:
And instead write something like this:
*/
Toggle("Example", isOn: .constant(true))
    .toggleStyle(.switch)
/*:
This was possible in early SwiftUI betas because Apple had put extensive workarounds in place, but these were withdrawn before release.

To see what’s actually changing here, imagine a `Theme` protocol with several structs conforming to it:
*/
protocol Theme { }
struct LightTheme: Theme { }
struct DarkTheme: Theme { }
struct RainbowTheme: Theme { }
/*:
We could also define a `Screen` protocol that is able to have a `theme()` method called on it with some sort of theme:
*/
protocol Screen { }
    
extension Screen {
    func theme<T: Theme>(_ style: T) -> Screen {
        print("Activating new theme!")
        return self
    }
}
/*:
And now we could create an instance of a screen:
*/
struct HomeScreen: Screen { }
/*:
Following older SwiftUI code, we could enable a light theme on that screen by specifying `LightTheme()`:
*/
let lightScreen = HomeScreen().theme(LightTheme())
/*:
If we wanted to make that easier to access, we could try adding a static `light` property to our `Theme` protocol like this:
*/
extension Theme where Self == LightTheme {
    static var light: LightTheme { .init() }
}
/*:
However, *using* that with the `theme()` method of our generic protocol was what caused the problem: before Swift 5.5 it was not possible and you had to use `LightTheme()` every time. However, in Swift 5.5 or later this is now possible:
*/
let lightTheme = HomeScreen().theme(.light)
/*:

&nbsp;

[< Previous](@previous)           [Home](Introduction)
*/