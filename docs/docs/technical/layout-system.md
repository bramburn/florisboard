# Layout Definition & Switching

## Overview

FlorisBoard uses a flexible JSON-based layout system that allows dynamic loading, caching, and switching between different keyboard layouts for various languages and input modes.

## Introduction

The layout system is one of FlorisBoard's most powerful features, enabling support for 100+ keyboard layouts across multiple languages. Layouts are defined in JSON files, loaded asynchronously, cached for performance, and can be extended through the extension system.

## Key Concepts

### Layout Types

FlorisBoard supports multiple layout types for different input scenarios:

<augment_code_snippet path="app/src/main/kotlin/dev/patrickgold/florisboard/ime/keyboard/LayoutType.kt" mode="EXCERPT">
````kotlin
enum class LayoutType(val id: String) {
    CHARACTERS(LayoutTypeId.CHARACTERS),           // Main character layout (QWERTY, AZERTY, etc.)
    CHARACTERS_MOD(LayoutTypeId.CHARACTERS_MOD),   // Modifier row for character layout
    EXTENSION(LayoutTypeId.EXTENSION),             // Extension layouts
    NUMERIC(LayoutTypeId.NUMERIC),                 // Numeric keypad
    NUMERIC_ADVANCED(LayoutTypeId.NUMERIC_ADVANCED), // Advanced numeric with symbols
    NUMERIC_ROW(LayoutTypeId.NUMERIC_ROW),         // Number row above main layout
    PHONE(LayoutTypeId.PHONE),                     // Phone number pad
    PHONE2(LayoutTypeId.PHONE2),                   // Alternative phone layout
    SYMBOLS(LayoutTypeId.SYMBOLS),                 // Symbol layout
    SYMBOLS_MOD(LayoutTypeId.SYMBOLS_MOD),         // Modifier row for symbols
    SYMBOLS2(LayoutTypeId.SYMBOLS2),               // Secondary symbol layout
    SYMBOLS2_MOD(LayoutTypeId.SYMBOLS2_MOD);       // Modifier for secondary symbols
}
````
</augment_code_snippet>

### Layout Arrangement

A layout arrangement is a 2D array of key definitions:

```kotlin
typealias LayoutArrangement = List<List<AbstractKeyData>>
```

Each layout is organized as:
- **Rows**: Horizontal rows of keys
- **Keys**: Individual key definitions with properties like code, label, type, popup keys

### LayoutManager

The `LayoutManager` is responsible for:

- **Loading**: Asynchronously loading layouts from JSON files
- **Caching**: Caching loaded layouts to avoid repeated parsing
- **Merging**: Combining main, modifier, and extension layouts
- **Popup Mappings**: Loading long-press popup key mappings

<augment_code_snippet path="app/src/main/kotlin/dev/patrickgold/florisboard/ime/keyboard/LayoutManager.kt" mode="EXCERPT">
````kotlin
class LayoutManager(context: Context) {
    private val layoutCache: HashMap<LTN, DeferredResult<CachedLayout>> = hashMapOf()
    private val layoutCacheGuard: Mutex = Mutex(locked = false)
    private val popupMappingCache: HashMap<ExtensionComponentName, DeferredResult<CachedPopupMapping>> = hashMapOf()
    private val ioScope = CoroutineScope(Dispatchers.IO + SupervisorJob())

    fun computeKeyboardAsync(
        keyboardMode: KeyboardMode,
        subtype: Subtype,
    ): Deferred<TextKeyboard>
}
````
</augment_code_snippet>

### Layout Components

<augment_code_snippet path="app/src/main/kotlin/dev/patrickgold/florisboard/ime/keyboard/LayoutArrangement.kt" mode="EXCERPT">
````kotlin
@Serializable
data class LayoutArrangementComponent(
    override val id: String,
    override val label: String,
    override val authors: List<String>,
    val direction: String,                          // "ltr" or "rtl"
    val modifier: ExtensionComponentName? = null,   // Optional modifier layout
    val arrangementFile: String? = null,            // Path to layout JSON
) : ExtensionComponent {
    fun arrangementFile(type: LayoutType) = arrangementFile ?: "layouts/${type.id}/$id.json"
}
````
</augment_code_snippet>

