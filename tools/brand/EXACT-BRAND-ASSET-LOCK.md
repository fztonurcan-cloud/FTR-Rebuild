# FTR Akademi — EXACT BRAND ASSET LOCK

User decision: **100/100 exact reference; no creative reinterpretation.**

Reference supplied in conversation:
- `ChatGPT Image 3 Eyl 2026 13_01_16.png`
- The approved mark is the circular skull + full spine + cyan/blue laurel/arc FTR Akademi emblem shown in that reference.

Required release assets:
- Runtime path: `assets/app/brand/ftr-logo-exact.png`
- Source path: `tools/brand/ftr-logo-exact.png`
- Hash lock: `tools/brand/ftr-logo-exact.sha256`
- The hash-lock file contains exactly one lowercase SHA-256 digest for the approved PNG.
- Source must be an exact pixel-preserving extraction from the user-supplied reference or a higher-resolution exact original supplied/approved by the user.
- Do **not** replace it with AI regeneration, a traced approximation, a different skull/spine mark, the older PDF logo, or a stylistic variation.
- Builder must fail closed when the exact asset or its SHA-256 lock is absent, malformed, or mismatched.

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
