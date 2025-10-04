# Text Prediction & Suggestion Engine

## Overview

FlorisBoard's NLP (Natural Language Processing) system provides text prediction, autocorrect, spell checking, and word suggestions through a pluggable provider architecture.

## Introduction

The prediction engine is built on a flexible provider system that allows different NLP implementations for various languages and use cases. The system supports:

- **Word Suggestions**: Next-word prediction based on context
- **Spell Checking**: Real-time spelling correction
- **Autocorrect**: Automatic correction of typos
- **Emoji Suggestions**: Emoji recommendations based on text
- **Clipboard Suggestions**: Quick access to recent clipboard items

## Key Concepts

### NLP Provider Architecture

FlorisBoard uses an abstract provider interface that allows pluggable NLP implementations:

```kotlin
interface NlpProvider {
    val providerId: String
    suspend fun create()
    suspend fun preload(subtype: Subtype)
}
```

### Provider Types

#### SuggestionProvider

Provides word suggestions and autocorrect:

<augment_code_snippet path="app/src/main/kotlin/dev/patrickgold/florisboard/ime/nlp/NlpProviders.kt" mode="EXCERPT">
````kotlin
interface SuggestionProvider : NlpProvider {
    suspend fun suggest(
        subtype: Subtype,
        content: EditorContent,
        maxCandidateCount: Int,
        allowPossiblyOffensive: Boolean,
        isPrivateSession: Boolean,
    ): List<SuggestionCandidate>

    suspend fun notifySuggestionAccepted(subtype: Subtype, candidate: SuggestionCandidate)
    suspend fun notifySuggestionReverted(subtype: Subtype, candidate: SuggestionCandidate)
    suspend fun removeSuggestion(subtype: Subtype, candidate: SuggestionCandidate): Boolean
    suspend fun getListOfWords(subtype: Subtype): List<String>
    suspend fun getFrequencyForWord(subtype: Subtype, word: String): Double
}
````
</augment_code_snippet>

#### SpellingProvider

Provides spell checking services:

```kotlin
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

### NlpManager

The central coordinator for all NLP operations:

<augment_code_snippet path="app/src/main/kotlin/dev/patrickgold/florisboard/ime/nlp/NlpManager.kt" mode="EXCERPT">
````kotlin
class NlpManager(context: Context) {
    private val activeCandidates = mutableStateListOf<SuggestionCandidate>()
    private val internalSuggestions = guardedByLock { 0L to emptyList<SuggestionCandidate>() }

    fun suggest(subtype: Subtype, content: EditorContent)
    suspend fun spell(
        subtype: Subtype,
        word: String,
        precedingWords: List<String>,
        followingWords: List<String>,
        maxSuggestionCount: Int,
    ): SpellingResult
}
````
</augment_code_snippet>

### Suggestion Candidates

Different types of suggestions:

```kotlin
sealed class SuggestionCandidate {
    abstract val text: String
    abstract val confidence: Double
    abstract val isEligibleForAutoCommit: Boolean
}

data class WordSuggestionCandidate(
    override val text: String,
    val secondaryText: String? = null,
    override val confidence: Double,
    override val isEligibleForAutoCommit: Boolean,
    val sourceProvider: SuggestionProvider,
) : SuggestionCandidate()

data class ClipboardSuggestionCandidate(
    val item: ClipboardItem,
    val sourceProvider: SuggestionProvider,
) : SuggestionCandidate()

data class EmojiSuggestionCandidate(
    val emoji: Emoji,
    override val confidence: Double,
) : SuggestionCandidate()
```

### Spelling Results

```kotlin
sealed class SpellingResult {
    abstract val suggestionsInfo: SuggestionsInfo

    data class ValidWord(...) : SpellingResult()
    data class Typo(val suggestions: Array<String>) : SpellingResult()
    data class GrammarError(val suggestions: Array<String>) : SpellingResult()
    data class Unspecified(...) : SpellingResult()
}
```

## Implementation Details

### Suggestion Flow

```
User Types → EditorInstance → NlpManager.suggest()
    ↓
Parallel Suggestion Gathering:
    ├─► EmojiSuggestionProvider
    ├─► ClipboardSuggestionProvider
    └─► SuggestionProvider (Language-specific)
    ↓
Candidate Assembly → activeCandidates
    ↓
