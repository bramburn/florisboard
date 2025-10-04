# Tutorial 2: Building Advanced Keyboard UI

## Introduction

In this tutorial, we'll enhance our basic keyboard with:
- Multiple keyboard modes (letters, symbols, numbers)
- Shift key functionality
- Better key layout and styling
- Popup keys for long-press
- Visual feedback for key presses

## Prerequisites

Complete [Tutorial 1: Building From Scratch](./build-from-scratch.md) first.

## Step 1: Define Keyboard State

First, let's create a state management system for our keyboard.

**`KeyboardState.kt`**

```kotlin
package com.example.mykeyboard

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue

/**
 * Represents the current mode of the keyboard.
 */
enum class KeyboardMode {
    CHARACTERS,  // Letters (a-z)
    SYMBOLS,     // Symbols (!@#$%^&*())
    NUMERIC      // Numbers (0-9)
}

/**
 * Represents the shift state of the keyboard.
 */
enum class ShiftState {
    UNSHIFTED,   // lowercase
    SHIFTED,     // Uppercase (one character)
    CAPS_LOCK    // UPPERCASE (locked)
}

/**
 * Manages the state of the keyboard.
 */
class KeyboardState {
    var mode by mutableStateOf(KeyboardMode.CHARACTERS)
        private set
    
    var shiftState by mutableStateOf(ShiftState.UNSHIFTED)
        private set
    
    /**
     * Switch to a different keyboard mode.
     */
    fun setMode(newMode: KeyboardMode) {
        mode = newMode
    }
    
    /**
     * Toggle shift state.
     * UNSHIFTED → SHIFTED → CAPS_LOCK → UNSHIFTED
     */
    fun toggleShift() {
        shiftState = when (shiftState) {
            ShiftState.UNSHIFTED -> ShiftState.SHIFTED
            ShiftState.SHIFTED -> ShiftState.CAPS_LOCK
            ShiftState.CAPS_LOCK -> ShiftState.UNSHIFTED
        }
    }
    
    /**
     * Reset shift to unshifted after typing a character.
     * Only if not in CAPS_LOCK mode.
     */
    fun consumeShift() {
        if (shiftState == ShiftState.SHIFTED) {
            shiftState = ShiftState.UNSHIFTED
        }
    }
    
    /**
     * Check if keyboard is currently shifted.
     */
    fun isShifted(): Boolean {
        return shiftState != ShiftState.UNSHIFTED
    }
}
```

## Step 2: Create Key Data Model

**`KeyData.kt`**

