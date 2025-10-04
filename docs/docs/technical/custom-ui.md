# Custom UI Components & KeyboardView

## Overview

FlorisBoard is built entirely with Jetpack Compose, providing a modern, declarative UI framework for creating custom keyboard components. This document explores the architecture, components, and patterns used to build the keyboard interface.

## Introduction

FlorisBoard leverages Jetpack Compose to create a fully customizable keyboard UI. The entire keyboard interface—from individual keys to complex layouts like emoji pickers—is built using Compose composables. This approach provides reactive state management, efficient recomposition, and a declarative API for building UI.

## Key Concepts

### Jetpack Compose in IME Context

Using Compose in an InputMethodService requires special setup:

- **AbstractComposeView**: Bridge between traditional Android Views and Compose
- **Lifecycle Integration**: Proper lifecycle management for Compose in IME
- **ViewTreeOwners**: Setting up LifecycleOwner, ViewModelStoreOwner, and SavedStateRegistryOwner
- **Window Management**: Handling IME window constraints and sizing

### Snygg Theme System

FlorisBoard uses a custom styling engine called **Snygg** (Swedish for "stylish"):

- **CSS-like Syntax**: Familiar styling approach with selectors and properties
- **Dynamic Theming**: Runtime theme switching without recomposition
- **Component-based**: Styles are scoped to specific UI elements
- **Extension Support**: Themes can be packaged as extensions

### Key UI Components

#### ComposeInputView

The root Compose view for the keyboard:

<augment_code_snippet path="app/src/main/kotlin/dev/patrickgold/florisboard/FlorisImeService.kt" mode="EXCERPT">
````kotlin
private inner class ComposeInputView : AbstractComposeView(this) {
    init {
        isHapticFeedbackEnabled = true
        layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT)
    }

    @Composable
    override fun Content() {
        ImeUiWrapper()
    }

    override fun getAccessibilityClassName(): CharSequence {
        return javaClass.name
    }
}
````
</augment_code_snippet>

#### ImeUiWrapper

Main container that provides theme and manages keyboard modes:

```kotlin
@Composable
fun ImeUiWrapper() {
    FlorisImeTheme {
        when (state.imeUiMode) {
            ImeUiMode.TEXT -> TextInputLayout()
            ImeUiMode.MEDIA -> MediaInputLayout()
            ImeUiMode.CLIPBOARD -> ClipboardInputLayout()
        }
    }
}
```

#### TextKeyboardLayout

Renders individual keyboard layouts with touch handling:

<augment_code_snippet path="app/src/main/kotlin/dev/patrickgold/florisboard/ime/text/keyboard/TextKeyboardLayout.kt" mode="EXCERPT">
````kotlin
BoxWithConstraints(
    modifier = modifier
        .pointerInteropFilter { event ->
            when (event.actionMasked) {
                MotionEvent.ACTION_DOWN,
                MotionEvent.ACTION_POINTER_DOWN,
                MotionEvent.ACTION_MOVE,
                MotionEvent.ACTION_POINTER_UP,
                MotionEvent.ACTION_UP,
                MotionEvent.ACTION_CANCEL -> {
                    val clonedEvent = MotionEvent.obtain(event)
                    touchEventChannel.trySend(clonedEvent)
                    return@pointerInteropFilter true
                }
            }
            return@pointerInteropFilter false
        }
)
````
</augment_code_snippet>

## Implementation Details

### Setting Up Compose in IME

#### 1. Create AbstractComposeView

```kotlin
override fun onCreateInputView(): View {
    super.installViewTreeOwners()
    val composeView = ComposeInputView()
    inputWindowView = composeView
    return composeView
}
```

#### 2. Install ViewTree Owners

<augment_code_snippet path="app/src/main/kotlin/dev/patrickgold/florisboard/ime/lifecycle/LifecycleInputMethodService.kt" mode="EXCERPT">
````kotlin
fun installViewTreeOwners() {
    val decorView = window!!.window!!.decorView
    decorView.setViewTreeLifecycleOwner(this)
    decorView.setViewTreeViewModelStoreOwner(this)
    decorView.setViewTreeSavedStateRegistryOwner(this)
}
````
</augment_code_snippet>

### Snygg Theme System

#### Theme Definition

<augment_code_snippet path="app/src/main/kotlin/dev/patrickgold/florisboard/ime/theme/FlorisImeThemeBaseStyle.kt" mode="EXCERPT">
````kotlin
val FlorisImeThemeBaseStyle = SnyggStylesheet.v2 {
    defines {
        "--primary" to rgbaColor(76, 175, 80)
        "--primary-variant" to rgbaColor(56, 142, 60)
        "--secondary" to rgbaColor(245, 124, 0)
        "--background" to rgbaColor(33, 33, 33)
        "--surface" to rgbaColor(66, 66, 66)
        "--on-primary" to rgbaColor(240, 240, 240)
        "--shape" to roundedCornerShape(8.dp)
    }
}
````
</augment_code_snippet>

#### Applying Themes

