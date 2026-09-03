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
3. Plan 3 — Exact approved brand + navigation.

FTR AI, lessons, quizzes, Movement Studio, notes, favorites, auth, notifications and all other existing working modules are out of scope and must remain untouched.

A fresh compare from the physically verified v29.9 source/QA checkpoint to the v30 branch confirms no FTR AI, lesson, quiz, Movement Studio, notes/favorites, auth or notification implementation files are modified. The changed-file set remains restricted to Plan 1 anatomy surfaces, Plan 2 Clinical Scales, Plan 3 brand/navigation, and their build/QA guards.

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

Plan 1 artifact workflow is now path-scoped so unrelated Plan 2/Plan 3 documentation/content commits do not regenerate the locked Plan 1 artifact.

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

Interactive score contracts now fail closed at source/host QA:
- Berg: 14 items / maximum 56;
- Tinetti/POMA-I: 16 items, Balance 16 + Gait 12 = maximum 28;
- DGI: 8 items / maximum 24;
- TUG: time recording only; no universal fall-risk threshold;
- 9-HPT: time recording only; standard physical kit required; vendor norms are not reproduced;
- Tardieu/MTS: R1/R2 + reaction quality, without automatic diagnosis;
- 6MWT: distance/protocol recording, with population-specific reference interpretation.

Recent rights clarification:
- Berg: public-domain availability per RehabMeasures;
- DGI, Tinetti/POMA, Modified Tardieu and Penn: free availability/cost status documented by RehabMeasures;
- 9-HPT: app may record measured time, but RehabMeasures lists the standard physical kit as not free; vendor kit/norm tables are not reproduced.

Recent Turkey-context evidence expansion:
- Brunnstrom: Turkey stroke research use; not mislabeled as direct translation validation.
- Fugl-Meyer: used as comparator in Turkish validation research; not mislabeled as direct FMA Turkish validation.
- Rivermead Mobility Index: direct Turkish-form validity/reliability evidence exists in an elderly population; this is explicitly not generalized automatically to stroke populations.
- Penn: used as convergent measure in Turkish SCI research; not mislabeled as direct PSFS validation.
- TUG: direct inter/intraobserver reliability evidence in Turkish community-dwelling older adults.
- 9-HPT: Turkey clinical comparator evidence; not mislabeled as direct 9-HPT Turkish norm/validation.

Latest CI after the scoring-contract shell-guard correction:
- v30 host integration fail-closed guards Run #24: SUCCESS.
- v30 three-plan fail-closed guards Run #48: SUCCESS.

Plan 2 still requires final packaged-phone navigation, scrolling, rendering and content spot-check QA.

## Plan 3 — Exact approved brand + navigation

User decision is exact-reference only. No AI regeneration, tracing, old logo, alternative skull/spine art or stylistic reinterpretation is allowed.

Approved source reference:
- `ChatGPT Image 3 Eyl 2026 13_01_16.png`
- expected dimensions `1536x1024`
- circular skull + full spine + cyan/blue laurel/arc emblem.

Library search was repeated for a standalone original copy of this exact emblem. Only composite design boards containing the emblem were found; no separate exact source PNG was found. Therefore no other Library logo is accepted as a substitute.

Navigation contract:
- logo tap => direct `Ana Sayfa`;
- normal Back / Android Back => hierarchical previous screen;
- Clinical Scales and 3D Anatomy point to the same exact runtime brand asset.

Prepared extraction utility:
- `tools/brand/extract_exact_logo_from_reference.ps1`
- approved large in-app emblem crop rectangle is locked in original 1536×1024 reference coordinates;
- rectangular source-pixel crop only;
- lossless PNG output;
- no resize/recolor/filter/sharpen/trace/AI/upscale;
- writes output SHA-256 lock and metadata;
- visual phone QA remains mandatory.

Current release blocker:
- `tools/brand/ftr-logo-exact.png` has NOT yet been committed;
- `tools/brand/ftr-logo-exact.sha256` has NOT yet been committed;
- therefore release APK creation MUST remain blocked.

The approved source image is available in the ChatGPT file library, but the current local binary-processing runtime is returning `ClientError`. Do not bypass this by generating an approximate logo.

## Release status

- Plan 1 source/artifact QA: PASS
- Plan 2 source/clinical/rights/offline/scoring QA: PASS
- Plan 3 navigation/source lock: PASS
- Plan 3 exact binary asset/hash: PENDING
- Host integration fail-closed QA: PASS
- Three-plan fail-closed QA: PASS
- v30 release APK: NOT BUILT
- Physical phone QA: PENDING
- FINAL/LOCKED: NO
