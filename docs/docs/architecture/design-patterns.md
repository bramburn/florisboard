# Design Patterns Explained

## Introduction

FlorisBoard employs several well-established design patterns to maintain code quality, testability, and maintainability. This document explains the key patterns used throughout the codebase and provides examples of their implementation.

## Architectural Patterns

### 1. MVVM (Model-View-ViewModel)

FlorisBoard uses a variant of MVVM adapted for Android IME development with Jetpack Compose.

#### Structure

```
┌─────────┐         ┌──────────────┐         ┌───────┐
│  View   │────────▶│  ViewModel   │────────▶│ Model │
│ (Compose)│◀────────│  (Manager)   │◀────────│ (Data)│
└─────────┘         └──────────────┘         └───────┘
     │                      │                      │
     │                      │                      │
  UI Layer            Business Logic          Data Layer
```

#### Implementation Example

**Model (Data)**
```kotlin
// EditorContent.kt - Represents editor state
data class EditorContent(
    val text: String,
    val selection: EditorRange,
    val composing: EditorRange?,
) {
    companion object {
        val Unspecified = EditorContent(
            text = "",
            selection = EditorRange.Unspecified,
            composing = null,
        )
    }
}
```

**ViewModel (Manager)**
```kotlin
// KeyboardManager.kt - Business logic
class KeyboardManager(context: Context) {
    // Observable state
    val activeState = ObservableKeyboardState.new()
    
    // State flows for reactive updates
    private val _activeEvaluator = MutableStateFlow<TextKeyboardEvaluator?>(null)
    val activeEvaluator = _activeEvaluator.asStateFlow()
    
    // Business logic methods
    fun handleKeyPress(data: KeyData) {
        // Process key press
        when (data.code) {
            KeyCode.DELETE -> handleBackwardDelete()
            KeyCode.ENTER -> handleEnter()
            else -> handleCharacterInput(data)
        }
    }
}
```

**View (Compose)**
```kotlin
// TextInputLayout.kt - UI
@Composable
fun TextInputLayout() {
    val keyboardManager by context.keyboardManager()
    val state by keyboardManager.activeState.collectAsState()
    val evaluator by keyboardManager.activeEvaluator.collectAsState()
    
    // UI reacts to state changes
    evaluator?.let { eval ->
        TextKeyboardLayout(
            keyboard = eval.keyboard,
            state = state,
        )
    }
}
```

### 2. Observer Pattern

Used extensively for reactive state management and event propagation.

#### StateFlow Implementation

```kotlin
// ObservableKeyboardState.kt
class ObservableKeyboardState private constructor(
    initValue: ULong,
    private val dispatchFlow: MutableStateFlow<KeyboardState>,
) : KeyboardState(initValue), StateFlow<KeyboardState> by dispatchFlow {
    
    override var rawValue by Delegates.observable(initValue) { _, old, new ->
        if (old != new) dispatchState()
    }
    
    private fun dispatchState() {
        dispatchFlow.value = KeyboardState.new(rawValue)
    }
    
    fun batchEdit(block: KeyboardState.() -> Unit) {
        batchEditCount.incrementAndGet()
        try {
            block()
        } finally {
            if (batchEditCount.decrementAndGet() == BATCH_ZERO) {
                dispatchState()
            }
        }
    }
}
```

#### Usage in Compose

```kotlin
@Composable
fun KeyboardComponent() {
    val keyboardManager by context.keyboardManager()
    val state by keyboardManager.activeState.collectAsState()
    
    // UI automatically recomposes when state changes
    Text("Current mode: ${state.keyboardMode}")
}
```

### 3. Strategy Pattern

Used for pluggable algorithms and behaviors, especially in NLP providers.

#### Interface Definition

```kotlin
// NlpProviders.kt
interface SuggestionProvider : NlpProvider {
    suspend fun suggest(
        subtype: Subtype,
        content: EditorContent,
        maxCandidateCount: Int,
        allowPossiblyOffensive: Boolean,
        isPrivateSession: Boolean,
    ): List<SuggestionCandidate>
}

interface SpellingProvider : NlpProvider {
    suspend fun spell(
        subtype: Subtype,
        word: String,
        precedingWords: List<String>,
        followingWords: List<String>,
        maxSuggestionCount: Int,
        allowPossiblyOffensive: Boolean,
        isPrivateSession: Boolean,
    ): SpellingResult
}
```

#### Concrete Implementations

```kotlin
// LatinLanguageProvider.kt
class LatinLanguageProvider : SuggestionProvider, SpellingProvider {
    override suspend fun suggest(...): List<SuggestionCandidate> {
        // Latin-specific suggestion logic
    }
    
    override suspend fun spell(...): SpellingResult {
        // Latin-specific spelling logic
    }
}

// HanShapeBasedLanguageProvider.kt
class HanShapeBasedLanguageProvider : SuggestionProvider, SpellingProvider {
    override suspend fun suggest(...): List<SuggestionCandidate> {
        // Han-specific suggestion logic
    }
    
    override suspend fun spell(...): SpellingResult {
        // Han-specific spelling logic
    }
}
```

