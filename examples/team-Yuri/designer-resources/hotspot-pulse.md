---

name: hotspot-pulse

description: Add pulsing interactive hotspot dots to images or sections that reveal tooltips or modals on click

category: interaction-effects

tags: [hotspot, pulse, tooltip, interactive, reveal, product, explainer]

appliesTo: [image, hero-image, product-image, section, feature-section]

modifiesCode: true

difficulty: medium

visualImpact: moderate

designStyle: interactive-premium

performanceImpact: low

accessibility: keyboard-accessible

requires: vanilla-js, css-animation

---

Locate the image, section, or visual element described by the user.

Apply pulsing hotspot dots that reveal information on hover or click, while preserving the original layout and content.

Rules:

* do not change text content
* do not redesign the surrounding layout
* keep dots subtle and purposeful
* maximum 5 hotspots per image

Hotspot effect guidelines:

* place a small circular dot (12–14px) at meaningful points on the image
* animate the dot with a ripple/pulse effect using 2–3 expanding rings
* on hover or click: reveal a tooltip or small card with title + short description
* tooltip appears above the dot with a smooth fade-in (0.25s ease)

Animation specs:

* ripple animation: scale 1 → 2.8, opacity 0.6 → 0, duration 1.8s, infinite
* wave delay: 0s, 0.6s (two waves offset)
* tooltip transition: opacity 0 → 1, translateY 4px → 0, duration 0.25s

Installation:

* no npm required
* CSS animation + Vanilla JS only

Design discipline:

* dot color should use brand accent color
* keep tooltip minimal: title + one sentence max
* avoid placing dots on text or CTAs
* ensure dots are visible against both light and dark backgrounds

Accessibility:

* each hotspot should be keyboard-focusable (tabindex="0")
* tooltip should appear on focus as well as hover
* include aria-label on each hotspot dot