UI Display (Smartbar)
```

### NlpManager Suggestion Process

<augment_code_snippet path="app/src/main/kotlin/dev/patrickgold/florisboard/ime/nlp/NlpManager.kt" mode="EXCERPT">
````kotlin
fun suggest(subtype: Subtype, content: EditorContent) {
    val reqTime = SystemClock.uptimeMillis()
    scope.launch {
        val emojiSuggestions = when {
            prefs.emoji.suggestionEnabled.get() -> {
                emojiSuggestionProvider.suggest(
                    subtype = subtype,
                    content = content,
                    maxCandidateCount = prefs.emoji.suggestionCandidateMaxCount.get(),
                    allowPossiblyOffensive = !prefs.suggestion.blockPossiblyOffensive.get(),
                    isPrivateSession = keyboardManager.activeState.isIncognitoMode,
                )
            }
            else -> emptyList()
        }
        val suggestions = when {
            emojiSuggestions.isNotEmpty() && prefs.emoji.suggestionType.get().prefix.isNotEmpty() -> {
                emptyList()
            }
            else -> {
                getSuggestionProvider(subtype).suggest(
                    subtype = subtype,
                    content = content,
                    maxCandidateCount = 8,
                    allowPossiblyOffensive = !prefs.suggestion.blockPossiblyOffensive.get(),
                    isPrivateSession = keyboardManager.activeState.isIncognitoMode,
                )
            }
        }
        internalSuggestionsGuard.withLock {
            if (internalSuggestions.first < reqTime) {
                internalSuggestions = reqTime to buildList {
                    addAll(emojiSuggestions)
                    addAll(suggestions)
                }
            }
        }
    }
}
````
</augment_code_snippet>

### Spell Checking Integration

<augment_code_snippet path="app/src/main/kotlin/dev/patrickgold/florisboard/FlorisSpellCheckerService.kt" mode="EXCERPT">
````kotlin
override fun onGetSuggestions(textInfo: TextInfo?, suggestionsLimit: Int): SuggestionsInfo {
    textInfo?.text ?: return SpellingResult.unspecified().suggestionsInfo
    setupSpellingIfNecessary()
    val spellingSubtype = cachedSpellingSubtype ?: return SpellingResult.unspecified().suggestionsInfo

    return runBlocking {
        nlpManager
            .spell(spellingSubtype, textInfo.text, emptyList(), emptyList(), suggestionsLimit)
            .sendToDebugOverlayIfEnabled(textInfo)
            .suggestionsInfo
    }
}
````
</augment_code_snippet>

### Clipboard Suggestions

<augment_code_snippet path="app/src/main/kotlin/dev/patrickgold/florisboard/ime/nlp/NlpManager.kt" mode="EXCERPT">
````kotlin
override suspend fun suggest(
    subtype: Subtype,
    content: EditorContent,
    maxCandidateCount: Int,
    allowPossiblyOffensive: Boolean,
    isPrivateSession: Boolean,
): List<SuggestionCandidate> {
    if (!prefs.clipboard.suggestionEnabled.get()) return emptyList()

    val currentItem = validateClipboardItem(clipboardManager.primaryClip, lastClipboardItemId, content.text)
        ?: return emptyList()

    return buildList {
        val now = System.currentTimeMillis()
        if ((now - currentItem.creationTimestampMs) < prefs.clipboard.suggestionTimeout.get() * 1000) {
            add(ClipboardSuggestionCandidate(currentItem, sourceProvider = this@ClipboardSuggestionProvider, context = context))
            if (currentItem.isSensitive) {
                return@buildList
            }
        }
    }
}
````
</augment_code_snippet>

### Latin Language Provider Example

<augment_code_snippet path="app/src/main/kotlin/dev/patrickgold/florisboard/ime/nlp/latin/LatinLanguageProvider.kt" mode="EXCERPT">
````kotlin
class LatinLanguageProvider(context: Context) : SpellingProvider, SuggestionProvider {
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

    override suspend fun spell(
        subtype: Subtype,
        word: String,
        precedingWords: List<String>,
        followingWords: List<String>,
        maxSuggestionCount: Int,
        allowPossiblyOffensive: Boolean,
        isPrivateSession: Boolean,
    ): SpellingResult {
        return when (word.lowercase()) {
            "typo" -> SpellingResult.typo(arrayOf("typo1", "typo2", "typo3"))
            "gerror" -> SpellingResult.grammarError(arrayOf("grammar1", "grammar2", "grammar3"))
            else -> SpellingResult.validWord()
        }
    }
}
````
</augment_code_snippet>

### Fallback Provider

<augment_code_snippet path="app/src/main/kotlin/dev/patrickgold/florisboard/ime/nlp/NlpProviders.kt" mode="EXCERPT">
````kotlin
object FallbackNlpProvider : SpellingProvider, SuggestionProvider {
    override val providerId = "org.florisboard.nlp.providers.fallback"

    override suspend fun spell(...): SpellingResult {
        return SpellingResult.unspecified()
    }

    override suspend fun suggest(...): List<SuggestionCandidate> {
        return emptyList()
    }
}
````
</augment_code_snippet>

## Code Examples

### Creating a Custom Suggestion Provider

```kotlin
class CustomSuggestionProvider(context: Context) : SuggestionProvider {
    override val providerId = "com.example.custom.provider"