<augment_code_snippet path="app/src/main/kotlin/dev/patrickgold/florisboard/ime/theme/FlorisImeTheme.kt" mode="EXCERPT">
````kotlin
@Composable
fun FlorisImeTheme(content: @Composable () -> Unit) {
    val keyboardManager by context.keyboardManager()
    val themeManager by context.themeManager()
    val activeStyle = themeManager.activeStyle
    val snyggTheme = rememberSnyggTheme(activeStyle, assetResolver)

    MaterialTheme {
        ProvideSnyggTheme(
            snyggTheme = snyggTheme,
            dynamicAccentColor = accentColor,
            fontSizeMultiplier = fontSizeMultiplier,
            content = content,
        )
    }
}
````
</augment_code_snippet>

### Custom Snygg Components

#### SnyggBox

Basic container with theme support:

```kotlin
@Composable
fun SnyggBox(
    elementName: String,
    modifier: Modifier = Modifier,
    attributes: SnyggQueryAttributes = emptyMap(),
    content: @Composable BoxScope.() -> Unit
) {
    ProvideSnyggStyle(elementName, attributes, null) { style ->
        Box(
            modifier = modifier
                .background(style.background())
                .border(style.border())
                .padding(style.padding()),
            content = content
        )
    }
}
```

#### SnyggButton

Interactive button with state management:

```kotlin
@Composable
fun SnyggButton(
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    content: @Composable RowScope.() -> Unit
) {
    val interactionSource = remember { MutableInteractionSource() }
    val isPressed by interactionSource.collectIsPressedAsState()

    val selector = when {
        !enabled -> SnyggSelector.DISABLED
        isPressed -> SnyggSelector.PRESSED
        else -> SnyggSelector.NONE
    }

    ProvideSnyggStyle(elementName, attributes, selector) { style ->
        Row(
            modifier = modifier
                .clickable(
                    onClick = onClick,
                    enabled = enabled,
                    interactionSource = interactionSource,
                    indication = null
                )
                .background(style.background())
                .padding(style.padding()),
            content = content
        )
    }
}
```

### Key Rendering

#### TextKeyButton

Individual key rendering with touch bounds:

<augment_code_snippet path="app/src/main/kotlin/dev/patrickgold/florisboard/ime/text/keyboard/TextKeyboardLayout.kt" mode="EXCERPT">
````kotlin
val desiredKey = remember(
    keyboard, keyboardWidth, keyboardHeight, keyMarginH, keyMarginV,
    keyboardRowBaseHeight, evaluator
) {
    TextKey(data = TextKeyData.UNSPECIFIED).also { desiredKey ->
        desiredKey.touchBounds.apply {
            width = keyboardWidth / 10f
            height = when (keyboard.mode) {
                KeyboardMode.CHARACTERS,
                KeyboardMode.NUMERIC_ADVANCED,
                KeyboardMode.SYMBOLS,
                KeyboardMode.SYMBOLS2 -> {
                    (keyboardHeight / keyboard.rowCount)
                        .coerceAtMost(keyboardRowBaseHeight.toPx() * 1.12f)
                }
                else -> keyboardRowBaseHeight.toPx()
            }
        }
        desiredKey.visibleBounds.applyFrom(desiredKey.touchBounds).deflateBy(keyMarginH, keyMarginV)
        keyboard.layout(keyboardWidth, keyboardHeight, desiredKey, true)
    }
}
````
</augment_code_snippet>

### Media Input Layout

Emoji picker and media input:

<augment_code_snippet path="app/src/main/kotlin/dev/patrickgold/florisboard/ime/media/MediaInputLayout.kt" mode="EXCERPT">
````kotlin
SnyggColumn(
    elementName = FlorisImeUi.Media.elementName,
    modifier = modifier
        .fillMaxWidth()
        .height(FlorisImeSizing.imeUiHeight()),
) {
    EmojiPaletteView(
        modifier = Modifier.weight(1f),
        fullEmojiMappings = emojiLayoutDataMap,
    )
    SnyggRow(
        elementName = FlorisImeUi.MediaBottomRow.elementName,
        modifier = Modifier
            .fillMaxWidth()
            .height(FlorisImeSizing.keyboardRowBaseHeight * 0.8f),
    ) {
        KeyboardLikeButton(
            elementName = FlorisImeUi.MediaBottomRowButton.elementName,
            keyData = TextKeyData.IME_UI_MODE_TEXT,
        ) {
            Text(text = "ABC", fontWeight = FontWeight.Bold)
        }
    }
}
````
</augment_code_snippet>

## Code Examples

### Creating a Custom Keyboard Component

```kotlin
@Composable
fun CustomKeyboardRow(
    keys: List<KeyData>,
    onKeyPress: (KeyData) -> Unit
) {
    SnyggRow(
        elementName = FlorisImeUi.KeyboardRow.elementName,
        modifier = Modifier.fillMaxWidth()
    ) {
        keys.forEach { keyData ->
            CustomKey(
                data = keyData,
                modifier = Modifier.weight(1f),
                onClick = { onKeyPress(keyData) }
            )
        }
    }
}

@Composable
fun CustomKey(
    data: KeyData,
    modifier: Modifier = Modifier,
    onClick: () -> Unit
) {
    val inputFeedbackController = LocalInputFeedbackController.current

    SnyggButton(
        elementName = FlorisImeUi.Key.elementName,
        onClick = {
            inputFeedbackController.keyPress(data)
            onClick()
        },
        modifier = modifier.aspectRatio(1f)
    ) {
        Text(
            text = data.label,
            style = MaterialTheme.typography.bodyLarge
        )
    }
}
```

