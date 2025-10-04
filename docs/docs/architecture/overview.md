# Architecture Overview

## Introduction

FlorisBoard is built with a modern, modular architecture that emphasizes separation of concerns, testability, and maintainability. This document provides a high-level overview of the system architecture and how different components interact.

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     FlorisBoard Application                  │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   Settings   │  │  IME Service │  │ Spell Checker│      │
│  │   Activity   │  │              │  │   Service    │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│         │                  │                  │              │
│         └──────────────────┴──────────────────┘              │
│                            │                                 │
│         ┌──────────────────┴──────────────────┐             │
│         │                                      │             │
│    ┌────▼────┐                          ┌─────▼─────┐       │
│    │ Manager │                          │  Provider │       │
│    │  Layer  │                          │   Layer   │       │
│    └────┬────┘                          └─────┬─────┘       │
│         │                                      │             │
│  ┌──────┴──────────────────────────────────────┴──────┐    │
│  │                                                      │    │
│  │  KeyboardManager  │  ThemeManager  │  NlpManager   │    │
│  │  EditorInstance   │  LayoutManager │  SubtypeManager│   │
│  │  ExtensionManager │  ClipboardMgr  │  GlideTypingMgr│   │
│  │                                                      │    │
│  └──────────────────────────────────────────────────────┘   │
│                            │                                 │
│         ┌──────────────────┴──────────────────┐             │
│         │                                      │             │
│    ┌────▼────┐                          ┌─────▼─────┐       │
│    │   UI    │                          │   Data    │       │
│    │  Layer  │                          │   Layer   │       │
│    └────┬────┘                          └─────┬─────┘       │
│         │                                      │             │
│  ┌──────┴──────────────────────────────────────┴──────┐    │
│  │                                                      │    │
│  │  Compose UI       │  Preferences  │  Extensions    │    │
│  │  KeyboardView     │  DataStore    │  Dictionaries  │    │
│  │  Theme System     │  Room DB      │  Assets        │    │
│  │                                                      │    │
│  └──────────────────────────────────────────────────────┘   │
│                                                               │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    Android System                            │
├─────────────────────────────────────────────────────────────┤
│  InputMethodService  │  SpellCheckerService  │  ContentProvider│
│  InputConnection     │  Settings Provider    │  Clipboard    │
└─────────────────────────────────────────────────────────────┘
```

## Core Components

### 1. Application Layer

#### FlorisApplication
- **Purpose**: Application-level initialization and dependency management
- **Responsibilities**:
  - Initialize managers and services
  - Load preferences and configuration
  - Set up logging and crash reporting
  - Manage application lifecycle
- **Key Features**:
  - Lazy initialization of managers
  - Coroutine scope management
  - Native library loading

#### FlorisImeService
- **Purpose**: Main IME service implementation
- **Extends**: `LifecycleInputMethodService` (custom base class)
- **Responsibilities**:
  - Handle IME lifecycle events
  - Create and manage input views
  - Process keyboard events
  - Communicate with Android system
- **Key Methods**:
  - `onCreateInputView()`: Create Compose-based keyboard UI
  - `onStartInput()`: Initialize for new input field
  - `onStartInputView()`: Show keyboard and update state
  - `onFinishInput()`: Clean up when input ends

#### FlorisSpellCheckerService
- **Purpose**: System-wide spell checking service
- **Extends**: `SpellCheckerService`
- **Responsibilities**:
  - Provide spell checking for other apps
  - Generate spelling suggestions
  - Integrate with NLP providers

### 2. Manager Layer

The manager layer contains singleton-like components that handle specific domains of functionality.

#### KeyboardManager
- **Purpose**: Central coordinator for keyboard state and behavior
- **Responsibilities**:
  - Manage keyboard state (shift, mode, layout)
  - Handle key events and gestures
  - Coordinate between input and output
  - Execute keyboard actions
- **Key State**:
  - `activeState`: Observable keyboard state
  - `activeEvaluator`: Current keyboard evaluator
  - Input event dispatcher

#### EditorInstance
- **Purpose**: Manage interaction with the current text editor
- **Responsibilities**:
  - Handle InputConnection operations
  - Track cursor position and selection
  - Manage composing text
  - Execute text editing operations
- **Key Features**:
  - Auto-space and phantom space handling
  - Mass selection support
  - Caps lock state management

#### ThemeManager
- **Purpose**: Handle theme loading and application
- **Responsibilities**:
  - Load theme extensions
  - Compile Snygg stylesheets
  - Manage day/night themes
  - Provide theme to UI components
- **Key Features**:
  - Theme caching
  - Dynamic theme switching
  - Asset resolution

#### LayoutManager
- **Purpose**: Load and cache keyboard layouts
- **Responsibilities**:
  - Load layout definitions from extensions
  - Cache compiled layouts
  - Merge main, modifier, and extension layouts
  - Load popup mappings
- **Key Features**:
  - Async layout loading
  - Layout composition
  - Extension support

#### NlpManager
- **Purpose**: Natural Language Processing coordination
- **Responsibilities**:
  - Manage suggestion providers
  - Coordinate spell checking
  - Handle emoji suggestions
  - Manage clipboard suggestions
- **Key Features**:
  - Provider abstraction
  - Suggestion assembly
  - Auto-commit logic

#### SubtypeManager
- **Purpose**: Manage language subtypes and switching
- **Responsibilities**:
  - Load and manage subtypes
  - Handle subtype switching
  - Provide active subtype information
- **Key Features**:
  - Subtype presets
  - Custom subtype creation
  - Locale management

#### ExtensionManager
- **Purpose**: Manage keyboard extensions
- **Responsibilities**:
  - Load extension packages
  - Index extension components
  - Provide extension metadata
  - Handle extension updates
- **Supported Extensions**:
  - Keyboard layouts
  - Themes
  - Language packs (future)

#### ClipboardManager
- **Purpose**: Manage clipboard history
- **Responsibilities**:
  - Track clipboard changes
  - Store clipboard history
  - Provide clipboard UI
  - Handle clipboard actions
- **Key Features**:
  - History persistence
  - Sensitive content filtering
  - Clipboard suggestions

#### GlideTypingManager
- **Purpose**: Handle gesture/glide typing
- **Responsibilities**:
  - Process gesture points
  - Generate word suggestions from gestures
  - Coordinate with layout for key positions
- **Key Features**:
  - Real-time gesture recognition
  - Preview suggestions
  - Integration with NLP

### 3. UI Layer

#### Jetpack Compose Architecture
FlorisBoard uses Jetpack Compose for its entire UI, providing:
- Declarative UI definition
- Reactive state management
- Efficient recomposition
- Material Design components

#### Key UI Components

**ImeUi**
- Main keyboard container
- Handles layout modes (text, media, clipboard)
- Manages one-handed mode
- Integrates smartbar

**TextInputLayout**
- Text keyboard UI
- Key rendering
- Touch handling
- Popup management

**TextKeyboardLayout**
- Individual keyboard layout rendering
- Touch event processing
- Gesture detection
- Visual feedback

**SmartbarLayout**
- Suggestion strip
- Quick actions
- Clipboard integration

**MediaInputLayout**
- Emoji picker
- Emoticon support
- Category navigation

**ClipboardInputLayout**
- Clipboard history UI
- Item management
- Search and filter

#### Theme System (Snygg)
- Custom styling engine
- CSS-like syntax
- Dynamic theming
- Component-based styling

### 4. Data Layer

#### Preferences (DataStore)
- Type-safe preference access
- Reactive preference updates
- Structured preference model
- Migration support

#### Room Database
- User dictionary storage
- Clipboard history
- Extension metadata

#### Extension Assets
- Layout definitions (JSON)
- Theme stylesheets (JSON)
- Popup mappings (JSON)
- Dictionary files

## Data Flow

### Input Processing Flow

```
Touch Event
    │
    ▼
