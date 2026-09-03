# FTR Akademi v30 — Current Three-Plan Status

Checkpoint date: 2026-09-03

## Immutable rollback / base

`FTR-Akademi-v29.9-3D-ANATOMI-STATIC-ATLAS.apk` is the physically phone-verified working rollback and MUST NOT be modified or overwritten.

- Size: `1,137,460,262` bytes
- SHA-256: `acbe8ba68cad016d56f4d61e43cfa912e37c65543e5321162d03f69dc220b809`
- Package: `com.ftrakademi.preview3`
- Signing cert SHA-256: `8771cb32093de52d180d08270909fa5796850900bf7eecaf2b3181873c488be2`
- Source/QA rollback branch: `rollback-v29.9-phone-verified`
- Development branch: `v30-three-plan-premium`

No v30 builder may accept a different base APK or overwrite an existing output. v29.9 remains untouched and is the immediate safe rollback.

## Absolute scope lock

ONLY these three plans are in scope:

1. Plan 1 — Ligament visibility.
2. Plan 2 — Clinical Scales.
3. Plan 3 — user-approved full premium reference presentation + exact brand + navigation + launcher/startup visual parity.

FTR AI, lessons, quizzes, Movement Studio business/content logic, notes, favorites, auth, notifications, existing contributor data and all other existing working modules remain protected. Plan 3 may change only the approved presentation/bridge surfaces; it must not rewrite protected content/business logic.

## Plan 1 — Ligament visibility

Locked behavior:
- skeleton/reference context remains ivory;
- all visible ligament structures use high-visibility red;
- selected ligament keeps the existing purple/bright interaction highlight;
- invisible selection/ID map remains unchanged.

Accepted implementation:
- derive directly from exact Run #68 / physically verified v29.9 atlas;
- recolor only pixels selected by the existing baseline ligament ID map;
- never render or modify `ligament-id.png`;
- preserve all 292 ligament IDs/names/anchors.

Verified artifact lock:
- Name: `v30-plan1-derived-from-v29.9`
- Artifact ID: `9891447400`
- Artifact digest: `sha256:8cb6fa86d6cc5cae3a4ee1e81d57a163ca85acc3384bdf9e3a0803f89b99c76d`
- `ligament-front.png` SHA-256: `f6d50400ddbdd31805a82c5b020040ca3c5fcc864fe83be32fa65c81f6ad2028`
- `ligament-id.png` SHA-256: `171d2bd119d3e08530d5c6bad77c6a5b6cf66283fdf5455f01a9cb61fcc75eb7`
- ID map byte-identical to v29.9: PASS
- Structure contract unchanged, count 292: PASS
- Static layered atlas/no runtime WebGL/no GLB/no continuous render: PASS

Plan 1 final phone visual/selection QA is still required.

## Plan 2 — Clinical Scales

Catalogue:
- 8 clinical categories
- 29 instruments

Module capabilities:
- search, categories, favorites/recent-use architecture;
- About / Application / Scoring / Interpretation / Sources detail structure;
- deep scoring architecture;
- Turkey psychometric/context evidence layer;
- rights/licensing layer;
- 29 original offline procedure/domain illustrations;
- interactive scoring/time/distance only where internal rights policy permits;
- protected/licensed forms remain information mode;
- no patient name/ID/e-mail collection;
- offline runtime with no fetch/WebSocket/geolocation/media-device dependency.

Clinical safety locks:
- no universal cut-off when evidence is population-specific;
- exact edition/version labels preserved;
- Turkish psychometric validity does not grant copyright/reproduction rights;
- comparator/use evidence is not mislabeled as direct Turkish translation validation;
- performance-test Turkey reference evidence is separated from language-form validation.

Interactive score contracts remain locked:
- Berg: 14 items / maximum 56;
- Tinetti/POMA-I: 16 items, Balance 16 + Gait 12 = maximum 28;
- DGI: 8 items / maximum 24;
- TUG: time recording only; no universal fall-risk threshold;
- 9-HPT: time recording only; standard physical kit required; vendor norms not reproduced;
- Tardieu/MTS: R1/R2 + reaction quality, without automatic diagnosis;
- 6MWT: distance/protocol recording, population-specific reference interpretation.

Premium Clinical Scales presentation follows the approved reference with compact heading/search/filter, 8 colored categories, phone-first spacing and four-item bottom navigation. Clinical data/scoring logic remains governed by Plan 2, not the visual layer.

Plan 2 final packaged-phone navigation, scrolling, rendering and content spot-check QA is still required.

## Plan 3 — Premium reference + exact brand + navigation + visual parity

100/100 approved visual reference: `ChatGPT Image 3 Eyl 2026 13_01_16.png`.

Approved brand:
- circular skull + full spine + cyan/blue laurel/arc emblem;
- source reference expected dimensions `1536x1024`;
- source-pixel crop rectangle x=137, y=468, width=112, height=112;
- no AI regeneration, tracing, substitute art, recolor, resize, filter, sharpen or upscale of the canonical asset;
- `tools/brand/ftr-logo-exact.png` dimensions `112x112`;
- exact PNG SHA-256: `4168f34bfee9a8cfe240758561a3c94845206ada891da5b9730b6fc1e4702d75`;
- exact PNG Git blob SHA-1: `4439b92096d04d6d90e277371826029ffb8091fd`;
- SHA lock + metadata committed and materialization integrity verified.

