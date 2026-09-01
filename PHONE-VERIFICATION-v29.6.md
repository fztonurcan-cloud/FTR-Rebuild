# v29.6 Physical Phone Verification

Date: 2026-09-01
Status: **PASS**

Canonical APK:
`FTR-Akademi-v29.6-PROGRAM-VE-HAZIRLAYANLAR-FIX.apk`

SHA-256:
`abe8b60a338751477d319abdcc2942f61942cd305341e0498243800fc07ed930`

Verified on a physical phone after updating over v29.5.

## Verified flows

### 1. Hareket Stüdyosu / Programım
PASS

- `Programıma Ekle` works.
- Added movement appears in `Programlar > Programım`.
- Workout can be started.
- Movement can be removed with `Programdan Çıkar`.
- No duplicate movement is added.

### 2. Menu cleanup
PASS

- Redundant second `Çalışma Alanım` row is gone.
- Primary `Çalışma Alanım` remains.
- Favorites, Notes and existing workspace options remain.

### 3. Hazırlayanlar
PASS

Displayed entries are correct:

- `FZT. ONURCAN SÖNMEZ` — `PROJE & İÇERİK & AKADEMİK KATKI`
- `A&R. OZAN SÖNMEZ` — `YARATICI ÜRETİM`
- `FZT. ÖZLEM ESRA DEMİRCİ` — `YARATICI ÜRETİM`

## Result

v29.6 is promoted from test candidate to the active locked canonical checkpoint.

v29.5 remains the safe rollback and must remain unchanged.

Any subsequent modification must be made as v29.7 or later.