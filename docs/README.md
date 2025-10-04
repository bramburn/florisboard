# FlorisBoard Documentation

This directory contains the comprehensive documentation for FlorisBoard, built with [Docusaurus](https://docusaurus.io/).

## 📚 Documentation Structure

The documentation is organized into the following sections:

### 🏗️ Architecture
- **Overview**: High-level architecture and component interaction
- **Project Structure**: Detailed module organization and file structure
- **Design Patterns**: MVVM, Observer, Strategy, and other patterns used
- **State Management**: Reactive state handling with StateFlow
- **Performance**: Touch handling and rendering optimizations
- **Extensions**: Theme and layout extension system

### 🔧 Technical Details
- **Input Pipeline**: From touch events to text output
- **Custom UI**: Jetpack Compose keyboard components
- **Layout System**: JSON-based layout definitions and loading
- **Touch & Gestures**: Multi-touch, swipe, and glide typing
- **Prediction Engine**: NLP providers and text suggestions
- **Internationalization**: Multi-language support
- **Accessibility**: Features for users with disabilities

### 🔌 Android Integration
- **IME APIs**: InputMethodService and Android integration
- **Native Code**: JNI and C/C++ components
- **Testing**: Unit, integration, and UI testing strategies
- **Build System**: Gradle configuration and asset management
- **System Settings**: Registration and permissions
- **Deployment**: Release process and distribution

### 🔍 Reverse Engineering
- **Key Questions**: What to look for when analyzing IMEs
- **Methodology**: Step-by-step analysis approach

### 📚 Case Studies
- **FlorisBoard**: In-depth analysis of this implementation
- **Comparison**: How FlorisBoard compares to other IMEs

### 📖 How-To Guides
- **Build From Scratch**: Complete guide to building your own keyboard

### ❓ FAQ
- **Common Pitfalls**: Frequently asked questions and issues
- **Security & Privacy**: Best practices and considerations

## 🚀 Getting Started

### Prerequisites

- Node.js 18+ and npm
- Git

### Installation

```bash
cd docs
npm install
```

### Local Development

```bash
npm run start
```

This command starts a local development server and opens up a browser window. Most changes are reflected live without having to restart the server.

### Build

```bash
npm run build
```

This command generates static content into the `build` directory and can be served using any static contents hosting service.

## 📝 Contributing to Documentation

### Adding New Pages

1. Create a new markdown file in the appropriate directory:
   ```bash
   touch docs/technical/new-topic.md
   ```

2. Add frontmatter to the file:
   ```markdown
   ---
   sidebar_position: 5
   ---
   
   # New Topic
   
   Content here...
   ```

3. Update `sidebars.js` if needed to include the new page in the navigation.

### Documentation Guidelines

- **Use clear headings**: Structure content with H2 and H3 headings
- **Include code examples**: Show real code from FlorisBoard when possible
- **Add diagrams**: Use ASCII art or Mermaid diagrams for complex flows
- **Link related topics**: Cross-reference related documentation pages
- **Keep it updated**: Update docs when code changes

## 🌐 Deployment

The documentation is automatically deployed to GitHub Pages when changes are pushed to the `main` branch.

### GitHub Pages Configuration

The site is configured to deploy to:
- **URL**: https://bramburn.github.io/florisboard/
- **Branch**: `gh-pages` (automatically created by GitHub Actions)

## 📂 Directory Structure

```
docs/
├── docs/                       # Documentation content
│   ├── index.md               # Homepage
│   ├── architecture/          # Architecture docs
│   ├── technical/             # Technical details
│   ├── integration/           # Android integration
│   ├── reverse-engineering/   # Analysis guides
│   ├── case-study/            # Case studies
│   ├── how-to/                # How-to guides
│   └── faq/                   # FAQ
├── src/                       # Custom React components
│   ├── components/            # Reusable components
│   └── pages/                 # Custom pages
├── static/                    # Static assets
│   └── img/                   # Images
├── docusaurus.config.js       # Docusaurus configuration
├── sidebars.js                # Sidebar configuration
├── package.json               # Dependencies
└── README.md                  # This file
```

## 🛠️ Customization

### Theme Configuration

Edit `docusaurus.config.js` to customize:
- Site title and tagline
- Navbar items
- Footer links
- Color mode (light/dark)
- Prism theme for code highlighting

### Sidebar Configuration

Edit `sidebars.js` to:
- Add new categories
- Reorder pages
- Create nested sections
- Control collapsed state

## 🐛 Troubleshooting

### Build Errors

If you encounter build errors:

1. Clear the cache:
   ```bash
   npm run clear
   ```

2. Reinstall dependencies:
   ```bash
   rm -rf node_modules package-lock.json
   npm install
   ```

3. Check for broken links:
   ```bash
   npm run build
   ```

## 📚 Resources

- [Docusaurus Documentation](https://docusaurus.io/docs)
- [Markdown Guide](https://www.markdownguide.org/)
- [FlorisBoard Repository](https://github.com/florisboard/florisboard)
- [FlorisBoard Wiki](https://github.com/florisboard/florisboard/wiki)

## 📄 License

The documentation is licensed under the same license as FlorisBoard (Apache License 2.0).

## 🤝 Contributing

Contributions to the documentation are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

For major changes, please open an issue first to discuss what you would like to change.

---

**Happy documenting!** 📝

