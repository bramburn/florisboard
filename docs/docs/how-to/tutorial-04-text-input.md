# Tutorial 4: Text Input and InputConnection

## Introduction

In this tutorial, we'll dive deep into `InputConnection`, the bridge between your keyboard and the text field. You'll learn:
- How InputConnection works
- Advanced text manipulation
- Handling different input types
- Auto-capitalization
- Auto-spacing
- Composing text (for predictive input)

## Prerequisites

Complete [Tutorial 3: Touch Input](./tutorial-03-touch-input.md) first.

## Understanding InputConnection

`InputConnection` is the communication channel between your IME and the application's text field. It provides methods to:
- Insert text (`commitText`)
- Delete text (`deleteSurroundingText`)
- Get text around cursor (`getTextBeforeCursor`, `getTextAfterCursor`)
- Set selection (`setSelection`)
- Handle composing text (`setComposingText`, `finishComposingText`)

## Step 1: Create EditorInstance Manager

This class wraps InputConnection and provides higher-level text manipulation methods.

**`EditorInstance.kt`**

```kotlin
package com.example.mykeyboard

import android.view.inputmethod.EditorInfo
import android.view.inputmethod.InputConnection
import android.view.KeyEvent

/**
 * Manages interaction with the current text editor.
 * Based on FlorisBoard's EditorInstance implementation.
 */
class EditorInstance {
    
    private var inputConnection: InputConnection? = null
    private var editorInfo: EditorInfo? = null
    
    /**
     * Information about the current editor state.
     */
    data class EditorContent(
        val textBeforeCursor: String = "",
        val textAfterCursor: String = "",
        val selectedText: String = "",
        val cursorPosition: Int = 0
    )
    
    /**
     * Start a new input session.
     */
    fun handleStartInput(info: EditorInfo, ic: InputConnection?) {
        this.editorInfo = info
        this.inputConnection = ic
    }
    
    /**
     * End the current input session.
     */
    fun handleFinishInput() {
        this.editorInfo = null
        this.inputConnection = null
    }
    
    /**
     * Get the current editor content.
     */
    fun getContent(maxLength: Int = 100): EditorContent {
        val ic = inputConnection ?: return EditorContent()
        
        val textBefore = ic.getTextBeforeCursor(maxLength, 0)?.toString() ?: ""
        val textAfter = ic.getTextAfterCursor(maxLength, 0)?.toString() ?: ""
        val selected = ic.getSelectedText(0)?.toString() ?: ""
        
        return EditorContent(
            textBeforeCursor = textBefore,
            textAfterCursor = textAfter,
            selectedText = selected,
            cursorPosition = textBefore.length
        )
    }
    
    /**
     * Commit a single character.
     */
    fun commitChar(char: String) {
        val ic = inputConnection ?: return
        ic.commitText(char, 1)
    }
    
    /**
     * Commit text with auto-spacing logic.
     */
    fun commitText(text: String) {
        val ic = inputConnection ?: return
        
        // Check if we need to add a space before
        val content = getContent(10)
        val needsSpaceBefore = shouldAddSpaceBefore(content.textBeforeCursor, text)
        
        val textToCommit = if (needsSpaceBefore) " $text" else text
        ic.commitText(textToCommit, 1)
    }
    
    /**
     * Delete text before the cursor.
     */
    fun deleteBackwards(count: Int = 1) {
        val ic = inputConnection ?: return
        
        // If there's selected text, delete it
        val content = getContent(1)
        if (content.selectedText.isNotEmpty()) {
            ic.commitText("", 1)
            return
        }
        
        // Otherwise delete before cursor
        ic.deleteSurroundingText(count, 0)
    }
    
    /**
     * Delete a word before the cursor.
     */
    fun deleteWordBackwards() {
        val ic = inputConnection ?: return
        val content = getContent(100)
        
        // Find the start of the current word
        val textBefore = content.textBeforeCursor
        var deleteCount = 0
        
        // Skip trailing whitespace
        var i = textBefore.length - 1
        while (i >= 0 && textBefore[i].isWhitespace()) {
            deleteCount++
            i--
        }
        
        // Delete word characters
        while (i >= 0 && !textBefore[i].isWhitespace()) {
            deleteCount++
            i--
        }
        
        if (deleteCount > 0) {
            ic.deleteSurroundingText(deleteCount, 0)
        }
    }
    
    /**
     * Perform the IME action (e.g., search, send, next).
     */
    fun performEnterAction() {
        val ic = inputConnection ?: return
        val info = editorInfo ?: return
        
        val imeAction = info.imeOptions and EditorInfo.IME_MASK_ACTION
        
        when (imeAction) {
            EditorInfo.IME_ACTION_NONE,
            EditorInfo.IME_ACTION_UNSPECIFIED -> {
                // Insert newline
                ic.commitText("\n", 1)
            }
            else -> {
                // Perform the action (search, send, etc.)
                ic.performEditorAction(imeAction)
            }
        }
    }
    
    /**
     * Set composing text (for predictive input).
     */
    fun setComposingText(text: String) {
        val ic = inputConnection ?: return
        ic.setComposingText(text, 1)
    }
    
    /**
     * Finish composing and commit the text.
     */
    fun finishComposingText() {
        val ic = inputConnection ?: return
        ic.finishComposingText()
    }
    
    /**
     * Send a key event (alternative to commitText).
     */
    fun sendKeyEvent(keyCode: Int) {
        val ic = inputConnection ?: return
        ic.sendKeyEvent(KeyEvent(KeyEvent.ACTION_DOWN, keyCode))
        ic.sendKeyEvent(KeyEvent(KeyEvent.ACTION_UP, keyCode))
    }
    
    /**
     * Get the input type of the current editor.
     */
    fun getInputType(): Int {
        return editorInfo?.inputType ?: 0
    }
    
    /**
     * Check if the current editor is a password field.
     */
    fun isPasswordField(): Boolean {
        val inputType = getInputType()
        val variation = inputType and EditorInfo.TYPE_MASK_VARIATION
        
        return variation == EditorInfo.TYPE_TEXT_VARIATION_PASSWORD ||
               variation == EditorInfo.TYPE_TEXT_VARIATION_WEB_PASSWORD ||
               variation == EditorInfo.TYPE_TEXT_VARIATION_VISIBLE_PASSWORD ||
               variation == EditorInfo.TYPE_NUMBER_VARIATION_PASSWORD
    }
    
    /**
     * Check if the current editor is an email field.
     */
    fun isEmailField(): Boolean {
        val inputType = getInputType()
        val variation = inputType and EditorInfo.TYPE_MASK_VARIATION
        return variation == EditorInfo.TYPE_TEXT_VARIATION_EMAIL_ADDRESS ||
               variation == EditorInfo.TYPE_TEXT_VARIATION_WEB_EMAIL_ADDRESS
    }
    
    /**
     * Check if the current editor is a numeric field.
     */
    fun isNumericField(): Boolean {
        val inputType = getInputType()
        val typeClass = inputType and EditorInfo.TYPE_MASK_CLASS
        return typeClass == EditorInfo.TYPE_CLASS_NUMBER ||
               typeClass == EditorInfo.TYPE_CLASS_PHONE
    }
    
    /**
     * Determine if we should add a space before the text.
     */
    private fun shouldAddSpaceBefore(textBefore: String, newText: String): Boolean {
        if (textBefore.isEmpty()) return false
        if (textBefore.last().isWhitespace()) return false
        if (newText.first().isWhitespace()) return false
        
        // Don't add space before punctuation
        val punctuation = setOf('.', ',', '!', '?', ';', ':', ')', ']', '}')
        if (newText.first() in punctuation) return false
        
        return true
    }
}
```

