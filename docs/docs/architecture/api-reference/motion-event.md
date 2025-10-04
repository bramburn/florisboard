---
sidebar_position: 4
title: MotionEvent
---

# MotionEvent

## Purpose and Data Flow

`MotionEvent` represents a stream of touch events (or other pointer events) that describe movements on the screen. In FlorisBoard, `MotionEvent` is fundamental for capturing user interactions with the soft keyboard UI, enabling features like key presses, swipes, and glide typing. It provides detailed information about each pointer, including its position, pressure, size, and historical data.

**Data Flow:**

1.  **User Touch:** When a user touches the FlorisBoard UI, the Android system dispatches `MotionEvent` objects to the IME's view hierarchy.
2.  **View Receives `MotionEvent`:** The `TextKeyboardLayout` (or other relevant UI components) receives these `MotionEvent`s.
3.  **IME Processes `MotionEvent`:** FlorisBoard's input handling logic (e.g., `InputEventDispatcher`, `GlideTypingGesture`, `SwipeGesture`) processes the `MotionEvent` stream to detect gestures, determine key presses, and track pointer movements.
4.  **Internal State Update:** Based on the `MotionEvent` data, FlorisBoard updates its internal state (e.g., which key is pressed, current glide path).
5.  **Input Generation:** The processed `MotionEvent` data is then used to generate `KeyEvent`s or `commitText()` calls via `InputConnection` to send input to the target application.

## Calling Scripts/Files

`MotionEvent` is extensively used in FlorisBoard's UI and input handling components.

*   **`dev/patrickgold/florisboard/ime/text/keyboard/TextKeyboardLayout.kt`**: This is a core UI component that handles touch events for the main keyboard layout.
*   **`dev/patrickgold/florisboard/ime/text/gestures/GlideTypingGesture.kt`**: This class specifically processes `MotionEvent` streams to detect and interpret glide typing gestures.
*   **`dev/patrickgold/florisboard/ime/text/gestures/SwipeGesture.kt`**: Handles `MotionEvent`s to detect swipe gestures for various actions.
*   **`dev/patrickgold/florisboard/ime/input/InputEventDispatcher.kt`**: Dispatches raw `MotionEvent`s to appropriate handlers within the IME.

## Usage Examples

Here's a simplified example of how `MotionEvent` is handled in FlorisBoard (from `TextKeyboardLayout.kt`):

```kotlin
// From TextKeyboardLayout.kt (simplified)
override fun onTouchEvent(event: MotionEvent?): Boolean {
    event?.let {
        when (it.actionMasked) {
            MotionEvent.ACTION_DOWN, MotionEvent.ACTION_POINTER_DOWN -> {
                // Handle initial touch or new pointer down
                val pointerIndex = it.actionIndex
                val x = it.getX(pointerIndex)
                val y = it.getY(pointerIndex)
                // Logic to determine which key was pressed
                // ...
            }
            MotionEvent.ACTION_MOVE -> {
                // Handle pointer movement
                for (i in 0 until it.pointerCount) {
                    val x = it.getX(i)
                    val y = it.getY(i)
                    // Logic for glide typing or tracking movement
                    // ...
                }
            }
            MotionEvent.ACTION_UP, MotionEvent.ACTION_POINTER_UP -> {
                // Handle pointer lift-off
                val pointerIndex = it.actionIndex
                val x = it.getX(pointerIndex)
                val y = it.getY(pointerIndex)
                // Logic for releasing a key or completing a gesture
                // ...
            }
            MotionEvent.ACTION_CANCEL -> {
                // Handle touch cancellation
                // ...
            }
        }
        // Pass MotionEvent to gesture detectors if applicable
        glideTypingGesture.onTouchEvent(it)
        swipeGesture.onTouchEvent(it)
        return true
    }
    return super.onTouchEvent(event)
}
```

## Android API Documentation

For more detailed information, refer to the official Android Developers documentation for `MotionEvent`:

*   [MotionEvent | Android Developers](https://developer.android.com/reference/android/view/MotionEvent)

## Criticality Assessment

`MotionEvent` is **highly critical** to FlorisBoard. As a soft keyboard, its primary mode of interaction is touch-based. `MotionEvent` provides the raw data for all user interactions with the keyboard UI, including basic key presses, multi-touch gestures, and advanced input methods like glide typing. Without robust `MotionEvent` handling, FlorisBoard would be unable to receive or interpret user input, making it completely non-functional. It forms the foundation of the user interaction layer.