    private val dictionary = mutableMapOf<String, Double>()

    override suspend fun create() {
        // Initialize provider
    }

    override suspend fun preload(subtype: Subtype) {
        // Load language-specific data
        val locale = subtype.primaryLocale
        loadDictionary(locale)
    }

    override suspend fun suggest(
        subtype: Subtype,
        content: EditorContent,
        maxCandidateCount: Int,
        allowPossiblyOffensive: Boolean,
        isPrivateSession: Boolean,
    ): List<SuggestionCandidate> {
        val currentWord = content.composingText
        if (currentWord.isBlank()) return emptyList()

        return dictionary.entries
            .filter { it.key.startsWith(currentWord, ignoreCase = true) }
            .sortedByDescending { it.value }
            .take(maxCandidateCount)
            .map { (word, frequency) ->
                WordSuggestionCandidate(
                    text = word,
                    confidence = frequency,
                    isEligibleForAutoCommit = frequency > 0.9,
                    sourceProvider = this
                )
            }
    }

    override suspend fun notifySuggestionAccepted(subtype: Subtype, candidate: SuggestionCandidate) {
        // Update frequency or learn from user
        if (candidate is WordSuggestionCandidate) {
            dictionary[candidate.text] = (dictionary[candidate.text] ?: 0.0) + 0.1
        }
    }

    override suspend fun removeSuggestion(subtype: Subtype, candidate: SuggestionCandidate): Boolean {
        if (candidate is WordSuggestionCandidate) {
            dictionary.remove(candidate.text)
            return true
        }
        return false
    }
}
```

### Implementing Spell Checking

```kotlin
override suspend fun spell(
    subtype: Subtype,
    word: String,
    precedingWords: List<String>,
    followingWords: List<String>,
    maxSuggestionCount: Int,
    allowPossiblyOffensive: Boolean,
    isPrivateSession: Boolean,
): SpellingResult {
    // Check if word exists in dictionary
    if (dictionary.containsKey(word.lowercase())) {
        return SpellingResult.validWord()
    }

    // Generate suggestions using edit distance
    val suggestions = dictionary.keys
        .filter { editDistance(word, it) <= 2 }
        .sortedBy { editDistance(word, it) }
        .take(maxSuggestionCount)
        .toTypedArray()

    return if (suggestions.isNotEmpty()) {
        SpellingResult.typo(suggestions)
    } else {
        SpellingResult.unspecified()
    }
}

private fun editDistance(s1: String, s2: String): Int {
    // Levenshtein distance implementation
    val dp = Array(s1.length + 1) { IntArray(s2.length + 1) }

    for (i in 0..s1.length) dp[i][0] = i
    for (j in 0..s2.length) dp[0][j] = j

    for (i in 1..s1.length) {
        for (j in 1..s2.length) {
            val cost = if (s1[i - 1] == s2[j - 1]) 0 else 1
            dp[i][j] = minOf(
                dp[i - 1][j] + 1,      // deletion
                dp[i][j - 1] + 1,      // insertion
                dp[i - 1][j - 1] + cost // substitution
            )
        }
    }

    return dp[s1.length][s2.length]
}
```

### Registering a Custom Provider

```kotlin
// In Subtype configuration
val subtype = Subtype(
    id = System.currentTimeMillis(),
    primaryLocale = FlorisLocale.from("en", "US"),
    nlpProviders = SubtypeNlpProviderMap(
        spelling = ExtensionComponentName.from("com.example.custom.provider"),
        suggestion = ExtensionComponentName.from("com.example.custom.provider")
    ),
    // ... other configuration
)
```

## Best Practices

### 1. Handle Private Sessions

```kotlin
override suspend fun suggest(..., isPrivateSession: Boolean): List<SuggestionCandidate> {
    if (isPrivateSession) {
        // Don't learn from user input
        // Only use pre-existing dictionary
        return suggestFromStaticDictionary(content)
    } else {
        // Can learn and adapt
        return suggestWithLearning(content)
    }
}
```

### 2. Respect Offensive Content Filtering

```kotlin
override suspend fun suggest(..., allowPossiblyOffensive: Boolean): List<SuggestionCandidate> {
    val candidates = generateCandidates(content)

    return if (allowPossiblyOffensive) {
        candidates
    } else {
        candidates.filter { !isOffensive(it.text) }
    }
}
```

### 3. Optimize for Performance

```kotlin
// Preload dictionaries asynchronously
override suspend fun preload(subtype: Subtype) = withContext(Dispatchers.IO) {
    val locale = subtype.primaryLocale
    dictionaryCache.getOrPut(locale) {
        loadDictionaryFromAssets(locale)
    }
}

// Use caching for frequent operations
private val suggestionCache = LruCache<String, List<SuggestionCandidate>>(100)
```

### 4. Provide Confidence Scores

```kotlin
WordSuggestionCandidate(
    text = word,
    confidence = calculateConfidence(word, context),
    isEligibleForAutoCommit = confidence > 0.95,
    sourceProvider = this
)

