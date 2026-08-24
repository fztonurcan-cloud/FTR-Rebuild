import { withSupabase } from 'npm:@supabase/server';

export default {
  fetch: withSupabase({ auth: 'user' }, async (_req, ctx) => {
    const userId = ctx.userClaims?.sub;
    if (!userId) return Response.json({ error: 'user_not_found' }, { status: 401 });

    const { error } = await ctx.supabaseAdmin.auth.admin.deleteUser(userId);
    if (error) {
      console.error('delete user failed', error);
      return Response.json({ error: 'delete_failed' }, { status: 500 });
    }

    return Response.json({ deleted: true });
  }),
};
