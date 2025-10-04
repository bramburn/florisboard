# Accessibility Features

## Overview

FlorisBoard is designed with accessibility in mind, providing features to support users with disabilities including screen reader support, haptic feedback, audio feedback, and customizable UI elements.

## Introduction

Accessibility is a core principle in FlorisBoard's design. This document covers the accessibility features implemented to ensure the keyboard is usable by everyone, including users who rely on assistive technologies like TalkBack, Switch Access, and other accessibility services.

## Key Concepts

### Screen Reader Support

FlorisBoard provides comprehensive support for Android's TalkBack screen reader through:

- **Content Descriptions**: All interactive elements have meaningful content descriptions
- **Semantic Markup**: Proper use of Compose semantics for accessibility
- **Announcement Support**: Important state changes are announced to screen readers
- **Navigation Support**: Logical focus order and navigation

### Haptic Feedback

Tactile feedback helps users confirm key presses without visual confirmation:

- **Key Press Feedback**: Vibration on key press
- **Long Press Feedback**: Different vibration pattern for long press
- **Gesture Feedback**: Haptic response for swipe gestures
- **Customizable Intensity**: Adjustable vibration strength

### Audio Feedback

Sound feedback provides auditory confirmation of actions:

- **Key Click Sounds**: Audio feedback on key press
- **System Sounds**: Integration with Android system sounds
- **Volume Control**: Adjustable sound volume
- **Sound Customization**: Different sounds for different key types

### Visual Accessibility

- **High Contrast Themes**: Support for high contrast color schemes
- **Customizable Font Sizes**: Adjustable text size for better readability
- **Color Customization**: Theme system allows custom colors
- **Clear Visual Feedback**: Visual indication of key presses and states

## Implementation Details

### Content Descriptions in Compose

FlorisBoard uses Jetpack Compose's semantic properties to provide accessibility information:

<augment_code_snippet path="lib/snygg/src/main/kotlin/org/florisboard/lib/snygg/ui/SnyggIcon.kt" mode="EXCERPT">
````kotlin
@Composable
fun SnyggIcon(
    elementName: String? = null,
    attributes: SnyggQueryAttributes = emptyMap(),
    selector: SnyggSelector? = null,
    modifier: Modifier = Modifier,
    imageVector: ImageVector,
    contentDescription: String? = null,
) {
    ProvideSnyggStyle(elementName, attributes, selector) { style ->
        Icon(
            modifier = modifier.snyggIconSize(style),
            imageVector = imageVector,
            contentDescription = contentDescription,
            tint = style.foreground(),
        )
    }
}
````
</augment_code_snippet>

### Accessibility Class Names

Views provide accessibility class names for proper identification:

<augment_code_snippet path="app/src/main/kotlin/dev/patrickgold/florisboard/FlorisImeService.kt" mode="EXCERPT">
````kotlin
override fun getAccessibilityClassName(): CharSequence {
    return javaClass.name
}
````
</augment_code_snippet>

### Haptic Feedback Controller

The `InputFeedbackController` manages haptic and audio feedback:

```kotlin
class InputFeedbackController {
    fun keyPress(data: KeyData) {
        if (prefs.inputFeedback.hapticEnabled.get()) {
            performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP)
        }
        if (prefs.inputFeedback.audioEnabled.get()) {
            playKeySound(data)
        }
    }

    fun keyLongPress(data: KeyData) {
        if (prefs.inputFeedback.hapticEnabled.get()) {
            performHapticFeedback(HapticFeedbackConstants.LONG_PRESS)
        }
    }
}
```

### Keyboard Enabled State

Keys can be enabled or disabled based on context, with proper accessibility support:

<augment_code_snippet path="app/src/main/kotlin/dev/patrickgold/florisboard/ime/keyboard/KeyboardManager.kt" mode="EXCERPT">
````kotlin
override fun evaluateEnabled(data: KeyData): Boolean {
    return when (data.code) {
        KeyCode.CLIPBOARD_COPY,
        KeyCode.CLIPBOARD_CUT -> {
            state.isSelectionMode && editorInfo.isRichInputEditor
        }
        KeyCode.CLIPBOARD_PASTE -> {
            !androidKeyguardManager.let { it.isDeviceLocked || it.isKeyguardLocked }
                && clipboardManager.canBePasted(clipboardManager.primaryClip)
        }
        ...
    }
}
````
</augment_code_snippet>

### Physical Keyboard Support

FlorisBoard supports physical keyboards with accessibility features:

- **Show/Hide On-Screen Keyboard**: Option to hide keyboard when physical keyboard is connected
- **Hardware Key Handling**: Proper handling of hardware key events
- **Keyboard Shortcuts**: Support for common keyboard shortcuts

## Code Examples

### Adding Content Descriptions