## Step 2: Implement Auto-Capitalization

**`CapitalizationHelper.kt`**

```kotlin
package com.example.mykeyboard

import android.view.inputmethod.EditorInfo

/**
 * Helps determine when to auto-capitalize.
 */
class CapitalizationHelper {
    
    /**
     * Determine if the next character should be capitalized.
     */
    fun shouldCapitalize(
        editorInfo: EditorInfo?,
        content: EditorInstance.EditorContent
    ): Boolean {
        val inputType = editorInfo?.inputType ?: return false
        val capType = inputType and EditorInfo.TYPE_MASK_CLASS
        
        // Check if auto-cap is enabled
        val autoCap = inputType and EditorInfo.TYPE_TEXT_FLAG_CAP_SENTENCES != 0 ||
                     inputType and EditorInfo.TYPE_TEXT_FLAG_CAP_WORDS != 0 ||
                     inputType and EditorInfo.TYPE_TEXT_FLAG_CAP_CHARACTERS != 0
        
        if (!autoCap) return false
        
        // Capitalize all characters
        if (inputType and EditorInfo.TYPE_TEXT_FLAG_CAP_CHARACTERS != 0) {
            return true
        }
        
        // Capitalize each word
        if (inputType and EditorInfo.TYPE_TEXT_FLAG_CAP_WORDS != 0) {
            return shouldCapitalizeWord(content.textBeforeCursor)
        }
        
        // Capitalize sentences
        if (inputType and EditorInfo.TYPE_TEXT_FLAG_CAP_SENTENCES != 0) {
            return shouldCapitalizeSentence(content.textBeforeCursor)
        }
        
        return false
    }
    
    /**
     * Check if we should capitalize the next word.
     */
    private fun shouldCapitalizeWord(textBefore: String): Boolean {
        if (textBefore.isEmpty()) return true
        
        // Capitalize after whitespace
        return textBefore.last().isWhitespace()
    }
    
    /**
     * Check if we should capitalize the next sentence.
     */
    private fun shouldCapitalizeSentence(textBefore: String): Boolean {
        if (textBefore.isEmpty()) return true
        
        // Find the last sentence-ending punctuation
        val sentenceEnders = setOf('.', '!', '?')
        val lastSentenceEnd = textBefore.indexOfLast { it in sentenceEnders }
        
        if (lastSentenceEnd == -1) {
            // No sentence ender found - capitalize if at start
            return textBefore.trim().isEmpty()
        }
        
        // Check if there's only whitespace after the sentence ender
        val afterPunctuation = textBefore.substring(lastSentenceEnd + 1)
        return afterPunctuation.all { it.isWhitespace() }
    }
}
```

