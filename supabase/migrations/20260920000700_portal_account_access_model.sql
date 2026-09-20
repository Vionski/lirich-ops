begin;

-- Bind each portal identity to its immutable WordPress user id and keep
-- client selection for staff while reserving internal controls for the owner.
update public.portal_accounts as a
set wp_user_id = m.wp_user_id,
    role = m.role,
    client_id = null,
    status = 'active',
    revoked_at = null,
    updated_at = now(),
    notes = concat_ws(' · ', nullif(a.notes, ''), 'WordPress identity and portal role reconciled 2026-09-20')
from (values
  ('qris', 4::bigint, 'operator'),
  ('sheryl', 3::bigint, 'operator'),
  ('marcus', 5::bigint, 'operator'),
  ('patrick', 6::bigint, 'operator'),
  ('zion', 8::bigint, 'operator'),
  ('yan', 9::bigint, 'operator'),
  ('michelle', 7::bigint, 'operator'),
  ('mondayblossomdesigns', 1::bigint, 'admin')
) as m(wp_login, wp_user_id, role)
where lower(a.wp_login) = m.wp_login;

-- The current WordPress administrator signs in as mondayblossomdesigns.
-- Retire the old alias so there is exactly one active portal administrator.
update public.portal_accounts
set status = 'revoked',
    revoked_at = coalesce(revoked_at, now()),
    updated_at = now(),
    notes = concat_ws(' · ', nullif(notes, ''), 'Retired stale WordPress login alias 2026-09-20')
where lower(wp_login) = 'lirichgroup';

insert into public.portal_accounts (
  email, display_name, client_id, status, requested_at, provisioned_at,
  notes, wp_user_id, role, revoked_at, updated_at, wp_login
)
select
  'pil-beta-2026@client.invalid', 'PIL beta client', 'PIL', 'active', now(), now(),
  'Existing WordPress Lirich Client account linked for production acceptance testing',
  2, 'client', null, now(), 'pil-beta-2026'
where not exists (
  select 1 from public.portal_accounts where lower(wp_login) = 'pil-beta-2026'
);

update public.portal_accounts
set email = 'pil-beta-2026@client.invalid',
    display_name = 'PIL beta client',
    client_id = 'PIL',
    status = 'active',
    provisioned_at = coalesce(provisioned_at, now()),
    wp_user_id = 2,
    role = 'client',
    revoked_at = null,
    updated_at = now()
where lower(wp_login) = 'pil-beta-2026';

do $$
begin
  if (select count(*) from public.portal_accounts where status = 'active' and role = 'admin') <> 1 then
    raise exception 'portal access migration must leave exactly one active administrator';
  end if;
  if not exists (
    select 1 from public.portal_accounts
    where lower(wp_login) = 'pil-beta-2026'
      and wp_user_id = 2 and role = 'client' and client_id = 'PIL'
      and status = 'active' and revoked_at is null
  ) then
    raise exception 'PIL client portal account was not provisioned correctly';
  end if;
end;
$$;

insert into supabase_migrations.schema_migrations(version, statements, name)
values ('20260920000700', null, 'portal_account_access_model')
on conflict (version) do nothing;

commit;
