# FTR Akademi — EXACT BRAND ASSET LOCK

User decision: **100/100 exact reference; no creative reinterpretation.**

Reference supplied in conversation:
- `ChatGPT Image 3 Eyl 2026 13_01_16.png`
- Expected approved reference dimensions: `1536x1024` pixels.
- The approved mark is the circular skull + full spine + cyan/blue laurel/arc FTR Akademi emblem shown in that reference.

Required release assets:
- Runtime path: `assets/app/brand/ftr-logo-exact.png`
- Source path: `tools/brand/ftr-logo-exact.png`
- Hash lock: `tools/brand/ftr-logo-exact.sha256`
- Extraction metadata: `tools/brand/ftr-logo-exact.metadata.json` when the crop is produced.
- The hash-lock file contains exactly one lowercase SHA-256 digest for the approved PNG.
- Source must be an exact pixel-preserving extraction from the user-supplied reference or a higher-resolution exact original supplied/approved by the user.
- Do **not** replace it with AI regeneration, a traced approximation, a different skull/spine mark, the older PDF logo, or a stylistic variation.
- Builder must fail closed when the exact asset or its SHA-256 lock is absent, malformed, or mismatched.

Pixel-preserving extraction procedure:
- Utility: `tools/brand/extract_exact_logo_from_reference.ps1`.
- The utility accepts only the `1536x1024` approved reference dimensions.
- Default crop targets the large in-app empty/loading-screen instance of the approved emblem in the left reference panel: `x=137, y=468, width=112, height=112` in original source pixels.
- The crop intentionally includes a small dark surrounding margin so emblem pixels are not clipped.
- Permitted operations: rectangular crop and lossless PNG serialization only.
- Forbidden operations: resize/resample, recolor, filter, sharpen, trace/vector recreation, generative AI, upscale or artistic cleanup.
- The script records both source SHA-256 and output SHA-256 and leaves physical-phone visual QA pending.
- If the crop fails visual comparison with the approved reference, do not cosmetically edit it; select a corrected rectangle from the same approved source and re-run pixel-preserving extraction.

Interaction lock:
- The logo is a real Home control in the host/app bar, Klinik Ölçekler and 3D Anatomi.
- Tap logo => direct `Ana Sayfa`.
- Normal Back/Android back => hierarchical previous screen.

Visual lock:
- Dark navy/black premium surface.
- Small circular emblem + white `FTR AKADEMİ` in the top app bar.
- Drawer/header uses the same approved emblem, larger, with `FTR AKADEMİ` and `Fizyoterapi Bilgi Platformu` as shown in the reference.
- No unrelated home redesign is allowed under this plan.

Release blocker:
- Until the exact PNG has been extracted/approved and its SHA-256 lock committed, v30 may pass source QA but **must not produce a release APK**.
