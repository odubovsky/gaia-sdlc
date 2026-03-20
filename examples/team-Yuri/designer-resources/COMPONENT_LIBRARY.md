# COMPONENT_LIBRARY.md
> רוני קוראת קובץ זה כשהיא בוחרת אינטראקציות לפרויקט.
> לכל component: תיאור, מתי להשתמש, ספריה נדרשת, הוראות התקנה, קוד בסיס.

---

## איך רוני משתמשת בקובץ זה

1. בוחרת components לפי Story Arc ומטרת הפרויקט
2. מעתיקה את פקודות ה-installation ל-designplan.md
3. מצרפת את ה-specs המדויקים לכל component
4. ה-developer מממש בדיוק לפי ה-plan

---

## מיפוי: מטרה עסקית → Components מומלצים

| מטרת הלקוח | Components לבחור |
|---|---|
| "שיבינו מה אני עושה" | hotspot_pulse + tooltip_popup + step_reveal |
| "שיצרו איתי קשר" | magnetic_cta + floating_popup + chat_faq |
| "שיקנו / ישאירו פרטים" | calculator_widget + social_proof_float + quiz_flow |
| "שיכירו את המותג שלי" | scroll_storytelling + parallax_layers + lottie_trigger |
| "להיות שונה מהמתחרים" | cursor_follower + text_scramble + tilt_card |
| "להסביר תהליך מורכב" | step_reveal + hotspot_pulse + before_after_slider |
| "לבנות אמון" | testimonial_drag + number_counter + logo_marquee |

---

## מתי לא להוסיף אינטראקציות

```
קהל 55+          → scroll_reveal עדין בלבד
אתר רפואי/משפטי  → tooltip_popup בלבד, ללא cursor effects
"נקי ומינימליסטי" → magnetic_cta אחד בלבד
חוק הזהב: אם הסיבה לאינטראקציה היא "כי אפשר" — לא מוסיפים.
           הסיבה חייבת להיות "כי זה משרת את הסיפור".
```

---

## COMPONENT SPECS

---

### 1. scroll_reveal
**מה זה:** אלמנטים נכנסים לתצוגה עם stagger בזמן גלילה
**מתי:** כמעט בכל פרויקט — ב-ACT 2 ו-ACT 4
**ספרייה:** GSAP + ScrollTrigger

```
INSTALLATION:
npm install gsap
או CDN:
<script src="https://cdnjs.cloudflare.com/ajax/libs/gsap/3.12.2/gsap.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/gsap/3.12.2/ScrollTrigger.min.js"></script>

SPEC לdesignplan:
- trigger: כשהאלמנט נכנס ל-80% מהמסך
- animation: fade up (y: 40px → 0, opacity: 0 → 1)
- duration: 0.7s
- stagger: 0.15s בין אלמנטים
- easing: "power2.out"
```

---

### 2. parallax_layers
**מה זה:** שכבות נעות במהירויות שונות — תחושת עומק תלת-מימדי
**מתי:** ACT 1 (Hero section) — נותן תחושת חיים מהשנייה הראשונה
**ספרייה:** GSAP + ScrollTrigger

```
INSTALLATION: (זהה ל-scroll_reveal)

SPEC לdesignplan:
- שכבה קדמית: מהירות 0.3 (זז לאט)
- שכבה אמצעית: מהירות 0.6
- שכבה אחורית: מהירות 1.0 (זז מהיר)
- כיוון: vertical scroll → vertical movement
- מספר שכבות מומלץ: 3-4
```

---

### 3. cursor_follower
**מה זה:** עיגול/blob רך שעוקב אחרי הסמן, משנה צורה על hover
**מתי:** פורטפוליו, מותג אישי, WOW bundle — ACT 1
**ספרייה:** GSAP בלבד

```
INSTALLATION: (זהה ל-scroll_reveal)

SPEC לdesignplan:
- צורה: עיגול 20px רגיל, מתרחב ל-60px על hover של כפתורים
- צבע: brand color עם opacity 0.3
- lag: 0.1s (לא עוקב מיידי — נותן תחושת נוזל)
- mix-blend-mode: difference (לאפקט מעניין על טקסט)
- cursor המקורי: נסתר (cursor: none על body)
```

