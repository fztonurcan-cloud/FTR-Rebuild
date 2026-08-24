import { createClient } from 'npm:@supabase/supabase-js@2';

type ServiceAccount = { client_email: string; private_key: string; token_uri?: string };
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

function adminClient() {
  const secretKeys = JSON.parse(Deno.env.get('SUPABASE_SECRET_KEYS') ?? '{}');
  const secret = secretKeys.default ?? Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!secret) throw new Error('supabase_secret_missing');
  return createClient(Deno.env.get('SUPABASE_URL')!, secret, { auth: { persistSession: false } });
}

function b64url(input: Uint8Array | string): string {
  const bytes = typeof input === 'string' ? new TextEncoder().encode(input) : input;
  let binary = '';
  for (const b of bytes) binary += String.fromCharCode(b);
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/g, '');
}
function pemToBytes(pem: string): Uint8Array {
  const normalized = pem.replace(/-----BEGIN PRIVATE KEY-----/g, '').replace(/-----END PRIVATE KEY-----/g, '').replace(/\s+/g, '');
  const binary = atob(normalized);
  return Uint8Array.from(binary, c => c.charCodeAt(0));
}
function parseServiceAccount(): ServiceAccount | null {
  const raw = Deno.env.get('GOOGLE_PLAY_SERVICE_ACCOUNT_JSON');
  if (!raw) return null;
  try { const p = JSON.parse(raw); return p.client_email && p.private_key ? p : null; } catch { return null; }
}
async function getGoogleAccessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const h = b64url(JSON.stringify({ alg: 'RS256', typ: 'JWT' }));
  const p = b64url(JSON.stringify({ iss: sa.client_email, scope: ANDROID_PUBLISHER_SCOPE, aud: sa.token_uri || DEFAULT_TOKEN_URI, iat: now, exp: now + 3600 }));
  const signingInput = `${h}.${p}`;
  const key = await crypto.subtle.importKey('pkcs8', pemToBytes(sa.private_key), { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' }, false, ['sign']);
  const sig = new Uint8Array(await crypto.subtle.sign('RSASSA-PKCS1-v1_5', key, new TextEncoder().encode(signingInput)));
  const assertion = `${signingInput}.${b64url(sig)}`;
  const res = await fetch(sa.token_uri || DEFAULT_TOKEN_URI, { method: 'POST', headers: { 'content-type': 'application/x-www-form-urlencoded' }, body: new URLSearchParams({ grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer', assertion }) });
  if (!res.ok) throw new Error(`google_oauth_failed:${res.status}`);
  const json = await res.json();
  if (!json.access_token) throw new Error('google_oauth_missing_access_token');
  return json.access_token;
}
async function verifyPubSubOidc(req: Request): Promise<boolean> {
  const expectedAudience = Deno.env.get('GOOGLE_PUBSUB_AUDIENCE');
  const expectedEmail = Deno.env.get('GOOGLE_PUBSUB_SERVICE_ACCOUNT_EMAIL');
  const expectedQueryToken = Deno.env.get('GOOGLE_PUBSUB_VERIFICATION_TOKEN');
  if (!expectedAudience || !expectedEmail || !expectedQueryToken) throw new Error('rtdn_not_configured');
  const url = new URL(req.url);
  if (url.searchParams.get('token') !== expectedQueryToken) return false;
  const auth = req.headers.get('authorization') ?? '';
  if (!auth.startsWith('Bearer ')) return false;
  const jwt = auth.slice(7);
  const res = await fetch(`https://oauth2.googleapis.com/tokeninfo?id_token=${encodeURIComponent(jwt)}`);
  if (!res.ok) return false;
  const claims = await res.json();
  const issuerOk = claims.iss === 'accounts.google.com' || claims.iss === 'https://accounts.google.com';
  const emailVerified = claims.email_verified === true || claims.email_verified === 'true';
  const expOk = Number(claims.exp ?? 0) > Math.floor(Date.now() / 1000);
  return issuerOk && emailVerified && expOk && claims.aud === expectedAudience && claims.email === expectedEmail;
}
function decodeBase64Utf8(data: string): string {
  const bin = atob(data);
  const bytes = Uint8Array.from(bin, c => c.charCodeAt(0));
  return new TextDecoder().decode(bytes);
}
async function fetchSubscription(packageName: string, token: string, accessToken: string): Promise<any> {
  const url = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${encodeURIComponent(packageName)}/purchases/subscriptionsv2/tokens/${encodeURIComponent(token)}`;
  const res = await fetch(url, { headers: { authorization: `Bearer ${accessToken}` } });
  if (!res.ok) { console.error('subscriptionsv2.get failed', res.status, (await res.text()).slice(0, 800)); throw new Error(`google_subscription_lookup_failed:${res.status}`); }
  return await res.json();
}
function chooseLineItem(items: any[]): any | null {
  if (!Array.isArray(items) || !items.length) return null;
  return [...items].sort((a,b) => (b?.expiryTime ? Date.parse(b.expiryTime) : 0) - (a?.expiryTime ? Date.parse(a.expiryTime) : 0))[0] ?? null;
}
async function acknowledgeIfNeeded(packageName: string, productId: string, token: string, accessToken: string, ackState: string): Promise<string> {
  if (ackState !== 'ACKNOWLEDGEMENT_STATE_PENDING') return ackState;
  const url = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${encodeURIComponent(packageName)}/purchases/subscriptions/${encodeURIComponent(productId)}/tokens/${encodeURIComponent(token)}:acknowledge`;
  const res = await fetch(url, { method: 'POST', headers: { authorization: `Bearer ${accessToken}`, 'content-type': 'application/json' }, body: '{}' });
  if (!res.ok) { console.error('ack failed', res.status, (await res.text()).slice(0, 800)); throw new Error(`google_acknowledge_failed:${res.status}`); }
  return 'ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED';
}

Deno.serve(async (req: Request) => {
  let claimedMessageId: string | null = null;
  let admin: ReturnType<typeof adminClient> | null = null;

  if (req.method !== 'POST') return Response.json({ error: 'method_not_allowed' }, { status: 405 });
  const packageName = Deno.env.get('GOOGLE_PLAY_PACKAGE_NAME')?.trim();
  const sa = parseServiceAccount();
  const allowedProducts = allowedProductIds();
  if (!packageName || !sa || allowedProducts.size === 0 || !Deno.env.get('GOOGLE_PUBSUB_AUDIENCE') || !Deno.env.get('GOOGLE_PUBSUB_SERVICE_ACCOUNT_EMAIL') || !Deno.env.get('GOOGLE_PUBSUB_VERIFICATION_TOKEN')) {
    return Response.json({ error: 'billing_rtdn_not_configured' }, { status: 503 });
  }

  try {
    if (!(await verifyPubSubOidc(req))) return Response.json({ error: 'invalid_pubsub_identity' }, { status: 401 });
    const envelope = await req.json();
    const messageId = String(envelope?.message?.messageId ?? envelope?.message?.message_id ?? '');
    const encoded = envelope?.message?.data;
    if (!messageId || typeof encoded !== 'string') return Response.json({ error: 'invalid_pubsub_envelope' }, { status: 400 });
    claimedMessageId = messageId;

    const payload = JSON.parse(decodeBase64Utf8(encoded));
    if (payload.packageName && payload.packageName !== packageName) return Response.json({ error: 'package_mismatch' }, { status: 400 });

    const sub = payload.subscriptionNotification ?? null;
    const purchaseToken = typeof sub?.purchaseToken === 'string' ? sub.purchaseToken : null;
    const notificationType = Number.isInteger(sub?.notificationType) ? sub.notificationType : null;
    admin = adminClient();
    const { data: claim, error: claimError } = await admin.rpc('service_claim_google_rtdn_message', {
      p_message_id: messageId,
      p_package_name: payload.packageName ?? packageName,
      p_notification_type: notificationType,
      p_purchase_token: purchaseToken,
      p_raw_payload: payload,
    });
    if (claimError) throw new Error('rtdn_claim_failed');
    if (claim?.already_processed) return new Response(null, { status: 204 });

    if (payload.testNotification) {
      await admin.rpc('service_finish_google_rtdn_message', { p_message_id: messageId, p_processing_error: null });
      return new Response(null, { status: 204 });
    }
    if (!purchaseToken || !sub) {
      await admin.rpc('service_finish_google_rtdn_message', { p_message_id: messageId, p_processing_error: null });
      return new Response(null, { status: 204 });
    }

    const userId = claim?.user_id;
    if (!userId) {
      await admin.rpc('service_finish_google_rtdn_message', { p_message_id: messageId, p_processing_error: 'purchase_owner_not_found' });
      return Response.json({ error: 'purchase_owner_not_found' }, { status: 503 });
    }

    const accessToken = await getGoogleAccessToken(sa);
    const purchase = await fetchSubscription(packageName, purchaseToken, accessToken);
    const line = chooseLineItem(purchase.lineItems ?? []);
    if (!line?.productId) throw new Error('google_response_missing_product');

    if (!allowedProducts.has(line.productId)) {
      await admin.rpc('service_finish_google_rtdn_message', { p_message_id: messageId, p_processing_error: null });
      return new Response(null, { status: 204 });
    }

    const external = purchase.externalAccountIdentifiers ?? {};
    const obfuscatedAccountId = external.obfuscatedExternalAccountId ?? null;
    if (obfuscatedAccountId != null && obfuscatedAccountId !== userId) {
      throw new Error('purchase_account_mismatch');
    }

    const ackState = await acknowledgeIfNeeded(packageName, line.productId, purchaseToken, accessToken, purchase.acknowledgementState ?? 'ACKNOWLEDGEMENT_STATE_UNSPECIFIED');
    const offer = line.offerDetails ?? {};
    const { error: applyError } = await admin.rpc('service_apply_google_subscription_verification', {
      p_user_id: userId,
      p_purchase_token: purchaseToken,
      p_package_name: packageName,
      p_product_id: line.productId,
      p_google_subscription_state: purchase.subscriptionState ?? 'SUBSCRIPTION_STATE_UNSPECIFIED',
      p_acknowledgement_state: ackState,
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
    if (applyError) throw new Error('subscription_persist_failed');

    await admin.rpc('service_finish_google_rtdn_message', { p_message_id: messageId, p_processing_error: null });
    return new Response(null, { status: 204 });
  } catch (error) {
    console.error('rtdn processing error', error);
    if (admin && claimedMessageId) {
      const message = error instanceof Error ? error.message.slice(0, 500) : 'rtdn_processing_failed';
      await admin.rpc('service_finish_google_rtdn_message', {
        p_message_id: claimedMessageId,
        p_processing_error: message,
      });
    }
    return Response.json({ error: 'rtdn_processing_failed' }, { status: 500 });
  }
});
