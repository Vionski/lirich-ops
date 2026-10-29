begin;

-- Kevin Chia (Trader) replaces Marcus in everything: portal account, operator
-- console access and salesperson attribution (Michelle, 29 Oct 2026).
-- Kevin's WordPress login is `kevin`, user id 11 (created 29 Oct 2026).

-- 1. Portal account: copy Marcus's role, then retire Marcus.
insert into public.portal_accounts (
  email, display_name, client_id, status, requested_at, provisioned_at,
  notes, wp_user_id, role, revoked_at, updated_at, wp_login
)
select
  'kevin@lirichresources.sg', 'Kevin Chia', m.client_id, 'active', now(), now(),
  'Trader · replaces Marcus 2026-10-29', 11, m.role, null, now(), 'kevin'
from public.portal_accounts m
where lower(m.wp_login) = 'marcus'
  and not exists (select 1 from public.portal_accounts where lower(wp_login) = 'kevin');

update public.portal_accounts
set email = 'kevin@lirichresources.sg',
    display_name = 'Kevin Chia',
    wp_user_id = 11,
    status = 'active',
    revoked_at = null,
    updated_at = now()
where lower(wp_login) = 'kevin';

update public.portal_accounts
set status = 'revoked',
    revoked_at = coalesce(revoked_at, now()),
    updated_at = now(),
    notes = concat_ws(' · ', nullif(notes, ''), 'Replaced by Kevin Chia 2026-10-29')
where lower(wp_login) = 'marcus';

-- 2. Operator console: same per-tab permissions as Marcus, then deactivate Marcus.
insert into public.console_users (user_key, wp_login, active)
select 'kevin', 'kevin', true
where exists (select 1 from public.console_users where lower(wp_login) = 'marcus')
  and not exists (select 1 from public.console_users where lower(wp_login) = 'kevin');

update public.console_users set active = true where lower(wp_login) = 'kevin';

insert into public.console_permissions (user_key, tab, can_view, can_edit)
select k.user_key, p.tab, p.can_view, p.can_edit
from public.console_permissions p
join public.console_users m on m.user_key = p.user_key and lower(m.wp_login) = 'marcus'
cross join (select user_key from public.console_users where lower(wp_login) = 'kevin') k
where not exists (
  select 1 from public.console_permissions x where x.user_key = k.user_key and x.tab = p.tab
);

update public.console_users set active = false where lower(wp_login) = 'marcus';

-- 3. Salesperson attribution on the customer master.
update public.customers set sales_rep = 'Kevin' where lower(trim(sales_rep)) = 'marcus';

do $$
begin
  if not exists (
    select 1 from public.portal_accounts
    where lower(wp_login) = 'kevin' and status = 'active' and revoked_at is null
  ) then
    raise exception 'Kevin portal account was not provisioned (no Marcus account to copy?)';
  end if;
  if exists (select 1 from public.portal_accounts where lower(wp_login) = 'marcus' and status = 'active') then
    raise exception 'Marcus portal account is still active';
  end if;
  if exists (select 1 from public.console_users where lower(wp_login) = 'marcus' and active) then
    raise exception 'Marcus console access is still active';
  end if;
end;
$$;

insert into supabase_migrations.schema_migrations(version, statements, name)
values ('20261029000100', null, 'kevin_replaces_marcus')
on conflict (version) do nothing;

commit;

