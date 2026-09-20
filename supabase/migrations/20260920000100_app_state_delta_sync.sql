-- Compact driver-app synchronisation.
-- The service-role Edge Function writes and reads this table. Browser clients
-- cannot access it directly; RLS deliberately has no anon/authenticated policy.

create table if not exists public.app_state_changes (
  rev bigint primary key,
  action text not null,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

alter table public.app_state_changes enable row level security;
revoke all on table public.app_state_changes from anon, authenticated;

create index if not exists app_state_changes_created_at_idx
  on public.app_state_changes (created_at);

comment on table public.app_state_changes is
  'Compact per-revision driver-app changes used to avoid downloading the complete app_state blob after every mutation.';
