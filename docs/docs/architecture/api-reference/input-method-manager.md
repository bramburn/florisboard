---
sidebar_position: 6
title: InputMethodManager
---

# InputMethodManager

## Purpose and Data Flow

`InputMethodManager` is a system service that manages the overall interaction with input methods. It allows applications to interact with the currently active input method, and it allows input methods to interact with the system. FlorisBoard uses `InputMethodManager` to enable itself as an input method, switch between input methods, and control the visibility of the soft keyboard.

**Data Flow:**

1.  **Application Request:** An application requests focus for a text input field.
2.  **System Notification:** The Android system notifies the `InputMethodManager` about the focused input field.
3.  **IME Activation:** If FlorisBoard is the currently selected IME, `InputMethodManager` activates it, leading to calls like `onStartInput()` in `InputMethodService`.
4.  **IME Control:** FlorisBoard can use `InputMethodManager` to perform actions like:
    *   `showSoftInput()` / `hideSoftInput()`: Control keyboard visibility.
    *   `switchToNextInputMethod()`: Switch to the next available IME.
    *   `setInputMethod()`: Programmatically select an IME.
    *   `getCurrentInputMethodSubtype()`: Get information about the current input method subtype.

## Calling Scripts/Files

`InputMethodManager` is primarily used in the following files:

*   **`dev/patrickgold/florisboard/FlorisImeService.kt`**: The core IME service uses `InputMethodManager` to manage its lifecycle and interaction with the system.
*   **`dev/patrickgold/florisboard/lib/util/InputMethodUtils.kt`**: This utility class provides helper functions for interacting with `InputMethodManager`, such as checking if FlorisBoard is enabled or setting it as the default IME.
*   **`dev/patrickgold/florisboard/app/setup/SetupScreen.kt`**: Used during the initial setup process to guide the user through enabling FlorisBoard as an input method.

## Usage Examples

Here's a simplified example of how `InputMethodManager` is used in FlorisBoard:

```kotlin
// From FlorisImeService.kt (simplified)
private lateinit var imm: InputMethodManager

override fun onCreate() {
    super.onCreate()
    imm = getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
}

// Example: Showing the soft input keyboard
fun showKeyboard() {
    imm.showSoftInput(currentInputEditorInfo.inputConnection, 0)
}

// Example: Switching to the next input method
fun switchToNextKeyboard() {
    imm.switchToNextInputMethod(false)
}

// From InputMethodUtils.kt (simplified)
fun isFlorisboardEnabled(context: Context): Boolean {
    val imm = context.getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
    val enabledInputMethodIds = imm.enabledInputMethodList.map { it.id }
    return enabledInputMethodIds.contains(context.packageName)
}

fun showImePicker(context: Context) {
    val imm = context.getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
    imm.showInputMethodPicker()
}
```

## Android API Documentation

For more detailed information, refer to the official Android Developers documentation for `InputMethodManager`:

*   [InputMethodManager | Android Developers](https://developer.android.com/reference/android/view/inputmethod/InputMethodManager)

## Criticality Assessment

`InputMethodManager` is **highly critical** to FlorisBoard. It is the central system service responsible for managing all input methods on the device. FlorisBoard relies on `InputMethodManager` to be recognized as an IME, to be activated when a text field is focused, and to control its own visibility. Without proper interaction with `InputMethodManager`, FlorisBoard would not be able to function as an input method at all. It is a foundational component for any IME.
