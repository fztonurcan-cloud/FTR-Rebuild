# FTR Akademi 3D Anatomi — SADE DESIGN LOCK

Status: **LOCKED BY USER — 2026-09-02 / v29.8.1**

## Required composition

- Dark navy/black FTR Akademi visual language with purple accent.
- Top bar: back arrow and `3D ANATOMİ`; no exam or learning mode.
- Left rail contains only `SİSTEM SEÇİMİ` and `MODEL KONTROLLERİ`.
- Systems: `Kaslar`, `Ligamentler`, `Damarlar`, `Kemikler`.
- Removed permanently from this design: Sinir Sistemi, Görünüm panel, Etiketler, Not Ekle, Ekran Görüntüsü, Bilgiyi Paylaş, Sınav Modu, Karma Sınav and Öğrenme Modu.
- Center: large, realistic, interactive 3D anatomy model.
- Controls: one-step rotate, zoom in, zoom out and reset.
- Any selectable structure opens the information card and receives a blue highlight.
- Information tabs remain: Genel Bilgi / Origo / Insertio / İnnervasyon / Fonksiyon.
- Bone cards interpret Origo and Insertio as muscular/ligamentous attachment information; bones are not described as motor-innervated structures.
- Fibula is a mandatory selectable QA structure with completed information across all five tabs.
- Bottom app navigation remains visually compatible with FTR Akademi.

## Performance lock

- Each GLB must physically contain only its own system meshes.
- Only one system GLB may be resident at a time.
- No continuous render loop; rendering is event-driven.
- Mobile pixel ratio is capped at 1 and screenshot framebuffer preservation is disabled.
- Rapid system switching must never display an earlier system under the latest system label.

## Home placement and protection

The card remains `Derslerim -> 3D Anatomi -> Hareket Stüdyosu`, never in the drawer. `v29.6`, the original `v29.7` APK and the failed physical-QA `v29.8` delivery remain unchanged. Work continues only as a new `v29.8.1-3d-simple` line until user phone QA is approved.
