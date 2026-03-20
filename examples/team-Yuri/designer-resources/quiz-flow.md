---

name: quiz-flow

description: Add an interactive multi-step quiz that leads to a personalized recommendation or result

category: gamification

tags: [quiz, interactive, personalization, flow, engagement, gamification, lead-generation]

appliesTo: [section, cta-section, hero-section, feature-section, landing-page]

modifiesCode: true

difficulty: medium

visualImpact: high

designStyle: conversational-interactive

performanceImpact: low

accessibility: keyboard-accessible

requires: vanilla-js

engagementType: guided-decision

---

Locate the section described by the user.

Add a multi-step quiz flow that guides the user through 3–5 questions and delivers a personalized result or recommendation, while matching the existing design direction.

Rules:

* do not exceed 5 questions (keep it fast)
* one question displayed at a time (no scrolling through all questions)
* answer options as clickable buttons (never dropdowns or text inputs)
* always end with a personalized result + clear CTA

Quiz structure:

* progress bar: visible at top, updates with each step
* question: large readable heading
* options: 2–4 large clickable buttons per question
* transition: slide + fade between questions (0.3s)
* result screen: personalized title + description + CTA button

Animation specs:

* question transition: current slides out left, next slides in from right
* easing: ease-out, 0.3s
* progress bar: smooth fill animation on each step advance
* result entrance: fade-up, 0.5s ease-out

Content guidance (ask user for):

* what is the user trying to decide or discover?
* what are the 3–5 questions?
* what are the possible results/recommendations?
* what is the CTA for each result?

Installation:

* no npm required
* Vanilla JS only (or React if project uses it)

Design discipline:

* each question should fill a generous card — not a small widget
* option buttons should be large and easy to tap on mobile
* result screen should feel like a reward — make it visually distinct
* use brand colors for selected state and progress bar

Accessibility:

* each step must be keyboard navigable
* selected option must have visible focus state
* progress bar must have aria-valuenow and aria-valuemax
* result must have aria-live="assertive"