## Implementation Details

### Layout JSON Structure

#### Basic Character Layout

<augment_code_snippet path="app/src/main/assets/ime/keyboard/org.florisboard.layouts/layouts/characters/workman.json" mode="EXCERPT">
````json
[
  [
    { "$": "auto_text_key", "code":  113, "label": "q" },
    { "$": "auto_text_key", "code":  100, "label": "d" },
    { "$": "auto_text_key", "code":  114, "label": "r" },
    { "$": "auto_text_key", "code":  119, "label": "w" },
    { "$": "auto_text_key", "code":   98, "label": "b" },
    { "$": "auto_text_key", "code":  106, "label": "j" },
    { "$": "auto_text_key", "code":  102, "label": "f" },
    { "$": "auto_text_key", "code":  117, "label": "u" },
    { "$": "auto_text_key", "code":  112, "label": "p" }
  ],
  ...
]
````
</augment_code_snippet>

#### Modifier Layout

<augment_code_snippet path="app/src/main/assets/ime/keyboard/org.florisboard.layouts/layouts/charactersMod/default.json" mode="EXCERPT">
````json
[
  [
    { "code":  -11, "label": "shift", "type": "modifier" },
    { "code":    0, "type": "placeholder" },
    { "code":   -7, "label": "delete", "type": "enter_editing" }
  ],
  [
    { "code": -202, "label": "view_symbols", "type": "system_gui" },
    { "$": "variation_selector",
      "default":  { "code":   44, "label": ",", "groupId": 1 },
      "email":    { "code":   64, "label": "@", "groupId": 1 },
      "uri":      { "code":   47, "label": "/", "groupId": 1 }
    },
    { "code": -227, "label": "language_switch", "type": "system_gui" },
    { "code": -212, "label": "ime_ui_mode_media", "type": "system_gui" },
    { "code":   32, "label": "space" },
    { "code":   46, "label": ".", "groupId": 2 },
    { "code":   10, "label": "enter", "groupId": 3, "type": "enter_editing" }
  ]
]
````
</augment_code_snippet>

### Layout Loading Process

<augment_code_snippet path="app/src/main/kotlin/dev/patrickgold/florisboard/ime/keyboard/LayoutManager.kt" mode="EXCERPT">
````kotlin
private fun loadLayoutAsync(ltn: LTN?, allowNullLTN: Boolean) = ioScope.runCatchingAsync {
    if (ltn == null) return@runCatchingAsync null

    layoutCacheGuard.withLock {
        val cached = layoutCache[ltn]
        if (cached != null) {
            flogDebug(LogTopic.LAYOUT_MANAGER) { "Using cache for '${ltn.name}'" }
            return@withLock cached
        } else {
            flogDebug(LogTopic.LAYOUT_MANAGER) { "Loading '${ltn.name}'" }
            val meta = keyboardManager.resources.layouts.value?.get(ltn.type)?.get(ltn.name)
                ?: error("No indexed entry found for ${ltn.type} - ${ltn.name}")
            val ext = extensionManager.getExtensionById(ltn.name.extensionId)
                ?: error("Extension ${ltn.name.extensionId} not found")
            val path = meta.arrangementFile(ltn.type)
            val layout = async {
                runCatching {
                    val jsonStr = ZipUtils.readFileFromArchive(appContext, ext.sourceRef!!, path).getOrThrow()
                    val arrangement = loadJsonAsset<LayoutArrangement>(jsonStr).getOrThrow()
                    CachedLayout(ltn.type, ltn.name, meta, arrangement)
                }
            }
            layoutCache[ltn] = layout
            return@withLock layout
        }
    }.await().getOrThrow()
}
````
</augment_code_snippet>

### Layout Merging

FlorisBoard merges three types of layouts:

1. **Main Layout**: The primary character/symbol layout
2. **Modifier Layout**: Bottom row with space, enter, mode switches
3. **Extension Layout**: Optional number row or other extensions