---

### 4. magnetic_cta
**מה זה:** כפתור ה-CTA הראשי נמשך לעבר הסמן כשהוא קרוב
**מתי:** כמעט בכל פרויקט — ACT 5, ה-CTA הראשי בלבד
**ספרייה:** Vanilla JS (ללא ספרייה חיצונית)

```
INSTALLATION: אין — Vanilla JS בלבד

SPEC לdesignplan:
- radius הפעלה: 100px סביב הכפתור
- עוצמת משיכה: 0.4 (40% מהמרחק)
- transition: 0.3s ease-out
- reset: חזרה למקום מקורי בצורה חלקה כשהסמן עוזב
- להחיל רק על כפתור CTA אחד ראשי — לא על כל הכפתורים
```

---

### 5. hotspot_pulse
**מה זה:** נקודה פועמת על תמונה/גרפיקה, לחיצה פותחת tooltip או modal
**מתי:** ACT 3 — להסביר מוצר/שירות מורכב ויזואלית
**ספרייה:** CSS Animations + Vanilla JS

```
INSTALLATION: אין — CSS + JS בלבד

SPEC לdesignplan:
- צורה: עיגול 12px עם ripple animation (גלים יוצאים החוצה)
- צבע: brand accent color
- ripple: 3 גלים עם animation-delay: 0s, 0.4s, 0.8s
- on click: tooltip נפתח smooth עם fade-in 0.3s
- tooltip תוכן: כותרת קצרה + משפט הסבר + optional CTA
- מספר נקודות מומלץ לתמונה: 3-5 מקסימום
```

---

### 6. floating_popup
**מה זה:** הודעה קופצת שמגיעה אחרי X שניות עם הנעה לפעולה
**מתי:** ACT 5 — כשהמשתמש כבר בדף ומחליט
**ספרייה:** CSS + Vanilla JS

```
INSTALLATION: אין — CSS + JS בלבד

SPEC לdesignplan:
- trigger: 35 שניות שהייה בדף (לא גלילה — זמן)
- מיקום: פינה תחתונה שמאל (RTL) או ימין (LTR)
- גודל: 280px רוחב
- animation כניסה: slide up + fade in, 0.4s ease-out
- תוכן: כותרת + משפט אחד + כפתור CTA
- סגירה: X button + סגירה אוטומטית אחרי 8 שניות
- frequency: להציג פעם אחת בלבד (localStorage)
```

---

### 7. calculator_widget
**מה זה:** מחשבון שמראה תוצאה אישית בזמן אמת לפי קלט המשתמש
**מתי:** ACT 3 — כשהמוצר/שירות ניתן לכמת (חיסכון, תשואה, זמן)
**ספרייה:** Vanilla JS (ללא ספרייה)

```
INSTALLATION: אין — Vanilla JS בלבד

SPEC לdesignplan:
- inputs: sliders ו/או number inputs (לא טקסט חופשי)
- output: מספר גדול שמתעדכן בזמן אמת עם כל שינוי
- animation: count-up של 0.5s כל שינוי
- design: output בולט מאוד ויזואלית (גדול, צבע brand)
- CTA: מתחת לתוצאה — "רוצה לדעת איך להגיע לזה? דברו איתנו"
- לכלול נוסחה עסקית ספציפית לתחום הלקוח
```

---

### 8. quiz_flow
**מה זה:** שאלון קצר שמוביל לתוצאה/המלצה מותאמת אישית
**מתי:** ACT 3 — כשיש כמה סוגי לקוחות / מוצרים
**ספרייה:** Vanilla JS או React

```
INSTALLATION (React): npm install react (אם הפרויקט כבר React)
INSTALLATION (Vanilla): אין

SPEC לdesignplan:
- מספר שאלות: 3-5 מקסימום
- סוג שאלות: single choice (כפתורים, לא dropdown)
- transition בין שאלות: slide + fade, 0.3s
- progress bar: מעל השאלות
- תוצאה: מותאמת אישית לפי בחירות + CTA ספציפי
- design: כל שאלה מסך מלא או כרטיס גדול — לא טופס
```

