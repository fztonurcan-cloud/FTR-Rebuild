# FTR authentication architecture

## Product decision

Browsing is not gated by authentication. Users are asked to sign in when they use account-bound features such as Favorites, Notes, Progress, or Premium access.

## Current implementation

- Supabase Auth: email + password.
- `AuthService.signUp` optionally sends `display_name` as sign-up metadata. The database trigger copies this display value into `public.profiles`; metadata is not used for authorization.
- `AuthService.signIn` uses password authentication.
- `authUserProvider` listens to `onAuthStateChange`.
- Profile and Favorites screens render a login CTA when signed out.
- Session persistence is handled by `supabase_flutter`.

## Security boundary

- Mobile app uses only the Supabase publishable key.
- No service-role/secret key belongs in Flutter.
- User-owned rows remain protected by RLS.
- Premium authorization comes from `public.subscriptions`, not editable user metadata.
- A store purchase result on the phone is not sufficient to grant access. Verification happens on a trusted backend before `subscriptions` changes.

## Before public launch

1. Configure production SMTP and branded verification emails.
2. Add password-recovery deep link and change-password screen.
3. Re-test the implemented in-app account deletion flow on a release build and production-like account.
4. Add abuse/rate-limit handling and friendly localized auth errors.
5. Decide whether Google Sign-In and Sign in with Apple are part of v1.
