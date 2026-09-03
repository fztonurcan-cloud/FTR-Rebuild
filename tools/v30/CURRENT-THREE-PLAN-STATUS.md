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

No v30 builder is allowed to accept a different base APK or overwrite an existing output.

## Scope lock

ONLY these three plans are in scope:

1. Plan 1 — Ligament visibility.
2. Plan 2 — Clinical Scales.
3. Plan 3 — user-approved full premium reference presentation + exact brand + navigation bridges.

FTR AI, lessons, quizzes, Movement Studio business/content logic, notes, favorites, auth, notifications and all other existing working modules remain protected. Plan 3 is allowed to replace the approved host presentation and invoke existing navigation/action surfaces, but it must not rewrite those protected modules' content/business logic.

## Plan 1 — Ligament visibility

Target:
- skeleton/reference context remains ivory;
- all visible ligament structures become high-visibility red;
- selected ligament remains existing purple/bright interaction highlight;
- invisible selection/ID map remains unchanged.

Rejected approach:
- fresh re-render artifact was rejected because its `ligament-id.png` was not byte-identical to the physically verified v29.9 baseline.

Accepted approach:
- derive directly from exact Run #68 / v29.9 atlas;
- copy baseline artifact;
- recolor only pixels selected by the existing baseline ligament ID map;
- do not render or modify `ligament-id.png`;
- preserve all 292 ligament IDs/names/anchors.

Verified artifact lock:
- Name: `v30-plan1-derived-from-v29.9`
- Artifact ID: `9891447400`
- Digest: `sha256:8cb6fa86d6cc5cae3a4ee1e81d57a163ca85acc3384bdf9e3a0803f89b99c76d`
- `ligament-id.png` SHA-256: `171d2bd119d3e08530d5c6bad77c6a5b6cf66283fdf5455f01a9cb61fcc75eb7`
- ID map byte-identical to v29.9: PASS
- Structure contract unchanged, count 292: PASS
- Static layered atlas/no runtime WebGL/no GLB/no continuous render: PASS

Plan 1 still requires final physical-phone visual QA in the packaged APK.

## Plan 2 — Clinical Scales

Current catalogue:
- 8 clinical categories
- 29 instruments

Module capabilities:
- search;
- categories;
- favorites/recent-use architecture;
- About / Application / Scoring / Interpretation / Sources detail structure;
- deep scoring architecture;
- Turkey psychometric/context evidence layer;
- rights/licensing layer;
- 29 original offline procedure/domain illustrations;
- interactive scoring/time/distance only for tools allowed by the internal rights policy;
- protected/licensed forms remain information mode;
- no patient name/ID/e-mail collection;
- offline runtime; no fetch/WebSocket/geolocation/media-device dependency.

Clinical safety rules:
- no universal cut-off when evidence is population-specific;
- exact edition/version labels must be preserved;
- Turkish psychometric validity does not grant copyright/reproduction rights;
- Turkey comparator/use evidence must not be mislabeled as direct Turkish translation validation;
- performance-test Turkey reference evidence is separated from language-form validation.

Interactive score contracts:
- Berg: 14 items / maximum 56;
- Tinetti/POMA-I: 16 items, Balance 16 + Gait 12 = maximum 28;
- DGI: 8 items / maximum 24;
- TUG: time recording only; no universal fall-risk threshold;
- 9-HPT: time recording only; standard physical kit required; vendor norms are not reproduced;
- Tardieu/MTS: R1/R2 + reaction quality, without automatic diagnosis;
- 6MWT: distance/protocol recording, with population-specific reference interpretation.

Premium Clinical Scales presentation now follows the approved right-hand reference screen:
- compact `Klinik Ölçekler` heading and subtitle;
- `Ölçek ara…` search field plus filter button;
- 8 colored category cards;
- compact phone-first spacing;
- fixed four-item bottom navigation;
- filter button exposes existing Recent/Favorites controls without changing clinical data logic.

Plan 2 still requires final packaged-phone navigation, scrolling, rendering and content spot-check QA.

## Plan 3 — Full premium reference + exact brand + navigation

The user's final decision is to continue with the full premium design shown in `ChatGPT Image 3 Eyl 2026 13_01_16.png`. The temporary logo-only simplification is superseded and must not be used.

Approved source reference:
- `ChatGPT Image 3 Eyl 2026 13_01_16.png`
- expected dimensions `1536x1024`
- circular skull + full spine + cyan/blue laurel/arc emblem.

Implemented premium host presentation:
- dark navy/black premium home shell;
- menu button + centered exact-logo/FTR AKADEMİ brand + notification surface;
- `Merhaba, Fizyoterapist!` hero and offline anatomy visual;
- four primary cards in locked order: Derslerim → 3D Anatomi → Hareket Stüdyosu → Klinik Ölçekler;
- Clinical Scales `YENİ` badge;
- shortcut row: Quizler, Favoriler, Notlarım, Programlarım;
- four-item bottom navigation: Ana Sayfa, Dersler, Çalışma Alanım, Profilim;
- premium drawer matching the approved information hierarchy;
- drawer/home buttons bridge to existing host actions rather than rewriting protected feature implementations;
- Clinical Scales bottom navigation returns to host routes through the `v30nav` bridge.

Navigation contract:
- logo tap => direct `Ana Sayfa`;
- normal Back / Android Back => hierarchical previous screen;
- Clinical Scales and 3D Anatomy point to the same exact runtime brand asset.

Exact-logo rule remains fail-closed:
- no AI regeneration, tracing, old logo or substitute art;
- pixel-preserving crop rectangle remains locked at source coordinates x=137, y=468, width=112, height=112;
- no resize/recolor/filter/sharpen/upscale;
- exact PNG + SHA lock remains mandatory before APK packaging.

Exact-brand binary status:
- approved source image bytes SHA-256: `5ed581158210e861af0ce93c0bc804372398b595765388ed6842d79784407792`;
- `tools/brand/ftr-logo-exact.png` is committed as a `112x112` lossless source-pixel crop;
- exact PNG SHA-256: `4168f34bfee9a8cfe240758561a3c94845206ada891da5b9730b6fc1e4702d75`;
- exact PNG Git blob SHA-1: `4439b92096d04d6d90e277371826029ffb8091fd`;
- `tools/brand/ftr-logo-exact.sha256` is committed as the 64-character hash lock;
- `tools/brand/ftr-logo-exact.metadata.json` records source, crop and forbidden-operation contract;
- exact-logo materialization Run #1 completed successfully after checking decoded byte size, SHA-256, Git blob identity and PNG dimensions;
- transfer-only temporary chunks and temporary materializer workflow were removed from the resulting tree;
- physical-phone visual QA is still PENDING and this asset must not be called FINAL/LOCKED before phone verification.

## Release status

- Plan 1 source/artifact QA: PASS
- Plan 2 source/clinical/rights/offline/scoring QA: PASS before the latest premium-shell commits; new presentation guards are running again
- Plan 3 full premium host source: IMPLEMENTED
- Plan 3 premium Clinical Scales shell: IMPLEMENTED
- Plan 3 exact-logo navigation/source lock: PASS
- Plan 3 exact binary asset/hash integrity: PASS
- v30 release APK: NOT BUILT
- Physical phone QA: PENDING
- FINAL/LOCKED: NO
