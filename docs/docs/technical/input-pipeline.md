# Input Processing Pipeline

## Overview

The input processing pipeline in FlorisBoard transforms raw touch events into text output through multiple stages of processing. Understanding this pipeline is crucial for implementing custom keyboards or debugging input issues.

## Pipeline Stages

```
┌─────────────────────────────────────────────────────────────┐
│                    Touch Event                               │
│                  (MotionEvent from Android)                  │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              Stage 1: Event Capture                          │
│              (pointerInteropFilter)                          │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              Stage 2: Event Queuing                          │
│              (TouchEventChannel)                             │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              Stage 3: Gesture Detection                      │
│              (SwipeGestureDetector, GlideTypingDetector)     │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ├─► Swipe Gesture → Execute Action
                         │
                         ├─► Glide Gesture → Generate Word
                         │
                         └─► Regular Touch → Continue
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────┐
│              Stage 4: Touch Handling                         │
│              (onTouchDown, onTouchMove, onTouchUp)           │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              Stage 5: Key Hit Detection                      │
│              (findKeyByCoords)                               │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              Stage 6: Event Dispatching                      │
│              (InputEventDispatcher)                          │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ├─► sendDown() → Long Press Timer
                         ├─► sendUp() → Key Release
                         └─► sendCancel() → Cancel Action
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────┐
│              Stage 7: Key Event Processing                   │
│              (KeyboardManager.onInputKeyUp)                  │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              Stage 8: Action Execution                       │
│              (handleCharacterInput, handleSpecialKey)        │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              Stage 9: Editor Interaction                     │
│              (EditorInstance.commitChar, etc.)               │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              Stage 10: InputConnection                       │
│              (commitText, deleteSurroundingText, etc.)       │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                    Target Application                        │
└─────────────────────────────────────────────────────────────┘
```

## Stage 1: Event Capture

Touch events are captured using Compose's `pointerInteropFilter` modifier.

```kotlin
// TextKeyboardLayout.kt
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
                    touchEventChannel
                        .trySend(clonedEvent)
                        .onFailure {
                            clonedEvent.recycle()
                        }
                    return@pointerInteropFilter true
                }
            }
            return@pointerInteropFilter false
        }
)
```

**Key Points:**
- Events are cloned to prevent memory issues
- Channel-based communication for async processing
- Events are recycled if channel is full

## Stage 2: Event Queuing

Events are queued in a channel for sequential processing.

```kotlin
private val touchEventChannel = Channel<MotionEvent>(
    capacity = Channel.UNLIMITED,
    onBufferOverflow = BufferOverflow.DROP_OLDEST
)

LaunchedEffect(Unit) {
    for (event in touchEventChannel) {
        if (!isActive) break
        controller.onTouchEventInternal(event)
        event.recycle()
    }
}
```

**Benefits:**
- Decouples event capture from processing
- Prevents UI thread blocking
- Handles burst events gracefully

## Stage 3: Gesture Detection

### Swipe Gesture Detection

```kotlin
// SwipeGesture.kt
class Detector(
    private val prefs: FlorisPreferenceStore,
    private val listener: Listener,
) {
    fun onTouchDown(event: MotionEvent, pointer: Pointer) {
        val gesturePointer = GesturePointer(
            id = pointer.id,
            index = pointer.index,
            firstX = ViewUtils.px2dp(event.getX(pointer.index)),
            firstY = ViewUtils.px2dp(event.getY(pointer.index)),
        )
        pointerMap.add(gesturePointer)
    }
    
    fun onTouchMove(event: MotionEvent, pointer: Pointer): Boolean {
        val gesturePointer = pointerMap.findById(pointer.id) ?: return false
        val currentX = ViewUtils.px2dp(event.getX(pointer.index))
        val currentY = ViewUtils.px2dp(event.getY(pointer.index))
        val absDiffX = currentX - gesturePointer.firstX
        val absDiffY = currentY - gesturePointer.firstY
        val thresholdWidth = prefs.gestures.swipeDistanceThreshold.get().dp.value
        
        if (abs(absDiffX) > thresholdWidth || abs(absDiffY) > thresholdWidth) {
            val direction = detectDirection(absDiffX, absDiffY)
            return listener.onSwipe(Event(direction, Type.TOUCH_MOVE, ...))
        }
        return false
    }
}
```

### Glide Typing Detection

