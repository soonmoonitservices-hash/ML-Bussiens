// Legt einen neuen Benutzer an. Zwei Arten (Feld `mode`):
//  - `join` (Standard): in der Firma des angemeldeten Benutzers. Jeder aktive Benutzer der Firma darf das (Chef und Verwaltung haben gleiche Rechte). Die Firma kommt immer aus dem Profil des Aufrufers, nie aus der Anfrage.
//  - `new_company`: eigene, neue Firma mit eigenem Chef-Konto. Das darf nur der Superadmin (Tabelle platform_admins, geprüft über die Datenbank). Der neue Benutzer sieht nichts von der Firma des Aufrufers und umgekehrt.
// Läuft mit dem Service-Role-Key, der nur hier in der Edge Function liegt, nie in der App.
import { createClient } from 'npm:@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// Höchstens so viele Benutzer je Firma (Schutz vor Missbrauch).
const MAX_USERS_PER_TENANT = 20;

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

  const admin = createClient(url, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
  const { data: caller } = await admin
    .from('profiles')
    .select('role, active, tenant_id')
    .eq('id', userData.user.id)
    .maybeSingle();
  if (!caller || !caller.active) {
    return reply(403, { message: 'Du darfst keine Benutzer anlegen.' });
  }

  let input: {
    email?: unknown;
    name?: unknown;
    password?: unknown;
    mode?: unknown;
    company?: unknown;
  };
  try {
    input = await request.json();
  } catch {
    return reply(400, { message: 'Die Eingabe ist ungültig.' });
  }
  const email = typeof input.email === 'string' ? input.email.trim().toLowerCase() : '';
  const name = typeof input.name === 'string' ? input.name.trim() : '';
  const password = typeof input.password === 'string' ? input.password : '';
  const company = typeof input.company === 'string' ? input.company.trim() : '';
  if (input.mode !== undefined && input.mode !== 'join' && input.mode !== 'new_company') {
    return reply(400, { message: 'Die Eingabe ist ungültig.' });
  }
  const mode: 'join' | 'new_company' = input.mode === 'new_company' ? 'new_company' : 'join';

  if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) {
    return reply(400, { message: 'Bitte eine gültige E-Mail-Adresse eingeben.' });
  }
  if (name.length === 0 || name.length > 100) {
    return reply(400, { message: 'Bitte einen Namen eingeben.' });
  }
  if (password.length < 8 || password.length > 72) {
    return reply(400, { message: 'Das Passwort braucht mindestens 8 Zeichen.' });
  }

  let metadata: Record<string, unknown>;
  if (mode === 'new_company') {
    // Nur der Superadmin darf neue Firmen anlegen (Prüfung in der Datenbank, mit dem Token des Aufrufers).
    const { data: isSuper } = await userClient.rpc('is_superadmin');
    if (isSuper !== true) {
      return reply(403, { message: 'Neue Firmen darf nur der Superadmin anlegen.' });
    }
    if (company.length === 0 || company.length > 100) {
      return reply(400, { message: 'Bitte einen Firmennamen eingeben.' });
    }
    // Die Datenbank (Trigger) legt die neue Firma an und macht den Benutzer zum Chef.
    metadata = { name, company, new_tenant: true };
  } else {
    const { count } = await admin
      .from('profiles')
      .select('id', { count: 'exact', head: true })
      .eq('tenant_id', caller.tenant_id);
    if ((count ?? 0) >= MAX_USERS_PER_TENANT) {
      return reply(409, { message: 'Es sind schon so viele Benutzer angelegt, wie möglich sind.' });
    }
    // Die Datenbank (Trigger) legt das Profil in der Firma des Aufrufers an, Rolle Verwaltung (oder Chef, falls die Firma noch keinen aktiven Chef hat).
    metadata = { name, tenant_id: caller.tenant_id };
  }

  const { data, error } = await admin.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
    user_metadata: metadata,
  });
  if (error) {
    const alreadyUsed = /already|registered|exists/i.test(error.message);
    return reply(alreadyUsed ? 409 : 400, {
      message: alreadyUsed ? 'Diese E-Mail-Adresse wird schon benutzt.' : 'Der Benutzer konnte nicht angelegt werden.',
    });
  }
  return reply(200, { ok: true, id: data.user?.id, mode });
});
