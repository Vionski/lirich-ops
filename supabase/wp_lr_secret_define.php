<?php
/**
 * ✅ STATUS: DEPLOYED & LIVE — task #16 CLOSED (Steps A–D done, verified 29 Jul 2026:
 *    valid token→200, forged→403, legacy key→403). The REAL secret is already set in the live
 *    WPCode snippet AND as the Supabase secret LR_TOKEN_SECRET (they match). This file is a
 *    REFERENCE TEMPLATE ONLY and intentionally holds a placeholder — the real value never lives here.
 *    ⛔ DO NOT re-run, re-set the secret, or "resume Step B". Pushing the placeholder or a new
 *       value would invalidate every token and break the live PIL dashboard. Nothing to do here.
 *
 * Lirich task #16 — SNIPPET 1 of 2: shared HMAC secret.
 * WPCode → Add Snippet → PHP → "Auto Insert / Run Everywhere" → Active.
 * (Keep this a separate snippet so the secret lives in one place and both the
 *  signer and any future verifier read it.)
 *
 * 🔑 Replace the value with a long random string (>= 32 chars), e.g. `openssl rand -hex 32`.
 *    This EXACT same string must also be set as the Supabase Edge Function secret
 *    named  LR_TOKEN_SECRET.  Never commit the real value.
 */
if (!defined('LR_TOKEN_SECRET_WP')) {
    define('LR_TOKEN_SECRET_WP', 'PUT_A_LONG_RANDOM_SECRET_HERE');
}
