# FTR — Google Play Console Production Release Checklist

Date: 2026-08-28

This checklist separates code-complete items from Play Console/account configuration that must be verified manually before production rollout.

## 1. App identity / update continuity

- [x] Android applicationId/package: `com.mobiroller.mobi743032079412`
- [x] Candidate version name: `4.0.0`
- [x] Candidate version code: `25`
- [x] Release gate requires version code greater than documented previous Play maximum (`24`).
- [ ] Confirm package shown by the existing Play Console app exactly matches the applicationId above.
- [ ] Confirm Play Console still reports `24` as the highest active/uploaded version code before final AAB generation; increase candidate version code if Play has a newer code.

## 2. Upload signing

- [x] Release signing is separated from debug signing.
- [x] Repository contains no tracked JKS/keystore/key.properties/private signing password.
- [x] Replacement upload-key/reset package prepared and locally validated.
- [ ] Recover historic upload key OR submit/complete Play upload-key reset.
- [ ] Confirm the replacement certificate fingerprint is accepted/displayed by Play Console.
- [ ] Only after Play acceptance, install the four GitHub Actions signing secrets.
- [ ] Run the production release workflow and compare its emitted upload-certificate fingerprint with Play Console.

Never upload the smoke AAB generated with the temporary CI key.

## 3. Google Play subscriptions

- [ ] Create/finalize the monthly subscription product in Play Console.
- [ ] Create/finalize the yearly subscription product in Play Console.
- [ ] Ensure product IDs are stable, distinct, and exactly match backend configuration.
- [ ] Add `PLAY_MONTHLY_PRODUCT_ID` and `PLAY_YEARLY_PRODUCT_ID` to GitHub Actions secrets.
- [ ] Configure Google Play Developer API service-account access.
- [ ] Configure RTDN/Pub/Sub identity, audience and verification-token settings.
- [ ] Validate purchase, restore, renewal, cancellation, expiry, refund/revoke where applicable, RTDN and account-binding behavior on a Play test track.

Production release CI intentionally fails closed while either product ID is missing.

## 4. Health Apps Declaration

Google Play requires all published apps to complete the Health Apps declaration, including testing tracks.

For the current FTR product design, review the declaration as follows:

- [ ] Declare the app's actual health-related functionality accurately. `Physical Therapy and Rehabilitation` is the most directly relevant Google Play health category for the current FTR subject matter; confirm this against the final feature set before submission.
- [ ] Do **not** declare `Medical Device Apps` unless the final product is actually regulated as a medical device under applicable law.
- [ ] Do not select patient-specific `Clinical Decision Support` merely because the educational curriculum contains clinical topics; select it only if the shipped app actually performs patient-specific decision-support functionality.
- [ ] Confirm the app does not request Health Connect/body-sensor permissions in the final manifest unless the declaration and product design are intentionally changed.

Current manifest baseline: `android.permission.INTERNET` only.

## 5. Required health/medical store-description disclaimer

For a health/medical app that is not regulated as a medical device, the Google Play listing description must contain a clear disclaimer. Before submission include wording equivalent to:

> FTR eğitim amaçlı bir uygulamadır. Tıbbi cihaz değildir; herhangi bir tıbbi durumu teşhis, tedavi, iyileştirme veya önleme amacı taşımaz. Tıbbi öneri, tanı veya tedavi için yetkin bir sağlık profesyoneline danışın.

- [ ] Disclaimer is present in the **Google Play store description**, not only inside the app/terms page.
- [x] Equivalent disclaimer is also present in the public FTR terms page.

## 6. Privacy policy

- [x] Public privacy/terms Edge Function deployed.
- [x] Privacy policy explains collected data, use, service providers, security and deletion/retention behavior.
- [x] Supabase service-role/secret credentials are not shipped in Flutter.
- [x] Public external account-deletion link is referenced by the privacy policy.
- [ ] Enter the public privacy policy URL in Play Console.
- [ ] Confirm the URL loads without authentication, geofencing or PDF/download behavior from a normal browser.
- [ ] Confirm the policy's developer/privacy contact mechanism matches the verified developer contact information used in Play Console.

## 7. Account deletion

- [x] In-app account-deletion flow exists.
- [x] Public external account-deletion page exists.
- [x] Backend deletion requires authenticated/fresh confirmation and deletes the auth user.
- [x] User-owned application rows use cascading deletion where reviewed.
- [ ] Enter the external account-deletion URL in the designated Play Console field.
- [ ] Verify the public page from a browser while signed out.
- [ ] Execute one end-to-end test-account deletion on the final Play test build and confirm associated application data is removed.

## 8. Data Safety — candidate declarations to verify against final build

Google Play defines collection as user data transmitted off the device, subject to its documented exceptions. The final form must reflect the shipped app and every included SDK.

Likely/current FTR data types requiring review:

- [ ] **Personal info → Email address** — account authentication.
- [ ] **Personal info → User IDs** — Supabase/auth account identifiers and account-bound application records.
- [ ] **Financial info → Purchase history** — Google Play subscription verification/status/event records. FTR does not receive full card/payment credentials from Play Billing.
- [ ] **App activity → App interactions / Other actions** — favorites, learning progress, quiz attempts and similar account-synced learning state; map each behavior to the Play form's current definitions.
- [ ] **Other user-generated content** — user-created personal notes stored/synced by the app.
- [ ] **In-app search history** — determine whether search queries are only processed ephemerally or are retained; answer the Play form according to the final backend behavior.
- [ ] **Crash logs / Diagnostics / Device IDs** — currently do not assume these are collected; re-check every production SDK/library and Play service integration before submission.
- [ ] **Health info / Fitness info** — do not declare merely because the app contains educational medical content. Declare these only if the shipped app actually collects/transmits data *about the user's own health or fitness*.

For every declared type, verify:

- collection vs sharing
- required vs optional
- purpose(s): app functionality, account management, fraud prevention/security, etc.
- encryption in transit
- deletion support
- whether a service-provider transfer qualifies as sharing under Google's current definitions

## 9. Store content / audience

- [ ] Confirm target audience accurately; do not position the app as a child-directed app unless the product is redesigned for that audience and corresponding policies are met.
- [ ] Complete content rating questionnaire accurately.
- [ ] Review screenshots, short description and full description for medical claims that exceed the actual educational product behavior.
- [ ] Avoid claims of guaranteed treatment, diagnosis, cure, prevention or clinical outcome.

## 10. Final Play test-track gate

Before production promotion:

- [ ] Production-signed AAB generated with the Play-accepted upload certificate.
- [ ] AAB package/version identity verified.
- [ ] Internal/closed Play test install succeeds.
- [ ] Existing-user upgrade continuity succeeds if an old Play version is available for upgrade testing.
- [ ] Sign-up/sign-in/recovery works.
- [ ] Lessons/content/media render correctly.
- [ ] Quiz/search/favorites/notes/progress persist correctly.
- [ ] Premium purchase/restore/entitlement lifecycle passes real Play tests.
- [ ] Network/offline/error states are acceptable.
- [ ] Account deletion passes end-to-end.
- [ ] Privacy policy and deletion URLs open publicly.
- [ ] Health Apps, Data Safety and store-description declarations match the exact shipped build.

## Release rule

Do not promote to production on the basis of a successful compile alone. Production promotion requires Play-accepted signing continuity, accurate policy declarations, real Play Billing validation and a clean device/test-track smoke pass.
