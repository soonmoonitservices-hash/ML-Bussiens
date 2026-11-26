// Löscht das eigene Konto (Pflicht für den Apple App Store).
// Der letzte aktive Chef kann sein Konto nicht löschen. Läuft mit dem Service-Role-Key,
// der nur hier in der Edge Function liegt, nie in der App.
import { createClient } from 'npm:@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

function reply(status: number, body: Record<string, unknown>): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

Deno.serve(async (request: Request): Promise<Response> => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  const authorization = request.headers.get('Authorization');
  if (!authorization) {
    return reply(401, { message: 'Bitte melden Sie sich an.' });
  }

  const url = Deno.env.get('SUPABASE_URL')!;
  const userClient = createClient(url, Deno.env.get('SUPABASE_ANON_KEY')!, {
    global: { headers: { Authorization: authorization } },
  });
  const { data: userData, error: userError } = await userClient.auth.getUser();
  if (userError || !userData.user) {
    return reply(401, { message: 'Bitte melden Sie sich an.' });
  }
  const userId = userData.user.id;

  const admin = createClient(url, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
  const { data: profile } = await admin
    .from('profiles')
    .select('role, active')
    .eq('id', userId)
    .maybeSingle();

  if (profile?.role === 'chef' && profile.active) {
    const { count } = await admin
      .from('profiles')
      .select('id', { count: 'exact', head: true })
      .eq('role', 'chef')
      .eq('active', true)
      .neq('id', userId);
    if (!count) {
      return reply(409, { message: 'Der letzte Chef kann sein Konto nicht löschen.' });
    }
  }

  const { error: deleteError } = await admin.auth.admin.deleteUser(userId);
  if (deleteError) {
    // Die Datenbank-Sperre „mindestens ein aktiver Chef“ meldet sich hier mit ihrem deutschen Text.
    return reply(409, { message: deleteError.message });
  }
  return reply(200, { ok: true });
});