```kotlin
package com.example.mykeyboard

/**
 * Represents a single key on the keyboard.
 */
data class KeyData(
    val code: Int,                    // Key code (e.g., 'a'.code)
    val label: String,                // Display label
    val shiftedLabel: String? = null, // Label when shifted
    val type: KeyType = KeyType.CHARACTER,
    val width: Float = 1f,            // Relative width (1f = normal key)
    val popupKeys: List<String>? = null // Long-press popup keys
)

/**
 * Type of key.
 */
enum class KeyType {
    CHARACTER,   // Regular character key
    SHIFT,       // Shift key
    DELETE,      // Backspace/delete
    ENTER,       // Enter/return
    SPACE,       // Space bar
    MODE_CHANGE, // Switch keyboard mode
    SYMBOL       // Symbol key
}

/**
 * Predefined keyboard layouts.
 */
object KeyboardLayouts {
    
    /**
     * QWERTY character layout.
     */
    val QWERTY = listOf(
        // Row 1
        listOf(
            KeyData('q'.code, "q", "Q", popupKeys = listOf("1")),
            KeyData('w'.code, "w", "W", popupKeys = listOf("2")),
            KeyData('e'.code, "e", "E", popupKeys = listOf("3", "é", "è", "ê", "ë")),
            KeyData('r'.code, "r", "R", popupKeys = listOf("4")),
            KeyData('t'.code, "t", "T", popupKeys = listOf("5")),
            KeyData('y'.code, "y", "Y", popupKeys = listOf("6")),
            KeyData('u'.code, "u", "U", popupKeys = listOf("7", "ú", "ù", "û", "ü")),
            KeyData('i'.code, "i", "I", popupKeys = listOf("8", "í", "ì", "î", "ï")),
            KeyData('o'.code, "o", "O", popupKeys = listOf("9", "ó", "ò", "ô", "ö")),
            KeyData('p'.code, "p", "P", popupKeys = listOf("0")),
        ),
        // Row 2
        listOf(
            KeyData('a'.code, "a", "A", popupKeys = listOf("á", "à", "â", "ä", "ã")),
            KeyData('s'.code, "s", "S", popupKeys = listOf("ß", "ś")),
            KeyData('d'.code, "d", "D"),
            KeyData('f'.code, "f", "F"),
            KeyData('g'.code, "g", "G"),
            KeyData('h'.code, "h", "H"),
            KeyData('j'.code, "j", "J"),
            KeyData('k'.code, "k", "K"),
            KeyData('l'.code, "l", "L"),
        ),
        // Row 3
        listOf(
            KeyData(-1, "⇧", type = KeyType.SHIFT, width = 1.5f),
            KeyData('z'.code, "z", "Z"),
            KeyData('x'.code, "x", "X"),
            KeyData('c'.code, "c", "C", popupKeys = listOf("ç")),
            KeyData('v'.code, "v", "V"),
            KeyData('b'.code, "b", "B"),
            KeyData('n'.code, "n", "N", popupKeys = listOf("ñ")),
            KeyData('m'.code, "m", "M"),
            KeyData(-2, "⌫", type = KeyType.DELETE, width = 1.5f),
        ),
        // Row 4
        listOf(
            KeyData(-3, "?123", type = KeyType.MODE_CHANGE, width = 1.5f),
            KeyData(','.code, ",", type = KeyType.SYMBOL),
            KeyData(' '.code, "space", type = KeyType.SPACE, width = 4f),
            KeyData('.'.code, ".", type = KeyType.SYMBOL),
            KeyData(-4, "↵", type = KeyType.ENTER, width = 1.5f),
        ),
    )
    
    /**
     * Symbols layout.
     */
    val SYMBOLS = listOf(
        // Row 1
        listOf(
            KeyData('1'.code, "1"),
            KeyData('2'.code, "2"),
            KeyData('3'.code, "3"),
            KeyData('4'.code, "4"),
            KeyData('5'.code, "5"),
            KeyData('6'.code, "6"),
            KeyData('7'.code, "7"),
            KeyData('8'.code, "8"),
            KeyData('9'.code, "9"),
            KeyData('0'.code, "0"),
        ),
        // Row 2
        listOf(
            KeyData('@'.code, "@"),
            KeyData('#'.code, "#"),
            KeyData('$'.code, "$"),
            KeyData('_'.code, "_"),
            KeyData('&'.code, "&"),
            KeyData('-'.code, "-"),
            KeyData('+'.code, "+"),
            KeyData('('.code, "("),
            KeyData(')'.code, ")"),
        ),
        // Row 3
        listOf(
            KeyData(-5, "=\\<", type = KeyType.MODE_CHANGE, width = 1.5f),
            KeyData('*'.code, "*"),
            KeyData('"'.code, "\""),
            KeyData('\''.code, "'"),
            KeyData(':'.code, ":"),
            KeyData(';'.code, ";"),
            KeyData('!'.code, "!"),
            KeyData('?'.code, "?"),
            KeyData(-2, "⌫", type = KeyType.DELETE, width = 1.5f),
        ),
        // Row 4
        listOf(
            KeyData(-6, "ABC", type = KeyType.MODE_CHANGE, width = 1.5f),
            KeyData(','.code, ",", type = KeyType.SYMBOL),
            KeyData(' '.code, "space", type = KeyType.SPACE, width = 4f),
            KeyData('.'.code, ".", type = KeyType.SYMBOL),
            KeyData(-4, "↵", type = KeyType.ENTER, width = 1.5f),
        ),
    )
    
    /**
     * Extended symbols layout.
     */
    val SYMBOLS_EXTENDED = listOf(
        // Row 1
        listOf(
            KeyData('~'.code, "~"),
            KeyData('`'.code, "`"),
            KeyData('|'.code, "|"),
            KeyData('•'.code, "•"),
            KeyData('√'.code, "√"),
            KeyData('π'.code, "π"),
            KeyData('÷'.code, "÷"),
            KeyData('×'.code, "×"),
            KeyData('¶'.code, "¶"),
            KeyData('∆'.code, "∆"),
        ),
        // Row 2
        listOf(
            KeyData('£'.code, "£"),
            KeyData('¢'.code, "¢"),
            KeyData('€'.code, "€"),
            KeyData('¥'.code, "¥"),
            KeyData('^'.code, "^"),
            KeyData('°'.code, "°"),
            KeyData('='.code, "="),
            KeyData('{'.code, "{"),
            KeyData('}'.code, "}"),
        ),
        // Row 3
        listOf(
            KeyData(-7, "?123", type = KeyType.MODE_CHANGE, width = 1.5f),
            KeyData('\\'.code, "\\"),
            KeyData('©'.code, "©"),
            KeyData('®'.code, "®"),
            KeyData('™'.code, "™"),
            KeyData('℅'.code, "℅"),
            KeyData('['.code, "["),
            KeyData(']'.code, "]"),
            KeyData(-2, "⌫", type = KeyType.DELETE, width = 1.5f),
        ),
        // Row 4
        listOf(
            KeyData(-6, "ABC", type = KeyType.MODE_CHANGE, width = 1.5f),
            KeyData('<'.code, "<", type = KeyType.SYMBOL),
            KeyData(' '.code, "space", type = KeyType.SPACE, width = 4f),
            KeyData('>'.code, ">", type = KeyType.SYMBOL),
            KeyData(-4, "↵", type = KeyType.ENTER, width = 1.5f),
        ),
    )
}
```

## Step 3: Update MyKeyboardService

**Update `MyKeyboardService.kt`:**

```kotlin
class MyKeyboardService : LifecycleInputMethodService() {
    