## Step 3: Update MyKeyboardService

**Update `MyKeyboardService.kt`:**

```kotlin
class MyKeyboardService : LifecycleInputMethodService() {
    
    private var inputView: View? = null
    private val keyboardState = KeyboardState()
    private val editorInstance = EditorInstance()
    private val capitalizationHelper = CapitalizationHelper()
    private val soundFeedback by lazy { SoundFeedback(this) }
    
    override fun onStartInput(info: EditorInfo?, restarting: Boolean) {
        super.onStartInput(info, restarting)
        if (info != null) {
            editorInstance.handleStartInput(info, currentInputConnection)
            updateKeyboardForInputType(info)
        }
    }
    
    override fun onFinishInput() {
        super.onFinishInput()
        editorInstance.handleFinishInput()
    }
    
    /**
     * Update keyboard based on input type.
     */
    private fun updateKeyboardForInputType(info: EditorInfo) {
        when {
            editorInstance.isNumericField() -> {
                keyboardState.setMode(KeyboardMode.NUMERIC)
            }
            editorInstance.isEmailField() -> {
                keyboardState.setMode(KeyboardMode.CHARACTERS)
                // Could customize layout for email (e.g., show @ key)
            }
            else -> {
                keyboardState.setMode(KeyboardMode.CHARACTERS)
            }
        }
        
        // Update shift state based on auto-cap
        val content = editorInstance.getContent()
        if (capitalizationHelper.shouldCapitalize(info, content)) {
            keyboardState.setShiftState(ShiftState.SHIFTED)
        }
    }
    
    private fun handleKeyPress(keyData: KeyData) {
        // Perform feedback
        performHapticFeedback()
        when (keyData.type) {
            KeyType.SPACE -> soundFeedback.playKeySpace()
            KeyType.DELETE -> soundFeedback.playKeyDelete()
            KeyType.ENTER -> soundFeedback.playKeyReturn()
            else -> soundFeedback.playKeyClick()
        }
        
        when (keyData.type) {
            KeyType.CHARACTER, KeyType.SYMBOL -> {
                var char = if (keyboardState.isShifted() && keyData.shiftedLabel != null) {
                    keyData.shiftedLabel
                } else {
                    keyData.label
                }
                
                editorInstance.commitChar(char)
                keyboardState.consumeShift()
                
                // Auto-capitalize next character if needed
                val content = editorInstance.getContent()
                if (capitalizationHelper.shouldCapitalize(currentInputEditorInfo, content)) {
                    keyboardState.setShiftState(ShiftState.SHIFTED)
                }
            }
            KeyType.SPACE -> {
                editorInstance.commitChar(" ")
                keyboardState.consumeShift()
            }
            KeyType.DELETE -> {
                editorInstance.deleteBackwards()
            }
            KeyType.ENTER -> {
                editorInstance.performEnterAction()
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
}
```

