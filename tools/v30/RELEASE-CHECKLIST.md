# FTR Akademi v30 — Three-Plan Release Checklist

Status is fail-closed. A checked source/CI item is not equivalent to physical-phone approval.

## Immutable base

- [x] Base must be the physically verified v29.9 APK only.
- [x] Exact size: `1,137,460,262` bytes.
- [x] Exact SHA-256: `acbe8ba68cad016d56f4d61e43cfa912e37c65543e5321162d03f69dc220b809`.
- [x] Package expected: `com.ftrakademi.preview3`.
- [x] Locked signing certificate SHA-256: `8771cb32093de52d180d08270909fa5796850900bf7eecaf2b3181873c488be2`.
- [x] Builder refuses any other base and refuses output overwrite.
- [x] Dedicated rollback branch: `rollback-v29.9-phone-verified`.

## Plan 1 — Ligament visibility only

- [x] Source contract: high-visibility red ligament beauty layer.
- [x] Ivory skeleton/reference context preserved by source policy.
- [x] Selected structure remains the existing purple/bright interaction layer.
- [x] Static layered atlas architecture; no runtime WebGL/GLB/continuous loop.
- [x] Risky fresh-render artifact rejected because its invisible ID map was not byte-identical to v29.9.
- [x] Safe artifact is derived only from physically verified v29.9 Run #68 atlas; invisible ID map is never re-rendered.
- [x] Verified safe artifact: `v30-plan1-derived-from-v29.9`, artifact ID `9891447400`.
- [x] Artifact digest: `sha256:8cb6fa86d6cc5cae3a4ee1e81d57a163ca85acc3384bdf9e3a0803f89b99c76d`.
- [x] Artifact `ligament-id.png` SHA-256 equals physically verified v29.9: `171d2bd119d3e08530d5c6bad77c6a5b6cf66283fdf5455f01a9cb61fcc75eb7`.
- [x] Artifact ligament structure IDs, names and anchors equal physically verified v29.9 atlas map; count = 292.
- [x] CI proves only `ligament-front.png` plus Plan-1 policy metadata differ inside the derived atlas artifact.
- [ ] Final APK phone visual review: high-visibility red ligaments, preserved ivory skeleton and correct purple selection.

## Plan 2 — Clinical Scales

- [x] Independent Clinical Scales module: 8 categories / 29 instruments.
- [x] Offline runtime; no patient identity fields.
- [x] Rights modes prevent protected/reference forms from exposing full interactive item wording.
- [x] Population-specific cut-off policy.
- [x] Edition/version distinctions: PDMS-3, DGI/mDGI, GMFM-88/66, GMFCS E&R, MMSE context, etc.
- [x] Deep scoring architecture layer present (`scoring-evidence.js`).
- [x] Turkey psychometric evidence separated from translation/copyright licence (`turkish-evidence.js`).
- [x] Detailed evidence rendering layer present (`detail-evidence-enhancer.js`).
- [x] 29 original offline procedure/domain illustrations.
- [x] Clinical home card host bridge present.
- [x] Source and host-integration CI guards pass.
- [ ] Final editorial spot-check of all 29 detail pages after packaging.
- [ ] Physical-phone navigation/content/scroll/performance test.

## Plan 3 — Exact approved FTR brand

Approved source only: `ChatGPT Image 3 Eyl 2026 13_01_16.png`.

- [x] Exact-brand lock explicitly forbids AI regeneration, tracing, older logos and stylistic substitutes.
- [x] Host, Clinical Scales and 3D Anatomy navigation paths target the same exact runtime asset.
- [x] Logo is a Home control; normal Back remains hierarchical.
- [ ] Pixel-preserving logo crop extracted from the approved source image.
- [ ] `tools/brand/ftr-logo-exact.png` committed.
- [ ] `tools/brand/ftr-logo-exact.sha256` committed and matches exactly.
- [ ] CI reports `EXACT BRAND BINARY + HASH PASS` rather than pending.
- [ ] Physical-phone visual comparison to approved reference.

## Packaging scope

The v30 builder may change existing APK payload only at:

1. `assets/app/index.html`
2. `assets/app/anatomy3d/atlas/ligament-front.png`

New payload is restricted to the v30 host bridge, Clinical Scales module and hash-locked brand asset. No existing unrelated payload may be removed or altered.

## Pre-phone binary QA

- [ ] Build succeeds from exact v29.9 base.
- [ ] ZIP integrity PASS; duplicate entries = 0.
- [ ] zipalign PASS.
- [ ] APK signature v1 PASS + v2 PASS; exactly one signer; locked certificate matches.
- [ ] Package/badging PASS.
- [ ] Existing-payload diff exactly `{index.html, ligament-front.png}`.
- [ ] `ligament-id.png` byte-identical to base.
- [ ] Exact brand SHA survives packaging unchanged.
- [ ] Clinical release payload includes core data, authoritative evidence, Turkish evidence, deep scoring evidence, detail evidence UI and all 29 visuals.
- [ ] No runtime WebGL/GLB regression.

## Physical phone gate

v30 must remain **NOT FINAL / NOT LOCKED** until the user confirms on a real phone:

- install/update succeeds without data-loss workaround;
- home remains visually intact;
- exact FTR logo matches the approved reference and taps Home;
- 3D Anatomy still performs smoothly and all five systems work;
- ligaments are clearly red while skeleton remains ivory, with correct purple selection;
- Clinical Scales opens, all 8 categories and 29 instruments browse correctly;
- interactive open tools work where enabled;
- protected/licensed tools stay in information mode;
- Back/Home navigation behaves correctly;
- no freeze, layout clipping or unrelated regression.
