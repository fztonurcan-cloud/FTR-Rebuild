# FTR Akademi v30 — PLAN 3 PREMIUM REFERENCE LOCK

Status: **USER 100/100 FINAL DESIGN DECISION — SOURCE/PHONE QA STILL REQUIRED**

Approved visual reference: `ChatGPT Image 3 Eyl 2026 13_01_16.png` (`1536x1024`).

The temporary later idea to keep the old presentation and change only the logo is **superseded**. The user's final decision is to continue the full premium presentation shown in the approved reference. Do not silently revert Plan 3 to a logo-only change.

## 1. Brand lock

- Use only the approved circular skull + full vertical spine + cyan/blue laurel/arc mark.
- Do not substitute old FTR artwork, another skull/spine drawing, generated art, tracing, recoloring or stylistic reinterpretation.
- Runtime logo target: `assets/app/brand/ftr-logo-exact.png`.
- Source-pixel crop contract: `x=137`, `y=468`, `width=112`, `height=112` from the approved `1536x1024` source.
- Crop is lossless and unscaled; resize/recolor/filter/sharpen/trace/upscale/AI regeneration are forbidden.
- `ftr-logo-exact.png` and its SHA-256 lock are mandatory before APK packaging.

## 2. Home visual hierarchy

Phone-first dark navy/black premium presentation.

Top bar, left to right:
1. hamburger/menu control;
2. centered exact FTR emblem + `FTR AKADEMİ`;
3. notification surface.

Hero:
- `Merhaba, Fizyoterapist! 👋`
- `Bugün kendini geliştirmek için harika bir gün.`
- offline anatomy visual on the right side.

Primary stack order is locked:
1. `Derslerim` — blue accent;
2. `3D Anatomi` — purple accent;
3. `Hareket Stüdyosu` — cyan/blue accent;
4. `Klinik Ölçekler` — green accent + `YENİ` badge.

Shortcut row:
1. Quizler;
2. Favoriler;
3. Notlarım;
4. Programlarım.

Bottom navigation:
1. Ana Sayfa;
2. Dersler;
3. Çalışma Alanım;
4. Profilim.

## 3. Drawer hierarchy

Header:
- exact FTR emblem;
- `FTR AKADEMİ`;
- `Fizyoterapi Bilgi Platformu`.

First group:
1. Ana Sayfa;
2. Derslerim;
3. 3D Anatomi;
4. Hareket Stüdyosu;
5. Klinik Ölçekler + `YENİ`.

Second group:
1. Çalışma Alanım;
2. Notlarım;
3. Favorilerim;
4. Programlarım.

Third group:
1. Ayarlar;
2. Yardım & Destek;
3. Çıkış Yap.

## 4. Clinical Scales premium shell

The catalogue landing screen follows the approved right-hand reference:
- exact FTR top brand;
- title `Klinik Ölçekler`;
- subtitle `Testler, skorlamalar ve değerlendirme araçları`;
- compact `Ölçek ara…` search field;
- filter control;
- eight colored category cards;
- four-item bottom navigation matching the host.

The visual override must not modify clinical database, scoring, rights/licensing or evidence semantics.

## 5. Navigation contract

- Exact FTR logo is an active Home control.
- Logo tap from 3D Anatomy or Clinical Scales => `Ana Sayfa` directly.
- Normal Back / Android Back remains hierarchical and must not be converted into Home.
- Example: `Berg → Denge & Mobilite → Klinik Ölçekler → Ana Sayfa`.
- Clinical bottom-nav non-home routes return to the host through the explicit `v30nav` bridge.
- Premium home cards/drawer/shortcuts must invoke existing host behavior where that behavior already exists; do not duplicate or replace protected business logic.

## 6. Protected implementation boundary

Plan 3 may change presentation/navigation bridge code only. It must not rewrite the content/business implementation of:
- FTR AI;
- Dersler / lesson content;
- Quizzes;
- Authentication/account/Supabase;
- Hareket Stüdyosu;
- Programlar;
- Favorites / notes;
- Notifications;
- contributor/preparer content;
- any unrelated working module.

The premium shell may call existing controls/routes for these areas, but must not reimplement them.

## 7. Phone acceptance gate

Before FINAL/LOCKED, verify on physical phone at minimum:
- home proportions against approved reference;
- no clipped logo/text/cards at 360×800 and 390×844-class layouts;
- drawer open/close and every drawer route;
- all four primary cards;
- all four shortcut routes;
- all four bottom-nav routes;
- logo Home behavior from home, 3D Anatomy and Clinical Scales;
- Android Back hierarchy;
- FTR AI and all protected modules remain functional;
- no overlay captures taps after leaving Home;
- no blank/black page, freeze or layout jump.

Static/source CI is not physical approval. `v30` remains NOT FINAL / NOT LOCKED until this gate passes.
