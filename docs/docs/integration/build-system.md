# Build System: Gradle, Assets, Packaging

## Overview

FlorisBoard uses Gradle with Kotlin DSL for its build system, providing a modern, type-safe build configuration. This document covers the build system architecture, asset management, and packaging process.

## Gradle Configuration

### Project Structure

```
florisboard/
├── build.gradle.kts              # Root build file
├── settings.gradle.kts           # Module configuration
├── gradle.properties             # Project properties
├── gradle/
│   ├── libs.versions.toml        # Dependency versions
│   ├── tools.versions.toml       # Tool versions
│   └── wrapper/                  # Gradle wrapper
├── app/
│   └── build.gradle.kts          # App module build
└── lib/
    ├── android/build.gradle.kts
    ├── snygg/build.gradle.kts
    └── ...
```

### Root Build File

```kotlin
// build.gradle.kts
plugins {
    alias(libs.plugins.agp.application) apply false
    alias(libs.plugins.agp.library) apply false
    alias(libs.plugins.kotlin.android) apply false
    alias(libs.plugins.kotlin.jvm) apply false
    alias(libs.plugins.kotlin.plugin.compose) apply false
    alias(libs.plugins.kotlin.serialization) apply false
    alias(libs.plugins.ksp) apply false
    alias(libs.plugins.mikepenz.aboutlibraries) apply false
}
```

### Settings Configuration

```kotlin
// settings.gradle.kts
rootProject.name = "FlorisBoard"

pluginManagement {
    repositories {
        gradlePluginPortal()
        google()
        mavenCentral()
    }
}

dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
    }
    
    versionCatalogs {
        create("tools") {
            from(files("gradle/tools.versions.toml"))
        }
    }
}

include(":app")
include(":lib:android")
include(":lib:color")
include(":lib:compose")
include(":lib:kotlin")
include(":lib:native")
include(":lib:snygg")
```

### Version Catalogs

**`gradle/libs.versions.toml`**
```toml
[versions]
agp = "8.7.3"
kotlin = "2.1.0"
compose = "1.7.6"
androidx-core = "1.15.0"
androidx-lifecycle = "2.8.7"
kotlinx-coroutines = "1.10.1"
kotlinx-serialization = "1.8.0"
room = "2.6.1"

[libraries]
androidx-core-ktx = { module = "androidx.core:core-ktx", version.ref = "androidx-core" }
androidx-lifecycle-runtime = { module = "androidx.lifecycle:lifecycle-runtime-ktx", version.ref = "androidx-lifecycle" }
compose-ui = { module = "androidx.compose.ui:ui", version.ref = "compose" }
compose-material3 = { module = "androidx.compose.material3:material3", version = "1.3.1" }
kotlinx-coroutines-android = { module = "org.jetbrains.kotlinx:kotlinx-coroutines-android", version.ref = "kotlinx-coroutines" }
kotlinx-serialization-json = { module = "org.jetbrains.kotlinx:kotlinx-serialization-json", version.ref = "kotlinx-serialization" }
room-runtime = { module = "androidx.room:room-runtime", version.ref = "room" }
room-ktx = { module = "androidx.room:room-ktx", version.ref = "room" }
room-compiler = { module = "androidx.room:room-compiler", version.ref = "room" }

[plugins]
agp-application = { id = "com.android.application", version.ref = "agp" }
agp-library = { id = "com.android.library", version.ref = "agp" }
kotlin-android = { id = "org.jetbrains.kotlin.android", version.ref = "kotlin" }
kotlin-jvm = { id = "org.jetbrains.kotlin.jvm", version.ref = "kotlin" }
kotlin-plugin-compose = { id = "org.jetbrains.kotlin.plugin.compose", version.ref = "kotlin" }
kotlin-serialization = { id = "org.jetbrains.kotlin.plugin.serialization", version.ref = "kotlin" }
ksp = { id = "com.google.devtools.ksp", version = "2.1.0-1.0.29" }
```

**`gradle/tools.versions.toml`**
```toml
[versions]
buildTools = "35.0.0"
ndk = "27.2.12479018"
```

### App Module Build

