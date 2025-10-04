# Building an Android Keyboard From Scratch

## Introduction

This comprehensive tutorial will guide you through building a fully-functional Android IME (Input Method Editor) keyboard from scratch. We'll use FlorisBoard as a reference implementation, showing you real code examples and explaining the rationale behind each decision.

By the end of this tutorial series, you'll understand:
- How to set up an IME service
- How to handle touch input and gestures
- How to manage keyboard layouts
- How to integrate with Android's text input system
- How to implement themes and customization

## Prerequisites

Before starting, ensure you have:
- **Android Studio** (latest stable version)
- **JDK 11** or higher
- **Basic Kotlin knowledge**
- **Understanding of Android development** (Activities, Services, Views)
- **Familiarity with Jetpack Compose** (recommended but not required)

## Tutorial Structure

This tutorial is divided into multiple chapters, each building on the previous:

### Part 1: Foundation
1. [Project Setup](#part-1-project-setup)
2. [Creating the IME Service](#part-2-creating-the-ime-service)
3. [Android Manifest Configuration](#part-3-manifest-configuration)

### Part 2: Core Functionality
4. [Building the Keyboard UI](./tutorial-02-keyboard-ui.md)
5. [Handling Touch Input](./tutorial-03-touch-input.md)
6. [Text Input and InputConnection](./tutorial-04-text-input.md)

### Part 3: Advanced Features
7. [Layout System](./tutorial-05-layout-system.md)
8. [Gesture Support](./tutorial-06-gestures.md)
9. [Theme System](./tutorial-07-themes.md)

### Part 4: Polish and Distribution
10. [Testing and Debugging](./tutorial-08-testing.md)
11. [Performance Optimization](./tutorial-09-performance.md)
12. [Publishing](./tutorial-10-publishing.md)

---

## Part 1: Project Setup

### Step 1: Create a New Android Project

1. Open Android Studio
2. Select **File → New → New Project**
3. Choose **Empty Activity**
4. Configure your project:
   ```
   Name: MyKeyboard
   Package name: com.example.mykeyboard
   Language: Kotlin
   Minimum SDK: API 26 (Android 8.0)
   ```

### Step 2: Configure Build Files

**`build.gradle.kts` (Project level)**

```kotlin
plugins {
    alias(libs.plugins.android.application) apply false
    alias(libs.plugins.kotlin.android) apply false
    alias(libs.plugins.kotlin.plugin.compose) apply false
}
```

**`build.gradle.kts` (App level)**

```kotlin
plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.kotlin.plugin.compose)
}

android {
    namespace = "com.example.mykeyboard"
    compileSdk = 34
    
    defaultConfig {
        applicationId = "com.example.mykeyboard"
        minSdk = 26
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
    }
    
    buildFeatures {
        compose = true
    }
    
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    
    kotlinOptions {
        jvmTarget = "11"
    }
}

dependencies {
    // AndroidX Core
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.7.0")
    
    // Jetpack Compose
    implementation(platform("androidx.compose:compose-bom:2024.02.00"))
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.ui:ui-tooling-preview")
    debugImplementation("androidx.compose.ui:ui-tooling")
    
    // Coroutines
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
}
```

### Step 3: Update gradle.properties

```properties
# Enable AndroidX
android.useAndroidX=true

# Kotlin
kotlin.code.style=official

# Gradle
org.gradle.jvmargs=-Xmx2048m
org.gradle.parallel=true
org.gradle.caching=true
```

---

## Part 2: Creating the IME Service

### Step 1: Create LifecycleInputMethodService

First, we need a base class that makes InputMethodService lifecycle-aware so we can use Compose and coroutines.

**`LifecycleInputMethodService.kt`**

```kotlin
package com.example.mykeyboard

import android.inputmethodservice.InputMethodService
import androidx.annotation.CallSuper
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.LifecycleRegistry
import androidx.lifecycle.ViewModelStore
import androidx.lifecycle.ViewModelStoreOwner
import androidx.lifecycle.setViewTreeLifecycleOwner
import androidx.lifecycle.setViewTreeViewModelStoreOwner
import androidx.savedstate.SavedStateRegistry
import androidx.savedstate.SavedStateRegistryController
import androidx.savedstate.SavedStateRegistryOwner
import androidx.savedstate.setViewTreeSavedStateRegistryOwner

/**
 * Base InputMethodService that implements lifecycle awareness.
 * This allows us to use Jetpack Compose and other lifecycle-aware components.
 */
open class LifecycleInputMethodService : InputMethodService(),
    LifecycleOwner,
    ViewModelStoreOwner,
    SavedStateRegistryOwner {
    
    private val lifecycleRegistry by lazy { LifecycleRegistry(this) }
    private val store by lazy { ViewModelStore() }
    private val savedStateRegistryController by lazy { 
        SavedStateRegistryController.create(this) 
    }
    
    override val lifecycle: Lifecycle
        get() = lifecycleRegistry
    
    override val viewModelStore: ViewModelStore
        get() = store
    
    override val savedStateRegistry: SavedStateRegistry
        get() = savedStateRegistryController.savedStateRegistry
    
    @CallSuper
    override fun onCreate() {
        super.onCreate()
        savedStateRegistryController.performRestore(null)
        lifecycleRegistry.handleLifecycleEvent(Lifecycle.Event.ON_CREATE)
        lifecycleRegistry.handleLifecycleEvent(Lifecycle.Event.ON_START)
    }
    
    /**
     * Call this in onCreateInputView to install lifecycle owners
     * on the window's decor view.
     */
    protected fun installViewTreeOwners() {
        val decorView = window?.window?.decorView ?: return
        decorView.setViewTreeLifecycleOwner(this)
        decorView.setViewTreeViewModelStoreOwner(this)
        decorView.setViewTreeSavedStateRegistryOwner(this)
    }
    
    @CallSuper
    override fun onWindowShown() {
        super.onWindowShown()
        lifecycleRegistry.handleLifecycleEvent(Lifecycle.Event.ON_RESUME)
    }
    
    @CallSuper
    override fun onWindowHidden() {
        super.onWindowHidden()
        lifecycleRegistry.handleLifecycleEvent(Lifecycle.Event.ON_PAUSE)
    }
    
    @CallSuper
    override fun onDestroy() {
        super.onDestroy()
        lifecycleRegistry.handleLifecycleEvent(Lifecycle.Event.ON_STOP)
        lifecycleRegistry.handleLifecycleEvent(Lifecycle.Event.ON_DESTROY)
    }
}
```

**Why this is important:**
- InputMethodService doesn't implement LifecycleOwner by default
- We need lifecycle awareness for Compose and coroutines
- This pattern is used by FlorisBoard and is essential for modern Android development

### Step 2: Create the Main IME Service

**`MyKeyboardService.kt`**

```kotlin
package com.example.mykeyboard

import android.inputmethodservice.InputMethodService
import android.view.View
import android.view.inputmethod.EditorInfo
import android.view.inputmethod.InputConnection
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.AbstractComposeView
import androidx.compose.ui.unit.dp
import androidx.lifecycle.lifecycleScope
import kotlinx.coroutines.launch

/**
 * Main IME Service for our keyboard.
 * This is the entry point for the keyboard functionality.
 */
class MyKeyboardService : LifecycleInputMethodService() {
    
    private var inputView: View? = null
    
    /**
     * Called when the service is created.
     * Initialize any managers or resources here.
     */
    override fun onCreate() {
        super.onCreate()
        // Service is created - initialize resources
    }
    
    /**
     * Called when the input view should be created.
     * This is where we create our keyboard UI.
     */
    override fun onCreateInputView(): View {
        // Install lifecycle owners for Compose
        installViewTreeOwners()
        
        // Create and return our Compose-based keyboard view
        val composeView = KeyboardComposeView()
        inputView = composeView
        return composeView
    }
    
    /**
     * Called when a new input session starts.
     * @param info Information about the text field
     * @param restarting Whether this is a restart of an existing session
     */
    override fun onStartInput(info: EditorInfo?, restarting: Boolean) {
        super.onStartInput(info, restarting)
        // Handle new input session
        // info contains details about the text field (type, hints, etc.)
    }
    
    /**
     * Called when the input view is being shown.
     * @param info Information about the text field
     * @param restarting Whether this is a restart
     */
    override fun onStartInputView(info: EditorInfo?, restarting: Boolean) {
        super.onStartInputView(info, restarting)
        // Keyboard is now visible - update UI if needed
    }
    
    /**
     * Called when the input view is being hidden.
     * @param finishingInput Whether the input session is finishing
     */
    override fun onFinishInputView(finishingInput: Boolean) {
        super.onFinishInputView(finishingInput)
        // Keyboard is being hidden - clean up if needed
    }
    
    /**
     * Called when the input session ends.
     */
    override fun onFinishInput() {
        super.onFinishInput()
        // Input session ended - reset state
    }
    
    /**
     * Called when the service is destroyed.
     */
    override fun onDestroy() {
        super.onDestroy()
        inputView = null
    }
    
    /**
     * Helper function to commit text to the current input field.
     */
    private fun commitText(text: String) {
        currentInputConnection?.commitText(text, 1)
    }
    
    /**
     * Helper function to delete text before the cursor.
     */
    private fun deleteText() {
        currentInputConnection?.deleteSurroundingText(1, 0)
    }
    
    /**
     * Compose view for the keyboard UI.
     */
    private inner class KeyboardComposeView : AbstractComposeView(this@MyKeyboardService) {
        
        @Composable
        override fun Content() {
            MaterialTheme {
                KeyboardUI(
                    onKeyPress = { text -> commitText(text) },
                    onDelete = { deleteText() }
                )
            }
        }
    }
}
```

**Keyboard UI Component:**

```kotlin
/**
 * Simple keyboard UI with basic keys.
 * This is a minimal example - we'll expand this in later tutorials.
 */
@Composable
fun KeyboardUI(
    onKeyPress: (String) -> Unit,
    onDelete: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .background(Color.DarkGray)
            .padding(8.dp)
    ) {
        // First row: Q W E R T Y U I O P
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceEvenly
        ) {
            listOf("Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P").forEach { key ->
                KeyButton(text = key, onClick = { onKeyPress(key.lowercase()) })
            }
        }

        Spacer(modifier = Modifier.height(4.dp))

        // Second row: A S D F G H J K L
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceEvenly
        ) {
            listOf("A", "S", "D", "F", "G", "H", "J", "K", "L").forEach { key ->
                KeyButton(text = key, onClick = { onKeyPress(key.lowercase()) })
            }
        }

        Spacer(modifier = Modifier.height(4.dp))

        // Third row: Z X C V B N M + Delete
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceEvenly
        ) {
            listOf("Z", "X", "C", "V", "B", "N", "M").forEach { key ->
                KeyButton(text = key, onClick = { onKeyPress(key.lowercase()) })
            }
            KeyButton(text = "⌫", onClick = onDelete)
        }

        Spacer(modifier = Modifier.height(4.dp))

        // Fourth row: Space
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.Center
        ) {
            KeyButton(
                text = "Space",
                onClick = { onKeyPress(" ") },
                modifier = Modifier.weight(1f)
            )
        }
    }
}

/**
 * Individual key button component.
 */
@Composable
fun KeyButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Button(
        onClick = onClick,
        modifier = modifier
            .padding(2.dp)
            .height(48.dp)
    ) {
        Text(text = text)
    }
}
```

**Key Concepts Explained:**

1. **Lifecycle Methods:**
   - `onCreate()`: Service initialization
   - `onCreateInputView()`: Create keyboard UI
   - `onStartInput()`: New text field focused
   - `onStartInputView()`: Keyboard shown
   - `onFinishInputView()`: Keyboard hidden
   - `onFinishInput()`: Text field unfocused
   - `onDestroy()`: Service cleanup

2. **InputConnection:**
   - `currentInputConnection`: Communication channel with the text field
   - `commitText()`: Insert text
   - `deleteSurroundingText()`: Delete text

3. **Compose Integration:**
   - `AbstractComposeView`: Bridge between View and Compose
   - Allows us to use Compose for UI while working with InputMethodService

---

## Part 3: Manifest Configuration

### Step 1: Update AndroidManifest.xml

**`AndroidManifest.xml`**

```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <!-- Permission for haptic feedback -->
    <uses-permission android:name="android.permission.VIBRATE"/>

    <application
        android:allowBackup="true"
        android:icon="@mipmap/ic_launcher"
        android:label="@string/app_name"
        android:theme="@style/Theme.MyKeyboard">

        <!-- Main Settings Activity -->
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:label="@string/app_name">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>

        <!-- IME Service Declaration -->
        <service
            android:name=".MyKeyboardService"
            android:label="@string/app_name"
            android:permission="android.permission.BIND_INPUT_METHOD"
            android:exported="true">
            <!-- Intent filter for IME -->
            <intent-filter>
                <action android:name="android.view.InputMethod"/>
            </intent-filter>
            <!-- Metadata pointing to IME configuration -->
            <meta-data
                android:name="android.view.im"
                android:resource="@xml/method"/>
        </service>

    </application>

</manifest>
```

**Important Elements:**

1. **`android:permission="android.permission.BIND_INPUT_METHOD"`**
   - Required for IME services
   - Ensures only the system can bind to your service

2. **Intent Filter with `android.view.InputMethod`**
   - Tells Android this is an IME service
   - Makes it appear in keyboard selection

3. **Meta-data pointing to `@xml/method`**
   - Configuration file for IME settings

### Step 2: Create IME Configuration

Create `res/xml/method.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<input-method xmlns:android="http://schemas.android.com/apk/res/android"
    android:settingsActivity="com.example.mykeyboard.MainActivity"
    android:supportsSwitchingToNextInputMethod="true">

    <!-- Default subtype -->
    <subtype
        android:label="@string/app_name"
        android:imeSubtypeMode="keyboard"
        android:isAsciiCapable="true"/>

</input-method>
```

**Configuration Options:**

- `settingsActivity`: Activity to open from keyboard settings
- `supportsSwitchingToNextInputMethod`: Allow switching to next keyboard
- `subtype`: Language/layout variant (we'll expand this later)

### Step 3: Update strings.xml

```xml
<resources>
    <string name="app_name">My Keyboard</string>
</resources>
```

---

## Testing Your Keyboard

### Step 1: Build and Install

```bash
./gradlew installDebug
```

### Step 2: Enable the Keyboard

1. Open **Settings** on your device/emulator
2. Go to **System → Languages & input → On-screen keyboard**
3. Tap **Manage on-screen keyboards**
4. Enable **My Keyboard**

### Step 3: Select the Keyboard

1. Open any app with a text field (e.g., Messages, Notes)
2. Tap the text field
3. Tap the keyboard icon in the navigation bar
4. Select **My Keyboard**

### Step 4: Test Basic Functionality

- Tap keys to type letters
- Tap space to add spaces
- Tap delete to remove characters

---

## What's Next?

Congratulations! You've created a basic working keyboard. In the next tutorials, we'll add:

- **Tutorial 2**: Advanced keyboard UI with multiple layouts
- **Tutorial 3**: Touch handling and gesture support
- **Tutorial 4**: Text prediction and suggestions
- **Tutorial 5**: Dynamic layout loading from JSON
- **Tutorial 6**: Theme system and customization
- **Tutorial 7**: Performance optimization

Continue to [Part 2: Building the Keyboard UI](./tutorial-02-keyboard-ui.md) →

---

## Common Issues and Solutions

### Issue: Keyboard doesn't appear in settings

**Solution**: Check that:
- `android:permission="android.permission.BIND_INPUT_METHOD"` is set
- Intent filter includes `android.view.InputMethod`
- `@xml/method` file exists

### Issue: App crashes when opening keyboard

**Solution**: Check that:
- `installViewTreeOwners()` is called in `onCreateInputView()`
- All Compose dependencies are included
- Minimum SDK is 26 or higher

### Issue: Keys don't type anything

**Solution**: Verify that:
- `currentInputConnection` is not null
- `commitText()` is being called correctly
- The text field has focus

---

## Resources

- [Android InputMethodService Documentation](https://developer.android.com/reference/android/inputmethodservice/InputMethodService)
- [FlorisBoard Source Code](https://github.com/florisboard/florisboard)
- [Jetpack Compose Documentation](https://developer.android.com/jetpack/compose)

---

**Next**: [Tutorial 2: Building the Keyboard UI](./tutorial-02-keyboard-ui.md)

