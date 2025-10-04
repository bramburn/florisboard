# Prerequisites

Before you can build and run FlorisBoard, you need to set up your development environment with the following tools and software:

## 1. Java Development Kit (JDK)

FlorisBoard is built using Kotlin, which runs on the Java Virtual Machine (JVM). You will need a compatible JDK installed on your system. We recommend **JDK 11** or newer.

*   **Download:** You can download OpenJDK from various providers like Adoptium (Eclipse Temurin), Oracle, or your system's package manager.
*   **Installation:** Follow the installation instructions for your operating system.
*   **Verification:** Open your terminal or command prompt and run:

    ```bash
    java -version
    javac -version
    ```

    Ensure that the output shows a version of 11 or higher.

## 2. Android Studio

Android Studio is the official Integrated Development Environment (IDE) for Android app development. It includes the Android SDK, platform tools, and an emulator, all of which are essential for building FlorisBoard.

*   **Download:** Download the latest stable version of Android Studio from the [official Android Developers website](https://developer.android.com/studio).
*   **Installation:** Follow the installation wizard. During installation, ensure that you install the necessary Android SDK components. FlorisBoard targets **Android API Level 34 (Android 14)**, so make sure this SDK version is installed.
*   **Configuration:** After installation, launch Android Studio. It will guide you through setting up the Android SDK and other components.

## 3. Git

Git is a version control system used to manage the FlorisBoard source code. You will need Git to clone the repository.

*   **Download:** Download Git from the [official Git website](https://git-scm.com/downloads).
*   **Installation:** Follow the installation instructions for your operating system.
*   **Verification:** Open your terminal or command prompt and run:

    ```bash
    git --version
    ```

    Ensure that Git is installed and accessible from your path.

## 4. Node.js and npm (for Documentation)

This documentation website is built using Docusaurus, which requires Node.js and npm (Node Package Manager).

*   **Download:** Download and install Node.js (which includes npm) from the [official Node.js website](https://nodejs.org/en/download/). We recommend the LTS (Long Term Support) version.
*   **Installation:** Follow the installation instructions for your operating system.
*   **Verification:** Open your terminal or command prompt and run:

    ```bash
    node -v
    npm -v
    ```

    Ensure that both Node.js and npm are installed and accessible.

With these prerequisites installed, you are ready to clone the FlorisBoard repository and begin setting up the project in Android Studio.