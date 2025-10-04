# Touch and Performance Optimizations

## Overview

FlorisBoard implements numerous performance optimizations to ensure responsive touch handling, smooth rendering, and minimal input latency for an excellent typing experience.

## Introduction

Performance is critical for keyboard applications where users expect instant feedback. FlorisBoard employs various optimization strategies:

- **Touch Latency Reduction**: Minimize delay between touch and visual feedback
- **Efficient Rendering**: Optimize Compose recomposition and drawing
- **Memory Management**: Reduce allocations and prevent leaks
- **Async Processing**: Keep UI thread responsive
- **Caching Strategies**: Avoid redundant computations
- **Resource Pooling**: Reuse expensive objects

## Key Concepts

### Touch Latency

Touch latency is the time between a user's touch and the visual response. FlorisBoard minimizes this through:

- **Hardware Acceleration**: GPU-accelerated rendering
- **Event Batching**: Process multiple events efficiently
- **Minimal Main Thread Work**: Offload heavy operations
- **Optimized Hit Testing**: Fast key detection

### Compose Recomposition

Jetpack Compose recomposes UI when state changes. Optimizations include:

- **Stable Parameters**: Prevent unnecessary recompositions
- **Remember**: Cache expensive calculations
- **DerivedStateOf**: Compute values only when dependencies change
- **Keys**: Help Compose identify items in lists

### Memory Efficiency

Reduce memory pressure through:

- **Object Pooling**: Reuse MotionEvent and other objects
- **LRU Caching**: Limit cache sizes
- **Weak References**: Prevent memory leaks
- **Lazy Initialization**: Create objects only when needed

### Async Operations

Keep UI responsive by:

- **Coroutines**: Structured concurrency
- **Dispatchers**: Appropriate thread pools
- **Channels**: Async communication
- **Flow**: Reactive streams

## Implementation Details

### Touch Event Optimization

#### Event Recycling

```kotlin
val touchEventChannel = remember { Channel<MotionEvent>(64) }

LaunchedEffect(Unit) {
    for (event in touchEventChannel) {
        if (!isActive) break
        controller.onTouchEventInternal(event)
        event.recycle() // Recycle to reduce allocations
    }
}
```

#### Hardware Acceleration

```kotlin
override fun onCreateInputView(): View {
    val composeView = ComposeInputView()
    composeView.setLayerType(View.LAYER_TYPE_HARDWARE, null)
    return composeView
}
```

### Compose Optimization

#### Remember Expensive Calculations

```kotlin
val desiredKey = remember(
    keyboard, keyboardWidth, keyboardHeight, keyMarginH, keyMarginV,
    keyboardRowBaseHeight, evaluator
) {
    TextKey(data = TextKeyData.UNSPECIFIED).also { desiredKey ->
        desiredKey.touchBounds.apply {
            width = keyboardWidth / 10f
            height = keyboardRowBaseHeight.toPx()
        }
        keyboard.layout(keyboardWidth, keyboardHeight, desiredKey, true)
    }
}
```

#### DerivedStateOf for Computed Values

```kotlin
val shouldShowPopup by remember {
    derivedStateOf {
        isPressed && hasPopupKeys
    }
}
```

#### Stable Keys in Lists

```kotlin
LazyColumn {
    items(
        items = emojiList,
        key = { emoji -> emoji.value } // Stable key
    ) { emoji ->
        EmojiItem(emoji)
    }
}
```

### Caching Strategies

#### Layout Caching

```kotlin
class LayoutManager(context: Context) {
    private val layoutCache: HashMap<LTN, DeferredResult<CachedLayout>> = hashMapOf()
    private val layoutCacheGuard: Mutex = Mutex(locked = false)

    private fun loadLayoutAsync(ltn: LTN?) = ioScope.runCatchingAsync {
        layoutCacheGuard.withLock {
            val cached = layoutCache[ltn]
            if (cached != null) {
                flogDebug { "Using cache for '${ltn.name}'" }
                return@withLock cached
            } else {
                flogDebug { "Loading '${ltn.name}'" }
                // Load and cache layout
            }
        }
    }
}
```

#### Dictionary Caching

```kotlin
class LatinLanguageProvider(context: Context) {
    private val wordData = guardedByLock { mutableMapOf<String, Int>() }

    override suspend fun preload(subtype: Subtype) {
        wordData.withLock { wordData ->
            if (wordData.isEmpty()) {
                val rawData = appContext.assets.readText("ime/dict/data.json")
                val jsonData = Json.decodeFromString(wordDataSerializer, rawData)
                wordData.putAll(jsonData)
            }
        }
    }
}
```

### Lifecycle-Aware Cleanup

```kotlin
DisposableEffect(Unit) {
    controller.glideTypingDetector.registerListener(controller)
    onDispose {
        controller.glideTypingDetector.unregisterListener(controller)
        resetAllKeys()
    }
}

DisposableLifecycleEffect(
    onResume = { /* Do nothing */ },
    onPause = { resetAllKeys() },
)
```

