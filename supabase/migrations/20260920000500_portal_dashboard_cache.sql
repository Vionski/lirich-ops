begin;

-- The live reporting engine excludes superseded delivery orders. Keep this
-- schema dependency explicit so a newly restored/staging database behaves the
-- same as production before the dashboard cache is used.
alter table public.collections
  add column if not exists superseded_by text;

-- The portal's short-lived internal JWT uses the authenticated role. The view
-- is security_invoker, so its underlying tenant RLS still applies.
grant select on public.v_invoice_vs_collections, public.v_xero_invoice_lines to authenticated;

create table if not exists public.portal_dashboard_cache (
  client_id text not null references public.customers(client_id) on update cascade on delete cascade,
  period_from date not null,
  period_to date not null,
  cache_version integer not null default 1,
  payload jsonb not null,
  generated_at timestamptz not null default now(),
  expires_at timestamptz not null,
  source_row_count integer not null default 0,
  primary key (client_id, period_from, period_to, cache_version),
  constraint portal_dashboard_cache_period_ck check (period_to >= period_from),
  constraint portal_dashboard_cache_expiry_ck check (expires_at > generated_at)
);

comment on table public.portal_dashboard_cache is
  'Service-only cache of complete client Overview/Materials/Carbon summaries. Raw collections remain authoritative.';

create index if not exists portal_dashboard_cache_expiry_idx
  on public.portal_dashboard_cache (expires_at);

alter table public.portal_dashboard_cache enable row level security;
revoke all on public.portal_dashboard_cache from public, anon, authenticated;
grant select, insert, update, delete on public.portal_dashboard_cache to service_role;

insert into supabase_migrations.schema_migrations(version, statements, name)
values ('20260920000500', null, 'portal_dashboard_cache')
on conflict (version) do nothing;

commit;
