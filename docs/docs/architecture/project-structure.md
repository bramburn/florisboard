# Project Structure Deep Dive

## Repository Overview

FlorisBoard follows a multi-module Gradle project structure with clear separation between the main application, libraries, and utilities.

```
florisboard/
├── .github/                    # GitHub workflows and templates
│   └── workflows/
│       └── android.yml         # CI/CD pipeline
├── app/                        # Main application module
│   ├── schemas/                # Room database schemas
│   ├── src/
│   │   ├── main/
│   │   │   ├── assets/         # Bundled assets
│   │   │   ├── kotlin/         # Kotlin source code
│   │   │   ├── res/            # Android resources
│   │   │   └── AndroidManifest.xml
│   │   └── test/               # Unit tests
│   └── build.gradle.kts
├── benchmark/                  # Performance benchmarks
├── docs/                       # Docusaurus documentation
├── lib/                        # Shared libraries
│   ├── android/                # Android utilities
│   ├── color/                  # Color utilities
│   ├── compose/                # Compose utilities
│   ├── kotlin/                 # Kotlin utilities
│   ├── native/                 # Native code bridge
│   └── snygg/                  # Theme engine
├── libnative/                  # Native C/C++ code
├── utils/                      # Build and development utilities
├── build.gradle.kts            # Root build configuration
├── settings.gradle.kts         # Module configuration
└── gradle.properties           # Project properties
```

## Module Breakdown

### App Module (`/app`)

The main application module containing all IME-specific code.

#### Package Structure

```
dev.patrickgold.florisboard/
├── FlorisApplication.kt        # Application entry point
├── FlorisImeService.kt         # Main IME service
├── FlorisSpellCheckerService.kt # Spell checker service
│
├── app/                        # Settings app UI
│   ├── apptheme/               # App theme (not IME theme)
│   ├── devtools/               # Developer tools
│   ├── ext/                    # Extension management UI
│   ├── settings/               # Settings screens
│   └── setup/                  # Setup wizard
│
├── ime/                        # IME implementation
│   ├── clipboard/              # Clipboard management
│   │   ├── ClipboardManager.kt
│   │   ├── ClipboardInputLayout.kt
│   │   └── provider/           # Clipboard providers
│   │
│   ├── core/                   # Core IME concepts
│   │   ├── Subtype.kt          # Language subtype
│   │   ├── DisplayLanguageNamesIn.kt
│   │   └── SubtypePreset.kt
│   │
│   ├── dictionary/             # Dictionary management
│   │   ├── DictionaryManager.kt
│   │   ├── FlorisUserDictionaryDatabase.kt
│   │   ├── SystemUserDictionaryDatabase.kt
│   │   └── UserDictionary.kt
│   │
│   ├── editor/                 # Text editor interaction
│   │   ├── AbstractEditorInstance.kt
│   │   ├── EditorInstance.kt
│   │   ├── EditorContent.kt
│   │   ├── EditorRange.kt
│   │   ├── FlorisEditorInfo.kt
│   │   └── InputAttributes.kt
│   │
│   ├── input/                  # Input handling
│   │   ├── InputEventDispatcher.kt
│   │   ├── InputFeedbackController.kt
│   │   └── InputKeyEventReceiver.kt
│   │
│   ├── keyboard/               # Keyboard core
│   │   ├── KeyboardManager.kt
│   │   ├── KeyboardState.kt
│   │   ├── LayoutManager.kt
│   │   ├── LayoutArrangement.kt
│   │   ├── KeyboardExtension.kt
│   │   ├── KeyData.kt
│   │   ├── KeyCode.kt
│   │   ├── KeyType.kt
│   │   └── TextKeyboard.kt
│   │
│   ├── lifecycle/              # Lifecycle management
│   │   └── LifecycleInputMethodService.kt
│   │
│   ├── media/                  # Media input (emoji, etc.)
│   │   ├── MediaInputLayout.kt
│   │   ├── emoji/
│   │   └── emoticon/
│   │
│   ├── nlp/                    # Natural Language Processing
│   │   ├── NlpManager.kt
│   │   ├── NlpProviders.kt
│   │   ├── SpellingResult.kt
│   │   ├── SuggestionCandidate.kt
│   │   ├── latin/              # Latin script provider
│   │   └── han/                # Han script provider
│   │
│   ├── onehanded/              # One-handed mode
│   │   └── OneHandedMode.kt
│   │
│   ├── sheet/                  # Bottom sheets
│   │   └── BottomSheetHostUi.kt
│   │
│   ├── smartbar/               # Suggestion bar
│   │   ├── SmartbarLayout.kt
│   │   ├── quickaction/
│   │   └── ExtendedActionsPlacement.kt
│   │
│   ├── text/                   # Text input
│   │   ├── TextInputLayout.kt
│   │   ├── composing/          # Composing text
│   │   ├── gestures/           # Gesture handling
│   │   │   ├── SwipeGesture.kt
│   │   │   ├── GlideTypingGesture.kt
│   │   │   └── GlideTypingManager.kt
│   │   ├── key/                # Key definitions
│   │   └── keyboard/           # Text keyboard UI
│   │       ├── TextKeyboardLayout.kt
│   │       ├── TextKeyButton.kt
│   │       └── TextKeyData.kt
│   │
│   └── theme/                  # Theme system
│       ├── ThemeManager.kt
│       ├── ThemeExtension.kt
│       ├── FlorisImeTheme.kt
│       └── FlorisImeThemeBaseStyle.kt
│
├── lib/                        # Internal libraries
│   ├── android/                # Android utilities
│   ├── cache/                  # Cache management
│   ├── compose/                # Compose utilities
│   ├── crash/                  # Crash reporting
│   ├── devtools/               # Development tools
│   ├── ext/                    # Extension system
│   │   ├── Extension.kt
│   │   ├── ExtensionManager.kt
│   │   ├── ExtensionComponent.kt
│   │   └── ExtensionMeta.kt
│   ├── io/                     # I/O utilities
│   ├── observables/            # Observable patterns
│   └── util/                   # General utilities
│
└── prefs/                      # Preferences
    ├── FlorisPreferenceModel.kt
    └── FlorisPreferenceStore.kt
```

