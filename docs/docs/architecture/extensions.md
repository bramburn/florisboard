# Theme & Extension System

## Overview

FlorisBoard features a powerful extension system that allows users to customize themes, keyboard layouts, and language support through packaged `.flex` files.

## Introduction

The extension system is a core feature that makes FlorisBoard highly customizable. Extensions are packaged as `.flex` archive files containing:

- **Themes**: Visual styling with Snygg CSS-like syntax
- **Keyboard Layouts**: Custom keyboard arrangements
- **Language Packs**: Dictionaries and NLP data for specific languages
- **Composers**: Input method composers for complex scripts
- **Popup Mappings**: Long-press character variants

## Key Concepts

### Extension Types

FlorisBoard supports three main extension types:

#### Keyboard Extensions

<augment_code_snippet path="app/src/main/kotlin/dev/patrickgold/florisboard/ime/keyboard/KeyboardExtension.kt" mode="EXCERPT">
````kotlin
@Serializable
data class KeyboardExtension(
    override val meta: ExtensionMeta,
    override val dependencies: List<String>? = null,
    val composers: List<Composer> = listOf(),
    val currencySets: List<CurrencySet> = listOf(),
    val layouts: Map<String, List<LayoutArrangementComponent>> = mapOf(),
    val punctuationRules: List<PunctuationRule> = listOf(),
    val popupMappings: List<PopupMappingComponent> = listOf(),
    val subtypePresets: List<SubtypePreset> = listOf(),
) : Extension()
````
</augment_code_snippet>

#### Theme Extensions

<augment_code_snippet path="app/src/main/kotlin/dev/patrickgold/florisboard/ime/theme/ThemeExtension.kt" mode="EXCERPT">
````kotlin
@Serializable
class ThemeExtension(
    override val meta: ExtensionMeta,
    override val dependencies: List<String>? = null,
    val themes: List<ThemeExtensionComponentImpl>,
) : Extension()
````
</augment_code_snippet>

#### Language Pack Extensions

<augment_code_snippet path="app/src/main/kotlin/dev/patrickgold/florisboard/ime/nlp/LanguagePackExtension.kt" mode="EXCERPT">
````kotlin
@Serializable
class LanguagePackExtension(
    override val meta: ExtensionMeta,
    override val dependencies: List<String>? = null,
    val items: List<LanguagePackComponent> = listOf(),
    val hanShapeBasedSQLite: String = "han.sqlite3",
) : Extension()
````
</augment_code_snippet>

### Extension Metadata

Every extension has metadata defined in `extension.json`:

<augment_code_snippet path="app/src/main/kotlin/dev/patrickgold/florisboard/lib/ext/ExtensionMeta.kt" mode="EXCERPT">
````kotlin
@Serializable
data class ExtensionMeta(
    val id: String,                    // Unique identifier (e.g., "org.example.mytheme")
    val version: String,               // Semantic version (e.g., "1.0.0")
    val title: String,                 // Display name
    val description: String,           // Description
    val keywords: List<String>? = null,
    val homepage: String? = null,
    val issueTracker: String? = null,
    val maintainers: List<String>,     // List of maintainers
    val license: String,               // License identifier (e.g., "apache-2.0")
)
````
</augment_code_snippet>

### Extension Manager

The `ExtensionManager` handles loading, indexing, and managing extensions:

<augment_code_snippet path="app/src/main/kotlin/dev/patrickgold/florisboard/lib/ext/ExtensionManager.kt" mode="EXCERPT">
````kotlin
class ExtensionManager(context: Context) {
    val keyboardExtensions = ExtensionIndex(KeyboardExtension.serializer(), IME_KEYBOARD_PATH)
    val themes = ExtensionIndex(ThemeExtension.serializer(), IME_THEME_PATH)
    val languagePacks = ExtensionIndex(LanguagePackExtension.serializer(), IME_LANGUAGEPACK_PATH)

    fun init()
    fun import(ext: Extension)
    fun export(ext: Extension, uri: Uri)
    fun getExtensionById(id: String): Extension?
    fun canDelete(ext: Extension): Boolean
    fun delete(ext: Extension)
}
````
</augment_code_snippet>

### Extension Lifecycle

Extensions follow this lifecycle:

```
Install → Index → Load → Use → Unload → Delete
```

<augment_code_snippet path="app/src/main/kotlin/dev/patrickgold/florisboard/lib/ext/Extension.kt" mode="EXCERPT">
````kotlin
abstract class Extension {
    var workingDir: FsDir? = null
    var sourceRef: FlorisRef? = null

    abstract val meta: ExtensionMeta
    abstract val dependencies: List<String>?