### Responsive Layout

```kotlin
@Composable
fun ResponsiveKeyboard() {
    BoxWithConstraints {
        val isLandscape = maxWidth > maxHeight
        val keyboardHeight = if (isLandscape) {
            maxHeight * 0.5f
        } else {
            maxHeight * 0.4f
        }

        KeyboardLayout(
            modifier = Modifier.height(keyboardHeight)
        )
    }
}
```

### State-Driven UI

```kotlin
@Composable
fun StatefulKeyboard() {
    val keyboardManager by LocalContext.current.keyboardManager()
    val state by keyboardManager.activeState.collectAsState()

    val attributes = mapOf(
        FlorisImeUi.Attr.Mode to state.keyboardMode.toString(),
        FlorisImeUi.Attr.ShiftState to state.inputShiftState.toString(),
    )

    SnyggBox(
        elementName = FlorisImeUi.Keyboard.elementName,
        attributes = attributes
    ) {
        // Keyboard content that reacts to state changes
    }
}
```

## Best Practices

### 1. Use remember for Expensive Calculations

```kotlin
val layoutData = remember(keyboard, width, height) {
    computeKeyboardLayout(keyboard, width, height)
}
```

### 2. Minimize Recomposition Scope

```kotlin
@Composable
fun KeyboardKey(key: TextKey) {
    // Only this key recomposes when its state changes
    val isPressed by key.isPressedState.collectAsState()

    KeyContent(key, isPressed)
}
```

### 3. Use derivedStateOf for Computed Values

```kotlin
val shouldShowPopup by remember {
    derivedStateOf {
        isPressed && hasPopupKeys
    }
}
```

### 4. Proper Lifecycle Management

```kotlin
@Composable
fun KeyboardComponent() {
    DisposableEffect(Unit) {
        // Setup
        onDispose {
            // Cleanup
        }
    }
}
```

### 5. Handle Touch Events Efficiently

```kotlin
LaunchedEffect(Unit) {
    for (event in touchEventChannel) {
        if (!isActive) break
        controller.onTouchEventInternal(event)
        event.recycle()
    }
}
```

## Common Patterns

### Theme-Aware Components

```kotlin
@Composable
fun ThemedKey(label: String) {
    ProvideSnyggStyle(
        elementName = FlorisImeUi.Key.elementName,
        attributes = emptyMap(),
        selector = SnyggSelector.NONE
    ) { style ->
        Box(
            modifier = Modifier
                .background(style.background())
                .border(style.border())
                .padding(style.padding())
        ) {
            Text(
                text = label,
                color = style.foreground(),
                fontSize = style.fontSize()
            )
        }
    }
}
```

### Popup Management

```kotlin
@Composable
fun KeyWithPopup(key: TextKey) {
    var showPopup by remember { mutableStateOf(false) }

    Box {
        KeyButton(
            onLongPress = { showPopup = true }
        )

        if (showPopup) {
            Popup(
                alignment = Alignment.TopCenter,
                onDismissRequest = { showPopup = false }
            ) {
                PopupContent(key.popupKeys)
            }
        }
    }
}
```

## Troubleshooting

### Compose Not Rendering

**Problem**: Compose UI doesn't appear in IME.

**Solutions**:
- Ensure `installViewTreeOwners()` is called
- Check lifecycle state is properly managed
- Verify `AbstractComposeView` is returned from `onCreateInputView()`

### Performance Issues

**Problem**: UI lags or stutters during typing.

**Solutions**:
- Use `remember` for expensive calculations
- Minimize recomposition scope with `derivedStateOf`
- Profile with Compose Layout Inspector
- Check for unnecessary recompositions

### Theme Not Applying

**Problem**: Custom theme styles not showing.

**Solutions**:
- Verify theme is loaded in ThemeManager
- Check element names match stylesheet
- Ensure `ProvideSnyggTheme` wraps content
- Validate stylesheet syntax

## Related Topics

- [Architecture Overview](../architecture/overview.md) - System architecture
- [Input Processing Pipeline](./input-pipeline.md) - Touch event handling
- [Theme System](../architecture/extensions.md) - Snygg styling engine
- [Accessibility Features](./accessibility.md) - Making UI accessible

## Next Steps

- Explore [Input Processing Pipeline](./input-pipeline.md) for touch handling
- Learn about [Theme System](../architecture/extensions.md) for customization
- Review [Accessibility Features](./accessibility.md) for inclusive design
- Study Jetpack Compose [documentation](https://developer.android.com/jetpack/compose)

---

**Note**: This documentation is continuously being improved. Contributions are welcome!