```kotlin
// app/build.gradle.kts
plugins {
    alias(libs.plugins.agp.application)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.kotlin.plugin.compose)
    alias(libs.plugins.kotlin.serialization)
    alias(libs.plugins.ksp)
    alias(libs.plugins.mikepenz.aboutlibraries)
}

val projectMinSdk: String by project
val projectTargetSdk: String by project
val projectCompileSdk: String by project
val projectVersionCode: String by project
val projectVersionName: String by project

android {
    namespace = "dev.patrickgold.florisboard"
    compileSdk = projectCompileSdk.toInt()
    buildToolsVersion = tools.versions.buildTools.get()
    ndkVersion = tools.versions.ndk.get()
    
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    
    kotlinOptions {
        jvmTarget = "11"
        freeCompilerArgs = listOf(
            "-opt-in=kotlin.contracts.ExperimentalContracts",
            "-Xjvm-default=all-compatibility",
            "-Xwhen-guards",
        )
    }
    
    defaultConfig {
        applicationId = "dev.patrickgold.florisboard"
        minSdk = projectMinSdk.toInt()
        targetSdk = projectTargetSdk.toInt()
        versionCode = projectVersionCode.toInt()
        versionName = projectVersionName.substringBefore("-")
        
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        
        buildConfigField("String", "BUILD_COMMIT_HASH", "\"${getGitCommitHash()}\"")
        
        ksp {
            arg("room.schemaLocation", "$projectDir/schemas")
            arg("room.incremental", "true")
            arg("room.expandProjection", "true")
        }
    }
    
    buildFeatures {
        buildConfig = true
        compose = true
    }
    
    buildTypes {
        named("debug") {
            applicationIdSuffix = ".debug"
            versionNameSuffix = "-debug+${getGitCommitHash(short = true)}"
            isDebuggable = true
            resValue("string", "floris_app_name", "FlorisBoard Debug")
        }
        
        create("beta") {
            applicationIdSuffix = ".beta"
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            isMinifyEnabled = true
            isShrinkResources = true
            resValue("string", "floris_app_name", "FlorisBoard Beta")
        }
        
        named("release") {
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            isMinifyEnabled = true
            isShrinkResources = true
            resValue("string", "floris_app_name", "@string/app_name")
        }
    }
}

dependencies {
    // AndroidX
    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.lifecycle.runtime)
    implementation(libs.androidx.datastore.preferences)
    
    // Compose
    implementation(platform(libs.compose.bom))
    implementation(libs.compose.ui)
    implementation(libs.compose.material3)
    implementation(libs.compose.ui.tooling.preview)
    debugImplementation(libs.compose.ui.tooling)
    
    // Kotlin
    implementation(libs.kotlinx.coroutines.android)
    implementation(libs.kotlinx.serialization.json)
    
    // Room
    implementation(libs.room.runtime)
    implementation(libs.room.ktx)
    ksp(libs.room.compiler)
    
    // Internal libraries
    implementation(project(":lib:android"))
    implementation(project(":lib:color"))
    implementation(project(":lib:compose"))
    implementation(project(":lib:kotlin"))
    implementation(project(":lib:native"))
    implementation(project(":lib:snygg"))
    
    // Testing
    testImplementation(libs.junit)
    androidTestImplementation(libs.androidx.test.ext.junit)
    androidTestImplementation(libs.androidx.test.espresso.core)
}

fun getGitCommitHash(short: Boolean = false): String {
    return try {
        val stdout = ByteArrayOutputStream()
        exec {
            commandLine("git", "rev-parse", if (short) "--short" else "", "HEAD")
            standardOutput = stdout
        }
        stdout.toString().trim()
    } catch (e: Exception) {
        "unknown"
    }
}
```

## Asset Management

### Asset Structure

```
app/src/main/assets/
└── ime/
    ├── keyboard/
    │   └── org.florisboard.layouts/
    │       ├── extension.json
    │       ├── layouts/
    │       │   ├── characters/
    │       │   ├── symbols/
    │       │   ├── numeric/
    │       │   └── phone/
    │       ├── popups/
    │       └── composers/
    └── theme/
        └── org.florisboard.themes/
            ├── extension.json
            └── stylesheets/
```

### Extension Metadata

**`extension.json` for Layouts**
```json
{
  "id": "org.florisboard.layouts",
  "version": "0.1.0",
  "title": "FlorisBoard Core Layouts",
  "description": "Core keyboard layouts",
  "authors": ["FlorisBoard Contributors"],
  "layouts": {
    "characters": [
      {
        "id": "qwerty",
        "label": "QWERTY",
        "authors": ["FlorisBoard"],
        "direction": "ltr"
      },
      {
        "id": "azerty",
        "label": "AZERTY",
        "authors": ["FlorisBoard"],
        "direction": "ltr"
      }
    ],
    "symbols": [...],
    "numeric": [...]
  },
  "popupMappings": [...],
  "composers": [...]
}
```

### Layout Definition

**`layouts/characters/qwerty.json`**
```json
[
  [
    { "$": "auto_text_key", "code": 113, "label": "q" },
    { "$": "auto_text_key", "code": 119, "label": "w" },
    { "$": "auto_text_key", "code": 101, "label": "e" },
    { "$": "auto_text_key", "code": 114, "label": "r" },
    { "$": "auto_text_key", "code": 116, "label": "t" },
    { "$": "auto_text_key", "code": 121, "label": "y" },
    { "$": "auto_text_key", "code": 117, "label": "u" },
    { "$": "auto_text_key", "code": 105, "label": "i" },
    { "$": "auto_text_key", "code": 111, "label": "o" },
    { "$": "auto_text_key", "code": 112, "label": "p" }
  ],
  [...]
]
```