private fun calculateConfidence(word: String, context: EditorContent): Double {
    val frequency = getWordFrequency(word)
    val contextMatch = getContextualRelevance(word, context)
    return (frequency * 0.6 + contextMatch * 0.4).coerceIn(0.0, 1.0)
}
```

### 5. Handle Notification Events

```kotlin
override suspend fun notifySuggestionAccepted(subtype: Subtype, candidate: SuggestionCandidate) {
    if (candidate is WordSuggestionCandidate) {
        // Increase word frequency
        updateWordFrequency(candidate.text, increase = true)

        // Learn n-grams for better context
        learnContext(candidate.text, currentContext)
    }
}

override suspend fun notifySuggestionReverted(subtype: Subtype, candidate: SuggestionCandidate) {
    if (candidate is WordSuggestionCandidate) {
        // Decrease confidence for this suggestion
        updateWordFrequency(candidate.text, increase = false)
    }
}
```

## Common Patterns

### Multi-Language Support

```kotlin
class MultiLanguageProvider : SuggestionProvider {
    private val providers = mutableMapOf<String, LanguageSpecificProvider>()

    override suspend fun suggest(
        subtype: Subtype,
        content: EditorContent,
        maxCandidateCount: Int,
        allowPossiblyOffensive: Boolean,
        isPrivateSession: Boolean,
    ): List<SuggestionCandidate> {
        val primaryProvider = providers.getOrPut(subtype.primaryLocale.language) {
            createProviderForLanguage(subtype.primaryLocale)
        }

        val primarySuggestions = primaryProvider.suggest(
            subtype, content, maxCandidateCount, allowPossiblyOffensive, isPrivateSession
        )

        // Optionally include suggestions from secondary languages
        val secondarySuggestions = subtype.secondaryLocales.flatMap { locale ->
            providers.getOrPut(locale.language) {
                createProviderForLanguage(locale)
            }.suggest(subtype, content, 2, allowPossiblyOffensive, isPrivateSession)
        }

        return (primarySuggestions + secondarySuggestions).take(maxCandidateCount)
    }
}
```

### Context-Aware Suggestions

```kotlin
private fun getContextualSuggestions(
    currentWord: String,
    precedingWords: List<String>
): List<String> {
    // Use n-gram model for context
    val bigrams = ngramModel.getBigrams(precedingWords.lastOrNull() ?: "")
    val trigrams = if (precedingWords.size >= 2) {
        ngramModel.getTrigrams(precedingWords.takeLast(2))
    } else emptyList()

    return (trigrams + bigrams)
        .filter { it.startsWith(currentWord, ignoreCase = true) }
        .sortedByDescending { ngramModel.getFrequency(it) }
}
```

## Troubleshooting

### Suggestions Not Appearing

**Problem**: No suggestions show up while typing.

**Solutions**:
- Check if suggestions are enabled in preferences
- Verify provider is properly registered
- Ensure dictionary is loaded
- Check for errors in provider implementation
- Verify `isSuggestionOn()` returns true

### Spell Checking Not Working

**Problem**: Misspelled words not highlighted.

**Solutions**:
- Verify FlorisSpellCheckerService is enabled in system settings
- Check spell checker service is running
- Ensure provider implements SpellingProvider
- Verify dictionary contains words
- Check Android spell checker settings

### Poor Suggestion Quality

**Problem**: Suggestions are irrelevant or low quality.

**Solutions**:
- Improve dictionary quality and coverage
- Implement better confidence scoring
- Use context-aware n-gram models
- Filter low-confidence suggestions
- Learn from user corrections

### Performance Issues

**Problem**: Suggestions cause lag or stuttering.

**Solutions**:
- Preload dictionaries asynchronously
- Use caching for frequent lookups
- Limit suggestion count
- Optimize dictionary data structure (trie, hash map)
- Profile and optimize hot paths

## Related Topics

- [Internationalization](./i18n.md) - Multi-language support
- [Architecture Overview](../architecture/overview.md) - System architecture
- [Input Processing](./input-pipeline.md) - How input flows through the system
- [Custom UI Components](./custom-ui.md) - Displaying suggestions

## Next Steps

- Implement a [custom NLP provider](../how-to/create-nlp-provider.md)
- Learn about [dictionary formats](../how-to/dictionary-formats.md)
- Explore [existing providers](https://github.com/florisboard/florisboard/tree/main/app/src/main/kotlin/dev/patrickgold/florisboard/ime/nlp)
- Contribute to [language support](https://github.com/florisboard/florisboard/issues?q=is%3Aissue+is%3Aopen+label%3Anlp)

---

**Note**: This documentation is continuously being improved. Contributions are welcome!
