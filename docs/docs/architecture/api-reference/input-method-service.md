---
sidebar_position: 1
title: InputMethodService
---

# InputMethodService

## Purpose and Data Flow

`InputMethodService` is the base class for implementing an Input Method Editor (IME), commonly known as a soft keyboard. It provides the fundamental framework for handling user input, managing the keyboard UI, and interacting with applications to insert text. FlorisBoard extends this class to provide its core functionality.

**Data Flow:**

1.  **User Input:** When a user interacts with the FlorisBoard UI (e.g., touches a key), `MotionEvent` and `KeyEvent` events are generated.
2.  **`InputMethodService` Processing:** FlorisBoard's `FlorisImeService` (which extends `InputMethodService`) intercepts and processes these events.
3.  **`InputConnection` Interaction:** Based on the processed input, `FlorisImeService` uses an `InputConnection` object to send text, delete characters, or perform other actions on the currently focused text field in the target application.
4.  **Application Feedback:** The application receives the input via its `InputConnection` and updates its UI accordingly.
5.  **IME UI Updates:** `FlorisImeService` also manages the keyboard's visual state, updating the UI based on user input, editor information (`EditorInfo`), and other factors.

## Calling Scripts/Files

The primary class that extends and implements `InputMethodService` in FlorisBoard is `FlorisImeService.kt`.

*   **`dev/patrickgold/florisboard/FlorisImeService.kt`**: This file contains the main logic for the IME, including lifecycle management, input handling, and UI rendering.
*   **`dev/patrickgold/florisboard/lib/compose/SystemUi.kt`**: This file might interact with `InputMethodService` to manage system UI visibility (e.g., status bar, navigation bar) in relation to the keyboard.

## Usage Examples

Here's a simplified example of how `InputMethodService` methods are typically overridden in FlorisBoard (from `FlorisImeService.kt`):

```kotlin
class FlorisImeService : InputMethodService() {

    override fun onCreate() {
        super.onCreate()
        // Initialize resources, managers, etc.
    }

    override fun onStartInput(attribute: EditorInfo?, restarting: Boolean) {
        super.onStartInput(attribute, restarting)
        // Called when a new input session starts or an existing one restarts.
        // Use 'attribute' to get information about the target text field.
    }

    override fun onFinishInput() {
        super.onFinishInput()
        // Called when the input session ends.
    }

    override fun onEvaluateInputViewShown(): Boolean {
        // Return true if the input view should be shown.
        return true
    }

    override fun onCreateInputView(): View {
        // Create and return the keyboard UI view.
        // In FlorisBoard, this would typically involve Compose UI.
        return ComposeInputView(this)
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        // Handle key down events.
        // Send key events to the InputConnection.
        currentInputConnection.sendKeyEvent(event)
        return true
    }

    override fun onKeyChar(primaryCode: Int, keyCodes: IntArray?): Boolean {
        // Handle character input.
        // currentInputConnection.commitText(primaryCode.toChar().toString(), 1)
        return true
    }

    override fun onUpdateSelection(oldSelStart: Int, oldSelEnd: Int, newSelStart: Int, newSelEnd: Int, candidatesStart: Int, candidatesEnd: Int) {
        super.onUpdateSelection(oldSelStart, oldSelEnd, newSelStart, newSelEnd, candidatesStart, candidatesEnd)
        // Called when the cursor position or selection changes.
    }

    // ... other overridden methods for touch events, gestures, etc.
}
```

## Android API Documentation

For more detailed information, refer to the official Android Developers documentation for `InputMethodService`:

*   [InputMethodService | Android Developers](https://developer.android.com/reference/android/inputmethodservice/InputMethodService)

## Criticality Assessment

`InputMethodService` is **highly critical** to FlorisBoard. It is the entry point and the core component that enables FlorisBoard to function as an IME. Without it, FlorisBoard would not be able to provide any input functionality. All other input-related APIs and UI components ultimately rely on the framework provided by `InputMethodService`.
