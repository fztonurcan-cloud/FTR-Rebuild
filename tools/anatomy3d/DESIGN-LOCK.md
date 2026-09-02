# FTR Akademi 3D Anatomi — PREMIUM DESIGN LOCK

Status: **USER REFERENCE LOCK — 2026-09-02 / v29.9 development line**

## Absolute scope rule

- The only active development area is **3D Anatomi**.
- No lesson, quiz, auth, Supabase, Hareket Stüdyosu, Programım, favorite, note, notification, FTR AI, drawer or unrelated home component may be changed.
- `FTR-Akademi-v29.7-BILDIRIM.apk` is the untouched safe checkpoint and must never be overwritten or repackaged in place.
- v29.8.1 remains an earlier test candidate; v29.9 work is isolated on its own branch.

## Visual reference lock

The six user-approved reference images supplied on 2026-09-02 define the target visual language for:

1. Home-page 3D Anatomi card
2. Kas Sistemi
3. Kemik Sistemi
4. Ligament Sistemi
5. Damar Sistemi
6. Sinir Sistemi

The implementation must reproduce their hierarchy and premium medical-atlas character rather than the low-quality white/raw-model appearance of v29.8.1.

## Required 3D systems

- Kaslar
- Kemikler
- Ligamentler
- Damarlar
- Sinirler

Only the selected detailed system is resident at a time. Ligament, vessel and nerve views may load a **single heavily optimized merged skeleton reference mesh** for anatomical context.

## System-specific information semantics

- **Kas:** Genel Bilgi / Origo / Insertio / İnnervasyon / Fonksiyon
- **Kemik:** Genel Bilgi / Anatomik Özellikler / Eklemleşmeler / Kas-Ligament Tutunmaları / Klinik Önemi
- **Ligament:** Genel Bilgi / Başlangıç-Tutunma / Bağladığı Yapılar / Fonksiyon / Klinik Önemi
- **Damar:** Genel Bilgi / Başlangıç / Seyir / Dalları / Beslediği Bölge / Klinik Önemi
- **Sinir:** Genel Bilgi / Anatomi / Seyir / Dalları / İnnervasyon / Fonksiyon / Klinik Önemi

Mandatory curated QA examples: Biceps brachii, Fibula, anterior talofibular ligament (ATFL), anterior tibial artery and median nerve.

## Premium model presentation

- Muscle tissue: anatomical red; tendon/aponeurosis: pale ivory.
- Bone: warm ivory/off-white with depth-preserving medical lighting.
- Ligament: pale fibrous material over a contextual skeleton; selected ligament highlighted purple.
- Vessels: arteries red, veins blue; selected vessel receives a stronger system-color highlight.
- Nerves: warm yellow/gold; selected nerve receives a bright yellow highlight.
- Raw Blender suffixes such as `001` / `.001` must never be shown to the learner.
- Structure selection must visually highlight the selected anatomy and update the matching information card.

## Controls and interaction

- Rotate, zoom in, zoom out and reset remain available.
- Automatic rotation is **off by default** and may render continuously only after explicit user activation.
- Searchable structure browser, layer isolation and transparency controls are allowed because they are part of the approved premium references; each visible control must work.
- Full-screen icon operates as an in-module focus mode if platform fullscreen is unavailable.

## Performance lock

- Mobile pixel ratio: `1`.
- Mobile antialias: off.
- `preserveDrawingBuffer: false`.
- No default continuous animation/render loop.
- No shadows.
- Models are Draco-compressed and mobile-decimated during export.
- Fast system switching uses a load sequence so stale loads cannot replace the latest selected system.
- Low-end Android physical QA remains mandatory; static QA never equals FINAL approval.

## Home placement lock

3D Anatomi stays exactly between `Derslerim` and `Hareket Stüdyosu`. The surrounding home layout does not move. The 3D card lists five unique systems: Kas, Sinir, Ligament, Damar and Kemik. It is not added to the drawer.

## Release rule

No v29.9 APK is `FINAL` or `LOCKED` until the user physically tests it, including a low-end device test. The safe rollback remains `FTR-Akademi-v29.7-BILDIRIM.apk`.
