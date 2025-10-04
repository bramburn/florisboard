# Tutorial 3: Handling Touch Input

## Introduction

In this tutorial, we'll implement advanced touch handling including:
- Raw touch event processing
- Multi-touch support
- Long-press detection
- Popup keys
- Visual feedback
- Gesture detection basics

## Prerequisites

Complete [Tutorial 2: Advanced Keyboard UI](./tutorial-02-keyboard-ui.md) first.

## Understanding Touch Events

Android provides touch events through `MotionEvent`. For keyboards, we need to:
1. Capture touch events from Compose
2. Map touch coordinates to keys
3. Handle touch down, move, and up events
4. Support multiple simultaneous touches (multi-touch)
5. Detect long presses for popup keys

## Step 1: Create Touch Event Handler

**`TouchEventHandler.kt`**

```kotlin
package com.example.mykeyboard

import android.view.MotionEvent
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import kotlinx.coroutines.*

/**
 * Handles touch events for the keyboard.
 */
class TouchEventHandler(
    private val scope: CoroutineScope,
    private val onKeyDown: (KeyData) -> Unit,
    private val onKeyUp: (KeyData) -> Unit,
    private val onLongPress: (KeyData) -> Boolean
) {
    // Map of pointer ID to active key
    private val activePointers = mutableMapOf<Int, PointerInfo>()
    
    // Long press delay in milliseconds
    private val longPressDelay = 500L
    
    /**
     * Information about an active pointer.
     */
    private data class PointerInfo(
        val key: KeyData,
        val initialPosition: Offset,
        var longPressJob: Job? = null,
        var hasLongPressed: Boolean = false
    )
    
    /**
     * Process a touch event.
     */
    fun onTouchEvent(
        event: MotionEvent,
        keyBounds: Map<KeyData, Rect>
    ): Boolean {
        when (event.actionMasked) {
            MotionEvent.ACTION_DOWN,
            MotionEvent.ACTION_POINTER_DOWN -> {
                handleTouchDown(event, keyBounds)
            }
            MotionEvent.ACTION_MOVE -> {
                handleTouchMove(event, keyBounds)
            }
            MotionEvent.ACTION_UP,
            MotionEvent.ACTION_POINTER_UP -> {
                handleTouchUp(event)
            }
            MotionEvent.ACTION_CANCEL -> {
                handleTouchCancel()
            }
        }
        return true
    }
    
    /**
     * Handle touch down event.
     */
    private fun handleTouchDown(
        event: MotionEvent,
        keyBounds: Map<KeyData, Rect>
    ) {
        val pointerIndex = event.actionIndex
        val pointerId = event.getPointerId(pointerIndex)
        val position = Offset(
            event.getX(pointerIndex),
            event.getY(pointerIndex)
        )
        
        // Find which key was touched
        val key = findKeyAtPosition(position, keyBounds) ?: return
        
        // Create pointer info
        val pointerInfo = PointerInfo(key, position)
        activePointers[pointerId] = pointerInfo
        
        // Trigger key down callback
        onKeyDown(key)
        
        // Start long press timer if key has popup keys
        if (key.popupKeys != null && key.popupKeys.isNotEmpty()) {
            pointerInfo.longPressJob = scope.launch {
                delay(longPressDelay)
                pointerInfo.hasLongPressed = true
                onLongPress(key)
            }
        }
    }
    
    /**
     * Handle touch move event.
     */
    private fun handleTouchMove(
        event: MotionEvent,
        keyBounds: Map<KeyData, Rect>
    ) {
        // Check each active pointer
        for (pointerIndex in 0 until event.pointerCount) {
            val pointerId = event.getPointerId(pointerIndex)
            val pointerInfo = activePointers[pointerId] ?: continue
            
            val position = Offset(
                event.getX(pointerIndex),
                event.getY(pointerIndex)
            )
            
            // Check if finger moved off the key
            val currentKey = findKeyAtPosition(position, keyBounds)
            if (currentKey != pointerInfo.key) {
                // Finger moved off key - cancel long press
                pointerInfo.longPressJob?.cancel()
            }
        }
    }
    
    /**
     * Handle touch up event.
     */
    private fun handleTouchUp(event: MotionEvent) {
        val pointerIndex = event.actionIndex
        val pointerId = event.getPointerId(pointerIndex)
        val pointerInfo = activePointers.remove(pointerId) ?: return
        
        // Cancel long press timer
        pointerInfo.longPressJob?.cancel()
        
        // Only trigger key up if not long pressed
        if (!pointerInfo.hasLongPressed) {
            onKeyUp(pointerInfo.key)
        }
    }
    
    /**
     * Handle touch cancel event.
     */
    private fun handleTouchCancel() {
        // Cancel all active pointers
        activePointers.values.forEach { it.longPressJob?.cancel() }
        activePointers.clear()
    }
    
    /**
     * Find which key is at the given position.
     */
    private fun findKeyAtPosition(
        position: Offset,
        keyBounds: Map<KeyData, Rect>
    ): KeyData? {
        return keyBounds.entries.firstOrNull { (_, bounds) ->
            bounds.contains(position)
        }?.key
    }
}
```

