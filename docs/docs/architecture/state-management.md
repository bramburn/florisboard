# Keyboard State Management

## Overview

Learn how FlorisBoard manages and propagates keyboard state throughout the application using reactive patterns and StateFlow.

## Introduction

This document is part of the comprehensive FlorisBoard documentation. It covers Keyboard State Management in detail.

## Key Concepts

The core of FlorisBoard's keyboard state management revolves around the `KeyboardState` class and its observable counterpart, `ObservableKeyboardState`.

*   **`KeyboardState` Class**: This fundamental class is responsible for managing the various aspects of the text input logic that directly influence how the keyboard is rendered and laid out. It acts as a single source of truth for the keyboard's current operational status.

*   **`rawValue` (ULong)**: At the heart of `KeyboardState` is a `ULong` (unsigned 64-bit integer) named `rawValue`. This single, compact value is used to efficiently store a multitude of keyboard-related flags and small integer regions. This approach minimizes memory footprint and allows for quick state checks.

*   **Bitmasking**: To pack diverse information into a single `ULong`, `KeyboardState` heavily utilizes bitmasking. Each specific piece of state (e.g., whether shift is active, the current keyboard mode) is assigned a particular bit or a small range of bits within the `rawValue`. Constants like `M_KEYBOARD_MODE`, `O_KEYBOARD_MODE`, `F_IS_SELECTION_MODE`, etc., are defined to provide the necessary masks and offsets for accessing and modifying these individual state components.

*   **Flags and Regions**:
    *   **Flags (prefixed with `F_`)**: These represent boolean states, indicating the presence or absence of a particular condition. Examples include `isSelectionMode` (is text currently selected?) or `isIncognitoMode` (is the keyboard in incognito mode?).
    *   **Regions (prefixed with `M_` for mask and `O_` for offset)**: These store small integer values, typically representing enumerated types or other limited-range data. Examples include `keyboardMode` (e.g., QWERTY, symbols), `keyVariation` (e.g., normal, shifted), `inputShiftState` (e.g., unshifted, shifted, caps lock), and `imeUiMode` (e.g., normal, one-handed).

*   **`ObservableKeyboardState`**: This class extends `KeyboardState`, adding the crucial capability of observability. It leverages Kotlin Coroutines' `MutableStateFlow` to allow other parts of the application to react to changes in the keyboard's state.

*   **`MutableStateFlow`**: A part of Kotlin Coroutines' Flow API, `MutableStateFlow` is used within `ObservableKeyboardState` to emit updates whenever the keyboard's state changes. This enables a reactive programming paradigm where UI components or other logic can collect these state changes and update themselves accordingly, ensuring the keyboard's appearance and behavior are always synchronized with its internal state.

## Implementation Details

### `KeyboardState`

*   **Efficient State Storage**: The `KeyboardState` class stores its entire state within a single `ULong` variable named `rawValue`. This design choice prioritizes memory efficiency and fast state manipulation.

*   **Helper Methods for Bit Manipulation**: To manage the `rawValue`, `KeyboardState` provides a set of private helper methods:
    *   `getFlag(f: ULong)`: Checks if a specific flag (bit) is set within `rawValue`.
    *   `setFlag(f: ULong, v: Boolean)`: Sets or clears a specific flag (bit) in `rawValue` based on the boolean value `v`.
    *   `getRegion(m: ULong, o: Int)`: Extracts an integer value from a defined bit region within `rawValue`, using a mask `m` and an offset `o`.
    *   `setRegion(m: ULong, o: Int, v: Int)`: Sets an integer value `v` into a defined bit region within `rawValue`.

*   **Convenience Properties**: `KeyboardState` exposes various public properties (e.g., `keyVariation`, `keyboardMode`, `isSelectionMode`). These properties act as convenient getters and setters that internally use the bit manipulation helper methods to read from and write to the `rawValue`. This abstraction simplifies state access for other parts of the application.

*   **`snapshot()`**: This method creates a new `KeyboardState` instance with the current `rawValue`, effectively providing an immutable snapshot of the state at a given moment.

### `ObservableKeyboardState`

