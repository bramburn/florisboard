---
sidebar_position: 3
title: KeyEvent
---

# KeyEvent

## Purpose and Data Flow

`KeyEvent` represents a key press or release event from a hardware keyboard or a software keyboard. In FlorisBoard's context, `KeyEvent` objects are primarily generated internally by the IME based on user interaction with the soft keyboard UI, and then sent to the target application via `InputConnection`. They are crucial for simulating hardware keyboard input and handling special key actions.

**Data Flow:**

1.  **User Interaction:** When a user taps a key on the FlorisBoard UI, an internal event is generated.
2.  **IME Generates `KeyEvent`:** FlorisBoard's internal logic (e.g., `KeyboardManager`) translates this internal event into a `KeyEvent` object, specifying the key code, meta states (shift, alt, etc.), and action (down or up).
3.  **`InputMethodService` Sends `KeyEvent`:** The `FlorisImeService` then sends this `KeyEvent` to the currently focused application's text input field using the `InputConnection.sendKeyEvent()` method.
4.  **Application Processes:** The application receives and processes the `KeyEvent` as if it originated from a physical keyboard.

## Calling Scripts/Files

`KeyEvent` objects are primarily generated and handled within the `FlorisImeService`, `AbstractEditorInstance`, and `KeyboardManager` classes.

*   **`dev/patrickgold/florisboard/FlorisImeService.kt`**: This is where `KeyEvent` objects are sent to the application via `InputConnection`.
*   **`dev/patrickgold/florisboard/ime/editor/AbstractEditorInstance.kt`**: This class might encapsulate logic for creating and sending `KeyEvent`s for specific text manipulation tasks.
*   **`dev/patrickgold/florisboard/ime/keyboard/KeyboardManager.kt`**: This class is responsible for managing the keyboard state and translating user touches into appropriate `KeyEvent`s or character inputs.

## Usage Examples

Here's a simplified example of how `KeyEvent` is used in FlorisBoard (from `FlorisImeService.kt`):

```kotlin
// From FlorisImeService.kt
override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
    // Handle special key codes like backspace, enter, etc.
    when (keyCode) {
        KeyEvent.KEYCODE_DEL -> {
            // Simulate backspace key press
            currentInputConnection.sendKeyEvent(KeyEvent(KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_DEL))
            currentInputConnection.sendKeyEvent(KeyEvent(KeyEvent.ACTION_UP, KeyEvent.KEYCODE_DEL))
            return true
        }
        KeyEvent.KEYCODE_ENTER -> {
            // Simulate enter key press
            currentInputConnection.sendKeyEvent(KeyEvent(KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_ENTER))
            currentInputConnection.sendKeyEvent(KeyEvent(KeyEvent.ACTION_UP, KeyEvent.KEYCODE_ENTER))
            return true
        }
        // ... other key handling ...
    }
    return super.onKeyDown(keyCode, event)
}

// Example of creating a KeyEvent (simplified, actual logic is more complex)
fun createAndSendKeyEvent(keyCode: Int, isShiftPressed: Boolean) {
    val metaState = if (isShiftPressed) KeyEvent.META_SHIFT_ON else 0
    val eventDown = KeyEvent(0, 0, KeyEvent.ACTION_DOWN, keyCode, 0, metaState)
    val eventUp = KeyEvent(0, 0, KeyEvent.ACTION_UP, keyCode, 0, metaState)
    currentInputConnection.sendKeyEvent(eventDown)
    currentInputConnection.sendKeyEvent(eventUp)
}
```

## Android API Documentation

For more detailed information, refer to the official Android Developers documentation for `KeyEvent`:

*   [KeyEvent | Android Developers](https://developer.android.com/reference/android/view/KeyEvent)

## Criticality Assessment

`KeyEvent` is **highly critical** to FlorisBoard. It is the primary mechanism for delivering simulated key presses to applications, enabling the core functionality of a keyboard. While direct character input can be handled via `InputConnection.commitText()`, `KeyEvent` is essential for handling special keys (like backspace, enter, arrow keys), modifier keys (shift, alt, ctrl), and for ensuring compatibility with applications that expect `KeyEvent`s for certain actions. Without proper `KeyEvent` handling, FlorisBoard's input capabilities would be severely limited.