## Step 2: Integrate Touch Handling with Compose

**Update `AdvancedKeyboardUI.kt`:**

```kotlin
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.*
import androidx.compose.runtime.*
import androidx.compose.ui.ExperimentalComposeUiApi
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.input.pointer.pointerInteropFilter
import androidx.compose.ui.layout.boundsInWindow
import androidx.compose.ui.layout.onGloballyPositioned
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.lifecycle.lifecycleScope

@OptIn(ExperimentalComposeUiApi::class)
@Composable
fun AdvancedKeyboardUI(
    state: KeyboardState,
    onKeyPress: (KeyData) -> Unit
) {
    val lifecycleOwner = LocalLifecycleOwner.current
    val scope = lifecycleOwner.lifecycleScope
    
    // Track key bounds for touch detection
    val keyBounds = remember { mutableStateMapOf<KeyData, Rect>() }
    
    // Track pressed keys for visual feedback
    var pressedKeys by remember { mutableStateOf(setOf<KeyData>()) }
    
    // Create touch event handler
    val touchHandler = remember {
        TouchEventHandler(
            scope = scope,
            onKeyDown = { key ->
                pressedKeys = pressedKeys + key
            },
            onKeyUp = { key ->
                pressedKeys = pressedKeys - key
                onKeyPress(key)
            },
            onLongPress = { key ->
                // Show popup keys
                // We'll implement this in the next step
                true
            }
        )
    }
    
    val layout = when (state.mode) {
        KeyboardMode.CHARACTERS -> KeyboardLayouts.QWERTY
        KeyboardMode.SYMBOLS -> KeyboardLayouts.SYMBOLS
        KeyboardMode.NUMERIC -> KeyboardLayouts.SYMBOLS_EXTENDED
    }
    
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .background(Color(0xFF2C2C2C))
            .padding(4.dp)
            .pointerInteropFilter { event ->
                touchHandler.onTouchEvent(event, keyBounds)
            }
    ) {
        layout.forEach { row ->
            KeyboardRow(
                keys = row,
                state = state,
                pressedKeys = pressedKeys,
                onKeyBoundsChanged = { key, bounds ->
                    keyBounds[key] = bounds
                }
            )
            Spacer(modifier = Modifier.height(4.dp))
        }
    }
}

@Composable
fun KeyboardRow(
    keys: List<KeyData>,
    state: KeyboardState,
    pressedKeys: Set<KeyData>,
    onKeyBoundsChanged: (KeyData, Rect) -> Unit
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        keys.forEach { keyData ->
            KeyButton(
                keyData = keyData,
                state = state,
                isPressed = keyData in pressedKeys,
                onKeyBoundsChanged = onKeyBoundsChanged,
                modifier = Modifier.weight(keyData.width)
            )
        }
    }
}
```

## Step 3: Enhanced Key Button with Visual Feedback

**Update `KeyButton.kt`:**