    private var inputView: View? = null
    private val keyboardState = KeyboardState()
    
    override fun onCreateInputView(): View {
        installViewTreeOwners()
        val composeView = KeyboardComposeView()
        inputView = composeView
        return composeView
    }
    
    private fun handleKeyPress(keyData: KeyData) {
        when (keyData.type) {
            KeyType.CHARACTER, KeyType.SYMBOL -> {
                val char = if (keyboardState.isShifted() && keyData.shiftedLabel != null) {
                    keyData.shiftedLabel
                } else {
                    keyData.label
                }
                currentInputConnection?.commitText(char, 1)
                keyboardState.consumeShift()
            }
            KeyType.SPACE -> {
                currentInputConnection?.commitText(" ", 1)
                keyboardState.consumeShift()
            }
            KeyType.DELETE -> {
                currentInputConnection?.deleteSurroundingText(1, 0)
            }
            KeyType.ENTER -> {
                currentInputConnection?.performEditorAction(
                    currentInputEditorInfo.imeOptions and EditorInfo.IME_MASK_ACTION
                )
            }
            KeyType.SHIFT -> {
                keyboardState.toggleShift()
            }
            KeyType.MODE_CHANGE -> {
                when (keyData.label) {
                    "?123" -> keyboardState.setMode(KeyboardMode.SYMBOLS)
                    "=\\<" -> keyboardState.setMode(KeyboardMode.NUMERIC)
                    "ABC" -> keyboardState.setMode(KeyboardMode.CHARACTERS)
                }
            }
        }
    }
    
    private inner class KeyboardComposeView : AbstractComposeView(this@MyKeyboardService) {
        @Composable
        override fun Content() {
            MaterialTheme {
                AdvancedKeyboardUI(
                    state = keyboardState,
                    onKeyPress = { keyData -> handleKeyPress(keyData) }
                )
            }
        }
    }
}
```

## Step 4: Create Advanced Keyboard UI

**`AdvancedKeyboardUI.kt`**

```kotlin
@Composable
fun AdvancedKeyboardUI(
    state: KeyboardState,
    onKeyPress: (KeyData) -> Unit
) {
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
    ) {
        layout.forEach { row ->
            KeyboardRow(
                keys = row,
                state = state,
                onKeyPress = onKeyPress
            )
            Spacer(modifier = Modifier.height(4.dp))
        }
    }
}

@Composable
fun KeyboardRow(
    keys: List<KeyData>,
    state: KeyboardState,
    onKeyPress: (KeyData) -> Unit
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        keys.forEach { keyData ->
            KeyButton(
                keyData = keyData,
                state = state,
                onKeyPress = onKeyPress,
                modifier = Modifier.weight(keyData.width)
            )
        }
    }
}
```

Continue to [Tutorial 3: Touch Input](./tutorial-03-touch-input.md) to learn about advanced touch handling and gestures.

## Summary

In this tutorial, you learned:
- ✅ How to manage keyboard state (mode, shift)
- ✅ How to define keyboard layouts with data models
- ✅ How to create multiple keyboard modes
- ✅ How to handle different key types
- ✅ How to implement shift and caps lock

**Next**: [Tutorial 3: Handling Touch Input](./tutorial-03-touch-input.md)

