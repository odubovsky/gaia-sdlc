---

name: before-after-slider

description: Add a draggable divider that reveals a before and after comparison between two states

category: interaction-effects

tags: [before-after, comparison, slider, drag, reveal, transformation, proof]

appliesTo: [image, section, hero-section, proof-section, result-section]

modifiesCode: true

difficulty: medium

visualImpact: high

designStyle: visual-proof

performanceImpact: low

accessibility: keyboard-accessible

touchSupport: true

requires: vanilla-js

---

Locate the image, section, or visual element described by the user.

Add a draggable before/after slider that allows the user to reveal two states of the same image or content by dragging a dividing line, while preserving the surrounding layout.

Rules:

* do not change surrounding content
* always require two distinct states (before and after)
* default divider position: 50% (center)
* support both mouse drag and touch swipe

Slider behavior:

* drag handle: circular button centered on the dividing line
* drag direction: horizontal only
* range: 5% to 95% (never fully hidden)
* smooth follow: no snapping, fluid drag

Animation specs:

* drag transition: none (real-time follow)
* initial load: animate divider from 30% to 50% on mount (0.8s ease-out) to hint interaction
* handle hover: subtle scale(1.1) and shadow increase

Handle design:

* size: 44px circle (touch-friendly)
* content: left/right arrow icons on either side
* color: white with subtle shadow
* border: 2px solid brand accent color

Labels:

* "לפני" label on left side (or "Before")
* "אחרי" label on right side (or "After")
* labels: small pill, semi-transparent background, top corners

Content guidance (ask user for):

* what are the two states being compared?
* are these images or UI screenshots?
* what labels should appear?

Installation:

* no npm required
* Vanilla JS + CSS clip-path or overflow hidden

Design discipline:

* container must have defined height (not auto)
* both images must be same dimensions
* avoid using on very narrow mobile widths (< 320px)

Accessibility:

* slider must be keyboard controllable (left/right arrow keys)
* include aria-label="comparison slider"
* include aria-valuenow (percentage position)
* touch: use touch events (touchstart, touchmove)
