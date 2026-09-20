-- The sync Edge Function uses the service role. New tables do not always
-- inherit explicit service_role table privileges in restored/legacy projects.
-- Keep browser roles blocked while allowing only the server to maintain the
-- compact change log.
grant select, insert, update, delete
on table public.app_state_changes
to service_role;
