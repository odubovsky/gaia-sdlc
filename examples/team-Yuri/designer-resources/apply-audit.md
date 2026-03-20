---

name: apply-audit

description: Automatically apply UI improvements recommended by ui-audit command

category: automation

tags: \[automation, audit, apply, implement, batch]

appliesTo: \[screen, page, component, section]

modifiesCode: true

difficulty: medium

requires: ui-audit

executionMode: automatic

safetyLevel: conservative

---



Locate the most recent UI audit recommendations produced by the ui-audit command.

Your task is to apply the recommended improvements automatically.

Rules:

* only execute commands that were explicitly recommended by the last ui-audit
* do not invent new commands
* preserve the existing layout and content
* keep the design direction unchanged

Execution behavior:

1. Identify each recommended command.
2. Identify the target element or section.
3. Apply the command directly to the code.

If multiple improvements affect the same element:

* combine them carefully
* avoid visual overload
* prioritize readability and clarity.

Important constraints:

* do not redesign the interface
* do not remove existing components
* do not introduce excessive motion or decoration

Output format:

Applied changes:

* command name
* target element
* short description of the change

If any recommendation cannot be applied safely:

* skip it
* explain briefly why it was skipped