<augment_code_snippet path="app/src/main/kotlin/dev/patrickgold/florisboard/ime/keyboard/LayoutManager.kt" mode="EXCERPT">
````kotlin
fun computeKeyboardAsync(
    keyboardMode: KeyboardMode,
    subtype: Subtype,
): Deferred<TextKeyboard> = ioScope.async {
    var main: LTN? = null
    var modifier: LTN? = null
    var extension: LTN? = null

    when (keyboardMode) {
        KeyboardMode.CHARACTERS -> {
            if (prefs.keyboard.numberRow.get()) {
                extension = LTN(LayoutType.NUMERIC_ROW, subtype.layoutMap.numericRow)
            }
            main = LTN(LayoutType.CHARACTERS, subtype.layoutMap.characters)
            modifier = LTN(LayoutType.CHARACTERS_MOD, extCoreLayout("default"))
        }
        KeyboardMode.SYMBOLS -> {
            extension = LTN(LayoutType.NUMERIC_ROW, subtype.layoutMap.numericRow)
            main = LTN(LayoutType.SYMBOLS, subtype.layoutMap.symbols)
            modifier = LTN(LayoutType.SYMBOLS_MOD, extCoreLayout("default"))
        }
        // ... other modes
    }

    return@async mergeLayouts(keyboardMode, subtype, main, modifier, extension)
}
````
</augment_code_snippet>

### Extension Metadata

<augment_code_snippet path="app/src/main/assets/ime/keyboard/org.florisboard.layouts/extension.json" mode="EXCERPT">
````json
{
  "$": "ime.extension.keyboard",
  "meta": {
    "id": "org.florisboard.layouts",
    "version": "0.1.0",
    "title": "Default layouts",
    "description": "Default layouts which are always available.",
    "maintainers": [ "patrickgold <patrick@patrickgold.dev>" ],
    "license": "apache-2.0"
  },
  "layouts": {
    "characters": [
      {
        "id": "arabic",
        "label": "Arabic",
        "authors": [ "HeiWiper" ],
        "direction": "rtl",
        "modifier": "org.florisboard.layouts:arabic"
      },
      {
        "id": "qwerty",
        "label": "QWERTY",
        "authors": [ "patrickgold" ],
        "direction": "ltr"
      }
    ]
  }
}
````
</augment_code_snippet>

## Code Examples

### Creating a Custom Layout

```json
[
  [
    { "$": "auto_text_key", "code": 97, "label": "a", "popup": {
      "relevant": [
        { "code": 224, "label": "à" },
        { "code": 225, "label": "á" },
        { "code": 226, "label": "â" }
      ]
    }},
    { "$": "auto_text_key", "code": 98, "label": "b" },
    { "$": "auto_text_key", "code": 99, "label": "c" }
  ],
  [
    { "code": 32, "label": "space" },
    { "code": 10, "label": "enter", "type": "enter_editing" }
  ]
]
```

### Key Types and Special Keys

```json
{
  "code": -11,
  "label": "shift",
  "type": "modifier"
}

{
  "code": -7,
  "label": "delete",
  "type": "enter_editing"
}

{
  "code": -202,
  "label": "view_symbols",
  "type": "system_gui"
}

{
  "code": 0,
  "type": "placeholder"
}
```

### Conditional Keys (Selectors)

```json
{
  "$": "case_selector",
  "lower": { "code": 59, "label": ";" },
  "upper": { "code": 58, "label": ":" }
}

{
  "$": "variation_selector",
  "default": { "code": 44, "label": "," },
  "email": { "code": 64, "label": "@" },
  "uri": { "code": 47, "label": "/" }
}
```

### Japanese Kana Layout

<augment_code_snippet path="app/src/main/assets/ime/keyboard/org.florisboard.layouts/layouts/characters/jis.json" mode="EXCERPT">
````json
{
  "$": "kana_selector",
  "hira": { "code": 12396, "label": "ぬ" },
  "kata": { "$": "char_width_selector",
    "full": { "code": 12492, "label": "ヌ" },
    "half": { "code": 65415, "label": "ﾇ" }
  }
}
````
</augment_code_snippet>

