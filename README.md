# Ballast

A property wrapper for discardable, re-creatable resources.

```swift
/// `thing` does not retain a `MyClass`, but will continue
/// serving the same value if it's retained elsewhere, or
/// create a new one on demand.
@Ballast(MyClass())
var thing: MyClass
```

```swift
/// `thing` retains a `MyClass` like a normal property
/// but it can be cleared by calling `_thing.jettison()`
/// and the resource is recreated on future calls.
@Ballast(MyClass(), policy: .manualRelease)
var thing: MyClass

...
func foo() {
    _thing.jettison()
    // `thing` will be re-created on the next access
}
```

```swift
/// `thing` retains a `MyClass` like a normal property
/// but is cleared when the supplied notification is
/// posted to `NotificationCenter.default`
@Ballast(MyClass(), policy: .notification(.didReceiveMemoryWarningNotification))
var thing: MyClass
```

```swift
/// `thing` retains a `MyClass` like a normal property
/// but is cleared after the specified `DispatchTimeInterval` elapses
/// without anyone reading the property. Reading the property
/// extends the lifespan by the specified amount of time.
/// Clearing the value is dispatched to the specified `DispatchQueue`.
@Ballast(MyClass(), policy: .disuse(.seconds(50), .main))
var thing: MyClass
```
