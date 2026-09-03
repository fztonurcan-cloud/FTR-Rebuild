# FTR Akademi — v30 THREE PLAN SCOPE LOCK

Status: USER 100/100 SCOPE LOCK — 2026-09-03

This branch may change **only** the three plans below. All other existing application areas are protected and must remain behaviorally unchanged unless a change is strictly required to expose one of these three approved plans.

## PLAN 1 — Ligament visibility

- Preserve the current static layered anatomy architecture and invisible ID-map selection.
- Preserve the current ivory/cream skeletal context.
- Render every ligament in the Ligamentler beauty atlas as a clearly visible high-contrast red.
- Preserve the current selected-structure purple/bright highlight, so the selected ligament remains visually distinct from the red unselected ligament layer.
- Do not change Kaslar, Kemikler, Damarlar or Sinirler.
- Do not alter pinch zoom, pan, structure browser, information tabs or structure identity data.

## PLAN 2 — Klinik Ölçekler

Create one new independent module named **KLİNİK ÖLÇEKLER** with subtitle **Testler • Skorlamalar • Değerlendirme Araçları**.

Initial locked catalogue (29 instruments, 8 categories):

1. Günlük Yaşam & Fonksiyon: Barthel Index, FIM, Katz GYA, Lawton-Brody IADL.
2. Nörolojik Değerlendirme: Brunnstrom, Fugl-Meyer Assessment, NIHSS, Rivermead Mobility Index.
3. Spastisite & Tonus: Modified Ashworth Scale, Tardieu/Modified Tardieu, Penn Spasm Frequency Scale.
4. Denge & Mobilite: Berg Balance Scale, Timed Up and Go, Tinetti/POMA, Dynamic Gait Index.
5. Ortopedi & Ağrı: Oswestry Disability Index, Neck Disability Index, DASH, WOMAC, Harris Hip Score.
6. Pediatrik Rehabilitasyon: GMFM, GMFCS, Peabody Developmental Motor Scales.
7. El & İnce Motor: Jebsen-Taylor Hand Function Test, Nine-Hole Peg Test, Purdue Pegboard.
8. Genel Sağlık & Kardiyopulmoner: SF-36/RAND-36 licensing distinction, MMSE, 6-Minute Walk Test.

Research/clinical rules:

- Use primary/official or high-quality rehabilitation measurement sources wherever possible.
- Verify Turkish validity/reliability evidence when available and identify the population studied.
- Never present a population-specific cut-off as a universal threshold.
- Keep scoring algorithms, administration instructions and interpretation clinically precise.
- Do not fabricate missing academic details.
- Respect copyright/licensing. Do not reproduce protected proprietary questionnaire/item text in the app without confirmed permission.
- Instruments that cannot legally be embedded remain rich educational/reference pages with licensing status and official-source guidance; interactive scoring is enabled only when the instrument can be implemented legally.
- Each instrument receives a purpose-matched original visual/diagram representing its clinical administration or measured domain; copyrighted web forms/photos are not copied.
- Module is offline-first and must remain usable on the low-end Android acceptance device.

## PLAN 3 — Full user-approved premium visual design + exact branding + navigation bridge

The user-supplied reference image `ChatGPT Image 3 Eyl 2026 13_01_16.png` is the **100/100 visual lock**. It is not merely inspiration.

Latest user decision: **do not simplify Plan 3 back to logo-only. Implement the approved premium design shown in the reference and continue from that decision.**

Required visual/branding behavior:

- Use the exact approved skull + full spine + cyan/blue laurel/arc FTR Akademi mark from the supplied reference. Do not regenerate, reinterpret, redraw or substitute a different logo when the exact source asset is available.
- Implement the reference's dark navy/black premium application shell, top bar, logo proportions, drawer/header presentation, card styling, spacing, typography hierarchy, icon treatment and bottom navigation language as closely as technically possible.
- The home presentation shown in the approved reference is part of Plan 3. Preserve all existing working home content/behaviors while applying this approved visual treatment; do not delete or functionally rewrite unrelated modules.
- The Klinik Ölçekler visual presentation shown in the reference is also part of the approved Plan 3 visual system, while its clinical content remains governed by Plan 2.
- **Launcher visual parity is part of Plan 3:** the icon visible on the Android phone home/app screen must use the same canonical exact FTR Akademi artwork as the in-app premium brand. The canonical exact logo file remains hash-locked and must not be AI-regenerated, traced, recolored or substituted.
- **Startup visual parity is part of Plan 3:** when the app opens, the previous light welcome artwork is visually superseded by a dark premium startup presentation using the exact canonical FTR mark, the existing offline anatomy asset and an explicit visible **BAŞLA** control. This is presentation-only; authentication and application business logic remain unchanged.
- The FTR Akademi logo is an active Home control: tapping it from any approved module returns directly to Ana Sayfa.
- Normal Back/Android back follows hierarchy rather than acting as Home. Example: Berg → Denge & Mobilite → Klinik Ölçekler → Ana Sayfa.
- Preserve prior screen/list position when returning where practical.
- Do not invent an alternate premium theme, rearrange content arbitrarily, or replace the approved reference with a different design concept.
- Plan 3 is a visual/navigation layer only: existing unrelated business logic, content, data and working feature behavior remain protected.

## PROTECTED AREAS — DO NOT CHANGE FUNCTIONAL CONTENT OR BEHAVIOR

Unless a minimal host bridge or approved Plan 3 visual wrapper is required solely to expose one of the three plans, do not alter the underlying content/business logic of:

- Dersler / lesson content / class content
- Quizzes
- Authentication/account/Supabase flows
- Hareket Stüdyosu content or behavior
- Programım / programs
- Favorites and notes behavior
- Notifications
- FTR AI
- Existing contributor/preparer content
- Any other unrelated module content or business logic

## Release and QA rule

- Existing working v29.9 remains untouched and usable as the immediate safe working build.
- Immutable v29.7 rollback remains untouched.
- Build guards must fail closed if any existing payload outside the explicitly approved host/bootstrap/Plan 3 visual surface changes functionally without authorization.
- Static CI/QA never equals physical approval.
- No new APK is FINAL or LOCKED until the user completes physical phone testing of all three plans.