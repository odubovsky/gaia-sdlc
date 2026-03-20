---

name: calculator-widget

description: Add an interactive real-time calculator that shows personalized value output as users adjust inputs

category: gamification

tags: [calculator, interactive, roi, conversion, slider, realtime, engagement, gamification]

appliesTo: [section, cta-section, feature-section, pricing-section, proof-section]

modifiesCode: true

difficulty: medium

visualImpact: high

designStyle: conversion-interactive

performanceImpact: low

accessibility: keyboard-accessible

requires: vanilla-js

engagementType: active-participation

---

Locate the section described by the user.

Add an interactive calculator widget that computes and displays a personalized result in real-time as the user adjusts sliders or inputs, while matching the existing design direction.

Rules:

* do not change existing surrounding content
* match the calculator visual style to the page design system
* keep inputs to 2–3 maximum (avoid overwhelming the user)
* always show a large, prominent result output

Calculator structure:

* inputs: range sliders preferred over text fields (easier interaction)
* output: large number displayed prominently with label and unit
* update: result recalculates instantly on every input change (no submit button)
* CTA: place a call-to-action below the result

Animation specs:

* result update: count-up animation from previous value to new value (0.5s)
* easing: ease-out
* input slider: smooth thumb movement, real-time response
* result color: brief brand accent pulse on change (0.2s)

Content guidance (ask user for):

* what does the user input? (budget, time, team size, quantity...)
* what is the output? (savings, ROI, revenue, time saved...)
* what is the formula connecting input to output?
* what is the CTA after seeing the result?

Installation:

* no npm required
* Vanilla JS only

Design discipline:

* result number should be the largest visual element in the widget
* use brand accent color for the result value
* keep surrounding text minimal — let the number speak
* add a subtle card container (floating-card or glass-card style)

Accessibility:

* all sliders must have aria-label and aria-valuenow
* result must have aria-live="polite" for screen reader updates
* keyboard: sliders controllable with arrow keys