### Asset Loading

```kotlin
// ExtensionManager.kt
suspend fun loadExtensionAsset(
    extension: Extension,
    path: String
): Result<String> {
    return runCatching {
        val sourceRef = extension.sourceRef ?: error("No source ref")
        ZipUtils.readFileFromArchive(context, sourceRef, path).getOrThrow()
    }
}
```

## Native Code Integration

### CMake Configuration

```cmake
# libnative/CMakeLists.txt
cmake_minimum_required(VERSION 3.22.1)
project(fl_native)

add_library(fl_native SHARED
    dummy/dummy.cpp
)

target_link_libraries(fl_native
    android
    log
)
```

### JNI Bridge

```kotlin
// NativeBridge.kt
package org.florisboard.libnative

external fun dummyAdd(a: Int, b: Int): Int

// FlorisApplication.kt
companion object {
    init {
        try {
            System.loadLibrary("fl_native")
        } catch (_: Exception) {
            // Handle load failure
        }
    }
}
```

### Native Code

```cpp
// dummy.cpp
#include <jni.h>

extern "C" JNIEXPORT jint JNICALL
Java_org_florisboard_libnative_NativeBridgeKt_dummyAdd(
    JNIEnv* env,
    jobject /* this */,
    jint a,
    jint b
) {
    return a + b;
}
```

## ProGuard Configuration

```proguard
# app/proguard-rules.pro

# Keep extension classes
-keep class dev.patrickgold.florisboard.lib.ext.** { *; }

# Keep serialization classes
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.AnnotationsKt

-keepclassmembers class kotlinx.serialization.json.** {
    *** Companion;
}
-keepclasseswithmembers class kotlinx.serialization.json.** {
    kotlinx.serialization.KSerializer serializer(...);
}

# Keep Room classes
-keep class * extends androidx.room.RoomDatabase
-keep @androidx.room.Entity class *
-dontwarn androidx.room.paging.**

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}
```

## Build Variants

### Debug Build
```bash
./gradlew assembleDebug
```
- Fast build
- No obfuscation
- Debug symbols included
- Debug app icon

### Beta Build
```bash
./gradlew assembleBeta
```
- Optimized build
- ProGuard enabled
- Beta app icon
- Separate package name

### Release Build
```bash
./gradlew assembleRelease
```
- Fully optimized
- ProGuard enabled
- Release signing
- Production app icon

## Signing Configuration

```kotlin
// app/build.gradle.kts
android {
    signingConfigs {
        create("release") {
            storeFile = file(System.getenv("KEYSTORE_FILE") ?: "release.keystore")
            storePassword = System.getenv("KEYSTORE_PASSWORD")
            keyAlias = System.getenv("KEY_ALIAS")
            keyPassword = System.getenv("KEY_PASSWORD")
        }
    }
    
    buildTypes {
        named("release") {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
```

## Continuous Integration

### GitHub Actions Workflow

```yaml
# .github/workflows/android.yml
name: Android CI

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Set up JDK 17
      uses: actions/setup-java@v4
      with:
        java-version: '17'
        distribution: 'temurin'
    
    - name: Grant execute permission for gradlew
      run: chmod +x gradlew
    
    - name: Build with Gradle
      run: ./gradlew assembleDebug
    
    - name: Run tests
      run: ./gradlew test
    
    - name: Upload APK
      uses: actions/upload-artifact@v4
      with:
        name: app-debug
        path: app/build/outputs/apk/debug/app-debug.apk
```

## Dependency Management

### Updating Dependencies

```bash
# Check for updates
./gradlew dependencyUpdates

# Update wrapper
./gradlew wrapper --gradle-version=8.11.1
```

### Custom Dependency Resolution

```kotlin
// settings.gradle.kts
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
        // Custom repository
        maven("https://jitpack.io")
    }
}
```

## Build Performance

### Gradle Properties

```properties
# gradle.properties
org.gradle.jvmargs=-Xmx4096m -XX:MaxMetaspaceSize=1024m
org.gradle.parallel=true
org.gradle.caching=true
org.gradle.configureondemand=true
kotlin.incremental=true
kotlin.incremental.java=true
kotlin.incremental.js=true
android.useAndroidX=true
android.enableJetifier=false
```

### Build Cache

```kotlin
// settings.gradle.kts
buildCache {
    local {
        isEnabled = true
        directory = File(rootDir, "build-cache")
        removeUnusedEntriesAfterDays = 30
    }
}
```

## Next Steps

- [Testing Strategies](./testing.md) - Unit and integration testing
- [Deployment](./deployment.md) - Release and distribution
- [System Integration](./system-settings.md) - Android system integration