## Step 4: Handle Special Input Types

**`InputTypeHandler.kt`**

```kotlin
package com.example.mykeyboard

import android.view.inputmethod.EditorInfo

/**
 * Handles special behavior for different input types.
 */
class InputTypeHandler {
    
    /**
     * Get suggested keys for the current input type.
     */
    fun getSuggestedKeys(editorInfo: EditorInfo?): List<String> {
        val inputType = editorInfo?.inputType ?: return emptyList()
        val variation = inputType and EditorInfo.TYPE_MASK_VARIATION
        
        return when (variation) {
            EditorInfo.TYPE_TEXT_VARIATION_EMAIL_ADDRESS,
            EditorInfo.TYPE_TEXT_VARIATION_WEB_EMAIL_ADDRESS -> {
                listOf("@", ".com", ".net", ".org")
            }
            EditorInfo.TYPE_TEXT_VARIATION_URI -> {
                listOf("://", ".com", "/", "www.")
            }
            EditorInfo.TYPE_CLASS_PHONE -> {
                listOf("+", "-", "(", ")")
            }
            else -> emptyList()
        }
    }
    
    /**
     * Check if multiline input is allowed.
     */
    fun isMultilineAllowed(editorInfo: EditorInfo?): Boolean {
        val inputType = editorInfo?.inputType ?: return false
        return inputType and EditorInfo.TYPE_TEXT_FLAG_MULTI_LINE != 0
    }
    
    /**
     * Get the action label for the enter key.
     */
    fun getEnterKeyLabel(editorInfo: EditorInfo?): String {
        val imeAction = editorInfo?.imeOptions?.and(EditorInfo.IME_MASK_ACTION) 
            ?: return "↵"
        
        return when (imeAction) {
            EditorInfo.IME_ACTION_SEARCH -> "🔍"
            EditorInfo.IME_ACTION_SEND -> "➤"
            EditorInfo.IME_ACTION_GO -> "→"
            EditorInfo.IME_ACTION_NEXT -> "⇥"
            EditorInfo.IME_ACTION_DONE -> "✓"
            else -> "↵"
        }
    }
}
```

## Testing Text Input

Test your keyboard with different input types:

1. **Regular text field**: Test auto-capitalization
2. **Email field**: Verify @ and .com suggestions
3. **Password field**: Check that suggestions are disabled
4. **Numeric field**: Verify numeric layout appears
5. **Search field**: Check search action button
6. **Multiline field**: Test newline insertion

## Summary

In this tutorial, you learned:
- ✅ How to use InputConnection effectively
- ✅ How to implement EditorInstance for text manipulation
- ✅ How to handle auto-capitalization
- ✅ How to adapt keyboard to different input types
- ✅ How to handle special fields (email, password, etc.)
- ✅ How to implement word deletion
- ✅ How to handle IME actions

**Next**: [Tutorial 5: Layout System](./tutorial-05-layout-system.md)