### Assets Structure (`/app/src/main/assets`)

```
assets/
└── ime/
    ├── keyboard/
    │   └── org.florisboard.layouts/
    │       ├── extension.json          # Layout extension metadata
    │       ├── layouts/
    │       │   ├── characters/         # Character layouts
    │       │   │   ├── qwerty.json
    │       │   │   ├── azerty.json
    │       │   │   ├── dvorak.json
    │       │   │   └── ... (100+ layouts)
    │       │   ├── symbols/            # Symbol layouts
    │       │   ├── numeric/            # Numeric layouts
    │       │   └── phone/              # Phone layouts
    │       ├── popups/                 # Popup key mappings
    │       │   ├── default.json
    │       │   └── ...
    │       └── composers/              # Text composers
    │
    └── theme/
        └── org.florisboard.themes/
            ├── extension.json          # Theme extension metadata
            └── stylesheets/
                ├── base.json           # Base theme
                ├── material-dark.json
                └── ...
```

### Library Modules

#### `/lib/snygg` - Theme Engine

Custom CSS-like styling engine for FlorisBoard themes.

```
snygg/
├── src/main/kotlin/org/florisboard/lib/snygg/
│   ├── Snygg.kt                    # Core definitions
│   ├── SnyggTheme.kt               # Theme runtime
│   ├── SnyggStylesheet.kt          # Stylesheet parser
│   ├── SnyggRule.kt                # Style rules
│   ├── SnyggPropertySet.kt         # Property collections
│   ├── SnyggValue.kt               # Value types
│   ├── ui/                         # Compose integration
│   │   ├── SnyggBox.kt
│   │   ├── SnyggButton.kt
│   │   ├── SnyggSurface.kt
│   │   └── ProvideSnyggTheme.kt
│   └── value/                      # Value implementations
│       ├── SnyggColorValue.kt
│       ├── SnyggSizeValue.kt
│       └── ...
└── build.gradle.kts
```

#### `/lib/android` - Android Utilities

Common Android utilities and extensions.

```
android/
└── src/main/kotlin/org/florisboard/lib/android/
    ├── AndroidVersion.kt           # Version checks
    ├── AndroidSettings.kt          # System settings
    ├── showToast.kt                # Toast utilities
    └── systemService.kt            # System service access
```

#### `/lib/kotlin` - Kotlin Utilities

Pure Kotlin utilities with no Android dependencies.

```
kotlin/
└── src/main/kotlin/org/florisboard/lib/kotlin/
    ├── collections/                # Collection utilities
    ├── io/                         # I/O utilities
    ├── curlyFormat.kt              # String formatting
    └── tryOrNull.kt                # Error handling
```

