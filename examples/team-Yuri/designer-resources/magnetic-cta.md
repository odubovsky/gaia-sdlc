---

name: magnetic-cta

description: Add a magnetic attraction effect to the primary CTA button that pulls toward the cursor

category: interaction-effects

tags: [cta, button, magnetic, hover, cursor, attraction, conversion, premium]

appliesTo: [button, cta-button, primary-action, hero-cta]

modifiesCode: true

difficulty: medium

visualImpact: subtle

designStyle: premium-interactive

performanceImpact: minimal

accessibility: hover-only

touchDevices: disabled

applyTo: primary-cta-only

---

Locate the primary CTA button described by the user.

Apply a magnetic attraction effect where the button gently pulls toward the cursor when nearby, while preserving all layout and design.

Rules:

* apply to ONE primary CTA button only
* do not apply to secondary buttons, nav links, or form elements
* do not change button text or styling
* disable on touch devices (no hover equivalent)

Magnetic effect guidelines:

* activation radius: 100px around the button center
* pull strength: 0.4 (button moves 40% of cursor distance from center)
* movement: smooth follow using mousemove event
* return: button snaps back to original position on mouseleave

Animation specs:

* movement transition: none (follows cursor in real-time)
* return transition: transform 0.3s cubic-bezier(0.25, 0.46, 0.45, 0.94)
* return easing: elastic feel — slight overshoot back to center
* max displacement: 12px in any direction

Installation:

* no npm required
* Vanilla JS mousemove listener only
* use getBoundingClientRect() to calculate cursor distance

Design discipline:

* keep movement subtle — the button should feel alive, not broken
* do not combine with soft-hover scale on the same button (visual conflict)
* pair well with a cursor-follower effect on the same page

Accessibility:

* magnetic effect is purely cosmetic and does not affect keyboard navigation
* button remains fully functional and focusable without mouse
* touch devices: effect is automatically disabled via pointer media query
