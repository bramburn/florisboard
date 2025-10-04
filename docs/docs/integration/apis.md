# Android IME APIs & Service Integration

## Overview

Comprehensive guide to Android's InputMethodService API and how FlorisBoard integrates with the Android system.

## Introduction

FlorisBoard extends Android's `InputMethodService` to provide a fully-featured keyboard implementation. This document covers the core Android IME APIs, lifecycle management, and how FlorisBoard integrates with the Android system through custom lifecycle-aware components.

## Key Concepts

### InputMethodService

The `InputMethodService` is the base class for implementing an Input Method Editor (IME) in Android. It provides:

- **Lifecycle Management**: Handles creation, visibility, and destruction of the keyboard
- **Input View Management**: Creates and manages the keyboard UI
- **Input Connection**: Communicates with the target application's text field
- **Configuration Handling**: Responds to device configuration changes
- **Window Management**: Controls keyboard window properties and behavior

### LifecycleInputMethodService

FlorisBoard extends `InputMethodService` with a custom `LifecycleInputMethodService` that adds:

- **Lifecycle Awareness**: Implements `LifecycleOwner` for AndroidX Lifecycle support
- **ViewModel Support**: Implements `ViewModelStoreOwner` for ViewModel integration
- **SavedState Support**: Implements `SavedStateRegistryOwner` for state preservation
- **Coroutine Scope**: Provides lifecycle-aware coroutine scope

### InputConnection

The `InputConnection` interface is the communication channel between the IME and the target application:

- **Text Manipulation**: Insert, delete, and replace text
- **Cursor Control**: Move cursor and manage selection
- **Composing Text**: Handle text composition for predictive input
- **Editor Actions**: Perform actions like "Go", "Search", "Send"

## Implementation Details

### FlorisImeService Architecture