*   **Observability with `Delegates.observable`**: `ObservableKeyboardState` extends `KeyboardState` and introduces observability. It uses Kotlin's `Delegates.observable` property delegate on its `rawValue`. This means that whenever `rawValue` is modified, a specified lambda function is executed, which in turn triggers the state dispatch mechanism.

*   **`dispatchFlow`**: An instance of `MutableStateFlow<KeyboardState>` named `dispatchFlow` is central to the observability. This `StateFlow` is updated with a new `KeyboardState` snapshot whenever the `rawValue` changes and no batch edit is active.

*   **Batch Editing Mechanism**: To handle scenarios where multiple state changes occur in quick succession (e.g., during a complex user interaction), `ObservableKeyboardState` implements a batch editing mechanism:
    *   `batchEditCount`: An `AtomicInteger` tracks the number of active batch edits. This ensures thread-safe management of concurrent batch operations.
    *   `beginBatchEdit()`: Increments `batchEditCount`. While `batchEditCount` is greater than zero, state changes to `rawValue` will *not* immediately trigger a dispatch to `dispatchFlow`.
    *   `endBatchEdit()`: Decrements `batchEditCount`. If `batchEditCount` returns to zero, it means all active batch edits have concluded, and the current state is then dispatched to `dispatchFlow`.
    *   `batchEdit(block: (ObservableKeyboardState) -> Unit)`: An inline function that provides a convenient and safe way to perform a series of state modifications within a batch. It automatically calls `beginBatchEdit()` before executing the provided `block` and `endBatchEdit()` (in a `finally` block) afterward, ensuring proper state dispatch even if exceptions occur within the `block`.

*   **`dispatchState()`**: This private method is responsible for checking `batchEditCount`. If it's `BATCH_ZERO` (meaning no active batch edits), it updates the `dispatchFlow` with a new snapshot of the current `KeyboardState`.

## Code Examples

Here are some illustrative code snippets from the FlorisBoard codebase demonstrating the concepts discussed:

### Bitmasking Constants and Helper Methods

```kotlin
open class KeyboardState protected constructor(open var rawValue: ULong) {
    companion object {
        const val M_KEYBOARD_MODE: ULong =                  0x0Fu
        const val O_KEYBOARD_MODE: Int =                    0
        const val M_KEY_VARIATION: ULong =                  0x0Fu
        const val O_KEY_VARIATION: Int =                    4
        // ... other masks and offsets

        const val F_IS_SELECTION_MODE: ULong =              0x00000400u
        // ... other flags

        fun new(value: ULong = STATE_ALL_ZERO) = KeyboardState(value)
    }

    private fun getFlag(f: ULong): Boolean {
        return (rawValue and f) != STATE_ALL_ZERO
    }

    private fun setFlag(f: ULong, v: Boolean) {
        rawValue = if (v) { rawValue or f } else { rawValue and f.inv() }
    }

    private fun getRegion(m: ULong, o: Int): Int {
        return ((rawValue shr o) and m).toInt()
    }

    private fun setRegion(m: ULong, o: Int, v: Int) {
        rawValue = (rawValue and (m shl o).inv()) or ((v.toULong() and m) shl o)
    }
}
```

### Property Usage

```kotlin
// Example of a property using the bit manipulation helpers
var keyVariation: KeyVariation
    get() = KeyVariation.fromInt(getRegion(M_KEY_VARIATION, O_KEY_VARIATION))
    set(v) { setRegion(M_KEY_VARIATION, O_KEY_VARIATION, v.toInt()) }

// Example of a boolean flag property
var isSelectionMode: Boolean
    get() = getFlag(F_IS_SELECTION_MODE)
    set(v) { setFlag(F_IS_SELECTION_MODE, v) }
```

### Batch Editing with `ObservableKeyboardState`