```kotlin
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.scale
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.boundsInWindow
import androidx.compose.ui.layout.onGloballyPositioned
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

@Composable
fun KeyButton(
    keyData: KeyData,
    state: KeyboardState,
    isPressed: Boolean,
    onKeyBoundsChanged: (KeyData, Rect) -> Unit,
    modifier: Modifier = Modifier
) {
    // Animate press state
    val scale by animateFloatAsState(
        targetValue = if (isPressed) 0.95f else 1f,
        label = "key_scale"
    )
    
    val backgroundColor by animateColorAsState(
        targetValue = when {
            isPressed -> Color(0xFF5294E2)
            keyData.type == KeyType.SHIFT && state.shiftState != ShiftState.UNSHIFTED -> 
                Color(0xFF4A90E2)
            else -> Color(0xFF3C3C3C)
        },
        label = "key_background"
    )
    
    // Determine label to display
    val label = when {
        keyData.type == KeyType.CHARACTER && state.isShifted() && keyData.shiftedLabel != null ->
            keyData.shiftedLabel
        else -> keyData.label
    }
    
    Box(
        modifier = modifier
            .height(48.dp)
            .scale(scale)
            .shadow(
                elevation = if (isPressed) 1.dp else 4.dp,
                shape = RoundedCornerShape(6.dp)
            )
            .background(
                color = backgroundColor,
                shape = RoundedCornerShape(6.dp)
            )
            .onGloballyPositioned { coordinates ->
                onKeyBoundsChanged(keyData, coordinates.boundsInWindow())
            },
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = label,
            color = Color.White,
            fontSize = when (keyData.type) {
                KeyType.SPACE -> 12.sp
                else -> 18.sp
            },
            fontWeight = FontWeight.Medium
        )
        
        // Show shift indicator for caps lock
        if (keyData.type == KeyType.SHIFT && state.shiftState == ShiftState.CAPS_LOCK) {
            Box(
                modifier = Modifier
                    .size(6.dp)
                    .align(Alignment.TopEnd)
                    .padding(4.dp)
                    .background(Color.Green, shape = RoundedCornerShape(3.dp))
            )
        }
    }
}
```

## Step 4: Add Haptic Feedback

**Update `MyKeyboardService.kt`:**

```kotlin
import android.os.VibrationEffect
import android.os.Vibrator
import androidx.core.content.getSystemService

class MyKeyboardService : LifecycleInputMethodService() {
    
    private val vibrator by lazy { getSystemService<Vibrator>() }
    
    private fun performHapticFeedback() {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            vibrator?.vibrate(
                VibrationEffect.createOneShot(
                    10, // duration in ms
                    VibrationEffect.DEFAULT_AMPLITUDE
                )
            )
        } else {
            @Suppress("DEPRECATION")
            vibrator?.vibrate(10)
        }
    }
    
    private fun handleKeyPress(keyData: KeyData) {
        // Perform haptic feedback
        performHapticFeedback()
        
        // Rest of the key handling code...
        when (keyData.type) {
            // ... existing code
        }
    }
}
```

## Step 5: Add Sound Feedback

**`SoundFeedback.kt`:**

```kotlin
package com.example.mykeyboard

import android.content.Context
import android.media.AudioManager
import androidx.core.content.getSystemService

class SoundFeedback(context: Context) {
    private val audioManager = context.getSystemService<AudioManager>()
    
    fun playKeyClick() {
        audioManager?.playSoundEffect(AudioManager.FX_KEY_CLICK)
    }
    
    fun playKeyDelete() {
        audioManager?.playSoundEffect(AudioManager.FX_KEYPRESS_DELETE)
    }
    
    fun playKeyReturn() {
        audioManager?.playSoundEffect(AudioManager.FX_KEYPRESS_RETURN)
    }
    
    fun playKeySpace() {
        audioManager?.playSoundEffect(AudioManager.FX_KEYPRESS_SPACEBAR)
    }
}
```

## Testing Touch Input

1. Build and install the updated keyboard
2. Test the following:
   - ✅ Single key presses
   - ✅ Multiple simultaneous key presses
   - ✅ Visual feedback (key press animation)
   - ✅ Haptic feedback (vibration)
   - ✅ Sound feedback
   - ✅ Long press detection (we'll add popup UI in next tutorial)

## Summary

In this tutorial, you learned:
- ✅ How to handle raw touch events in Compose
- ✅ How to implement multi-touch support
- ✅ How to detect long presses
- ✅ How to add visual feedback with animations
- ✅ How to implement haptic and sound feedback
- ✅ How to map touch coordinates to keys

**Next**: [Tutorial 4: Text Input and InputConnection](./tutorial-04-text-input.md)

