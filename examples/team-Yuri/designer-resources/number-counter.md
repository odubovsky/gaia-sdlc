---

name: number-counter

description: Animate numeric statistics from zero to their target value when they enter the viewport

category: motion-effects

tags: [counter, number, stats, animation, scroll, entrance, social-proof]

appliesTo: [stats-section, achievement-block, metrics-section, hero-section, proof-section]

modifiesCode: true

difficulty: easy

visualImpact: moderate

designStyle: dynamic-data

performanceImpact: minimal

accessibility: motion-reducible

requires: intersection-observer, vanilla-js

triggerType: scroll-viewport-entry

fireOnce: true

---

Locate the stats, metrics, or achievement section described by the user.

Animate numeric values from 0 to their target when they scroll into the viewport, while preserving layout and design.

Rules:

* do not change the displayed numbers or labels
* do not redesign the section
* fire animation only once per page load
* preserve readability at all times

Counter animation guidelines:

* trigger: IntersectionObserver when element enters viewport (threshold: 0.3)
* start value: 0
* end value: the existing number in the DOM
* duration: 2000ms
* easing: ease-out (fast start, slows to final value)
* fire once: true (does not repeat on re-scroll)

Number formatting:

* preserve existing suffixes: %, +, ₪, $, x, k
* preserve existing prefixes if any
* round to integer during animation
* snap to exact final value on completion

Animation specs:

* easing formula: easeOutCubic = 1 - Math.pow(1 - progress, 3)
* update frequency: requestAnimationFrame
* stagger between multiple counters: 150ms

Installation:

* no npm required
* Vanilla JS + IntersectionObserver API (native browser support)

Design discipline:

* do not change font size or weight of the numbers
* optionally add a brief color pulse on completion (brand accent, 0.3s)
* keep the surrounding labels visible and stable during animation

Accessibility:

* include aria-live="polite" on counter elements
* respect prefers-reduced-motion: skip animation, show final value immediately
