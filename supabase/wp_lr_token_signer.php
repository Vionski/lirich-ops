<?php
/**
 * Lirich WordPress-signed access token.
 *
 * WordPress administrators become portal admins with internal controls.
 * Lirich staff become operators with a client selector and the client-safe view.
 * Client users are locked to one lr_client_id and never receive the selector.
 * The matching portal_accounts record in Supabase remains authoritative.
 */
add_action('wp_head', function () {
    if ((!is_page(2691) && !is_page(2721) && !is_page(3064)) || !is_user_logged_in()) return;

    $SECRET = defined('LR_TOKEN_SECRET_WP') ? LR_TOKEN_SECRET_WP : '';
    if (strlen($SECRET) < 24 || $SECRET === 'PUT_A_LONG_RANDOM_SECRET_HERE') return;

    $u = wp_get_current_user();

    $cid = strtoupper(trim(get_user_meta($u->ID, 'lr_client_id', true)));
    if (!$cid && (int) $u->ID === 2) $cid = 'PIL';

    $is_admin = user_can($u, 'manage_options');
    $is_staff = $is_admin
        || in_array('lirich_staff', (array) $u->roles, true)
        || ((int) $u->ID !== 2 && preg_match('/@lirichresources\.sg$/', strtolower(trim($u->user_email))));
    if ($is_staff) $cid = 'ALL';
    if (!$cid || !preg_match('/^[A-Z0-9_]{1,32}$/', $cid)) return;

    $role = $is_admin ? 'admin' : ($is_staff ? 'operator' : 'client');
    $ttl = $is_staff ? 28800 : 3600;
    $exp = time() + $ttl;
    $user_key = strtolower(trim($u->user_login));
    $payload = base64_encode($cid . '|' . $role . '|' . $user_key . '|' . $exp);
    $token = $payload . '.' . hash_hmac('sha256', $payload, $SECRET);

    echo '<script>window.LR_TOKEN=' . json_encode($token) . ';</script>' . "\n";
}, 1);
