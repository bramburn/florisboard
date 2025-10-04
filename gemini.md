# Gemini CLI Documentation

This document outlines the Docusaurus setup within the `docs/` directory and provides guidance on how to structure documentation for the FlorisBoard application.

## Docusaurus Setup in `docs/`

The `docs/` directory has been initialized as a Docusaurus project. Docusaurus is a static site generator that helps you build, deploy, and maintain open source project websites easily. It uses Markdown for documentation content and React for custom pages and components.

### Key Configuration (`docusaurus.config.js`)

The main configuration file, `docusaurus.config.js`, has been set up with basic FlorisBoard details. All default placeholders, social media links, and navigation items have been cleared to provide a clean slate for new documentation.

### Content Structure

Documentation content will primarily reside within Markdown files (`.md` or `.mdx`). These files will be organized into categories to provide a logical and easy-to-navigate structure.

## Creating Categories and Documentation

To effectively document the FlorisBoard application, we need to create categories within the `docs/` directory. Categories help in organizing related documentation pages and generating a structured sidebar navigation.

### How to Create Categories

1.  **Create a new directory** within the `docs/` folder for each major category (e.g., `docs/api-reference`, `docs/android-integration`, `docs/getting-started`).
2.  **Add Markdown files** (`.md` or `.mdx`) directly into these category directories. Each Markdown file will represent a documentation page.
3.  **Configure `sidebars.js`**: The `sidebars.js` file defines the structure of your documentation sidebar. By default, it's set to autogenerate from the directory structure. For more control, you can explicitly define categories and document order within this file.

    **Example `sidebars.js` for explicit categories:**

    ```javascript
    /** @type {import('@docusaurus/plugin-content-docs').SidebarsConfig} */
    const sidebars = {
      tutorialSidebar: [
        {
          type: 'category',
          label: 'Getting Started',
          items: ['getting-started/introduction', 'getting-started/installation'],
        },
        {
          type: 'category',
          label: 'API Reference',
          items: ['api-reference/overview', 'api-reference/keyboard-api'],
        },
        {
          type: 'category',
          label: 'Android Integration',
          items: ['android-integration/setup', 'android-integration/connecting-api'],
        },
      ],
    };

    export default sidebars;
    ```

### Documentation Goal: Replicating the Application and Starting a Keyboard Project

The primary aim of this documentation is to provide comprehensive guides that enable others to:

1.  **Replicate the FlorisBoard application:** Detail the entire build process, dependencies, and environment setup required to get the FlorisBoard application running from source.
2.  **Start a keyboard project in Android Studio from scratch:** Explain how the API connects to the Android framework, providing step-by-step instructions and code examples for developing a custom keyboard using the FlorisBoard architecture or components. This includes:
    *   **Core API Explanation:** Documenting the key APIs and interfaces used in FlorisBoard.
    *   **Android Integration:** How to integrate these APIs into an Android Studio project.
    *   **Example Implementations:** Providing simple, runnable examples for common keyboard functionalities.

By following these guidelines, the documentation will serve as a valuable resource for developers looking to understand, contribute to, or build upon the FlorisBoard project.