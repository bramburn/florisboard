# Project Structure

Understanding the overall project structure is crucial for navigating the FlorisBoard codebase and contributing effectively. This document outlines the main directories and modules, as well as the organization of the documentation itself.

## Application Modules

FlorisBoard is organized into several Gradle modules, each serving a specific purpose. This modular approach enhances maintainability, reusability, and testability.

*   **`app/`**: This is the main Android application module. It contains the core `FlorisImeService`, `FlorisSpellCheckerService`, the main `FlorisAppActivity` (for settings and UI), and all application-specific resources and Kotlin code. Most of the user-facing features and their integration points reside here.
*   **`benchmark/`**: Contains benchmark tests for measuring the performance of various parts of the application.
*   **`lib/android/`**: A utility library for Android-specific functionalities that are reusable across different parts of the application or other Android projects. This includes helpers for assets, clipboard, settings, and more.
*   **`lib/color/`**: Defines color palettes and schemes used throughout the application, especially for theming.
*   **`lib/compose/`**: Contains reusable Jetpack Compose UI components and utilities specific to FlorisBoard's design system.
*   **`lib/kotlin/`**: A general-purpose Kotlin utility library with extensions and helper functions that are not Android-specific.
*   **`lib/native/`**: Houses native code (e.g., Rust) that is integrated into the Android application, typically for performance-critical tasks.
*   **`lib/snygg/`**: This module defines FlorisBoard's custom styling language (Snygg) and its parsing/rendering logic. It's central to the advanced theming capabilities of FlorisBoard.
*   **`libnative/dummy/`**: A dummy native library, likely for testing or as a placeholder.

## Root Project Files

Several important configuration files reside in the root directory of the project:

*   **`build.gradle.kts` (root)**: The top-level Gradle build file, defining common plugins and configurations for all sub-projects.
*   **`settings.gradle.kts`**: Defines the project's module structure, including all the `app/` and `lib/` modules.
*   **`gradle.properties`**: Contains project-wide properties, such as SDK versions, application ID, and version codes/names.
*   **`.gitignore`**: Specifies files and directories that Git should ignore.
*   **`README.md`**: The main project README, providing a high-level overview of FlorisBoard.
*   **`LICENSE`**: The project's license file.
*   **`CONTRIBUTING.md`**: Guidelines for contributing to the project.
*   **`ROADMAP.md`**: Outlines the future development plans for FlorisBoard.
*   **`gemini.md`**: This document, explaining the Docusaurus setup and documentation goals.

## Documentation Structure (`docs/` folder)

The `docs/` directory contains all the Docusaurus documentation for FlorisBoard. It is organized into the following top-level categories, each with its own purpose:

*   **`getting-started/`**: This section provides a step-by-step guide for new contributors or users to set up their development environment, clone the repository, open it in Android Studio, and perform an initial build and run of the FlorisBoard application.
*   **`project-overview/`**: This section (where this document resides) aims to give a high-level understanding of the FlorisBoard project, including its modular structure, build system, and Android Manifest configuration.
*   **`core-concepts/`**: Delves into the fundamental technical concepts and technologies used in FlorisBoard, such as Input Method Editor (IME) fundamentals, Jetpack Compose, Kotlin Coroutines, and the modular architecture.
*   **`api-reference/`**: Will contain detailed documentation of FlorisBoard's various APIs, including the core keyboard API, theme engine API, clipboard API, and more. This is crucial for developers looking to extend or integrate FlorisBoard components.
*   **`android-integration-extension/`**: Provides guides and tutorials on how to integrate FlorisBoard components into new or existing Android projects, and how to extend FlorisBoard's functionality (e.g., creating custom themes or input methods).
*   **`contribution-guidelines/`**: Offers detailed information for developers interested in contributing to the FlorisBoard project, covering code style, testing, and the pull request process.

Each of these categories is further broken down into individual Markdown files, providing focused and digestible information on specific topics. The `_category_.json` files within each directory help Docusaurus automatically generate the sidebar navigation, ensuring a consistent and easy-to-browse documentation experience.