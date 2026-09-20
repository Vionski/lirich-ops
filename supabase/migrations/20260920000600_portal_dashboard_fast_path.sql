begin;

create or replace function public.portal_cached_dashboard_fast(
  p_wp_login text,
  p_claim_role text,
  p_claim_client_id text,
  p_requested_client_id text,
  p_period_from date,
  p_period_to date,
  p_cache_version integer,
  p_endpoint text,
  p_request_id text
) returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_account public.portal_accounts%rowtype;
  v_cache public.portal_dashboard_cache%rowtype;
  v_staff boolean;
  v_client_id text;
begin
  begin
    select * into strict v_account
    from public.portal_accounts
    where wp_login = trim(p_wp_login);
  exception
    when no_data_found or too_many_rows then
      raise exception using message = 'account_inactive', errcode = 'P0001';
  end;

  if v_account.status <> 'active' or v_account.revoked_at is not null then
    raise exception using message = 'account_inactive', errcode = 'P0001';
  end if;
  if v_account.wp_login is null or lower(v_account.wp_login) <> lower(trim(p_wp_login)) then
    raise exception using message = 'account_inactive', errcode = 'P0001';
  end if;
  if lower(v_account.role) <> lower(trim(p_claim_role)) then
    raise exception using message = 'token_account_role_mismatch', errcode = 'P0001';
  end if;

  v_staff := lower(v_account.role) in ('operator', 'admin');
  if v_staff then
    if upper(trim(p_claim_client_id)) <> 'ALL' then
      raise exception using message = 'invalid_staff_scope', errcode = 'P0001';
    end if;
    v_client_id := upper(trim(coalesce(p_requested_client_id, '')));
    if v_client_id = '' then
      raise exception using message = 'staff_client_required', errcode = 'P0001';
    end if;
  else
    if v_account.client_id is null
       or upper(v_account.client_id) <> upper(trim(p_claim_client_id)) then
      raise exception using message = 'token_account_client_mismatch', errcode = 'P0001';
    end if;
    v_client_id := upper(v_account.client_id);
  end if;

  select * into v_cache
  from public.portal_dashboard_cache
  where client_id = v_client_id
    and period_from = p_period_from
    and period_to = p_period_to
    and cache_version = p_cache_version
    and expires_at > now();

  if not found then
    return jsonb_build_object('cache_hit', false, 'client_id', v_client_id);
  end if;

  insert into public.portal_access_events (
    portal_account_id, wp_user_id, wp_login, role, client_id,
    event_type, outcome, request_id, endpoint, detail
  ) values (
    v_account.id, v_account.wp_user_id, lower(v_account.wp_login), v_account.role, v_client_id,
    'portal.request', 'success', p_request_id, p_endpoint,
    jsonb_build_object(
      'endpoint', p_endpoint,
      'client_id', v_client_id,
      'cache_hit', true,
      'fast_path', true
    )
  );

  return jsonb_build_object(
    'cache_hit', true,
    'client_id', v_client_id,
    'payload', v_cache.payload || jsonb_build_object(
      'cache', jsonb_build_object(
        'hit', true,
        'generated_at', v_cache.generated_at,
        'expires_at', v_cache.expires_at,
        'source_row_count', v_cache.source_row_count,
        'fast_path', true
      )
    )
  );
end;
$$;

revoke all on function public.portal_cached_dashboard_fast(text,text,text,text,date,date,integer,text,text)
  from public, anon, authenticated;
grant execute on function public.portal_cached_dashboard_fast(text,text,text,text,date,date,integer,text,text)
  to service_role;

comment on function public.portal_cached_dashboard_fast(text,text,text,text,date,date,integer,text,text) is
  'Service-only fast path: validates the live portal account against signed WordPress claims, enforces tenant scope, returns one unexpired dashboard snapshot and appends its access event in one transaction.';

insert into supabase_migrations.schema_migrations(version, statements, name)
values ('20260920000600', null, 'portal_dashboard_fast_path')
on conflict (version) do nothing;

commit;
