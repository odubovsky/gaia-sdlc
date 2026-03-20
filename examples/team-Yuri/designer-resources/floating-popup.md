---

name: floating-popup

description: Display a timed floating notification popup that appears after a delay to drive conversion

category: conversion-effects

tags: [popup, notification, cta, conversion, timed, floating, engagement]

appliesTo: [page, screen, landing-section, hero-section]

modifiesCode: true

difficulty: easy

visualImpact: moderate

designStyle: conversion-focused

performanceImpact: minimal

accessibility: dismissible

requires: vanilla-js

triggerType: time-based

defaultDelay: 35

---

Locate the page or screen described by the user.

Add a floating popup notification that appears after a delay to present a soft call-to-action, while preserving the existing layout and design direction.

Rules:

* do not change existing content
* do not block the main content area
* keep the popup small and non-intrusive
* show only once per session using localStorage

Popup behavior guidelines:

* trigger: appears after 35 seconds of page dwell time (configurable)
* position: bottom-left corner (RTL-friendly) or bottom-right
* size: 280px wide maximum
* auto-dismiss: disappears after 8 seconds if not interacted with
* close button: visible X in top-right corner of popup

Animation specs:

* entrance: translateY(20px) → translateY(0), opacity 0 → 1
* easing: cubic-bezier(0.34, 1.56, 0.64, 1) for slight bounce
* duration: 0.4s
* exit: fade out 0.3s ease

Content structure:

* title: short and urgent (max 6 words)
* body: one sentence with clear value proposition
* CTA: single action button or link

Installation:

* no npm required
* CSS + Vanilla JS only
* uses localStorage to prevent repeat shows

Design discipline:

* match popup style to brand (glassmorphism or solid card)
* keep z-index above all content (500+)
* never cover the main CTA or navigation
* mobile: position bottom-center, full width minus padding

Accessibility:

* popup should be dismissible with Escape key
* focus should move to popup on appearance
* include role="dialog" and aria-label