---

### 9. lottie_trigger
**מה זה:** איור מונפש (JSON) שמופעל בגלילה או לחיצה
**מתי:** ACT 1 או ACT 3 — כשרוצים ויזואל שאי אפשר לעשות ב-CSS
**ספרייה:** Lottie Web

```
INSTALLATION:
npm install lottie-web
או CDN:
<script src="https://cdnjs.cloudflare.com/ajax/libs/lottie-web/5.12.2/lottie.min.js"></script>

SPEC לdesignplan:
- קובץ: animation.json (לקבל מהלקוח או ממאגר LottieFiles.com)
- trigger: scroll (מופעל כש-section נכנס לתצוגה)
- playback: once (לא לופ — אלא אם מדובר ב-Hero)
- גודל: להגדיר container מפורש (לא auto)
- fallback: תמונה סטטית למקרה שJS לא נטען
- מאגר חינמי: https://lottiefiles.com/featured
```

---

### 10. text_scramble
**מה זה:** טקסט "מתערבב" ואז מתגלה מחדש בהובר או בטעינה
**מתי:** ACT 1 — על כותרות Hero, WOW bundle
**ספרייה:** Vanilla JS (אלגוריתם פשוט)

```
INSTALLATION: אין — Vanilla JS בלבד

SPEC לdesignplan:
- trigger: hover על הכותרת / כניסה לדף
- characters: "!<>-_\\/[]{}—=+*^?#________"
- duration: 1.5s מ-scramble ל-revealed
- frames: 10 frames של randomization לפני reveal
- להחיל על: כותרת ראשית בלבד (לא על כל טקסט)
```

---

### 11. before_after_slider
**מה זה:** גרירת קו שמשווה שתי תמונות / מצבים
**מתי:** ACT 2 — להראות מצב לפני ואחרי השירות
**ספרייה:** Vanilla JS

```
INSTALLATION: אין — Vanilla JS + CSS בלבד

SPEC לdesignplan:
- drag handle: עיגול עם חצים משני הצדדים
- default position: 50% (אמצע)
- touch support: כן (חובה)
- labels: "לפני" / "אחרי" על כל צד
- transition: חלק (no snap)
```

---

### 12. number_counter
**מה זה:** מספרים "רצים" מ-0 לערך הסופי כשנכנסים לתצוגה
**מתי:** ACT 2 (גודל הבעיה) או ACT 4 (תוצאות ועובדות)
**ספרייה:** GSAP או Vanilla JS

```
INSTALLATION (GSAP): (ראה scroll_reveal)
INSTALLATION (Vanilla): אין

SPEC לdesignplan:
- trigger: IntersectionObserver — כשהמספר נכנס לתצוגה
- duration: 2s
- easing: ease-out (מהיר בהתחלה, מאט בסוף)
- format: לכלול סיומת (%, ₪, +, X) שנשארת קבועה
- להפעיל פעם אחת בלבד
```

---

### 13. tilt_card
**מה זה:** כרטיס מסתובב ב-3D בעקבות תנועת הסמן
**מתי:** פורטפוליו, כרטיסי מוצר — WOW bundle
**ספרייה:** VanillaTilt.js

```
INSTALLATION:
npm install vanilla-tilt
או CDN:
<script src="https://cdnjs.cloudflare.com/ajax/libs/vanilla-tilt/1.8.1/vanilla-tilt.min.js"></script>

SPEC לdesignplan:
- max tilt: 15 degrees
- speed: 400ms
- glare: true (אפקט ברק)
- max-glare: 0.3
- perspective: 1000px
- scale: 1.05 (כרטיס גדל קצת בהובר)
```

---

### 14. testimonial_drag
**מה זה:** המלצות שמשתמש גורר ביד (swipe/drag)
**מתי:** ACT 4 — social proof
**ספרייה:** Swiper.js