```kotlin
@Composable
fun AccessibleButton(
    onClick: () -> Unit,
    label: String,
    contentDescription: String,
) {
    SnyggButton(
        onClick = onClick,
        modifier = Modifier.semantics {
            this.contentDescription = contentDescription
            this.role = Role.Button
        }
    ) {
        Text(text = label)
    }
}
```

### Announcing State Changes

```kotlin
@Composable
fun KeyboardModeSwitch() {
    val context = LocalContext.current
    val view = LocalView.current

    LaunchedEffect(keyboardMode) {
        view.announceForAccessibility(
            context.getString(R.string.keyboard_mode_changed, keyboardMode.name)
        )
    }
}
```

### Haptic Feedback Integration

```kotlin
@Composable
fun EmojiKey(emoji: Emoji, onEmojiInput: (Emoji) -> Unit) {
    val inputFeedbackController = LocalInputFeedbackController.current

    SnyggBox(
        modifier = Modifier.pointerInput(Unit) {
            detectTapGestures(
                onPress = {
                    inputFeedbackController.keyPress(TextKeyData.UNSPECIFIED)
                },
                onTap = {
                    onEmojiInput(emoji)
                },
                onLongPress = {
                    inputFeedbackController.keyLongPress(TextKeyData.UNSPECIFIED)
                },
            )
        },
    ) {
        EmojiText(text = emoji.value)
    }
}
```

## Best Practices

### 1. Always Provide Content Descriptions

Every interactive element should have a meaningful content description:

```kotlin
Icon(
    imageVector = Icons.Default.Settings,
    contentDescription = stringResource(R.string.settings_button_description)
)
```

### 2. Use Semantic Properties

Leverage Compose's semantic properties for better accessibility:

```kotlin
Modifier.semantics {
    contentDescription = "Delete key"
    role = Role.Button
    stateDescription = if (enabled) "Enabled" else "Disabled"
}
```

### 3. Announce Important Changes

Use `announceForAccessibility()` for important state changes:

```kotlin
view.announceForAccessibility("Caps lock enabled")
```

### 4. Support Multiple Feedback Modes

Provide haptic, audio, and visual feedback:

```kotlin
fun provideKeyFeedback(key: KeyData) {
    // Visual feedback
    showKeyHighlight(key)

    // Haptic feedback
    if (hapticsEnabled) performHapticFeedback()

    // Audio feedback
    if (soundEnabled) playKeySound()
}
```

### 5. Respect System Accessibility Settings

Check and respect system accessibility preferences:

```kotlin
val accessibilityManager = context.getSystemService(AccessibilityManager::class.java)
if (accessibilityManager.isEnabled) {
    // Adjust UI for accessibility
}
```

## Common Patterns

### Accessible Custom Views

```kotlin
@Composable
fun AccessibleKeyboardKey(
    key: TextKey,
    onKeyPress: () -> Unit,
) {
    val label = key.computedData.label
    val contentDesc = buildString {
        append(label)
        if (key.computedData.type == KeyType.SHIFT) {
            append(", shift key")
        }
    }

    Box(
        modifier = Modifier
            .semantics {
                contentDescription = contentDesc
                role = Role.Button
            }
            .clickable(onClick = onKeyPress)
    ) {
        Text(text = label)
    }
}
```

### Focus Management

```kotlin
@Composable
fun KeyboardLayout() {
    val focusManager = LocalFocusManager.current

    LaunchedEffect(isVisible) {
        if (isVisible) {
            // Request focus on first key
            focusManager.moveFocus(FocusDirection.Next)
        }
    }
}
```

## Troubleshooting

### TalkBack Not Reading Keys

**Problem**: Screen reader doesn't announce key presses.

**Solutions**:
- Ensure content descriptions are set
- Check semantic properties are properly applied
- Verify accessibility services are enabled
- Test with `Modifier.semantics { }`

### Haptic Feedback Not Working

**Problem**: No vibration on key press.

**Solutions**:
- Check if haptic feedback is enabled in preferences
- Verify device supports haptic feedback
- Ensure `isHapticFeedbackEnabled = true` on view
- Check system haptic feedback settings

### High Contrast Mode Issues

**Problem**: UI elements not visible in high contrast mode.

**Solutions**:
- Use theme system for colors
- Avoid hardcoded colors
- Test with high contrast themes
- Ensure sufficient color contrast ratios

## Related Topics

- [Custom UI Components](./custom-ui.md) - Building accessible UI components
- [Input Processing Pipeline](./input-pipeline.md) - How input events are processed
- [Theme System](../architecture/extensions.md) - Customizing visual appearance
- [Android IME APIs](../integration/apis.md) - IME service integration

## Next Steps

- Review [Custom UI Components](./custom-ui.md) to learn about building accessible Compose UI
- Explore [Theme System](../architecture/extensions.md) for creating accessible themes
- Test your keyboard with TalkBack and other accessibility services
- Follow Android's [Accessibility Guidelines](https://developer.android.com/guide/topics/ui/accessibility)

---

**Note**: This documentation is continuously being improved. Contributions are welcome!