<augment_code_snippet path="app/src/main/kotlin/dev/patrickgold/florisboard/FlorisImeService.kt" mode="EXCERPT">
````kotlin
class FlorisImeService : LifecycleInputMethodService() {
    // Core managers injected via dependency injection
    private val keyboardManager by keyboardManager()
    private val editorInstance by editorInstance()
    private val themeManager by themeManager()
    ...
````
</augment_code_snippet>

### Lifecycle Events

The service follows this lifecycle:

```
onCreate() → onStartInput() → onStartInputView() → onWindowShown()
    ↓                                                      ↓
onDestroy() ← onFinishInput() ← onFinishInputView() ← onWindowHidden()
```

#### onCreate()

<augment_code_snippet path="app/src/main/kotlin/dev/patrickgold/florisboard/FlorisImeService.kt" mode="EXCERPT">
````kotlin
override fun onCreate() {
    super.onCreate()
    FlorisImeServiceReference = WeakReference(this)
    WindowCompat.setDecorFitsSystemWindows(window.window!!, false)
    subtypeManager.activeSubtypeFlow.collectIn(lifecycleScope) { subtype ->
        val config = Configuration(resources.configuration)
        if (prefs.localization.displayKeyboardLabelsInSubtypeLanguage.get()) {
            config.setLocale(subtype.primaryLocale.base)
        }
        resourcesContext = createConfigurationContext(config)
    }
    ...
````
</augment_code_snippet>

#### onCreateInputView()

Creates the Compose-based keyboard UI:

<augment_code_snippet path="app/src/main/kotlin/dev/patrickgold/florisboard/FlorisImeService.kt" mode="EXCERPT">
````kotlin
override fun onCreateInputView(): View {
    super.installViewTreeOwners()
    // Instantiate and install bottom sheet host UI view
    val bottomSheetView = FlorisBottomSheetHostUiView()
    window.window!!.findViewById<ViewGroup>(android.R.id.content).addView(bottomSheetView)
    // Instantiate and return input view
    val composeView = ComposeInputView()
    inputWindowView = composeView
    return composeView
}
````
</augment_code_snippet>

#### onStartInput() & onStartInputView()

Called when a new text field receives focus:

<augment_code_snippet path="app/src/main/kotlin/dev/patrickgold/florisboard/FlorisImeService.kt" mode="EXCERPT">
````kotlin
override fun onStartInput(info: EditorInfo?, restarting: Boolean) {
    flogInfo { "restarting=$restarting info=${info?.debugSummarize()}" }
    super.onStartInput(info, restarting)
    if (info == null) return
    val editorInfo = FlorisEditorInfo.wrap(info)
    editorInstance.handleStartInput(editorInfo)
}

override fun onStartInputView(info: EditorInfo?, restarting: Boolean) {
    flogInfo { "restarting=$restarting info=${info?.debugSummarize()}" }
    super.onStartInputView(info, restarting)
    if (info == null) return
    val editorInfo = FlorisEditorInfo.wrap(info)
    activeState.batchEdit {
        if (activeState.imeUiMode != ImeUiMode.CLIPBOARD || prefs.clipboard.historyHideOnNextTextField.get()) {
            activeState.imeUiMode = ImeUiMode.TEXT
        }
        activeState.isSelectionMode = editorInfo.initialSelection.isSelectionMode
        editorInstance.handleStartInputView(editorInfo, isRestart = restarting)
    }
}
````
</augment_code_snippet>

### EditorInfo Processing

FlorisBoard wraps Android's `EditorInfo` to extract input attributes:

- **Input Type**: Text, number, phone, email, password, etc.
- **IME Options**: Action buttons (Go, Search, Send, Done)
- **Input Flags**: Auto-correct, auto-capitalize, multi-line
- **Package Name**: Identify the calling application

## Code Examples

### Accessing InputConnection

<augment_code_snippet path="app/src/main/kotlin/dev/patrickgold/florisboard/ime/editor/EditorInstance.kt" mode="EXCERPT">
````kotlin
fun commitText(text: String): Boolean {
    val ic = currentInputConnection() ?: return false

    // Handle phantom space
    if (phantomSpace.determine(text)) {
        ic.commitText(" ", 1)
    }
    phantomSpace.setInactive()

    // Commit text
    ic.commitText(text, 1)

    // Update auto-space state
    autoSpace.updateState(text)

    return true
}
````
</augment_code_snippet>

### Handling Hardware Keys

<augment_code_snippet path="app/src/main/kotlin/dev/patrickgold/florisboard/FlorisImeService.kt" mode="EXCERPT">
````kotlin
override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
    return keyboardManager.onHardwareKeyDown(keyCode, event) || super.onKeyDown(keyCode, event)
}

override fun onKeyUp(keyCode: Int, event: KeyEvent?): Boolean {
    return keyboardManager.onHardwareKeyUp(keyCode, event) || super.onKeyUp(keyCode, event)
}
````
</augment_code_snippet>

## Best Practices

### 1. Always Check InputConnection Validity

```kotlin
val ic = currentInputConnection() ?: return false
// Use ic safely
```

### 2. Handle Configuration Changes

Override `onConfigurationChanged()` to respond to orientation, locale, or theme changes:

```kotlin
override fun onConfigurationChanged(newConfig: Configuration) {
    super.onConfigurationChanged(newConfig)
    themeManager.configurationChangeCounter.update { it + 1 }
}
```

### 3. Use Lifecycle-Aware Components

Leverage `lifecycleScope` for coroutines that should be cancelled when the service is destroyed:

```kotlin
prefs.somePreference.asFlow().collectIn(lifecycleScope) { value ->
    // Handle preference change
}
```

### 4. Manage Window Parameters

Control keyboard window behavior for different scenarios:

```kotlin
override fun updateFullscreenMode() {
    super.updateFullscreenMode()
    isFullscreenUiMode = isFullscreenMode
    updateSoftInputWindowLayoutParameters()
}
```

## Common Patterns

### Switching Input Methods

```kotlin
fun switchToVoiceInputMethod(): Boolean {
    val ims = FlorisImeServiceReference.get() ?: return false
    val imm = ims.systemServiceOrNull(InputMethodManager::class) ?: return false
    val list: List<InputMethodInfo> = imm.enabledInputMethodList
    for (el in list) {
        for (i in 0 until el.subtypeCount) {
            if (el.getSubtypeAt(i).mode != "voice") continue
            if (AndroidVersion.ATLEAST_API28_P) {
                ims.switchInputMethod(el.id, el.getSubtypeAt(i))
                return true
            }
        }
    }
    return false
}
```

### Launching Settings Activity

```kotlin
fun launchSettings() {
    val ims = FlorisImeServiceReference.get() ?: return
    ims.requestHideSelf(0)
    ims.launchActivity(FlorisAppActivity::class) {
        it.flags = Intent.FLAG_ACTIVITY_NEW_TASK or
            Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED or
            Intent.FLAG_ACTIVITY_CLEAR_TOP
    }
}
```

## Troubleshooting

### InputConnection Returns Null

**Problem**: `currentInputConnection()` returns null unexpectedly.

**Solutions**:
- Check if the keyboard is actually visible
- Verify the target app properly implements `InputConnection`
- Add null checks before using `InputConnection`

### Keyboard Not Showing

**Problem**: Keyboard doesn't appear when text field is focused.

**Solutions**:
- Check if IME is enabled in system settings
- Verify `onStartInputView()` is being called
- Check window visibility flags

### Configuration Changes Break UI

**Problem**: UI breaks after rotation or theme change.

**Solutions**:
- Properly handle `onConfigurationChanged()`
- Use `rememberSaveable` for Compose state
- Implement `SavedStateRegistryOwner`

## Related Topics

- [Architecture Overview](../architecture/overview.md) - System architecture
- [Input Processing Pipeline](../technical/input-pipeline.md) - How input is processed
- [Custom UI Components](../technical/custom-ui.md) - Compose UI implementation
- [State Management](../architecture/state-management.md) - Managing keyboard state

## Next Steps

- Explore [Input Processing Pipeline](../technical/input-pipeline.md) to understand how touch events become text
- Learn about [Custom UI Components](../technical/custom-ui.md) for building keyboard UI
- Review [State Management](../architecture/state-management.md) for reactive state handling

---

**Note**: This documentation is continuously being improved. Contributions are welcome!