```kotlin
class ObservableKeyboardState private constructor(
    initValue: ULong,
    private val dispatchFlow: MutableStateFlow<KeyboardState> = MutableStateFlow(KeyboardState.new(initValue)),
) : KeyboardState(initValue), StateFlow<KeyboardState> by dispatchFlow {

    // ... (other code)

    /**
     * Performs a batch edit by executing the modifier [block]. Any exception that [block] throws will be caught and
     * re-thrown after correctly ending the batch edit.
     */
    inline fun batchEdit(block: (ObservableKeyboardState) -> Unit) {
        contract {
            callsInPlace(block, InvocationKind.EXACTLY_ONCE)
        }
        beginBatchEdit()
        try {
            block(this)
        } catch (e: Throwable) {
            throw e
        } finally {
            endBatchEdit()
        }
    }
}

// Example usage of batchEdit:
// Assuming 'observableKeyboardState' is an instance of ObservableKeyboardState
/*
observableKeyboardState.batchEdit {
    it.isSelectionMode = true
    it.keyboardMode = KeyboardMode.SYMBOLS
    // Multiple changes are applied, but observers are notified only once at the end
}
*/
```

## Best Practices

To effectively utilize FlorisBoard's keyboard state management system, consider the following best practices:

*   **Utilize `batchEdit` for Multiple Changes**: When making several modifications to the `ObservableKeyboardState` in a short period, always wrap these changes within a `batchEdit` block. This practice is crucial for performance optimization, as it prevents unnecessary intermediate state dispatches and ensures that observers are notified only once after all changes have been applied. It also guarantees atomicity for a set of related state updates.

*   **Access State via Properties**: Always interact with the keyboard state through the provided high-level properties (e.g., `keyboardMode`, `isSelectionMode`) rather than directly manipulating the `rawValue`. These properties encapsulate the bitwise logic, making the code more readable, maintainable, and less prone to errors.

*   **Observe `StateFlow` for Reactions**: For any UI component or logic that needs to react to changes in the keyboard's state, observe the `StateFlow` exposed by `ObservableKeyboardState`. This reactive approach ensures that your components automatically update when the underlying state changes, promoting a clean and responsive architecture.

*   **Create Snapshots When Immutability is Required**: If you need to pass the keyboard state to a function or component that requires an immutable representation, use the `snapshot()` method. This creates a new `KeyboardState` instance, preventing unintended modifications to the active state.

*   **Understand Bitmasking (for advanced use)**: While the properties abstract away most of the bitmasking complexity, having a basic understanding of how `rawValue` is structured and how flags/regions are defined can be beneficial for debugging or when extending the `KeyboardState` with new properties.

## Common Patterns

FlorisBoard's state management system facilitates several common patterns in keyboard development:

*   **Centralized Keyboard State**: The `KeyboardState` and `ObservableKeyboardState` classes provide a single, centralized location for all keyboard-related operational states. This simplifies state management and ensures consistency across different parts of the keyboard.

*   **Reactive UI Updates**: By exposing the keyboard state as a `StateFlow`, FlorisBoard enables a reactive UI architecture. UI components (e.g., Compose UI elements) can collect from this `StateFlow` and automatically recompose or update themselves whenever the keyboard state changes, leading to a highly responsive user interface.

*   **Efficient State Storage and Retrieval**: The use of a `ULong` with bitmasking for `rawValue` is a pattern for highly efficient storage of multiple boolean flags and small integer values. This is particularly important in performance-critical applications like a keyboard, where every bit and CPU cycle counts.

*   **Atomic State Updates**: The `batchEdit` mechanism allows for multiple state changes to be applied atomically. This is a common pattern in reactive systems to prevent intermediate, inconsistent states from being observed by subscribers and to optimize performance by reducing the number of state emissions.

*   **Decoupling Logic and UI**: The clear separation between the `KeyboardState` (data and logic) and its observation mechanism (via `StateFlow`) promotes a clean architecture where the keyboard's core logic is decoupled from its UI representation. This makes the codebase easier to understand, test, and maintain.

## Troubleshooting

When working with FlorisBoard's keyboard state management, you might encounter some common issues. Here's how to troubleshoot them:

*   **State Changes Not Propagating to Observers**: If you're modifying the `ObservableKeyboardState` but your observers (e.g., UI components) are not reacting to the changes, consider the following:
    *   **Missing `endBatchEdit()`**: Ensure that every `beginBatchEdit()` call has a corresponding `endBatchEdit()`. If `endBatchEdit()` is not called, the `batchEditCount` will remain elevated, preventing state dispatches.
    *   **Not Using `batchEdit` for Multiple Changes**: If you're making multiple changes outside a `batchEdit` block, and only the last change seems to be observed, it's likely due to the rapid succession of updates. Use `batchEdit` to group these changes.
    *   **Direct `rawValue` Manipulation (Avoid)**: Directly modifying `rawValue` in `ObservableKeyboardState` without going through the properties or `batchEdit` will bypass the observability mechanism. Always use the provided properties or the `batchEdit` function.

*   **Incorrect State Values**: If the keyboard state properties (e.g., `keyboardMode`, `isSelectionMode`) are returning unexpected values:
    *   **Bitmasking Errors**: For custom state properties or when debugging, verify that the bitmasks (`M_`, `F_`) and offsets (`O_`) are correctly defined and applied. An incorrect mask or offset can lead to reading or writing to the wrong bits within `rawValue`.
    *   **Race Conditions**: Although `batchEditCount` uses `AtomicInteger` for thread safety, complex multi-threaded scenarios could still lead to unexpected state. Ensure state modifications are properly synchronized if they occur across different threads.

*   **Performance Issues with State Updates**: If the keyboard feels sluggish or experiences UI jank during state transitions:
    *   **Overuse of `StateFlow` Updates**: While `StateFlow` is efficient, frequent, unnecessary updates can still impact performance. Ensure that state changes are only triggered when truly necessary.
    *   **Complex Calculations in Observers**: Avoid performing heavy computations directly within your `StateFlow` observers. Delegate complex logic to background threads or use derived states that are computed efficiently.

*   **Debugging `KeyboardState`**: The `toString()` method of `KeyboardState` provides a hexadecimal representation of the `rawValue`. This can be useful for debugging to see the raw bit pattern and verify if flags and regions are set as expected.

## Related Topics

Understanding FlorisBoard's keyboard state management can be enhanced by exploring these related topics:

*   **Kotlin Coroutines and Flow**: A deep understanding of Kotlin Coroutines and, specifically, the `StateFlow` and `SharedFlow` APIs, is essential. These are the foundational technologies for reactive programming in FlorisBoard.

*   **Android Jetpack Compose**: As FlorisBoard heavily utilizes Jetpack Compose for its UI, understanding how Compose observes `StateFlow`s and recomposes UI elements based on state changes is crucial for building responsive keyboard UIs.

*   **Bitwise Operations in Kotlin/Java**: The efficient packing of state into a `ULong` relies on bitwise operations (AND, OR, XOR, shifts). Familiarity with these operations will provide a deeper insight into how `KeyboardState` manages its internal `rawValue`.

*   **State Management Patterns (General)**: Concepts from general state management patterns (e.g., Redux, MVI, MVVM) can provide a broader context for why certain architectural decisions were made in FlorisBoard's state management design.

*   **Input Method Editors (IMEs) on Android**: Understanding the Android IME framework and its lifecycle will help in comprehending how the `KeyboardState` interacts with the broader Android system and input events.

## Next Steps

To further your understanding of keyboard state management in FlorisBoard, consider the following next steps:

*   **Explore `KeyboardManager.kt`**: Investigate `KeyboardManager.kt` to see how `ObservableKeyboardState` is instantiated, managed, and how its state changes are observed and acted upon by the core keyboard logic.

*   **Analyze UI Components**: Examine various UI components within the `ime/keyboard` or `ime/text` packages (e.g., key views, smartbar components) to understand how they collect from the `KeyboardState`'s `StateFlow` and update their appearance based on the current state.

*   **Implement a Custom State Flag/Region**: As an exercise, try to add a new custom state flag or a small integer region to `KeyboardState` and `ObservableKeyboardState`. Then, create a property to access it and demonstrate how to modify and observe its changes.

*   **Review Input Event Handling**: Understand how user input events (key presses, gestures) are processed and how they lead to modifications in the `KeyboardState`.

*   **Contribute to Documentation**: If you find areas that could be explained more clearly or have additional insights, consider contributing to this documentation!

---

**Note**: This documentation is continuously being improved. Contributions are welcome!
