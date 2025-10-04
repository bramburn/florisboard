# Cloning the Repository

Once you have set up all the [prerequisites](prerequisites.md), the next step is to clone the FlorisBoard repository to your local machine. This will download the entire source code of the project.

## 1. Open your Terminal or Command Prompt

Navigate to the directory where you want to store the FlorisBoard project. For example, if you want to store it in a `dev` folder in your home directory, you would do:

```bash
cd ~/dev
```

## 2. Clone the Repository

Use the `git clone` command followed by the repository URL. Since you have forked the repository to your GitHub profile, you should use the URL of your fork. If you are using the original `florisboard/florisboard` repository, use its URL.

**If you are cloning your fork (recommended for contributions):**

```bash
git clone https://github.com/bramburn/florisboard.git
```

**If you are cloning the original FlorisBoard repository (for read-only access or initial setup):**

```bash
git clone https://github.com/florisboard/florisboard.git
```

Replace `bramburn` with your GitHub username if you are cloning your own fork.

## 3. Navigate into the Project Directory

After the cloning process is complete, a new directory named `florisboard` will be created. Navigate into this directory:

```bash
cd florisboard
```

## 4. Verify the Clone

You can verify that the repository was cloned successfully by listing its contents:

```bash
ls -la
```

You should see the project files and directories, including `.git`, `app/`, `build.gradle.kts`, etc.

Now that you have the FlorisBoard source code on your local machine, you are ready to open the project in Android Studio.