```
INSTALLATION:
npm install swiper
או CDN:
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/swiper@11/swiper-bundle.min.css"/>
<script src="https://cdn.jsdelivr.net/npm/swiper@11/swiper-bundle.min.js"></script>

SPEC לdesignplan:
- mode: grab cursor (כפתורים לא נראים — רק drag)
- loop: true
- autoplay: false (רק drag ידני)
- slides visible: 1.2 (הצצה לכרטיס הבא)
- touch ratio: 1 (responsive לtouch)
```

---

### 15. social_proof_float
**מה זה:** הודעה קטנה בפינה "X רכש לפני 5 דקות"
**מתי:** ACT 4 או ACT 5 — ליצור תחושת ביקוש
**ספרייה:** Vanilla JS

```
INSTALLATION: אין

SPEC לdesignplan:
- מיקום: פינה תחתונה שמאל
- תוכן: שם + פעולה + "לפני X דקות"
- interval: מופיעה כל 45 שניות
- animation: slide in מהשמאל, נעלמת אחרי 5 שניות
- data: מערך של 5-10 רשומות שמתחלפות (לא חייב להיות real-time)
```

---

### 16. chat_faq
**מה זה:** שאלות נפוצות בפורמט שיחה — דיאלוג, לא אקורדיון
**מתי:** כמעט בכל פרויקט — בתחתית הדף
**ספרייה:** Vanilla JS

```
INSTALLATION: אין

SPEC לdesignplan:
- design: בועות שיחה (כמו WhatsApp) — שאלה מימין, תשובה משמאל
- interaction: לחיצה על שאלה → תשובה מופיעה עם typing animation
- typing animation: 3 נקודות לפני התשובה (0.8s)
- שאלות: 5-7 שאלות נפוצות של הלקוח
- הודעה אחרונה: תמיד CTA ("עדיין יש לך שאלה? דבר איתנו →")
```

---

### 17. scroll_progress_bar
**מה זה:** סרגל דק בראש הדף שמראה כמה אחוז מהדף עברת
**מתי:** דפים ארוכים עם הרבה תוכן
**ספרייה:** Vanilla JS

```
INSTALLATION: אין

SPEC לdesignplan:
- מיקום: top של ה-viewport, fixed
- גובה: 3px
- צבע: brand gradient
- z-index: גבוה מאוד (מעל הכל)
- animation: smooth (no jumps)
```

---

### 18. step_reveal
**מה זה:** תהליך שנחשף שלב אחרי שלב — לחיצה מקדמת
**מתי:** ACT 3 — להסביר תהליך עבודה מורכב
**ספרייה:** GSAP או Vanilla JS

```
INSTALLATION (GSAP): (ראה scroll_reveal)

SPEC לdesignplan:
- מספר שלבים: 3-6 מקסימום
- navigation: כפתורי "הבא" / "קודם" + dots indicator
- transition: slide + fade, 0.4s
- auto-advance: לא (המשתמש שולט)
- כל שלב: מספר + כותרת + תיאור + optional icon/image
```

---

### 19. logo_marquee
**מה זה:** לוגואים של לקוחות/שותפים גוללים אוטומטית בלופ
**מתי:** ACT 4 — social proof מהיר
**ספרייה:** CSS Animation בלבד

```
INSTALLATION: אין — CSS בלבד

SPEC לdesignplan:
- speed: 30s לסיבוב מלא
- direction: RTL לעברית
- hover: מאט ל-60s
- duplicate: כפל את הלוגואים לחיבור חלק
- fade edges: gradient mask משני הצדדים
```

---

### 20. spotlight_hover
**מה זה:** אור/gradient עגול שעוקב אחרי הסמן על רקע כהה
**מתי:** sections כהים — נותן תחושת מסתורין ועומק
**ספרייה:** Vanilla JS

```
INSTALLATION: אין

SPEC לdesignplan:
- צורה: radial gradient עגול, 400px קוטר
- opacity: 0.15 (עדין, לא דומיננטי)
- צבע: brand color (לבן או accent)
- lag: 0 (עוקב מיידי — שונה מ-cursor follower)
- להחיל על: sections עם רקע כהה בלבד
```