    fun isLoaded() = workingDir != null

    open fun onBeforeLoad(context: Context, cacheDir: FsDir)
    open fun onAfterLoad(context: Context, cacheDir: FsDir)

    fun load(context: Context, force: Boolean = false): Result<Unit>
    fun unload(context: Context)
}
````
</augment_code_snippet>

## Implementation Details

### Extension File Structure

A `.flex` file is a ZIP archive with this structure:

```
mytheme.flex
├── extension.json          # Metadata
├── README.md              # Optional documentation
├── LICENSE                # License file
└── ime/
    └── theme/
        └── mytheme/
            ├── day.json   # Day theme stylesheet
            └── night.json # Night theme stylesheet
```

### Extension Indexing

Extensions are indexed from two locations:

1. **Assets**: Built-in extensions in `app/src/main/assets/ime/`
2. **Internal Storage**: User-installed extensions in app's internal storage

<augment_code_snippet path="app/src/main/kotlin/dev/patrickgold/florisboard/lib/ext/ExtensionManager.kt" mode="EXCERPT">
````kotlin
inner class ExtensionIndex<T : Extension>(
    private val serializer: KSerializer<T>,
    modulePath: String,
) : LiveData<List<T>>() {

    fun init() {
        ioScope.launch {
            initGuard.withLock {
                internalModuleDir = internalModuleRef.absoluteFile(appContext)
                internalModuleDir.mkdirs()

                refreshGuard.withLock {
                    staticExtensions = indexAssetsModule()
                    refresh()
                }

                // Watch for file changes
                fileObserver = FileObserver(internalModuleDir, FILE_OBSERVER_MASK) { event, path ->
                    ioScope.launch {
                        refreshGuard.withLock { refresh() }
                    }
                }.also { it.startWatching() }
            }
        }
    }
}
````
</augment_code_snippet>

### Theme System (Snygg)

FlorisBoard uses a custom styling engine called **Snygg** (Swedish for "stylish"):

#### Theme Stylesheet Example

```json
{
  "$": "ime.extension.theme",
  "meta": {
    "id": "org.example.mytheme",
    "version": "1.0.0",
    "title": "My Custom Theme",
    "maintainers": ["Your Name <email@example.com>"],
    "license": "apache-2.0"
  },
  "themes": [
    {
      "id": "day",
      "label": "Day",
      "authors": ["Your Name"],
      "isNightTheme": false,
      "stylesheetPath": "ime/theme/mytheme/day.json"
    }
  ]
}
```

#### Stylesheet Definition

```json
{
  "defines": {
    "--primary": "#4CAF50",
    "--background": "#FFFFFF",
    "--surface": "#F5F5F5",
    "--on-primary": "#FFFFFF",
    "--shape": "8dp"
  },
  "rules": {
    "keyboard": {
      "background": "var(--background)",
      "foreground": "var(--on-background)"
    },
    "key": {
      "background": "var(--surface)",
      "foreground": "var(--on-surface)",
      "shape": "var(--shape)",
      "shadow-elevation": "2dp"
    },
    "key:pressed": {
      "background": "var(--primary)",
      "foreground": "var(--on-primary)"
    }
  }
}
```

### Extension Loading

<augment_code_snippet path="app/src/main/kotlin/dev/patrickgold/florisboard/lib/ext/Extension.kt" mode="EXCERPT">
````kotlin
fun load(context: Context, force: Boolean = false): Result<Unit> {
    val cacheDir = FsDir(context.cacheDir, meta.id)
    if (cacheDir.exists()) {
        if (force) {
            cacheDir.deleteRecursively()
        }
    }
    cacheDir.mkdirs()
    val sourceRef = sourceRef ?: return resultOk()
    onBeforeLoad(context, cacheDir)
    ZipUtils.unzip(context, sourceRef, cacheDir).onFailure { return resultErr(it) }
    workingDir = cacheDir
    onAfterLoad(context, cacheDir)
    return resultOk()
}
````
</augment_code_snippet>

## Code Examples

### Creating a Theme Extension

```json
{
  "$": "ime.extension.theme",
  "meta": {
    "id": "com.example.ocean",
    "version": "1.0.0",
    "title": "Ocean Theme",
    "description": "A calming blue theme inspired by the ocean",
    "maintainers": ["Ocean Dev <dev@example.com>"],
    "license": "apache-2.0"
  },
  "themes": [
    {
      "id": "ocean_day",
      "label": "Ocean Day",
      "authors": ["Ocean Dev"],
      "isNightTheme": false,
      "stylesheetPath": "ime/theme/ocean/day.json"
    },
    {
      "id": "ocean_night",
      "label": "Ocean Night",
      "authors": ["Ocean Dev"],
      "isNightTheme": true,
      "stylesheetPath": "ime/theme/ocean/night.json"
    }
  ]
}
```

