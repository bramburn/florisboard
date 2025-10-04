---
sidebar_position: 2
title: InputConnection
---

# InputConnection

## Purpose and Data Flow

`InputConnection` is the primary interface through which an Input Method Editor (IME) communicates with the application's text input field. It allows the IME to send text, delete characters, retrieve surrounding text, and perform various other text manipulation operations. FlorisBoard heavily relies on `InputConnection` to provide a seamless typing experience.

**Data Flow:**

1.  **IME Request:** FlorisBoard, via its `InputMethodService`, requests an `InputConnection` from the currently focused application's text input field.
2.  **Application Provides:** The application provides an `InputConnection` instance to the IME.
3.  **IME Sends Input:** FlorisBoard uses methods like `commitText()`, `deleteSurroundingText()`, `sendKeyEvent()`, etc., on the `InputConnection` object to send user input or perform text modifications.
4.  **Application Processes:** The application receives these calls and updates its text field accordingly.
5.  **IME Queries State:** FlorisBoard can also query the `InputConnection` for information about the text field's current state, such as the cursor position, selected text, or surrounding text, using methods like `getTextBeforeCursor()`, `getTextAfterCursor()`, `getSelectedText()`, etc.

## Calling Scripts/Files

`InputConnection` is primarily used within the `FlorisImeService` and `AbstractEditorInstance` classes in FlorisBoard.

*   **`dev/patrickgold/florisboard/FlorisImeService.kt`**: This is where the `InputConnection` is obtained and where basic text input operations are initiated.
*   **`dev/patrickgold/florisboard/ime/editor/AbstractEditorInstance.kt`**: This class acts as an abstraction layer over `InputConnection`, providing a more convenient and robust way for FlorisBoard's internal logic to interact with the text field. Most text manipulation logic in FlorisBoard goes through this abstraction.

## Usage Examples

Here's a simplified example of how `InputConnection` is used in FlorisBoard:

```kotlin
// From FlorisImeService.kt
override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
    // ... logic to determine if key should be handled by IME ...
    currentInputConnection.sendKeyEvent(event) // Send key event to the app
    return true
}

override fun onKeyChar(primaryCode: Int, keyCodes: IntArray?): Boolean {
    // ... logic to determine character to commit ...
    currentInputConnection.commitText(primaryCode.toChar().toString(), 1) // Commit text to the app
    return true
}

// From AbstractEditorInstance.kt (simplified)
class AbstractEditorInstance(private val inputConnection: InputConnection) {

    fun commitText(text: CharSequence) {
        inputConnection.commitText(text, 1)
    }

    fun deleteSurroundingText(beforeLength: Int, afterLength: Int) {
        inputConnection.deleteSurroundingText(beforeLength, afterLength)
    }

    fun getTextBeforeCursor(n: Int, flags: Int): CharSequence? {
        return inputConnection.getTextBeforeCursor(n, flags)
    }

    // ... other methods wrapping InputConnection calls ...
}
```

## Android API Documentation

For more detailed information, refer to the official Android Developers documentation for `InputConnection`:

*   [InputConnection | Android Developers](https://developer.android.com/reference/android/view/inputmethod/InputConnection)

## Criticality Assessment

`InputConnection` is **highly critical** to FlorisBoard. It is the fundamental communication channel between the keyboard and the application's text field. Without a functioning `InputConnection`, FlorisBoard would be unable to insert any text, delete characters, or interact with the user's input area, rendering it unusable as an IME. All text-related features, such as word suggestions, auto-correction, and clipboard integration, ultimately rely on `InputConnection` to apply changes to the text field.
