# FTR Akademi 3D Anatomi — FINAL PREMIUM DESIGN LOCK

Status: **USER FINAL REFERENCE LOCK — 2026-09-02 / v29.9 development line; ligament visibility correction approved 2026-09-03**

## Absolute scope rule

- The only active development area is **3D Anatomi**.
- No lesson, quiz, auth, Supabase, Hareket Stüdyosu, Programım, favorite, note, notification, FTR AI, drawer or unrelated home component may be changed.
- `FTR-Akademi-v29.7-BILDIRIM.apk` is the untouched safe checkpoint and must never be overwritten or repackaged in place.
- v29.8.1 remains an earlier technical prototype. v29.9 work is isolated on its own branch.
- The physically working v29.9 APK must not be overwritten; any post-phone-test usability correction is released as a new build such as v29.9.1.

## Final visual reference lock

The user-approved premium reference images supplied on 2026-09-02 define the visual result. The implementation must stay inside those references: dark navy medical-atlas UI, left searchable anatomy browser, large central anatomical figure, strong system-specific selection color, bottom information card and the same five system tabs.

Required systems:

- Kaslar
- Kemikler
- Ligamentler
- Damarlar
- Sinirler

## Final interaction architecture

The heavy live WebGL/GLB viewer is removed from runtime.

`3D ANATOMİ` remains the product/design name because the anatomical figures are produced from 3D anatomical source models, but the phone runtime is a **static layered anatomical atlas**:

1. A premium pre-rendered front-view anatomical image is loaded for the selected system.
2. A matching invisible object-ID map is loaded with it.
3. Choosing a structure in the left browser highlights that exact structure on the anatomical figure.
4. Tapping the anatomical figure can select the structure under the finger through the ID map.
5. The previously selected structure turns off when another structure is selected.
6. Other anatomy is visually subdued while the selected structure remains clear and receives the system highlight.
7. The bottom information card updates immediately to the selected structure.
8. Two-finger pinch zoom and panning while zoomed are allowed; double tap may toggle zoom.

There is **no runtime free 3D rotation**, no WebGL renderer, no runtime GLB model loading, no automatic rotation and no continuous render loop.

The old right-side controls `Döndür / Yakınlaştır / Uzaklaştır / Sıfırla / Otomatik Döndür` are removed. This is intentional and is part of the user's final decision.

## Selection and presentation colors

- Muscle presentation: anatomical red muscle; selected structure receives vivid orange/purple premium highlight.
- Bone selection: blue.
- **Ligament presentation: ivory/cream skeleton with all tappable ligament structures rendered high-visibility red.**
- **Ligament selection: selected ligament receives the existing vivid purple/premium highlight over the red ligament atlas, so both discoverability and selected-state identity remain clear.**
- Vessel selection: artery red / vessel-system red; veins remain blue in the base atlas.
- Nerve selection: yellow/gold.

The 2026-09-03 ligament visibility correction changes only the visible ligament beauty layer. The invisible ligament ID map, structure identities, tap-selection mapping and all other systems remain unchanged.

Raw Blender/export suffixes such as `001`, `.001`, `.L` and `.R` must never be shown as learner-facing names.

## System-specific information semantics

- **Kas:** Genel Bilgi / Origo / Insertio / İnnervasyon / Fonksiyon
- **Kemik:** Genel Bilgi / Anatomik Özellikler / Eklemleşmeler / Kas-Ligament Tutunmaları / Klinik Önemi
- **Ligament:** Genel Bilgi / Başlangıç-Tutunma / Bağladığı Yapılar / Fonksiyon / Klinik Önemi
- **Damar:** Genel Bilgi / Başlangıç / Seyir / Dalları / Beslediği Bölge / Klinik Önemi
- **Sinir:** Genel Bilgi / Anatomi / Seyir / Dalları / İnnervasyon / Fonksiyon / Klinik Önemi

Mandatory curated QA examples: Biceps brachii, Fibula, anterior talofibular ligament (ATFL), anterior tibial artery and median nerve.

Generated visual copy is never accepted as medical truth. Unknown structures must not receive fabricated generic anatomy statements; detailed academic copy is published only after verification.

## Performance lock

- Runtime WebGL: **forbidden**.
- Runtime GLB models: **forbidden**.
- Continuous render/animation loop: **forbidden**.
- Static beauty image + ID-selection map is the runtime architecture.
- Rendering only occurs when a system, selection or zoom/pan state changes.
- Atlas raster dimensions are intentionally bounded for low-end Android memory.
- Only the selected system's two raster layers are kept active.
- Reder S19 Max / equivalent low-end Android remains the physical acceptance floor.
- Static and synthetic QA never equal FINAL phone approval.

## Home placement lock

3D Anatomi stays exactly between `Derslerim` and `Hareket Stüdyosu`. The surrounding home layout does not move. The 3D card lists five unique systems: Kas, Sinir, Ligament, Damar and Kemik. It is not added to the drawer.

## Release rule

No corrected v29.9.x APK is `FINAL` or `LOCKED` until the user physically tests that exact APK. The safe rollback remains `FTR-Akademi-v29.7-BILDIRIM.apk`; the previously working v29.9 APK is also preserved unchanged as the immediate pre-correction phone-tested build.