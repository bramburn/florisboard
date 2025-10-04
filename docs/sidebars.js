/**
 * Creating a sidebar enables you to: 
 - Create an ordered group of docs
 - Render a sidebar for each doc of that group
 - Provide next/previous navigation

 The sidebars can be generated from the filesystem, or explicitly defined here.

 Create as many sidebars as you want. 
 */

// @ts-check

/** @type {import('@docusaurus/plugin-content-docs').SidebarsConfig} */
const sidebars = {
  tutorialSidebar: [
    {
      type: 'doc',
      id: 'index',
      label: 'Welcome',
    },
    {
      type: 'category',
      label: 'Getting Started',
      collapsed: false,
      items: [
        'getting-started/introduction',
        'getting-started/prerequisites',
        'getting-started/cloning-the-repository',
        'getting-started/opening-in-android-studio',
        'getting-started/initial-build-and-run',
      ],
    },
    {
      type: 'category',
      label: 'Architecture',
      collapsed: false,
      items: [
        'architecture/overview',
        'architecture/project-structure',
        'architecture/design-patterns',
        'architecture/state-management',
        'architecture/performance',
        'architecture/extensions',
      ],
    },
    {
      type: 'category',
      label: 'Technical Details',
      collapsed: true,
      items: [
        'technical/input-pipeline',
        'technical/custom-ui',
        'technical/layout-system',
        'technical/touch-gestures',
        'technical/prediction-engine',
        'technical/i18n',
        'technical/accessibility',
      ],
    },
    {
      type: 'category',
      label: 'Android Integration',
      collapsed: true,
      items: [
        'integration/apis',
        'integration/native-code',
        'integration/testing',
        'integration/build-system',
        'integration/system-settings',
        'integration/deployment',
      ],
    },
    {
      type: 'category',
      label: 'Reverse Engineering',
      collapsed: true,
      items: [
        'reverse-engineering/questions',
        'reverse-engineering/methodology',
      ],
    },
    {
      type: 'category',
      label: 'Case Studies',
      collapsed: true,
      items: [
        'case-study/florisboard',
        'case-study/comparison',
      ],
    },
    {
      type: 'category',
      label: 'How-To Guides',
      collapsed: true,
      items: [
        'how-to/build-from-scratch',
      ],
    },
    {
      type: 'category',
      label: 'FAQ',
      collapsed: true,
      items: [
        'faq/common-pitfalls',
        'faq/security-privacy',
      ],
    },
  ],
};

export default sidebars;