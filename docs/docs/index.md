# Welcome to FlorisBoard Documentation

## Introduction

**FlorisBoard** is a free and open-source keyboard for Android 8.0+ devices. It aims at being modern, user-friendly, and customizable while fully respecting your privacy. This comprehensive documentation serves as both a user guide and a technical reference for developers who want to understand, contribute to, or build their own Android IME (Input Method Editor) keyboard.

## What You'll Learn

This documentation is structured to take you from understanding the basics of FlorisBoard to mastering the intricate details of building a fully-featured Android keyboard from scratch. Whether you're a contributor, a curious developer, or someone looking to build their own IME, you'll find:

### 🏗️ Architecture & Design
- **Project Structure**: Deep dive into how FlorisBoard is organized
- **Design Patterns**: MVVM, state management, and architectural decisions
- **Performance Optimizations**: Touch handling, rendering, and latency reduction
- **Extension System**: How themes, layouts, and plugins work

### 🔧 Technical Implementation
- **Input Processing Pipeline**: From touch events to text output
- **Custom UI Components**: Building keyboard views with Jetpack Compose
- **Layout System**: How keyboard layouts are defined, loaded, and switched
- **Text Prediction**: NLP engines, suggestions, and autocorrect
- **Internationalization**: Multi-language support and locale handling

### 🔌 Android Integration
- **IME APIs**: Understanding Android's InputMethodService
- **System Integration**: Registration, settings, and lifecycle
- **Native Components**: JNI integration and native libraries
- **Testing Strategies**: Unit, integration, and UI testing

### 🔍 Reverse Engineering Guide
- **Methodology**: How to analyze and understand complex IME codebases
- **Key Questions**: What to look for when studying keyboard implementations
- **Case Studies**: FlorisBoard compared to other IMEs

### 📚 Practical Guides
- **Building From Scratch**: Step-by-step guide to creating your own keyboard
- **Common Pitfalls**: Lessons learned and how to avoid them
- **Security & Privacy**: Best practices for handling user input

## Why FlorisBoard?

FlorisBoard serves as an excellent real-world example for learning Android IME development because:

1. **Modern Architecture**: Built with Kotlin, Jetpack Compose, and modern Android practices
2. **Comprehensive Features**: Includes text input, emoji, clipboard, themes, and more
3. **Well-Structured**: Clear separation of concerns and modular design
4. **Active Development**: Continuously evolving with new features and improvements
5. **Open Source**: Full access to source code for learning and contribution

## Key Features

- ✨ **Advanced Theming**: Snygg styling engine with extensive customization
- 📋 **Clipboard Manager**: Integrated clipboard history and management
- 🎨 **Extension Support**: Themes, layouts, and language packs
- 😊 **Emoji Support**: Emoji keyboard with history and suggestions
- 🌍 **Multi-language**: Support for 100+ languages and layouts
- 🎯 **Glide Typing**: Gesture-based typing support
- 🔒 **Privacy-Focused**: No data collection, fully offline

## Project Statistics

- **Language**: Kotlin (primary), Java (minimal)
- **UI Framework**: Jetpack Compose
- **Min SDK**: Android 8.0 (API 26)
- **Target SDK**: Android 14+ (API 34+)
- **Architecture**: MVVM with reactive state management
- **Build System**: Gradle with Kotlin DSL

## Getting Started

### For Users
If you're looking to use FlorisBoard, check out the [installation guide](https://github.com/florisboard/florisboard#readme) and explore the features.

### For Contributors
Start with the [Getting Started](./getting-started/introduction.md) section to set up your development environment and understand the contribution workflow.

### For Learners
Begin with [Architecture Overview](./architecture/overview.md) to understand the high-level design, then dive into specific technical areas based on your interests.

### For IME Developers
Jump to [Building a Keyboard From Scratch](./how-to/build-from-scratch.md) for a comprehensive guide on creating your own Android keyboard, using FlorisBoard as a reference implementation.

## Documentation Structure

```
docs/
├── architecture/          # High-level design and patterns
│   ├── overview.md
│   ├── project-structure.md
│   ├── design-patterns.md
│   ├── state-management.md
│   ├── performance.md
│   └── extensions.md
├── technical/            # Implementation details
│   ├── input-pipeline.md
│   ├── custom-ui.md
│   ├── layout-system.md
│   ├── touch-gestures.md
│   ├── prediction-engine.md
│   ├── i18n.md
│   └── accessibility.md
├── integration/          # Android system integration
│   ├── apis.md
│   ├── native-code.md
│   ├── testing.md
│   ├── build-system.md
│   ├── system-settings.md
│   └── deployment.md
├── reverse-engineering/  # Analysis methodology
│   ├── questions.md
│   └── methodology.md
├── case-study/          # Real-world examples
│   ├── florisboard.md
│   └── comparison.md
├── how-to/              # Practical guides
│   └── build-from-scratch.md
└── faq/                 # Common questions
    ├── common-pitfalls.md
    └── security-privacy.md
```

## Contributing to Documentation

Found an error or want to improve the documentation? Contributions are welcome! Please see the [contribution guidelines](https://github.com/florisboard/florisboard/blob/main/CONTRIBUTING.md) for more information.

## Resources

- **GitHub Repository**: [florisboard/florisboard](https://github.com/florisboard/florisboard)
- **Issue Tracker**: [GitHub Issues](https://github.com/florisboard/florisboard/issues)
- **Community**: [Matrix Chat](https://matrix.to/#/#florisboard:matrix.org)
- **Addons Store**: [beta.addons.florisboard.org](https://beta.addons.florisboard.org)

## License

FlorisBoard is licensed under the Apache License 2.0. See the [LICENSE](https://github.com/florisboard/florisboard/blob/main/LICENSE) file for details.

<!-- Build trigger: 2025-10-04-v2 -->

---

**Ready to dive in?** Start with the [Architecture Overview](./architecture/overview.md) to understand how FlorisBoard is built!

