# Input Method Editor (IME) Fundamentals

An Input Method Editor (IME), commonly known as a virtual keyboard, is a crucial component of the Android operating system. It allows users to input text into any application. FlorisBoard is an advanced example of an IME, leveraging various Android APIs and best practices.

## What is an IME?

At its core, an IME is a service that provides a user interface for text input. When a user taps on a text input field (like in a messaging app or a browser), the Android system displays the currently selected IME. This IME then captures user input (e.g., key presses, gestures, voice input) and sends the resulting text to the application.

## Android IME Architecture

The Android framework provides a robust architecture for IMEs, primarily centered around the `InputMethodService` class. Here are the key components and their interactions:

### 1. `InputMethodService`

This is the central class for any IME. Your custom keyboard will extend this service. It manages the lifecycle of the input method, handles user input events, and communicates with the application where text is being entered.

Key responsibilities of `InputMethodService`:

*   **Lifecycle Management:** `onCreate()`, `onInitializeInterface()`, `onStartInput()`, `onFinishInput()`, `onDestroy()`.
*   **UI Management:** Creating and managing the keyboard UI (e.g., `onCreateInputView()`, `onStartInputView()`).
*   **Input Handling:** Receiving key events (`onKeyDown()`, `onKeyUp()`) and touch events.
*   **Communication with Application:** Sending text to the current input field via `InputConnection`.

### 2. `InputConnection`

`InputConnection` is the communication channel between the IME and the application's text input field (e.g., `EditText`). The IME uses this interface to perform operations on the text in the application, such as:

*   **Sending Text:** `commitText()`, `setComposingText()`.
*   **Deleting Text:** `deleteSurroundingText()`, `deleteSurroundingTextInCodePoints()`.
*   **Retrieving Text:** `getTextBeforeCursor()`, `getTextAfterCursor()`, `getExtractedText()`.
*   **Managing Selection:** `setSelection()`.

### 3. `KeyboardView` (Deprecated, but conceptual)

Historically, `KeyboardView` was a common way to render a keyboard. While modern IMEs like FlorisBoard often use more flexible UI frameworks (like Jetpack Compose), the concept remains: a view that draws the keyboard layout and handles touch events.

### 4. `InputMethodManager`

This system service manages all IMEs installed on the device. Applications use `InputMethodManager` to interact with the IME (e.g., showing/hiding the keyboard). Users also interact with it through system settings to select their preferred keyboard.

## How FlorisBoard Utilizes the IME Architecture

FlorisBoard extends `InputMethodService` (specifically `FlorisImeService`) to manage its lifecycle and interact with the Android system. Instead of `KeyboardView`, FlorisBoard leverages **Jetpack Compose** to build its rich and dynamic user interface. This allows for a highly customizable and performant keyboard experience.

User input (key presses, gestures) are captured by the Compose UI, processed by FlorisBoard's internal logic, and then sent to the target application via the `InputConnection` interface. This modular approach separates the UI from the core input logic, making the keyboard more maintainable and extensible.

Understanding these fundamental components is crucial for anyone looking to develop or extend an Android IME.