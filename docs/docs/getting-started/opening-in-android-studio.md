# Opening in Android Studio

After [cloning the repository](cloning-the-repository.md), the next step is to open the FlorisBoard project in Android Studio. This will allow Android Studio to set up the project, download dependencies, and prepare it for development.

## 1. Launch Android Studio

Open Android Studio on your computer. If you have a previous project open, close it to get to the welcome screen.

## 2. Open an Existing Project

From the Android Studio welcome screen, select **"Open an existing Android Studio project"** or **"Open"** (depending on your Android Studio version).

## 3. Navigate to the FlorisBoard Project Directory

In the file browser that appears, navigate to the directory where you cloned the FlorisBoard repository. Select the **`florisboard`** folder (the root of the cloned repository) and click **"Open"**.

## 4. Wait for Project Sync and Indexing

Android Studio will now start importing and syncing the project. This process can take some time, especially during the first import, as it needs to:

*   Download Gradle dependencies.
*   Index project files.
*   Resolve Kotlin and Android SDK components.

Keep an eye on the status bar at the bottom of Android Studio. You might see messages like "Gradle sync in progress...", "Indexing...", or "Downloading components...".

**Troubleshooting:**

*   **Gradle Sync Failed:** If Gradle sync fails, check the "Build" or "Gradle Console" window for error messages. Common issues include missing JDK, incorrect Android SDK path, or network problems.
*   **Missing SDK Components:** Android Studio might prompt you to install missing SDK components. Follow the prompts to install them.

## 5. Project Structure View

Once the sync and indexing are complete, you should see the project structure in the "Project" window (usually on the left side). It should display the `app` module, `lib` modules, and other project files.

## 6. Initial Build (Optional but Recommended)

To ensure everything is set up correctly, it's a good idea to perform an initial build of the project. You can do this by:

*   Going to **Build > Make Project** in the Android Studio menu.
*   Clicking the **hammer icon** in the toolbar.

This will compile the project and check for any immediate build errors.

Congratulations! You have successfully opened the FlorisBoard project in Android Studio. The next step is to run the application on an emulator or a physical device.