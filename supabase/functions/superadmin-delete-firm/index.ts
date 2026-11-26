// Superadmin: löscht eine Firma endgültig mit allen Daten, Dateien und Benutzerkonten.
// NICHT rückgängig zu machen. Nur Superadmins dürfen das; geprüft über die Datenbank. Die eigene
// Firma des Superadmins lässt sich nicht löschen (prüft die Datenbank-Funktion).
// Läuft mit dem Service-Role-Key, der nur hier in der Edge Function liegt, nie in der App.
import { createClient, SupabaseClient } from 'npm:@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

const BUCKETS = ['receipts', 'signatures', 'documents', 'logos', 'products'];

function reply(status: number, body: Record<string, unknown>): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

// Alle Dateien unter einem Ordner einsammeln (rekursiv, in Seiten).
async function listFiles(admin: SupabaseClient, bucket: string, prefix: string): Promise<string[]> {
  const files: string[] = [];
  let offset = 0;
  while (true) {
    const { data, error } = await admin.storage.from(bucket).list(prefix, { limit: 100, offset });
    if (error || !data || data.length === 0) break;
    for (const entry of data) {
      const path = `${prefix}/${entry.name}`;
      if (entry.id === null) {
        files.push(...(await listFiles(admin, bucket, path)));
      } else {
        files.push(path);
      }
    }
    if (data.length < 100) break;
    offset += 100;
  }
  return files;
}

Deno.serve(async (request: Request): Promise<Response> => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }
  if (request.method !== 'POST') {
    return reply(405, { message: 'Nur POST ist erlaubt.' });
  }
  const authorization = request.headers.get('Authorization');
  if (!authorization) {
    return reply(401, { message: 'Bitte melde dich an.' });
  }

  const url = Deno.env.get('SUPABASE_URL')!;
  const userClient = createClient(url, Deno.env.get('SUPABASE_ANON_KEY')!, {
    global: { headers: { Authorization: authorization } },
  });
  const { data: userData, error: userError } = await userClient.auth.getUser();
  if (userError || !userData.user) {
    return reply(401, { message: 'Bitte melde dich an.' });
  }
  const { data: isSuper } = await userClient.rpc('is_superadmin');
  if (isSuper !== true) {
    return reply(403, { message: 'Das darf nur der Superadmin.' });
  }

  let input: { tenant_id?: unknown };
  try {
    input = await request.json();
  } catch {
    return reply(400, { message: 'Die Eingabe ist ungültig.' });
  }
  const tenantId = typeof input.tenant_id === 'string' ? input.tenant_id : '';
  if (!/^[0-9a-f-]{36}$/i.test(tenantId)) {
    return reply(400, { message: 'Die Firma ist ungültig.' });
  }

  // 1. Datenbank: alle Daten und Profile der Firma löschen (prüft auch den Superadmin).
  const { data: userIds, error: dbError } = await userClient.rpc('superadmin_delete_tenant', {
    p_tenant: tenantId,
  });
  if (dbError) {
    return reply(409, { message: dbError.message });
  }

  const admin = createClient(url, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);

  // 2. Dateien der Firma löschen (Ordner = Firmen-Kennung).
  for (const bucket of BUCKETS) {
    const paths = await listFiles(admin, bucket, tenantId);
    for (let i = 0; i < paths.length; i += 100) {
      await admin.storage.from(bucket).remove(paths.slice(i, i + 100));
    }
  }

  // 3. Anmelde-Konten der Firma löschen.
  for (const id of (userIds as string[] | null) ?? []) {
    await admin.auth.admin.deleteUser(id);
  }
  return reply(200, { ok: true });
});