```kotlin
// GlideTypingGesture.kt
fun onTouchEvent(event: MotionEvent, initialKey: TextKey?): Boolean {
    when (event.actionMasked) {
        MotionEvent.ACTION_DOWN -> {
            val pointerData = PointerData(
                startTime = System.currentTimeMillis(),
                positions = mutableListOf(Position(event.x, event.y))
            )
            pointerMap[event.getPointerId(0)] = pointerData
        }
        
        MotionEvent.ACTION_MOVE -> {
            val pointerData = pointerMap[event.getPointerId(0)] ?: return false
            val pos = Position(event.x, event.y)
            pointerData.positions.add(pos)
            
            if (pointerData.isActuallyGesture == null) {
                val dist = ViewUtils.px2dp(pointerData.positions[0].dist(pos))
                val time = (System.currentTimeMillis() - pointerData.startTime) + 1
                
                if (dist > keySize && (dist / time) > VELOCITY_THRESHOLD) {
                    pointerData.isActuallyGesture = true
                    listeners.forEach { it.onGlideAddPoint(pos) }
                }
            }
        }
    }
}
```

## Stage 4: Touch Handling

### Pointer Tracking

```kotlin
// TextKeyboardLayoutController.kt
private val pointerMap = PointerMap()

fun onTouchEventInternal(event: MotionEvent) {
    when (event.actionMasked) {
        MotionEvent.ACTION_DOWN -> {
            val pointerId = event.getPointerId(event.actionIndex)
            val pointer = pointerMap.add(pointerId, event.actionIndex)
            if (pointer != null) {
                onTouchDownInternal(event, pointer)
            }
        }
        
        MotionEvent.ACTION_MOVE -> {
            for (pointer in pointerMap) {
                onTouchMoveInternal(event, pointer)
            }
        }
        
        MotionEvent.ACTION_UP -> {
            val pointer = pointerMap.findById(event.getPointerId(event.actionIndex))
            if (pointer != null) {
                onTouchUpInternal(event, pointer)
                pointerMap.remove(pointer.id)
            }
        }
    }
}
```

### Multi-Touch Support

```kotlin
class PointerMap : Iterable<Pointer> {
    private val pointers = mutableListOf<Pointer>()
    
    fun add(id: Int, index: Int): Pointer? {
        if (pointers.size >= MAX_POINTER_COUNT) return null
        val pointer = Pointer(id, index)
        pointers.add(pointer)
        return pointer
    }
    
    fun findById(id: Int): Pointer? {
        return pointers.find { it.id == id }
    }
}
```

## Stage 5: Key Hit Detection

```kotlin
private fun findKeyByCoords(x: Float, y: Float): TextKey? {
    for (key in keyboard.keys()) {
        val bounds = key.visibleBounds
        if (bounds.contains(x, y)) {
            return key
        }
    }
    return null
}

private fun onTouchDownInternal(event: MotionEvent, pointer: Pointer) {
    val key = findKeyByCoords(
        event.getX(pointer.index),
        event.getY(pointer.index)
    )
    
    if (key != null) {
        pointer.activeKey = key
        pointer.initialKey = key
        
        // Visual feedback
        popupUiController.show(key)
        
        // Haptic feedback
        inputFeedbackController.keyPress(key.computedData)
        
        // Send key down event
        inputEventDispatcher.sendDown(
            data = key.computedData,
            onLongPress = { handleLongPress(key) },
            onRepeat = { handleRepeat(key) }
        )
    }
}
```

## Stage 6: Event Dispatching

```kotlin
// InputEventDispatcher.kt
class InputEventDispatcher(
    private val scope: CoroutineScope,
    private val keyEventReceiver: InputKeyEventReceiver?,
) {
    private val pressedKeys = mutableMapOf<Int, PressedKeyInfo>()
    
    fun sendDown(
        data: KeyData,
        onLongPress: () -> Boolean = { false },
        onRepeat: () -> Boolean = { true },
    ) = runBlocking {
        val eventTime = SystemClock.uptimeMillis()
        val pressedKeyInfo = PressedKeyInfo(eventTime).also { info ->
            info.job = scope.launch {
                val longPressDelay = determineLongPressDelay(data)
                delay(longPressDelay)
                
                val longPressResult = withContext(Dispatchers.Main) {
                    onLongPress()
                }
                
                if (longPressResult) {
                    info.blockUp = true
                } else if (repeatableKeyCodes.contains(data.code)) {
                    // Handle key repeat
                    while (isActive) {
                        delay(repeatDelay)
                        withContext(Dispatchers.Main) {
                            onRepeat()
                        }
                    }
                }
            }
        }
        
        pressedKeys[data.code] = pressedKeyInfo
        keyEventReceiver?.onInputKeyDown(data)
    }
    
    fun sendUp(data: KeyData) = runBlocking {
        val pressedKeyInfo = pressedKeys.remove(data.code)
        pressedKeyInfo?.cancelJobs()
        
        if (pressedKeyInfo?.blockUp != true) {
            keyEventReceiver?.onInputKeyUp(data)
        } else {
            keyEventReceiver?.onInputKeyCancel(data)
        }
    }
}
```

