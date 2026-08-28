import { withSupabase } from 'npm:@supabase/server@1.4.1';

const allowedActions = new Set([
  'categories',
  'featured',
  'category',
  'search',
  'detail',
  'curriculum',
  'quiz_questions',
  'quiz_submit',
]);

export default {
  fetch: withSupabase({ auth: 'user' }, async (req, ctx) => {
    if (req.method !== 'POST') {
      return Response.json({ error: 'method_not_allowed' }, { status: 405 });
    }

    const userId = ctx.userClaims?.sub;
    if (!userId) {
      console.error('internal-preview missing authenticated user claims');
      return Response.json({ error: 'unauthorized' }, { status: 401 });
    }

    let body: any;
    try {
      body = await req.json();
    } catch {
      return Response.json({ error: 'invalid_json' }, { status: 400 });
    }

    const action = typeof body?.action === 'string'
      ? body.action.trim().toLowerCase()
      : '';
    if (!allowedActions.has(action)) {
      return Response.json({ error: 'invalid_action' }, { status: 400 });
    }

    const payload = body?.payload && typeof body.payload === 'object' && !Array.isArray(body.payload)
      ? body.payload
      : {};

    const { data, error } = await ctx.supabaseAdmin.rpc('service_internal_preview', {
      p_user_id: userId,
      p_action: action,
      p_payload: payload,
    });

    if (error) {
      const denied = error.code === '42501' ||
        String(error.message ?? '').includes('internal_preview_not_allowed');
      if (!denied) console.error('internal-preview rpc failed', error);
      return Response.json(
        { error: denied ? 'internal_preview_not_allowed' : 'internal_preview_failed' },
        { status: denied ? 403 : 500 },
      );
    }

    return Response.json(
      { ok: true, data },
      { headers: { 'cache-control': 'no-store' } },
    );
  }),
};
