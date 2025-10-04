# Initial Build and Run

After successfully [opening the project in Android Studio](opening-in-android-studio.md), the next crucial step is to build and run the FlorisBoard application. This will deploy the app to an emulator or a physical device, allowing you to see it in action.

## 1. Connect a Device or Start an Emulator

Before you can run the app, you need a target device. You have two main options:

### Option A: Use an Android Emulator

1.  In Android Studio, go to **Tools > Device Manager**.
2.  Click on **"Create device"** to set up a new virtual device if you don't have one.
3.  Choose a device definition (e.g., Pixel 6) and a system image (e.g., Android 14 - API Level 34). Ensure the API level matches or is close to FlorisBoard's target SDK (API 34).
4.  Once created, click the **"Play" icon** next to your virtual device in the Device Manager to launch it.

### Option B: Use a Physical Android Device

1.  **Enable Developer Options** on your Android device:
    *   Go to **Settings > About phone**.
    *   Tap on **"Build number"** seven times until you see a message that Developer Options are enabled.
2.  **Enable USB Debugging**:
    *   Go to **Settings > System > Developer options** (or similar path, it varies by device).
    *   Toggle on **"USB debugging"**.
3.  **Connect your device** to your computer using a USB cable.
4.  On your device, you might see a prompt asking to **"Allow USB debugging"**. Grant permission.

## 2. Select Your Target Device

In Android Studio, look for the **device selection dropdown** in the toolbar (usually next to the run button). Select your connected physical device or the running emulator from the list.

## 3. Run the Application

Click the **"Run" icon** (a green triangle) in the Android Studio toolbar. Alternatively, go to **Run > Run 'app'**.

Android Studio will now:

*   Build the application (if not already built).
*   Install the APK on your selected device/emulator.
*   Launch the FlorisBoard application.

## 4. Enable FlorisBoard as an Input Method

After the app launches, you will likely be taken to the FlorisBoard setup wizard or settings screen. To use FlorisBoard as your keyboard, you need to enable it in your Android device's settings:

1.  Follow the on-screen instructions within the FlorisBoard app, which will typically guide you to:
    *   **Enable FlorisBoard** in your device's language and input settings.
    *   **Switch to FlorisBoard** as your active keyboard.

    (The exact steps may vary slightly depending on your Android version and device manufacturer.)

## 5. Verify Installation

Open any app that requires text input (e.g., a messaging app, notes app) and tap on a text field. FlorisBoard should now appear as your active keyboard.

Congratulations! You have successfully built and run FlorisBoard. You are now ready to explore its features or begin making modifications to the source code.