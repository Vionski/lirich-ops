import { createClient, SupabaseClient } from "npm:@supabase/supabase-js@2";
import { JWK, SignJWT } from "npm:jose@5";

export type PortalRole = "client" | "client_admin" | "operator" | "admin";
export type PortalAccount = {
  id: number;
  wp_user_id: number | null;
  wp_login: string;
  display_name: string | null;
  client_id: string | null;
  role: PortalRole;
  status: string;
};

export type PortalContext = {
  account: PortalAccount;
  staff: boolean;
  admin: SupabaseClient;
  db: SupabaseClient;
  requestId: string;
};

export type WordPressClaims = {
  clientId: string;
  role: PortalRole;
  wpLogin: string;
};

const encoder = new TextEncoder();

function required(name: string): string {
  const value = Deno.env.get(name)?.trim();
  if (!value) throw new Error(`missing_server_secret:${name}`);
  return value;
}

function bearer(req: Request): string | null {
  const value = req.headers.get("authorization") || "";
  const match = value.match(/^Bearer\s+(.+)$/i);
  return match?.[1]?.trim() || null;
}

async function hmacHex(message: string, secret: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign("HMAC", key, encoder.encode(message));
  return [...new Uint8Array(signature)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

function timingSafeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}

async function verifyWordPressToken(token: string): Promise<WordPressClaims> {
  const dot = token.lastIndexOf(".");
  if (dot <= 0) throw new Error("invalid_token");
  const payload = token.slice(0, dot);
  const actual = token.slice(dot + 1).toLowerCase();
  const expected = await hmacHex(payload, required("LR_TOKEN_SECRET"));
  if (!timingSafeEqual(actual, expected)) throw new Error("invalid_token");

  let decoded = "";
  try {
    decoded = atob(payload);
  } catch {
    throw new Error("invalid_token");
  }
  const fields = decoded.split("|");
  if (fields.length !== 4) throw new Error("unsupported_token_version");
  const clientId = fields[0].trim().toUpperCase();
  const role = fields[1].trim().toLowerCase() as PortalRole;
  const rawLogin = fields[2].trim();
  const wpLogin = rawLogin.toLowerCase();
  const expires = Number(fields[3]);
  if (!clientId || !wpLogin || rawLogin !== wpLogin || !Number.isFinite(expires)) {
    throw new Error("invalid_token_claims");
  }
  if (!["client", "client_admin", "operator", "admin"].includes(role)) {
    throw new Error("invalid_token_role");
  }
  if (Math.floor(Date.now() / 1000) >= expires) throw new Error("expired_token");
  return { clientId, role, wpLogin };
}

export async function verifyWordPressRequest(req: Request): Promise<WordPressClaims> {
  const token = bearer(req);
  if (!token) throw new Error("missing_bearer_token");
  return await verifyWordPressToken(token);
}

export function serviceClient(): SupabaseClient {
  return createClient(required("SUPABASE_URL"), required("SUPABASE_SERVICE_ROLE_KEY"), {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

async function stableUuid(input: string): Promise<string> {
  const hash = new Uint8Array(await crypto.subtle.digest("SHA-256", encoder.encode(input)));
  const bytes = hash.slice(0, 16);
  bytes[6] = (bytes[6] & 0x0f) | 0x50;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  const hex = [...bytes].map((b) => b.toString(16).padStart(2, "0")).join("");
  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20)}`;
}

async function internalJwt(account: PortalAccount): Promise<string> {
  const url = required("SUPABASE_URL");
  const jwk = JSON.parse(required("PORTAL_JWT_PRIVATE_JWK")) as JWK;
  const alg = String(jwk.alg || "ES256");
  if (alg !== "ES256" || jwk.kty !== "EC" || jwk.crv !== "P-256" || !jwk.d) {
    throw new Error("invalid_portal_signing_key");
  }
  // Supabase's signing-key import requires both sign and verify in key_ops, but
  // Web Crypto correctly permits only sign for an EC private key. Strip the
  // metadata before importing so browser-generated JWKs work in Deno.
  const { key_ops: _keyOps, use: _use, ext: _ext, alg: _alg, ...keyMaterial } = jwk as Record<string, unknown>;
  const key = await crypto.subtle.importKey(
    "jwk",
    keyMaterial as JsonWebKey,
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["sign"],
  );
  const now = Math.floor(Date.now() / 1000);
  return await new SignJWT({
    role: "authenticated",
    portal_account_id: String(account.id),
    wp_login: account.wp_login,
    portal_role: account.role,
    client_id: account.client_id || "",
  })
    .setProtectedHeader({ alg, kid: jwk.kid ? String(jwk.kid) : undefined, typ: "JWT" })
    .setSubject(await stableUuid(`lirich-wp:${account.id}:${account.wp_login}`))
    .setAudience("authenticated")
    .setIssuer(`${url}/auth/v1`)
    .setIssuedAt(now)
    .setExpirationTime(now + 60)
    .sign(key);
}

export async function authenticate(req: Request): Promise<PortalContext> {
  const claims = await verifyWordPressRequest(req);
  const url = required("SUPABASE_URL");
  const admin = serviceClient();

  const { data, error } = await admin.from("portal_accounts")
    .select("id,wp_user_id,wp_login,display_name,client_id,role,status,revoked_at")
    .eq("wp_login", claims.wpLogin)
    .maybeSingle();
  if (error) throw new Error(`account_lookup_failed:${error.message}`);
  if (!data || data.status !== "active" || data.revoked_at) throw new Error("account_inactive");

  const account: PortalAccount = {
    id: Number(data.id),
    wp_user_id: data.wp_user_id == null ? null : Number(data.wp_user_id),
    wp_login: String(data.wp_login).toLowerCase(),
    display_name: data.display_name ? String(data.display_name) : null,
    client_id: data.client_id ? String(data.client_id).toUpperCase() : null,
    role: String(data.role) as PortalRole,
    status: String(data.status),
  };
  const staff = account.role === "operator" || account.role === "admin";
  if (account.role !== claims.role) throw new Error("token_account_role_mismatch");
  if (!staff && (!account.client_id || account.client_id !== claims.clientId)) {
    throw new Error("token_account_client_mismatch");
  }
  if (staff && claims.clientId !== "ALL") throw new Error("invalid_staff_scope");

  const jwt = await internalJwt(account);
  const db = createClient(url, required("SUPABASE_ANON_KEY"), {
    auth: { persistSession: false, autoRefreshToken: false },
    global: { headers: { Authorization: `Bearer ${jwt}` } },
  });
  return { account, staff, admin, db, requestId: crypto.randomUUID() };
}

export async function writeAccessEvent(
  ctx: Pick<PortalContext, "admin" | "account" | "requestId">,
  eventType: string,
  outcome: "success" | "denied" | "failed",
  detail: Record<string, unknown> = {},
  required = false,
): Promise<void> {
  const row = {
    portal_account_id: ctx.account.id,
    wp_user_id: ctx.account.wp_user_id,
    wp_login: ctx.account.wp_login,
    role: ctx.account.role,
    client_id: typeof detail.client_id === "string" ? detail.client_id : ctx.account.client_id,
    event_type: eventType,
    outcome,
    request_id: ctx.requestId,
    endpoint: typeof detail.endpoint === "string" ? detail.endpoint : null,
    format: typeof detail.format === "string" ? detail.format : null,
    reporting_period_id: typeof detail.reporting_period_id === "string" ? detail.reporting_period_id : null,
    template_version_id: typeof detail.template_version_id === "string" ? detail.template_version_id : null,
    artifact_id: typeof detail.artifact_id === "string" ? detail.artifact_id : null,
    detail,
  };
  const { error } = await ctx.admin.from("portal_access_events").insert(row);
  if (error) {
    console.error("portal_access_event_failed", error.message, ctx.requestId);
    if (required) throw new Error(`portal_access_event_failed:${error.message}`);
  }
}

export function resolveClient(ctx: PortalContext, requested: string | null): string {
  if (!ctx.staff) {
    if (!ctx.account.client_id) throw new Error("account_has_no_client");
    return ctx.account.client_id;
  }
  const selected = (requested || "").trim().toUpperCase();
  if (!selected) throw new Error("staff_client_required");
  return selected;
}