Implemented premium host presentation:
- dark navy/black premium home shell;
- menu + centered exact-logo/FTR AKADEMİ brand + notification surface;
- `Merhaba, Fizyoterapist!` hero and offline anatomy visual;
- cards locked in order: Derslerim → 3D Anatomi → Hareket Stüdyosu → Klinik Ölçekler;
- Clinical Scales `YENİ` badge;
- shortcuts: Quizler, Favoriler, Notlarım, Programlarım;
- bottom navigation: Ana Sayfa, Dersler, Çalışma Alanım, Profilim;
- premium drawer using existing host actions rather than rewriting protected feature implementations.

Navigation contract:
- logo tap => direct Ana Sayfa;
- normal Back / Android Back => hierarchical previous screen;
- Clinical Scales and 3D Anatomy use the same exact runtime brand asset.

Latest user-locked visual parity:
- Android phone launcher/app icon must show the same canonical exact FTR artwork as in-app branding;
- `assets/app/app_logo.png`, `res/Cx.png`, `res/Wn.png`, `res/Ko.png` are packaged using the same exact canonical logo bytes;
- app startup visually supersedes the old light welcome with dark premium Plan 3 presentation;
- startup uses exact canonical FTR mark + existing offline `muscle-front.png` anatomy asset + visible `BAŞLA` button;
- startup/launcher work is presentation-only and must not alter auth or other protected business logic.

## Release preflight and build checkpoint

Exact source export used for the build:
- source artifact commit: `760deab5ad5cd8aa054808a0bca905e5bc7f7f81`;
- export artifact digest: `sha256:25c1c5fd9101bf5cadd15e8405fe8cfd7d9301acdc7f2d04bb295f91fc6ef0a7`;
- temporary export workflow self-deleted after export;
- cleaned resulting tree is identical to the guarded permanent source tree apart from the temporary workflow history.

Preflight:
- status: `V30_THREE_PLAN_RELEASE_INPUTS_PASS`;
- exact v29.9 base size/SHA: PASS;
- Plan 1 artifact/ID map/292 structures: PASS;
- Plan 2 required Clinical Scales payload: PASS;
- Plan 3 exact 112x112 brand SHA: PASS.

Intermediate core APK (not for phone delivery):
- `FTR-Akademi-v30-THREE-PLAN-PREMIUM-CORE.apk`
- Size: `1,137,494,811` bytes
- SHA-256: `c990c1f52166c91048f687a41c1dc38d4a0aa574fe81514d160f2ddee492db20`
- build/static QA: PASS

Current phone-test candidate:
- `FTR-Akademi-v30-THREE-PLAN-PREMIUM-PHONE-TEST.apk`
- Size: `1,136,610,099` bytes
- SHA-256: `c02f903be2ada959a5314107a3539507b82e2adb2332404953e54cfae9aaecfa`
- Package: `com.ftrakademi.preview3`
- versionCode: `29`
- versionName: `2.4`
- targetSdkVersion: `36`
- V1 signature: PASS
- V2 signature: PASS
- Signer count: 1
- Signing certificate SHA-256: `8771cb32093de52d180d08270909fa5796850900bf7eecaf2b3181873c488be2`
- zipalign: PASS
- ZIP integrity: PASS
- duplicate entries: 0

Independent final-candidate payload QA versus v29.9:
- changed existing entries exactly 6:
  - `assets/app/anatomy3d/atlas/ligament-front.png` — Plan 1;
  - `assets/app/index.html` — narrow Plan 3 host bootstrap;
  - `assets/app/app_logo.png` — Plan 3 exact visual parity;
  - `res/Cx.png` — Plan 3 exact launcher visual parity;
  - `res/Ko.png` — Plan 3 exact launcher visual parity;
  - `res/Wn.png` — Plan 3 exact launcher visual parity.
- removed existing entries: 0
- added Plan 2/Plan 3 entries: 16
- `AndroidManifest.xml`, `classes.dex`, `resources.arsc`: byte-identical to v29.9
- ligament ID map: byte-identical to v29.9
- Plan 1 ligament structure count: 292
- runtime GLB/GLTF count: 0
- Clinical Scales packaged files: 13 and offline contract PASS
- canonical runtime logo, app logo and all three launcher PNGs share SHA-256 `4168f34bfee9a8cfe240758561a3c94845206ada891da5b9730b6fc1e4702d75`
- launcher manifest points to `mipmap/ic_launcher`; non-adaptive icon resolves to `res/Ko.png`, adaptive foreground resolves to `res/Wn.png`; both use exact canonical logo bytes.

Delivery split verification:
- five 250 MiB-style parts (last part smaller) prepared;
- each part SHA-256 locked;
- join BAT refuses overwrite, verifies all part hashes, final byte size and final SHA;
- independent rejoin produced `1,136,610,099` bytes and SHA `c02f903be2ada959a5314107a3539507b82e2adb2332404953e54cfae9aaecfa`;
- rejoined bytes are identical to the phone-test APK: PASS.

Browser-level startup smoke could not be executed in the container because Chromium policy blocks localhost and `file://` navigation with `ERR_BLOCKED_BY_ADMINISTRATOR`. This is recorded as environment-blocked, not as a PASS or APK defect. Real Android phone QA is authoritative for startup visuals and `BAŞLA` interaction.

## Current release status

- Plan 1 source/artifact/static package QA: PASS
- Plan 2 source/clinical/rights/offline/scoring/package QA: PASS
- Plan 3 premium host/source/exact-logo/launcher/startup package QA: PASS
- v30 phone-test APK: BUILT
- independent static/signature/package/payload QA: PASS
- physical phone QA: PENDING USER RETEST
- FINAL/LOCKED: NO

Do not rename this candidate FINAL or replace the immutable v29.9 rollback until physical phone testing passes.