### Creating a Keyboard Layout Extension

```json
{
  "$": "ime.extension.keyboard",
  "meta": {
    "id": "com.example.customlayout",
    "version": "1.0.0",
    "title": "Custom Layouts",
    "maintainers": ["Layout Dev <dev@example.com>"],
    "license": "apache-2.0"
  },
  "layouts": {
    "characters": [
      {
        "id": "custom_qwerty",
        "label": "Custom QWERTY",
        "authors": ["Layout Dev"],
        "direction": "ltr",
        "arrangementFile": "layouts/characters/custom_qwerty.json"
      }
    ]
  }
}
```

### Importing an Extension

```kotlin
fun importExtension(uri: Uri) {
    val cacheManager by context.cacheManager()
    val extensionManager by context.extensionManager()

    // Read extension from URI
    val workspace = cacheManager.importer.new()
    cacheManager.readFromUriIntoCache(uri)

    // Parse and validate
    val ext = parseExtension(workspace)

    // Import into extension manager
    extensionManager.import(ext)

    // Cleanup
    workspace.close()
}
```

### Exporting an Extension

```kotlin
fun exportExtension(ext: Extension, uri: Uri) {
    val extensionManager by context.extensionManager()
    extensionManager.export(ext, uri)
}
```

## Best Practices

### 1. Use Semantic Versioning

```json
{
  "version": "1.2.3"  // MAJOR.MINOR.PATCH
}
```

### 2. Provide Comprehensive Metadata

```json
{
  "meta": {
    "id": "org.example.mytheme",
    "title": "My Theme",
    "description": "A detailed description of what makes this theme special",
    "keywords": ["dark", "minimal", "modern"],
    "homepage": "https://example.org/mytheme",
    "issueTracker": "https://github.com/example/mytheme/issues",
    "maintainers": ["Name <email@example.com>"],
    "license": "apache-2.0"
  }
}
```

### 3. Include Documentation

Always include README.md and LICENSE files in your extension.

### 4. Test Thoroughly

Test your extension with:
- Different screen sizes
- Light and dark modes
- Various Android versions
- Different languages (for layouts)

### 5. Follow Naming Conventions

```
Extension ID: org.example.extensionname (reverse domain)
File name: org.example.extensionname.flex
```

## Common Patterns

### Multi-Theme Extension

```json
{
  "themes": [
    {
      "id": "light",
      "label": "Light",
      "isNightTheme": false,
      "stylesheetPath": "ime/theme/mytheme/light.json"
    },
    {
      "id": "dark",
      "label": "Dark",
      "isNightTheme": true,
      "stylesheetPath": "ime/theme/mytheme/dark.json"
    },
    {
      "id": "amoled",
      "label": "AMOLED",
      "isNightTheme": true,
      "stylesheetPath": "ime/theme/mytheme/amoled.json"
    }
  ]
}
```

### Extension Dependencies

```json
{
  "meta": {
    "id": "org.example.advanced",
    "version": "1.0.0"
  },
  "dependencies": [
    "org.florisboard.layouts",
    "org.example.baselayouts"
  ]
}
```

## Troubleshooting

### Extension Not Loading

**Solutions**:
- Verify JSON syntax is valid
- Check extension.json has correct structure
- Ensure file paths are correct
- Verify extension ID is unique
- Check logs for parsing errors

### Theme Not Applying

**Solutions**:
- Verify stylesheet path is correct
- Check CSS syntax in stylesheet
- Ensure all required properties are defined
- Test with default theme first
- Validate color values

### Layout Not Appearing

**Solutions**:
- Check layout JSON is valid
- Verify arrangement file path
- Ensure layout is registered in extension.json
- Check layout type matches usage
- Validate key codes and labels

## Related Topics

- [Layout System](../technical/layout-system.md) - Creating custom layouts
- [Internationalization](../technical/i18n.md) - Language support
- [Custom UI Components](../technical/custom-ui.md) - Snygg theme system
- [Project Structure](./project-structure.md) - Extension directories

## Next Steps

- Create your first [custom theme](../how-to/create-theme.md)
- Build a [custom keyboard layout](../how-to/create-layout.md)
- Package and [distribute extensions](../how-to/distribute-extensions.md)
- Explore [existing extensions](https://github.com/florisboard/florisboard/tree/main/app/src/main/assets/ime)

---

**Note**: This documentation is continuously being improved. Contributions are welcome!
