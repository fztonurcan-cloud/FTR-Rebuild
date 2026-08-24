import { withSupabase } from 'npm:@supabase/server';

type ServiceAccount = {
  client_email: string;
  private_key: string;
  token_uri?: string;
};

const ANDROID_PUBLISHER_SCOPE = 'https://www.googleapis.com/auth/androidpublisher';
const DEFAULT_TOKEN_URI = 'https://oauth2.googleapis.com/token';

function allowedProductIds(): Set<string> {
  return new Set(
    (Deno.env.get('GOOGLE_PLAY_ALLOWED_PRODUCT_IDS') ?? '')
      .split(',')
      .map((v) => v.trim())
      .filter((v) => v.length > 0),
  );
}

function b64url(input: Uint8Array | string): string {
  const bytes = typeof input === 'string' ? new TextEncoder().encode(input) : input;
  let binary = '';
  for (const b of bytes) binary += String.fromCharCode(b);
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/g, '');
}

function pemToBytes(pem: string): Uint8Array {
  const normalized = pem.replace(/-----BEGIN PRIVATE KEY-----/g, '')
    .replace(/-----END PRIVATE KEY-----/g, '')
    .replace(/\s+/g, '');
  const binary = atob(normalized);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes;
}

async function getGoogleAccessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = b64url(JSON.stringify({ alg: 'RS256', typ: 'JWT' }));
  const payload = b64url(JSON.stringify({
    iss: sa.client_email,
    scope: ANDROID_PUBLISHER_SCOPE,
    aud: sa.token_uri || DEFAULT_TOKEN_URI,
    iat: now,
    exp: now + 3600,
  }));
  const signingInput = `${header}.${payload}`;
  const key = await crypto.subtle.importKey(
    'pkcs8',
    pemToBytes(sa.private_key),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const sig = new Uint8Array(await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    key,
    new TextEncoder().encode(signingInput),
  ));
  const assertion = `${signingInput}.${b64url(sig)}`;

  const tokenRes = await fetch(sa.token_uri || DEFAULT_TOKEN_URI, {
    method: 'POST',
    headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion,
    }),
  });
  if (!tokenRes.ok) throw new Error(`google_oauth_failed:${tokenRes.status}`);
  const tokenJson = await tokenRes.json();
  if (!tokenJson.access_token) throw new Error('google_oauth_missing_access_token');
  return tokenJson.access_token as string;
}

function parseConfiguredServiceAccount(): ServiceAccount | null {
  const raw = Deno.env.get('GOOGLE_PLAY_SERVICE_ACCOUNT_JSON');
  if (!raw) return null;
  try {
    const parsed = JSON.parse(raw);
    if (!parsed.client_email || !parsed.private_key) return null;
    return parsed as ServiceAccount;
  } catch {
    return null;
  }
}

function chooseLineItem(lineItems: any[]): any | null {
  if (!Array.isArray(lineItems) || lineItems.length === 0) return null;
  return [...lineItems].sort((a, b) => {
    const at = a?.expiryTime ? Date.parse(a.expiryTime) : 0;
    const bt = b?.expiryTime ? Date.parse(b.expiryTime) : 0;
    return bt - at;
  })[0] ?? null;
}

async function fetchSubscription(packageName: string, token: string, accessToken: string): Promise<any> {
  const url = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${encodeURIComponent(packageName)}/purchases/subscriptionsv2/tokens/${encodeURIComponent(token)}`;
  const res = await fetch(url, { headers: { authorization: `Bearer ${accessToken}` } });
  if (!res.ok) {
    const body = await res.text();
    console.error('subscriptionsv2.get failed', res.status, body.slice(0, 800));
    throw new Error(`google_subscription_lookup_failed:${res.status}`);
  }
  return await res.json();
}

async function acknowledgeIfNeeded(packageName: string, productId: string, token: string, accessToken: string, ackState: string): Promise<string> {
  if (ackState !== 'ACKNOWLEDGEMENT_STATE_PENDING') return ackState;
  const url = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${encodeURIComponent(packageName)}/purchases/subscriptions/${encodeURIComponent(productId)}/tokens/${encodeURIComponent(token)}:acknowledge`;
  const res = await fetch(url, {
    method: 'POST',
    headers: { authorization: `Bearer ${accessToken}`, 'content-type': 'application/json' },
    body: '{}',
  });
  if (!res.ok) {
    const body = await res.text();
    console.error('subscription acknowledge failed', res.status, body.slice(0, 800));
    throw new Error(`google_acknowledge_failed:${res.status}`);
  }
  return 'ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED';
}