#### `/lib/compose` - Compose Utilities

Jetpack Compose utilities and custom components.

```
compose/
└── src/main/kotlin/org/florisboard/lib/compose/
    ├── FlorisScreen.kt             # Screen composable
    ├── FlorisButtonBar.kt          # Button bar
    ├── FlorisOutlinedBox.kt        # Outlined container
    └── ...
```

#### `/lib/native` - Native Bridge

JNI bridge for native code integration.

```
native/
└── src/main/kotlin/org/florisboard/libnative/
    └── NativeBridge.kt             # JNI declarations
```

### Native Code (`/libnative`)

```
libnative/
├── dummy/                          # Dummy native implementation
│   └── dummy.cpp
└── CMakeLists.txt                  # CMake build configuration
```

### Build Configuration

#### Root `build.gradle.kts`

```kotlin
plugins {
    alias(libs.plugins.agp.application) apply false
    alias(libs.plugins.agp.library) apply false
    alias(libs.plugins.kotlin.android) apply false
    alias(libs.plugins.kotlin.jvm) apply false
    alias(libs.plugins.kotlin.plugin.compose) apply false
    alias(libs.plugins.kotlin.serialization) apply false
    alias(libs.plugins.ksp) apply false
}
```

#### `settings.gradle.kts`

```kotlin
rootProject.name = "FlorisBoard"

include(":app")
include(":lib:android")
include(":lib:color")
include(":lib:compose")
include(":lib:kotlin")
include(":lib:native")
include(":lib:snygg")
```

#### Version Catalogs

**`gradle/libs.versions.toml`**
- Centralized dependency versions
- Plugin versions
- Library coordinates

**`gradle/tools.versions.toml`**
- Build tools version
- NDK version
- Other tooling versions

## Key Files

### Application Entry Points

1. **`FlorisApplication.kt`**
   - Application initialization
   - Manager instantiation
   - Preference loading
   - Native library loading

2. **`FlorisImeService.kt`**
   - IME service lifecycle
   - Input view creation
   - Event handling
   - System integration

3. **`FlorisSpellCheckerService.kt`**
   - Spell checking service
   - Suggestion generation
   - System-wide spell check

### Configuration Files

1. **`AndroidManifest.xml`**
   - Service declarations
   - Permissions
   - Intent filters
   - Metadata

2. **`gradle.properties`**
   - Project version
   - SDK versions
   - Build configuration

3. **`proguard-rules.pro`**
   - Code obfuscation rules
   - Keep rules for reflection

## Module Dependencies

```
app
├── lib:android
├── lib:color
├── lib:compose
├── lib:kotlin
├── lib:native
└── lib:snygg

lib:snygg
└── lib:kotlin

lib:compose
├── lib:android
└── lib:kotlin

lib:android
└── lib:kotlin

lib:color
└── lib:kotlin

lib:native
└── lib:kotlin
```

## Build Variants

### Debug
- Application ID: `dev.patrickgold.florisboard.debug`
- Debuggable: Yes
- Minification: No
- Icon: Debug variant

### Beta
- Application ID: `dev.patrickgold.florisboard.beta`
- Debuggable: No
- Minification: Yes
- Icon: Beta variant

### Release
- Application ID: `dev.patrickgold.florisboard`
- Debuggable: No
- Minification: Yes
- Icon: Stable variant

### Benchmark
- Based on release
- Debug signing
- For performance testing

## Resource Organization

### Layouts
- Minimal XML layouts (mostly Compose)
- Preference screens
- Widget layouts

### Drawables
- Vector icons
- App icons (multiple variants)
- Background images

### Values
- Strings (localized)
- Colors
- Dimensions
- Styles
- Themes

### Assets
- Keyboard layouts (JSON)
- Themes (JSON)
- Popup mappings (JSON)
- Extension metadata

## Testing Structure

```
app/src/
├── test/                       # Unit tests
│   └── kotlin/
│       └── dev/patrickgold/florisboard/
│           ├── keyboard/
│           ├── nlp/
│           └── ...
│
└── androidTest/                # Instrumentation tests
    └── kotlin/
        └── dev/patrickgold/florisboard/
            └── ...
```

## Next Steps

- [Design Patterns](./design-patterns.md) - Patterns used in the codebase
- [State Management](./state-management.md) - How state flows through the app
- [Extension System](./extensions.md) - How extensions are structured and loaded

