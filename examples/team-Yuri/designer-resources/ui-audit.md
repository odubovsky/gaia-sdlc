---

name: ui-audit

description: Comprehensive UI quality audit with actionable improvement recommendations

category: analysis

tags: \[audit, analysis, review, recommendations, quality-check]

appliesTo: \[screen, section, component, layout]

modifiesCode: false

difficulty: easy

outputFormat: structured-recommendations

comprehensive: true

requiresCommandLibrary: true

---



Analyze the current screen, section, or component described by the user.

Do not modify the code.

Your task is to audit the UI and suggest the most useful improvements using the existing command library.

Audit the following aspects:

Structure:

* identify the main screen or section
* identify the most important UI components
* identify whether the layout feels clear or crowded

Spacing and typography:

* check spacing consistency
* check internal padding
* check visual grouping
* check hierarchy of headings, subheadings, and body text
* check readability

Visual depth and interaction:

* check whether cards feel flat or well separated
* check whether key images need more visual emphasis
* check whether buttons and interactive elements need hover feedback
* check whether the hero section has enough focus

Scroll and motion opportunities:

* check whether any section would benefit from scroll reveal
* check whether any major section would benefit from subtle parallax
* check whether a multi-item section would benefit from horizontal scrolling

Output format:

UI summary:

* short summary of the current screen

Main issues:

* bullet list of the main weaknesses

Recommended commands:

* command name
* target element or section
* short reason

Important rules:

* only recommend commands from the current command library
* do not invent new commands
* do not modify the code
* keep recommendations practical and minimal
