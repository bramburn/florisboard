#!/bin/bash

# Script to generate placeholder documentation files for FlorisBoard
# This creates the structure for all documentation pages

set -e

DOCS_DIR="docs"

# Create directory structure
mkdir -p "$DOCS_DIR/architecture"
mkdir -p "$DOCS_DIR/technical"
mkdir -p "$DOCS_DIR/integration"
mkdir -p "$DOCS_DIR/reverse-engineering"
mkdir -p "$DOCS_DIR/case-study"
mkdir -p "$DOCS_DIR/how-to"
mkdir -p "$DOCS_DIR/faq"

# Function to create a documentation file with placeholder content
create_doc() {
    local file_path="$1"
    local title="$2"
    local description="$3"
    
    if [ ! -f "$file_path" ]; then
        cat > "$file_path" << EOF
# $title

## Overview

$description

## Introduction

This document is part of the comprehensive FlorisBoard documentation. It covers $title in detail.

## Key Concepts

(Content to be added)

## Implementation Details

(Content to be added)

## Code Examples

(Content to be added)

## Best Practices

(Content to be added)

## Common Patterns

(Content to be added)

## Troubleshooting

(Content to be added)

## Related Topics

(Content to be added)

## Next Steps

(Content to be added)

---

**Note**: This documentation is continuously being improved. Contributions are welcome!
EOF
        echo "Created: $file_path"
    else
        echo "Skipped (exists): $file_path"
    fi
}

# Architecture documents
create_doc "$DOCS_DIR/architecture/state-management.md" \
    "Keyboard State Management" \
    "Learn how FlorisBoard manages and propagates keyboard state throughout the application using reactive patterns and StateFlow."

create_doc "$DOCS_DIR/architecture/performance.md" \
    "Touch and Performance Optimizations" \
    "Discover the performance optimizations implemented in FlorisBoard for touch handling, rendering, and input latency reduction."

create_doc "$DOCS_DIR/architecture/extensions.md" \
    "Theme & Extension System" \
    "Understand how FlorisBoard's extension system works, including themes, layouts, and language packs."

# Technical documents
create_doc "$DOCS_DIR/technical/custom-ui.md" \
    "Custom UI Components & KeyboardView" \
    "Explore how FlorisBoard builds custom keyboard UI components using Jetpack Compose."

create_doc "$DOCS_DIR/technical/layout-system.md" \
    "Layout Definition & Switching" \
    "Learn how keyboard layouts are defined in JSON, loaded dynamically, and switched between different languages and modes."

create_doc "$DOCS_DIR/technical/touch-gestures.md" \
    "Touch Handling & Gestures" \
    "Deep dive into touch event processing, gesture recognition, and multi-touch support in FlorisBoard."

create_doc "$DOCS_DIR/technical/prediction-engine.md" \
    "Text Prediction & Suggestion Engine" \
    "Understand how FlorisBoard implements text prediction, autocorrect, and word suggestions using NLP providers."

create_doc "$DOCS_DIR/technical/i18n.md" \
    "Internationalization & Multilingual Input" \
    "Learn how FlorisBoard supports multiple languages, locales, and input methods for international users."

create_doc "$DOCS_DIR/technical/accessibility.md" \
    "Accessibility Features" \
    "Discover the accessibility features implemented in FlorisBoard to support users with disabilities."

# Integration documents
create_doc "$DOCS_DIR/integration/apis.md" \
    "Android IME APIs & Service Integration" \
    "Comprehensive guide to Android's InputMethodService API and how FlorisBoard integrates with the Android system."

create_doc "$DOCS_DIR/integration/native-code.md" \
    "JNI & Native Components" \
    "Learn how FlorisBoard integrates native C/C++ code using JNI for performance-critical operations."

create_doc "$DOCS_DIR/integration/testing.md" \
    "Testing Strategies & Coverage" \
    "Explore the testing strategies used in FlorisBoard, including unit tests, integration tests, and UI tests."

create_doc "$DOCS_DIR/integration/system-settings.md" \
    "System Integration & Registration" \
    "Understand how FlorisBoard registers with Android system, handles permissions, and integrates with system settings."

create_doc "$DOCS_DIR/integration/deployment.md" \
    "Release, Updates, Store Distribution" \
    "Learn about the release process, versioning, and distribution channels for FlorisBoard."

# Reverse Engineering documents
create_doc "$DOCS_DIR/reverse-engineering/questions.md" \
    "Reverse Engineering: Key Questions" \
    "A comprehensive list of questions to ask when reverse engineering an IME keyboard application."

create_doc "$DOCS_DIR/reverse-engineering/methodology.md" \
    "Reverse Engineering: Methodology" \
    "Step-by-step methodology for analyzing and understanding complex keyboard implementations."

# Case Study documents
create_doc "$DOCS_DIR/case-study/florisboard.md" \
    "FlorisBoard Case Study" \
    "In-depth analysis of FlorisBoard's architecture, design decisions, and implementation details."

create_doc "$DOCS_DIR/case-study/comparison.md" \
    "Comparison With Other IMEs" \
    "Comparative analysis of FlorisBoard with other popular keyboard implementations like Gboard, OpenBoard, and AnySoftKeyboard."

# How-To documents
create_doc "$DOCS_DIR/how-to/build-from-scratch.md" \
    "Building a Keyboard From Scratch" \
    "Complete guide to building your own Android IME keyboard from scratch, using FlorisBoard as a reference."

# FAQ documents
create_doc "$DOCS_DIR/faq/common-pitfalls.md" \
    "FAQ & Common Pitfalls" \
    "Frequently asked questions and common pitfalls when developing Android IME keyboards."

create_doc "$DOCS_DIR/faq/security-privacy.md" \
    "FAQ: Security & Privacy" \
    "Security and privacy considerations for IME development, including best practices and common concerns."

echo ""
echo "Documentation structure created successfully!"
echo "Run 'npm run start' in the docs directory to preview the documentation."