#### Provider Selection

```kotlin
// NlpManager.kt
class NlpManager(context: Context) {
    private fun getSuggestionProvider(subtype: Subtype): SuggestionProvider {
        return when (subtype.primaryLocale.language) {
            "zh", "ja", "ko" -> hanShapeBasedProvider
            else -> latinLanguageProvider
        }
    }
}
```

### 4. Factory Pattern

Used for creating complex objects with multiple configuration options.

#### Extension Factory

```kotlin
// ExtensionManager.kt
class ExtensionManager(context: Context) {
    fun createExtension(meta: ExtensionMeta, sourceRef: Uri): Extension? {
        return when (meta.type) {
            KeyboardExtension.SERIAL_TYPE -> {
                loadJsonAsset<KeyboardExtension>(jsonStr).getOrNull()
            }
            ThemeExtension.SERIAL_TYPE -> {
                loadJsonAsset<ThemeExtension>(jsonStr).getOrNull()
            }
            else -> null
        }
    }
}
```

#### Keyboard Factory

```kotlin
// LayoutManager.kt
suspend fun computeKeyboardAsync(
    keyboardMode: KeyboardMode,
    subtype: Subtype,
): TextKeyboard {
    // Determine which layouts to load
    val main = LTN(LayoutType.CHARACTERS, subtype.layoutMap.characters)
    val modifier = LTN(LayoutType.CHARACTERS_MOD, extCoreLayout("default"))
    val extension = if (prefs.keyboard.numberRow.get()) {
        LTN(LayoutType.NUMERIC_ROW, subtype.layoutMap.numericRow)
    } else null
    
    // Load and compose layouts
    return composeKeyboard(keyboardMode, subtype, main, modifier, extension)
}
```

### 5. Singleton Pattern (via Lazy Initialization)

Managers are lazily initialized singletons within the application scope.

```kotlin
// FlorisApplication.kt
class FlorisApplication : Application() {
    val cacheManager = lazy { CacheManager(this) }
    val clipboardManager = lazy { ClipboardManager(this) }
    val editorInstance = lazy { EditorInstance(this) }
    val extensionManager = lazy { ExtensionManager(this) }
    val glideTypingManager = lazy { GlideTypingManager(this) }
    val keyboardManager = lazy { KeyboardManager(this) }
    val nlpManager = lazy { NlpManager(this) }
    val subtypeManager = lazy { SubtypeManager(this) }
    val themeManager = lazy { ThemeManager(this) }
}
```

#### Access Pattern

```kotlin
// Context extensions for easy access
fun Context.keyboardManager() = lazy {
    (applicationContext as FlorisApplication).keyboardManager.value
}

// Usage
class SomeComponent(context: Context) {
    private val keyboardManager by context.keyboardManager()
}
```

### 6. Builder Pattern

Used for complex object construction, especially in Snygg theme system.

```kotlin
// SnyggStylesheet.kt
fun SnyggStylesheet.Companion.v2(
    block: SnyggStylesheetBuilder.() -> Unit
): SnyggStylesheet {
    return SnyggStylesheetBuilder().apply(block).build()
}

// Usage
val FlorisImeThemeBaseStyle = SnyggStylesheet.v2 {
    defines {
        "--primary" to rgbaColor(76, 175, 80)
        "--background" to rgbaColor(33, 33, 33)
        "--shape" to roundedCornerShape(8.dp)
    }
    
    "keyboard" {
        background = `var`("--background")
        foreground = `var`("--primary")
        shape = `var`("--shape")
    }
    
    "key"(selector = SnyggSelector.PRESSED) {
        foreground = rgbaColor(255, 255, 255)
    }
}
```

### 7. Adapter Pattern

Used to adapt Android system interfaces to FlorisBoard's internal representations.

```kotlin
// FlorisEditorInfo.kt - Adapts Android EditorInfo
class FlorisEditorInfo private constructor(
    val packageName: String,
    val inputAttributes: InputAttributes,
    val initialSelection: EditorRange,
    val initialCapsMode: InputShiftState,
    val isRichInputEditor: Boolean,
) {
    companion object {
        fun wrap(editorInfo: EditorInfo): FlorisEditorInfo {
            // Adapt Android EditorInfo to FlorisEditorInfo
            return FlorisEditorInfo(
                packageName = editorInfo.packageName,
                inputAttributes = InputAttributes.fromEditorInfo(editorInfo),
                initialSelection = EditorRange.from(editorInfo),
                initialCapsMode = determineInitialCapsMode(editorInfo),
                isRichInputEditor = determineRichInputSupport(editorInfo),
            )
        }
    }
}
```

### 8. Command Pattern

Used for input event handling and undo/redo operations.