PointerInteropFilter
    │
    ▼
TouchEventChannel
    │
    ▼
TextKeyboardLayoutController
    │
    ├─► SwipeGestureDetector
    │       │
    │       └─► KeyboardManager.executeSwipeAction()
    │
    ├─► GlideTypingDetector
    │       │
    │       └─► GlideTypingManager.onGlideAddPoint()
    │
    └─► PointerMap & Touch Handlers
            │
            ▼
        InputEventDispatcher
            │
            ├─► sendDown() → onInputKeyDown()
            ├─► sendUp() → onInputKeyUp()
            └─► sendCancel() → onInputKeyCancel()
                    │
                    ▼
            KeyboardManager (KeyEventReceiver)
                    │
                    ▼
            Process Key Action
                    │
                    ├─► Character Input → EditorInstance.commitChar()
                    ├─► Special Keys → Handle specific actions
                    └─► System Keys → Android system calls
                            │
                            ▼
                    InputConnection
                            │
                            ▼
                    Target Application
```

### State Management Flow

```
User Action / System Event
    │
    ▼
Manager (KeyboardManager, ThemeManager, etc.)
    │
    ▼
Update Observable State
    │
    ├─► StateFlow.emit()
    │
    └─► ObservableKeyboardState.batchEdit()
            │
            ▼
    Compose Recomposition
            │
            ▼
    UI Update
```

## Design Principles

### 1. Separation of Concerns
- Clear boundaries between layers
- Single responsibility for each component
- Minimal coupling between modules

### 2. Reactive Architecture
- State flows for reactive updates
- Compose for declarative UI
- Event-driven communication

### 3. Extensibility
- Plugin architecture for extensions
- Abstract interfaces for providers
- Configuration-driven behavior

### 4. Performance
- Lazy initialization
- Caching strategies
- Async operations
- Efficient recomposition

### 5. Testability
- Dependency injection
- Interface-based design
- Isolated components

## Technology Stack

### Core Technologies
- **Language**: Kotlin 1.9+
- **UI Framework**: Jetpack Compose
- **Build System**: Gradle with Kotlin DSL
- **Min SDK**: Android 8.0 (API 26)
- **Target SDK**: Android 14+ (API 34+)

### Key Libraries
- **AndroidX**: Core, Lifecycle, Room, DataStore
- **Kotlin Coroutines**: Async operations
- **Kotlin Serialization**: JSON parsing
- **Jetpack Compose**: UI framework
- **Material 3**: Design components
- **KSP**: Annotation processing

### Custom Libraries
- **Snygg**: Theme styling engine
- **JetPref**: Preference management
- **Native Libraries**: Performance-critical operations

## Next Steps

- [Project Structure Deep Dive](./project-structure.md) - Detailed module organization
- [Design Patterns](./design-patterns.md) - Patterns used throughout the codebase
- [State Management](./state-management.md) - How state is managed and propagated
- [Performance Optimizations](./performance.md) - Touch handling and rendering optimizations
- [Extension System](./extensions.md) - How themes and layouts are extended

