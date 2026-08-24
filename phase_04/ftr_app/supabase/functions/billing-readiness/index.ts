Deno.serve((_req: Request) => {
  const packageName = Deno.env.get('GOOGLE_PLAY_PACKAGE_NAME')?.trim() ?? '';
  const serviceAccountRaw = Deno.env.get('GOOGLE_PLAY_SERVICE_ACCOUNT_JSON') ?? '';
  const allowedProducts = (Deno.env.get('GOOGLE_PLAY_ALLOWED_PRODUCT_IDS') ?? '')
    .split(',')
    .map((v) => v.trim())
    .filter((v) => v.length > 0);

  let validServiceAccount = false;
  if (serviceAccountRaw) {
    try {
      const parsed = JSON.parse(serviceAccountRaw);
      validServiceAccount = Boolean(parsed.client_email && parsed.private_key);
    } catch {
      validServiceAccount = false;
    }
  }

  const androidVerificationConfigured =
      packageName.length > 0 && validServiceAccount && allowedProducts.length > 0;
  const rtdnConfigured = androidVerificationConfigured &&
      Boolean(Deno.env.get('GOOGLE_PUBSUB_AUDIENCE')) &&
      Boolean(Deno.env.get('GOOGLE_PUBSUB_SERVICE_ACCOUNT_EMAIL')) &&
      Boolean(Deno.env.get('GOOGLE_PUBSUB_VERIFICATION_TOKEN'));

  return Response.json({
    androidVerificationConfigured,
    rtdnConfigured,
    allowedProductCount: allowedProducts.length,
  }, {
    headers: { 'cache-control': 'no-store' },
  });
});