## Stage 7: Key Event Processing

```kotlin
// KeyboardManager.kt
override fun onInputKeyUp(data: KeyData) {
    when (data.type) {
        KeyType.CHARACTER, KeyType.NUMERIC -> {
            val text = data.asString(isForDisplay = false)
            editorInstance.commitChar(text)
        }
        
        KeyType.ENTER_EDITING -> {
            handleEnter()
        }
        
        KeyType.DELETE -> {
            handleBackwardDelete(OperationUnit.CHARACTERS)
        }
        
        KeyType.SHIFT -> {
            handleShift()
        }
        
        KeyType.FUNCTION -> {
            when (data.code) {
                KeyCode.SPACE -> handleSpace()
                KeyCode.LANGUAGE_SWITCH -> handleLanguageSwitch()
                KeyCode.SWITCH_TO_MEDIA_CONTEXT -> {
                    activeState.imeUiMode = ImeUiMode.MEDIA
                }
                // ... more function keys
            }
        }
    }
}
```

## Stage 8: Action Execution

### Character Input

```kotlin
private fun handleCharacterInput(data: KeyData) {
    val text = data.asString(isForDisplay = false)
    
    // Check for auto-commit of suggestions
    if (!UCharacter.isUAlphabetic(UCharacter.codePointAt(text, 0))) {
        nlpManager.getAutoCommitCandidate()?.let { candidate ->
            commitCandidate(candidate)
        }
    }
    
    // Commit character
    editorInstance.commitChar(text)
    
    // Update shift state
    if (activeState.inputShiftState != InputShiftState.CAPS_LOCK) {
        activeState.inputShiftState = InputShiftState.UNSHIFTED
    }
}
```

### Special Key Handling

```kotlin
private fun handleBackwardDelete(unit: OperationUnit) {
    when {
        editorInstance.massSelection.isActive -> {
            editorInstance.massSelection.deleteAll()
        }
        editorInstance.selection.isSelectionMode -> {
            editorInstance.deleteBackwards()
        }
        else -> {
            when (unit) {
                OperationUnit.CHARACTERS -> editorInstance.deleteBackwards()
                OperationUnit.WORDS -> editorInstance.deleteWordBackwards()
            }
        }
    }
}
```

## Stage 9: Editor Interaction

```kotlin
// EditorInstance.kt
fun commitChar(text: String) {
    val ic = currentInputConnection() ?: return
    
    // Handle phantom space
    if (phantomSpace.isActive) {
        if (text.isNotBlank()) {
            ic.commitText(" ", 1)
        }
        phantomSpace.reset()
    }
    
    // Commit text
    ic.commitText(text, 1)
    
    // Update auto-space state
    autoSpace.updateState(text)
    
    // Request suggestions
    nlpManager.suggest(subtypeManager.activeSubtype, activeContent)
}
```

## Stage 10: InputConnection

```kotlin
// Android InputConnection API
interface InputConnection {
    fun commitText(text: CharSequence, newCursorPosition: Int): Boolean
    fun deleteSurroundingText(beforeLength: Int, afterLength: Int): Boolean
    fun setComposingText(text: CharSequence, newCursorPosition: Int): Boolean
    fun finishComposingText(): Boolean
    fun setSelection(start: Int, end: Int): Boolean
    // ... more methods
}
```

## Performance Optimizations

### 1. Event Batching
- Process multiple move events together
- Reduce recomposition frequency

### 2. Touch Slop
- Ignore small movements
- Reduce false gesture detection

### 3. Debouncing
- Limit suggestion updates
- Prevent excessive processing

### 4. Caching
- Cache key bounds
- Reuse motion events

### 5. Async Processing
- Use coroutines for heavy operations
- Keep UI thread responsive

## Next Steps

- [Touch Handling & Gestures](./touch-gestures.md) - Detailed gesture implementation
- [Custom UI Components](./custom-ui.md) - Keyboard view implementation
- [Text Prediction Engine](./prediction-engine.md) - NLP integration

