abstract final class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  static const useMockContent =
      bool.fromEnvironment('USE_MOCK_CONTENT', defaultValue: false);

  // Internal device QA only. Preview reads are routed through the authenticated
  // internal-preview Edge Function and a server-side tester allowlist. Release
  // builds must never enable this compile-time switch.
  static const internalReviewPreview = bool.fromEnvironment(
    'INTERNAL_REVIEW_PREVIEW',
    defaultValue: false,
  );

  static const contentMediaBucket =
      String.fromEnvironment('CONTENT_MEDIA_BUCKET', defaultValue: 'content-assets');
  static const authRedirectUrl = String.fromEnvironment(
    'AUTH_REDIRECT_URL',
    defaultValue: 'com.mobiroller.mobi743032079412://login-callback/',
  );

  // Release-only configuration. Never invent or ship placeholder Play product IDs.
  static const playMonthlyProductId =
      String.fromEnvironment('PLAY_MONTHLY_PRODUCT_ID');
  static const playYearlyProductId =
      String.fromEnvironment('PLAY_YEARLY_PRODUCT_ID');

  static bool get hasSupabaseConfiguration =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;

  static Set<String> get configuredPlayProductIds => {
        if (playMonthlyProductId.trim().isNotEmpty) playMonthlyProductId.trim(),
        if (playYearlyProductId.trim().isNotEmpty) playYearlyProductId.trim(),
      };

  static bool get hasPlayProductConfiguration =>
      configuredPlayProductIds.isNotEmpty;
}