```kotlin
// InputEventDispatcher.kt
class InputEventDispatcher(
    private val scope: CoroutineScope,
    private val keyEventReceiver: InputKeyEventReceiver?,
) {
    fun sendDown(
        data: KeyData,
        onLongPress: () -> Boolean = { false },
        onRepeat: () -> Boolean = { true },
    ) = runBlocking {
        val pressedKeyInfo = PressedKeyInfo(eventTime).also { info ->
            info.job = scope.launch {
                delay(longPressDelay)
                val result = withContext(Dispatchers.Main) { onLongPress() }
                if (result) {
                    info.blockUp = true
                } else {
                    // Handle repeat
                }
            }
        }
        keyEventReceiver?.onInputKeyDown(data)
    }
    
    fun sendUp(data: KeyData) = runBlocking {
        keyEventReceiver?.onInputKeyUp(data)
    }
}
```

### 9. Composite Pattern

Used for keyboard layout composition and key hierarchies.

```kotlin
// TextKeyboard.kt
data class TextKeyboard(
    val arrangement: Array<Array<TextKey>>,
    val mode: KeyboardMode,
    val extendedPopupMapping: Map<Int, ExtendedPopupMapping>?,
    val extendedPopupMappingDefault: Map<Int, ExtendedPopupMapping>?,
) {
    fun keys(): Sequence<TextKey> = sequence {
        for (row in arrangement) {
            for (key in row) {
                yield(key)
            }
        }
    }
}

// TextKey can contain other keys in popups
data class TextKey(
    val computedData: KeyData,
    val computedPopups: KeyPopupCollection?,
    // ... other properties
)
```

### 10. Decorator Pattern

Used to enhance functionality without modifying original classes.

```kotlin
// LifecycleInputMethodService.kt - Decorates InputMethodService
abstract class LifecycleInputMethodService : InputMethodService(), LifecycleOwner {
    private val lifecycleRegistry = LifecycleRegistry(this)
    
    override val lifecycle: Lifecycle
        get() = lifecycleRegistry
    
    // Decorates lifecycle methods
    override fun onCreate() {
        super.onCreate()
        lifecycleRegistry.handleLifecycleEvent(Lifecycle.Event.ON_CREATE)
    }
    
    override fun onDestroy() {
        lifecycleRegistry.handleLifecycleEvent(Lifecycle.Event.ON_DESTROY)
        super.onDestroy()
    }
}
```

## Reactive Patterns

### Flow-Based Architecture

```kotlin
// Combining multiple flows
combine(
    prefs.theme.mode.asFlow(),
    prefs.theme.dayThemeId.asFlow(),
    prefs.theme.nightThemeId.asFlow(),
    previewThemeId,
) { mode, dayId, nightId, previewId ->
    // React to any change
    updateActiveTheme()
}.collectIn(scope)
```

### State Hoisting

```kotlin
@Composable
fun ParentComponent() {
    var selectedKey by remember { mutableStateOf<TextKey?>(null) }
    
    KeyboardLayout(
        selectedKey = selectedKey,
        onKeySelected = { key -> selectedKey = key }
    )
}

@Composable
fun KeyboardLayout(
    selectedKey: TextKey?,
    onKeySelected: (TextKey) -> Unit,
) {
    // State is hoisted to parent
}
```

## Concurrency Patterns

### Mutex for Thread Safety

```kotlin
class LayoutManager(context: Context) {
    private val layoutCache: HashMap<LTN, DeferredResult<CachedLayout>> = hashMapOf()
    private val layoutCacheGuard: Mutex = Mutex(locked = false)
    
    suspend fun loadLayoutAsync(ltn: LTN?): Deferred<Result<CachedLayout>> {
        return layoutCacheGuard.withLock {
            layoutCache.getOrPut(ltn) {
                async { loadLayout(ltn) }
            }
        }
    }
}
```

### Coroutine Scopes

```kotlin
class ThemeManager(context: Context) {
    private val scope = CoroutineScope(Dispatchers.Default + SupervisorJob())
    
    init {
        // Launch coroutines in manager scope
        indexedThemeConfigs.collectIn(scope) {
            updateActiveTheme()
        }
    }
}
```

## Best Practices

### 1. Immutability
- Use `val` over `var` when possible
- Use immutable data classes
- Copy-on-write for state updates

### 2. Null Safety
- Leverage Kotlin's null safety
- Use safe calls and elvis operator
- Avoid `!!` operator

### 3. Extension Functions
- Extend existing classes without inheritance
- Keep code organized and readable

### 4. Sealed Classes
- Represent restricted class hierarchies
- Exhaustive when expressions

### 5. Delegation
- Property delegation for lazy initialization
- Class delegation for composition

## Next Steps

- [State Management](./state-management.md) - Deep dive into state handling
- [Performance Optimizations](./performance.md) - Performance patterns
- [Extension System](./extensions.md) - Plugin architecture patterns