### Async Processing

#### Coroutine Scopes

```kotlin
class NlpManager(context: Context) {
    private val scope = CoroutineScope(Dispatchers.Default + SupervisorJob())

    fun suggest(subtype: Subtype, content: EditorContent) {
        scope.launch {
            // Heavy NLP processing off main thread
            val suggestions = getSuggestionProvider(subtype).suggest(...)
            // Update UI on main thread
            withContext(Dispatchers.Main) {
                activeCandidates.clear()
                activeCandidates.addAll(suggestions)
            }
        }
    }
}
```

#### IO Operations

```kotlin
private val ioScope = CoroutineScope(Dispatchers.IO + SupervisorJob())

fun loadDictionary() = ioScope.launch {
    val data = withContext(Dispatchers.IO) {
        // File I/O on IO dispatcher
        File("dictionary.txt").readText()
    }
    // Process data
}
```

## Code Examples

### Optimized State Management

```kotlin
@Composable
fun OptimizedKeyboardView() {
    // Good: Remembers state across recompositions
    val state by remember { keyboardManager.activeState }.collectAsState()

    // Better: Use derivedStateOf for computed values
    val shouldShowPopup by remember {
        derivedStateOf {
            state.isPopupVisible && state.activeKey != null
        }
    }
}
```

### Efficient Event Processing

```kotlin
class TouchEventProcessor {
    private val eventQueue = Channel<MotionEvent>(capacity = 64)
    private val scope = CoroutineScope(Dispatchers.Default)

    init {
        scope.launch {
            for (event in eventQueue) {
                processEvent(event)
                event.recycle() // Recycle to reduce allocations
            }
        }
    }

    fun onTouchEvent(event: MotionEvent) {
        val clonedEvent = MotionEvent.obtain(event)
        eventQueue.trySend(clonedEvent)
    }
}
```

### Memory-Efficient Caching

```kotlin
class DictionaryCache {
    private val cache = LruCache<String, List<String>>(maxSize = 100)

    fun getSuggestions(prefix: String): List<String> {
        return cache.get(prefix) ?: run {
            val suggestions = computeSuggestions(prefix)
            cache.put(prefix, suggestions)
            suggestions
        }
    }
}
```

## Best Practices

### 1. Profile Before Optimizing

```kotlin
val startTime = System.nanoTime()
performOperation()
val duration = (System.nanoTime() - startTime) / 1_000_000
flogDebug { "Operation took ${duration}ms" }
```

### 2. Minimize Allocations in Hot Paths

```kotlin
// Good: Reuse objects
private val tempPoint = PointF()

fun onTouchMove(event: MotionEvent) {
    tempPoint.set(event.x, event.y)
    processPoint(tempPoint)
}
```

### 3. Use Appropriate Dispatchers

```kotlin
// CPU-intensive work
scope.launch(Dispatchers.Default) { complexCalculation() }

// File I/O
scope.launch(Dispatchers.IO) { file.readText() }

// UI updates
scope.launch(Dispatchers.Main) { textView.text = "Updated" }
```

### 4. Implement Proper Cancellation

```kotlin
class CancellableOperation {
    private var job: Job? = null

    fun start() {
        job = scope.launch {
            try {
                while (isActive) {
                    performWork()
                    delay(100)
                }
            } catch (e: CancellationException) {
                cleanup()
                throw e
            }
        }
    }

    fun cancel() {
        job?.cancel()
    }
}
```

## Common Patterns

### Lazy Initialization

```kotlin
class ExpensiveResource {
    companion object {
        val instance by lazy {
            ExpensiveResource().apply { initialize() }
        }
    }
}
```

### Batch Processing

```kotlin
class BatchProcessor<T> {
    private val batch = mutableListOf<T>()
    private val batchSize = 10

    fun add(item: T) {
        batch.add(item)
        if (batch.size >= batchSize) {
            processBatch()
        }
    }
}
```

## Troubleshooting

### High Touch Latency

**Solutions**:
- Enable hardware acceleration
- Reduce work on main thread
- Optimize touch event processing
- Profile with systrace

### Memory Leaks

**Solutions**:
- Use LeakCanary for detection
- Properly cancel coroutines
- Unregister listeners in onDispose
- Clear caches periodically

### Janky Animations

**Solutions**:
- Use Compose animations
- Reduce recomposition scope
- Optimize drawing operations
- Check GPU overdraw

## Related Topics

- [Touch Handling & Gestures](../technical/touch-gestures.md) - Touch event processing
- [Custom UI Components](../technical/custom-ui.md) - Compose optimization
- [Input Processing Pipeline](../technical/input-pipeline.md) - Input flow
- [Design Patterns](./design-patterns.md) - Architectural patterns

## Next Steps

- Profile your keyboard with Android Profiler
- Implement caching for frequently accessed data
- Optimize Compose recompositions
- Review [Jetpack Compose Performance](https://developer.android.com/jetpack/compose/performance)

---

**Note**: This documentation is continuously being improved. Contributions are welcome!
```
