-- Address actionable Supabase Security/Performance Advisor findings without
-- removing the authenticated booking RPCs required by the client portal.

-- These views previously ran with their owner's privileges. With invoker
-- security, callers are also subject to the permissions/RLS of base tables.
alter view if exists public.v_xero_invoice_lines set (security_invoker = true);
alter view if exists public.v_invoice_vs_collections set (security_invoker = true);
alter view if exists public.v_dump_fairness set (security_invoker = true);

-- The former FOR ALL staff policies overlapped the tenant SELECT policies,
-- causing two permissive SELECT policies to be evaluated for staff. Keep the
-- existing tenant SELECT policies and split staff writes by operation.
drop policy if exists portal_reporting_periods_staff_write on public.reporting_periods;
drop policy if exists portal_reporting_periods_staff_insert on public.reporting_periods;
drop policy if exists portal_reporting_periods_staff_update on public.reporting_periods;
create policy portal_reporting_periods_staff_insert
on public.reporting_periods for insert to authenticated
with check (private.portal_claims_valid() and private.portal_is_staff());
create policy portal_reporting_periods_staff_update
on public.reporting_periods for update to authenticated
using (private.portal_claims_valid() and private.portal_is_staff())
with check (private.portal_claims_valid() and private.portal_is_staff());

drop policy if exists portal_exceptions_staff_write on public.report_exceptions;
drop policy if exists portal_exceptions_staff_insert on public.report_exceptions;
drop policy if exists portal_exceptions_staff_update on public.report_exceptions;
create policy portal_exceptions_staff_insert
on public.report_exceptions for insert to authenticated
with check (private.portal_claims_valid() and private.portal_is_staff());
create policy portal_exceptions_staff_update
on public.report_exceptions for update to authenticated
using (private.portal_claims_valid() and private.portal_is_staff())
with check (private.portal_claims_valid() and private.portal_is_staff());

comment on function public.client_booking_context() is
  'SECURITY DEFINER by design. Requires a valid short-lived portal JWT and rejects staff accounts.';
comment on function public.check_client_booking_slot(text,date,time,time,text) is
  'SECURITY DEFINER by design. Validates the portal JWT and derives the client from signed claims.';
comment on function public.create_client_booking(text,text,date,time,time,text,text,integer) is
  'SECURITY DEFINER by design. Validates the portal JWT, derives tenant identity from signed claims, and writes an audit event.';
comment on function public.amend_client_booking(text,text,text,date,time,time,text,text,integer) is
  'SECURITY DEFINER by design. Validates the portal JWT, scopes the booking to the signed client, and writes an audit event.';
comment on function public.cancel_client_booking(text,text) is
  'SECURITY DEFINER by design. Validates the portal JWT, scopes the booking to the signed client, and writes an audit event.';