export default {
  fetch: withSupabase({ auth: 'user' }, async (req, ctx) => {
    if (req.method !== 'POST') return Response.json({ error: 'method_not_allowed' }, { status: 405 });

    const userId = ctx.userClaims?.sub;
    if (!userId) return Response.json({ error: 'unauthorized' }, { status: 401 });

    const packageName = Deno.env.get('GOOGLE_PLAY_PACKAGE_NAME')?.trim();
    const serviceAccount = parseConfiguredServiceAccount();
    const allowedProducts = allowedProductIds();
    if (!packageName || !serviceAccount || allowedProducts.size === 0) {
      return Response.json({ error: 'billing_not_configured' }, { status: 503 });
    }

    let body: any;
    try { body = await req.json(); } catch { return Response.json({ error: 'invalid_json' }, { status: 400 }); }
    const purchaseToken = typeof body?.purchaseToken === 'string' ? body.purchaseToken.trim() : '';
    if (purchaseToken.length < 8 || purchaseToken.length > 4096) {
      return Response.json({ error: 'invalid_purchase_token' }, { status: 400 });
    }

    try {
      const accessToken = await getGoogleAccessToken(serviceAccount);
      const purchase = await fetchSubscription(packageName, purchaseToken, accessToken);
      const line = chooseLineItem(purchase.lineItems ?? []);
      if (!line?.productId) return Response.json({ error: 'google_response_missing_product' }, { status: 502 });

      const productId = line.productId as string;
      if (!allowedProducts.has(productId)) {
        return Response.json({ error: 'product_not_entitled' }, { status: 400 });
      }

      const external = purchase.externalAccountIdentifiers ?? {};
      const obfuscatedAccountId = external.obfuscatedExternalAccountId ?? null;
      if (obfuscatedAccountId != null && obfuscatedAccountId !== userId) {
        return Response.json({ error: 'purchase_account_mismatch' }, { status: 409 });
      }

      const acknowledgementState = await acknowledgeIfNeeded(
        packageName,
        productId,
        purchaseToken,
        accessToken,
        purchase.acknowledgementState ?? 'ACKNOWLEDGEMENT_STATE_UNSPECIFIED',
      );
      const offer = line.offerDetails ?? {};

      const { data, error } = await ctx.supabaseAdmin.rpc('service_apply_google_subscription_verification', {
        p_user_id: userId,
        p_purchase_token: purchaseToken,
        p_package_name: packageName,
        p_product_id: productId,
        p_google_subscription_state: purchase.subscriptionState ?? 'SUBSCRIPTION_STATE_UNSPECIFIED',
        p_acknowledgement_state: acknowledgementState,
        p_start_time: purchase.startTime ?? null,
        p_expires_at: line.expiryTime ?? null,
        p_auto_renew_enabled: Boolean(line.autoRenewingPlan?.autoRenewEnabled ?? false),
        p_linked_purchase_token: purchase.linkedPurchaseToken ?? null,
        p_latest_order_id: line.latestSuccessfulOrderId ?? null,
        p_external_account_identifier: obfuscatedAccountId ?? external.externalAccountId ?? null,
        p_test_purchase: Boolean(purchase.testPurchase),
        p_raw_response: purchase,
        p_base_plan_id: offer.basePlanId ?? null,
        p_offer_id: offer.offerId ?? null,
      });
      if (error) {
        console.error('apply verification failed', error);
        return Response.json({ error: 'subscription_persist_failed' }, { status: 500 });
      }

      return Response.json({ verified: true, subscription: data });
    } catch (error) {
      console.error('verification error', error);
      const message = error instanceof Error ? error.message : 'verification_failed';
      return Response.json({ error: 'verification_failed', detail: message }, { status: 502 });
    }
  }),
};
