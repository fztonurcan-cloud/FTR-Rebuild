# FTR Akademi — v29.6 Canonical Checkpoint

Status: **LOCKED / PHONE-VERIFIED / ACTIVE CANONICAL APK**

This branch is the authoritative checkpoint for the currently verified FTR Akademi application line.

## Canonical APK

- File: `FTR-Akademi-v29.6-PROGRAM-VE-HAZIRLAYANLAR-FIX.apk`
- Size: `1,130,842,466 bytes`
- SHA-256: `abe8b60a338751477d319abdcc2942f61942cd305341e0498243800fc07ed930`
- Android package: `com.ftrakademi.preview3`
- Signing identity: FTR Akademi Preview v41
- Signing certificate SHA-256: `8771cb32093de52d180d08270909fa5796850900bf7eecaf2b3181873c488be2`
- Android V1 signature: PASS
- Android V2 signature: PASS

## Phone verification

The APK was physically installed and tested on a phone on 2026-09-01. The following requested changes were confirmed working:

1. Hareket Stüdyosu `Programıma Ekle` -> `Programlar` -> `Programım` -> start workout -> remove movement.
2. The redundant second `Çalışma Alanım` menu row is removed while the primary workspace/favorites/notes remain.
3. The `Hazırlayanlar` button is present and all three contributor entries are correct.

## Exact v29.6 scope

Only these payload files differ from v29.5:

- `assets/app/index.html`
- `assets/app/app.js`
- `assets/app/app.css`
- `assets/app/movement/studio.js`
- `assets/app/movement/studio.css`

All other payload entries match v29.5 by size/CRC32 according to QA. Lessons, quizzes, FTR AI, Auth, Supabase integration and 88 movement visuals were not changed.

## Rollback

Safe rollback is `rollback-v29.5` / `FTR-Akademi-v29.5-HAREKET-STUDYOSU-INSTALL-FIX.apk` with SHA-256:

`2518c9b79a69f2fe3c5a60b4b8c2a454bbe6fb2b83daad789374695e2e3fdbb3`

## Rules

- Never overwrite or modify this checkpoint in place.
- Any future application change must be made as a new version (v29.7+).
- Do not merge historical Flutter/v56/v57 branches into this checkpoint.
- Do not relabel an older APK/source tree as v29.6.
- Reconstruct the APK only from the exact five parts listed in the manifest and verify final SHA-256 before installation.

The 1.13 GB APK itself is not stored as a normal GitHub repository file; this checkpoint stores the canonical identity, reconstruction hashes, QA scope and verification rules.