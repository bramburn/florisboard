# Touch Handling & Gestures

## Overview

FlorisBoard implements sophisticated touch handling and gesture recognition, including multi-touch support, swipe gestures, glide typing, and customizable gesture actions.

## Introduction

Touch handling is critical for keyboard responsiveness and user experience. FlorisBoard's gesture system provides:

- **Multi-Touch Support**: Handle multiple simultaneous touches
- **Swipe Gestures**: Directional swipes with configurable actions
- **Glide Typing**: Continuous gesture typing across keys
- **Long Press**: Access popup keys and alternative characters
- **Pointer Tracking**: Precise tracking of touch points across keys
- **Gesture Customization**: User-configurable swipe actions

## Key Concepts

### Pointer Management

FlorisBoard uses a `PointerMap` to track multiple simultaneous touch points. Each pointer tracks ID, index, position, active key, and state.

### Swipe Gesture Detection

The `SwipeGesture.Detector` recognizes directional swipes using velocity tracking and distance thresholds.

### Swipe Directions

Eight directional swipes are supported: UP, DOWN, LEFT, RIGHT, and diagonal combinations (UP_LEFT, UP_RIGHT, DOWN_LEFT, DOWN_RIGHT).

### Swipe Actions

Configurable actions triggered by gestures include:
- Cursor movement
- Text deletion
- Keyboard mode switching
- Language switching
- Undo/Redo
- Hide keyboard
- And many more

### Glide Typing

Continuous gesture typing across multiple keys using a statistical classifier to predict words from gesture paths.

## Implementation Details

### Touch Event Flow

```
MotionEvent → TextKeyboardLayout → Controller
    ↓
Swipe Detector ← Check if swipe
    ↓
Glide Detector ← Check if glide typing
    ↓
Pointer Map ← Track individual touches
    ↓
Key Press/Release → Input Processing
```

### Gesture Configuration

Users can configure:
- Swipe distance threshold (default: 32dp)
- Swipe velocity threshold (default: 1900 dp/s)
- Actions for each swipe direction
- Space bar swipe actions
- Delete key gestures

## Code Examples

### Implementing a Custom Gesture Listener

```kotlin
class CustomGestureListener : SwipeGesture.Listener {
    override fun onSwipe(event: SwipeGesture.Event): Boolean {
        return when (event.direction) {
            SwipeGesture.Direction.UP -> {
                keyboardManager.activeState.inputShiftState = InputShiftState.CAPS_LOCK
                true
            }
            SwipeGesture.Direction.DOWN -> {
                keyboardManager.requestHideSelf()
                true
            }
            else -> false
        }
    }
}
```

### Processing Swipe Actions

```kotlin
fun processSwipeAction(action: SwipeAction) {
    when (action) {
        SwipeAction.DELETE_WORD -> editorInstance.deleteWordBeforeCursor()
        SwipeAction.MOVE_CURSOR_LEFT -> editorInstance.sendDownUpKeyEvent(KeyEvent.KEYCODE_DPAD_LEFT)
        SwipeAction.SWITCH_TO_NEXT_SUBTYPE -> subtypeManager.switchToNextSubtype()
        SwipeAction.HIDE_KEYBOARD -> keyboardManager.requestHideSelf()
        SwipeAction.UNDO -> editorInstance.performUndo()
        else -> { /* Handle other actions */ }
    }
}
```

## Best Practices

### 1. Respect Gesture Thresholds

Always check user-configured thresholds before triggering gesture actions.

### 2. Handle Multi-Touch Properly

Track pointer IDs correctly and handle ACTION_POINTER_DOWN/UP events.

### 3. Provide Visual Feedback

Show visual indication of key presses and gesture trails for better user experience.

### 4. Optimize Touch Performance

Use hardware acceleration and minimize allocations in touch handlers.

### 5. Handle Edge Cases

Validate events, handle out-of-bounds touches, and manage rapid touch sequences.

## Common Patterns

### Space Bar Cursor Movement

Swipe left/right on space bar to move cursor character by character.

### Delete Key Gestures

Swipe left on delete key for precise character deletion, or long press for word deletion.

### Long Press Detection

Detect long presses with configurable delay (typically 500ms) for accessing popup keys.

## Troubleshooting

### Gestures Not Detected

**Solutions**:
- Check gesture thresholds in settings
- Verify swipe distance and velocity meet thresholds
- Ensure gestures are enabled
- Verify gesture detector is initialized

### Glide Typing Not Working

**Solutions**:
- Ensure glide typing is enabled in preferences
- Check keyboard mode is CHARACTERS
- Verify layout is set in glide classifier
- Ensure not in password field

### Touch Lag or Stuttering

**Solutions**:
- Enable hardware acceleration
- Reduce allocations in touch handlers
- Optimize rendering pipeline
- Profile touch event processing

## Related Topics

- [Input Processing Pipeline](./input-pipeline.md) - How touch becomes text
- [Custom UI Components](./custom-ui.md) - Rendering keyboard UI
- [Performance Optimizations](../architecture/performance.md) - Touch latency reduction
- [Accessibility Features](./accessibility.md) - Touch accessibility

## Next Steps

- Configure gesture settings in FlorisBoard preferences
- Learn about glide typing setup and customization
- Explore custom gesture action configuration
- Review touch performance optimization techniques

---

**Note**: This documentation is continuously being improved. Contributions are welcome!