## Best Practices

### 1. Use Selectors for Context-Aware Keys

```json
{
  "$": "variation_selector",
  "default": { "code": 46, "label": "." },
  "email": { "code": 64, "label": "@" },
  "uri": { "code": 47, "label": "/" }
}
```

### 2. Organize Popup Keys Logically

```json
{
  "code": 101,
  "label": "e",
  "popup": {
    "relevant": [
      { "code": 232, "label": "è" },
      { "code": 233, "label": "é" },
      { "code": 234, "label": "ê" },
      { "code": 235, "label": "ë" }
    ]
  }
}
```

### 3. Use Placeholders for Flexible Layouts

```json
{ "code": 0, "type": "placeholder" }
```

Placeholders expand to fill available space, allowing flexible key sizing.

### 4. Specify Direction for RTL Languages

```json
{
  "id": "arabic",
  "label": "Arabic",
  "direction": "rtl",
  "modifier": "org.florisboard.layouts:arabic"
}
```

### 5. Group Related Keys

```json
{ "code": 44, "label": ",", "groupId": 1 },
{ "code": 46, "label": ".", "groupId": 2 },
{ "code": 10, "label": "enter", "groupId": 3, "type": "enter_editing" }
```

Groups control key sizing and spacing.

## Common Patterns

### Multi-Language Support

```kotlin
val subtype = Subtype(
    id = System.currentTimeMillis(),
    primaryLocale = FlorisLocale.from("fr", "FR"),
    layoutMap = SubtypeLayoutMap(
        characters = extCoreLayout("french/azerty"),
        symbols = extCoreLayout("symbols"),
        numeric = extCoreLayout("numeric")
    )
)
```

### Dynamic Layout Switching

```kotlin
keyboardManager.activeState.keyboardMode = when (editorInfo.inputType) {
    InputType.TYPE_CLASS_NUMBER -> KeyboardMode.NUMERIC
    InputType.TYPE_CLASS_PHONE -> KeyboardMode.PHONE
    else -> KeyboardMode.CHARACTERS
}
```

### Custom Modifier Layouts

```json
{
  "id": "custom_layout",
  "label": "Custom",
  "direction": "ltr",
  "modifier": "org.florisboard.layouts:custom_modifier"
}
```

## Troubleshooting

### Layout Not Loading

**Problem**: Custom layout doesn't appear in keyboard.

**Solutions**:
- Verify JSON syntax is valid
- Check extension.json includes layout metadata
- Ensure layout file is in correct directory
- Verify extension is properly installed
- Check logs for parsing errors

### Keys Not Displaying Correctly

**Problem**: Keys show wrong characters or labels.

**Solutions**:
- Verify Unicode code points are correct
- Check font supports the characters
- Ensure proper encoding (UTF-8)
- Test with different themes

### Popup Keys Not Working

**Problem**: Long-press doesn't show popup keys.

**Solutions**:
- Verify popup mapping is loaded
- Check popup key definitions in JSON
- Ensure long-press duration is configured
- Verify key has popup property

### Layout Caching Issues

**Problem**: Layout changes don't appear after modification.

**Solutions**:
- Clear app cache
- Force reload extension
- Restart keyboard service
- Check cache invalidation logic

## Related Topics

- [Internationalization](./i18n.md) - Multi-language support
- [Extension System](../architecture/extensions.md) - Creating layout extensions
- [Custom UI Components](./custom-ui.md) - Rendering layouts
- [Input Processing](./input-pipeline.md) - How key presses are handled

## Next Steps

- Explore [existing layouts](https://github.com/florisboard/florisboard/tree/main/app/src/main/assets/ime/keyboard/org.florisboard.layouts/layouts)
- Contribute layouts to the [FlorisBoard repository](https://github.com/florisboard/florisboard)
- Check the FlorisBoard documentation for upcoming guides on custom layouts and popup mappings

---

**Note**: This documentation is continuously being improved. Contributions are welcome!
