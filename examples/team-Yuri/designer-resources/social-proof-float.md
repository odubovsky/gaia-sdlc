---

name: social-proof-float

description: Display rotating live-style social proof notifications in the corner of the screen

category: conversion-effects

tags: [social-proof, notification, trust, conversion, live, floating, credibility]

appliesTo: [page, screen, landing-page, product-section]

modifiesCode: true

difficulty: easy

visualImpact: subtle

designStyle: trust-building

performanceImpact: minimal

accessibility: non-blocking

requires: vanilla-js

triggerType: interval-based

defaultInterval: 45

---

Locate the page or screen described by the user.

Add floating social proof notifications that appear periodically in the corner of the screen, showing recent activity or customer actions, while not disrupting the main content.

Rules:

* do not block any interactive elements
* keep notifications small and non-intrusive
* rotate through a predefined list of messages (not real-time API)
* never show more than one notification at a time

Notification behavior:

* trigger: first appears after 10 seconds, then every 45 seconds
* position: bottom-left corner (RTL) or bottom-right (LTR)
* visible duration: 5 seconds then auto-dismisses
* rotation: cycles through array of 5–10 predefined messages

Animation specs:

* entrance: translateX(-110%) → translateX(0), opacity 0 → 1
* easing: cubic-bezier(0.34, 1.56, 0.64, 1), duration 0.4s
* exit: translateX(-110%), opacity 0, duration 0.3s ease-in

Notification content structure:

* avatar: initials circle (2 letters, brand color background)
* name: first name + city/country
* action: what they did ("purchased", "booked a call", "downloaded")
* time: "X minutes ago" (use rotating values 2–18 minutes)

Content guidance (ask user for):

* 5–10 example customer names and cities
* what action should be shown? (purchase, signup, booking...)
* should time be shown?

Installation:

* no npm required
* Vanilla JS only

Design discipline:

* card style: match page (glass-card or floating-card)
* size: max 300px wide, compact height
* avatar: 36px circle, brand accent background
* keep text small (12–13px) and concise

Accessibility:

* notification must have role="status" and aria-live="polite"
* must not trap focus
* must be dismissible (X button)
* does not interfere with keyboard navigation
