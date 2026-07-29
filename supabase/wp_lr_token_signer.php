<?php
/**
 * ✅ STATUS: DEPLOYED & LIVE — task #16 CLOSED (verified 29 Jul 2026). The live WPCode signer is
 *    AHEAD of this template: it also emits window.LR_TOKEN on the operator page 2721 (health check
 *    on 2721 confirmed the token + valid→200 / forged→403 / legacy key→403). This file is
 *    REFERENCE ONLY. ⛔ Do not redeploy from here, and do not paste a live window.LR_TOKEN into chat.
 *
 * Lirich task #16 — SNIPPET 2 of 2: WP-signed per-user token.
 * WPCode → Add Snippet → PHP → "Auto Insert / Run Everywhere" → Active.
 * Injects window.LR_TOKEN in <head> (before the dashboard iframes load) for the
 * logged-in user, scoped to their client_id. The report Edge Function verifies it.
 * Reads the secret from SNIPPET 1 (LR_TOKEN_SECRET_WP).
 */
add_action('wp_head', function () {
    if (!is_page(2691) || !is_user_logged_in()) return;

    $SECRET = defined('LR_TOKEN_SECRET_WP') ? LR_TOKEN_SECRET_WP : '';
    if (strlen($SECRET) < 24 || $SECRET === 'PUT_A_LONG_RANDOM_SECRET_HERE') return;

    $u = wp_get_current_user();

    // Map WP user -> client_id (data scope).
    $cid = get_user_meta($u->ID, 'lr_client_id', true);       // preferred: per-user meta
    if (!$cid) {
        if (user_can($u, 'manage_options')) $cid = 'ALL';     // Lirich admins: all clients + selector
        elseif ((int) $u->ID === 2)         $cid = 'PIL';     // PIL beta user (user_id 2)
    }
    if (!$cid) return;  // unmapped user -> no token (fails closed; report stays empty)

    $exp     = time() + 3600;  // 1 hour  (⏳ EXPIRY TEST: temporarily use  time() - 60  then revert)
    $payload = base64_encode($cid . '|' . $exp);
    $token   = $payload . '.' . hash_hmac('sha256', $payload, $SECRET);

    echo '<script>window.LR_TOKEN=' . json_encode($token) . ';</script>' . "\n";
}, 1);
