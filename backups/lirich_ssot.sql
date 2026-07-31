--
-- PostgreSQL database dump
--

\restrict Ar07BeEGEIfFD2VhXEbIeIKIc2ecfAx7vKJ0ShCUu1oB6HMIaWukUk61bw5UH8o

-- Dumped from database version 17.6
-- Dumped by pg_dump version 17.10 (Ubuntu 17.10-1.pgdg24.04+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: auth; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA auth;


--
-- Name: pg_cron; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_cron WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION pg_cron; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_cron IS 'Job scheduler for PostgreSQL';


--
-- Name: extensions; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA extensions;


--
-- Name: graphql; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA graphql;


--
-- Name: graphql_public; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA graphql_public;


--
-- Name: pg_net; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA public;


--
-- Name: EXTENSION pg_net; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_net IS 'Async HTTP';


--
-- Name: pgbouncer; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA pgbouncer;


--
-- Name: realtime; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA realtime;


--
-- Name: storage; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA storage;


--
-- Name: vault; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA vault;


--
-- Name: pg_stat_statements; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_stat_statements WITH SCHEMA extensions;


--
-- Name: EXTENSION pg_stat_statements; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_stat_statements IS 'track planning and execution statistics of all SQL statements executed';


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: supabase_vault; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS supabase_vault WITH SCHEMA vault;


--
-- Name: EXTENSION supabase_vault; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION supabase_vault IS 'Supabase Vault Extension';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: aal_level; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.aal_level AS ENUM (
    'aal1',
    'aal2',
    'aal3'
);


--
-- Name: code_challenge_method; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.code_challenge_method AS ENUM (
    's256',
    'plain'
);


--
-- Name: factor_status; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.factor_status AS ENUM (
    'unverified',
    'verified'
);


--
-- Name: factor_type; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.factor_type AS ENUM (
    'totp',
    'webauthn',
    'phone'
);


--
-- Name: oauth_authorization_status; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.oauth_authorization_status AS ENUM (
    'pending',
    'approved',
    'denied',
    'expired'
);


--
-- Name: oauth_client_type; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.oauth_client_type AS ENUM (
    'public',
    'confidential'
);


--
-- Name: oauth_registration_type; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.oauth_registration_type AS ENUM (
    'dynamic',
    'manual'
);


--
-- Name: oauth_response_type; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.oauth_response_type AS ENUM (
    'code'
);


--
-- Name: one_time_token_type; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.one_time_token_type AS ENUM (
    'confirmation_token',
    'reauthentication_token',
    'recovery_token',
    'email_change_token_new',
    'email_change_token_current',
    'phone_change_token'
);


--
-- Name: action; Type: TYPE; Schema: realtime; Owner: -
--

CREATE TYPE realtime.action AS ENUM (
    'INSERT',
    'UPDATE',
    'DELETE',
    'TRUNCATE',
    'ERROR'
);


--
-- Name: equality_op; Type: TYPE; Schema: realtime; Owner: -
--

CREATE TYPE realtime.equality_op AS ENUM (
    'eq',
    'neq',
    'lt',
    'lte',
    'gt',
    'gte',
    'in',
    'like',
    'ilike',
    'is',
    'match',
    'imatch',
    'isdistinct'
);


--
-- Name: user_defined_filter; Type: TYPE; Schema: realtime; Owner: -
--

CREATE TYPE realtime.user_defined_filter AS (
	column_name text,
	op realtime.equality_op,
	value text,
	negate boolean
);


--
-- Name: wal_column; Type: TYPE; Schema: realtime; Owner: -
--

CREATE TYPE realtime.wal_column AS (
	name text,
	type_name text,
	type_oid oid,
	value jsonb,
	is_pkey boolean,
	is_selectable boolean
);


--
-- Name: wal_rls; Type: TYPE; Schema: realtime; Owner: -
--

CREATE TYPE realtime.wal_rls AS (
	wal jsonb,
	is_rls_enabled boolean,
	subscription_ids uuid[],
	errors text[]
);


--
-- Name: buckettype; Type: TYPE; Schema: storage; Owner: -
--

CREATE TYPE storage.buckettype AS ENUM (
    'STANDARD',
    'ANALYTICS',
    'VECTOR'
);


--
-- Name: email(); Type: FUNCTION; Schema: auth; Owner: -
--

CREATE FUNCTION auth.email() RETURNS text
    LANGUAGE sql STABLE
    AS $$
  select 
  coalesce(
    nullif(current_setting('request.jwt.claim.email', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'email')
  )::text
$$;


--
-- Name: FUNCTION email(); Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON FUNCTION auth.email() IS 'Deprecated. Use auth.jwt() -> ''email'' instead.';


--
-- Name: jwt(); Type: FUNCTION; Schema: auth; Owner: -
--

CREATE FUNCTION auth.jwt() RETURNS jsonb
    LANGUAGE sql STABLE
    AS $$
  select 
    coalesce(
        nullif(current_setting('request.jwt.claim', true), ''),
        nullif(current_setting('request.jwt.claims', true), '')
    )::jsonb
$$;


--
-- Name: role(); Type: FUNCTION; Schema: auth; Owner: -
--

CREATE FUNCTION auth.role() RETURNS text
    LANGUAGE sql STABLE
    AS $$
  select 
  coalesce(
    nullif(current_setting('request.jwt.claim.role', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role')
  )::text
$$;


--
-- Name: FUNCTION role(); Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON FUNCTION auth.role() IS 'Deprecated. Use auth.jwt() -> ''role'' instead.';


--
-- Name: uid(); Type: FUNCTION; Schema: auth; Owner: -
--

CREATE FUNCTION auth.uid() RETURNS uuid
    LANGUAGE sql STABLE
    AS $$
  select 
  coalesce(
    nullif(current_setting('request.jwt.claim.sub', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub')
  )::uuid
$$;


--
-- Name: FUNCTION uid(); Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON FUNCTION auth.uid() IS 'Deprecated. Use auth.jwt() -> ''sub'' instead.';


--
-- Name: grant_pg_cron_access(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.grant_pg_cron_access() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF EXISTS (
    SELECT
    FROM pg_event_trigger_ddl_commands() AS ev
    JOIN pg_extension AS ext
    ON ev.objid = ext.oid
    WHERE ext.extname = 'pg_cron'
  )
  THEN
    grant usage on schema cron to postgres with grant option;

    alter default privileges in schema cron grant all on tables to postgres with grant option;
    alter default privileges in schema cron grant all on functions to postgres with grant option;
    alter default privileges in schema cron grant all on sequences to postgres with grant option;

    alter default privileges for user supabase_admin in schema cron grant all
        on sequences to postgres with grant option;
    alter default privileges for user supabase_admin in schema cron grant all
        on tables to postgres with grant option;
    alter default privileges for user supabase_admin in schema cron grant all
        on functions to postgres with grant option;

    grant all privileges on all tables in schema cron to postgres with grant option;
    revoke all on table cron.job from postgres;
    grant select on table cron.job to postgres with grant option;
  END IF;
END;
$$;


--
-- Name: FUNCTION grant_pg_cron_access(); Type: COMMENT; Schema: extensions; Owner: -
--

COMMENT ON FUNCTION extensions.grant_pg_cron_access() IS 'Grants access to pg_cron';


--
-- Name: grant_pg_graphql_access(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.grant_pg_graphql_access() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $_$
begin
    if not exists (
        select 1
        from pg_event_trigger_ddl_commands() ev
        join pg_catalog.pg_extension e on ev.objid = e.oid
        where e.extname = 'pg_graphql'
    ) then
        return;
    end if;

    drop function if exists graphql_public.graphql;
    create or replace function graphql_public.graphql(
        "operationName" text default null,
        query text default null,
        variables jsonb default null,
        extensions jsonb default null
    )
        returns jsonb
        language sql
    as $$
        select graphql.resolve(
            query := query,
            variables := coalesce(variables, '{}'),
            "operationName" := "operationName",
            extensions := extensions
        );
    $$;

    -- Attach the wrapper to the extension so DROP EXTENSION cascades to it,
    -- which in turn triggers set_graphql_placeholder to reinstall the "not enabled" stub.
    alter extension pg_graphql add function graphql_public.graphql(text, text, jsonb, jsonb);

    grant usage on schema graphql to postgres, anon, authenticated, service_role;
    grant execute on function graphql.resolve to postgres, anon, authenticated, service_role;
    grant usage on schema graphql to postgres with grant option;
    grant usage on schema graphql_public to postgres with grant option;
end;
$_$;


--
-- Name: FUNCTION grant_pg_graphql_access(); Type: COMMENT; Schema: extensions; Owner: -
--

COMMENT ON FUNCTION extensions.grant_pg_graphql_access() IS 'Grants access to pg_graphql';


--
-- Name: grant_pg_net_access(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.grant_pg_net_access() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_event_trigger_ddl_commands() AS ev
    JOIN pg_extension AS ext
    ON ev.objid = ext.oid
    WHERE ext.extname = 'pg_net'
  )
  THEN
    IF NOT EXISTS (
      SELECT 1
      FROM pg_roles
      WHERE rolname = 'supabase_functions_admin'
    )
    THEN
      CREATE USER supabase_functions_admin NOINHERIT CREATEROLE LOGIN NOREPLICATION;
    END IF;

    GRANT USAGE ON SCHEMA net TO supabase_functions_admin, postgres, anon, authenticated, service_role;

    IF EXISTS (
      SELECT FROM pg_extension
      WHERE extname = 'pg_net'
      -- all versions in use on existing projects as of 2025-02-20
      -- version 0.12.0 onwards don't need these applied
      AND extversion IN ('0.2', '0.6', '0.7', '0.7.1', '0.8', '0.10.0', '0.11.0')
    ) THEN
      ALTER function net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) SECURITY DEFINER;
      ALTER function net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) SECURITY DEFINER;

      ALTER function net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) SET search_path = net;
      ALTER function net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) SET search_path = net;

      REVOKE ALL ON FUNCTION net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) FROM PUBLIC;
      REVOKE ALL ON FUNCTION net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) FROM PUBLIC;

      GRANT EXECUTE ON FUNCTION net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) TO supabase_functions_admin, postgres, anon, authenticated, service_role;
      GRANT EXECUTE ON FUNCTION net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) TO supabase_functions_admin, postgres, anon, authenticated, service_role;
    END IF;
  END IF;
END;
$$;


--
-- Name: FUNCTION grant_pg_net_access(); Type: COMMENT; Schema: extensions; Owner: -
--

COMMENT ON FUNCTION extensions.grant_pg_net_access() IS 'Grants access to pg_net';


--
-- Name: pgrst_ddl_watch(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.pgrst_ddl_watch() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN SELECT * FROM pg_event_trigger_ddl_commands()
  LOOP
    IF cmd.command_tag IN (
      'CREATE SCHEMA', 'ALTER SCHEMA'
    , 'CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO', 'ALTER TABLE'
    , 'CREATE FOREIGN TABLE', 'ALTER FOREIGN TABLE'
    , 'CREATE VIEW', 'ALTER VIEW'
    , 'CREATE MATERIALIZED VIEW', 'ALTER MATERIALIZED VIEW'
    , 'CREATE FUNCTION', 'ALTER FUNCTION'
    , 'CREATE TRIGGER'
    , 'CREATE TYPE', 'ALTER TYPE'
    , 'CREATE RULE'
    , 'COMMENT'
    )
    -- don't notify in case of CREATE TEMP table or other objects created on pg_temp
    AND cmd.schema_name is distinct from 'pg_temp'
    THEN
      NOTIFY pgrst, 'reload schema';
    END IF;
  END LOOP;
END; $$;


--
-- Name: pgrst_drop_watch(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.pgrst_drop_watch() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  obj record;
BEGIN
  FOR obj IN SELECT * FROM pg_event_trigger_dropped_objects()
  LOOP
    IF obj.object_type IN (
      'schema'
    , 'table'
    , 'foreign table'
    , 'view'
    , 'materialized view'
    , 'function'
    , 'trigger'
    , 'type'
    , 'rule'
    )
    AND obj.is_temporary IS false -- no pg_temp objects
    THEN
      NOTIFY pgrst, 'reload schema';
    END IF;
  END LOOP;
END; $$;


--
-- Name: set_graphql_placeholder(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.set_graphql_placeholder() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $_$
    DECLARE
    graphql_is_dropped bool;
    BEGIN
    graphql_is_dropped = (
        SELECT ev.schema_name = 'graphql_public'
        FROM pg_event_trigger_dropped_objects() AS ev
        WHERE ev.schema_name = 'graphql_public'
    );

    IF graphql_is_dropped
    THEN
        create or replace function graphql_public.graphql(
            "operationName" text default null,
            query text default null,
            variables jsonb default null,
            extensions jsonb default null
        )
            returns jsonb
            language plpgsql
        as $$
            DECLARE
                server_version float;
            BEGIN
                server_version = (SELECT (SPLIT_PART((select version()), ' ', 2))::float);

                IF server_version >= 14 THEN
                    RETURN jsonb_build_object(
                        'errors', jsonb_build_array(
                            jsonb_build_object(
                                'message', 'pg_graphql extension is not enabled.'
                            )
                        )
                    );
                ELSE
                    RETURN jsonb_build_object(
                        'errors', jsonb_build_array(
                            jsonb_build_object(
                                'message', 'pg_graphql is only available on projects running Postgres 14 onwards.'
                            )
                        )
                    );
                END IF;
            END;
        $$;
    END IF;

    END;
$_$;


--
-- Name: FUNCTION set_graphql_placeholder(); Type: COMMENT; Schema: extensions; Owner: -
--

COMMENT ON FUNCTION extensions.set_graphql_placeholder() IS 'Reintroduces placeholder function for graphql_public.graphql';


--
-- Name: graphql(text, text, jsonb, jsonb); Type: FUNCTION; Schema: graphql_public; Owner: -
--

CREATE FUNCTION graphql_public.graphql("operationName" text DEFAULT NULL::text, query text DEFAULT NULL::text, variables jsonb DEFAULT NULL::jsonb, extensions jsonb DEFAULT NULL::jsonb) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
            DECLARE
                server_version float;
            BEGIN
                server_version = (SELECT (SPLIT_PART((select version()), ' ', 2))::float);

                IF server_version >= 14 THEN
                    RETURN jsonb_build_object(
                        'errors', jsonb_build_array(
                            jsonb_build_object(
                                'message', 'pg_graphql extension is not enabled.'
                            )
                        )
                    );
                ELSE
                    RETURN jsonb_build_object(
                        'errors', jsonb_build_array(
                            jsonb_build_object(
                                'message', 'pg_graphql is only available on projects running Postgres 14 onwards.'
                            )
                        )
                    );
                END IF;
            END;
        $$;


--
-- Name: get_auth(text); Type: FUNCTION; Schema: pgbouncer; Owner: -
--

CREATE FUNCTION pgbouncer.get_auth(p_usename text) RETURNS TABLE(username text, password text)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $_$
  BEGIN
      RAISE DEBUG 'PgBouncer auth request: %', p_usename;

      RETURN QUERY
      SELECT
          rolname::text,
          CASE WHEN rolvaliduntil < now()
              THEN null
              ELSE rolpassword::text
          END
      FROM pg_authid
      WHERE rolname=$1 and rolcanlogin;
  END;
  $_$;


--
-- Name: apply_rls(jsonb, integer); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.apply_rls(wal jsonb, max_record_bytes integer DEFAULT (1024 * 1024)) RETURNS SETOF realtime.wal_rls
    LANGUAGE plpgsql
    AS $$
declare
    -- Regclass of the table e.g. public.notes
    entity_ regclass = (quote_ident(wal ->> 'schema') || '.' || quote_ident(wal ->> 'table'))::regclass;

    -- I, U, D, T: insert, update ...
    action realtime.action = (
        case wal ->> 'action'
            when 'I' then 'INSERT'
            when 'U' then 'UPDATE'
            when 'D' then 'DELETE'
            else 'ERROR'
        end
    );

    -- Is row level security enabled for the table
    is_rls_enabled bool = relrowsecurity from pg_class where oid = entity_;

    subscriptions realtime.subscription[] = array_agg(subs)
        from
            realtime.subscription subs
        where
            subs.entity = entity_
            -- Filter by action early - only get subscriptions interested in this action
            -- action_filter column can be: '*' (all), 'INSERT', 'UPDATE', or 'DELETE'
            and (subs.action_filter = '*' or subs.action_filter = action::text);

    -- Subscription vars
    working_role regrole;
    working_selected_columns text[];
    claimed_role regrole;
    claims jsonb;

    subscription_id uuid;
    subscription_has_access bool;
    visible_to_subscription_ids uuid[] = '{}';

    -- structured info for wal's columns
    columns realtime.wal_column[];
    -- previous identity values for update/delete
    old_columns realtime.wal_column[];

    error_record_exceeds_max_size boolean = octet_length(wal::text) > max_record_bytes;

    -- Primary jsonb output for record
    output jsonb;

    -- Loop record for iterating unique roles (outer loop)
    role_record record;
    -- Loop record for iterating unique selected_columns within a role (inner loop)
    cols_record record;
    -- Subscription ids visible at the role level (before fanning out by selected_columns)
    visible_role_sub_ids uuid[] = '{}';

begin
    perform set_config('role', null, true);

    columns =
        array_agg(
            (
                x->>'name',
                x->>'type',
                x->>'typeoid',
                realtime.cast(
                    (x->'value') #>> '{}',
                    coalesce(
                        (x->>'typeoid')::regtype, -- null when wal2json version <= 2.4
                        (x->>'type')::regtype
                    )
                ),
                (pks ->> 'name') is not null,
                true
            )::realtime.wal_column
        )
        from
            jsonb_array_elements(wal -> 'columns') x
            left join jsonb_array_elements(wal -> 'pk') pks
                on (x ->> 'name') = (pks ->> 'name');

    old_columns =
        array_agg(
            (
                x->>'name',
                x->>'type',
                x->>'typeoid',
                realtime.cast(
                    (x->'value') #>> '{}',
                    coalesce(
                        (x->>'typeoid')::regtype, -- null when wal2json version <= 2.4
                        (x->>'type')::regtype
                    )
                ),
                (pks ->> 'name') is not null,
                true
            )::realtime.wal_column
        )
        from
            jsonb_array_elements(wal -> 'identity') x
            left join jsonb_array_elements(wal -> 'pk') pks
                on (x ->> 'name') = (pks ->> 'name');

    for role_record in
        select claims_role
        from (select distinct claims_role from unnest(subscriptions)) t
        order by claims_role::text
    loop
        working_role := role_record.claims_role;

        -- Update `is_selectable` for columns and old_columns (once per role)
        columns =
            array_agg(
                (
                    c.name,
                    c.type_name,
                    c.type_oid,
                    c.value,
                    c.is_pkey,
                    pg_catalog.has_column_privilege(working_role, entity_, c.name, 'SELECT')
                )::realtime.wal_column
            )
            from
                unnest(columns) c;

        old_columns =
                array_agg(
                    (
                        c.name,
                        c.type_name,
                        c.type_oid,
                        c.value,
                        c.is_pkey,
                        pg_catalog.has_column_privilege(working_role, entity_, c.name, 'SELECT')
                    )::realtime.wal_column
                )
                from
                    unnest(old_columns) c;

        if action <> 'DELETE' and count(1) = 0 from unnest(columns) c where c.is_pkey then
            -- Fan out 400 error per distinct selected_columns for this role
            for cols_record in
                select selected_columns
                from (select distinct selected_columns from unnest(subscriptions) s where s.claims_role = working_role) t
                order by coalesce(array_to_string(selected_columns, ','), '')
            loop
                working_selected_columns := cols_record.selected_columns;
                return next (
                    jsonb_build_object(
                        'schema', wal ->> 'schema',
                        'table', wal ->> 'table',
                        'type', action
                    ),
                    is_rls_enabled,
                    (select array_agg(s.subscription_id) from unnest(subscriptions) as s where s.claims_role = working_role and (s.selected_columns is not distinct from working_selected_columns)),
                    array['Error 400: Bad Request, no primary key']
                )::realtime.wal_rls;
            end loop;

        -- The claims role does not have SELECT permission to the primary key of entity
        elsif action <> 'DELETE' and sum(c.is_selectable::int) <> count(1) from unnest(columns) c where c.is_pkey then
            -- Fan out 401 error per distinct selected_columns for this role
            for cols_record in
                select selected_columns
                from (select distinct selected_columns from unnest(subscriptions) s where s.claims_role = working_role) t
                order by coalesce(array_to_string(selected_columns, ','), '')
            loop
                working_selected_columns := cols_record.selected_columns;
                return next (
                    jsonb_build_object(
                        'schema', wal ->> 'schema',
                        'table', wal ->> 'table',
                        'type', action
                    ),
                    is_rls_enabled,
                    (select array_agg(s.subscription_id) from unnest(subscriptions) as s where s.claims_role = working_role and (s.selected_columns is not distinct from working_selected_columns)),
                    array['Error 401: Unauthorized']
                )::realtime.wal_rls;
            end loop;

        else
            -- Create the prepared statement (once per role)
            if is_rls_enabled and action <> 'DELETE' then
                if (select 1 from pg_prepared_statements where name = 'walrus_rls_stmt' limit 1) > 0 then
                    deallocate walrus_rls_stmt;
                end if;
                execute realtime.build_prepared_statement_sql('walrus_rls_stmt', entity_, columns);
            end if;

            -- Collect all visible subscription IDs for this role (filter check + RLS check)
            visible_role_sub_ids = '{}';

            for subscription_id, claims in (
                    select
                        subs.subscription_id,
                        subs.claims
                    from
                        unnest(subscriptions) subs
                    where
                        subs.entity = entity_
                        and subs.claims_role = working_role
                        and (
                            realtime.is_visible_through_filters(columns, subs.filters)
                            or (
                              action = 'DELETE'
                              and realtime.is_visible_through_filters(old_columns, subs.filters)
                            )
                        )
            ) loop

                if not is_rls_enabled or action = 'DELETE' then
                    visible_role_sub_ids = visible_role_sub_ids || subscription_id;
                else
                    -- Check if RLS allows the role to see the record
                    perform
                        -- Trim leading and trailing quotes from working_role because set_config
                        -- doesn't recognize the role as valid if they are included
                        set_config('role', trim(both '"' from working_role::text), true),
                        set_config('request.jwt.claims', claims::text, true);

                    execute 'execute walrus_rls_stmt' into subscription_has_access;

                    -- Reset the role on every FOR..LOOP batch execution.
                    -- The first batch of 10 rows is pre-fetched using the current connection role (PG internal behaviour)
                    -- then we have to reset it again otherwise it would use the role defined in the `set_config` above
                    -- to fetch the remaining rows when rows>10, which could be a user-defined role that lacks execution grants.
                    -- The flow is:
                    --   1. run batch with conn role
                    --   2. set_config working_role
                    --   3. execute walrus
                    --   4. reset role (revert)
                    --   5. repeat
                    perform set_config('role', null, true);

                    if subscription_has_access then
                        visible_role_sub_ids = visible_role_sub_ids || subscription_id;
                    end if;
                end if;
            end loop;

            perform set_config('role', null, true);

            -- Inner loop: per distinct selected_columns for this role
            for cols_record in
                select selected_columns
                from (select distinct selected_columns from unnest(subscriptions) s where s.claims_role = working_role) t
                order by coalesce(array_to_string(selected_columns, ','), '')
            loop
                working_selected_columns := cols_record.selected_columns;

                output = jsonb_build_object(
                    'schema', wal ->> 'schema',
                    'table', wal ->> 'table',
                    'type', action,
                    'commit_timestamp', to_char(
                        ((wal ->> 'timestamp')::timestamptz at time zone 'utc'),
                        'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'
                    ),
                    'columns', (
                        select
                            jsonb_agg(
                                jsonb_build_object(
                                    'name', pa.attname,
                                    'type', pt.typname
                                )
                                order by pa.attnum asc
                            )
                        from
                            pg_attribute pa
                            join pg_type pt
                                on pa.atttypid = pt.oid
                            left join (
                                select unnest(conkey) as pkey_attnum
                                from pg_constraint
                                where conrelid = entity_ and contype = 'p'
                            ) pk on pk.pkey_attnum = pa.attnum
                        where
                            attrelid = entity_
                            and attnum > 0
                            and pg_catalog.has_column_privilege(working_role, entity_, pa.attname, 'SELECT')
                            and (working_selected_columns is null or pa.attname = any(working_selected_columns) or pk.pkey_attnum is not null)
                    )
                )
                -- Add "record" key for insert and update
                || case
                    when action in ('INSERT', 'UPDATE') then
                        jsonb_build_object(
                            'record',
                            (
                                select
                                    jsonb_object_agg(
                                        -- if unchanged toast, get column name and value from old record
                                        coalesce((c).name, (oc).name),
                                        case
                                            when (c).name is null then (oc).value
                                            else (c).value
                                        end
                                    )
                                from
                                    unnest(columns) c
                                    full outer join unnest(old_columns) oc
                                        on (c).name = (oc).name
                                where
                                    coalesce((c).is_selectable, (oc).is_selectable)
                                    and (working_selected_columns is null or coalesce((c).name, (oc).name) = any(working_selected_columns) or coalesce((c).is_pkey, (oc).is_pkey))
                                    and ( not error_record_exceeds_max_size or (octet_length((c).value::text) <= 64))
                            )
                        )
                    else '{}'::jsonb
                end
                -- Add "old_record" key for update and delete
                || case
                    when action = 'UPDATE' then
                        jsonb_build_object(
                                'old_record',
                                (
                                    select jsonb_object_agg((c).name, (c).value)
                                    from unnest(old_columns) c
                                    where
                                        (c).is_selectable
                                        and (working_selected_columns is null or (c).name = any(working_selected_columns) or (c).is_pkey)
                                        and ( not error_record_exceeds_max_size or (octet_length((c).value::text) <= 64))
                                )
                            )
                    when action = 'DELETE' then
                        jsonb_build_object(
                            'old_record',
                            (
                                select jsonb_object_agg((c).name, (c).value)
                                from unnest(old_columns) c
                                where
                                    (c).is_selectable
                                    and (working_selected_columns is null or (c).name = any(working_selected_columns) or (c).is_pkey)
                                    and ( not error_record_exceeds_max_size or (octet_length((c).value::text) <= 64))
                                    and ( not is_rls_enabled or (c).is_pkey ) -- if RLS enabled, we can't secure deletes so filter to pkey
                            )
                        )
                    else '{}'::jsonb
                end;

                -- Filter visible_role_sub_ids to those matching the current selected_columns group
                visible_to_subscription_ids = coalesce(
                    (
                        select array_agg(s.subscription_id)
                        from unnest(subscriptions) s
                        where s.claims_role = working_role
                          and (s.selected_columns is not distinct from working_selected_columns)
                          and s.subscription_id = any(visible_role_sub_ids)
                    ),
                    '{}'::uuid[]
                );

                return next (
                    output,
                    is_rls_enabled,
                    visible_to_subscription_ids,
                    case
                        when error_record_exceeds_max_size then array['Error 413: Payload Too Large']
                        else '{}'
                    end
                )::realtime.wal_rls;
            end loop;

        end if;
    end loop;

    perform set_config('role', null, true);
end;
$$;


--
-- Name: broadcast_changes(text, text, text, text, text, record, record, text); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.broadcast_changes(topic_name text, event_name text, operation text, table_name text, table_schema text, new record, old record, level text DEFAULT 'ROW'::text) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    -- Declare a variable to hold the JSONB representation of the row
    row_data jsonb := '{}'::jsonb;
BEGIN
    IF level = 'STATEMENT' THEN
        RAISE EXCEPTION 'function can only be triggered for each row, not for each statement';
    END IF;
    -- Check the operation type and handle accordingly
    IF operation = 'INSERT' OR operation = 'UPDATE' OR operation = 'DELETE' THEN
        row_data := jsonb_build_object('old_record', OLD, 'record', NEW, 'operation', operation, 'table', table_name, 'schema', table_schema);
        PERFORM realtime.send (row_data, event_name, topic_name);
    ELSE
        RAISE EXCEPTION 'Unexpected operation type: %', operation;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Failed to process the row: %', SQLERRM;
END;

$$;


--
-- Name: build_prepared_statement_sql(text, regclass, realtime.wal_column[]); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.build_prepared_statement_sql(prepared_statement_name text, entity regclass, columns realtime.wal_column[]) RETURNS text
    LANGUAGE sql
    AS $$
      /*
      Builds a sql string that, if executed, creates a prepared statement to
      tests retrive a row from *entity* by its primary key columns.
      Example
          select realtime.build_prepared_statement_sql('public.notes', '{"id"}'::text[], '{"bigint"}'::text[])
      */
          select
      'prepare ' || prepared_statement_name || ' as
          select
              exists(
                  select
                      1
                  from
                      ' || entity || '
                  where
                      ' || string_agg(quote_ident(pkc.name) || '=' || quote_nullable(pkc.value #>> '{}') , ' and ') || '
              )'
          from
              unnest(columns) pkc
          where
              pkc.is_pkey
          group by
              entity
      $$;


--
-- Name: cast(text, regtype); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime."cast"(val text, type_ regtype) RETURNS jsonb
    LANGUAGE plpgsql IMMUTABLE
    AS $$
declare
  res jsonb;
begin
  if type_::text = 'bytea' then
    return to_jsonb(val);
  end if;
  execute format('select to_jsonb(%L::'|| type_::text || ')', val) into res;
  return res;
end
$$;


--
-- Name: check_equality_op(realtime.equality_op, regtype, text, text); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text) RETURNS boolean
    LANGUAGE plpgsql IMMUTABLE
    AS $$
/*
Casts *val_1* and *val_2* as type *type_* and check the *op* condition for truthiness
*/
declare
    op_symbol text = (
        case
            when op = 'eq' then '='
            when op = 'neq' then '!='
            when op = 'lt' then '<'
            when op = 'lte' then '<='
            when op = 'gt' then '>'
            when op = 'gte' then '>='
            when op = 'in' then '= any'
            else 'UNKNOWN OP'
        end
    );
    res boolean;
begin
    execute format(
        'select %L::'|| type_::text || ' ' || op_symbol
        || ' ( %L::'
        || (
            case
                when op = 'in' then type_::text || '[]'
                else type_::text end
        )
        || ')', val_1, val_2) into res;
    return res;
end;
$$;


--
-- Name: check_equality_op(realtime.equality_op, regtype, text, text, boolean); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text, negate boolean) RETURNS boolean
    LANGUAGE plpgsql STABLE
    AS $$
declare
    op_symbol text;
    res boolean;
begin
    -- IS DISTINCT FROM / IS NOT DISTINCT FROM: infix, both sides typed literals
    if op = 'isdistinct' then
        execute format(
            'select %L::%s %s %L::%s',
            val_1,
            type_::text,
            case when negate then 'IS NOT DISTINCT FROM' else 'IS DISTINCT FROM' end,
            val_2,
            type_::text
        ) into res;
        return res;
    end if;

    -- IS requires a keyword RHS (NULL, TRUE, FALSE, UNKNOWN), not a typed literal
    if op = 'is' then
        if val_2 not in ('null', 'true', 'false', 'unknown') then
            raise exception 'invalid value for is filter: must be null, true, false, or unknown';
        end if;
        execute format(
            'select %L::%s %s %s',
            val_1,
            type_::text,
            case when negate then 'IS NOT' else 'IS' end,
            upper(val_2)
        ) into res;
        return res;
    end if;

    op_symbol = case
        when op = 'eq'    then '='
        when op = 'neq'   then '!='
        when op = 'lt'    then '<'
        when op = 'lte'   then '<='
        when op = 'gt'    then '>'
        when op = 'gte'   then '>='
        when op = 'in'    then '= any'
        when op = 'like'   then 'LIKE'
        when op = 'ilike'  then 'ILIKE'
        when op = 'match'  then '~'
        when op = 'imatch' then '~*'
        else null
    end;

    if op_symbol is null then
        raise exception 'unsupported equality operator: %', op::text;
    end if;

    execute format(
        'select %L::%s %s (%L::%s)',
        val_1,
        type_::text,
        op_symbol,
        val_2,
        case when op = 'in' then type_::text || '[]' else type_::text end
    ) into res;

    return case when negate then not res else res end;
end;
$$;


--
-- Name: is_visible_through_filters(realtime.wal_column[], realtime.user_defined_filter[]); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.is_visible_through_filters(columns realtime.wal_column[], filters realtime.user_defined_filter[]) RETURNS boolean
    LANGUAGE sql STABLE
    AS $$
    select
        filters is null
        or array_length(filters, 1) is null
        or coalesce(
            count(col.name) = count(1)
            and sum(
                realtime.check_equality_op(
                    op:=f.op,
                    type_:=coalesce(col.type_oid::regtype, col.type_name::regtype),
                    val_1:=col.value #>> '{}',
                    val_2:=f.value,
                    negate:=coalesce(f.negate, false)
                )::int
            ) filter (where col.name is not null) = count(col.name),
            false
        )
    from
        unnest(filters) f
        left join unnest(columns) col
            on f.column_name = col.name;
$$;


--
-- Name: list_changes(name, name, integer, integer); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.list_changes(publication name, slot_name name, max_changes integer, max_record_bytes integer) RETURNS TABLE(wal jsonb, is_rls_enabled boolean, subscription_ids uuid[], errors text[], slot_changes_count bigint)
    LANGUAGE sql
    SET log_min_messages TO 'fatal'
    AS $$
  WITH pub AS (
    SELECT
      concat_ws(
        ',',
        CASE WHEN bool_or(pubinsert) THEN 'insert' ELSE NULL END,
        CASE WHEN bool_or(pubupdate) THEN 'update' ELSE NULL END,
        CASE WHEN bool_or(pubdelete) THEN 'delete' ELSE NULL END
      ) AS w2j_actions,
      coalesce(
        string_agg(
          realtime.quote_wal2json(format('%I.%I', schemaname, tablename)::regclass),
          ','
        ) filter (WHERE ppt.tablename IS NOT NULL),
        ''
      ) AS w2j_add_tables
    FROM pg_publication pp
    LEFT JOIN pg_publication_tables ppt ON pp.pubname = ppt.pubname
    WHERE pp.pubname = publication
    GROUP BY pp.pubname
    LIMIT 1
  ),
  -- MATERIALIZED ensures pg_logical_slot_get_changes is called exactly once
  w2j AS MATERIALIZED (
    SELECT x.*, pub.w2j_add_tables
    FROM pub,
         pg_logical_slot_get_changes(
           slot_name, null, max_changes,
           'include-pk', 'true',
           'include-transaction', 'false',
           'include-timestamp', 'true',
           'include-type-oids', 'true',
           'format-version', '2',
           'actions', pub.w2j_actions,
           'add-tables', pub.w2j_add_tables
         ) x
  ),
  slot_count AS (
    SELECT count(*)::bigint AS cnt
    FROM w2j
    WHERE w2j.w2j_add_tables <> ''
  ),
  rls_filtered AS (
    SELECT xyz.wal, xyz.is_rls_enabled, xyz.subscription_ids, xyz.errors
    FROM w2j,
         realtime.apply_rls(
           wal := w2j.data::jsonb,
           max_record_bytes := max_record_bytes
         ) xyz(wal, is_rls_enabled, subscription_ids, errors)
    WHERE w2j.w2j_add_tables <> ''
      AND xyz.subscription_ids[1] IS NOT NULL
  )
  SELECT rf.wal, rf.is_rls_enabled, rf.subscription_ids, rf.errors, sc.cnt
  FROM rls_filtered rf, slot_count sc

  UNION ALL

  SELECT null, null, null, null, sc.cnt
  FROM slot_count sc
  WHERE NOT EXISTS (SELECT 1 FROM rls_filtered)
$$;


--
-- Name: quote_wal2json(regclass); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.quote_wal2json(entity regclass) RETURNS text
    LANGUAGE sql IMMUTABLE STRICT
    AS $$
  SELECT
    realtime.wal2json_escape_identifier(nsp.nspname::text)
    || '.'
    || realtime.wal2json_escape_identifier(pc.relname::text)
  FROM pg_class pc
  JOIN pg_namespace nsp ON pc.relnamespace = nsp.oid
  WHERE pc.oid = entity
$$;


--
-- Name: send(jsonb, text, text, boolean); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.send(payload jsonb, event text, topic text, private boolean DEFAULT true) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  generated_id uuid;
  final_payload jsonb;
BEGIN
  BEGIN
    generated_id := gen_random_uuid();

    -- Check if payload has an 'id' key, if not, add the generated UUID
    IF payload ? 'id' THEN
      final_payload := payload;
    ELSE
      final_payload := jsonb_set(payload, '{id}', to_jsonb(generated_id));
    END IF;

    -- Set the topic configuration
    EXECUTE format('SET LOCAL realtime.topic TO %L', topic);

    INSERT INTO realtime.messages (id, payload, event, topic, private, extension)
    VALUES (generated_id, final_payload, event, topic, private, 'broadcast');
  EXCEPTION
    WHEN OTHERS THEN
      RAISE WARNING 'WarnSendingBroadcastMessage: %', SQLERRM;
  END;
END;
$$;


--
-- Name: send_binary(bytea, text, text, boolean); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.send_binary(payload bytea, event text, topic text, private boolean DEFAULT true) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  generated_id uuid;
BEGIN
  BEGIN
    generated_id := gen_random_uuid();

    EXECUTE format('SET LOCAL realtime.topic TO %L', topic);

    INSERT INTO realtime.messages (id, binary_payload, event, topic, private, extension)
    VALUES (generated_id, payload, event, topic, private, 'broadcast');
  EXCEPTION
    WHEN OTHERS THEN
      RAISE WARNING 'WarnSendingBroadcastMessage: %', SQLERRM;
  END;
END;
$$;


--
-- Name: subscription_check_filters(); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.subscription_check_filters() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare
    col_names text[] = coalesce(
            array_agg(a.attname order by a.attnum),
            '{}'::text[]
        )
        from
            pg_catalog.pg_attribute a
        where
            a.attrelid = new.entity
            and a.attnum > 0
            and not a.attisdropped
            and pg_catalog.has_column_privilege(
                (new.claims ->> 'role'),
                a.attrelid,
                a.attnum,
                'SELECT'
            );
    filter realtime.user_defined_filter;
    col_type regtype;
    in_val jsonb;
    selected_col text;
begin
    for filter in select * from unnest(new.filters) loop
        if not filter.column_name = any(col_names) then
            raise exception 'invalid column for filter %', filter.column_name;
        end if;

        col_type = (
            select atttypid::regtype
            from pg_catalog.pg_attribute
            where attrelid = new.entity
                  and attname = filter.column_name
        );
        if col_type is null then
            raise exception 'failed to lookup type for column %', filter.column_name;
        end if;

        if filter.op = 'in'::realtime.equality_op then
            in_val = realtime.cast(filter.value, (col_type::text || '[]')::regtype);
            if coalesce(jsonb_array_length(in_val), 0) > 100 then
                raise exception 'too many values for `in` filter. Maximum 100';
            end if;
        elsif filter.op = 'is'::realtime.equality_op then
            -- `is` requires a keyword RHS rather than a typed literal
            if filter.value not in ('null', 'true', 'false', 'unknown') then
                raise exception 'invalid value for is filter: must be null, true, false, or unknown';
            end if;
            -- IS NULL works for any type, but IS TRUE/FALSE/UNKNOWN require a boolean
            -- operand. Reject the non-null keywords on non-boolean columns here so they
            -- don't abort apply_rls at WAL time.
            if filter.value <> 'null' and col_type <> 'boolean'::regtype then
                raise exception 'is % filter requires a boolean column, got %', filter.value, col_type::text;
            end if;
        elsif filter.op in ('like'::realtime.equality_op, 'ilike'::realtime.equality_op) then
            -- like/ilike apply the text pattern operator (~~); reject column types that
            -- have no such operator instead of failing at WAL time
            if not exists (
                select 1 from pg_catalog.pg_operator
                where oprname = '~~' and oprleft = col_type
            ) then
                raise exception 'operator % requires a text-compatible column type, got %', filter.op::text, col_type::text;
            end if;
        elsif filter.op in ('match'::realtime.equality_op, 'imatch'::realtime.equality_op) then
            -- match/imatch apply the regex operators ~ / ~*; reject column types that have
            -- no such operator (e.g. integer) instead of failing at WAL time, mirroring the
            -- like/ilike guard above.
            if not exists (
                select 1 from pg_catalog.pg_operator
                where oprname = case when filter.op = 'imatch'::realtime.equality_op then '~*' else '~' end
                  and oprleft = col_type
                  and oprright = col_type
                  and oprresult = 'boolean'::regtype
            ) then
                raise exception 'operator % requires a text-compatible column type, got %', filter.op::text, col_type::text;
            end if;
            -- validate the regex eagerly so a bad pattern is rejected here, not inside
            -- apply_rls where it would abort the WAL stream for the entity
            begin
                perform '' ~ filter.value;
            exception when others then
                raise exception 'invalid regular expression for % filter: %', filter.op::text, sqlerrm;
            end;
        else
            -- eq/neq/lt/lte/gt/gte: value must be coercable to the type
            perform realtime.cast(filter.value, col_type);
        end if;
    end loop;

    if new.selected_columns is not null then
        for selected_col in select * from unnest(new.selected_columns) loop
            if not selected_col = any(col_names) then
                raise exception 'invalid column for select %', selected_col;
            end if;
        end loop;
    end if;

    -- Apply consistent order to filters so the unique constraint can't be tricked by a
    -- different filter order. negate is part of the sort key.
    new.filters = coalesce(
        array_agg(f order by f.column_name, f.op, f.value, f.negate),
        '{}'
    ) from unnest(new.filters) f;

    new.selected_columns = (
        select array_agg(c order by c)
        from unnest(new.selected_columns) c
    );

    return new;
end;
$$;


--
-- Name: to_regrole(text); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.to_regrole(role_name text) RETURNS regrole
    LANGUAGE sql IMMUTABLE
    AS $$ select role_name::regrole $$;


--
-- Name: topic(); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.topic() RETURNS text
    LANGUAGE sql STABLE
    AS $$
select nullif(current_setting('realtime.topic', true), '')::text;
$$;


--
-- Name: wal2json_escape_identifier(text); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.wal2json_escape_identifier(name text) RETURNS text
    LANGUAGE sql IMMUTABLE STRICT
    AS $$
  -- Prefix `\`, `,`, `.`, and any whitespace with `\`
  SELECT regexp_replace(name, '([\\,.[:space:]])', '\\\1', 'g')
$$;


--
-- Name: allow_any_operation(text[]); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.allow_any_operation(expected_operations text[]) RETURNS boolean
    LANGUAGE sql STABLE
    AS $$
  WITH current_operation AS (
    SELECT storage.operation() AS raw_operation
  ),
  normalized AS (
    SELECT CASE
      WHEN raw_operation LIKE 'storage.%' THEN substr(raw_operation, 9)
      ELSE raw_operation
    END AS current_operation
    FROM current_operation
  )
  SELECT EXISTS (
    SELECT 1
    FROM normalized n
    CROSS JOIN LATERAL unnest(expected_operations) AS expected_operation
    WHERE expected_operation IS NOT NULL
      AND expected_operation <> ''
      AND n.current_operation = CASE
        WHEN expected_operation LIKE 'storage.%' THEN substr(expected_operation, 9)
        ELSE expected_operation
      END
  );
$$;


--
-- Name: allow_only_operation(text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.allow_only_operation(expected_operation text) RETURNS boolean
    LANGUAGE sql STABLE
    AS $$
  WITH current_operation AS (
    SELECT storage.operation() AS raw_operation
  ),
  normalized AS (
    SELECT
      CASE
        WHEN raw_operation LIKE 'storage.%' THEN substr(raw_operation, 9)
        ELSE raw_operation
      END AS current_operation,
      CASE
        WHEN expected_operation LIKE 'storage.%' THEN substr(expected_operation, 9)
        ELSE expected_operation
      END AS requested_operation
    FROM current_operation
  )
  SELECT CASE
    WHEN requested_operation IS NULL OR requested_operation = '' THEN FALSE
    ELSE COALESCE(current_operation = requested_operation, FALSE)
  END
  FROM normalized;
$$;


--
-- Name: can_insert_object(text, text, uuid, jsonb); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.can_insert_object(bucketid text, name text, owner uuid, metadata jsonb) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO "storage"."objects" ("bucket_id", "name", "owner", "metadata") VALUES (bucketid, name, owner, metadata);
  -- hack to rollback the successful insert
  RAISE sqlstate 'PT200' using
  message = 'ROLLBACK',
  detail = 'rollback successful insert';
END
$$;


--
-- Name: enforce_bucket_name_length(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.enforce_bucket_name_length() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
    if length(new.name) > 100 then
        raise exception 'bucket name "%" is too long (% characters). Max is 100.', new.name, length(new.name);
    end if;
    return new;
end;
$$;


--
-- Name: extension(text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.extension(name text) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $$
DECLARE
    _parts text[];
    _filename text;
BEGIN
    -- Split on "/" to get path segments
    SELECT string_to_array(name, '/') INTO _parts;
    -- Get the last path segment (the actual filename)
    SELECT _parts[array_length(_parts, 1)] INTO _filename;
    -- Extract extension: reverse, split on '.', then reverse again
    RETURN reverse(split_part(reverse(_filename), '.', 1));
END
$$;


--
-- Name: filename(text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.filename(name text) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
_parts text[];
BEGIN
	select string_to_array(name, '/') into _parts;
	return _parts[array_length(_parts,1)];
END
$$;


--
-- Name: foldername(text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.foldername(name text) RETURNS text[]
    LANGUAGE plpgsql IMMUTABLE
    AS $$
DECLARE
    _parts text[];
BEGIN
    -- Split on "/" to get path segments
    SELECT string_to_array(name, '/') INTO _parts;
    -- Return everything except the last segment
    RETURN _parts[1 : array_length(_parts,1) - 1];
END
$$;


--
-- Name: get_common_prefix(text, text, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.get_common_prefix(p_key text, p_prefix text, p_delimiter text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
SELECT CASE
    WHEN position(p_delimiter IN substring(p_key FROM length(p_prefix) + 1)) > 0
    THEN left(p_key, length(p_prefix) + position(p_delimiter IN substring(p_key FROM length(p_prefix) + 1)))
    ELSE NULL
END;
$$;


--
-- Name: get_size_by_bucket(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.get_size_by_bucket() RETURNS TABLE(size bigint, bucket_id text)
    LANGUAGE plpgsql STABLE
    AS $$
BEGIN
    return query
        select sum((metadata->>'size')::bigint)::bigint as size, obj.bucket_id
        from "storage".objects as obj
        group by obj.bucket_id;
END
$$;


--
-- Name: list_multipart_uploads_with_delimiter(text, text, text, integer, text, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.list_multipart_uploads_with_delimiter(bucket_id text, prefix_param text, delimiter_param text, max_keys integer DEFAULT 100, next_key_token text DEFAULT ''::text, next_upload_token text DEFAULT ''::text) RETURNS TABLE(key text, id text, created_at timestamp with time zone)
    LANGUAGE plpgsql
    AS $_$
BEGIN
    RETURN QUERY EXECUTE
        'SELECT DISTINCT ON(key COLLATE "C") * from (
            SELECT
                CASE
                    WHEN position($2 IN substring(key from length($1) + 1)) > 0 THEN
                        substring(key from 1 for length($1) + position($2 IN substring(key from length($1) + 1)))
                    ELSE
                        key
                END AS key, id, created_at
            FROM
                storage.s3_multipart_uploads
            WHERE
                bucket_id = $5 AND
                key ILIKE $1 || ''%'' AND
                CASE
                    WHEN $4 != '''' AND $6 = '''' THEN
                        CASE
                            WHEN position($2 IN substring(key from length($1) + 1)) > 0 THEN
                                substring(key from 1 for length($1) + position($2 IN substring(key from length($1) + 1))) COLLATE "C" > $4
                            ELSE
                                key COLLATE "C" > $4
                            END
                    ELSE
                        true
                END AND
                CASE
                    WHEN $6 != '''' THEN
                        id COLLATE "C" > $6
                    ELSE
                        true
                    END
            ORDER BY
                key COLLATE "C" ASC, created_at ASC) as e order by key COLLATE "C" LIMIT $3'
        USING prefix_param, delimiter_param, max_keys, next_key_token, bucket_id, next_upload_token;
END;
$_$;


--
-- Name: list_objects_with_delimiter(text, text, text, integer, text, text, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.list_objects_with_delimiter(_bucket_id text, prefix_param text, delimiter_param text, max_keys integer DEFAULT 100, start_after text DEFAULT ''::text, next_token text DEFAULT ''::text, sort_order text DEFAULT 'asc'::text) RETURNS TABLE(name text, id uuid, metadata jsonb, updated_at timestamp with time zone, created_at timestamp with time zone, last_accessed_at timestamp with time zone)
    LANGUAGE plpgsql STABLE
    AS $_$
DECLARE
    v_peek_name TEXT;
    v_current RECORD;
    v_common_prefix TEXT;

    -- Configuration
    v_is_asc BOOLEAN;
    v_prefix TEXT;
    v_start TEXT;
    v_upper_bound TEXT;
    v_file_batch_size INT;

    -- Seek state
    v_next_seek TEXT;
    v_count INT := 0;

    -- Dynamic SQL for batch query only
    v_batch_query TEXT;

BEGIN
    -- ========================================================================
    -- INITIALIZATION
    -- ========================================================================
    v_is_asc := lower(coalesce(sort_order, 'asc')) = 'asc';
    v_prefix := coalesce(prefix_param, '');
    v_start := CASE WHEN coalesce(next_token, '') <> '' THEN next_token ELSE coalesce(start_after, '') END;
    v_file_batch_size := LEAST(GREATEST(max_keys * 2, 100), 1000);

    -- Calculate upper bound for prefix filtering (bytewise, using COLLATE "C")
    IF v_prefix = '' THEN
        v_upper_bound := NULL;
    ELSIF right(v_prefix, 1) = delimiter_param THEN
        v_upper_bound := left(v_prefix, -1) || chr(ascii(delimiter_param) + 1);
    ELSE
        v_upper_bound := left(v_prefix, -1) || chr(ascii(right(v_prefix, 1)) + 1);
    END IF;

    -- Build batch query (dynamic SQL - called infrequently, amortized over many rows)
    IF v_is_asc THEN
        IF v_upper_bound IS NOT NULL THEN
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND o.name COLLATE "C" >= $2 ' ||
                'AND o.name COLLATE "C" < $3 ORDER BY o.name COLLATE "C" ASC LIMIT $4';
        ELSE
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND o.name COLLATE "C" >= $2 ' ||
                'ORDER BY o.name COLLATE "C" ASC LIMIT $4';
        END IF;
    ELSE
        IF v_upper_bound IS NOT NULL THEN
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND o.name COLLATE "C" < $2 ' ||
                'AND o.name COLLATE "C" >= $3 ORDER BY o.name COLLATE "C" DESC LIMIT $4';
        ELSE
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND o.name COLLATE "C" < $2 ' ||
                'ORDER BY o.name COLLATE "C" DESC LIMIT $4';
        END IF;
    END IF;

    -- ========================================================================
    -- SEEK INITIALIZATION: Determine starting position
    -- ========================================================================
    IF v_start = '' THEN
        IF v_is_asc THEN
            v_next_seek := v_prefix;
        ELSE
            -- DESC without cursor: find the last item in range
            IF v_upper_bound IS NOT NULL THEN
                SELECT o.name INTO v_next_seek FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" >= v_prefix AND o.name COLLATE "C" < v_upper_bound
                ORDER BY o.name COLLATE "C" DESC LIMIT 1;
            ELSIF v_prefix <> '' THEN
                SELECT o.name INTO v_next_seek FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" >= v_prefix
                ORDER BY o.name COLLATE "C" DESC LIMIT 1;
            ELSE
                SELECT o.name INTO v_next_seek FROM storage.objects o
                WHERE o.bucket_id = _bucket_id
                ORDER BY o.name COLLATE "C" DESC LIMIT 1;
            END IF;

            IF v_next_seek IS NOT NULL THEN
                v_next_seek := v_next_seek || delimiter_param;
            ELSE
                RETURN;
            END IF;
        END IF;
    ELSE
        -- Cursor provided: determine if it refers to a folder or leaf
        IF EXISTS (
            SELECT 1 FROM storage.objects o
            WHERE o.bucket_id = _bucket_id
              AND o.name COLLATE "C" LIKE v_start || delimiter_param || '%'
            LIMIT 1
        ) THEN
            -- Cursor refers to a folder
            IF v_is_asc THEN
                v_next_seek := v_start || chr(ascii(delimiter_param) + 1);
            ELSE
                v_next_seek := v_start || delimiter_param;
            END IF;
        ELSE
            -- Cursor refers to a leaf object
            IF v_is_asc THEN
                v_next_seek := v_start || delimiter_param;
            ELSE
                v_next_seek := v_start;
            END IF;
        END IF;
    END IF;

    -- ========================================================================
    -- MAIN LOOP: Hybrid peek-then-batch algorithm
    -- Uses STATIC SQL for peek (hot path) and DYNAMIC SQL for batch
    -- ========================================================================
    LOOP
        EXIT WHEN v_count >= max_keys;

        -- STEP 1: PEEK using STATIC SQL (plan cached, very fast)
        IF v_is_asc THEN
            IF v_upper_bound IS NOT NULL THEN
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" >= v_next_seek AND o.name COLLATE "C" < v_upper_bound
                ORDER BY o.name COLLATE "C" ASC LIMIT 1;
            ELSE
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" >= v_next_seek
                ORDER BY o.name COLLATE "C" ASC LIMIT 1;
            END IF;
        ELSE
            IF v_upper_bound IS NOT NULL THEN
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" < v_next_seek AND o.name COLLATE "C" >= v_prefix
                ORDER BY o.name COLLATE "C" DESC LIMIT 1;
            ELSIF v_prefix <> '' THEN
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" < v_next_seek AND o.name COLLATE "C" >= v_prefix
                ORDER BY o.name COLLATE "C" DESC LIMIT 1;
            ELSE
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" < v_next_seek
                ORDER BY o.name COLLATE "C" DESC LIMIT 1;
            END IF;
        END IF;

        EXIT WHEN v_peek_name IS NULL;

        -- STEP 2: Check if this is a FOLDER or FILE
        v_common_prefix := storage.get_common_prefix(v_peek_name, v_prefix, delimiter_param);

        IF v_common_prefix IS NOT NULL THEN
            -- FOLDER: Emit and skip to next folder (no heap access needed)
            name := rtrim(v_common_prefix, delimiter_param);
            id := NULL;
            updated_at := NULL;
            created_at := NULL;
            last_accessed_at := NULL;
            metadata := NULL;
            RETURN NEXT;
            v_count := v_count + 1;

            -- Advance seek past the folder range
            IF v_is_asc THEN
                v_next_seek := left(v_common_prefix, -1) || chr(ascii(delimiter_param) + 1);
            ELSE
                v_next_seek := v_common_prefix;
            END IF;
        ELSE
            -- FILE: Batch fetch using DYNAMIC SQL (overhead amortized over many rows)
            -- For ASC: upper_bound is the exclusive upper limit (< condition)
            -- For DESC: prefix is the inclusive lower limit (>= condition)
            FOR v_current IN EXECUTE v_batch_query USING _bucket_id, v_next_seek,
                CASE WHEN v_is_asc THEN COALESCE(v_upper_bound, v_prefix) ELSE v_prefix END, v_file_batch_size
            LOOP
                v_common_prefix := storage.get_common_prefix(v_current.name, v_prefix, delimiter_param);

                IF v_common_prefix IS NOT NULL THEN
                    -- Hit a folder: exit batch, let peek handle it
                    v_next_seek := v_current.name;
                    EXIT;
                END IF;

                -- Emit file
                name := v_current.name;
                id := v_current.id;
                updated_at := v_current.updated_at;
                created_at := v_current.created_at;
                last_accessed_at := v_current.last_accessed_at;
                metadata := v_current.metadata;
                RETURN NEXT;
                v_count := v_count + 1;

                -- Advance seek past this file
                IF v_is_asc THEN
                    v_next_seek := v_current.name || delimiter_param;
                ELSE
                    v_next_seek := v_current.name;
                END IF;

                EXIT WHEN v_count >= max_keys;
            END LOOP;
        END IF;
    END LOOP;
END;
$_$;


--
-- Name: operation(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.operation() RETURNS text
    LANGUAGE plpgsql STABLE
    AS $$
BEGIN
    RETURN current_setting('storage.operation', true);
END;
$$;


--
-- Name: protect_delete(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.protect_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Check if storage.allow_delete_query is set to 'true'
    IF COALESCE(current_setting('storage.allow_delete_query', true), 'false') != 'true' THEN
        RAISE EXCEPTION 'Direct deletion from storage tables is not allowed. Use the Storage API instead.'
            USING HINT = 'This prevents accidental data loss from orphaned objects.',
                  ERRCODE = '42501';
    END IF;
    RETURN NULL;
END;
$$;


--
-- Name: search(text, text, integer, integer, integer, text, text, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.search(prefix text, bucketname text, limits integer DEFAULT 100, levels integer DEFAULT 1, offsets integer DEFAULT 0, search text DEFAULT ''::text, sortcolumn text DEFAULT 'name'::text, sortorder text DEFAULT 'asc'::text) RETURNS TABLE(name text, id uuid, updated_at timestamp with time zone, created_at timestamp with time zone, last_accessed_at timestamp with time zone, metadata jsonb)
    LANGUAGE plpgsql STABLE
    AS $_$
DECLARE
    v_peek_name TEXT;
    v_current RECORD;
    v_common_prefix TEXT;
    v_delimiter CONSTANT TEXT := '/';

    -- Configuration
    v_limit INT;
    v_prefix TEXT;
    v_prefix_lower TEXT;
    v_is_asc BOOLEAN;
    v_order_by TEXT;
    v_sort_order TEXT;
    v_upper_bound TEXT;
    v_file_batch_size INT;

    -- Dynamic SQL for batch query only
    v_batch_query TEXT;

    -- Seek state
    v_next_seek TEXT;
    v_count INT := 0;
    v_skipped INT := 0;
BEGIN
    -- ========================================================================
    -- INITIALIZATION
    -- ========================================================================
    v_limit := LEAST(coalesce(limits, 100), 1500);
    v_prefix := coalesce(prefix, '') || coalesce(search, '');
    v_prefix_lower := lower(v_prefix);
    v_is_asc := lower(coalesce(sortorder, 'asc')) = 'asc';
    v_file_batch_size := LEAST(GREATEST(v_limit * 2, 100), 1000);

    -- Validate sort column
    CASE lower(coalesce(sortcolumn, 'name'))
        WHEN 'name' THEN v_order_by := 'name';
        WHEN 'updated_at' THEN v_order_by := 'updated_at';
        WHEN 'created_at' THEN v_order_by := 'created_at';
        WHEN 'last_accessed_at' THEN v_order_by := 'last_accessed_at';
        ELSE v_order_by := 'name';
    END CASE;

    v_sort_order := CASE WHEN v_is_asc THEN 'asc' ELSE 'desc' END;

    -- ========================================================================
    -- NON-NAME SORTING: Use path_tokens approach (unchanged)
    -- ========================================================================
    IF v_order_by != 'name' THEN
        RETURN QUERY EXECUTE format(
            $sql$
            WITH folders AS (
                SELECT path_tokens[$1] AS folder
                FROM storage.objects
                WHERE objects.name ILIKE $2 || '%%'
                  AND bucket_id = $3
                  AND array_length(objects.path_tokens, 1) <> $1
                GROUP BY folder
                ORDER BY folder %s
            )
            (SELECT folder AS "name",
                   NULL::uuid AS id,
                   NULL::timestamptz AS updated_at,
                   NULL::timestamptz AS created_at,
                   NULL::timestamptz AS last_accessed_at,
                   NULL::jsonb AS metadata FROM folders)
            UNION ALL
            (SELECT path_tokens[$1] AS "name",
                   id, updated_at, created_at, last_accessed_at, metadata
             FROM storage.objects
             WHERE objects.name ILIKE $2 || '%%'
               AND bucket_id = $3
               AND array_length(objects.path_tokens, 1) = $1
             ORDER BY %I %s)
            LIMIT $4 OFFSET $5
            $sql$, v_sort_order, v_order_by, v_sort_order
        ) USING levels, v_prefix, bucketname, v_limit, offsets;
        RETURN;
    END IF;

    -- ========================================================================
    -- NAME SORTING: Hybrid skip-scan with batch optimization
    -- ========================================================================

    -- Calculate upper bound for prefix filtering
    IF v_prefix_lower = '' THEN
        v_upper_bound := NULL;
    ELSIF right(v_prefix_lower, 1) = v_delimiter THEN
        v_upper_bound := left(v_prefix_lower, -1) || chr(ascii(v_delimiter) + 1);
    ELSE
        v_upper_bound := left(v_prefix_lower, -1) || chr(ascii(right(v_prefix_lower, 1)) + 1);
    END IF;

    -- Build batch query (dynamic SQL - called infrequently, amortized over many rows)
    IF v_is_asc THEN
        IF v_upper_bound IS NOT NULL THEN
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND lower(o.name) COLLATE "C" >= $2 ' ||
                'AND lower(o.name) COLLATE "C" < $3 ORDER BY lower(o.name) COLLATE "C" ASC LIMIT $4';
        ELSE
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND lower(o.name) COLLATE "C" >= $2 ' ||
                'ORDER BY lower(o.name) COLLATE "C" ASC LIMIT $4';
        END IF;
    ELSE
        IF v_upper_bound IS NOT NULL THEN
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND lower(o.name) COLLATE "C" < $2 ' ||
                'AND lower(o.name) COLLATE "C" >= $3 ORDER BY lower(o.name) COLLATE "C" DESC LIMIT $4';
        ELSE
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND lower(o.name) COLLATE "C" < $2 ' ||
                'ORDER BY lower(o.name) COLLATE "C" DESC LIMIT $4';
        END IF;
    END IF;

    -- Initialize seek position
    IF v_is_asc THEN
        v_next_seek := v_prefix_lower;
    ELSE
        -- DESC: find the last item in range first (static SQL)
        IF v_upper_bound IS NOT NULL THEN
            SELECT o.name INTO v_peek_name FROM storage.objects o
            WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" >= v_prefix_lower AND lower(o.name) COLLATE "C" < v_upper_bound
            ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1;
        ELSIF v_prefix_lower <> '' THEN
            SELECT o.name INTO v_peek_name FROM storage.objects o
            WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" >= v_prefix_lower
            ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1;
        ELSE
            SELECT o.name INTO v_peek_name FROM storage.objects o
            WHERE o.bucket_id = bucketname
            ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1;
        END IF;

        IF v_peek_name IS NOT NULL THEN
            v_next_seek := lower(v_peek_name) || v_delimiter;
        ELSE
            RETURN;
        END IF;
    END IF;

    -- ========================================================================
    -- MAIN LOOP: Hybrid peek-then-batch algorithm
    -- Uses STATIC SQL for peek (hot path) and DYNAMIC SQL for batch
    -- ========================================================================
    LOOP
        EXIT WHEN v_count >= v_limit;

        -- STEP 1: PEEK using STATIC SQL (plan cached, very fast)
        IF v_is_asc THEN
            IF v_upper_bound IS NOT NULL THEN
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" >= v_next_seek AND lower(o.name) COLLATE "C" < v_upper_bound
                ORDER BY lower(o.name) COLLATE "C" ASC LIMIT 1;
            ELSE
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" >= v_next_seek
                ORDER BY lower(o.name) COLLATE "C" ASC LIMIT 1;
            END IF;
        ELSE
            IF v_upper_bound IS NOT NULL THEN
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" < v_next_seek AND lower(o.name) COLLATE "C" >= v_prefix_lower
                ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1;
            ELSIF v_prefix_lower <> '' THEN
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" < v_next_seek AND lower(o.name) COLLATE "C" >= v_prefix_lower
                ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1;
            ELSE
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" < v_next_seek
                ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1;
            END IF;
        END IF;

        EXIT WHEN v_peek_name IS NULL;

        -- STEP 2: Check if this is a FOLDER or FILE
        v_common_prefix := storage.get_common_prefix(lower(v_peek_name), v_prefix_lower, v_delimiter);

        IF v_common_prefix IS NOT NULL THEN
            -- FOLDER: Handle offset, emit if needed, skip to next folder
            IF v_skipped < offsets THEN
                v_skipped := v_skipped + 1;
            ELSE
                name := split_part(rtrim(storage.get_common_prefix(v_peek_name, v_prefix, v_delimiter), v_delimiter), v_delimiter, levels);
                id := NULL;
                updated_at := NULL;
                created_at := NULL;
                last_accessed_at := NULL;
                metadata := NULL;
                RETURN NEXT;
                v_count := v_count + 1;
            END IF;

            -- Advance seek past the folder range
            IF v_is_asc THEN
                v_next_seek := lower(left(v_common_prefix, -1)) || chr(ascii(v_delimiter) + 1);
            ELSE
                v_next_seek := lower(v_common_prefix);
            END IF;
        ELSE
            -- FILE: Batch fetch using DYNAMIC SQL (overhead amortized over many rows)
            -- For ASC: upper_bound is the exclusive upper limit (< condition)
            -- For DESC: prefix_lower is the inclusive lower limit (>= condition)
            FOR v_current IN EXECUTE v_batch_query
                USING bucketname, v_next_seek,
                    CASE WHEN v_is_asc THEN COALESCE(v_upper_bound, v_prefix_lower) ELSE v_prefix_lower END, v_file_batch_size
            LOOP
                v_common_prefix := storage.get_common_prefix(lower(v_current.name), v_prefix_lower, v_delimiter);

                IF v_common_prefix IS NOT NULL THEN
                    -- Hit a folder: exit batch, let peek handle it
                    v_next_seek := lower(v_current.name);
                    EXIT;
                END IF;

                -- Handle offset skipping
                IF v_skipped < offsets THEN
                    v_skipped := v_skipped + 1;
                ELSE
                    -- Emit file
                    name := split_part(v_current.name, v_delimiter, levels);
                    id := v_current.id;
                    updated_at := v_current.updated_at;
                    created_at := v_current.created_at;
                    last_accessed_at := v_current.last_accessed_at;
                    metadata := v_current.metadata;
                    RETURN NEXT;
                    v_count := v_count + 1;
                END IF;

                -- Advance seek past this file
                IF v_is_asc THEN
                    v_next_seek := lower(v_current.name) || v_delimiter;
                ELSE
                    v_next_seek := lower(v_current.name);
                END IF;

                EXIT WHEN v_count >= v_limit;
            END LOOP;
        END IF;
    END LOOP;
END;
$_$;


--
-- Name: search_by_timestamp(text, text, integer, integer, text, text, text, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.search_by_timestamp(p_prefix text, p_bucket_id text, p_limit integer, p_level integer, p_start_after text, p_sort_order text, p_sort_column text, p_sort_column_after text) RETURNS TABLE(key text, name text, id uuid, updated_at timestamp with time zone, created_at timestamp with time zone, last_accessed_at timestamp with time zone, metadata jsonb)
    LANGUAGE plpgsql STABLE
    AS $_$
DECLARE
    v_cursor_op text;
    v_query text;
    v_prefix text;
BEGIN
    v_prefix := coalesce(p_prefix, '');

    IF p_sort_order = 'asc' THEN
        v_cursor_op := '>';
    ELSE
        v_cursor_op := '<';
    END IF;

    v_query := format($sql$
        WITH raw_objects AS (
            SELECT
                o.name AS obj_name,
                o.id AS obj_id,
                o.updated_at AS obj_updated_at,
                o.created_at AS obj_created_at,
                o.last_accessed_at AS obj_last_accessed_at,
                o.metadata AS obj_metadata,
                storage.get_common_prefix(o.name, $1, '/') AS common_prefix
            FROM storage.objects o
            WHERE o.bucket_id = $2
              AND o.name COLLATE "C" LIKE $1 || '%%'
        ),
        -- Aggregate common prefixes (folders)
        -- Both created_at and updated_at use MIN(obj_created_at) to match the old prefixes table behavior
        aggregated_prefixes AS (
            SELECT
                rtrim(common_prefix, '/') AS name,
                NULL::uuid AS id,
                MIN(obj_created_at) AS updated_at,
                MIN(obj_created_at) AS created_at,
                NULL::timestamptz AS last_accessed_at,
                NULL::jsonb AS metadata,
                TRUE AS is_prefix
            FROM raw_objects
            WHERE common_prefix IS NOT NULL
            GROUP BY common_prefix
        ),
        leaf_objects AS (
            SELECT
                obj_name AS name,
                obj_id AS id,
                obj_updated_at AS updated_at,
                obj_created_at AS created_at,
                obj_last_accessed_at AS last_accessed_at,
                obj_metadata AS metadata,
                FALSE AS is_prefix
            FROM raw_objects
            WHERE common_prefix IS NULL
        ),
        combined AS (
            SELECT * FROM aggregated_prefixes
            UNION ALL
            SELECT * FROM leaf_objects
        ),
        filtered AS (
            SELECT *
            FROM combined
            WHERE (
                $5 = ''
                OR ROW(
                    date_trunc('milliseconds', %I),
                    name COLLATE "C"
                ) %s ROW(
                    COALESCE(NULLIF($6, '')::timestamptz, 'epoch'::timestamptz),
                    $5
                )
            )
        )
        SELECT
            split_part(name, '/', $3) AS key,
            name,
            id,
            updated_at,
            created_at,
            last_accessed_at,
            metadata
        FROM filtered
        ORDER BY
            COALESCE(date_trunc('milliseconds', %I), 'epoch'::timestamptz) %s,
            name COLLATE "C" %s
        LIMIT $4
    $sql$,
        p_sort_column,
        v_cursor_op,
        p_sort_column,
        p_sort_order,
        p_sort_order
    );

    RETURN QUERY EXECUTE v_query
    USING v_prefix, p_bucket_id, p_level, p_limit, p_start_after, p_sort_column_after;
END;
$_$;


--
-- Name: search_v2(text, text, integer, integer, text, text, text, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.search_v2(prefix text, bucket_name text, limits integer DEFAULT 100, levels integer DEFAULT 1, start_after text DEFAULT ''::text, sort_order text DEFAULT 'asc'::text, sort_column text DEFAULT 'name'::text, sort_column_after text DEFAULT ''::text) RETURNS TABLE(key text, name text, id uuid, updated_at timestamp with time zone, created_at timestamp with time zone, last_accessed_at timestamp with time zone, metadata jsonb)
    LANGUAGE plpgsql STABLE
    AS $$
DECLARE
    v_sort_col text;
    v_sort_ord text;
    v_limit int;
BEGIN
    -- Cap limit to maximum of 1500 records
    v_limit := LEAST(coalesce(limits, 100), 1500);

    -- Validate and normalize sort_order
    v_sort_ord := lower(coalesce(sort_order, 'asc'));
    IF v_sort_ord NOT IN ('asc', 'desc') THEN
        v_sort_ord := 'asc';
    END IF;

    -- Validate and normalize sort_column
    v_sort_col := lower(coalesce(sort_column, 'name'));
    IF v_sort_col NOT IN ('name', 'updated_at', 'created_at') THEN
        v_sort_col := 'name';
    END IF;

    -- Route to appropriate implementation
    IF v_sort_col = 'name' THEN
        -- Use list_objects_with_delimiter for name sorting (most efficient: O(k * log n))
        RETURN QUERY
        SELECT
            split_part(l.name, '/', levels) AS key,
            l.name AS name,
            l.id,
            l.updated_at,
            l.created_at,
            l.last_accessed_at,
            l.metadata
        FROM storage.list_objects_with_delimiter(
            bucket_name,
            coalesce(prefix, ''),
            '/',
            v_limit,
            start_after,
            '',
            v_sort_ord
        ) l;
    ELSE
        -- Use aggregation approach for timestamp sorting
        -- Not efficient for large datasets but supports correct pagination
        RETURN QUERY SELECT * FROM storage.search_by_timestamp(
            prefix, bucket_name, v_limit, levels, start_after,
            v_sort_ord, v_sort_col, sort_column_after
        );
    END IF;
END;
$$;


--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW; 
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: audit_log_entries; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.audit_log_entries (
    instance_id uuid,
    id uuid NOT NULL,
    payload json,
    created_at timestamp with time zone,
    ip_address character varying(64) DEFAULT ''::character varying NOT NULL
);


--
-- Name: TABLE audit_log_entries; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.audit_log_entries IS 'Auth: Audit trail for user actions.';


--
-- Name: custom_oauth_providers; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.custom_oauth_providers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    provider_type text NOT NULL,
    identifier text NOT NULL,
    name text NOT NULL,
    client_id text NOT NULL,
    client_secret text NOT NULL,
    acceptable_client_ids text[] DEFAULT '{}'::text[] NOT NULL,
    scopes text[] DEFAULT '{}'::text[] NOT NULL,
    pkce_enabled boolean DEFAULT true NOT NULL,
    attribute_mapping jsonb DEFAULT '{}'::jsonb NOT NULL,
    authorization_params jsonb DEFAULT '{}'::jsonb NOT NULL,
    enabled boolean DEFAULT true NOT NULL,
    email_optional boolean DEFAULT false NOT NULL,
    issuer text,
    discovery_url text,
    skip_nonce_check boolean DEFAULT false NOT NULL,
    cached_discovery jsonb,
    discovery_cached_at timestamp with time zone,
    authorization_url text,
    token_url text,
    userinfo_url text,
    jwks_uri text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    custom_claims_allowlist text[] DEFAULT '{}'::text[] NOT NULL,
    CONSTRAINT custom_oauth_providers_authorization_url_https CHECK (((authorization_url IS NULL) OR (authorization_url ~~ 'https://%'::text))),
    CONSTRAINT custom_oauth_providers_authorization_url_length CHECK (((authorization_url IS NULL) OR (char_length(authorization_url) <= 2048))),
    CONSTRAINT custom_oauth_providers_client_id_length CHECK (((char_length(client_id) >= 1) AND (char_length(client_id) <= 512))),
    CONSTRAINT custom_oauth_providers_discovery_url_length CHECK (((discovery_url IS NULL) OR (char_length(discovery_url) <= 2048))),
    CONSTRAINT custom_oauth_providers_identifier_format CHECK ((identifier ~ '^[a-z0-9][a-z0-9:-]{0,48}[a-z0-9]$'::text)),
    CONSTRAINT custom_oauth_providers_issuer_length CHECK (((issuer IS NULL) OR ((char_length(issuer) >= 1) AND (char_length(issuer) <= 2048)))),
    CONSTRAINT custom_oauth_providers_jwks_uri_https CHECK (((jwks_uri IS NULL) OR (jwks_uri ~~ 'https://%'::text))),
    CONSTRAINT custom_oauth_providers_jwks_uri_length CHECK (((jwks_uri IS NULL) OR (char_length(jwks_uri) <= 2048))),
    CONSTRAINT custom_oauth_providers_name_length CHECK (((char_length(name) >= 1) AND (char_length(name) <= 100))),
    CONSTRAINT custom_oauth_providers_oauth2_requires_endpoints CHECK (((provider_type <> 'oauth2'::text) OR ((authorization_url IS NOT NULL) AND (token_url IS NOT NULL) AND (userinfo_url IS NOT NULL)))),
    CONSTRAINT custom_oauth_providers_oidc_discovery_url_https CHECK (((provider_type <> 'oidc'::text) OR (discovery_url IS NULL) OR (discovery_url ~~ 'https://%'::text))),
    CONSTRAINT custom_oauth_providers_oidc_issuer_https CHECK (((provider_type <> 'oidc'::text) OR (issuer IS NULL) OR (issuer ~~ 'https://%'::text))),
    CONSTRAINT custom_oauth_providers_oidc_requires_issuer CHECK (((provider_type <> 'oidc'::text) OR (issuer IS NOT NULL))),
    CONSTRAINT custom_oauth_providers_provider_type_check CHECK ((provider_type = ANY (ARRAY['oauth2'::text, 'oidc'::text]))),
    CONSTRAINT custom_oauth_providers_token_url_https CHECK (((token_url IS NULL) OR (token_url ~~ 'https://%'::text))),
    CONSTRAINT custom_oauth_providers_token_url_length CHECK (((token_url IS NULL) OR (char_length(token_url) <= 2048))),
    CONSTRAINT custom_oauth_providers_userinfo_url_https CHECK (((userinfo_url IS NULL) OR (userinfo_url ~~ 'https://%'::text))),
    CONSTRAINT custom_oauth_providers_userinfo_url_length CHECK (((userinfo_url IS NULL) OR (char_length(userinfo_url) <= 2048)))
);


--
-- Name: flow_state; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.flow_state (
    id uuid NOT NULL,
    user_id uuid,
    auth_code text,
    code_challenge_method auth.code_challenge_method,
    code_challenge text,
    provider_type text NOT NULL,
    provider_access_token text,
    provider_refresh_token text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    authentication_method text NOT NULL,
    auth_code_issued_at timestamp with time zone,
    invite_token text,
    referrer text,
    oauth_client_state_id uuid,
    linking_target_id uuid,
    email_optional boolean DEFAULT false NOT NULL
);


--
-- Name: TABLE flow_state; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.flow_state IS 'Stores metadata for all OAuth/SSO login flows';


--
-- Name: identities; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.identities (
    provider_id text NOT NULL,
    user_id uuid NOT NULL,
    identity_data jsonb NOT NULL,
    provider text NOT NULL,
    last_sign_in_at timestamp with time zone,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    email text GENERATED ALWAYS AS (lower((identity_data ->> 'email'::text))) STORED,
    id uuid DEFAULT gen_random_uuid() NOT NULL
);


--
-- Name: TABLE identities; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.identities IS 'Auth: Stores identities associated to a user.';


--
-- Name: COLUMN identities.email; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.identities.email IS 'Auth: Email is a generated column that references the optional email property in the identity_data';


--
-- Name: instances; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.instances (
    id uuid NOT NULL,
    uuid uuid,
    raw_base_config text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


--
-- Name: TABLE instances; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.instances IS 'Auth: Manages users across multiple sites.';


--
-- Name: mfa_amr_claims; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.mfa_amr_claims (
    session_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    authentication_method text NOT NULL,
    id uuid NOT NULL
);


--
-- Name: TABLE mfa_amr_claims; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.mfa_amr_claims IS 'auth: stores authenticator method reference claims for multi factor authentication';


--
-- Name: mfa_challenges; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.mfa_challenges (
    id uuid NOT NULL,
    factor_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    verified_at timestamp with time zone,
    ip_address inet NOT NULL,
    otp_code text,
    web_authn_session_data jsonb
);


--
-- Name: TABLE mfa_challenges; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.mfa_challenges IS 'auth: stores metadata about challenge requests made';


--
-- Name: mfa_factors; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.mfa_factors (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    friendly_name text,
    factor_type auth.factor_type NOT NULL,
    status auth.factor_status NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    secret text,
    phone text,
    last_challenged_at timestamp with time zone,
    web_authn_credential jsonb,
    web_authn_aaguid uuid,
    last_webauthn_challenge_data jsonb
);


--
-- Name: TABLE mfa_factors; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.mfa_factors IS 'auth: stores metadata about factors';


--
-- Name: COLUMN mfa_factors.last_webauthn_challenge_data; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.mfa_factors.last_webauthn_challenge_data IS 'Stores the latest WebAuthn challenge data including attestation/assertion for customer verification';


--
-- Name: oauth_authorizations; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.oauth_authorizations (
    id uuid NOT NULL,
    authorization_id text NOT NULL,
    client_id uuid NOT NULL,
    user_id uuid,
    redirect_uri text NOT NULL,
    scope text NOT NULL,
    state text,
    resource text,
    code_challenge text,
    code_challenge_method auth.code_challenge_method,
    response_type auth.oauth_response_type DEFAULT 'code'::auth.oauth_response_type NOT NULL,
    status auth.oauth_authorization_status DEFAULT 'pending'::auth.oauth_authorization_status NOT NULL,
    authorization_code text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    expires_at timestamp with time zone DEFAULT (now() + '00:03:00'::interval) NOT NULL,
    approved_at timestamp with time zone,
    nonce text,
    CONSTRAINT oauth_authorizations_authorization_code_length CHECK ((char_length(authorization_code) <= 255)),
    CONSTRAINT oauth_authorizations_code_challenge_length CHECK ((char_length(code_challenge) <= 128)),
    CONSTRAINT oauth_authorizations_expires_at_future CHECK ((expires_at > created_at)),
    CONSTRAINT oauth_authorizations_nonce_length CHECK ((char_length(nonce) <= 255)),
    CONSTRAINT oauth_authorizations_redirect_uri_length CHECK ((char_length(redirect_uri) <= 2048)),
    CONSTRAINT oauth_authorizations_resource_length CHECK ((char_length(resource) <= 2048)),
    CONSTRAINT oauth_authorizations_scope_length CHECK ((char_length(scope) <= 4096)),
    CONSTRAINT oauth_authorizations_state_length CHECK ((char_length(state) <= 4096))
);


--
-- Name: oauth_client_states; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.oauth_client_states (
    id uuid NOT NULL,
    provider_type text NOT NULL,
    code_verifier text,
    created_at timestamp with time zone NOT NULL
);


--
-- Name: TABLE oauth_client_states; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.oauth_client_states IS 'Stores OAuth states for third-party provider authentication flows where Supabase acts as the OAuth client.';


--
-- Name: oauth_clients; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.oauth_clients (
    id uuid NOT NULL,
    client_secret_hash text,
    registration_type auth.oauth_registration_type NOT NULL,
    redirect_uris text NOT NULL,
    grant_types text NOT NULL,
    client_name text,
    client_uri text,
    logo_uri text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    client_type auth.oauth_client_type DEFAULT 'confidential'::auth.oauth_client_type NOT NULL,
    token_endpoint_auth_method text NOT NULL,
    CONSTRAINT oauth_clients_client_name_length CHECK ((char_length(client_name) <= 1024)),
    CONSTRAINT oauth_clients_client_uri_length CHECK ((char_length(client_uri) <= 2048)),
    CONSTRAINT oauth_clients_logo_uri_length CHECK ((char_length(logo_uri) <= 2048)),
    CONSTRAINT oauth_clients_token_endpoint_auth_method_check CHECK ((token_endpoint_auth_method = ANY (ARRAY['client_secret_basic'::text, 'client_secret_post'::text, 'none'::text])))
);


--
-- Name: oauth_consents; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.oauth_consents (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    client_id uuid NOT NULL,
    scopes text NOT NULL,
    granted_at timestamp with time zone DEFAULT now() NOT NULL,
    revoked_at timestamp with time zone,
    CONSTRAINT oauth_consents_revoked_after_granted CHECK (((revoked_at IS NULL) OR (revoked_at >= granted_at))),
    CONSTRAINT oauth_consents_scopes_length CHECK ((char_length(scopes) <= 2048)),
    CONSTRAINT oauth_consents_scopes_not_empty CHECK ((char_length(TRIM(BOTH FROM scopes)) > 0))
);


--
-- Name: one_time_tokens; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.one_time_tokens (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    token_type auth.one_time_token_type NOT NULL,
    token_hash text NOT NULL,
    relates_to text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT one_time_tokens_token_hash_check CHECK ((char_length(token_hash) > 0))
);


--
-- Name: refresh_tokens; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.refresh_tokens (
    instance_id uuid,
    id bigint NOT NULL,
    token character varying(255),
    user_id character varying(255),
    revoked boolean,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    parent character varying(255),
    session_id uuid
);


--
-- Name: TABLE refresh_tokens; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.refresh_tokens IS 'Auth: Store of tokens used to refresh JWT tokens once they expire.';


--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE; Schema: auth; Owner: -
--

CREATE SEQUENCE auth.refresh_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: auth; Owner: -
--

ALTER SEQUENCE auth.refresh_tokens_id_seq OWNED BY auth.refresh_tokens.id;


--
-- Name: saml_providers; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.saml_providers (
    id uuid NOT NULL,
    sso_provider_id uuid NOT NULL,
    entity_id text NOT NULL,
    metadata_xml text NOT NULL,
    metadata_url text,
    attribute_mapping jsonb,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    name_id_format text,
    CONSTRAINT "entity_id not empty" CHECK ((char_length(entity_id) > 0)),
    CONSTRAINT "metadata_url not empty" CHECK (((metadata_url = NULL::text) OR (char_length(metadata_url) > 0))),
    CONSTRAINT "metadata_xml not empty" CHECK ((char_length(metadata_xml) > 0))
);


--
-- Name: TABLE saml_providers; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.saml_providers IS 'Auth: Manages SAML Identity Provider connections.';


--
-- Name: saml_relay_states; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.saml_relay_states (
    id uuid NOT NULL,
    sso_provider_id uuid NOT NULL,
    request_id text NOT NULL,
    for_email text,
    redirect_to text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    flow_state_id uuid,
    CONSTRAINT "request_id not empty" CHECK ((char_length(request_id) > 0))
);


--
-- Name: TABLE saml_relay_states; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.saml_relay_states IS 'Auth: Contains SAML Relay State information for each Service Provider initiated login.';


--
-- Name: schema_migrations; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.schema_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: TABLE schema_migrations; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.schema_migrations IS 'Auth: Manages updates to the auth system.';


--
-- Name: sessions; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.sessions (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    factor_id uuid,
    aal auth.aal_level,
    not_after timestamp with time zone,
    refreshed_at timestamp without time zone,
    user_agent text,
    ip inet,
    tag text,
    oauth_client_id uuid,
    refresh_token_hmac_key text,
    refresh_token_counter bigint,
    scopes text,
    CONSTRAINT sessions_scopes_length CHECK ((char_length(scopes) <= 4096))
);


--
-- Name: TABLE sessions; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.sessions IS 'Auth: Stores session data associated to a user.';


--
-- Name: COLUMN sessions.not_after; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.sessions.not_after IS 'Auth: Not after is a nullable column that contains a timestamp after which the session should be regarded as expired.';


--
-- Name: COLUMN sessions.refresh_token_hmac_key; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.sessions.refresh_token_hmac_key IS 'Holds a HMAC-SHA256 key used to sign refresh tokens for this session.';


--
-- Name: COLUMN sessions.refresh_token_counter; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.sessions.refresh_token_counter IS 'Holds the ID (counter) of the last issued refresh token.';


--
-- Name: sso_domains; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.sso_domains (
    id uuid NOT NULL,
    sso_provider_id uuid NOT NULL,
    domain text NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    CONSTRAINT "domain not empty" CHECK ((char_length(domain) > 0))
);


--
-- Name: TABLE sso_domains; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.sso_domains IS 'Auth: Manages SSO email address domain mapping to an SSO Identity Provider.';


--
-- Name: sso_providers; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.sso_providers (
    id uuid NOT NULL,
    resource_id text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    disabled boolean,
    CONSTRAINT "resource_id not empty" CHECK (((resource_id = NULL::text) OR (char_length(resource_id) > 0)))
);


--
-- Name: TABLE sso_providers; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.sso_providers IS 'Auth: Manages SSO identity provider information; see saml_providers for SAML.';


--
-- Name: COLUMN sso_providers.resource_id; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.sso_providers.resource_id IS 'Auth: Uniquely identifies a SSO provider according to a user-chosen resource ID (case insensitive), useful in infrastructure as code.';


--
-- Name: users; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.users (
    instance_id uuid,
    id uuid NOT NULL,
    aud character varying(255),
    role character varying(255),
    email character varying(255),
    encrypted_password character varying(255),
    email_confirmed_at timestamp with time zone,
    invited_at timestamp with time zone,
    confirmation_token character varying(255),
    confirmation_sent_at timestamp with time zone,
    recovery_token character varying(255),
    recovery_sent_at timestamp with time zone,
    email_change_token_new character varying(255),
    email_change character varying(255),
    email_change_sent_at timestamp with time zone,
    last_sign_in_at timestamp with time zone,
    raw_app_meta_data jsonb,
    raw_user_meta_data jsonb,
    is_super_admin boolean,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    phone text DEFAULT NULL::character varying,
    phone_confirmed_at timestamp with time zone,
    phone_change text DEFAULT ''::character varying,
    phone_change_token character varying(255) DEFAULT ''::character varying,
    phone_change_sent_at timestamp with time zone,
    confirmed_at timestamp with time zone GENERATED ALWAYS AS (LEAST(email_confirmed_at, phone_confirmed_at)) STORED,
    email_change_token_current character varying(255) DEFAULT ''::character varying,
    email_change_confirm_status smallint DEFAULT 0,
    banned_until timestamp with time zone,
    reauthentication_token character varying(255) DEFAULT ''::character varying,
    reauthentication_sent_at timestamp with time zone,
    is_sso_user boolean DEFAULT false NOT NULL,
    deleted_at timestamp with time zone,
    is_anonymous boolean DEFAULT false NOT NULL,
    CONSTRAINT users_email_change_confirm_status_check CHECK (((email_change_confirm_status >= 0) AND (email_change_confirm_status <= 2)))
);


--
-- Name: TABLE users; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.users IS 'Auth: Stores user login data within a secure schema.';


--
-- Name: COLUMN users.is_sso_user; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.users.is_sso_user IS 'Auth: Set this column to true when the account comes from SSO. These accounts can have duplicate emails.';


--
-- Name: webauthn_challenges; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.webauthn_challenges (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid,
    challenge_type text NOT NULL,
    session_data jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    CONSTRAINT webauthn_challenges_challenge_type_check CHECK ((challenge_type = ANY (ARRAY['signup'::text, 'registration'::text, 'authentication'::text])))
);


--
-- Name: webauthn_credentials; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.webauthn_credentials (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    credential_id bytea NOT NULL,
    public_key bytea NOT NULL,
    attestation_type text DEFAULT ''::text NOT NULL,
    aaguid uuid,
    sign_count bigint DEFAULT 0 NOT NULL,
    transports jsonb DEFAULT '[]'::jsonb NOT NULL,
    backup_eligible boolean DEFAULT false NOT NULL,
    backed_up boolean DEFAULT false NOT NULL,
    friendly_name text DEFAULT ''::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    last_used_at timestamp with time zone
);


--
-- Name: adjustments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.adjustments (
    id bigint NOT NULL,
    do_no text NOT NULL,
    field text NOT NULL,
    old_value text,
    new_value text NOT NULL,
    reason text NOT NULL,
    adjusted_by text NOT NULL,
    adjusted_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: adjustments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.adjustments ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.adjustments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: app_state; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.app_state (
    id integer DEFAULT 1 NOT NULL,
    state jsonb NOT NULL,
    rev bigint DEFAULT 0 NOT NULL,
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT app_state_id_check CHECK ((id = 1))
);


--
-- Name: approved_domains; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.approved_domains (
    domain text NOT NULL,
    client_id text,
    account_limit smallint DEFAULT 10 NOT NULL,
    accounts_used smallint DEFAULT 0 NOT NULL,
    added_by text,
    added_at timestamp with time zone DEFAULT now()
);


--
-- Name: audit_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.audit_log (
    id bigint NOT NULL,
    at timestamp with time zone DEFAULT now() NOT NULL,
    actor text,
    action text,
    entity text,
    entity_id text,
    before jsonb,
    after jsonb
);


--
-- Name: audit_log_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.audit_log ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.audit_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: bins; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bins (
    bin_id text NOT NULL,
    bin_type text,
    volume_m3 numeric(6,2),
    tare_kg numeric(8,1),
    owner text DEFAULT 'Lirich'::text,
    purchase_cost numeric(10,2),
    active boolean DEFAULT true NOT NULL
);


--
-- Name: collections; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.collections (
    do_no text NOT NULL,
    source text DEFAULT 'live'::text NOT NULL,
    job_no text,
    do_date date,
    do_type text,
    trip_type text,
    site_id text,
    vessel_name text,
    berth text,
    vehicle_id text,
    driver_id text,
    job_type text,
    waste_type text,
    bin_in text,
    bin_out text,
    vol_cat_a numeric(8,2),
    vol_cat_b numeric(8,2),
    vol_cat_c numeric(8,2),
    vol_cat_d numeric(8,2),
    vol_cat_e numeric(8,2),
    vol_cat_f numeric(8,2),
    vol_total_m3 numeric(8,2),
    gross_kg numeric(10,1),
    tare_kg numeric(10,1),
    net_kg numeric(10,1),
    weigh_ticket_no text,
    weigh_location text,
    weight_source text DEFAULT 'volume_est'::text,
    gps_lat numeric(9,6),
    gps_lng numeric(9,6),
    gps_accuracy_m numeric(6,1),
    gps_captured_at timestamp with time zone,
    photo_do_ref text,
    photo_sig_ref text,
    photo_weigh_ref text,
    receipt_ref text,
    disposal_facility text,
    xero_invoice_id text,
    backfill_notes text,
    synced_at timestamp with time zone DEFAULT now() NOT NULL,
    sludge_requested_t numeric,
    sludge_actual_t numeric,
    dispose_to text,
    CONSTRAINT collections_source_check CHECK ((source = ANY (ARRAY['live'::text, 'backfill'::text]))),
    CONSTRAINT collections_weight_source_check CHECK ((weight_source = ANY (ARRAY['weighbridge'::text, 'volume_est'::text, 'invoice'::text])))
);


--
-- Name: COLUMN collections.sludge_requested_t; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.collections.sludge_requested_t IS 'Sludge requested (tonnes), MARPOL Annex I. Nullable; home for the PIL invoice backfill. NULL/0 until backfilled.';


--
-- Name: COLUMN collections.sludge_actual_t; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.collections.sludge_actual_t IS 'Sludge actually recovered (tonnes). Nullable; feeds recovery/avoided in the report function. NULL/0 until backfilled.';


--
-- Name: collections_effective; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.collections_effective AS
 SELECT do_no,
    source,
    job_no,
    do_date,
    do_type,
    trip_type,
    site_id,
    vessel_name,
    berth,
    vehicle_id,
    driver_id,
    job_type,
    waste_type,
    bin_in,
    bin_out,
    vol_cat_a,
    vol_cat_b,
    vol_cat_c,
    vol_cat_d,
    vol_cat_e,
    vol_cat_f,
    vol_total_m3,
    gross_kg,
    tare_kg,
    net_kg,
    weigh_ticket_no,
    weigh_location,
    weight_source,
    gps_lat,
    gps_lng,
    gps_accuracy_m,
    gps_captured_at,
    photo_do_ref,
    photo_sig_ref,
    photo_weigh_ref,
    receipt_ref,
    disposal_facility,
    xero_invoice_id,
    backfill_notes,
    synced_at,
    COALESCE(( SELECT (a.new_value)::numeric AS new_value
           FROM public.adjustments a
          WHERE ((a.do_no = c.do_no) AND (a.field = 'net_kg'::text))
          ORDER BY a.adjusted_at DESC
         LIMIT 1), net_kg) AS net_kg_effective,
    COALESCE(( SELECT (a.new_value)::numeric AS new_value
           FROM public.adjustments a
          WHERE ((a.do_no = c.do_no) AND (a.field = 'vol_total_m3'::text))
          ORDER BY a.adjusted_at DESC
         LIMIT 1), vol_total_m3) AS vol_total_m3_effective
   FROM public.collections c;


--
-- Name: customers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.customers (
    client_id text NOT NULL,
    name text NOT NULL,
    payment_terms text,
    sales_rep text,
    xero_contact_id text,
    active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    contact_name text,
    contact_phone text,
    contact_email text
);


--
-- Name: drivers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.drivers (
    driver_id text NOT NULL,
    name text NOT NULL,
    phone text,
    active boolean DEFAULT true NOT NULL
);


--
-- Name: facilities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.facilities (
    facility_id text NOT NULL,
    name text NOT NULL,
    route text NOT NULL
);


--
-- Name: factors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.factors (
    id bigint NOT NULL,
    domain text NOT NULL,
    key text NOT NULL,
    route text,
    value numeric(12,6) NOT NULL,
    unit text NOT NULL,
    basis text,
    source_ref text,
    valid_from date DEFAULT CURRENT_DATE NOT NULL
);


--
-- Name: factors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.factors ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.factors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: fuel_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fuel_log (
    id bigint NOT NULL,
    vehicle_id text NOT NULL,
    fill_date date NOT NULL,
    litres numeric(8,2) NOT NULL,
    cost numeric(10,2),
    odometer_km integer,
    entered_by text,
    source text,
    fuel_type text,
    cartrack_co2_g numeric,
    synced_at timestamp with time zone
);


--
-- Name: fuel_log_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.fuel_log ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.fuel_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: interest_leads; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.interest_leads (
    id bigint NOT NULL,
    email text NOT NULL,
    source text DEFAULT 'carbon_calculator'::text,
    page text,
    ip text,
    user_agent text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: interest_leads_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.interest_leads ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.interest_leads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: jobcard_overrides; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.jobcard_overrides (
    id bigint NOT NULL,
    card_date date NOT NULL,
    driver_id integer NOT NULL,
    field_key text NOT NULL,
    old_value text,
    new_value text,
    actor text,
    at timestamp with time zone DEFAULT now()
);


--
-- Name: jobcard_overrides_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.jobcard_overrides_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: jobcard_overrides_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.jobcard_overrides_id_seq OWNED BY public.jobcard_overrides.id;


--
-- Name: jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.jobs (
    job_no text NOT NULL,
    job_date date NOT NULL,
    status text DEFAULT 'assigned'::text NOT NULL,
    site_id text NOT NULL,
    contact text,
    task text,
    bin_size text,
    waste_type text,
    dump_to text,
    driver_id text,
    started_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: maintenance; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.maintenance (
    id bigint NOT NULL,
    vehicle_id text NOT NULL,
    service_date date,
    description text,
    cost numeric(10,2),
    photo_ref text
);


--
-- Name: maintenance_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.maintenance ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.maintenance_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: odometer_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.odometer_log (
    id bigint NOT NULL,
    vehicle_id text NOT NULL,
    read_date date NOT NULL,
    odometer_km integer,
    source text,
    distance_km numeric,
    cartrack_co2_g numeric,
    synced_at timestamp with time zone
);


--
-- Name: odometer_log_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.odometer_log ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.odometer_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: onward_disposal; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.onward_disposal (
    id bigint NOT NULL,
    do_no text NOT NULL,
    hop_no smallint DEFAULT 1 NOT NULL,
    facility_id text,
    moved_date date,
    receipt_ref text
);


--
-- Name: onward_disposal_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.onward_disposal ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.onward_disposal_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: portal_accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.portal_accounts (
    id bigint NOT NULL,
    email text NOT NULL,
    display_name text,
    client_id text,
    status text DEFAULT 'pending'::text NOT NULL,
    requested_at timestamp with time zone DEFAULT now(),
    provisioned_at timestamp with time zone,
    notes text,
    CONSTRAINT portal_accounts_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'approved'::text, 'provisioned'::text, 'revoked'::text])))
);


--
-- Name: portal_accounts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.portal_accounts ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.portal_accounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: rate_card; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rate_card (
    id bigint NOT NULL,
    site_id text NOT NULL,
    job_type text NOT NULL,
    price numeric(10,2) NOT NULL,
    valid_from date DEFAULT CURRENT_DATE NOT NULL,
    created_by text,
    CONSTRAINT rate_card_job_type_check CHECK ((job_type = ANY (ARRAY['Exchange'::text, 'Collect'::text, 'Delivery'::text, 'Sell'::text, 'Dump'::text, 'Load'::text])))
);


--
-- Name: rate_card_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.rate_card ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.rate_card_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: ref_lists; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ref_lists (
    kind text NOT NULL,
    value text NOT NULL
);


--
-- Name: sites; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sites (
    site_id text NOT NULL,
    client_id text NOT NULL,
    site_name text,
    address text,
    active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    contact_name text,
    contact_phone text,
    contact_email text
);


--
-- Name: vehicles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vehicles (
    vehicle_id text NOT NULL,
    vtype text,
    active boolean DEFAULT true NOT NULL
);


--
-- Name: yard_inbound; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.yard_inbound (
    id bigint NOT NULL,
    log_date date NOT NULL,
    waste_type text NOT NULL,
    source_name text NOT NULL,
    source_addr text,
    qty_t numeric NOT NULL,
    remarks text,
    entered_by text,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: yard_inbound_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.yard_inbound_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: yard_inbound_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.yard_inbound_id_seq OWNED BY public.yard_inbound.id;


--
-- Name: yard_stock; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.yard_stock (
    id bigint NOT NULL,
    take_date date NOT NULL,
    waste_type text NOT NULL,
    qty_t numeric NOT NULL,
    remarks text,
    entered_by text,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: yard_stock_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.yard_stock_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: yard_stock_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.yard_stock_id_seq OWNED BY public.yard_stock.id;


--
-- Name: messages; Type: TABLE; Schema: realtime; Owner: -
--

CREATE TABLE realtime.messages (
    topic text NOT NULL,
    extension text NOT NULL,
    payload jsonb,
    event text,
    private boolean DEFAULT false,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    binary_payload bytea
)
PARTITION BY RANGE (inserted_at);


--
-- Name: schema_migrations; Type: TABLE; Schema: realtime; Owner: -
--

CREATE TABLE realtime.schema_migrations (
    version bigint NOT NULL,
    inserted_at timestamp(0) without time zone DEFAULT now()
);


--
-- Name: subscription; Type: TABLE; Schema: realtime; Owner: -
--

CREATE TABLE realtime.subscription (
    id bigint NOT NULL,
    subscription_id uuid NOT NULL,
    entity regclass NOT NULL,
    filters realtime.user_defined_filter[] DEFAULT '{}'::realtime.user_defined_filter[] NOT NULL,
    claims jsonb NOT NULL,
    claims_role regrole GENERATED ALWAYS AS (realtime.to_regrole((claims ->> 'role'::text))) STORED NOT NULL,
    created_at timestamp without time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    action_filter text DEFAULT '*'::text,
    selected_columns text[],
    CONSTRAINT subscription_action_filter_check CHECK ((action_filter = ANY (ARRAY['*'::text, 'INSERT'::text, 'UPDATE'::text, 'DELETE'::text])))
);


--
-- Name: subscription_id_seq; Type: SEQUENCE; Schema: realtime; Owner: -
--

ALTER TABLE realtime.subscription ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME realtime.subscription_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: buckets; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.buckets (
    id text NOT NULL,
    name text NOT NULL,
    owner uuid,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    public boolean DEFAULT false,
    avif_autodetection boolean DEFAULT false,
    file_size_limit bigint,
    allowed_mime_types text[],
    owner_id text,
    type storage.buckettype DEFAULT 'STANDARD'::storage.buckettype NOT NULL
);


--
-- Name: COLUMN buckets.owner; Type: COMMENT; Schema: storage; Owner: -
--

COMMENT ON COLUMN storage.buckets.owner IS 'Field is deprecated, use owner_id instead';


--
-- Name: buckets_analytics; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.buckets_analytics (
    name text NOT NULL,
    type storage.buckettype DEFAULT 'ANALYTICS'::storage.buckettype NOT NULL,
    format text DEFAULT 'ICEBERG'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    deleted_at timestamp with time zone
);


--
-- Name: buckets_vectors; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.buckets_vectors (
    id text NOT NULL,
    type storage.buckettype DEFAULT 'VECTOR'::storage.buckettype NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: migrations; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.migrations (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    hash character varying(40) NOT NULL,
    executed_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: objects; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.objects (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    bucket_id text,
    name text,
    owner uuid,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    last_accessed_at timestamp with time zone DEFAULT now(),
    metadata jsonb,
    path_tokens text[] GENERATED ALWAYS AS (string_to_array(name, '/'::text)) STORED,
    version text,
    owner_id text,
    user_metadata jsonb
);


--
-- Name: COLUMN objects.owner; Type: COMMENT; Schema: storage; Owner: -
--

COMMENT ON COLUMN storage.objects.owner IS 'Field is deprecated, use owner_id instead';


--
-- Name: s3_multipart_uploads; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.s3_multipart_uploads (
    id text NOT NULL,
    in_progress_size bigint DEFAULT 0 NOT NULL,
    upload_signature text NOT NULL,
    bucket_id text NOT NULL,
    key text NOT NULL COLLATE pg_catalog."C",
    version text NOT NULL,
    owner_id text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    user_metadata jsonb,
    metadata jsonb
);


--
-- Name: s3_multipart_uploads_parts; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.s3_multipart_uploads_parts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    upload_id text NOT NULL,
    size bigint DEFAULT 0 NOT NULL,
    part_number integer NOT NULL,
    bucket_id text NOT NULL,
    key text NOT NULL COLLATE pg_catalog."C",
    etag text NOT NULL,
    owner_id text,
    version text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: vector_indexes; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.vector_indexes (
    id text DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL COLLATE pg_catalog."C",
    bucket_id text NOT NULL,
    data_type text NOT NULL,
    dimension integer NOT NULL,
    distance_metric text NOT NULL,
    metadata_configuration jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: refresh_tokens id; Type: DEFAULT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.refresh_tokens ALTER COLUMN id SET DEFAULT nextval('auth.refresh_tokens_id_seq'::regclass);


--
-- Name: jobcard_overrides id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.jobcard_overrides ALTER COLUMN id SET DEFAULT nextval('public.jobcard_overrides_id_seq'::regclass);


--
-- Name: yard_inbound id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.yard_inbound ALTER COLUMN id SET DEFAULT nextval('public.yard_inbound_id_seq'::regclass);


--
-- Name: yard_stock id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.yard_stock ALTER COLUMN id SET DEFAULT nextval('public.yard_stock_id_seq'::regclass);


--
-- Data for Name: audit_log_entries; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) FROM stdin;
\.


--
-- Data for Name: custom_oauth_providers; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.custom_oauth_providers (id, provider_type, identifier, name, client_id, client_secret, acceptable_client_ids, scopes, pkce_enabled, attribute_mapping, authorization_params, enabled, email_optional, issuer, discovery_url, skip_nonce_check, cached_discovery, discovery_cached_at, authorization_url, token_url, userinfo_url, jwks_uri, created_at, updated_at, custom_claims_allowlist) FROM stdin;
\.


--
-- Data for Name: flow_state; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.flow_state (id, user_id, auth_code, code_challenge_method, code_challenge, provider_type, provider_access_token, provider_refresh_token, created_at, updated_at, authentication_method, auth_code_issued_at, invite_token, referrer, oauth_client_state_id, linking_target_id, email_optional) FROM stdin;
\.


--
-- Data for Name: identities; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, id) FROM stdin;
\.


--
-- Data for Name: instances; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.instances (id, uuid, raw_base_config, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: mfa_amr_claims; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) FROM stdin;
\.


--
-- Data for Name: mfa_challenges; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.mfa_challenges (id, factor_id, created_at, verified_at, ip_address, otp_code, web_authn_session_data) FROM stdin;
\.


--
-- Data for Name: mfa_factors; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.mfa_factors (id, user_id, friendly_name, factor_type, status, created_at, updated_at, secret, phone, last_challenged_at, web_authn_credential, web_authn_aaguid, last_webauthn_challenge_data) FROM stdin;
\.


--
-- Data for Name: oauth_authorizations; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.oauth_authorizations (id, authorization_id, client_id, user_id, redirect_uri, scope, state, resource, code_challenge, code_challenge_method, response_type, status, authorization_code, created_at, expires_at, approved_at, nonce) FROM stdin;
\.


--
-- Data for Name: oauth_client_states; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.oauth_client_states (id, provider_type, code_verifier, created_at) FROM stdin;
\.


--
-- Data for Name: oauth_clients; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.oauth_clients (id, client_secret_hash, registration_type, redirect_uris, grant_types, client_name, client_uri, logo_uri, created_at, updated_at, deleted_at, client_type, token_endpoint_auth_method) FROM stdin;
\.


--
-- Data for Name: oauth_consents; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.oauth_consents (id, user_id, client_id, scopes, granted_at, revoked_at) FROM stdin;
\.


--
-- Data for Name: one_time_tokens; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.one_time_tokens (id, user_id, token_type, token_hash, relates_to, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: refresh_tokens; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) FROM stdin;
\.


--
-- Data for Name: saml_providers; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.saml_providers (id, sso_provider_id, entity_id, metadata_xml, metadata_url, attribute_mapping, created_at, updated_at, name_id_format) FROM stdin;
\.


--
-- Data for Name: saml_relay_states; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.saml_relay_states (id, sso_provider_id, request_id, for_email, redirect_to, created_at, updated_at, flow_state_id) FROM stdin;
\.


--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.schema_migrations (version) FROM stdin;
20171026211738
20171026211808
20171026211834
20180103212743
20180108183307
20180119214651
20180125194653
00
20210710035447
20210722035447
20210730183235
20210909172000
20210927181326
20211122151130
20211124214934
20211202183645
20220114185221
20220114185340
20220224000811
20220323170000
20220429102000
20220531120530
20220614074223
20220811173540
20221003041349
20221003041400
20221011041400
20221020193600
20221021073300
20221021082433
20221027105023
20221114143122
20221114143410
20221125140132
20221208132122
20221215195500
20221215195800
20221215195900
20230116124310
20230116124412
20230131181311
20230322519590
20230402418590
20230411005111
20230508135423
20230523124323
20230818113222
20230914180801
20231027141322
20231114161723
20231117164230
20240115144230
20240214120130
20240306115329
20240314092811
20240427152123
20240612123726
20240729123726
20240802193726
20240806073726
20241009103726
20250717082212
20250731150234
20250804100000
20250901200500
20250903112500
20250904133000
20250925093508
20251007112900
20251104100000
20251111201300
20251201000000
20260115000000
20260121000000
20260219120000
20260302000000
20260625000000
\.


--
-- Data for Name: sessions; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) FROM stdin;
\.


--
-- Data for Name: sso_domains; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.sso_domains (id, sso_provider_id, domain, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: sso_providers; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.sso_providers (id, resource_id, created_at, updated_at, disabled) FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) FROM stdin;
\.


--
-- Data for Name: webauthn_challenges; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.webauthn_challenges (id, user_id, challenge_type, session_data, created_at, expires_at) FROM stdin;
\.


--
-- Data for Name: webauthn_credentials; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.webauthn_credentials (id, user_id, credential_id, public_key, attestation_type, aaguid, sign_count, transports, backup_eligible, backed_up, friendly_name, created_at, updated_at, last_used_at) FROM stdin;
\.


--
-- Data for Name: job; Type: TABLE DATA; Schema: cron; Owner: -
--

COPY cron.job (jobid, schedule, command, nodename, nodeport, database, username, active, jobname) FROM stdin;
1	0 19 * * *	 select net.http_post( url:='https://zjtvrlbyfeirnrlqgefo.supabase.co/functions/v1/cartrack-sync?mode=sync', headers:=jsonb_build_object('x-sync-key','3c55a26e60493d32504ab0a5d1cf898922396f399e27e2e8') ); 	localhost	5432	postgres	postgres	t	cartrack-daily-sync
\.


--
-- Data for Name: job_run_details; Type: TABLE DATA; Schema: cron; Owner: -
--

COPY cron.job_run_details (jobid, runid, job_pid, database, username, command, status, return_message, start_time, end_time) FROM stdin;
1	1	550901	postgres	postgres	 select net.http_post( url:='https://zjtvrlbyfeirnrlqgefo.supabase.co/functions/v1/cartrack-sync?mode=sync', headers:=jsonb_build_object('x-sync-key','3c55a26e60493d32504ab0a5d1cf898922396f399e27e2e8') ); 	succeeded	1 row	2026-07-29 19:00:00.223239+00	2026-07-29 19:00:00.285774+00
1	2	653743	postgres	postgres	 select net.http_post( url:='https://zjtvrlbyfeirnrlqgefo.supabase.co/functions/v1/cartrack-sync?mode=sync', headers:=jsonb_build_object('x-sync-key','3c55a26e60493d32504ab0a5d1cf898922396f399e27e2e8') ); 	succeeded	1 row	2026-07-30 19:00:00.154752+00	2026-07-30 19:00:00.214262+00
1	3	755078	postgres	postgres	 select net.http_post( url:='https://zjtvrlbyfeirnrlqgefo.supabase.co/functions/v1/cartrack-sync?mode=sync', headers:=jsonb_build_object('x-sync-key','3c55a26e60493d32504ab0a5d1cf898922396f399e27e2e8') ); 	succeeded	1 row	2026-07-31 19:00:00.162194+00	2026-07-31 19:00:00.183096+00
\.


--
-- Data for Name: adjustments; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.adjustments (id, do_no, field, old_value, new_value, reason, adjusted_by, adjusted_at) FROM stdin;
1	23636	do_date	\N	2026-06-09	Re-OCR of scan p3: date clearly reads 09/06/26 (was blank in backfill)	claude re-ocr 24Jul2026	2026-07-24 15:45:07.605862+00
12	43109	net_kg	3630	3600	3600	admin	2026-07-31 01:21:02.314872+00
13	43109	net_kg	3630	3630	Revert test adjustment (console Adjust verification) - back to original weighed value	legacy-key	2026-07-31 01:34:17.543742+00
14	26065	net_kg	7710	7700	Weight correction (operator console)	admin	2026-07-31 04:39:04.888932+00
15	26065	net_kg	7710	7710	Weight correction (operator console)	admin	2026-07-31 04:40:11.173156+00
\.


--
-- Data for Name: app_state; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.app_state (id, state, rev, updated_at) FROM stdin;
1	{"rev": 237, "seq": {"do": 1, "job": 117, "vdo": 17921, "trip": 63, "ticket": 55}, "bins": [{"no": "5028", "size": "5 ft", "source": "seed", "status": "yard", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5038", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5044", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5046", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5047", "size": "5 ft", "source": "seed", "status": "client", "siteIdx": 0, "clientId": "cmrkt9189j9t", "firstSeen": "2026-07-14"}, {"no": "5051", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5056", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5057", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5058", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5060", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5064", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5069", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5073", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5079", "size": "5 ft", "source": "seed", "status": "client", "siteIdx": 0, "clientId": "cmrkt918as3h", "firstSeen": "2026-07-14"}, {"no": "5081", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5083", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5084", "size": "5 ft", "source": "seed", "status": "yard", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5086", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5089", "size": "5 ft", "source": "seed", "status": "yard", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5092", "size": "5 ft", "source": "seed", "status": "client", "siteIdx": 0, "clientId": "cmrkt918eg0z", "firstSeen": "2026-07-14"}, {"no": "5096", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5106", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5108", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5116", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5123", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5135", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5142", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5147", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5151", "size": "5 ft", "source": "seed", "status": "client", "siteIdx": 0, "clientId": "cmrkt9189chy", "firstSeen": "2026-07-14"}, {"no": "5153", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5160", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5162", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5169", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5176", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5194", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5196", "size": "5 ft", "source": "seed", "status": "client", "siteIdx": 3, "clientId": "cmrkt918aco2", "firstSeen": "2026-07-14"}, {"no": "5197", "size": "5 ft", "source": "seed", "status": "client", "siteIdx": 0, "clientId": "c1", "firstSeen": "2026-07-14"}, {"no": "5198", "size": "5 ft", "source": "seed", "status": "client", "siteIdx": 8, "clientId": "cmrkt91888e3", "firstSeen": "2026-07-14"}, {"no": "5199", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5203", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5204", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5210", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5211", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5213", "size": "5 ft", "source": "seed", "status": "client", "siteIdx": 0, "clientId": "cmrkt918ag06", "firstSeen": "2026-07-14"}, {"no": "5217", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5220", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5221", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5222", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5232", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5239", "size": "5 ft", "source": "seed", "status": "yard", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5240", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5245", "size": "5 ft", "source": "seed", "status": "client", "siteIdx": 0, "clientId": "cmrkt918auof", "firstSeen": "2026-07-14"}, {"no": "5247", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "7006", "size": "7 ft", "source": "seed", "status": "yard", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "7016", "size": "7 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "7017", "size": "7 ft", "source": "seed", "status": "client", "siteIdx": 3, "clientId": "c2", "firstSeen": "2026-07-14"}, {"no": "7022", "size": "7 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "8007", "size": "7 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "L802", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "L806", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "L807", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "L808", "size": "5 ft", "source": "seed", "status": "yard", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "L809", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "R08", "size": "5 ft", "source": "driver", "status": "client", "siteIdx": 0, "clientId": "c1", "firstSeen": "2026-07-14"}, {"no": "Y111", "size": "5 ft", "source": "driver", "status": "yard", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "L801", "size": "", "source": "driver", "status": "client", "siteIdx": 0, "clientId": "cmrkt91878od", "firstSeen": "2026-07-15"}, {"no": "L805", "size": "", "source": "driver", "status": "yard", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-15"}, {"no": "L53", "size": "", "source": "driver", "status": "client", "siteIdx": 0, "clientId": "cmrkt91878od", "firstSeen": "2026-07-15"}, {"no": "5109", "size": "5 ft", "source": "driver", "status": "client", "siteIdx": 2, "clientId": "cmrkt918ag06", "firstSeen": "2026-07-15"}, {"no": "5072", "size": "5 ft", "source": "driver", "status": "yard", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-15"}, {"no": "5070", "size": "5 ft", "source": "driver", "status": "client", "siteIdx": 1, "clientId": "cmrkt9189v5w", "firstSeen": "2026-07-15"}, {"no": "R13", "size": "7 ft", "source": "driver", "status": "yard", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-15"}, {"no": "5033", "size": "5 ft", "source": "driver", "status": "client", "siteIdx": 0, "clientId": "cmrkt9187x1k", "firstSeen": "2026-07-15"}, {"no": "5070号", "size": "5 ft", "source": "driver", "status": "client", "siteIdx": 1, "clientId": "cmrkt9189v5w", "firstSeen": "2026-07-15"}, {"no": "5193", "size": "5 ft", "source": "driver", "status": "client", "siteIdx": 1, "clientId": "cmrkt9189v5w", "firstSeen": "2026-07-15"}, {"no": "R21", "size": "7 ft", "source": "driver", "status": "yard", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-15"}, {"no": "8005", "size": "7 ft", "source": "driver", "status": "yard", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-16"}, {"no": "L57", "size": "5 ft", "source": "driver", "status": "yard", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-16"}, {"no": "5132", "size": "5 ft", "source": "driver", "status": "yard", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-16"}, {"no": "6002", "size": "5 ft", "source": "driver", "status": "yard", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-20"}, {"no": "L26", "size": "5 ft", "source": "driver", "status": "yard", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-27"}, {"no": "5098", "size": "5 ft", "source": "driver", "status": "yard", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-27"}, {"no": "L51", "size": "5 ft", "source": "driver", "status": "yard", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-27"}, {"no": "L46", "size": "5 ft", "source": "driver", "status": "yard", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-27"}, {"no": "8000", "size": "5 ft", "source": "driver", "status": "yard", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-27"}, {"no": "660L-TBD", "size": "660L", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-27"}, {"no": "R11", "size": "7 ft", "source": "driver", "status": "client", "siteIdx": 3, "clientId": "c2", "firstSeen": "2026-07-28"}, {"no": "6006", "size": "5 ft", "source": "driver", "status": "yard", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-29"}, {"no": "6005", "size": "5 ft", "source": "driver", "status": "yard", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-29"}, {"no": "L804", "size": "5 ft", "source": "driver", "status": "client", "siteIdx": 3, "clientId": "cmrkt9189hjd", "firstSeen": "2026-07-29"}, {"no": "R02", "size": "7 ft", "source": "driver", "status": "yard", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-29"}, {"no": "5224", "size": "5 ft", "source": "driver", "status": "yard", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-29"}, {"no": "L29", "size": "5 ft", "source": "driver", "status": "client", "siteIdx": 2, "clientId": "cmrkt918aco2", "firstSeen": "2026-07-30"}, {"no": "5 56", "size": "5 ft", "source": "driver", "status": "client", "siteIdx": 0, "clientId": "cmrkt918fl15", "firstSeen": "2026-07-31"}, {"no": "L24", "size": "5 ft", "source": "driver", "status": "yard", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-31"}, {"no": "3013", "size": "5 ft", "source": "driver", "status": "client", "siteIdx": 0, "clientId": "cms6sx0w2c6g", "firstSeen": "2026-07-31"}, {"no": "COMPACTOR", "size": "5 ft", "source": "driver", "status": "yard", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-31"}], "jobs": [{"id": 3, "date": "2026-07-15", "_addr": "48 Pandan Road L3", "_task": "Exchange", "price": 13, "waste": "General Waste", "dumpTo": "", "status": "done", "_client": "Poh Tiong Choon Logistics Ltd", "_driver": "Yao Jun", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 2, "_contact": "", "clientId": "cmrkt918ag06", "distance": 0, "driverId": 5, "createdAt": "2026-07-15T10:45", "startedAt": "10:46", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1784083566810, "instructions": ""}, {"id": 4, "date": "2026-07-14", "_addr": "79 Anson Road", "_task": "Exchange", "price": 18, "waste": "Wood Waste", "dumpTo": "", "status": "done", "_client": "HCG", "_driver": "Yao Jun", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 1, "_contact": "", "clientId": "cmrkt9189v5w", "distance": 0, "driverId": 5, "createdAt": "2026-07-14T13:07", "startedAt": "13:10", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1784092230111, "instructions": ""}, {"id": 5, "date": "2026-07-15", "_addr": "26 Loyang Drive", "_task": "Load", "price": 31, "waste": "General Waste", "dumpTo": "", "status": "done", "_client": "B&C Waste", "_driver": "Yao Jun", "binSize": "7 ft", "jobType": "Load", "siteIdx": 6, "_contact": "", "clientId": "cmrkt91878od", "distance": 0, "driverId": 5, "createdAt": "2026-07-15T14:47", "startedAt": "15:14", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1784099668422, "instructions": ""}, {"id": 6, "date": "2026-07-15", "_addr": "47A Jalan Buroh", "_task": "Exchange", "price": 13, "waste": "General Waste", "dumpTo": "", "status": "done", "_client": "Advanced Substrate Technologies Pte Ltd", "_driver": "Yao Jun", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 0, "_contact": "", "clientId": "cmrkt9187x1k", "distance": 0, "driverId": 5, "createdAt": "2026-07-15T15:10", "startedAt": "17:53", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1784109223975, "instructions": ""}, {"id": 7, "date": "2026-07-15", "_addr": "79 Anson Road", "_task": "Exchange", "price": 18, "waste": "General Waste", "dumpTo": "", "status": "done", "_client": "HCG", "_driver": "Yao Jun", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 1, "_contact": "", "clientId": "cmrkt9189v5w", "distance": 0, "driverId": 5, "createdAt": "2026-07-15T15:13", "startedAt": "18:52", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1784112771627, "instructions": ""}, {"id": 8, "date": "2026-07-15", "_addr": "54 Senoko Road", "_task": "Exchange", "price": 18, "waste": "General Waste", "dumpTo": "Lirich Resources Pte Ltd", "status": "assigned", "_client": "Calvary Carpentry Pte Ltd", "_driver": "Sathish", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 0, "_contact": "", "clientId": "cmrkt91889mm", "distance": 30, "driverId": 1, "createdAt": "2026-07-15T21:21", "contactIdx": 0, "surcharges": [], "instructions": "7:30-8:00am\\nContact - 86807640"}, {"id": 9, "date": "2026-07-15", "_addr": "46 Gul Drive", "_task": "Delivery", "price": 8, "waste": "Carton Boxes", "dumpTo": "Lirich Resources Pte Ltd", "status": "assigned", "_client": "Haid Biotechnology Industry (Singapore) Pte Ltd", "_driver": "Sathish", "binSize": "5 ft", "jobType": "Delivery", "siteIdx": 0, "_contact": "", "clientId": "cmrkt9189g55", "distance": 1.1, "driverId": 1, "createdAt": "2026-07-15T21:23", "contactIdx": 0, "surcharges": [], "instructions": ""}, {"id": 10, "date": "2026-07-15", "_addr": "46 Gul Drive", "_task": "Collect", "price": 13, "waste": "Carton Boxes", "dumpTo": "Lirich Resources Pte Ltd", "status": "in_progress", "_client": "Haid Biotechnology Industry (Singapore) Pte Ltd", "_driver": "Sathish", "binSize": "5 ft", "jobType": "Collect", "siteIdx": 0, "_contact": "", "clientId": "cmrkt9189g55", "distance": 1.1, "driverId": 1, "createdAt": "2026-07-15T21:24", "startedAt": "17:51", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1784281884954, "instructions": "Collect bin 10:00am"}, {"id": 11, "date": "2026-07-15", "_addr": "Benoi", "_task": "Exchange", "price": 13, "waste": "General Waste", "dumpTo": "Lirich Resources Pte Ltd", "status": "in_progress", "_client": "ST", "_driver": "Sathish", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 1, "_contact": "", "clientId": "cmrkt918dn4k", "distance": 2.3, "driverId": 1, "createdAt": "2026-07-15T21:26", "startedAt": "19:21", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1784287270474, "instructions": ""}, {"id": 12, "date": "2026-07-15", "_addr": "6 Chin Bee Ave L5", "_task": "Exchange", "price": 13, "waste": "General Waste", "dumpTo": "Lirich Resources Pte Ltd", "status": "in_progress", "_client": "Shin Ya O Ya Pte Ltd", "_driver": "Sathish", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 0, "_contact": "", "clientId": "cmrkt918dq77", "distance": 0, "driverId": 1, "createdAt": "2026-07-15T21:28", "startedAt": "14:41", "contactIdx": 0, "surcharges": [], "instructions": ""}, {"id": 13, "date": "2026-07-15", "_addr": "6 Chin Bee Ave L5", "_task": "Exchange", "price": 13, "waste": "General Waste", "dumpTo": "Lirich Resources Pte Ltd", "status": "done", "_client": "Shin Ya O Ya Pte Ltd", "_driver": "Yao Jun", "binSize": "7 ft", "jobType": "Exchange", "siteIdx": 0, "_contact": "", "clientId": "cmrkt918dq77", "distance": 0, "driverId": 5, "createdAt": "2026-07-15T22:25", "startedAt": "22:59", "contactIdx": 0, "surcharges": ["after7v"], "acceptedAtMs": 1784127557628, "instructions": ""}, {"id": 14, "date": "2026-07-15", "_addr": "8 Pandan Crescent", "_task": "Exchange", "price": 13, "waste": "General Waste", "dumpTo": "Lirich Resources Pte Ltd", "status": "done", "_client": "ASL Proworld Solution Pte Ltd", "_driver": "Yao Jun", "binSize": "7 ft", "jobType": "Exchange", "siteIdx": 0, "_contact": "", "clientId": "cmrkt9187ws7", "distance": 13.1, "driverId": 5, "createdAt": "2026-07-15T22:46", "startedAt": "08:45", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1784162742439, "instructions": "PIC - Jun Hong 88894769"}, {"id": 15, "date": "2026-07-15", "_addr": "60 Benoi Road", "_task": "Exchange", "price": 13, "waste": "General Waste", "dumpTo": "Lirich Resources Pte Ltd", "status": "done", "_client": "EverTeam Pte Ltd", "_driver": "Yao Jun", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 0, "_contact": "", "clientId": "cmrkt9189j9t", "distance": 1.9, "driverId": 5, "createdAt": "2026-07-15T22:48", "startedAt": "09:59", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1784167147780, "instructions": "PIC - Anwar 80792542"}, {"id": 16, "date": "2026-07-15", "_addr": "5 Jalan Samulun", "_task": "Exchange", "price": 13, "waste": "General Waste", "dumpTo": "Lirich Resources Pte Ltd", "status": "assigned", "_client": "PaxOcean Singapore Pte Ltd", "_driver": "Liu", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 0, "_contact": "", "clientId": "cmrkt918askd", "distance": 4.6, "driverId": 4, "createdAt": "2026-07-15T22:52", "contactIdx": 0, "surcharges": [], "instructions": "Morning \\nMuthu- 84553465"}, {"id": 17, "date": "2026-07-15", "_addr": "5 Jalan Samulun", "_task": "Exchange", "price": 13, "waste": "General Waste", "dumpTo": "Lirich Resources Pte Ltd", "status": "assigned", "_client": "PaxOcean Singapore Pte Ltd", "_driver": "Liu", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 0, "_contact": "", "clientId": "cmrkt918askd", "distance": 4.6, "driverId": 4, "createdAt": "2026-07-15T22:53", "contactIdx": 0, "surcharges": [], "instructions": "Afternoon\\nMuthu- 84553465"}, {"id": 18, "date": "2026-07-15", "_addr": "6 Tuas South Street 15", "_task": "Exchange", "price": 13, "waste": "General Waste", "dumpTo": "Lirich Resources Pte Ltd", "status": "assigned", "_client": "ST", "_driver": "Liu", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 0, "_contact": "", "clientId": "cmrkt918dn4k", "distance": 8.4, "driverId": 4, "createdAt": "2026-07-15T22:55", "contactIdx": 0, "surcharges": [], "instructions": "Rate will change in the system $19.50"}, {"id": 19, "date": "2026-07-15", "_addr": "Peck Seah Street", "_task": "Exchange", "price": 23, "waste": "General Waste", "dumpTo": "", "status": "assigned", "_client": "B&C Waste", "_driver": "Liu", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 4, "_contact": "", "clientId": "cmrkt91878od", "distance": 26.7, "driverId": 4, "createdAt": "2026-07-15T22:58", "contactIdx": 0, "surcharges": [], "instructions": "Call 1 hour before go\\nAvoid.lunch time 12pm-1pm\\nAnamul- 85236820"}, {"id": 20, "date": "2026-07-16", "_addr": "79 Anson Road", "_task": "Exchange", "price": 18, "waste": "General Waste", "dumpTo": "HCG Environmental Pte Ltd", "status": "done", "_client": "HCG", "_driver": "Yao Jun", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 1, "_contact": "", "clientId": "cmrkt9189v5w", "distance": 32, "driverId": 5, "createdAt": "2026-07-16T09:35", "startedAt": "14:32", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1784183568667, "instructions": "Trip rate is $23"}, {"id": 21, "date": "2026-07-16", "_addr": "79 Anson Road", "_task": "Exchange", "price": 18, "waste": "General Waste", "dumpTo": "HCG Environmental Pte Ltd", "status": "done", "_client": "HCG", "_driver": "Yao Jun", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 1, "_contact": "", "clientId": "cmrkt9189v5w", "distance": 32, "driverId": 5, "createdAt": "2026-07-16T09:37", "startedAt": "10:43", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1784169791187, "instructions": "Trip rate is $23"}, {"id": 22, "date": "2026-07-16", "_addr": "13 Kian Teck Crescent", "_task": "Exchange", "price": 13, "waste": "General Waste", "dumpTo": "Lirich Resources Pte Ltd", "status": "in_progress", "_client": "WIKA Instrumentation Pte Ltd", "_driver": "Kumar", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 0, "_contact": "", "clientId": "cmrkt918fsbo", "distance": 3.8, "driverId": 3, "createdAt": "2026-07-16T13:56", "startedAt": "22:35", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1784212514524, "instructions": ""}, {"id": 23, "date": "2026-07-17", "_addr": "9 Gul Circle", "_task": "Exchange", "price": 13, "waste": "Carton Boxes", "dumpTo": "", "status": "void", "_client": "Eng Lee Logistics Pte Ltd", "_driver": "Sathish", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 0, "_contact": "Jacky", "clientId": "c1", "distance": 0, "driverId": 1, "createdAt": "2026-07-17T17:35", "contactIdx": 0, "surcharges": [], "instructions": ""}, {"id": 24, "date": "2026-07-17", "_addr": "9 Gul Circle", "_task": "Exchange", "price": 13, "waste": "Carton Boxes", "dumpTo": "", "status": "void", "_client": "Eng Lee Logistics Pte Ltd", "_driver": "Sathish", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 0, "_contact": "Jacky", "clientId": "c1", "distance": 0, "driverId": 1, "createdAt": "2026-07-17T19:21", "startedAt": "19:22", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1784287355671, "instructions": ""}, {"id": 25, "date": "2026-07-17", "_addr": "9 Gul Circle", "_task": "Exchange", "price": 13, "waste": "Carton Boxes", "dumpTo": "", "status": "in_progress", "_client": "Eng Lee Logistics Pte Ltd", "_driver": "Test Driver", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 0, "_contact": "Jacky", "clientId": "c1", "distance": 0, "driverId": 6, "createdAt": "2026-07-17T20:52", "startedAt": "20:52", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1784292770918, "instructions": ""}, {"id": 26, "date": "2026-07-17", "_addr": "15 Tuas Ave 8", "_task": "Exchange", "price": 13, "waste": "Carton Boxes", "dumpTo": "", "status": "in_progress", "_client": "Eng Lee Logistics Pte Ltd", "_driver": "Test Driver", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 1, "_contact": "Jacky", "clientId": "c1", "distance": 0, "driverId": 6, "createdAt": "2026-07-17T21:25", "startedAt": "21:25", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1784294732895, "instructions": ""}, {"id": 27, "date": "2026-07-17", "_addr": "9 Gul Circle", "_task": "Exchange", "price": 13, "waste": "Carton Boxes", "dumpTo": "Asia Recycling Resources Pte Ltd", "status": "void", "_client": "Eng Lee Logistics Pte Ltd", "_driver": "Sathish", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 0, "_contact": "Jacky", "clientId": "c1", "distance": 1.2, "driverId": 1, "createdAt": "2026-07-17T21:36", "contactIdx": 0, "surcharges": [], "instructions": ""}, {"id": 28, "date": "2026-07-17", "_addr": "9 Gul Circle", "_task": "Exchange", "price": 13, "waste": "Carton Boxes", "dumpTo": "", "status": "in_progress", "_client": "Eng Lee Logistics Pte Ltd", "_driver": "Test Driver", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 0, "_contact": "Jacky", "clientId": "c1", "distance": 0, "driverId": 6, "createdAt": "2026-07-17T21:37", "startedAt": "21:38", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1784295480487, "instructions": ""}, {"id": 29, "date": "2026-07-18", "_addr": "5 Sungei Kadut Street 6", "_task": "Dump", "price": 18, "waste": "Wood Waste", "dumpTo": "Bee Joo", "status": "assigned", "_client": "Beejoo", "_driver": "Sathish", "binSize": "5 ft", "jobType": "Dump", "siteIdx": 0, "_contact": "", "clientId": "cmrkt9187viy", "distance": 0, "driverId": 1, "createdAt": "2026-07-17T22:00", "contactIdx": 0, "surcharges": [], "instructions": ""}, {"id": 30, "date": "2026-07-20", "_addr": "5 Sungei Kadut Street 6", "_task": "Dump", "price": 18, "waste": "Wood Waste", "dumpTo": "Bee Joo", "status": "assigned", "_client": "Beejoo", "_driver": "Liu", "binSize": "7 ft", "jobType": "Dump", "siteIdx": 0, "_contact": "", "clientId": "cmrkt9187viy", "distance": 0, "driverId": 4, "createdAt": "2026-07-19T20:46", "contactIdx": 0, "surcharges": [], "instructions": ""}, {"id": 31, "date": "2026-07-20", "_addr": "1 Tuas View Place, Westlink One, #02-01", "_task": "Delivery", "price": 8, "waste": "General Waste", "dumpTo": "", "status": "assigned", "_client": "Epont Building Services Pte Ltd", "_driver": "Liu", "binSize": "5 ft", "jobType": "Delivery", "siteIdx": 0, "_contact": "", "clientId": "cmrkt9189ewq", "distance": 0, "driverId": 4, "createdAt": "2026-07-19T20:48", "contactIdx": 0, "surcharges": [], "instructions": ""}, {"id": 32, "date": "2026-07-19", "_addr": "5 Sungei Kadut Street 6", "_task": "Dump", "price": 18, "waste": "Wood Waste", "dumpTo": "Bee Joo", "status": "done", "_client": "Beejoo", "_driver": "Yao Jun", "binSize": "7 ft", "jobType": "Dump", "siteIdx": 0, "_contact": "", "clientId": "cmrkt9187viy", "distance": 0, "driverId": 5, "createdAt": "2026-07-19T20:49", "startedAt": "07:50", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1784505051464, "instructions": ""}, {"id": 33, "date": "2026-07-20", "_addr": "Benoi", "_task": "Exchange", "price": 19.5, "waste": "General Waste", "dumpTo": "Lirich Resources Pte Ltd", "status": "done", "_client": "ST", "_driver": "Yao Jun", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 1, "_contact": "", "clientId": "cmrkt918dn4k", "distance": 2.3, "driverId": 5, "createdAt": "2026-07-19T20:50", "startedAt": "09:21", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1784510460438, "instructions": ""}, {"id": 34, "date": "2026-07-20", "_addr": "5 Sungei Kadut Street 6", "_task": "Dump", "price": 18, "waste": "Wood Waste", "dumpTo": "Bee Joo", "status": "in_progress", "_client": "Beejoo", "_driver": "Kumar", "binSize": "7 ft", "jobType": "Dump", "siteIdx": 0, "_contact": "", "clientId": "cmrkt9187viy", "distance": 0, "driverId": 3, "createdAt": "2026-07-19T20:52", "startedAt": "23:24", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1785338667709, "instructions": ""}, {"id": 35, "date": "2026-07-20", "_addr": "118 Pioneer Rd L1", "_task": "Delivery", "price": 8, "waste": "General Waste", "dumpTo": "", "status": "in_progress", "_client": "Radha Exports Pte Ltd", "_driver": "Kumar", "binSize": "7 ft", "jobType": "Delivery", "siteIdx": 0, "_contact": "Radha", "clientId": "c2", "distance": 0, "driverId": 3, "createdAt": "2026-07-19T20:53", "startedAt": "23:25", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1785338738743, "instructions": ""}, {"id": 36, "date": "2026-07-20", "_addr": "61a Tuas Nexus Drive", "_task": "Exchange", "price": 13, "waste": "General Waste", "dumpTo": "Lirich Resources Pte Ltd", "status": "in_progress", "_client": "ST", "_driver": "Kumar", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 3, "_contact": "", "clientId": "cmrkt918dn4k", "distance": 7, "driverId": 3, "createdAt": "2026-07-19T20:54", "startedAt": "23:26", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1785338800605, "instructions": ""}, {"id": 37, "date": "2026-07-20", "_addr": "5 Sungei Kadut Street 6", "_task": "Dump", "price": 18, "waste": "Wood Waste", "dumpTo": "Bee Joo", "status": "assigned", "_client": "Beejoo", "_driver": "Sathish", "binSize": "7 ft", "jobType": "Dump", "siteIdx": 0, "_contact": "", "clientId": "cmrkt9187viy", "distance": 0, "driverId": 1, "createdAt": "2026-07-19T20:56", "contactIdx": 0, "surcharges": [], "instructions": ""}, {"id": 38, "date": "2026-07-20", "_addr": "5 Jalan Samulun", "_task": "Exchange", "price": 13, "waste": "General Waste", "dumpTo": "Lirich Resources Pte Ltd", "status": "assigned", "_client": "PaxOcean Singapore Pte Ltd", "_driver": "Sathish", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 0, "_contact": "", "clientId": "cmrkt918askd", "distance": 4.6, "driverId": 1, "createdAt": "2026-07-19T20:57", "contactIdx": 0, "surcharges": [], "instructions": "Morning"}, {"id": 39, "date": "2026-07-20", "_addr": "5 Jalan Samulun", "_task": "Exchange", "price": 13, "waste": "General Waste", "dumpTo": "Lirich Resources Pte Ltd", "status": "assigned", "_client": "PaxOcean Singapore Pte Ltd", "_driver": "Sathish", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 0, "_contact": "", "clientId": "cmrkt918askd", "distance": 4.6, "driverId": 1, "createdAt": "2026-07-19T20:58", "contactIdx": 0, "surcharges": [], "instructions": "Afternoon"}, {"id": 40, "date": "2026-07-20", "_addr": "5 Sungei Kadut Street 6", "_task": "Dump", "price": 18, "waste": "Wood Waste", "dumpTo": "Bee Joo", "status": "assigned", "_client": "Beejoo", "_driver": "Karthik", "binSize": "5 ft", "jobType": "Dump", "siteIdx": 0, "_contact": "", "clientId": "cmrkt9187viy", "distance": 0, "driverId": 2, "createdAt": "2026-07-19T20:59", "contactIdx": 0, "surcharges": [], "instructions": ""}, {"id": 41, "date": "2026-07-20", "_addr": "46 Gul Drive", "_task": "Exchange", "price": 13, "waste": "General Waste", "dumpTo": "Lirich Resources Pte Ltd", "status": "assigned", "_client": "Haid Biotechnology Industry (Singapore) Pte Ltd", "_driver": "Karthik", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 0, "_contact": "", "clientId": "cmrkt9189g55", "distance": 1.1, "driverId": 2, "createdAt": "2026-07-19T21:01", "contactIdx": 0, "surcharges": [], "instructions": "Exchange 660L Bin"}, {"id": 42, "date": "2026-07-20", "_addr": "Gul", "_task": "Exchange", "price": 19.5, "waste": "General Waste", "dumpTo": "Lirich Resources Pte Ltd", "status": "assigned", "_client": "ST", "_driver": "Karthik", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 2, "_contact": "", "clientId": "cmrkt918dn4k", "distance": 0.4, "driverId": 2, "createdAt": "2026-07-19T21:02", "contactIdx": 0, "surcharges": [], "instructions": ""}, {"id": 43, "date": "2026-07-25", "_addr": "9 Gul Circle", "_task": "Exchange", "_test": true, "price": 13, "waste": "General Waste", "dumpTo": "", "status": "done", "_client": "Eng Lee Logistics Pte Ltd", "_driver": "Test Driver", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 0, "_contact": "Jacky", "clientId": "c1", "distance": 0, "driverId": 6, "createdAt": "2026-07-25T03:04", "startedAt": "03:04", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1784919884770, "instructions": ""}, {"id": 46, "date": "2026-07-27", "_addr": "2 Woodlands Sector 1, #05-18", "_task": "Exchange", "price": 18, "waste": "General Waste", "dumpTo": "Lirich Resources Pte Ltd", "status": "void", "_client": "Sys-Mac Automation Engineering Pte Ltd", "_driver": "Yao Jun", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 0, "_contact": "", "clientId": "cmrkt918eg0z", "distance": 30, "driverId": 5, "voidedOn": "2026-07-29", "_bydriver": true, "_voidedBy": "Yao Jun", "createdAt": "2026-07-27T14:39", "startedAt": "14:39", "contactIdx": 0, "surcharges": [], "_voidReason": "Client cancelled", "acceptedAtMs": 1785134390158, "instructions": ""}, {"id": 47, "date": "2026-07-27", "_addr": "2 Woodlands Sector 1, #05-18", "_task": "Delivery", "price": 8, "waste": "General Waste", "dumpTo": "", "status": "done", "_client": "Sys-Mac Automation Engineering Pte Ltd", "_driver": "Yao Jun", "binSize": "5 ft", "jobType": "Delivery", "siteIdx": 0, "_contact": "", "clientId": "cmrkt918eg0z", "distance": 0, "driverId": 5, "_bydriver": true, "createdAt": "2026-07-27T14:40", "startedAt": "14:40", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1785134455812, "instructions": ""}, {"id": 48, "date": "2026-07-27", "_addr": "28A Penjuru Close Bin Centre", "_task": "Exchange", "price": 13, "waste": "General Waste", "dumpTo": "Lirich Resources Pte Ltd", "status": "done", "_client": "Eng Leng Contractors Pte Ltd", "_driver": "Yao Jun", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 4, "_contact": "", "clientId": "cmrkt91888e3", "distance": 0, "driverId": 5, "_bydriver": true, "createdAt": "2026-07-27T14:43", "startedAt": "14:43", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1785134605462, "instructions": ""}, {"id": 49, "date": "2026-07-27", "_addr": "Pandan Loop, Blk K, (Phase 1), Bin Centre", "_task": "Exchange", "price": 13, "waste": "General Waste", "dumpTo": "Lirich Resources Pte Ltd", "status": "done", "_client": "Eng Leng Contractors Pte Ltd", "_driver": "Yao Jun", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 8, "_contact": "", "clientId": "cmrkt91888e3", "distance": 0, "driverId": 5, "_bydriver": true, "createdAt": "2026-07-27T15:45", "startedAt": "15:45", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1785138356571, "instructions": ""}, {"id": 50, "date": "2026-07-27", "_addr": "5 Gul Drive", "_task": "Exchange", "price": 13, "waste": "General Waste", "dumpTo": "Lirich Resources Pte Ltd", "status": "done", "_client": "Qualicoat Pte Ltd", "_driver": "Yao Jun", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 0, "_contact": "", "clientId": "cmrkt918a8k1", "distance": 0.5, "driverId": 5, "_bydriver": true, "createdAt": "2026-07-27T15:50", "startedAt": "17:52", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1785145936778, "instructions": ""}, {"id": 51, "date": "2026-07-27", "_addr": "79 Anson Road", "_task": "Exchange", "price": 18, "waste": "General Waste", "dumpTo": "", "status": "done", "_client": "HCG", "_driver": "Yao Jun", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 1, "_contact": "", "clientId": "cmrkt9189v5w", "distance": 0, "driverId": 5, "_bydriver": true, "createdAt": "2026-07-27T17:54", "startedAt": "17:54", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1785146080042, "instructions": ""}, {"id": 52, "date": "2026-07-27", "_addr": "Gul", "_task": "Exchange", "price": 19.5, "waste": "General Waste", "dumpTo": "", "status": "done", "_client": "ST", "_driver": "Yao Jun", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 2, "_contact": "", "clientId": "cmrkt918dn4k", "distance": 0, "driverId": 5, "_bydriver": true, "createdAt": "2026-07-27T17:56", "startedAt": "17:56", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1785146176560, "instructions": ""}, {"id": 53, "date": "2026-07-27", "_addr": "11 Pioneer Turn L601", "_task": "Exchange", "price": 13, "waste": "General Waste", "dumpTo": "", "status": "done", "_client": "Savills Property Management Pte Ltd (Green Hub)", "_driver": "Yao Jun", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 3, "_contact": "", "clientId": "cmrkt918aco2", "distance": 0, "driverId": 5, "_bydriver": true, "createdAt": "2026-07-27T17:58", "startedAt": "18:26", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1785147961672, "instructions": ""}, {"id": 54, "date": "2026-07-28", "_addr": "Wood Waste", "_task": "Dump", "price": 13, "waste": "General Waste", "dumpTo": "Bee Joo", "status": "void", "_client": "Lirich", "_driver": "Yao Jun", "binSize": "5 ft", "jobType": "Dump", "siteIdx": 0, "_contact": "", "clientId": "cmrkt918ar8i", "distance": 0, "driverId": 5, "voidedOn": "2026-07-29", "_voidedBy": "Yao Jun", "createdAt": "2026-07-27T00:37", "startedAt": "08:42", "contactIdx": 0, "surcharges": [], "_voidReason": "Client cancelled", "acceptedAtMs": 1785199336049, "instructions": "Early Morning"}, {"id": 55, "date": "2026-07-28", "_addr": "Gul", "_task": "Exchange", "price": 19.5, "waste": "General Waste", "dumpTo": "", "status": "void", "_client": "ST", "_driver": "Yao Jun", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 2, "_contact": "", "clientId": "cmrkt918dn4k", "distance": 0, "driverId": 5, "voidedOn": "2026-07-29", "_voidedBy": "Yao Jun", "createdAt": "2026-07-27T00:38", "startedAt": "12:56", "contactIdx": 0, "surcharges": [], "_voidReason": "Client cancelled", "acceptedAtMs": 1785214580838, "instructions": "Exchange Bin"}, {"id": 56, "date": "2026-07-28", "_addr": "46 Gul Drive", "_task": "Collect", "price": 13, "waste": "General Waste", "dumpTo": "", "status": "assigned", "_client": "Haid Biotechnology Industry (Singapore) Pte Ltd", "_driver": "Karthik", "binSize": "660L", "jobType": "Collect", "siteIdx": 0, "_contact": "", "clientId": "cmrkt9189g55", "distance": 0, "driverId": 2, "createdAt": "2026-07-27T01:58", "contactIdx": 0, "surcharges": [], "instructions": "Use REL to collect 1 x 660L."}, {"id": 57, "date": "2026-07-28", "_addr": "23 Jurong Port Road", "_task": "Exchange", "price": 13, "waste": "General Waste", "dumpTo": "", "status": "assigned", "_client": "Mecom GreenBuild (Singapore) Pte Ltd", "_driver": "Karthik", "binSize": "660L", "jobType": "Exchange", "siteIdx": 0, "_contact": "", "clientId": "cmrkt918aw4z", "distance": 0, "driverId": 2, "createdAt": "2026-07-27T01:59", "contactIdx": 0, "surcharges": [], "instructions": "Use REL to collect 1 x 660L."}, {"id": 58, "date": "2026-07-28", "_addr": "501 Old Choa Chu Kang Road, Home Team Academy", "_task": "Exchange", "price": 18, "waste": "General Waste", "dumpTo": "", "status": "assigned", "_client": "CBM Pte Ltd", "_driver": "Karthik", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 0, "_contact": "", "clientId": "cmrkt9188fou", "distance": 0, "driverId": 2, "createdAt": "2026-07-27T02:06", "contactIdx": 0, "surcharges": [], "instructions": "Exchange 1 x 5ft.\\nRizab 8019 5329"}, {"id": 59, "date": "2026-07-28", "_addr": "Others", "_task": "Delivery", "price": 8, "waste": "General Waste", "dumpTo": "", "status": "assigned", "_client": "SLS", "_driver": "Liu", "binSize": "5 ft", "jobType": "Delivery", "siteIdx": 2, "_contact": "", "clientId": "cmrkt918diax", "distance": 0, "driverId": 4, "createdAt": "2026-07-28T02:15", "contactIdx": 0, "surcharges": [], "instructions": "Deliver 1 x 5ft OTC to 16 Benoi Road, ST Marine.\\nVenkatesh 92200324."}, {"id": 60, "date": "2026-07-28", "_addr": "46 Gul Drive", "_task": "Exchange", "price": 13, "waste": "General Waste", "dumpTo": "", "status": "assigned", "_client": "Haid Biotechnology Industry (Singapore) Pte Ltd", "_driver": "Liu", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 0, "_contact": "", "clientId": "cmrkt9189g55", "distance": 0, "driverId": 4, "createdAt": "2026-07-28T02:18", "contactIdx": 0, "surcharges": [], "instructions": "10-10.30am.\\n46 Gul Drive.\\n- Issue 1 x 5ft bin for woven. \\n- Collect back 1 hour later. \\nYvonne 89101994"}, {"id": 61, "date": "2026-07-28", "_addr": "8 Buroh Street", "_task": "Exchange", "price": 13, "waste": "General Waste", "dumpTo": "", "status": "assigned", "_client": "Eng Leng Contractors Pte Ltd", "_driver": "Liu", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 5, "_contact": "", "clientId": "cmrkt91888e3", "distance": 0, "driverId": 4, "createdAt": "2026-07-28T02:20", "contactIdx": 0, "surcharges": [], "instructions": "Exchange 1x 5ft.\\nEzwan 98644193"}, {"id": 62, "date": "2026-07-28", "_addr": "Wood Waste", "_task": "Dump", "price": 13, "waste": "Wood Waste", "dumpTo": "Bee Joo", "status": "assigned", "_client": "Lirich", "_driver": "Sathish", "binSize": "5 ft", "jobType": "Dump", "siteIdx": 0, "_contact": "", "clientId": "cmrkt918ar8i", "distance": 0, "driverId": 1, "createdAt": "2026-07-28T02:22", "contactIdx": 0, "surcharges": [], "instructions": "Early morning.\\nLirich Yard.\\nDump wood to BeeJoo."}, {"id": 63, "date": "2026-07-28", "_addr": "32 Jurong Port Road, Heritage Center", "_task": "Exchange", "price": 13, "waste": "General Waste", "dumpTo": "", "status": "assigned", "_client": "Engie Services Singapore Pte Ltd", "_driver": "Sathish", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 8, "_contact": "", "clientId": "cmrkt918885s", "distance": 0, "driverId": 1, "createdAt": "2026-07-28T02:23", "contactIdx": 0, "surcharges": [], "instructions": "Exchange 1 x 5ft.\\nSunder 8267 7685."}, {"id": 64, "date": "2026-07-28", "_addr": "Others", "_task": "Sell", "price": 13, "waste": "General Waste", "dumpTo": "", "status": "assigned", "_client": "Lirich", "_driver": "Sathish", "binSize": "5 ft", "jobType": "Sell", "siteIdx": 0, "_contact": "", "clientId": "cmrkt918ar8i", "distance": 0, "driverId": 1, "createdAt": "2026-07-28T02:23", "contactIdx": 0, "surcharges": [], "instructions": "Sell Mooring Rope."}, {"id": 65, "date": "2026-07-28", "_addr": "5 Jalan Samulun", "_task": "Exchange", "price": 13, "waste": "General Waste", "dumpTo": "", "status": "assigned", "_client": "PaxOcean Singapore Pte Ltd", "_driver": "Kumar", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 0, "_contact": "", "clientId": "cmrkt918askd", "distance": 0, "driverId": 3, "createdAt": "2026-07-28T02:25", "contactIdx": 0, "surcharges": [], "instructions": "Morning\\nExchange 1 x 5ft.\\nMuthu 8455 3465."}, {"id": 66, "date": "2026-07-28", "_addr": "5 Jalan Samulun", "_task": "Exchange", "price": 13, "waste": "General Waste", "dumpTo": "", "status": "assigned", "_client": "PaxOcean Singapore Pte Ltd", "_driver": "Kumar", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 0, "_contact": "", "clientId": "cmrkt918askd", "distance": 0, "driverId": 3, "createdAt": "2026-07-28T02:26", "contactIdx": 0, "surcharges": [], "instructions": "Afternoon.\\nExchange 1 x 5ft.\\nMuthu 8455 3465."}, {"id": 67, "date": "2026-07-28", "_addr": "Benoi", "_task": "Exchange", "price": 19.5, "waste": "General Waste", "dumpTo": "", "status": "assigned", "_client": "ST", "_driver": "Kumar", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 1, "_contact": "", "clientId": "cmrkt918dn4k", "distance": 0, "driverId": 3, "createdAt": "2026-07-28T02:26", "contactIdx": 0, "surcharges": [], "instructions": ""}, {"id": 68, "date": "2026-07-28", "_addr": "5 Sungei Kadut Street 6", "_task": "Dump", "price": 18, "waste": "General Waste", "dumpTo": "", "status": "done", "_client": "Beejoo", "_driver": "Yao Jun", "binSize": "5 ft", "jobType": "Dump", "siteIdx": 0, "_contact": "", "clientId": "cmrkt9187viy", "distance": 0, "driverId": 5, "_bydriver": true, "createdAt": "2026-07-28T09:23", "startedAt": "09:23", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1785201809513, "instructions": ""}, {"id": 69, "date": "2026-07-28", "_addr": "118 Pioneer Road L7", "_task": "Exchange", "price": 13, "waste": "Wood Waste", "dumpTo": "", "status": "done", "_client": "Radha Exports Pte Ltd", "_driver": "Yao Jun", "binSize": "7 ft", "jobType": "Exchange", "siteIdx": 3, "_contact": "Radha", "clientId": "c2", "distance": 0, "driverId": 5, "_bydriver": true, "createdAt": "2026-07-28T10:01", "startedAt": "11:53", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1785210786199, "instructions": ""}, {"id": 70, "date": "2026-07-28", "_addr": "118 Pioneer Road L7", "_task": "Exchange", "price": 13, "waste": "Wood Waste", "dumpTo": "", "status": "done", "_client": "Radha Exports Pte Ltd", "_driver": "Yao Jun", "binSize": "7 ft", "jobType": "Exchange", "siteIdx": 3, "_contact": "Radha", "clientId": "c2", "distance": 0, "driverId": 5, "_bydriver": true, "createdAt": "2026-07-28T10:01", "startedAt": "11:06", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1785207997114, "instructions": ""}, {"id": 71, "date": "2026-07-29", "_addr": "60 Benoi Road", "_task": "Exchange", "price": 13, "waste": "General Waste", "dumpTo": "", "status": "done", "_client": "EverTeam Pte Ltd", "_driver": "Yao Jun", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 0, "_contact": "", "clientId": "cmrkt9189j9t", "distance": 0, "driverId": 5, "_bydriver": true, "createdAt": "2026-07-29T07:39", "startedAt": "07:39", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1785281998227, "instructions": ""}, {"id": 72, "date": "2026-07-29", "_addr": "Gul", "_task": "Exchange", "price": 19.5, "waste": "General Waste", "dumpTo": "", "status": "done", "_client": "ST", "_driver": "Yao Jun", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 2, "_contact": "", "clientId": "cmrkt918dn4k", "distance": 0, "driverId": 5, "_bydriver": true, "createdAt": "2026-07-29T15:59", "startedAt": "15:59", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1785311949328, "instructions": ""}, {"id": 73, "date": "2026-07-29", "_addr": "Gul", "_task": "Exchange", "price": 19.5, "waste": "Wood Waste", "dumpTo": "", "status": "done", "_client": "ST", "_driver": "Yao Jun", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 2, "_contact": "", "clientId": "cmrkt918dn4k", "distance": 0, "driverId": 5, "_bydriver": true, "createdAt": "2026-07-29T16:01", "startedAt": "16:01", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1785312078493, "instructions": ""}, {"id": 74, "date": "2026-07-29", "_addr": "Gul", "_task": "Exchange", "price": 19.5, "waste": "General Waste", "dumpTo": "", "status": "done", "_client": "ST", "_driver": "Yao Jun", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 2, "_contact": "", "clientId": "cmrkt918dn4k", "distance": 0, "driverId": 5, "_bydriver": true, "createdAt": "2026-07-29T16:02", "startedAt": "16:02", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1785312160754, "instructions": ""}, {"id": 75, "date": "2026-07-29", "_addr": "NEA Tuas", "_task": "Exchange", "price": 13, "waste": "General Waste", "dumpTo": "NEA", "status": "done", "_client": "NEA", "_driver": "Yao Jun", "binSize": "7 ft", "jobType": "Exchange", "siteIdx": 0, "_contact": "", "clientId": "cmrkt918ate4", "distance": 7.7, "driverId": 5, "_bydriver": true, "createdAt": "2026-07-29T16:04", "startedAt": "16:04", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1785312245751, "instructions": ""}, {"id": 76, "date": "2026-07-29", "_addr": "NEA Tuas", "_task": "Exchange", "price": 13, "waste": "General Waste", "dumpTo": "", "status": "done", "_client": "NEA", "_driver": "Yao Jun", "binSize": "7 ft", "jobType": "Exchange", "siteIdx": 0, "_contact": "", "clientId": "cmrkt918ate4", "distance": 0, "driverId": 5, "_bydriver": true, "createdAt": "2026-07-29T16:05", "startedAt": "16:05", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1785312325410, "instructions": ""}, {"id": 77, "date": "2026-07-29", "_addr": "Ophir Road LP 14/1F", "_task": "Exchange", "price": 23, "waste": "General Waste", "dumpTo": "", "status": "done", "_client": "GS Engineering and Construction Corporation", "_driver": "Yao Jun", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 3, "_contact": "", "clientId": "cmrkt9189hjd", "distance": 0, "driverId": 5, "_bydriver": true, "createdAt": "2026-07-29T16:06", "startedAt": "16:07", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1785312421081, "instructions": ""}, {"id": 78, "date": "2026-07-29", "_addr": "100 Beach Road", "_task": "Exchange", "price": 23, "waste": "General Waste", "dumpTo": "", "status": "done", "_client": "Hyundai Engineering & Construction Co., Ltd", "_driver": "Yao Jun", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 0, "_contact": "", "clientId": "cmrkt918azpz", "distance": 0, "driverId": 5, "_bydriver": true, "createdAt": "2026-07-29T16:08", "startedAt": "16:08", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1785312538394, "instructions": ""}, {"id": 79, "date": "2026-07-29", "_addr": "NEA Tuas", "_task": "Exchange", "price": 13, "waste": "General Waste", "dumpTo": "", "status": "done", "_client": "NEA", "_driver": "Yao Jun", "binSize": "7 ft", "jobType": "Exchange", "siteIdx": 0, "_contact": "", "clientId": "cmrkt918ate4", "distance": 0, "driverId": 5, "_bydriver": true, "createdAt": "2026-07-29T16:09", "startedAt": "17:06", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1785315997949, "instructions": ""}, {"id": 80, "date": "2026-07-29", "_addr": "80 Tuas West Drive", "_task": "Exchange", "price": 13, "waste": "General Waste", "dumpTo": "", "status": "done", "_client": "INVX Asia Pacific Pte Ltd", "_driver": "Yao Jun", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 0, "_contact": "", "clientId": "cmrkt918as3h", "distance": 0, "driverId": 5, "_bydriver": true, "createdAt": "2026-07-29T16:09", "startedAt": "19:01", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1785322902253, "instructions": ""}, {"id": 81, "date": "2026-07-30", "_addr": "5 Sungei Kadut Street 6", "_task": "Dump", "price": 18, "waste": "Wood Waste", "dumpTo": "Bee Joo", "status": "assigned", "_client": "Beejoo", "_driver": "Sathish", "binSize": "7 ft", "jobType": "Dump", "siteIdx": 0, "_contact": "", "clientId": "cmrkt9187viy", "distance": 0, "driverId": 1, "createdAt": "2026-07-29T23:02", "contactIdx": 0, "surcharges": [], "instructions": ""}, {"id": 82, "date": "2026-07-30", "_addr": "6 Chin Bee Ave L5", "_task": "Exchange", "price": 13, "waste": "General Waste", "dumpTo": "Lirich Resources Pte Ltd", "status": "in_progress", "_client": "Shin Ya O Ya Pte Ltd", "_driver": "Sathish", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 0, "_contact": "", "clientId": "cmrkt918dq77", "distance": 0, "driverId": 1, "createdAt": "2026-07-29T23:03", "startedAt": "11:44", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1785383097932, "instructions": ""}, {"id": 83, "date": "2026-07-30", "_addr": "2 Bukit Batok Street 24, #03-19 Skytech", "_task": "Delivery", "price": 8, "waste": "General Waste", "dumpTo": "Lirich Resources Pte Ltd", "status": "assigned", "_client": "Dyna Cool", "_driver": "Karthik", "binSize": "5 ft", "jobType": "Delivery", "siteIdx": 0, "_contact": "", "clientId": "cmrkt91880wf", "distance": 0, "driverId": 2, "createdAt": "2026-07-29T23:05", "contactIdx": 0, "surcharges": [], "instructions": "128 Tuas South Ave 3"}, {"id": 84, "date": "2026-07-30", "_addr": "48 Pandan Road L3", "_task": "Exchange", "price": 13, "waste": "General Waste", "dumpTo": "Lirich Resources Pte Ltd", "status": "in_progress", "_client": "Poh Tiong Choon Logistics Ltd", "_driver": "Karthik", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 2, "_contact": "", "clientId": "cmrkt918ag06", "distance": 0, "driverId": 2, "createdAt": "2026-07-29T23:06", "startedAt": "10:55", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1785380104971, "instructions": ""}, {"id": 85, "date": "2026-07-30", "_addr": "2 Bukit Batok Street 24, #03-19 Skytech", "_task": "Collect", "price": 13, "waste": "General Waste", "dumpTo": "Lirich Resources Pte Ltd", "status": "assigned", "_client": "Dyna Cool", "_driver": "Karthik", "binSize": "5 ft", "jobType": "Collect", "siteIdx": 0, "_contact": "", "clientId": "cmrkt91880wf", "distance": 0, "driverId": 2, "createdAt": "2026-07-29T23:08", "contactIdx": 0, "surcharges": [], "instructions": "128 Tuas South Ave 3"}, {"id": 86, "date": "2026-07-30", "_addr": "5 Sungei Kadut Street 6", "_task": "Dump", "price": 18, "waste": "Wood Waste", "dumpTo": "Bee Joo", "status": "done", "_client": "Beejoo", "_driver": "Yao Jun", "binSize": "7 ft", "jobType": "Dump", "siteIdx": 0, "_contact": "", "clientId": "cmrkt9187viy", "distance": 0, "driverId": 5, "createdAt": "2026-07-29T23:09", "startedAt": "04:35", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1785357335082, "instructions": ""}, {"id": 87, "date": "2026-07-30", "_addr": "Gul", "_task": "Exchange", "price": 19.5, "waste": "General Waste", "dumpTo": "Lirich Resources Pte Ltd", "status": "done", "_client": "ST", "_driver": "Yao Jun", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 2, "_contact": "", "clientId": "cmrkt918dn4k", "distance": 0.4, "driverId": 5, "createdAt": "2026-07-29T23:10", "startedAt": "10:29", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1785378545827, "instructions": ""}, {"id": 88, "date": "2026-07-30", "_addr": "46 Gul Drive", "_task": "Exchange", "price": 13, "waste": "General Waste", "dumpTo": "Lirich Resources Pte Ltd", "status": "in_progress", "_client": "Haid Biotechnology Industry (Singapore) Pte Ltd", "_driver": "Kumar", "binSize": "660L", "jobType": "Exchange", "siteIdx": 0, "_contact": "Yvonne", "clientId": "cmrkt9189g55", "distance": 1.1, "driverId": 3, "createdAt": "2026-07-29T23:11", "startedAt": "09:58", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1785376691740, "instructions": ""}, {"id": 89, "date": "2026-07-30", "_addr": "5 Jalan Samulun", "_task": "Exchange", "price": 13, "waste": "General Waste", "dumpTo": "Lirich Resources Pte Ltd", "status": "assigned", "_client": "PaxOcean Singapore Pte Ltd", "_driver": "Kumar", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 0, "_contact": "Muthu", "clientId": "cmrkt918askd", "distance": 4.6, "driverId": 3, "createdAt": "2026-07-29T23:12", "contactIdx": 0, "surcharges": ["sunph"], "instructions": "Morning trip"}, {"id": 90, "date": "2026-07-30", "_addr": "5 Jalan Samulun", "_task": "Exchange", "price": 13, "waste": "General Waste", "dumpTo": "Lirich Resources Pte Ltd", "status": "in_progress", "_client": "PaxOcean Singapore Pte Ltd", "_driver": "Kumar", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 0, "_contact": "Muthu", "clientId": "cmrkt918askd", "distance": 4.6, "driverId": 3, "createdAt": "2026-07-29T23:13", "startedAt": "09:52", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1785376357477, "instructions": "Afternoon trip"}, {"id": 91, "date": "2026-07-30", "_addr": "Benoi", "_task": "Exchange", "price": 19.5, "waste": "General Waste", "dumpTo": "Lirich Resources Pte Ltd", "status": "assigned", "_client": "ST", "_driver": "Kumar", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 1, "_contact": "", "clientId": "cmrkt918dn4k", "distance": 2.3, "driverId": 3, "createdAt": "2026-07-29T23:14", "contactIdx": 0, "surcharges": [], "instructions": ""}, {"id": 92, "date": "2026-07-30", "_addr": "31 Tuas West Drive, Lamppost 74F", "_task": "Exchange", "price": 13, "waste": "General Waste", "dumpTo": "", "status": "done", "_client": "Hyundai Engineering & Construction Co., Ltd", "_driver": "Yao Jun", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 1, "_contact": "Liton", "clientId": "cmrkt918azpz", "distance": 0, "driverId": 5, "_bydriver": true, "createdAt": "2026-07-30T09:00", "startedAt": "09:00", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1785373221523, "instructions": ""}, {"id": 93, "date": "2026-07-30", "_addr": "31 Tuas West Drive, Lamppost 74F", "_task": "Delivery", "price": 8, "waste": "General Waste", "dumpTo": "", "status": "done", "_client": "Hyundai Engineering & Construction Co., Ltd", "_driver": "Yao Jun", "binSize": "5 ft", "jobType": "Delivery", "siteIdx": 1, "_contact": "Liton", "clientId": "cmrkt918azpz", "distance": 0, "driverId": 5, "createdAt": "2026-07-30T09:05", "startedAt": "09:30", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1785375047962, "instructions": ""}, {"id": 94, "date": "2026-07-30", "_addr": "", "_task": "", "price": 0, "waste": "General Waste", "dumpTo": "", "status": "done", "_client": "Ecozeal", "_driver": "Liu", "binSize": "5 ft", "jobType": "", "siteIdx": 0, "_contact": "", "clientId": "cms6sx0w2c6g", "distance": 0, "driverId": 4, "createdAt": "2026-07-30T09:08", "startedAt": "09:59", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1785376750065, "instructions": "Call William"}, {"id": 95, "date": "2026-07-30", "_addr": "11 Pioneer Turn L407", "_task": "Exchange", "price": 13, "waste": "General Waste", "dumpTo": "", "status": "done", "_client": "Savills Property Management Pte Ltd (Green Hub)", "_driver": "Yao Jun", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 2, "_contact": "", "clientId": "cmrkt918aco2", "distance": 0, "driverId": 5, "_bydriver": true, "createdAt": "2026-07-30T09:32", "startedAt": "11:25", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1785381915100, "instructions": ""}, {"id": 96, "date": "2026-07-30", "_addr": "75 Tech Park Crescent", "_task": "Exchange", "price": 13, "waste": "General Waste", "dumpTo": "", "status": "done", "_client": "Faxolif Industries Pte Ltd", "_driver": "Yao Jun", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 0, "_contact": "", "clientId": "cmrkt9189chy", "distance": 0, "driverId": 5, "_bydriver": true, "createdAt": "2026-07-30T11:35", "startedAt": "12:14", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1785384844252, "instructions": ""}, {"id": 97, "date": "2026-07-30", "_addr": "Gul", "_task": "Exchange", "price": 19.5, "waste": "General Waste", "dumpTo": "", "status": "done", "_client": "ST", "_driver": "Yao Jun", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 2, "_contact": "", "clientId": "cmrkt918dn4k", "distance": 0, "driverId": 5, "_bydriver": true, "createdAt": "2026-07-30T13:32", "startedAt": "13:32", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1785389529624, "instructions": ""}, {"id": 98, "date": "2026-07-30", "_addr": "79 Anson Road", "_task": "Exchange", "price": 18, "waste": "General Waste", "dumpTo": "", "status": "done", "_client": "HCG", "_driver": "Yao Jun", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 1, "_contact": "", "clientId": "cmrkt9189v5w", "distance": 0, "driverId": 5, "_bydriver": true, "createdAt": "2026-07-30T13:36", "startedAt": "15:33", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1785396801240, "instructions": ""}, {"id": 99, "date": "2026-07-31", "_addr": "5 Sungei Kadut Street 6", "_task": "Dump", "price": 18, "waste": "Wood Waste", "dumpTo": "Bee Joo", "status": "done", "_client": "Beejoo", "_driver": "Liu", "binSize": "7 ft", "jobType": "Dump", "siteIdx": 0, "_contact": "", "clientId": "cmrkt9187viy", "distance": 0, "driverId": 4, "createdAt": "2026-07-30T21:26", "startedAt": "05:16", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1785446196018, "instructions": ""}, {"id": 100, "date": "2026-07-31", "_addr": "21 Ayer Merbau, Jurong Island", "_task": "Exchange", "price": 13, "waste": "General Waste", "dumpTo": "Lirich Resources Pte Ltd", "status": "in_progress", "_client": "Poh Tiong Choon Logistics Ltd", "_driver": "Liu", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 0, "_contact": "", "clientId": "cmrkt918ag06", "distance": 9.7, "driverId": 4, "createdAt": "2026-07-30T21:27", "startedAt": "10:24", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1785464689987, "instructions": ""}, {"id": 101, "date": "2026-07-31", "_addr": "14 Tractor Road", "_task": "Exchange", "price": 18, "waste": "General Waste", "dumpTo": "Lirich Resources Pte Ltd", "status": "assigned", "_client": "Tong Hock Pte Ltd", "_driver": "Karthik", "binSize": "7 ft", "jobType": "Exchange", "siteIdx": 2, "_contact": "", "clientId": "cmrkt918ebot", "distance": 5.3, "driverId": 2, "createdAt": "2026-07-30T21:30", "contactIdx": 0, "surcharges": [], "instructions": "Caterpillar"}, {"id": 102, "date": "2026-07-31", "_addr": "Nicoll Highway LP 120F", "_task": "Exchange", "price": 13, "waste": "General Waste", "dumpTo": "Lirich Resources Pte Ltd", "status": "assigned", "_client": "GS Engineering and Construction Corporation", "_driver": "Karthik", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 0, "_contact": "", "clientId": "cmrkt9189hjd", "distance": 0, "driverId": 2, "createdAt": "2026-07-30T21:32", "contactIdx": 0, "surcharges": [], "instructions": "Trip rate is $23"}, {"id": 103, "date": "2026-07-31", "_addr": "5 Sungei Kadut Street 6", "_task": "Dump", "price": 18, "waste": "Wood Waste", "dumpTo": "Bee Joo", "status": "assigned", "_client": "Beejoo", "_driver": "Karthik", "binSize": "7 ft", "jobType": "Dump", "siteIdx": 0, "_contact": "", "clientId": "cmrkt9187viy", "distance": 0, "driverId": 2, "createdAt": "2026-07-30T21:33", "contactIdx": 0, "surcharges": [], "instructions": ""}, {"id": 104, "date": "2026-07-31", "_addr": "22 Scotts Road, Goodwood Park Hotel", "_task": "Delivery", "price": 8, "waste": "General Waste", "dumpTo": "", "status": "assigned", "_client": "W'Ray Construction Pte Ltd", "_driver": "Sathish", "binSize": "5 ft", "jobType": "Delivery", "siteIdx": 0, "_contact": "", "clientId": "cmrkt918fh09", "distance": 0, "driverId": 1, "createdAt": "2026-07-30T21:35", "contactIdx": 0, "surcharges": [], "instructions": ""}, {"id": 105, "date": "2026-07-31", "_addr": "SUTD Building 2, 8 Somapah Road, loading bay", "_task": "Collect", "price": 23, "waste": "General Waste", "dumpTo": "Lirich Resources Pte Ltd", "status": "assigned", "_client": "Sun City Maintenance Pte Ltd", "_driver": "Sathish", "binSize": "5 ft", "jobType": "Collect", "siteIdx": 2, "_contact": "", "clientId": "cmrkt918em7e", "distance": 0, "driverId": 1, "createdAt": "2026-07-30T21:36", "contactIdx": 0, "surcharges": [], "instructions": ""}, {"id": 106, "date": "2026-07-31", "_addr": "46 Gul Drive", "_task": "Exchange", "price": 13, "waste": "General Waste", "dumpTo": "Lirich Resources Pte Ltd", "status": "assigned", "_client": "Haid Biotechnology Industry (Singapore) Pte Ltd", "_driver": "Kumar", "binSize": "660L", "jobType": "Exchange", "siteIdx": 0, "_contact": "Yvonne", "clientId": "cmrkt9189g55", "distance": 1.1, "driverId": 3, "createdAt": "2026-07-30T21:36", "contactIdx": 0, "surcharges": [], "instructions": ""}, {"id": 107, "date": "2026-07-31", "_addr": "5 Jalan Samulun", "_task": "Exchange", "price": 13, "waste": "General Waste", "dumpTo": "Lirich Resources Pte Ltd", "status": "assigned", "_client": "PaxOcean Singapore Pte Ltd", "_driver": "Kumar", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 0, "_contact": "Muthu", "clientId": "cmrkt918askd", "distance": 4.6, "driverId": 3, "createdAt": "2026-07-30T21:37", "contactIdx": 0, "surcharges": [], "instructions": "Morning"}, {"id": 108, "date": "2026-07-31", "_addr": "5 Jalan Samulun", "_task": "Exchange", "price": 13, "waste": "General Waste", "dumpTo": "Lirich Resources Pte Ltd", "status": "assigned", "_client": "PaxOcean Singapore Pte Ltd", "_driver": "Kumar", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 0, "_contact": "Muthu", "clientId": "cmrkt918askd", "distance": 4.6, "driverId": 3, "createdAt": "2026-07-30T21:37", "contactIdx": 0, "surcharges": [], "instructions": "Afternoon"}, {"id": 109, "date": "2026-07-31", "_addr": "Benoi", "_task": "Exchange", "price": 19.5, "waste": "General Waste", "dumpTo": "Lirich Resources Pte Ltd", "status": "assigned", "_client": "ST", "_driver": "Kumar", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 1, "_contact": "", "clientId": "cmrkt918dn4k", "distance": 2.3, "driverId": 3, "createdAt": "2026-07-30T21:38", "contactIdx": 0, "surcharges": [], "instructions": ""}, {"id": 110, "date": "2026-07-31", "_addr": "50 Playfair road", "_task": "Exchange", "price": 23, "waste": "General Waste", "dumpTo": "Lirich Resources Pte Ltd", "status": "done", "_client": "Top Star Builder Pte Ltd", "_driver": "Yao Jun", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 0, "_contact": "", "clientId": "cmrkt918fl15", "distance": 32.4, "driverId": 5, "createdAt": "2026-07-30T21:39", "startedAt": "07:34", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1785454499091, "instructions": ""}, {"id": 111, "date": "2026-07-31", "_addr": "Gul", "_task": "Exchange", "price": 19.5, "waste": "General Waste", "dumpTo": "Lirich Resources Pte Ltd", "status": "done", "_client": "ST", "_driver": "Yao Jun", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 2, "_contact": "", "clientId": "cmrkt918dn4k", "distance": 0.4, "driverId": 5, "createdAt": "2026-07-30T21:39", "startedAt": "14:56", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1785481002873, "instructions": ""}, {"id": 112, "date": "2026-07-31", "_addr": "31 Tuas West Drive, Lamppost 74F", "_task": "Load", "price": 21, "waste": "General Waste", "dumpTo": "", "status": "done", "_client": "Hyundai Engineering & Construction Co., Ltd", "_driver": "Yao Jun", "binSize": "5 ft", "jobType": "Load", "siteIdx": 1, "_contact": "Liton", "clientId": "cmrkt918azpz", "distance": 0, "driverId": 5, "_bydriver": true, "createdAt": "2026-07-31T09:46", "startedAt": "09:46", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1785462401619, "instructions": ""}, {"id": 113, "date": "2026-07-31", "_addr": "", "_task": "", "price": 0, "waste": "Hardcore Waste", "dumpTo": "", "status": "void", "_client": "Ecozeal", "_driver": "Yao Jun", "binSize": "5 ft", "jobType": "", "siteIdx": 0, "_contact": "", "clientId": "cms6sx0w2c6g", "distance": 0, "driverId": 5, "voidedOn": "2026-07-31", "_bydriver": true, "_voidedBy": "Yao Jun", "createdAt": "2026-07-31T12:28", "contactIdx": 0, "surcharges": [], "_voidReason": "Client cancelled", "contactName": "", "contactPhone": "", "instructions": "", "_contactPhone": ""}, {"id": 114, "date": "2026-07-31", "_addr": "", "_task": "", "price": 0, "waste": "Hardcore Waste", "dumpTo": "", "status": "done", "_client": "Ecozeal", "_driver": "Yao Jun", "binSize": "5 ft", "jobType": "", "siteIdx": 0, "_contact": "", "clientId": "cms6sx0w2c6g", "distance": 0, "driverId": 5, "_bydriver": true, "createdAt": "2026-07-31T12:29", "startedAt": "12:29", "contactIdx": 0, "surcharges": [], "contactName": "", "acceptedAtMs": 1785472152116, "contactPhone": "", "instructions": "", "_contactPhone": ""}, {"id": 115, "date": "2026-07-31", "_addr": "Gul", "_task": "Exchange", "price": 19.5, "waste": "General Waste", "dumpTo": "", "status": "done", "_client": "ST", "_driver": "Yao Jun", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 2, "_contact": "", "clientId": "cmrkt918dn4k", "distance": 0, "driverId": 5, "_bydriver": true, "createdAt": "2026-07-31T16:37", "startedAt": "16:37", "contactIdx": 0, "surcharges": [], "contactName": "", "acceptedAtMs": 1785487027018, "contactPhone": "", "instructions": "", "_contactPhone": ""}, {"id": 116, "date": "2026-07-31", "_addr": "NEA Tuas", "_task": "Exchange", "price": 13, "waste": "General Waste", "dumpTo": "", "status": "done", "_client": "NEA", "_driver": "Yao Jun", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 0, "_contact": "", "clientId": "cmrkt918ate4", "distance": 0, "driverId": 5, "_bydriver": true, "createdAt": "2026-07-31T16:39", "startedAt": "16:39", "contactIdx": 0, "surcharges": [], "contactName": "", "acceptedAtMs": 1785487196382, "contactPhone": "", "instructions": "", "_contactPhone": ""}], "trips": [{"id": 1, "tDO": 1784043316345, "_pay": 13, "date": "2026-07-14", "doNo": 2222, "tEnd": 1784043310829, "_addr": "9 Gul Circle", "_type": "Exchange", "binIn": "R08", "jobId": 1, "price": 13, "waste": "Carton Boxes", "_sales": "Patrick", "_surch": "", "binOut": "5239", "doType": "land", "photos": [{"id": "1tgLjlHKUm5ozfJk0IirMSAiTJH9hsYXy", "url": "https://drive.google.com/uc?export=view&id=1tgLjlHKUm5ozfJk0IirMSAiTJH9hsYXy", "kind": "in", "thumb": "https://drive.google.com/thumbnail?id=1tgLjlHKUm5ozfJk0IirMSAiTJH9hsYXy&sz=w240"}, {"id": "1nNhVZLTnxMbl7SymXuG1pSbtRaXcBn1u", "url": "https://drive.google.com/uc?export=view&id=1nNhVZLTnxMbl7SymXuG1pSbtRaXcBn1u", "kind": "out", "thumb": "https://drive.google.com/thumbnail?id=1nNhVZLTnxMbl7SymXuG1pSbtRaXcBn1u&sz=w240"}, {"id": "1jU2lhFs_tSB04dr4OLqJyLdhvUwMvuVp", "url": "https://drive.google.com/uc?export=view&id=1jU2lhFs_tSB04dr4OLqJyLdhvUwMvuVp", "kind": "do", "thumb": "https://drive.google.com/thumbnail?id=1jU2lhFs_tSB04dr4OLqJyLdhvUwMvuVp&sz=w240"}, {"id": "1g37CnCn4F9V53xxWtJ0ukpFRSGrQqBYt", "url": "https://drive.google.com/uc?export=view&id=1g37CnCn4F9V53xxWtJ0ukpFRSGrQqBYt", "kind": "signature", "thumb": "https://drive.google.com/thumbnail?id=1g37CnCn4F9V53xxWtJ0ukpFRSGrQqBYt&sz=w240"}], "tBinIn": 1784043299719, "vessel": null, "weight": {"net": 11, "tare": 1, "gross": 12, "ticket": "LR2"}, "_charge": 13, "_client": "Eng Lee Logistics Pte Ltd", "_driver": "Sathish", "jobType": "Exchange", "remarks": "", "sigName": "m", "tAccept": 1784043239862, "tBinOut": 1784043310829, "tServer": 1784043329809, "tWeight": 0, "timeEnd": "23:35", "tonnAdj": 0, "tonnage": 0, "clientId": "c1", "distance": 0, "driverId": 1, "invoiced": false, "disposeTo": "", "timeStart": "23:34", "vehicleNo": "1234", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": [], "sigPosition": "o"}, {"id": 2, "tDO": 1784043369307, "_pay": 13, "date": "2026-07-14", "doNo": 1233, "tEnd": 1784043363952, "_addr": "9 Gul Circle", "_type": "Exchange", "binIn": "5197", "jobId": 1, "price": 13, "waste": "Metal Waste", "_sales": "Patrick", "_surch": "", "binOut": "Y111", "doType": "land", "photos": [{"id": "1W5NA-QihPP2re3kzsnG7GaVEwTZxxJUR", "url": "https://drive.google.com/uc?export=view&id=1W5NA-QihPP2re3kzsnG7GaVEwTZxxJUR", "kind": "in", "thumb": "https://drive.google.com/thumbnail?id=1W5NA-QihPP2re3kzsnG7GaVEwTZxxJUR&sz=w240"}, {"id": "1Fdvfh3ULw_38sOkADQVlNUICSe-gOH7B", "url": "https://drive.google.com/uc?export=view&id=1Fdvfh3ULw_38sOkADQVlNUICSe-gOH7B", "kind": "out", "thumb": "https://drive.google.com/thumbnail?id=1Fdvfh3ULw_38sOkADQVlNUICSe-gOH7B&sz=w240"}, {"id": "14hohAWmRlA3sAES9ITVXKT1M2m2Gfa5E", "url": "https://drive.google.com/uc?export=view&id=14hohAWmRlA3sAES9ITVXKT1M2m2Gfa5E", "kind": "do", "thumb": "https://drive.google.com/thumbnail?id=14hohAWmRlA3sAES9ITVXKT1M2m2Gfa5E&sz=w240"}, {"id": "19JjJfTKn5IexrPNACe7UAWbZYtajLA7l", "url": "https://drive.google.com/uc?export=view&id=19JjJfTKn5IexrPNACe7UAWbZYtajLA7l", "kind": "signature", "thumb": "https://drive.google.com/thumbnail?id=19JjJfTKn5IexrPNACe7UAWbZYtajLA7l&sz=w240"}], "tBinIn": 1784043358329, "vessel": null, "weight": {"net": 61, "tare": 50, "gross": 111, "ticket": "LR1"}, "_charge": 13, "_client": "Eng Lee Logistics Pte Ltd", "_driver": "Sathish", "jobType": "Exchange", "remarks": "", "sigName": "1qq", "tAccept": 1784043239862, "tBinOut": 1784043363952, "tServer": 1784043423958, "tWeight": 0, "timeEnd": "23:36", "tonnAdj": 0, "tonnage": 0, "clientId": "c1", "distance": 0, "driverId": 1, "invoiced": false, "disposeTo": "", "timeStart": "23:35", "vehicleNo": "2234", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["Metal Waste"], "sigPosition": "999"}, {"id": 3, "tDO": 1784071515005, "_pay": 13, "date": "2026-07-15", "doNo": 26138, "tEnd": 1784071247206, "_addr": "16 Gul Crescent", "_type": "Collect / Exchange — Middle", "binIn": "L801", "jobId": null, "price": null, "waste": "General Waste", "_sales": "", "_surch": "", "binOut": "5245", "doType": "land", "photos": [{"id": "1qFlDqwT8YofpcCAcfXCUKbLjQ1j5ySv7", "url": "https://drive.google.com/uc?export=view&id=1qFlDqwT8YofpcCAcfXCUKbLjQ1j5ySv7", "kind": "in", "thumb": "https://drive.google.com/thumbnail?id=1qFlDqwT8YofpcCAcfXCUKbLjQ1j5ySv7&sz=w240"}, {"id": "1V7UfpThw3CZqRPaKyh_PF8EIW2m4yO0K", "url": "https://drive.google.com/uc?export=view&id=1V7UfpThw3CZqRPaKyh_PF8EIW2m4yO0K", "kind": "out", "thumb": "https://drive.google.com/thumbnail?id=1V7UfpThw3CZqRPaKyh_PF8EIW2m4yO0K&sz=w240"}, {"id": "1SZoxdC0PYt-oNTBfbhzJlo-4Xrq4RYqk", "url": "https://drive.google.com/uc?export=view&id=1SZoxdC0PYt-oNTBfbhzJlo-4Xrq4RYqk", "kind": "do", "thumb": "https://drive.google.com/thumbnail?id=1SZoxdC0PYt-oNTBfbhzJlo-4Xrq4RYqk&sz=w240"}], "tBinIn": 1784071231427, "typeId": "col_m", "vessel": null, "weight": {"net": 2350, "tare": 14100, "gross": 16450, "ticket": "LR6"}, "_charge": "", "_client": "Eng Leng Contractors Pte Ltd", "_driver": "Yao Jun", "jobType": "", "remarks": "", "sigName": "", "tAccept": 0, "tBinOut": 1784071247206, "tServer": 1784072079535, "tWeight": 0, "timeEnd": "07:20", "tonnAdj": 0, "tonnage": 0, "clientId": "cmrkt91888e3", "distance": 0, "driverId": 5, "invoiced": false, "disposeTo": "", "timeStart": "07:20", "vehicleNo": "XE7126P", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["General Waste"], "sigPosition": ""}, {"id": 4, "tDO": 1784074542634, "_pay": 13, "date": "2026-07-15", "doNo": 26139, "tEnd": 1784074019313, "_addr": "11 Tuas Bay Close, #04-01/02", "_type": "Collect / Exchange — Middle", "binIn": "5245", "jobId": null, "price": null, "waste": "General Waste", "_sales": "", "_surch": "", "binOut": "5151", "doType": "land", "photos": [{"id": "1xMrJ-p4atIc61RrIB2OPbcCEH1lwWvcE", "url": "https://drive.google.com/uc?export=view&id=1xMrJ-p4atIc61RrIB2OPbcCEH1lwWvcE", "kind": "in", "thumb": "https://drive.google.com/thumbnail?id=1xMrJ-p4atIc61RrIB2OPbcCEH1lwWvcE&sz=w240"}, {"id": "1H7qG_zGX_aUeH7jQx7KTpN9TNm8ozY7V", "url": "https://drive.google.com/uc?export=view&id=1H7qG_zGX_aUeH7jQx7KTpN9TNm8ozY7V", "kind": "out", "thumb": "https://drive.google.com/thumbnail?id=1H7qG_zGX_aUeH7jQx7KTpN9TNm8ozY7V&sz=w240"}, {"id": "1g_FGtC-FjZGGVDEwHB75vb0APek6EvtQ", "url": "https://drive.google.com/uc?export=view&id=1g_FGtC-FjZGGVDEwHB75vb0APek6EvtQ", "kind": "do", "thumb": "https://drive.google.com/thumbnail?id=1g_FGtC-FjZGGVDEwHB75vb0APek6EvtQ&sz=w240"}], "tBinIn": 1784074010542, "typeId": "col_m", "vessel": null, "weight": {"net": 2370, "tare": 14050, "gross": 16420, "ticket": "LR4"}, "_charge": "", "_client": "LexBuild International Pte Ltd", "_driver": "Yao Jun", "jobType": "", "remarks": "", "sigName": "", "tAccept": 0, "tBinOut": 1784074019313, "tServer": 1784074555682, "tWeight": 0, "timeEnd": "08:06", "tonnAdj": 0, "tonnage": 0, "clientId": "cmrkt918auof", "distance": 0, "driverId": 5, "invoiced": false, "disposeTo": "", "timeStart": "08:06", "vehicleNo": "XE7126P", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["General Waste"], "sigPosition": ""}, {"id": 5, "tDO": 1784076200794, "_pay": 13, "date": "2026-07-15", "doNo": 24436, "tEnd": 1784075742933, "_addr": "16 Gul Crescent", "_type": "Collect / Exchange — Middle", "binIn": "L805", "jobId": null, "price": null, "waste": "General Waste", "_sales": "", "_surch": "", "binOut": "L53", "doType": "land", "photos": [{"id": "1Vb1CWUVz51t5tfF_hZCj6SH5XxrwIRqO", "url": "https://drive.google.com/uc?export=view&id=1Vb1CWUVz51t5tfF_hZCj6SH5XxrwIRqO", "kind": "in", "thumb": "https://drive.google.com/thumbnail?id=1Vb1CWUVz51t5tfF_hZCj6SH5XxrwIRqO&sz=w240"}, {"id": "1vHghJ-AqSLjYQm7RBpY6-5IveejK09zj", "url": "https://drive.google.com/uc?export=view&id=1vHghJ-AqSLjYQm7RBpY6-5IveejK09zj", "kind": "out", "thumb": "https://drive.google.com/thumbnail?id=1vHghJ-AqSLjYQm7RBpY6-5IveejK09zj&sz=w240"}, {"id": "1JgZ4XwuS7NQ1dpvXJTx-CHO3P-q5pUwK", "url": "https://drive.google.com/uc?export=view&id=1JgZ4XwuS7NQ1dpvXJTx-CHO3P-q5pUwK", "kind": "do", "thumb": "https://drive.google.com/thumbnail?id=1JgZ4XwuS7NQ1dpvXJTx-CHO3P-q5pUwK&sz=w240"}, {"id": "1T9vDX9FiLrGdDqH9lXssT5Gg4M4z8leq", "url": "https://drive.google.com/uc?export=view&id=1T9vDX9FiLrGdDqH9lXssT5Gg4M4z8leq", "kind": "gross", "thumb": "https://drive.google.com/thumbnail?id=1T9vDX9FiLrGdDqH9lXssT5Gg4M4z8leq&sz=w240"}, {"id": "1xmEMxQ9_zgOxLN5ZYPATfPaygFyDwQPd", "url": "https://drive.google.com/uc?export=view&id=1xmEMxQ9_zgOxLN5ZYPATfPaygFyDwQPd", "kind": "signature", "thumb": "https://drive.google.com/thumbnail?id=1xmEMxQ9_zgOxLN5ZYPATfPaygFyDwQPd&sz=w240"}], "tBinIn": 1784075733368, "typeId": "col_m", "vessel": null, "weight": null, "_charge": "", "_client": "B&C Waste", "_driver": "Liu", "jobType": "", "remarks": "", "sigName": "", "tAccept": 0, "tBinOut": 1784075742933, "tServer": 1784076241962, "tWeight": 1784076231052, "timeEnd": "08:35", "tonnAdj": 0, "tonnage": 0, "clientId": "cmrkt91878od", "distance": 0, "driverId": 4, "invoiced": false, "disposeTo": "", "timeStart": "08:35", "vehicleNo": "XE8496P", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["General Waste"], "sigPosition": ""}, {"id": 6, "tDO": 1784077013616, "_pay": 13, "date": "2026-07-15", "doNo": 26140, "tEnd": 1784076916734, "_addr": "14 Benoi Place", "_type": "Collect / Exchange — Middle", "binIn": "5151", "jobId": null, "price": null, "waste": "General Waste", "_sales": "", "_surch": "", "binOut": "5109", "doType": "land", "photos": [{"id": "1UuOmAHMaagpi9UMdSCnQnGkO8qPsX9Y1", "url": "https://drive.google.com/uc?export=view&id=1UuOmAHMaagpi9UMdSCnQnGkO8qPsX9Y1", "kind": "in", "thumb": "https://drive.google.com/thumbnail?id=1UuOmAHMaagpi9UMdSCnQnGkO8qPsX9Y1&sz=w240"}, {"id": "1RrkuoJNVT6YpB5uhK_pcrDrdOrRGprox", "url": "https://drive.google.com/uc?export=view&id=1RrkuoJNVT6YpB5uhK_pcrDrdOrRGprox", "kind": "out", "thumb": "https://drive.google.com/thumbnail?id=1RrkuoJNVT6YpB5uhK_pcrDrdOrRGprox&sz=w240"}, {"id": "1hcfmrIjFaC0y6K5yw7HH-56xL9a7StIZ", "url": "https://drive.google.com/uc?export=view&id=1hcfmrIjFaC0y6K5yw7HH-56xL9a7StIZ", "kind": "do", "thumb": "https://drive.google.com/thumbnail?id=1hcfmrIjFaC0y6K5yw7HH-56xL9a7StIZ&sz=w240"}], "tBinIn": 1784076911151, "typeId": "col_m", "vessel": null, "weight": {"net": 2180, "tare": 13900, "gross": 16080, "ticket": "LR5"}, "_charge": "", "_client": "Aver Asia (S) Pte Ltd", "_driver": "Yao Jun", "jobType": "", "remarks": "", "sigName": "", "tAccept": 0, "tBinOut": 1784076916734, "tServer": 1784077020268, "tWeight": 0, "timeEnd": "08:55", "tonnAdj": 0, "tonnage": 0, "clientId": "cmrkt9187zx3", "distance": 0, "driverId": 5, "invoiced": false, "disposeTo": "", "timeStart": "08:55", "vehicleNo": "XE7126P", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["General Waste"], "sigPosition": ""}, {"id": 7, "tDO": 1784079687110, "_pay": 13, "date": "2026-07-15", "doNo": 24437, "tEnd": 1784079351735, "_addr": "16 Gul Crescent", "_type": "Collect / Exchange — Middle", "binIn": "L53", "jobId": null, "price": null, "waste": "General Waste", "_sales": "", "_surch": "", "binOut": "L805", "doType": "land", "photos": [{"id": "1kVvuBCuKOorb_nsmiffYmiIuV9w9KJsc", "url": "https://drive.google.com/uc?export=view&id=1kVvuBCuKOorb_nsmiffYmiIuV9w9KJsc", "kind": "in", "thumb": "https://drive.google.com/thumbnail?id=1kVvuBCuKOorb_nsmiffYmiIuV9w9KJsc&sz=w240"}, {"id": "1OpCe92IT-B0nMP72derqw3kS3MopnedW", "url": "https://drive.google.com/uc?export=view&id=1OpCe92IT-B0nMP72derqw3kS3MopnedW", "kind": "out", "thumb": "https://drive.google.com/thumbnail?id=1OpCe92IT-B0nMP72derqw3kS3MopnedW&sz=w240"}, {"id": "1DAJiNSy0Ri877eCvQLsDO_lEp2ePg-xt", "url": "https://drive.google.com/uc?export=view&id=1DAJiNSy0Ri877eCvQLsDO_lEp2ePg-xt", "kind": "do", "thumb": "https://drive.google.com/thumbnail?id=1DAJiNSy0Ri877eCvQLsDO_lEp2ePg-xt&sz=w240"}, {"id": "1vvTxGEOC5zH20IJLRKYEfYiGIyRs6tVr", "url": "https://drive.google.com/uc?export=view&id=1vvTxGEOC5zH20IJLRKYEfYiGIyRs6tVr", "kind": "gross", "thumb": "https://drive.google.com/thumbnail?id=1vvTxGEOC5zH20IJLRKYEfYiGIyRs6tVr&sz=w240"}, {"id": "1sug1rNwNtmyyJxKKTicGHI9iUe7HW4Ca", "url": "https://drive.google.com/uc?export=view&id=1sug1rNwNtmyyJxKKTicGHI9iUe7HW4Ca", "kind": "signature", "thumb": "https://drive.google.com/thumbnail?id=1sug1rNwNtmyyJxKKTicGHI9iUe7HW4Ca&sz=w240"}], "tBinIn": 1784079344671, "typeId": "col_m", "vessel": null, "weight": null, "_charge": "", "_client": "B&C Waste", "_driver": "Liu", "jobType": "", "remarks": "", "sigName": "", "tAccept": 0, "tBinOut": 1784079351735, "tServer": 1784079750044, "tWeight": 1784079740316, "timeEnd": "09:35", "tonnAdj": 0, "tonnage": 0, "clientId": "cmrkt91878od", "distance": 0, "driverId": 4, "invoiced": false, "disposeTo": "", "timeStart": "09:35", "vehicleNo": "XE8496P", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["General Waste"], "sigPosition": ""}, {"id": 8, "tDO": 1784083739701, "_pay": 13, "date": "2026-07-15", "doNo": 26141, "tEnd": 1784083734080, "_addr": "48 Pandan Road L3", "_type": "Exchange", "binIn": "5109", "jobId": 3, "price": 13, "waste": "General Waste", "_sales": "", "_surch": "", "binOut": "5028", "doType": "land", "photos": [{"id": "19YTk0k2rnjHXzGglV37GqYja2f7y-I8N", "url": "https://drive.google.com/uc?export=view&id=19YTk0k2rnjHXzGglV37GqYja2f7y-I8N", "kind": "in", "thumb": "https://drive.google.com/thumbnail?id=19YTk0k2rnjHXzGglV37GqYja2f7y-I8N&sz=w240"}, {"id": "1xiSWQVckX3IhOkwZbeTW4SUH0s7GBPlL", "url": "https://drive.google.com/uc?export=view&id=1xiSWQVckX3IhOkwZbeTW4SUH0s7GBPlL", "kind": "out", "thumb": "https://drive.google.com/thumbnail?id=1xiSWQVckX3IhOkwZbeTW4SUH0s7GBPlL&sz=w240"}, {"id": "1-XIrWYwbV7gABY5ubsMK542N7UXHNLK9", "url": "https://drive.google.com/uc?export=view&id=1-XIrWYwbV7gABY5ubsMK542N7UXHNLK9", "kind": "do", "thumb": "https://drive.google.com/thumbnail?id=1-XIrWYwbV7gABY5ubsMK542N7UXHNLK9&sz=w240"}], "tBinIn": 1784083726402, "typeId": "send", "vessel": null, "weight": {"net": 2770, "tare": 14100, "gross": 16870, "ticket": "LR3"}, "_charge": 13, "_client": "Poh Tiong Choon Logistics Ltd", "_driver": "Yao Jun", "jobType": "Exchange", "remarks": "", "sigName": "", "tAccept": 1784083566810, "tBinOut": 1784083734080, "tServer": 1784083789210, "tWeight": 0, "timeEnd": "10:48", "tonnAdj": 0, "tonnage": 0, "clientId": "cmrkt918ag06", "distance": 0, "driverId": 5, "invoiced": false, "disposeTo": "", "timeStart": "10:48", "vehicleNo": "XE7126P", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["General Waste"], "sigPosition": ""}, {"id": 9, "tDO": 1784083822099, "_pay": 0, "date": "2026-07-15", "doNo": 26141, "tEnd": 1784083818920, "_addr": "48 Pandan Road L3", "_type": "Exchange", "binIn": "5109", "jobId": 3, "price": 0, "waste": "General Waste", "_sales": "", "_surch": "", "binOut": "5028", "doType": "land", "photos": [{"id": "12fNbQQoIi-uZ0KvTs-oGaRqUiRkPIS2Y", "url": "https://drive.google.com/uc?export=view&id=12fNbQQoIi-uZ0KvTs-oGaRqUiRkPIS2Y", "kind": "in", "thumb": "https://drive.google.com/thumbnail?id=12fNbQQoIi-uZ0KvTs-oGaRqUiRkPIS2Y&sz=w240"}, {"id": "1tOsRtuWobrSWnGrUfy9KqvDlHwA6lPdw", "url": "https://drive.google.com/uc?export=view&id=1tOsRtuWobrSWnGrUfy9KqvDlHwA6lPdw", "kind": "out", "thumb": "https://drive.google.com/thumbnail?id=1tOsRtuWobrSWnGrUfy9KqvDlHwA6lPdw&sz=w240"}, {"id": "1i2KSiWHMwClaTfeVdFRaI7kjarrcoJ2J", "url": "https://drive.google.com/uc?export=view&id=1i2KSiWHMwClaTfeVdFRaI7kjarrcoJ2J", "kind": "do", "thumb": "https://drive.google.com/thumbnail?id=1i2KSiWHMwClaTfeVdFRaI7kjarrcoJ2J&sz=w240"}], "tBinIn": 1784083815170, "vessel": null, "weight": null, "_charge": 0, "_client": "Poh Tiong Choon Logistics Ltd", "_driver": "Yao Jun", "jobType": "Exchange", "remarks": "DUPLICATE of Trip #8 (same Job #3 / DO 26141) — voided by office, no pay/charge", "sigName": "", "tAccept": 1784083566810, "tBinOut": 1784083818920, "tServer": 1784083842987, "tWeight": 0, "timeEnd": "10:50", "tonnAdj": 0, "tonnage": 0, "clientId": "cmrkt918ag06", "distance": 0, "driverId": 5, "invoiced": false, "disposeTo": "", "timeStart": "10:50", "vehicleNo": "XE7126P", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["General Waste"], "sigPosition": ""}, {"id": 10, "tDO": 1784092488976, "_pay": 18, "date": "2026-07-15", "doNo": 130351, "tEnd": 1784093095025, "_addr": "79 Anson Road", "_type": "Exchange", "binIn": "5072", "jobId": 4, "price": 18, "waste": "Wood Waste", "_sales": "", "_surch": "", "binOut": "5070", "doType": "land", "photos": [{"id": "10vmRrXWJF4TA3IeMvYRKzYA2MDFG7HTZ", "url": "https://drive.google.com/uc?export=view&id=10vmRrXWJF4TA3IeMvYRKzYA2MDFG7HTZ", "kind": "do", "thumb": "https://drive.google.com/thumbnail?id=10vmRrXWJF4TA3IeMvYRKzYA2MDFG7HTZ&sz=w240"}, {"id": "1XNcbU-Umw02k_OAUdsjGPIroIZQbwCQi", "url": "https://drive.google.com/uc?export=view&id=1XNcbU-Umw02k_OAUdsjGPIroIZQbwCQi", "kind": "in", "thumb": "https://drive.google.com/thumbnail?id=1XNcbU-Umw02k_OAUdsjGPIroIZQbwCQi&sz=w240"}, {"id": "1cV2ElhMxZMaqJBqGctop7WFdW4eyNxS1", "url": "https://drive.google.com/uc?export=view&id=1cV2ElhMxZMaqJBqGctop7WFdW4eyNxS1", "kind": "out", "thumb": "https://drive.google.com/thumbnail?id=1cV2ElhMxZMaqJBqGctop7WFdW4eyNxS1&sz=w240"}], "tBinIn": 1784093090592, "typeId": "send", "vessel": null, "weight": {"net": 2560, "tare": 14810, "gross": 17370, "ticket": "LR7"}, "_charge": 18, "_client": "HCG", "_driver": "Yao Jun", "jobType": "Exchange", "remarks": "", "sigName": "", "tAccept": 1784092230111, "tBinOut": 1784093095025, "tServer": 1784092560713, "tWeight": 0, "timeEnd": "13:24", "tonnAdj": 0, "tonnage": 0, "clientId": "cmrkt9189v5w", "distance": 0, "driverId": 5, "invoiced": false, "disposeTo": "", "timeStart": "13:24", "vehicleNo": "XE7126P", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["Wood Waste"], "sigPosition": ""}, {"id": 11, "tDO": 1784092777431, "_pay": 0, "date": "2026-07-15", "doNo": 130351, "tEnd": 1784093066201, "_addr": "79 Anson Road", "_type": "Exchange", "binIn": "5072", "jobId": 4, "price": 0, "waste": "Wood Waste", "_sales": "", "_surch": "", "binOut": "5070", "doType": "land", "photos": [{"id": "1hX3uiC98aNawe_rMVCijSs5zOpCsUrJI", "url": "https://drive.google.com/uc?export=view&id=1hX3uiC98aNawe_rMVCijSs5zOpCsUrJI", "kind": "in", "thumb": "https://drive.google.com/thumbnail?id=1hX3uiC98aNawe_rMVCijSs5zOpCsUrJI&sz=w240"}, {"id": "1KjuYwJCPwMX793jzhttYKtONraoZXE-6", "url": "https://drive.google.com/uc?export=view&id=1KjuYwJCPwMX793jzhttYKtONraoZXE-6", "kind": "out", "thumb": "https://drive.google.com/thumbnail?id=1KjuYwJCPwMX793jzhttYKtONraoZXE-6&sz=w240"}, {"id": "1CoZdMsbdT9CP8-S-DhQPaDjcTDscWMC8", "url": "https://drive.google.com/uc?export=view&id=1CoZdMsbdT9CP8-S-DhQPaDjcTDscWMC8", "kind": "do", "thumb": "https://drive.google.com/thumbnail?id=1CoZdMsbdT9CP8-S-DhQPaDjcTDscWMC8&sz=w240"}], "tBinIn": 1784093061131, "vessel": null, "weight": null, "_charge": 0, "_client": "HCG", "_driver": "Yao Jun", "jobType": "Exchange", "remarks": "DUPLICATE of Trip #10 (same Job #4 / DO 130351) — voided by office, no pay/charge", "sigName": "", "tAccept": 1784092230111, "tBinOut": 1784093066201, "tServer": 1784093074379, "tWeight": 0, "timeEnd": "13:24", "tonnAdj": 0, "tonnage": 0, "clientId": "cmrkt9189v5w", "distance": 0, "driverId": 5, "invoiced": false, "disposeTo": "", "timeStart": "13:24", "vehicleNo": "XE7126P", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["Wood Waste"], "sigPosition": ""}, {"id": 12, "tDO": 1784101592533, "_pay": 31, "date": "2026-07-15", "doNo": 41767, "tEnd": 1784101577412, "_addr": "26 Loyang Drive", "_type": "Load", "binIn": "R13", "jobId": 5, "price": 31, "waste": "Wood Waste", "_sales": "", "_surch": "", "binOut": "R13", "doType": "land", "photos": [{"id": "1PEcHHSrsgmdw_FYGmwz2SXf_YQIkItmt", "url": "https://drive.google.com/uc?export=view&id=1PEcHHSrsgmdw_FYGmwz2SXf_YQIkItmt", "kind": "in", "thumb": "https://drive.google.com/thumbnail?id=1PEcHHSrsgmdw_FYGmwz2SXf_YQIkItmt&sz=w240"}, {"id": "1rENbGVPDnU17thW_8d7IvoIsCzn7s8os", "url": "https://drive.google.com/uc?export=view&id=1rENbGVPDnU17thW_8d7IvoIsCzn7s8os", "kind": "out", "thumb": "https://drive.google.com/thumbnail?id=1rENbGVPDnU17thW_8d7IvoIsCzn7s8os&sz=w240"}, {"id": "1FjqgXtP6_HEjulcsh5XRY624R0ZLCABz", "url": "https://drive.google.com/uc?export=view&id=1FjqgXtP6_HEjulcsh5XRY624R0ZLCABz", "kind": "do", "thumb": "https://drive.google.com/thumbnail?id=1FjqgXtP6_HEjulcsh5XRY624R0ZLCABz&sz=w240"}], "tBinIn": 1784101561860, "vessel": null, "weight": {"net": 1, "tare": 2, "gross": 3, "ticket": "LR34"}, "_charge": 31, "_client": "B&C Waste", "_driver": "Yao Jun", "jobType": "Load", "remarks": "", "sigName": "", "tAccept": 1784099668422, "tBinOut": 1784101577412, "tServer": 1784101625150, "tWeight": 0, "timeEnd": "15:46", "tonnAdj": 0, "tonnage": 0, "clientId": "cmrkt91878od", "distance": 0, "driverId": 5, "invoiced": false, "disposeTo": "", "timeStart": "15:46", "vehicleNo": "XE7126P", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["Wood Waste"], "sigPosition": ""}, {"id": 13, "tDO": 1784111702513, "_pay": 13, "date": "2026-07-15", "doNo": 26143, "tEnd": 1784111098580, "_addr": "47A Jalan Buroh", "_type": "Exchange", "binIn": "5033", "jobId": 6, "price": 13, "waste": "General Waste", "_sales": "", "_surch": "", "binOut": "5084", "doType": "land", "photos": [{"id": "1rXel9yA366uv2L-HZinhFWS-oR6ms0o_", "url": "https://drive.google.com/uc?export=view&id=1rXel9yA366uv2L-HZinhFWS-oR6ms0o_", "kind": "in", "thumb": "https://drive.google.com/thumbnail?id=1rXel9yA366uv2L-HZinhFWS-oR6ms0o_&sz=w240"}, {"id": "1WgF0l6sHzhrXvHuKlhwvATkp4WhkyUio", "url": "https://drive.google.com/uc?export=view&id=1WgF0l6sHzhrXvHuKlhwvATkp4WhkyUio", "kind": "out", "thumb": "https://drive.google.com/thumbnail?id=1WgF0l6sHzhrXvHuKlhwvATkp4WhkyUio&sz=w240"}, {"id": "1kzwOoTewqvBR5Kn9oY-izITJsqgi7meO", "url": "https://drive.google.com/uc?export=view&id=1kzwOoTewqvBR5Kn9oY-izITJsqgi7meO", "kind": "do", "thumb": "https://drive.google.com/thumbnail?id=1kzwOoTewqvBR5Kn9oY-izITJsqgi7meO&sz=w240"}], "tBinIn": 1784111092703, "vessel": null, "weight": {"net": 1180, "tare": 14100, "gross": 15280, "ticket": "LR8"}, "_charge": 13, "_client": "Advanced Substrate Technologies Pte Ltd", "_driver": "Yao Jun", "jobType": "Exchange", "remarks": "", "sigName": "", "tAccept": 1784109223975, "tBinOut": 1784111098580, "tServer": 1784111729097, "tWeight": 0, "timeEnd": "18:24", "tonnAdj": 0, "tonnage": 0, "clientId": "cmrkt9187x1k", "distance": 0, "driverId": 5, "invoiced": false, "disposeTo": "", "timeStart": "18:24", "vehicleNo": "XE7126P", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["General Waste"], "sigPosition": ""}, {"id": 14, "tDO": 1784116479514, "_pay": 18, "date": "2026-07-15", "doNo": 130352, "tEnd": 1784116593955, "_addr": "79 Anson Road", "_type": "Exchange", "binIn": "5070号", "jobId": 7, "price": 18, "waste": "General Waste", "_sales": "", "_surch": "", "binOut": "5193", "doType": "land", "photos": [{"id": "18ZwPbi7_6RWP8GelyM2jj_v9C7O9yyMf", "url": "https://drive.google.com/uc?export=view&id=18ZwPbi7_6RWP8GelyM2jj_v9C7O9yyMf", "kind": "in", "thumb": "https://drive.google.com/thumbnail?id=18ZwPbi7_6RWP8GelyM2jj_v9C7O9yyMf&sz=w240"}, {"id": "1_ujAtz5uxQsJBsui_YII3hBEoUSl5luo", "url": "https://drive.google.com/uc?export=view&id=1_ujAtz5uxQsJBsui_YII3hBEoUSl5luo", "kind": "out", "thumb": "https://drive.google.com/thumbnail?id=1_ujAtz5uxQsJBsui_YII3hBEoUSl5luo&sz=w240"}, {"id": "1Ep2VBalTd9LvuG-sgK2WQM-XndKvkaeF", "url": "https://drive.google.com/uc?export=view&id=1Ep2VBalTd9LvuG-sgK2WQM-XndKvkaeF", "kind": "do", "thumb": "https://drive.google.com/thumbnail?id=1Ep2VBalTd9LvuG-sgK2WQM-XndKvkaeF&sz=w240"}], "tBinIn": 1784116504583, "vessel": null, "weight": {"net": 1, "tare": 2, "gross": 3, "ticket": "LR35"}, "_charge": 18, "_client": "HCG", "_driver": "Yao Jun", "jobType": "Exchange", "remarks": "", "sigName": "", "tAccept": 1784112771627, "tBinOut": 1784116593955, "tServer": 1784116628918, "tWeight": 0, "timeEnd": "19:56", "tonnAdj": 0, "tonnage": 0, "clientId": "cmrkt9189v5w", "distance": 0, "driverId": 5, "invoiced": false, "disposeTo": "", "timeStart": "19:55", "vehicleNo": "XE7126P", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["General Waste"], "sigPosition": ""}, {"id": 15, "tDO": 1784127628883, "_pay": 18, "date": "2026-07-15", "doNo": 26144, "tEnd": 1784127597933, "_addr": "6 Chin Bee Ave L5", "_type": "Exchange", "binIn": "R21", "jobId": 13, "price": 13, "waste": "General Waste", "_sales": "", "_surch": "After 7pm (Vessel)", "binOut": "R21", "doType": "land", "photos": [{"id": "1lfk9MOCXXDDDuHDnxXrHJVNny9-yf1ou", "url": "https://drive.google.com/uc?export=view&id=1lfk9MOCXXDDDuHDnxXrHJVNny9-yf1ou", "kind": "in", "thumb": "https://drive.google.com/thumbnail?id=1lfk9MOCXXDDDuHDnxXrHJVNny9-yf1ou&sz=w240"}, {"id": "1tmhM2nspeUP1UwWxAgN-P_o4W2z9UCuv", "url": "https://drive.google.com/uc?export=view&id=1tmhM2nspeUP1UwWxAgN-P_o4W2z9UCuv", "kind": "out", "thumb": "https://drive.google.com/thumbnail?id=1tmhM2nspeUP1UwWxAgN-P_o4W2z9UCuv&sz=w240"}, {"id": "1c_btJQYx-ktkRL5ka8IqE9sRrag6XB0k", "url": "https://drive.google.com/uc?export=view&id=1c_btJQYx-ktkRL5ka8IqE9sRrag6XB0k", "kind": "do", "thumb": "https://drive.google.com/thumbnail?id=1c_btJQYx-ktkRL5ka8IqE9sRrag6XB0k&sz=w240"}], "tBinIn": 1784127593575, "vessel": null, "weight": {"net": 1300, "tare": 14050, "gross": 15350, "ticket": "LR9"}, "_charge": 13, "_client": "Shin Ya O Ya Pte Ltd", "_driver": "Yao Jun", "jobType": "Exchange", "remarks": "", "sigName": "", "tAccept": 1784127557628, "tBinOut": 1784127597933, "tServer": 1784127668045, "tWeight": 0, "timeEnd": "22:59", "tonnAdj": 0, "tonnage": 0, "clientId": "cmrkt918dq77", "distance": 0, "driverId": 5, "invoiced": false, "disposeTo": "Lirich Resources Pte Ltd", "timeStart": "22:59", "vehicleNo": "XE7126P", "weightAdj": 0, "surcharges": ["after7v"], "wasteOther": "", "wasteTypes": ["General Waste"], "sigPosition": ""}, {"id": 16, "tDO": 1784163115843, "_pay": 13, "date": "2026-07-16", "doNo": 26145, "tEnd": 1784163061350, "_addr": "8 Pandan Crescent", "_type": "Exchange", "binIn": "7006", "jobId": 14, "price": 13, "waste": "General Waste", "_sales": "", "_surch": "", "binOut": "8005", "doType": "land", "photos": [{"id": "18mGbQqsLMEDnKkwLGo7e2yJQD3188dkX", "url": "https://drive.google.com/uc?export=view&id=18mGbQqsLMEDnKkwLGo7e2yJQD3188dkX", "kind": "in", "thumb": "https://drive.google.com/thumbnail?id=18mGbQqsLMEDnKkwLGo7e2yJQD3188dkX&sz=w240"}, {"id": "1O26ckVh6NLtPzOPMUpM323OyFQ1rr75m", "url": "https://drive.google.com/uc?export=view&id=1O26ckVh6NLtPzOPMUpM323OyFQ1rr75m", "kind": "out", "thumb": "https://drive.google.com/thumbnail?id=1O26ckVh6NLtPzOPMUpM323OyFQ1rr75m&sz=w240"}, {"id": "1mLurR3mtqgY0cmYLUIgUWSwsxuEAVGDL", "url": "https://drive.google.com/uc?export=view&id=1mLurR3mtqgY0cmYLUIgUWSwsxuEAVGDL", "kind": "do", "thumb": "https://drive.google.com/thumbnail?id=1mLurR3mtqgY0cmYLUIgUWSwsxuEAVGDL&sz=w240"}], "tBinIn": 1784163053131, "vessel": null, "weight": {"net": 2130, "tare": 14650, "gross": 16780, "ticket": "LR10"}, "_charge": 13, "_client": "ASL Proworld Solution Pte Ltd", "_driver": "Yao Jun", "jobType": "Exchange", "remarks": "", "sigName": "", "tAccept": 1784162742439, "tBinOut": 1784163061350, "tServer": 1784163151992, "tWeight": 0, "timeEnd": "08:51", "tonnAdj": 0, "tonnage": 0, "clientId": "cmrkt9187ws7", "distance": 13.1, "driverId": 5, "invoiced": false, "disposeTo": "Lirich Resources Pte Ltd", "timeStart": "08:50", "vehicleNo": "XE7126P", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["General Waste"], "sigPosition": ""}, {"id": 17, "tDO": 1784167594817, "_pay": 13, "date": "2026-07-16", "doNo": 26146, "tEnd": 1784167171816, "_addr": "60 Benoi Road", "_type": "Exchange", "binIn": "L57", "jobId": 15, "price": 13, "waste": "General Waste", "_sales": "", "_surch": "", "binOut": "5213", "doType": "land", "photos": [{"id": "1AHAR0zEKuGBzXVNQ1bpGQeAnNQPw8bVY", "url": "https://drive.google.com/uc?export=view&id=1AHAR0zEKuGBzXVNQ1bpGQeAnNQPw8bVY", "kind": "in", "thumb": "https://drive.google.com/thumbnail?id=1AHAR0zEKuGBzXVNQ1bpGQeAnNQPw8bVY&sz=w240"}, {"id": "10my5iLMP6bf3h6_hdxSB9ZGpGpxKfS_L", "url": "https://drive.google.com/uc?export=view&id=10my5iLMP6bf3h6_hdxSB9ZGpGpxKfS_L", "kind": "out", "thumb": "https://drive.google.com/thumbnail?id=10my5iLMP6bf3h6_hdxSB9ZGpGpxKfS_L&sz=w240"}, {"id": "1tsvTulFhjZpII0jjDYAFFDIq8OhpDJbt", "url": "https://drive.google.com/uc?export=view&id=1tsvTulFhjZpII0jjDYAFFDIq8OhpDJbt", "kind": "do", "thumb": "https://drive.google.com/thumbnail?id=1tsvTulFhjZpII0jjDYAFFDIq8OhpDJbt&sz=w240"}], "tBinIn": 1784167164967, "vessel": null, "weight": {"net": 15965, "tare": 1395, "gross": 17360, "ticket": "LR11"}, "_charge": 13, "_client": "EverTeam Pte Ltd", "_driver": "Yao Jun", "jobType": "Exchange", "remarks": "", "sigName": "", "tAccept": 1784167147780, "tBinOut": 1784167171816, "tServer": 1784167619295, "tWeight": 0, "timeEnd": "09:59", "tonnAdj": 0, "tonnage": 0, "clientId": "cmrkt9189j9t", "distance": 1.9, "driverId": 5, "invoiced": false, "disposeTo": "Lirich Resources Pte Ltd", "timeStart": "09:59", "vehicleNo": "XE7126P", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["General Waste"], "sigPosition": ""}, {"id": 18, "tDO": 1784172031973, "_pay": 18, "date": "2026-07-16", "doNo": 130353, "tEnd": 1784171589576, "_addr": "79 Anson Road", "_type": "Exchange", "binIn": "5193", "jobId": 21, "price": 18, "waste": "Wood Waste", "_sales": "", "_surch": "", "binOut": "5132", "doType": "land", "photos": [{"id": "1ATztqAtb0SB81wvu9WFUVIhAYfyn7-Nt", "url": "https://drive.google.com/uc?export=view&id=1ATztqAtb0SB81wvu9WFUVIhAYfyn7-Nt", "kind": "in", "thumb": "https://drive.google.com/thumbnail?id=1ATztqAtb0SB81wvu9WFUVIhAYfyn7-Nt&sz=w240"}, {"id": "17lqHyCkKkt3gRNlwNvAPsLe7QrWmDxcn", "url": "https://drive.google.com/uc?export=view&id=17lqHyCkKkt3gRNlwNvAPsLe7QrWmDxcn", "kind": "out", "thumb": "https://drive.google.com/thumbnail?id=17lqHyCkKkt3gRNlwNvAPsLe7QrWmDxcn&sz=w240"}, {"id": "1B-1uZfGzmgynG8FVhsGnZyZL1AZ24IPa", "url": "https://drive.google.com/uc?export=view&id=1B-1uZfGzmgynG8FVhsGnZyZL1AZ24IPa", "kind": "do", "thumb": "https://drive.google.com/thumbnail?id=1B-1uZfGzmgynG8FVhsGnZyZL1AZ24IPa&sz=w240"}], "tBinIn": 1784171582853, "vessel": null, "weight": {"net": 1, "tare": 2, "gross": 3, "ticket": "LR37"}, "_charge": 18, "_client": "HCG", "_driver": "Yao Jun", "jobType": "Exchange", "remarks": "", "sigName": "", "tAccept": 1784169791187, "tBinOut": 1784171589576, "tServer": 1784172041720, "tWeight": 0, "timeEnd": "11:13", "tonnAdj": 0, "tonnage": 0, "clientId": "cmrkt9189v5w", "distance": 32, "driverId": 5, "invoiced": false, "disposeTo": "HCG Environmental Pte Ltd", "timeStart": "11:13", "vehicleNo": "XE7126P", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["Wood Waste"], "sigPosition": ""}, {"id": 19, "tDO": 1784184620264, "_pay": 18, "date": "2026-07-16", "doNo": 130354, "tEnd": 1784184586430, "_addr": "79 Anson Road", "_type": "Exchange", "binIn": "5132", "jobId": 20, "price": 18, "waste": "General Waste", "_sales": "", "_surch": "", "binOut": "5072", "doType": "land", "photos": [{"id": "1AGLyIHSUjlboegCEa3HWSyYsxX7hPiZJ", "url": "https://drive.google.com/uc?export=view&id=1AGLyIHSUjlboegCEa3HWSyYsxX7hPiZJ", "kind": "in", "thumb": "https://drive.google.com/thumbnail?id=1AGLyIHSUjlboegCEa3HWSyYsxX7hPiZJ&sz=w240"}, {"id": "14C5rcRXjWYFSWgdgu1mjR-d8Ar_0zXtg", "url": "https://drive.google.com/uc?export=view&id=14C5rcRXjWYFSWgdgu1mjR-d8Ar_0zXtg", "kind": "out", "thumb": "https://drive.google.com/thumbnail?id=14C5rcRXjWYFSWgdgu1mjR-d8Ar_0zXtg&sz=w240"}, {"id": "1u3CpdU1tSn2qsNIbCRvfqw4ser-eHTZe", "url": "https://drive.google.com/uc?export=view&id=1u3CpdU1tSn2qsNIbCRvfqw4ser-eHTZe", "kind": "do", "thumb": "https://drive.google.com/thumbnail?id=1u3CpdU1tSn2qsNIbCRvfqw4ser-eHTZe&sz=w240"}], "tBinIn": 1784184554590, "vessel": null, "weight": {"net": 1, "tare": 2, "gross": 3, "ticket": "LR36"}, "_charge": 18, "_client": "HCG", "_driver": "Yao Jun", "jobType": "Exchange", "remarks": "", "sigName": "", "tAccept": 1784183568667, "tBinOut": 1784184586430, "tServer": 1784184652222, "tWeight": 0, "timeEnd": "14:49", "tonnAdj": 0, "tonnage": 0, "clientId": "cmrkt9189v5w", "distance": 32, "driverId": 5, "invoiced": false, "disposeTo": "HCG Environmental Pte Ltd", "timeStart": "14:49", "vehicleNo": "XE7126P", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["General Waste"], "sigPosition": ""}, {"id": 20, "tDO": 1784296282125, "_pay": 13, "date": "2026-07-17", "doNo": 26218, "tEnd": 0, "_addr": "9 Gul Circle", "_type": "Exchange", "binIn": "", "jobId": 28, "price": 13, "waste": "General Waste", "_sales": "Patrick", "_surch": "", "binOut": "", "doType": "land", "photos": [{"id": "1-CyxHvyBN_IBRTt5dvT_6HqpxvGX75qx", "url": "https://drive.google.com/uc?export=view&id=1-CyxHvyBN_IBRTt5dvT_6HqpxvGX75qx", "kind": "do", "thumb": "https://drive.google.com/thumbnail?id=1-CyxHvyBN_IBRTt5dvT_6HqpxvGX75qx&sz=w240"}, {"id": "1CyfT6Af8Q0HOzu_fAEJQEzXufiF9Rki6", "url": "https://drive.google.com/uc?export=view&id=1CyfT6Af8Q0HOzu_fAEJQEzXufiF9Rki6", "kind": "signature", "thumb": "https://drive.google.com/thumbnail?id=1CyfT6Af8Q0HOzu_fAEJQEzXufiF9Rki6&sz=w240"}], "tBinIn": 0, "vessel": null, "weight": null, "_charge": 13, "_client": "Eng Lee Logistics Pte Ltd", "_driver": "Test Driver", "jobType": "Exchange", "remarks": "", "sigName": "", "tAccept": 1784295480487, "tBinOut": 0, "tServer": 1784296361691, "tWeight": 0, "timeEnd": "", "tonnAdj": 0, "tonnage": 0, "clientId": "c1", "distance": 0, "driverId": 6, "invoiced": false, "disposeTo": "", "timeStart": "", "vehicleNo": "X1234Y", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["General Waste"], "sigPosition": ""}, {"id": 21, "tDO": 0, "_pay": 18, "date": "2026-07-20", "doNo": 0, "tEnd": 1784506951000, "_addr": "5 Sungei Kadut Street 6", "_type": "Dump", "binIn": "", "jobId": 32, "price": 18, "waste": "Wood Waste", "_sales": "", "_surch": "", "binOut": "", "doType": "land", "photos": [{"id": "1vju9VBTIMjv-VqYyv0DmoLe_KWPfoVT5", "ts": 1784506957000, "url": "https://drive.google.com/uc?export=view&id=1vju9VBTIMjv-VqYyv0DmoLe_KWPfoVT5", "kind": "bin", "thumb": "https://drive.google.com/thumbnail?id=1vju9VBTIMjv-VqYyv0DmoLe_KWPfoVT5&sz=w240"}, {"id": "1xYyxvfoFVRxF-drM1skSojB-f4f6JfUY", "ts": 1784506951000, "url": "https://drive.google.com/uc?export=view&id=1xYyxvfoFVRxF-drM1skSojB-f4f6JfUY", "kind": "bin", "thumb": "https://drive.google.com/thumbnail?id=1xYyxvfoFVRxF-drM1skSojB-f4f6JfUY&sz=w240"}], "tBinIn": 0, "vessel": null, "weight": {"net": 5170, "tare": 15640, "gross": 20810, "ticket": "LR12"}, "_charge": 18, "_client": "Beejoo", "_driver": "Yao Jun", "jobType": "Dump", "remarks": "", "sigName": "", "tAccept": 1784505051464, "tBinOut": 0, "tServer": 1784507031650, "tWeight": 0, "timeEnd": "08:22", "tonnAdj": 0, "tonnage": 0, "clientId": "cmrkt9187viy", "distance": 0, "driverId": 5, "invoiced": false, "disposeTo": "Bee Joo", "timeStart": "07:50", "vehicleNo": "", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": [], "sigPosition": ""}, {"id": 22, "tDO": 1784510392000, "_pay": 19.5, "date": "2026-07-20", "doNo": 0, "tEnd": 1784509583000, "_addr": "Benoi", "_type": "Exchange", "binIn": "6002", "jobId": 33, "price": 19.5, "waste": "General Waste", "_sales": "", "_surch": "", "binOut": "6002", "doType": "land", "photos": [{"id": "1p_VkTnz1WRtmY4rssV6Rq0TK9JBlYTFO", "ts": 1784509583000, "url": "https://drive.google.com/uc?export=view&id=1p_VkTnz1WRtmY4rssV6Rq0TK9JBlYTFO", "kind": "in", "thumb": "https://drive.google.com/thumbnail?id=1p_VkTnz1WRtmY4rssV6Rq0TK9JBlYTFO&sz=w240"}, {"id": "133wnotINTbCw8ooglK5xZmstd46QZxlp", "ts": 1784509583000, "url": "https://drive.google.com/uc?export=view&id=133wnotINTbCw8ooglK5xZmstd46QZxlp", "kind": "out", "thumb": "https://drive.google.com/thumbnail?id=133wnotINTbCw8ooglK5xZmstd46QZxlp&sz=w240"}, {"id": "1I3c4p7BgTju6vffkDPM7x6s1uBJ26gCw", "ts": 1784510392000, "url": "https://drive.google.com/uc?export=view&id=1I3c4p7BgTju6vffkDPM7x6s1uBJ26gCw", "kind": "do", "thumb": "https://drive.google.com/thumbnail?id=1I3c4p7BgTju6vffkDPM7x6s1uBJ26gCw&sz=w240"}], "tBinIn": 1784509583000, "vessel": null, "weight": {"net": 4430, "tare": 14100, "gross": 18530, "ticket": "LR13"}, "_charge": 19.5, "_client": "ST", "_driver": "Yao Jun", "jobType": "Exchange", "remarks": "", "sigName": "", "tAccept": 1784510460438, "tBinOut": 1784509583000, "tServer": 1784510504417, "tWeight": 0, "timeEnd": "09:06", "tonnAdj": 0, "tonnage": 0, "clientId": "cmrkt918dn4k", "distance": 2.3, "driverId": 5, "invoiced": false, "disposeTo": "Lirich Resources Pte Ltd", "timeStart": "09:06", "vehicleNo": "XE7126P", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["General Waste"], "sigPosition": ""}, {"id": 23, "tDO": 1784920014000, "_pay": 13, "date": "2026-07-25", "doNo": 0, "tEnd": 1784920014000, "_addr": "9 Gul Circle", "_test": true, "_type": "Exchange", "binIn": "", "jobId": 43, "price": 13, "waste": "General Waste", "_sales": "Patrick", "_surch": "", "binOut": "", "doType": "land", "photos": [{"id": "mrzbayza-BININ-43-1.jpg", "ts": 1784920014000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/mrzbayza-BININ-43-1.jpg", "kind": "in", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/mrzbayza-BININ-43-1.jpg"}, {"id": "mrzbaz6l-BINOUT-43-1.jpg", "ts": 1784920014000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/mrzbaz6l-BINOUT-43-1.jpg", "kind": "out", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/mrzbaz6l-BINOUT-43-1.jpg"}, {"id": "mrzbazaa-DO-43-1.jpg", "ts": 1784920014000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/mrzbazaa-DO-43-1.jpg", "kind": "do", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/mrzbazaa-DO-43-1.jpg"}], "tBinIn": 1784920014000, "vessel": null, "weight": null, "_charge": 13, "_client": "Eng Lee Logistics Pte Ltd", "_driver": "Test Driver", "jobType": "Exchange", "remarks": "", "sigName": "", "tAccept": 1784919884770, "tBinOut": 1784920014000, "tServer": 1784920037014, "tWeight": 0, "timeEnd": "03:06", "tonnAdj": 0, "tonnage": 0, "clientId": "c1", "distance": 0, "driverId": 6, "invoiced": false, "disposeTo": "", "timeStart": "03:06", "vehicleNo": "X1234Y", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["General Waste"], "sigPosition": ""}, {"id": 26, "tDO": 0, "_pay": 8, "date": "2026-07-27", "doNo": 0, "tEnd": 1785134494000, "_addr": "2 Woodlands Sector 1, #05-18", "_type": "Delivery", "binIn": "5092", "jobId": 47, "price": 8, "waste": "General Waste", "_sales": "", "_surch": "", "binOut": "", "doType": "land", "photos": [{"id": "ms2uzua3-BININ-47-1.jpg", "ts": 1785134494000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms2uzua3-BININ-47-1.jpg", "kind": "in", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms2uzua3-BININ-47-1.jpg"}], "tBinIn": 1785134494000, "vessel": null, "weight": {"net": 1, "tare": 2, "gross": 3, "ticket": "LR38"}, "_charge": 8, "_client": "Sys-Mac Automation Engineering Pte Ltd", "_driver": "Yao Jun", "jobType": "Delivery", "remarks": "", "sigName": "", "tAccept": 1785134455812, "tBinOut": 0, "tServer": 1785134508555, "tWeight": 0, "timeEnd": "", "tonnAdj": 0, "tonnage": 0, "clientId": "cmrkt918eg0z", "distance": 0, "driverId": 5, "invoiced": false, "disposeTo": "", "timeStart": "14:41", "vehicleNo": "XE7126P", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["General Waste"], "sigPosition": ""}, {"id": 27, "tDO": 1785124412000, "_pay": 13, "date": "2026-07-27", "doNo": 26198, "tEnd": 1785123539000, "_addr": "28A Penjuru Close Bin Centre", "_type": "Exchange", "binIn": "L26", "jobId": 48, "price": 13, "waste": "General Waste", "_sales": "", "_surch": "", "binOut": "5098", "doType": "land", "photos": [{"id": "ms2v45as-BININ-48-1.jpg", "ts": 1785124415000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms2v45as-BININ-48-1.jpg", "kind": "in", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms2v45as-BININ-48-1.jpg"}, {"id": "ms2v45hg-BINOUT-48-1.jpg", "ts": 1785123539000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms2v45hg-BINOUT-48-1.jpg", "kind": "out", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms2v45hg-BINOUT-48-1.jpg"}, {"id": "ms2v45mh-DO-48-1.jpg", "ts": 1785124412000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms2v45mh-DO-48-1.jpg", "kind": "do", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms2v45mh-DO-48-1.jpg"}], "tBinIn": 1785124415000, "vessel": null, "weight": {"net": 2690, "tare": 14100, "gross": 16790, "ticket": "LR16"}, "_charge": 13, "_client": "Eng Leng Contractors Pte Ltd", "_driver": "Yao Jun", "jobType": "Exchange", "remarks": "", "sigName": "", "tAccept": 1785134605462, "tBinOut": 1785123539000, "tServer": 1785134709460, "tWeight": 0, "timeEnd": "11:38", "tonnAdj": 0, "tonnage": 0, "clientId": "cmrkt91888e3", "distance": 0, "driverId": 5, "invoiced": false, "disposeTo": "Lirich Resources Pte Ltd", "timeStart": "11:53", "vehicleNo": "XE7126P", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["General Waste"], "sigPosition": ""}, {"id": 28, "tDO": 1785134494000, "_pay": 13, "date": "2026-07-27", "doNo": 0, "tEnd": 1785127484000, "_addr": "Pandan Loop, Blk K, (Phase 1), Bin Centre", "_type": "Exchange", "binIn": "5198", "jobId": 49, "price": 13, "waste": "General Waste", "_sales": "", "_surch": "", "binOut": "L51", "doType": "land", "photos": [{"id": "ms2xeq8v-BININ-49-1.jpg", "ts": 1785127456000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms2xeq8v-BININ-49-1.jpg", "kind": "in", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms2xeq8v-BININ-49-1.jpg"}, {"id": "ms2xeqky-BINOUT-49-1.jpg", "ts": 1785127484000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms2xeqky-BINOUT-49-1.jpg", "kind": "out", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms2xeqky-BINOUT-49-1.jpg"}, {"id": "ms2xeqp9-DO-49-1.jpg", "ts": 1785134494000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms2xeqp9-DO-49-1.jpg", "kind": "do", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms2xeqp9-DO-49-1.jpg"}], "tBinIn": 1785127456000, "vessel": null, "weight": {"net": 3480, "tare": 14100, "gross": 17580, "ticket": "LR17"}, "_charge": 13, "_client": "Eng Leng Contractors Pte Ltd", "_driver": "Yao Jun", "jobType": "Exchange", "remarks": "", "sigName": "", "tAccept": 1785138356571, "tBinOut": 1785127484000, "tServer": 1785138562398, "tWeight": 0, "timeEnd": "12:44", "tonnAdj": 0, "tonnage": 0, "clientId": "cmrkt91888e3", "distance": 0, "driverId": 5, "invoiced": false, "disposeTo": "Lirich Resources Pte Ltd", "timeStart": "12:44", "vehicleNo": "XE7126P", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["General Waste"], "sigPosition": ""}, {"id": 29, "tDO": 1785145949000, "_pay": 13, "date": "2026-07-27", "doNo": 26197, "tEnd": 1785145926000, "_addr": "5 Gul Drive", "_type": "Exchange", "binIn": "L46", "jobId": 50, "price": 13, "waste": "General Waste", "_sales": "", "_surch": "", "binOut": "L46", "doType": "land", "photos": [{"id": "ms31u4uy-BININ-50-1.jpg", "ts": 1785145926000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms31u4uy-BININ-50-1.jpg", "kind": "in", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms31u4uy-BININ-50-1.jpg"}, {"id": "ms31u53y-BINOUT-50-1.jpg", "ts": 1785145926000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms31u53y-BINOUT-50-1.jpg", "kind": "out", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms31u53y-BINOUT-50-1.jpg"}, {"id": "ms31u58y-DO-50-1.jpg", "ts": 1785145949000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms31u58y-DO-50-1.jpg", "kind": "do", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms31u58y-DO-50-1.jpg"}], "tBinIn": 1785145926000, "vessel": null, "weight": {"net": 2570, "tare": 14200, "gross": 16770, "ticket": "LR18"}, "_charge": 13, "_client": "Qualicoat Pte Ltd", "_driver": "Yao Jun", "jobType": "Exchange", "remarks": "", "sigName": "", "tAccept": 1785145936778, "tBinOut": 1785145926000, "tServer": 1785145999642, "tWeight": 0, "timeEnd": "17:52", "tonnAdj": 0, "tonnage": 0, "clientId": "cmrkt918a8k1", "distance": 0.5, "driverId": 5, "invoiced": false, "disposeTo": "Lirich Resources Pte Ltd", "timeStart": "17:52", "vehicleNo": "XE7126P", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["General Waste"], "sigPosition": ""}, {"id": 30, "tDO": 1785137632000, "_pay": 18, "date": "2026-07-27", "doNo": 130359, "tEnd": 1785137152000, "_addr": "79 Anson Road", "_type": "Exchange", "binIn": "5132", "jobId": 51, "price": 18, "waste": "General Waste", "_sales": "", "_surch": "", "binOut": "5070", "doType": "land", "photos": [{"id": "ms31xbl4-BININ-51-1.jpg", "ts": 1785136949000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms31xbl4-BININ-51-1.jpg", "kind": "in", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms31xbl4-BININ-51-1.jpg"}, {"id": "ms31xbql-BINOUT-51-1.jpg", "ts": 1785137152000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms31xbql-BINOUT-51-1.jpg", "kind": "out", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms31xbql-BINOUT-51-1.jpg"}, {"id": "ms31xbw7-DO-51-1.jpg", "ts": 1785137632000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms31xbw7-DO-51-1.jpg", "kind": "do", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms31xbw7-DO-51-1.jpg"}], "tBinIn": 1785136949000, "vessel": null, "weight": {"net": 1, "tare": 2, "gross": 3, "ticket": "LR39"}, "_charge": 18, "_client": "HCG", "_driver": "Yao Jun", "jobType": "Exchange", "remarks": "", "sigName": "", "tAccept": 1785146080042, "tBinOut": 1785137152000, "tServer": 1785146148328, "tWeight": 0, "timeEnd": "15:25", "tonnAdj": 0, "tonnage": 0, "clientId": "cmrkt9189v5w", "distance": 0, "driverId": 5, "invoiced": false, "disposeTo": "", "timeStart": "15:22", "vehicleNo": "XE7126P", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["General Waste"], "sigPosition": ""}, {"id": 31, "tDO": 0, "_pay": 19.5, "date": "2026-07-27", "doNo": 0, "tEnd": 1785131039000, "_addr": "Gul", "_type": "Exchange", "binIn": "8000", "jobId": 52, "price": 19.5, "waste": "General Waste", "_sales": "", "_surch": "", "binOut": "8000", "doType": "land", "photos": [{"id": "ms31ynjl-BININ-52-1.jpg", "ts": 1785131039000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms31ynjl-BININ-52-1.jpg", "kind": "in", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms31ynjl-BININ-52-1.jpg"}, {"id": "ms31ynw7-BINOUT-52-1.jpg", "ts": 1785131039000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms31ynw7-BINOUT-52-1.jpg", "kind": "out", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms31ynw7-BINOUT-52-1.jpg"}], "tBinIn": 1785131039000, "vessel": null, "weight": {"net": 5010, "tare": 15750, "gross": 20760, "ticket": "LR19"}, "_charge": 19.5, "_client": "ST", "_driver": "Yao Jun", "jobType": "Exchange", "remarks": "", "sigName": "", "tAccept": 1785146176560, "tBinOut": 1785131039000, "tServer": 1785146210481, "tWeight": 0, "timeEnd": "13:43", "tonnAdj": 0, "tonnage": 0, "clientId": "cmrkt918dn4k", "distance": 0, "driverId": 5, "invoiced": false, "disposeTo": "", "timeStart": "13:43", "vehicleNo": "XE7126P", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["General Waste"], "sigPosition": ""}, {"id": 32, "tDO": 1785148717000, "_pay": 13, "date": "2026-07-27", "doNo": 26200, "tEnd": 1785147904000, "_addr": "11 Pioneer Turn L601", "_type": "Exchange", "binIn": "5196", "jobId": 53, "price": 13, "waste": "General Waste", "_sales": "", "_surch": "", "binOut": "L26", "doType": "land", "photos": [{"id": "ms33hlne-BININ-53-1.jpg", "ts": 1785148021000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms33hlne-BININ-53-1.jpg", "kind": "in", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms33hlne-BININ-53-1.jpg"}, {"id": "ms33hlvi-BINOUT-53-1.jpg", "ts": 1785147904000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms33hlvi-BINOUT-53-1.jpg", "kind": "out", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms33hlvi-BINOUT-53-1.jpg"}, {"id": "ms33hlzc-DO-53-1.jpg", "ts": 1785148717000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms33hlzc-DO-53-1.jpg", "kind": "do", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms33hlzc-DO-53-1.jpg"}], "tBinIn": 1785148021000, "vessel": null, "weight": {"net": 710, "tare": 14120, "gross": 14830, "ticket": "LR20"}, "_charge": 13, "_client": "Savills Property Management Pte Ltd (Green Hub)", "_driver": "Yao Jun", "jobType": "Exchange", "remarks": "", "sigName": "", "tAccept": 1785147961672, "tBinOut": 1785147904000, "tServer": 1785148774105, "tWeight": 0, "timeEnd": "18:25", "tonnAdj": 0, "tonnage": 0, "clientId": "cmrkt918aco2", "distance": 0, "driverId": 5, "invoiced": false, "disposeTo": "", "timeStart": "18:27", "vehicleNo": "XE7126P", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["General Waste"], "sigPosition": ""}, {"id": 33, "tDO": 0, "_pay": 18, "date": "2026-07-28", "doNo": 0, "tEnd": 1785199384000, "_addr": "5 Sungei Kadut Street 6", "_type": "Dump", "binIn": "", "jobId": 68, "price": 18, "waste": "General Waste", "_sales": "", "_surch": "", "binOut": "", "doType": "land", "photos": [{"id": "ms3z2m8u-BIN-68-1.jpg", "ts": 1785199384000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms3z2m8u-BIN-68-1.jpg", "kind": "bin", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms3z2m8u-BIN-68-1.jpg"}], "tBinIn": 0, "vessel": null, "weight": {"net": 3160, "tare": 14150, "gross": 17310, "ticket": "LR21"}, "_charge": 18, "_client": "Beejoo", "_driver": "Yao Jun", "jobType": "Dump", "remarks": "", "sigName": "", "tAccept": 1785201809513, "tBinOut": 0, "tServer": 1785201822750, "tWeight": 0, "timeEnd": "08:43", "tonnAdj": 0, "tonnage": 0, "clientId": "cmrkt9187viy", "distance": 0, "driverId": 5, "invoiced": false, "disposeTo": "", "timeStart": "09:23", "vehicleNo": "", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": [], "sigPosition": ""}, {"id": 34, "tDO": 1785208546000, "_pay": 13, "date": "2026-07-28", "doNo": 26052, "tEnd": 1785208393000, "_addr": "118 Pioneer Road L7", "_type": "Exchange", "binIn": "R11", "jobId": 70, "price": 13, "waste": "Wood Waste", "_sales": "Marcus", "_surch": "", "binOut": "7017", "doType": "land", "photos": [{"id": "ms433t2h-BININ-70-1.jpg", "ts": 1785208391000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms433t2h-BININ-70-1.jpg", "kind": "in", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms433t2h-BININ-70-1.jpg"}, {"id": "ms433tap-BINOUT-70-1.jpg", "ts": 1785208393000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms433tap-BINOUT-70-1.jpg", "kind": "out", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms433tap-BINOUT-70-1.jpg"}, {"id": "ms433tej-DO-70-1.jpg", "ts": 1785208546000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms433tej-DO-70-1.jpg", "kind": "do", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms433tej-DO-70-1.jpg"}], "tBinIn": 1785208391000, "vessel": null, "weight": {"net": 2670, "tare": 15150, "gross": 17820, "ticket": "LR22"}, "_charge": 13, "_client": "Radha Exports Pte Ltd", "_driver": "Yao Jun", "jobType": "Exchange", "remarks": "", "sigName": "", "tAccept": 1785207997114, "tBinOut": 1785208393000, "tServer": 1785208596713, "tWeight": 0, "timeEnd": "11:13", "tonnAdj": 0, "tonnage": 0, "clientId": "c2", "distance": 0, "driverId": 5, "invoiced": false, "disposeTo": "", "timeStart": "11:13", "vehicleNo": "XE7126P", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["Wood Waste"], "sigPosition": ""}, {"id": 35, "tDO": 1785211776000, "_pay": 13, "date": "2026-07-28", "doNo": 26053, "tEnd": 1785211617000, "_addr": "118 Pioneer Road L7", "_type": "Exchange", "binIn": "7017", "jobId": 69, "price": 13, "waste": "Wood Waste", "_sales": "Marcus", "_surch": "", "binOut": "7006", "doType": "land", "photos": [{"id": "ms451ots-BININ-69-1.jpg", "ts": 1785211619000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms451ots-BININ-69-1.jpg", "kind": "in", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms451ots-BININ-69-1.jpg"}, {"id": "ms451p23-BINOUT-69-1.jpg", "ts": 1785211617000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms451p23-BINOUT-69-1.jpg", "kind": "out", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms451p23-BINOUT-69-1.jpg"}, {"id": "ms451p83-DO-69-1.jpg", "ts": 1785211776000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms451p83-DO-69-1.jpg", "kind": "do", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms451p83-DO-69-1.jpg"}], "tBinIn": 1785211619000, "vessel": null, "weight": {"net": 2460, "tare": 14520, "gross": 16980, "ticket": "LR23"}, "_charge": 13, "_client": "Radha Exports Pte Ltd", "_driver": "Yao Jun", "jobType": "Exchange", "remarks": "", "sigName": "", "tAccept": 1785210786199, "tBinOut": 1785211617000, "tServer": 1785211857136, "tWeight": 0, "timeEnd": "12:06", "tonnAdj": 0, "tonnage": 0, "clientId": "c2", "distance": 0, "driverId": 5, "invoiced": false, "disposeTo": "", "timeStart": "12:06", "vehicleNo": "XE7126P", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["Wood Waste"], "sigPosition": ""}, {"id": 36, "tDO": 1785282628000, "_pay": 13, "date": "2026-07-29", "doNo": 26057, "tEnd": 1785281077000, "_addr": "60 Benoi Road", "_type": "Exchange", "binIn": "5047", "jobId": 71, "price": 13, "waste": "General Waste", "_sales": "", "_surch": "", "binOut": "L57", "doType": "land", "photos": [{"id": "ms5atplk-BININ-71-1.jpg", "ts": 1785281069000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5atplk-BININ-71-1.jpg", "kind": "in", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5atplk-BININ-71-1.jpg"}, {"id": "ms5atpuq-BINOUT-71-1.jpg", "ts": 1785281077000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5atpuq-BINOUT-71-1.jpg", "kind": "out", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5atpuq-BINOUT-71-1.jpg"}, {"id": "ms5b71vv-DO-71-1.jpg", "ts": 1785282628000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5b71vv-DO-71-1.jpg", "kind": "do", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5b71vv-DO-71-1.jpg"}], "tBinIn": 1785281069000, "vessel": null, "weight": {"net": 2390, "tare": 14450, "gross": 16840, "ticket": "LR24"}, "_charge": 13, "_client": "EverTeam Pte Ltd", "_driver": "Yao Jun", "jobType": "Exchange", "remarks": "", "sigName": "", "tAccept": 1785281998227, "tBinOut": 1785281077000, "tServer": 1785282028760, "tWeight": 0, "timeEnd": "07:24", "tonnAdj": 0, "tonnage": 0, "clientId": "cmrkt9189j9t", "distance": 0, "driverId": 5, "invoiced": false, "disposeTo": "", "timeStart": "07:24", "vehicleNo": "XE7126P", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["General Waste"], "sigPosition": ""}, {"id": 37, "tDO": 1785311973000, "_pay": 19.5, "date": "2026-07-29", "doNo": 43184, "tEnd": 1785284712000, "_addr": "Gul", "_type": "Exchange", "binIn": "6006", "jobId": 72, "price": 19.5, "waste": "General Waste", "_sales": "", "_surch": "", "binOut": "6006", "doType": "land", "photos": [{"id": "ms5soxc5-BININ-72-1.jpg", "ts": 1785284712000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5soxc5-BININ-72-1.jpg", "kind": "in", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5soxc5-BININ-72-1.jpg"}, {"id": "ms5soxml-BINOUT-72-1.jpg", "ts": 1785284712000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5soxml-BINOUT-72-1.jpg", "kind": "out", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5soxml-BINOUT-72-1.jpg"}, {"id": "ms5soxqm-DO-72-1.jpg", "ts": 1785311973000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5soxqm-DO-72-1.jpg", "kind": "do", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5soxqm-DO-72-1.jpg"}], "tBinIn": 1785284712000, "vessel": null, "weight": {"net": 2820, "tare": 14050, "gross": 16870, "ticket": "LR25"}, "_charge": 19.5, "_client": "ST", "_driver": "Yao Jun", "jobType": "Exchange", "remarks": "", "sigName": "", "tAccept": 1785311949328, "tBinOut": 1785284712000, "tServer": 1785312038597, "tWeight": 0, "timeEnd": "08:25", "tonnAdj": 0, "tonnage": 0, "clientId": "cmrkt918dn4k", "distance": 0, "driverId": 5, "invoiced": false, "disposeTo": "", "timeStart": "08:25", "vehicleNo": "XE7126P", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["General Waste"], "sigPosition": ""}, {"id": 38, "tDO": 1785311980000, "_pay": 19.5, "date": "2026-07-29", "doNo": 43183, "tEnd": 1785284704000, "_addr": "Gul", "_type": "Exchange", "binIn": "8000", "jobId": 73, "price": 19.5, "waste": "Wood Waste", "_sales": "", "_surch": "", "binOut": "8000", "doType": "land", "photos": [{"id": "ms5sqrla-BININ-73-1.jpg", "ts": 1785284704000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5sqrla-BININ-73-1.jpg", "kind": "in", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5sqrla-BININ-73-1.jpg"}, {"id": "ms5sqrrd-BINOUT-73-1.jpg", "ts": 1785284704000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5sqrrd-BINOUT-73-1.jpg", "kind": "out", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5sqrrd-BINOUT-73-1.jpg"}, {"id": "ms5sqrw2-DO-73-1.jpg", "ts": 1785311980000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5sqrw2-DO-73-1.jpg", "kind": "do", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5sqrw2-DO-73-1.jpg"}], "tBinIn": 1785284704000, "vessel": null, "weight": {"net": 1790, "tare": 15830, "gross": 17620, "ticket": "LR26"}, "_charge": 19.5, "_client": "ST", "_driver": "Yao Jun", "jobType": "Exchange", "remarks": "", "sigName": "", "tAccept": 1785312078493, "tBinOut": 1785284704000, "tServer": 1785312124462, "tWeight": 0, "timeEnd": "08:25", "tonnAdj": 0, "tonnage": 0, "clientId": "cmrkt918dn4k", "distance": 0, "driverId": 5, "invoiced": false, "disposeTo": "", "timeStart": "08:25", "vehicleNo": "XE7126P", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["Wood Waste"], "sigPosition": ""}, {"id": 39, "tDO": 1785311986000, "_pay": 19.5, "date": "2026-07-29", "doNo": 43186, "tEnd": 1785307741000, "_addr": "Gul", "_type": "Exchange", "binIn": "6005", "jobId": 74, "price": 19.5, "waste": "General Waste", "_sales": "", "_surch": "", "binOut": "6005", "doType": "land", "photos": [{"id": "ms5ss9ma-BININ-74-1.jpg", "ts": 1785307741000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5ss9ma-BININ-74-1.jpg", "kind": "in", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5ss9ma-BININ-74-1.jpg"}, {"id": "ms5ss9rk-BINOUT-74-1.jpg", "ts": 1785307741000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5ss9rk-BINOUT-74-1.jpg", "kind": "out", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5ss9rk-BINOUT-74-1.jpg"}, {"id": "ms5ss9vo-DO-74-1.jpg", "ts": 1785311986000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5ss9vo-DO-74-1.jpg", "kind": "do", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5ss9vo-DO-74-1.jpg"}], "tBinIn": 1785307741000, "vessel": null, "weight": {"net": 2630, "tare": 13950, "gross": 16580, "ticket": "LR27"}, "_charge": 19.5, "_client": "ST", "_driver": "Yao Jun", "jobType": "Exchange", "remarks": "", "sigName": "", "tAccept": 1785312160754, "tBinOut": 1785307741000, "tServer": 1785312194482, "tWeight": 0, "timeEnd": "14:49", "tonnAdj": 0, "tonnage": 0, "clientId": "cmrkt918dn4k", "distance": 0, "driverId": 5, "invoiced": false, "disposeTo": "", "timeStart": "14:49", "vehicleNo": "XE7126P", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["General Waste"], "sigPosition": ""}, {"id": 40, "tDO": 1785290494000, "_pay": 13, "date": "2026-07-29", "doNo": 0, "tEnd": 1785290494000, "_addr": "NEA Tuas", "_type": "Exchange", "binIn": "R13", "jobId": 75, "price": 13, "waste": "General Waste", "_sales": "", "_surch": "", "binOut": "R13", "doType": "land", "photos": [{"id": "ms5su7xq-BININ-75-1.jpg", "ts": 1785290494000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5su7xq-BININ-75-1.jpg", "kind": "in", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5su7xq-BININ-75-1.jpg"}, {"id": "ms5su81m-BINOUT-75-1.jpg", "ts": 1785290494000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5su81m-BINOUT-75-1.jpg", "kind": "out", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5su81m-BINOUT-75-1.jpg"}, {"id": "ms5su85q-DO-75-1.jpg", "ts": 1785290494000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5su85q-DO-75-1.jpg", "kind": "do", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5su85q-DO-75-1.jpg"}], "tBinIn": 1785290494000, "vessel": null, "weight": {"net": 6610, "tare": 15860, "gross": 22470, "ticket": "LR28"}, "_charge": 13, "_client": "NEA", "_driver": "Yao Jun", "jobType": "Exchange", "remarks": "", "sigName": "", "tAccept": 1785312245751, "tBinOut": 1785290494000, "tServer": 1785312285614, "tWeight": 0, "timeEnd": "10:01", "tonnAdj": 0, "tonnage": 0, "clientId": "cmrkt918ate4", "distance": 7.7, "driverId": 5, "invoiced": false, "disposeTo": "NEA", "timeStart": "10:01", "vehicleNo": "XE7126P", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["General Waste"], "sigPosition": ""}, {"id": 41, "tDO": 1785296148000, "_pay": 13, "date": "2026-07-29", "doNo": 0, "tEnd": 1785296148000, "_addr": "NEA Tuas", "_type": "Exchange", "binIn": "R13", "jobId": 76, "price": 13, "waste": "General Waste", "_sales": "", "_surch": "", "binOut": "R13", "doType": "land", "photos": [{"id": "ms5svucu-BININ-76-1.jpg", "ts": 1785296148000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5svucu-BININ-76-1.jpg", "kind": "in", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5svucu-BININ-76-1.jpg"}, {"id": "ms5svuiu-BINOUT-76-1.jpg", "ts": 1785296148000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5svuiu-BINOUT-76-1.jpg", "kind": "out", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5svuiu-BINOUT-76-1.jpg"}, {"id": "ms5svumm-DO-76-1.jpg", "ts": 1785296148000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5svumm-DO-76-1.jpg", "kind": "do", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5svumm-DO-76-1.jpg"}], "tBinIn": 1785296148000, "vessel": null, "weight": {"net": 7390, "tare": 15860, "gross": 23250, "ticket": "LR29"}, "_charge": 13, "_client": "NEA", "_driver": "Yao Jun", "jobType": "Exchange", "remarks": "", "sigName": "", "tAccept": 1785312325410, "tBinOut": 1785296148000, "tServer": 1785312361326, "tWeight": 0, "timeEnd": "11:35", "tonnAdj": 0, "tonnage": 0, "clientId": "cmrkt918ate4", "distance": 0, "driverId": 5, "invoiced": false, "disposeTo": "", "timeStart": "11:35", "vehicleNo": "XE7126P", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["General Waste"], "sigPosition": ""}, {"id": 42, "tDO": 1785303839000, "_pay": 23, "date": "2026-07-29", "doNo": 26058, "tEnd": 1785300696000, "_addr": "Ophir Road LP 14/1F", "_type": "Exchange", "binIn": "L804", "jobId": 77, "price": 23, "waste": "General Waste", "_sales": "", "_surch": "", "binOut": "L808", "doType": "land", "photos": [{"id": "ms5sy324-BININ-77-1.jpg", "ts": 1785300590000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5sy324-BININ-77-1.jpg", "kind": "in", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5sy324-BININ-77-1.jpg"}, {"id": "ms5sy370-BINOUT-77-1.jpg", "ts": 1785300696000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5sy370-BINOUT-77-1.jpg", "kind": "out", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5sy370-BINOUT-77-1.jpg"}, {"id": "ms5sy3bv-DO-77-1.jpg", "ts": 1785303839000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5sy3bv-DO-77-1.jpg", "kind": "do", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5sy3bv-DO-77-1.jpg"}], "tBinIn": 1785300590000, "vessel": null, "weight": {"net": 1740, "tare": 14050, "gross": 15790, "ticket": "LR30"}, "_charge": 23, "_client": "GS Engineering and Construction Corporation", "_driver": "Yao Jun", "jobType": "Exchange", "remarks": "", "sigName": "", "tAccept": 1785312421081, "tBinOut": 1785300696000, "tServer": 1785312465916, "tWeight": 0, "timeEnd": "12:51", "tonnAdj": 0, "tonnage": 0, "clientId": "cmrkt9189hjd", "distance": 0, "driverId": 5, "invoiced": false, "disposeTo": "", "timeStart": "12:49", "vehicleNo": "XE7126P", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["General Waste"], "sigPosition": ""}, {"id": 43, "tDO": 1785312797000, "_pay": 23, "date": "2026-07-29", "doNo": 26060, "tEnd": 1785311207000, "_addr": "100 Beach Road", "_type": "Exchange", "binIn": "5079", "jobId": 78, "price": 23, "waste": "General Waste", "_sales": "", "_surch": "", "binOut": "5079", "doType": "land", "photos": [{"id": "ms5t6p8d-BININ-78-1.jpg", "ts": 1785311211000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5t6p8d-BININ-78-1.jpg", "kind": "in", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5t6p8d-BININ-78-1.jpg"}, {"id": "ms5t6pem-BINOUT-78-1.jpg", "ts": 1785311207000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5t6pem-BINOUT-78-1.jpg", "kind": "out", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5t6pem-BINOUT-78-1.jpg"}, {"id": "ms5t6plv-DO-78-1.jpg", "ts": 1785312797000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5t6plv-DO-78-1.jpg", "kind": "do", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5t6plv-DO-78-1.jpg"}], "tBinIn": 1785311211000, "vessel": null, "weight": {"net": 4560, "tare": 14150, "gross": 18710, "ticket": "LR32"}, "_charge": 23, "_client": "Hyundai Engineering & Construction Co., Ltd", "_driver": "Yao Jun", "jobType": "Exchange", "remarks": "", "sigName": "", "tAccept": 1785312538394, "tBinOut": 1785311207000, "tServer": 1785312867901, "tWeight": 0, "timeEnd": "15:46", "tonnAdj": 0, "tonnage": 0, "clientId": "cmrkt918azpz", "distance": 0, "driverId": 5, "invoiced": false, "disposeTo": "", "timeStart": "15:46", "vehicleNo": "XE7126P", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["General Waste"], "sigPosition": ""}, {"id": 44, "tDO": 0, "_pay": 13, "date": "2026-07-29", "doNo": 0, "tEnd": 1785320688000, "_addr": "NEA Tuas", "_type": "Exchange", "binIn": "R02", "jobId": 79, "price": 13, "waste": "General Waste", "_sales": "", "_surch": "", "binOut": "R02", "doType": "land", "photos": [{"id": "ms5xviy1-BININ-79-1.jpg", "ts": 1785320688000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5xviy1-BININ-79-1.jpg", "kind": "in", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5xviy1-BININ-79-1.jpg"}, {"id": "ms5xvjmq-BINOUT-79-1.jpg", "ts": 1785320688000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5xvjmq-BINOUT-79-1.jpg", "kind": "out", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5xvjmq-BINOUT-79-1.jpg"}], "tBinIn": 1785320688000, "vessel": null, "weight": {"net": 6880, "tare": 15610, "gross": 22490, "ticket": "LR31"}, "_charge": 13, "_client": "NEA", "_driver": "Yao Jun", "jobType": "Exchange", "remarks": "", "sigName": "", "tAccept": 1785315997949, "tBinOut": 1785320688000, "tServer": 1785316032421, "tWeight": 0, "timeEnd": "18:24", "tonnAdj": 0, "tonnage": 0, "clientId": "cmrkt918ate4", "distance": 0, "driverId": 5, "invoiced": false, "disposeTo": "", "timeStart": "18:24", "vehicleNo": "XE7126P", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["General Waste"], "sigPosition": ""}, {"id": 45, "tDO": 1785323625000, "_pay": 13, "date": "2026-07-29", "doNo": 26059, "tEnd": 1785323384000, "_addr": "80 Tuas West Drive", "_type": "Exchange", "binIn": "5079", "jobId": 80, "price": 13, "waste": "General Waste", "_sales": "", "_surch": "", "binOut": "5224", "doType": "land", "photos": [{"id": "ms5zmslm-BININ-80-1.jpg", "ts": 1785323391000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5zmslm-BININ-80-1.jpg", "kind": "in", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5zmslm-BININ-80-1.jpg"}, {"id": "ms5zmstf-BINOUT-80-1.jpg", "ts": 1785323384000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5zmstf-BINOUT-80-1.jpg", "kind": "out", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5zmstf-BINOUT-80-1.jpg"}, {"id": "ms5zmsyg-DO-80-1.jpg", "ts": 1785323625000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5zmsyg-DO-80-1.jpg", "kind": "do", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5zmsyg-DO-80-1.jpg"}], "tBinIn": 1785323391000, "vessel": null, "weight": {"net": 2210, "tare": 14100, "gross": 16310, "ticket": "LR33"}, "_charge": 13, "_client": "INVX Asia Pacific Pte Ltd", "_driver": "Yao Jun", "jobType": "Exchange", "remarks": "", "sigName": "", "tAccept": 1785322902253, "tBinOut": 1785323384000, "tServer": 1785323696458, "tWeight": 0, "timeEnd": "19:09", "tonnAdj": 0, "tonnage": 0, "clientId": "cmrkt918as3h", "distance": 0, "driverId": 5, "invoiced": false, "disposeTo": "", "timeStart": "19:09", "vehicleNo": "XE7126P", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["General Waste"], "sigPosition": ""}, {"id": 46, "tDO": 0, "_pay": 18, "date": "2026-07-30", "doNo": 0, "tEnd": 1785369725000, "_addr": "5 Sungei Kadut Street 6", "_type": "Dump", "binIn": "", "jobId": 86, "price": 18, "waste": "Wood Waste", "_sales": "", "_surch": "", "binOut": "", "doType": "land", "photos": [{"id": "ms6rc9rj-BIN-86-1.jpg", "ts": 1785369725000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms6rc9rj-BIN-86-1.jpg", "kind": "bin", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms6rc9rj-BIN-86-1.jpg"}], "tBinIn": 0, "vessel": null, "weight": {"net": 5000, "tare": 15470, "gross": 20470, "ticket": "LR43"}, "_charge": 18, "_client": "Beejoo", "_driver": "Yao Jun", "jobType": "Dump", "remarks": "", "sigName": "", "tAccept": 1785357335082, "tBinOut": 0, "tServer": 1785370234735, "tWeight": 0, "timeEnd": "08:02", "tonnAdj": 0, "tonnage": 0, "clientId": "cmrkt9187viy", "distance": 0, "driverId": 5, "invoiced": false, "disposeTo": "Bee Joo", "timeStart": "04:35", "vehicleNo": "", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": [], "sigPosition": ""}, {"id": 47, "tDO": 1785373234000, "_pay": 13, "date": "2026-07-30", "doNo": 26061, "tEnd": 1785373020000, "_addr": "31 Tuas West Drive, Lamppost 74F", "_type": "Exchange", "binIn": "L29", "jobId": 92, "price": 13, "waste": "General Waste", "_sales": "", "_surch": "", "binOut": "L29", "doType": "land", "photos": [{"id": "ms6t5ylt-BININ-92-1.jpg", "ts": 1785373020000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms6t5ylt-BININ-92-1.jpg", "kind": "in", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms6t5ylt-BININ-92-1.jpg"}, {"id": "ms6t5yzk-BINOUT-92-1.jpg", "ts": 1785373020000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms6t5yzk-BINOUT-92-1.jpg", "kind": "out", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms6t5yzk-BINOUT-92-1.jpg"}, {"id": "ms6t5zcv-DO-92-1.jpg", "ts": 1785373234000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms6t5zcv-DO-92-1.jpg", "kind": "do", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms6t5zcv-DO-92-1.jpg"}], "tBinIn": 1785373020000, "vessel": null, "weight": {"net": 7020, "tare": 14050, "gross": 21070, "ticket": "LR41"}, "_charge": 13, "_client": "Hyundai Engineering & Construction Co., Ltd", "_driver": "Yao Jun", "jobType": "Exchange", "remarks": "", "sigName": "", "tAccept": 1785373221523, "tBinOut": 1785373020000, "tServer": 1785373299569, "tWeight": 0, "timeEnd": "08:57", "tonnAdj": 0, "tonnage": 0, "clientId": "cmrkt918azpz", "distance": 0, "driverId": 5, "invoiced": false, "disposeTo": "", "timeStart": "08:57", "vehicleNo": "XE7126P", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["General Waste"], "sigPosition": ""}, {"id": 48, "tDO": 1785373234000, "_pay": 8, "date": "2026-07-30", "doNo": 26061, "tEnd": 1785373020000, "_addr": "31 Tuas West Drive, Lamppost 74F", "_type": "Delivery", "binIn": "L29", "jobId": 93, "price": 8, "waste": "General Waste", "_sales": "", "_surch": "", "binOut": "", "doType": "land", "photos": [{"id": "ms6u83cm-BININ-93-1.jpg", "ts": 1785373020000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms6u83cm-BININ-93-1.jpg", "kind": "in", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms6u83cm-BININ-93-1.jpg"}, {"id": "ms6u83mv-DO-93-1.jpg", "ts": 1785373234000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms6u83mv-DO-93-1.jpg", "kind": "do", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms6u83mv-DO-93-1.jpg"}], "tBinIn": 1785373020000, "vessel": null, "weight": {"net": 7020, "tare": 14050, "gross": 21070, "ticket": "LR42"}, "_charge": 8, "_client": "Hyundai Engineering & Construction Co., Ltd", "_driver": "Yao Jun", "jobType": "Delivery", "remarks": "", "sigName": "", "tAccept": 1785375047962, "tBinOut": 0, "tServer": 1785375078646, "tWeight": 0, "timeEnd": "", "tonnAdj": 0, "tonnage": 0, "clientId": "cmrkt918azpz", "distance": 0, "driverId": 5, "invoiced": false, "disposeTo": "", "timeStart": "08:57", "vehicleNo": "XE7126P", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["General Waste"], "sigPosition": ""}, {"id": 49, "tDO": 1785374905000, "_pay": 0, "date": "2026-07-30", "doNo": 0, "tEnd": 1785384824000, "_addr": "", "binIn": "R13", "jobId": 94, "price": 0, "waste": "General Waste", "_sales": "", "_surch": "", "binOut": "R13", "doType": "land", "photos": [{"id": "ms6vl45v-DO-94-1.jpg", "ts": 1785374905000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms6vl45v-DO-94-1.jpg", "kind": "do", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms6vl45v-DO-94-1.jpg"}, {"id": "ms6vl4ed-SIG-94-1.jpg", "ts": 1785377364732, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms6vl4ed-SIG-94-1.jpg", "kind": "signature", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms6vl4ed-SIG-94-1.jpg"}, {"id": "ms701kqr-BININ-94-1.jpg", "ts": 1785383944000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms701kqr-BININ-94-1.jpg", "kind": "in", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms701kqr-BININ-94-1.jpg"}, {"id": "ms701lfz-BINOUT-94-1.jpg", "ts": 1785384824000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms701lfz-BINOUT-94-1.jpg", "kind": "out", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms701lfz-BINOUT-94-1.jpg"}], "tBinIn": 1785383944000, "vessel": null, "weight": {"net": 0, "tare": 0, "gross": 0, "ticket": ""}, "_charge": 0, "_client": "Ecozeal", "_driver": "Liu", "jobType": "", "remarks": "", "sigName": "", "tAccept": 1785376750065, "tBinOut": 1785384824000, "tServer": 1785377365843, "tWeight": 0, "timeEnd": "12:13", "tonnAdj": 0, "tonnage": 0, "clientId": "cms6sx0w2c6g", "distance": 0, "driverId": 4, "invoiced": false, "disposeTo": "", "timeStart": "11:59", "vehicleNo": "XE8496P", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["General Waste"], "sigPosition": ""}, {"id": 50, "tDO": 1785378580000, "_pay": 19.5, "date": "2026-07-30", "doNo": 43109, "tEnd": 1785378242000, "_addr": "Gul", "_type": "Exchange", "binIn": "6006", "jobId": 87, "price": 19.5, "waste": "General Waste", "_sales": "", "_surch": "", "binOut": "6006", "doType": "land", "photos": [{"id": "ms6wbvag-BININ-87-1.jpg", "ts": 1785378242000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms6wbvag-BININ-87-1.jpg", "kind": "in", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms6wbvag-BININ-87-1.jpg"}, {"id": "ms6wbvjf-BINOUT-87-1.jpg", "ts": 1785378242000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms6wbvjf-BINOUT-87-1.jpg", "kind": "out", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms6wbvjf-BINOUT-87-1.jpg"}, {"id": "ms6wbvrq-DO-87-1.jpg", "ts": 1785378580000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms6wbvrq-DO-87-1.jpg", "kind": "do", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms6wbvrq-DO-87-1.jpg"}, {"id": "ms6wbvv6-SIG-87-1.jpg", "ts": 1785378610760, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms6wbvv6-SIG-87-1.jpg", "kind": "signature", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms6wbvv6-SIG-87-1.jpg"}], "tBinIn": 1785378242000, "vessel": null, "weight": {"net": 3630, "tare": 14100, "gross": 17730, "ticket": "LR40"}, "_charge": 19.5, "_client": "ST", "_driver": "Yao Jun", "jobType": "Exchange", "remarks": "", "sigName": "", "tAccept": 1785378545827, "tBinOut": 1785378242000, "tServer": 1785378614056, "tWeight": 0, "timeEnd": "10:24", "tonnAdj": 0, "tonnage": 0, "clientId": "cmrkt918dn4k", "distance": 0.4, "driverId": 5, "invoiced": false, "disposeTo": "Lirich Resources Pte Ltd", "timeStart": "10:24", "vehicleNo": "XE7126P", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["General Waste"], "sigPosition": ""}, {"id": 51, "tDO": 1785382456000, "_pay": 13, "date": "2026-07-30", "doNo": 26062, "tEnd": 1785382335000, "_addr": "11 Pioneer Turn L407", "_type": "Exchange", "binIn": "L29", "jobId": 95, "price": 13, "waste": "General Waste", "_sales": "", "_surch": "", "binOut": "5151", "doType": "land", "photos": [{"id": "ms6ylj60-BININ-95-1.jpg", "ts": 1785382374000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms6ylj60-BININ-95-1.jpg", "kind": "in", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms6ylj60-BININ-95-1.jpg"}, {"id": "ms6yljh2-BINOUT-95-1.jpg", "ts": 1785382335000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms6yljh2-BINOUT-95-1.jpg", "kind": "out", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms6yljh2-BINOUT-95-1.jpg"}, {"id": "ms6ymuzj-DO-95-1.jpg", "ts": 1785382456000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms6ymuzj-DO-95-1.jpg", "kind": "do", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms6ymuzj-DO-95-1.jpg"}], "tBinIn": 1785382374000, "vessel": null, "weight": {"net": 690, "tare": 14320, "gross": 15010, "ticket": "LR44"}, "_charge": 13, "_client": "Savills Property Management Pte Ltd (Green Hub)", "_driver": "Yao Jun", "jobType": "Exchange", "remarks": "", "sigName": "", "tAccept": 1785381915100, "tBinOut": 1785382335000, "tServer": 1785382424136, "tWeight": 0, "timeEnd": "11:32", "tonnAdj": 0, "tonnage": 0, "clientId": "cmrkt918aco2", "distance": 0, "driverId": 5, "invoiced": false, "disposeTo": "", "timeStart": "11:32", "vehicleNo": "XE7126P", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["General Waste"], "sigPosition": ""}, {"id": 52, "tDO": 1785385207000, "_pay": 13, "date": "2026-07-30", "doNo": 26063, "tEnd": 1785384753000, "_addr": "75 Tech Park Crescent", "_type": "Exchange", "binIn": "5151", "jobId": 96, "price": 13, "waste": "Wood Waste", "_sales": "", "_surch": "", "binOut": "5089", "doType": "land", "photos": [{"id": "ms7022jl-BININ-96-1.jpg", "ts": 1785384747000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms7022jl-BININ-96-1.jpg", "kind": "in", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms7022jl-BININ-96-1.jpg"}, {"id": "ms7022tw-BINOUT-96-1.jpg", "ts": 1785384753000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms7022tw-BINOUT-96-1.jpg", "kind": "out", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms7022tw-BINOUT-96-1.jpg"}, {"id": "ms709mp2-DO-96-1.jpg", "ts": 1785385207000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms709mp2-DO-96-1.jpg", "kind": "do", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms709mp2-DO-96-1.jpg"}], "tBinIn": 1785384747000, "vessel": null, "weight": {"net": 4150, "tare": 14050, "gross": 18200, "ticket": "LR45"}, "_charge": 13, "_client": "Faxolif Industries Pte Ltd", "_driver": "Yao Jun", "jobType": "Exchange", "remarks": "", "sigName": "", "tAccept": 1785384844252, "tBinOut": 1785384753000, "tServer": 1785384875361, "tWeight": 0, "timeEnd": "12:12", "tonnAdj": 0, "tonnage": 0, "clientId": "cmrkt9189chy", "distance": 0, "driverId": 5, "invoiced": false, "disposeTo": "", "timeStart": "12:12", "vehicleNo": "XE7126P", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["Wood Waste"], "sigPosition": ""}, {"id": 53, "tDO": 1785389535000, "_pay": 19.5, "date": "2026-07-30", "doNo": 43191, "tEnd": 1785389177000, "_addr": "Gul", "_type": "Exchange", "binIn": "6005", "jobId": 97, "price": 19.5, "waste": "General Waste", "_sales": "", "_surch": "", "binOut": "6005", "doType": "land", "photos": [{"id": "ms72uu5y-BININ-97-1.jpg", "ts": 1785389177000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms72uu5y-BININ-97-1.jpg", "kind": "in", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms72uu5y-BININ-97-1.jpg"}, {"id": "ms72uuhw-BINOUT-97-1.jpg", "ts": 1785389177000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms72uuhw-BINOUT-97-1.jpg", "kind": "out", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms72uuhw-BINOUT-97-1.jpg"}, {"id": "ms72uum7-DO-97-1.jpg", "ts": 1785389535000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms72uum7-DO-97-1.jpg", "kind": "do", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms72uum7-DO-97-1.jpg"}], "tBinIn": 1785389177000, "vessel": null, "weight": {"net": 2400, "tare": 13950, "gross": 16350, "ticket": "LR46"}, "_charge": 19.5, "_client": "ST", "_driver": "Yao Jun", "jobType": "Exchange", "remarks": "", "sigName": "", "tAccept": 1785389529624, "tBinOut": 1785389177000, "tServer": 1785389576758, "tWeight": 0, "timeEnd": "13:26", "tonnAdj": 0, "tonnage": 0, "clientId": "cmrkt918dn4k", "distance": 0, "driverId": 5, "invoiced": false, "disposeTo": "", "timeStart": "13:26", "vehicleNo": "XE7126P", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["General Waste"], "sigPosition": ""}, {"id": 54, "tDO": 1785396779000, "_pay": 18, "date": "2026-07-30", "doNo": 13036, "tEnd": 1785395879000, "_addr": "79 Anson Road", "_type": "Exchange", "binIn": "5070", "jobId": 98, "price": 18, "waste": "General Waste", "_sales": "", "_surch": "", "binOut": "5132", "doType": "land", "photos": [{"id": "ms776qh3-BININ-98-1.jpg", "ts": 1785395879000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms776qh3-BININ-98-1.jpg", "kind": "in", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms776qh3-BININ-98-1.jpg"}, {"id": "ms776qqi-BINOUT-98-1.jpg", "ts": 1785395879000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms776qqi-BINOUT-98-1.jpg", "kind": "out", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms776qqi-BINOUT-98-1.jpg"}, {"id": "ms776qx7-DO-98-1.jpg", "ts": 1785396779000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms776qx7-DO-98-1.jpg", "kind": "do", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms776qx7-DO-98-1.jpg"}], "tBinIn": 1785395879000, "vessel": null, "weight": {"net": 1, "tare": 2, "gross": 3, "ticket": "LR47"}, "_charge": 18, "_client": "HCG", "_driver": "Yao Jun", "jobType": "Exchange", "remarks": "", "sigName": "", "tAccept": 1785396801240, "tBinOut": 1785395879000, "tServer": 1785396850311, "tWeight": 0, "timeEnd": "15:17", "tonnAdj": 0, "tonnage": 0, "clientId": "cmrkt9189v5w", "distance": 0, "driverId": 5, "invoiced": false, "disposeTo": "", "timeStart": "15:17", "vehicleNo": "XE7126P", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["General Waste"], "sigPosition": ""}, {"id": 55, "tDO": 1785457146000, "_pay": 23, "date": "2026-07-31", "doNo": 26064, "tEnd": 1785455922000, "_addr": "50 Playfair road", "_type": "Exchange", "binIn": "5056", "jobId": 110, "price": 23, "waste": "General Waste", "_sales": "", "_surch": "", "binOut": "L808", "doType": "land", "photos": [{"id": "ms86dtbl-BININ-110-1.jpg", "ts": 1785455926000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms86dtbl-BININ-110-1.jpg", "kind": "in", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms86dtbl-BININ-110-1.jpg"}, {"id": "ms86dtjw-BINOUT-110-1.jpg", "ts": 1785455922000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms86dtjw-BINOUT-110-1.jpg", "kind": "out", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms86dtjw-BINOUT-110-1.jpg"}], "tBinIn": 1785455926000, "vessel": null, "weight": {"net": 3710, "tare": 14100, "gross": 17810, "ticket": "LR48"}, "_charge": 23, "_client": "Top Star Builder Pte Ltd", "_driver": "Yao Jun", "jobType": "Exchange", "remarks": "", "sigName": "", "tAccept": 1785454499091, "tBinOut": 1785455922000, "tServer": 1785455967153, "tWeight": 0, "timeEnd": "07:58", "tonnAdj": 0, "tonnage": 0, "clientId": "cmrkt918fl15", "distance": 32.4, "driverId": 5, "invoiced": false, "disposeTo": "Lirich Resources Pte Ltd", "timeStart": "07:58", "vehicleNo": "XE7126P", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["General Waste"], "sigPosition": ""}, {"id": 56, "tDO": 0, "_pay": 18, "date": "2026-07-31", "doNo": 0, "tEnd": 1785456865000, "_addr": "5 Sungei Kadut Street 6", "_type": "Dump", "binIn": "", "jobId": 99, "price": 18, "waste": "Wood Waste", "_sales": "", "_surch": "", "binOut": "", "doType": "land", "photos": [{"id": "ms86y17q-BIN-99-1.jpg", "ts": 1785456865000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms86y17q-BIN-99-1.jpg", "kind": "bin", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms86y17q-BIN-99-1.jpg"}], "tBinIn": 0, "vessel": null, "weight": {"net": 0, "tare": 0, "gross": 0, "ticket": ""}, "_charge": 18, "_client": "Beejoo", "_driver": "Liu", "jobType": "Dump", "remarks": "", "sigName": "", "tAccept": 1785446196018, "tBinOut": 0, "tServer": 1785456787310, "tWeight": 0, "timeEnd": "08:14", "tonnAdj": 0, "tonnage": 0, "clientId": "cmrkt9187viy", "distance": 0, "driverId": 4, "invoiced": false, "disposeTo": "Bee Joo", "timeStart": "05:16", "vehicleNo": "", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": [], "sigPosition": ""}, {"id": 57, "tDO": 1785467366000, "_pay": 21, "date": "2026-07-31", "doNo": 26065, "tEnd": 1785466665000, "_addr": "31 Tuas West Drive, Lamppost 74F", "_type": "Load", "binIn": "L808", "jobId": 112, "price": 21, "waste": "General Waste", "_sales": "", "_surch": "", "binOut": "L808", "doType": "land", "photos": [{"id": "ms8d74vt-BININ-112-1.jpg", "ts": 1785466665000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms8d74vt-BININ-112-1.jpg", "kind": "in", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms8d74vt-BININ-112-1.jpg"}, {"id": "ms8d755c-BINOUT-112-1.jpg", "ts": 1785466665000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms8d755c-BINOUT-112-1.jpg", "kind": "out", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms8d755c-BINOUT-112-1.jpg"}, {"id": "ms8d759v-DO-112-1.jpg", "ts": 1785467366000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms8d759v-DO-112-1.jpg", "kind": "do", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms8d759v-DO-112-1.jpg"}, {"id": "ms8d75e1-SIG-112-1.jpg", "ts": 1785467410304, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms8d75e1-SIG-112-1.jpg", "kind": "signature", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms8d75e1-SIG-112-1.jpg"}], "tBinIn": 1785466665000, "vessel": null, "weight": {"net": 7710, "tare": 14050, "gross": 21760, "ticket": "LR50"}, "_charge": 21, "_client": "Hyundai Engineering & Construction Co., Ltd", "_driver": "Yao Jun", "jobType": "Load", "remarks": "", "sigName": "", "tAccept": 1785462401619, "tBinOut": 1785466665000, "tServer": 1785467412857, "tWeight": 0, "timeEnd": "10:57", "tonnAdj": 0, "tonnage": 0, "clientId": "cmrkt918azpz", "distance": 0, "driverId": 5, "invoiced": false, "disposeTo": "", "timeStart": "10:57", "vehicleNo": "XE7126P", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["General Waste"], "sigPosition": ""}, {"id": 58, "tDO": 1785468212000, "_pay": 13, "date": "2026-07-31", "doNo": 26300, "tEnd": 1785467147000, "_addr": "21 Ayer Merbau, Jurong Island", "_type": "Exchange", "binIn": "5213", "jobId": 100, "price": 13, "waste": "General Waste", "_sales": "", "_surch": "", "binOut": "L24", "doType": "land", "photos": [{"id": "ms8dp492-BINOUT-100-1.jpg", "ts": 1785467147000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms8dp492-BINOUT-100-1.jpg", "kind": "out", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms8dp492-BINOUT-100-1.jpg"}, {"id": "ms8dp4jq-DO-100-1.jpg", "ts": 1785468212000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms8dp4jq-DO-100-1.jpg", "kind": "do", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms8dp4jq-DO-100-1.jpg"}, {"id": "ms8dp4o9-SIG-100-1.jpg", "ts": 1785468250442, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms8dp4o9-SIG-100-1.jpg", "kind": "signature", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms8dp4o9-SIG-100-1.jpg"}], "tBinIn": 0, "vessel": null, "weight": null, "_charge": 13, "_client": "Poh Tiong Choon Logistics Ltd", "_driver": "Liu", "jobType": "Exchange", "remarks": "", "sigName": "", "tAccept": 1785464689987, "tBinOut": 1785467147000, "tServer": 1785468251846, "tWeight": 0, "timeEnd": "11:05", "tonnAdj": 0, "tonnage": 0, "clientId": "cmrkt918ag06", "distance": 9.7, "driverId": 4, "invoiced": false, "disposeTo": "Lirich Resources Pte Ltd", "timeStart": "", "vehicleNo": "XE8496P", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["General Waste"], "sigPosition": ""}, {"id": 59, "tDO": 1785472161000, "_pay": 0, "date": "2026-07-31", "doNo": 26066, "tEnd": 0, "_addr": "", "binIn": "3013", "jobId": 114, "price": 0, "waste": "Hardcore Waste", "_sales": "", "_surch": "", "binOut": "", "doType": "land", "photos": [{"id": "ms8g1hlh-DO-114-1.jpg", "ts": 1785472161000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms8g1hlh-DO-114-1.jpg", "kind": "do", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms8g1hlh-DO-114-1.jpg"}, {"id": "ms8g1hvv-SIG-114-1.jpg", "ts": 1785472187200, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms8g1hvv-SIG-114-1.jpg", "kind": "signature", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms8g1hvv-SIG-114-1.jpg"}], "tBinIn": 0, "vessel": null, "weight": {"net": 1, "tare": 2, "gross": 3, "ticket": "LR51"}, "_charge": 0, "_client": "Ecozeal", "_driver": "Yao Jun", "jobType": "", "remarks": "", "sigName": "", "tAccept": 1785472152116, "tBinOut": 0, "tServer": 1785472188245, "tWeight": 0, "timeEnd": "", "tonnAdj": 0, "tonnage": 0, "clientId": "cms6sx0w2c6g", "distance": 0, "driverId": 5, "invoiced": false, "disposeTo": "", "timeStart": "", "vehicleNo": "XE7126P", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": [], "sigPosition": ""}, {"id": 60, "tDO": 1785482494000, "_pay": 19.5, "date": "2026-07-31", "doNo": 0, "tEnd": 1785481019000, "_addr": "Gul", "_type": "Exchange", "binIn": "6006", "jobId": 111, "price": 19.5, "waste": "General Waste", "_sales": "", "_surch": "", "binOut": "6006", "doType": "land", "photos": [{"id": "ms8m6yfg-BININ-111-1.jpg", "ts": 1785481020000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms8m6yfg-BININ-111-1.jpg", "kind": "in", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms8m6yfg-BININ-111-1.jpg"}, {"id": "ms8m6yp2-BINOUT-111-1.jpg", "ts": 1785481019000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms8m6yp2-BINOUT-111-1.jpg", "kind": "out", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms8m6yp2-BINOUT-111-1.jpg"}, {"id": "ms8m6yuq-DO-111-1.jpg", "ts": 1785482494000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms8m6yuq-DO-111-1.jpg", "kind": "do", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms8m6yuq-DO-111-1.jpg"}], "tBinIn": 1785481020000, "vessel": null, "weight": {"net": 3550, "tare": 13950, "gross": 17500, "ticket": "LR52"}, "_charge": 19.5, "_client": "ST", "_driver": "Yao Jun", "jobType": "Exchange", "remarks": "", "sigName": "", "tAccept": 1785481002873, "tBinOut": 1785481019000, "tServer": 1785482521036, "tWeight": 0, "timeEnd": "14:56", "tonnAdj": 0, "tonnage": 0, "clientId": "cmrkt918dn4k", "distance": 0.4, "driverId": 5, "invoiced": false, "disposeTo": "Lirich Resources Pte Ltd", "timeStart": "14:57", "vehicleNo": "XE7126P", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["General Waste"], "sigPosition": ""}, {"id": 61, "tDO": 1785484736000, "_pay": 19.5, "date": "2026-07-31", "doNo": 43198, "tEnd": 1785484254000, "_addr": "Gul", "_type": "Exchange", "binIn": "COMPACTOR", "jobId": 115, "price": 19.5, "waste": "General Waste", "_sales": "", "_surch": "", "binOut": "COMPACTOR", "doType": "land", "photos": [{"id": "ms8owgjr-BININ-115-1.jpg", "ts": 1785484254000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms8owgjr-BININ-115-1.jpg", "kind": "in", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms8owgjr-BININ-115-1.jpg"}, {"id": "ms8owh4y-BINOUT-115-1.jpg", "ts": 1785484254000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms8owh4y-BINOUT-115-1.jpg", "kind": "out", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms8owh4y-BINOUT-115-1.jpg"}, {"id": "ms8owh95-DO-115-1.jpg", "ts": 1785484736000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms8owh95-DO-115-1.jpg", "kind": "do", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms8owh95-DO-115-1.jpg"}], "tBinIn": 1785484254000, "vessel": null, "weight": {"net": 3980, "tare": 17090, "gross": 21070, "ticket": "LR53"}, "_charge": 19.5, "_client": "ST", "_driver": "Yao Jun", "jobType": "Exchange", "remarks": "", "sigName": "", "tAccept": 1785487027018, "tBinOut": 1785484254000, "tServer": 1785487070151, "tWeight": 0, "timeEnd": "15:50", "tonnAdj": 0, "tonnage": 0, "clientId": "cmrkt918dn4k", "distance": 0, "driverId": 5, "invoiced": false, "disposeTo": "", "timeStart": "15:50", "vehicleNo": "XE7126P", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["General Waste"], "sigPosition": ""}, {"id": 62, "tDO": 1785486942000, "_pay": 13, "date": "2026-07-31", "doNo": 0, "tEnd": 1785486942000, "_addr": "NEA Tuas", "_type": "Exchange", "binIn": "", "jobId": 116, "price": 13, "waste": "General Waste", "_sales": "", "_surch": "", "binOut": "", "doType": "land", "photos": [{"id": "ms8ozoku-BININ-116-1.jpg", "ts": 1785486942000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms8ozoku-BININ-116-1.jpg", "kind": "in", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms8ozoku-BININ-116-1.jpg"}, {"id": "ms8ozop7-BINOUT-116-1.jpg", "ts": 1785486942000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms8ozop7-BINOUT-116-1.jpg", "kind": "out", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms8ozop7-BINOUT-116-1.jpg"}, {"id": "ms8ozotx-DO-116-1.jpg", "ts": 1785486942000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms8ozotx-DO-116-1.jpg", "kind": "do", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms8ozotx-DO-116-1.jpg"}], "tBinIn": 1785486942000, "vessel": null, "weight": {"net": 3980, "tare": 17090, "gross": 21070, "ticket": "LR54"}, "_charge": 13, "_client": "NEA", "_driver": "Yao Jun", "jobType": "Exchange", "remarks": "", "sigName": "", "tAccept": 1785487196382, "tBinOut": 1785486942000, "tServer": 1785487220526, "tWeight": 0, "timeEnd": "16:35", "tonnAdj": 0, "tonnage": 0, "clientId": "cmrkt918ate4", "distance": 0, "driverId": 5, "invoiced": false, "disposeTo": "", "timeStart": "16:35", "vehicleNo": "XE7126P", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["General Waste"], "sigPosition": ""}], "clients": [{"id": "c1", "name": "Eng Lee Logistics Pte Ltd", "type": "land", "sites": [{"addr": "9 Gul Circle", "label": "Gul Circle yard", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "15 Tuas Ave 8", "label": "Tuas yard"}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [{"name": "Jacky", "phone": "84118884"}, {"name": "Mei Ling", "phone": "91234567"}], "salesRep": "Patrick"}, {"id": "c2", "name": "Radha Exports Pte Ltd", "type": "land", "sites": [{"addr": "118 Pioneer Rd L1", "label": "Pioneer Rd"}, {"addr": "118 Pioneer Road L1", "label": "Yard 2", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "118 Pioneer Road L4", "label": "Yard 3", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "118 Pioneer Road L7", "label": "Yard 4", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "6 Fishery Port, L5M", "label": "Yard 5", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [{"name": "Radha", "phone": ""}, {"name": "Eugene / Poornima", "phone": "81614185 / 81572014"}, {"name": "", "phone": "82982405 / 9185 8431"}], "salesRep": "Marcus"}, {"id": "c3", "name": "Aspiration City", "type": "land", "sites": [{"addr": "Boon Lay Ave", "label": "Main"}], "contacts": [], "salesRep": "Patrick"}, {"id": "c4", "name": "SLG Construction", "type": "land", "sites": [{"addr": "Tuas South Ave 10", "label": "Main"}], "contacts": [], "salesRep": "Patrick"}, {"id": "c5", "name": "Tian Heng Eng", "type": "land", "sites": [{"addr": "Tractor Rd", "label": "Main"}], "contacts": [], "salesRep": "Marcus"}, {"id": "c6", "name": "Pacific International Lines", "type": "vessel", "sites": [{"addr": "PSA, BT Gate 2 Commercial Lane", "label": "PSA"}, {"addr": "PSA berths - vessel operations", "label": "Yard 2", "prices": {}}], "contacts": [{"name": "Ops Desk", "phone": ""}], "salesRep": "Marcus"}, {"id": "cmrkt918745o", "name": "123 Express", "type": "land", "sites": [{"addr": "60 Kaki Bukit Place, #06-14 Eunos Techpark", "label": "Yard 1", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}], "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}, "contacts": [], "salesRep": ""}, {"id": "cmrkt91876ld", "name": "Absolut Properties Pte Ltd", "type": "land", "sites": [{"addr": "163 Marine Parade Road, Marine Meadows Condo", "label": "Yard 1", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "173 Jalan Loyang Besar, Ocean Front Suites Condo", "label": "Yard 2", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}], "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}, "contacts": [], "salesRep": ""}, {"id": "cmrkt9187gpn", "name": "Acreation Group Pte Ltd", "type": "land", "sites": [{"addr": "19 Jalan Mesin", "label": "Yard 1", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "9 Raffles Boulevard", "label": "Yard 2", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "Engku Aman Road", "label": "Yard 3", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "Orchard Gateway, 277 Orchard Road", "label": "Yard 4", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}], "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}, "contacts": [], "salesRep": ""}, {"id": "cmrkt9187x1k", "name": "Advanced Substrate Technologies Pte Ltd", "type": "land", "sites": [{"addr": "47A Jalan Buroh", "label": "Yard 1", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt9187dcx", "name": "AJK", "type": "land", "sites": [{"addr": "24 Tuas Ave 8", "label": "Yard 1", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt9187ip5", "name": "Allalloy Dynaweld Pte Ltd", "type": "land", "sites": [{"addr": "10 Tuas Link 1", "label": "Yard 1", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt91872y0", "name": "Allied Container Services Pte Ltd", "type": "land", "sites": [{"addr": "10 Tuas Ave 6", "label": "Yard 1", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "15 Pioneer Crescent", "label": "Yard 2", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "25 Penjuru Lane Yard 3", "label": "Yard 3", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt9187co1", "name": "Apex Sealing Technologies Pte Ltd", "type": "land", "sites": [{"addr": "19 Tuas South Street 5", "label": "Yard 1", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "Tuas Basin Lane", "label": "Yard 2", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt91871qf", "name": "Archibiz", "type": "land", "sites": [{"addr": "Blk A 30 Kranji Loop, #06-05 Timmac @ Kranji", "label": "Yard 1", "prices": {"Load": 26, "Collect": 18, "Delivery": 8, "Exchange": 18}}], "prices": {"Collect": 18, "Delivery": 8, "Exchange": 18}, "contacts": [], "salesRep": ""}, {"id": "cmrkt9187obq", "name": "Artdecor Design Studio Pte Ltd", "type": "land", "sites": [{"addr": "2 Defu South Street 1, #05-03, JTC Industrial City", "label": "Yard 1", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}], "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}, "contacts": [], "salesRep": ""}, {"id": "cmrkt9187ws7", "name": "ASL Proworld Solution Pte Ltd", "type": "land", "sites": [{"addr": "8 Pandan Crescent", "label": "Yard 1", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt9187n05", "name": "Astore Pte Ltd", "type": "land", "sites": [{"addr": "43 Keppel Road", "label": "Yard 1", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}], "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}, "contacts": [], "salesRep": ""}, {"id": "cmrkt9187zx3", "name": "Aver Asia (S) Pte Ltd", "type": "land", "sites": [{"addr": "14 Benoi Place", "label": "Yard 1", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt91878od", "name": "B&C Waste", "type": "land", "sites": [{"addr": "16 Gul Crescent", "label": "Yard 1", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "513 Kampong Bahru Road Keppel Distripark", "label": "Yard 2", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "Upper Changi Road, Summer Garden Condo", "label": "Yard 3", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "2 Mandai Link", "label": "Yard 4", "prices": {"Load": 26, "Collect": 18, "Delivery": 8, "Exchange": 18}}, {"addr": "Peck Seah Street", "label": "Yard 5", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "7 Changi South Street 2", "label": "Yard 6", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "26 Loyang Drive", "label": "Yard 7", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}], "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}, "contacts": [], "salesRep": ""}, {"id": "cmrkt9187pck", "name": "Babu", "type": "land", "sites": [{"addr": "80 Mandai Lake Road", "label": "Yard 1", "prices": {"Load": 26, "Collect": 18, "Delivery": 8, "Exchange": 18}}, {"addr": "Blk 5 Haig Road #07-463", "label": "Yard 2", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "900 Bedok North Road", "label": "Yard 3", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "2 Stadium Walk", "label": "Yard 4", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}], "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}, "contacts": [], "salesRep": ""}, {"id": "cmrkt9187viy", "name": "Beejoo", "type": "land", "sites": [{"addr": "5 Sungei Kadut Street 6", "label": "Yard 1", "prices": {"Dump": 18}}], "prices": {"Dump": 18}, "contacts": [], "salesRep": ""}, {"id": "cmrkt9187nen", "name": "BNDC (Fairprice)", "type": "land", "sites": [{"addr": "1 Buroh Lane L4", "label": "Yard 1", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "28 Tuas Ave 13", "label": "Yard 2", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "5 Joo Koon Circle", "label": "Yard 3", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "7 Sunview Road", "label": "Yard 4", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt9188ra9", "name": "C & P Holdings Pte Ltd", "type": "land", "sites": [{"addr": "46 Penjuru Lane", "label": "Yard 1", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt91889mm", "name": "Calvary Carpentry Pte Ltd", "type": "land", "sites": [{"addr": "54 Senoko Road", "label": "Yard 1", "prices": {"Load": 26, "Collect": 18, "Delivery": 8, "Exchange": 18}}], "prices": {"Collect": 18, "Delivery": 8, "Exchange": 18}, "contacts": [], "salesRep": ""}, {"id": "cmrkt9188tnl", "name": "Cargo International", "type": "land", "sites": [{"addr": "20 Gul Way, #05-04", "label": "Yard 1", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt91889d7", "name": "Caterpillar", "type": "land", "sites": [{"addr": "14 Tractor Road", "label": "Yard 1", "prices": {"Load": 26, "Collect": 18, "Delivery": 8, "Exchange": 18}}, {"addr": "7 Tractor Road", "label": "Yard 2", "prices": {"Load": 26, "Collect": 18, "Delivery": 8, "Exchange": 18}}], "prices": {"Collect": 18, "Delivery": 8, "Exchange": 18}, "contacts": [], "salesRep": ""}, {"id": "cmrkt9188fou", "name": "CBM Pte Ltd", "type": "land", "sites": [{"addr": "501 Old Choa Chu Kang Road, Home Team Academy", "label": "Yard 1", "prices": {"Load": 26, "Collect": 18, "Delivery": 8, "Exchange": 18}}], "prices": {"Collect": 18, "Delivery": 8, "Exchange": 18}, "contacts": [{"name": "Rizab", "phone": "8019 5329"}], "salesRep": ""}, {"id": "cmrkt91889z2", "name": "Chateraise", "type": "land", "sites": [{"addr": "8 Jalan Besut L3", "label": "Yard 1", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt9188wm8", "name": "Chiong Construction", "type": "land", "sites": [{"addr": "10 Serangoon Ave 4", "label": "Yard 1", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "13 Serangoon Ave 3", "label": "Yard 2", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "60 Blk A Jurong West Street 42", "label": "Yard 3", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt9188jxn", "name": "Chuan Seng Leong", "type": "land", "sites": [{"addr": "21 Benoi Sector #03-03", "label": "Yard 1", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}], "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}, "contacts": [], "salesRep": ""}, {"id": "cmrkt91886cl", "name": "Cleanis-Tee", "type": "land", "sites": [{"addr": "8 Jalan Papan", "label": "Yard 1", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt9188smd", "name": "CNCCS Engineering and Construction Pte Ltd", "type": "land", "sites": [{"addr": "15 Tembusu Crescent, #08-01, COGENT.", "label": "Yard 1", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}], "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}, "contacts": [], "salesRep": ""}, {"id": "cmrkt9188btv", "name": "CrestSA Marine & Offshore Pte Ltd", "type": "land", "sites": [{"addr": "15 Pandan Road", "label": "Yard 1", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt9188ahz", "name": "DSV", "type": "land", "sites": [{"addr": "24 Penjuru Road, #09-05/06 (Loading Bay 2)", "label": "Yard 1", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt91880wf", "name": "Dyna Cool", "type": "land", "sites": [{"addr": "2 Bukit Batok Street 24, #03-19 Skytech", "label": "Yard 1", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt91888e3", "name": "Eng Leng Contractors Pte Ltd", "type": "land", "sites": [{"addr": "1 CleanTech Loop", "label": "Yard 1", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "1 Gul Circle, JTC Logistics Hub", "label": "Yard 2", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "16 Tuas Ave 1, JTC Space @ Tuas", "label": "Yard 3", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "2 Tukang Innovation Grove", "label": "Yard 4", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "28A Penjuru Close Bin Centre", "label": "Yard 5", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "8 Buroh Street", "label": "Yard 6", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "8 Jurong Town Hall Rd, JTC Summit Building", "label": "Yard 7", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "Jalan Papan LP 15", "label": "Yard 8", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "Pandan Loop, Blk K, (Phase 1), Bin Centre", "label": "Yard 9", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "Pandan Loop, Blk X, (Phase 3), Bin Centre", "label": "Yard 10", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "15 Jalan Terusan", "label": "Yard 11", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [{"name": "Ezwan", "phone": "98644193"}], "salesRep": ""}, {"id": "cmrkt918885s", "name": "Engie Services Singapore Pte Ltd", "type": "land", "sites": [{"addr": "1 Canning Rise Singapore 179868", "label": "Yard 1", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "1 Empress Place", "label": "Yard 2", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "1 Jurong East st 21, Ng Teng Fong Hospital", "label": "Yard 3", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "100 Victoria Street, Basement 2, Loading Bay", "label": "Yard 4", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "17 Woodlands Drive 17, Woodlands Health Campus", "label": "Yard 5", "prices": {"Load": 26, "Collect": 18, "Delivery": 8, "Exchange": 18}}, {"addr": "2 Simei Street 3, Changi General Hospital", "label": "Yard 6", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "20 Airport Boulevard Changi Airport", "label": "Yard 7", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "28 Irrawaddy Road, New Phoenix Park. (Ministry of Home Affairs)", "label": "Yard 8", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "32 Jurong Port Road, Heritage Center", "label": "Yard 9", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "4A Tuas Bay Street", "label": "Yard 10", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "65 Airport Boulevard, #B2-63, Changi Airport T3", "label": "Yard 11", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "9 Kallang Place", "label": "Yard 12", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "93 Stamford Road, National Museum of Singapore", "label": "Yard 13", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "Changi Airport T2 Basement", "label": "Yard 14", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "2 Tuas Bay Street", "label": "Yard 15", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "1 Cove Grove", "label": "Yard 16", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "1 Media Link", "label": "Yard 17", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "30 Changi North Cresent", "label": "Yard 18", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}], "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}, "contacts": [{"name": "Sunder", "phone": "8267 7685"}], "salesRep": ""}, {"id": "cmrkt9189ewq", "name": "Epont Building Services Pte Ltd", "type": "land", "sites": [{"addr": "1 Tuas View Place, Westlink One, #02-01", "label": "Yard 1", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt91893rb", "name": "Euro Pac Logistics Pte Ltd", "type": "land", "sites": [{"addr": "42 Tanjong Penjuru Road", "label": "Yard 1", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "52 Tanjong Penjuru #04-92", "label": "Yard 2", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt9189j9t", "name": "EverTeam Pte Ltd", "type": "land", "sites": [{"addr": "60 Benoi Road", "label": "Yard 1", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt9189chy", "name": "Faxolif Industries Pte Ltd", "type": "land", "sites": [{"addr": "75 Tech Park Crescent", "label": "Yard 1", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt91891r8", "name": "Geoinnovations Pte Ltd", "type": "land", "sites": [{"addr": "5 Kwong Ming Road", "label": "Yard 1", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}], "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}, "contacts": [], "salesRep": ""}, {"id": "cmrkt9189hjd", "name": "GS Engineering and Construction Corporation", "type": "land", "sites": [{"addr": "Nicoll Highway LP 120F", "label": "Yard 1", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "Nicoll Highway LP 131F", "label": "Yard 2", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "Nicoll Highway, LP 132F", "label": "Yard 3", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "Ophir Road LP 14/1F", "label": "Yard 4", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "Ophir Road, LP 30F", "label": "Yard 5", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "Republic Boulevard LP 4F", "label": "Yard 6", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "Victoria Street, LP 64F", "label": "Yard 7", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}], "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}, "contacts": [], "salesRep": ""}, {"id": "cmrkt9189rdg", "name": "GWC", "type": "land", "sites": [{"addr": "449 Clementi Ave 3, #01-259", "label": "Yard 1", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt9189clz", "name": "Gymsportz", "type": "land", "sites": [{"addr": "7, Block B Mandai Link, #05-27 Mandai Connection", "label": "Yard 1", "prices": {"Load": 26, "Collect": 18, "Delivery": 8, "Exchange": 18}}], "prices": {"Collect": 18, "Delivery": 8, "Exchange": 18}, "contacts": [], "salesRep": ""}, {"id": "cmrkt9189uq4", "name": "H1 Projects Pte Ltd", "type": "land", "sites": [{"addr": "107 Jalan Pari Burong", "label": "Yard 1", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}], "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}, "contacts": [], "salesRep": ""}, {"id": "cmrkt9189g55", "name": "Haid Biotechnology Industry (Singapore) Pte Ltd", "type": "land", "sites": [{"addr": "46 Gul Drive", "label": "Yard 1", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [{"name": "Yvonne", "phone": "89101994"}], "salesRep": ""}, {"id": "cmrkt9189v5w", "name": "HCG", "type": "land", "sites": [{"addr": "8 Tuas View Circuit", "label": "Yard 1", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "79 Anson Road", "label": "Yard 2", "prices": {"Load": 26, "Collect": 18, "Delivery": 8, "Exchange": 18}}], "prices": {"Collect": 18, "Delivery": 8, "Exchange": 18}, "contacts": [], "salesRep": ""}, {"id": "cmrkt9189qwx", "name": "He Ping Development Pte Ltd", "type": "land", "sites": [{"addr": "32 Tras Street", "label": "Yard 1", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "38 Beach Road, South Beach Tower", "label": "Yard 2", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "51 Tanjong Pagar Road", "label": "Yard 3", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}], "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}, "contacts": [], "salesRep": ""}, {"id": "cmrkt9189tvd", "name": "Hong Hang Hardware", "type": "land", "sites": [{"addr": "35 Pioneer Road", "label": "Yard 1", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt9189mv1", "name": "Hotel Royal Singapore", "type": "land", "sites": [{"addr": "36 Newton Road", "label": "Yard 1", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}], "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}, "contacts": [], "salesRep": ""}, {"id": "cmrkt91895ny", "name": "Huationg Contractor", "type": "land", "sites": [{"addr": "Tanah Merah Coast Road LP 509", "label": "Yard 1", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}], "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}, "contacts": [], "salesRep": ""}, {"id": "cmrkt9189zdz", "name": "Huntsman (S) Pte Ltd", "type": "land", "sites": [{"addr": "10 Seraya Ave", "label": "Yard 1", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}], "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}, "contacts": [], "salesRep": ""}, {"id": "cmrkt9189166", "name": "Hydroproof", "type": "land", "sites": [{"addr": "The Aries, 51 Science Park", "label": "Yard 1", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918azpz", "name": "Hyundai Engineering & Construction Co., Ltd", "type": "land", "sites": [{"addr": "100 Beach Road", "label": "Yard 1", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "31 Tuas West Drive, Lamppost 74F", "label": "Yard 2", "prices": {"Load": 21, "Sell": 8, "Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}, "contacts": [{"name": "Liton", "phone": "88960490"}], "salesRep": ""}, {"id": "cmrkt918as3h", "name": "INVX Asia Pacific Pte Ltd", "type": "land", "sites": [{"addr": "80 Tuas West Drive", "label": "Yard 1", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918ap5c", "name": "Iwatech", "type": "land", "sites": [{"addr": "2 Kian Teck Drive", "label": "Yard 1", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918avdw", "name": "Lau Choy Seng Pte Ltd", "type": "land", "sites": [{"addr": "30 Tuas West Avenue", "label": "Yard 1", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918a2es", "name": "LCH Logistics Pte Ltd", "type": "land", "sites": [{"addr": "3 Pioneer Sector 3", "label": "Yard 1", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918ao9s", "name": "Leng Aik Engineering", "type": "land", "sites": [{"addr": "17 Soon Lee Road", "label": "Yard 1", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918auof", "name": "LexBuild International Pte Ltd", "type": "land", "sites": [{"addr": "11 Tuas Bay Close, #04-01/02", "label": "Yard 1", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918ar8i", "name": "Lirich", "type": "land", "sites": [{"addr": "23 Gul Drive", "label": "Main", "prices": {"Sell": 13, "Delivery": 8}}], "prices": {"Dump": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918abew", "name": "Lim Siang Huat Pte Ltd", "type": "land", "sites": [{"addr": "6 Fishery Port Road L3", "label": "Yard 1", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918a2xv", "name": "Matrix Cooling (Singapore) Pte Ltd", "type": "land", "sites": [{"addr": "10 Buroh Street, #07-01, Westconnect Building", "label": "Yard 1", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918aw4z", "name": "Mecom GreenBuild (Singapore) Pte Ltd", "type": "land", "sites": [{"addr": "23 Jurong Port Road", "label": "Yard 1", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918ate4", "name": "NEA", "type": "land", "sites": [{"addr": "NEA Tuas", "label": "Yard 1", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918askd", "name": "PaxOcean Singapore Pte Ltd", "type": "land", "sites": [{"addr": "5 Jalan Samulun", "label": "Yard 1", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [{"name": "Muthu", "phone": "8455 3465"}], "salesRep": ""}, {"id": "cmrkt918ag06", "name": "Poh Tiong Choon Logistics Ltd", "type": "land", "sites": [{"addr": "21 Ayer Merbau, Jurong Island", "label": "Yard 1", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "48 Pandan Road L1", "label": "Yard 2", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "48 Pandan Road L3", "label": "Yard 3", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "48 Pandan Road L6", "label": "Yard 4", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918auyz", "name": "PSA Port Ecosystem (Sea) Pte Ltd", "type": "land", "sites": [{"addr": "24 Penjuru Road. #05-06", "label": "Yard 1", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918a8k1", "name": "Qualicoat Pte Ltd", "type": "land", "sites": [{"addr": "5 Gul Drive", "label": "Yard 1", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918aitb", "name": "REMEX Minerals Singapore Pte Ltd", "type": "land", "sites": [{"addr": "98 Tuas South Ave 3 (Inside NEA building)", "label": "Yard 1", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918apvn", "name": "RJ Hydralics", "type": "land", "sites": [{"addr": "83 Tagore Lane", "label": "Yard 1", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}], "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918auhe", "name": "Savills Property Management Pte Ltd (Blue Hub)", "type": "land", "sites": [{"addr": "10 Sunview Road L109", "label": "Yard 1", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "10 Sunview Road L309", "label": "Yard 2", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "10 Sunview Road L407", "label": "Yard 3", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "10 Sunview Road L609", "label": "Yard 4", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918aco2", "name": "Savills Property Management Pte Ltd (Green Hub)", "type": "land", "sites": [{"addr": "11 Pioneer Turn L2", "label": "Yard 1", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "11 Pioneer Turn L401", "label": "Yard 2", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "11 Pioneer Turn L407", "label": "Yard 3", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "11 Pioneer Turn L601", "label": "Yard 4", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "11 Pioneer Turn L8", "label": "Yard 5", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918du9v", "name": "Seatrium Pte Ltd", "type": "land", "sites": [{"addr": "60 Admiralty Road West", "label": "Yard 1", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}], "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918dq77", "name": "Shin Ya O Ya Pte Ltd", "type": "land", "sites": [{"addr": "6 Chin Bee Ave L5", "label": "Yard 1", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "6 Chin Bee Ave L9", "label": "Yard 2", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [{"name": "", "phone": "8919 2975"}], "salesRep": ""}, {"id": "cmrkt918dmr4", "name": "Siew Kong Glass Makers Pte Ltd", "type": "land", "sites": [{"addr": "43 Joo Koon Circle", "label": "Yard 1", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918d2ww", "name": "Sin Hong Hardware Pte Ltd", "type": "land", "sites": [{"addr": "3 Kian Teck Crescent", "label": "Yard 1", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918devh", "name": "Sin Hong Poh Metal Trading", "type": "land", "sites": [{"addr": "59 Tampines Industrial Ave", "label": "Yard 1", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}], "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918dvh6", "name": "Sindac Cleaning Services Pte Ltd", "type": "land", "sites": [{"addr": "1H Pine Grove, Pine Grove Condo", "label": "Yard 1", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "20 Woodlands Crescent, Northoaks Condo", "label": "Yard 2", "prices": {"Load": 26, "Collect": 18, "Delivery": 8, "Exchange": 18}}], "prices": {"Collect": 18, "Delivery": 8, "Exchange": 18}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918diax", "name": "SLS", "type": "land", "sites": [{"addr": "No. 9 Tuas South Avenue 19, #01-99", "label": "Yard 1", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "VSMC site office Gate 3", "label": "Yard 2", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "Others", "label": "Yard 3", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918dpo7", "name": "Snip Avenue Holdings", "type": "land", "sites": [{"addr": "9 Changi South Street 3, loading bay", "label": "Yard 1", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}], "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918dhx4", "name": "Springlife Maintenance Service Pte Ltd", "type": "land", "sites": [{"addr": "21 Ang Mo Kio Ave 9, Nuovo Condo", "label": "Yard 1", "prices": {"Load": 26, "Collect": 18, "Delivery": 8, "Exchange": 18}}, {"addr": "464 Corporation Road, Parc Vista Condo", "label": "Yard 2", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "88 Flora Road, Edelweiss Park Condo", "label": "Yard 3", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}], "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918dn4k", "name": "ST", "type": "land", "sites": [{"addr": "6 Tuas South Street 15", "label": "Yard 1", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "Benoi", "label": "Yard 2", "prices": {"Collect": 19.5, "Delivery": 8, "Exchange": 19.5}}, {"addr": "Gul", "label": "Yard 3", "prices": {"Collect": 19.5, "Delivery": 8, "Exchange": 19.5}}, {"addr": "61a Tuas Nexus Drive", "label": "Yard 4", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918e1wj", "name": "Stamford Tyres", "type": "land", "sites": [{"addr": "19 Lok Yang Way", "label": "Yard 1", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}], "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918el54", "name": "STSM", "type": "land", "sites": [{"addr": "15 Pasir Ris Street 21", "label": "Yard 1", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "47 Hougang Avenue 1", "label": "Yard 2", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "Blk 15 Toa Payoh Lorong 7", "label": "Yard 3", "prices": {"Load": 26, "Collect": 18, "Delivery": 8, "Exchange": 18}}, {"addr": "Blk 61 Jurong West Street 65, Jurong West Secondary School (JWSS)", "label": "Yard 4", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "Blk 64 Lorong 5 Toa Payoh - Lot no. 24", "label": "Yard 5", "prices": {"Load": 26, "Collect": 18, "Delivery": 8, "Exchange": 18}}, {"addr": "Blk 698 West Coast Road, Commonwealth Secondary School (CWSS)", "label": "Yard 6", "prices": {"Load": 26, "Collect": 18, "Delivery": 8, "Exchange": 18}}], "prices": {"Collect": 18, "Delivery": 8, "Exchange": 18}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918ehaz", "name": "Sumber Indah Pte Ltd", "type": "land", "sites": [{"addr": "1 Tuas View Close", "label": "Yard 1", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918em7e", "name": "Sun City Maintenance Pte Ltd", "type": "land", "sites": [{"addr": "300 Mandai Road, Mandai Crematorium and Columbarium", "label": "Yard 1", "prices": {"Load": 26, "Collect": 18, "Delivery": 8, "Exchange": 18}}, {"addr": "55 Changi South Ave 1", "label": "Yard 2", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "SUTD Building 2, 8 Somapah Road, loading bay", "label": "Yard 3", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "SUTD Building 3, 8 somapah Road , with access via the Changi Street carpark entrance", "label": "Yard 4", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "Yishun Columbarium, 569 Yishun Ring Road", "label": "Yard 5", "prices": {"Load": 26, "Collect": 18, "Delivery": 8, "Exchange": 18}}], "prices": {"Collect": 18, "Delivery": 8, "Exchange": 18}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918eg0z", "name": "Sys-Mac Automation Engineering Pte Ltd", "type": "land", "sites": [{"addr": "2 Woodlands Sector 1, #05-18", "label": "Yard 1", "prices": {"Load": 26, "Collect": 18, "Delivery": 8, "Exchange": 18}}], "prices": {"Collect": 18, "Delivery": 8, "Exchange": 18}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918efxl", "name": "System Foundation Pte Ltd", "type": "land", "sites": [{"addr": "21A Tuas South Place", "label": "Yard 1", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "45 Tuas View Place", "label": "Yard 2", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918ejrl", "name": "T3 Reources Pte Ltd", "type": "land", "sites": [{"addr": "16 Gul Street 3", "label": "Yard 1", "prices": {"Sell": 13}}], "prices": {"Sell": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918enlk", "name": "Tai Lee Tong", "type": "land", "sites": [{"addr": "No 11, Lorong 21A Geylang", "label": "Yard 1", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}], "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918e77h", "name": "Technigroup Far East Pte Ltd", "type": "land", "sites": [{"addr": "Outram Road", "label": "Yard 1", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}], "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918evff", "name": "Technicair Singapore Services Pte Ltd", "type": "land", "sites": [{"addr": "16 Jalan Tan Tock Seng", "label": "Yard 1", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}], "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918e0xf", "name": "Teck Sang Pte Ltd", "type": "land", "sites": [{"addr": "30A Quality Road", "label": "Yard 1", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918eczv", "name": "Toh Ban Seng", "type": "land", "sites": [{"addr": "Seletar Westlink LP 103", "label": "Yard 1", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}], "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918een0", "name": "Tong Carriage (S) Pte Ltd", "type": "land", "sites": [{"addr": "30 Toh Guan Road", "label": "Yard 1", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918ebot", "name": "Tong Hock Pte Ltd", "type": "land", "sites": [{"addr": "10 Pandan Crescent", "label": "Yard 1", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "1206A East Coast Park", "label": "Yard 2", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "14 Tractor Road", "label": "Yard 3", "prices": {"Load": 26, "Collect": 18, "Delivery": 8, "Exchange": 18}}, {"addr": "19 Tuas Street", "label": "Yard 4", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "2 Peach Garden, Peach Garden condo", "label": "Yard 5", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "2 Pioneer Sector 1", "label": "Yard 6", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "58 Woodlands Drive 16, La Casa Condo", "label": "Yard 7", "prices": {"Load": 26, "Collect": 18, "Delivery": 8, "Exchange": 18}}, {"addr": "7 Tractor Road", "label": "Yard 8", "prices": {"Load": 26, "Collect": 18, "Delivery": 8, "Exchange": 18}}, {"addr": "1 Woodlands Terrace", "label": "Yard 9", "prices": {"Load": 26, "Collect": 18, "Delivery": 8, "Exchange": 18}}], "prices": {"Collect": 18, "Delivery": 8, "Exchange": 18}, "contacts": [{"name": "", "phone": "88206384"}], "salesRep": ""}, {"id": "cmrkt918fl15", "name": "Top Star Builder Pte Ltd", "type": "land", "sites": [{"addr": "50 Playfair road", "label": "Yard 1", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}], "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918fjc5", "name": "TSTL", "type": "land", "sites": [{"addr": "19 Tuas Street", "label": "Yard 1", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918fzog", "name": "Tracebuild", "type": "land", "sites": [{"addr": "1 Woodlands Street 31, Fu Chun Community Club", "label": "Yard 1", "prices": {"Load": 26, "Collect": 18, "Delivery": 8, "Exchange": 18}}], "prices": {"Collect": 18, "Delivery": 8, "Exchange": 18}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918f6wq", "name": "Urban Group Pte Ltd", "type": "land", "sites": [{"addr": "200 Netheravon Road", "label": "Yard 1", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}], "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918frwu", "name": "Wah & Hua Pte Ltd", "type": "land", "sites": [{"addr": "17 Kallang Junction, #01-01, Singapore 339274", "label": "Yard 1", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "19 Loyang Way", "label": "Yard 2", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "22 Woodlands Link", "label": "Yard 3", "prices": {"Load": 26, "Collect": 18, "Delivery": 8, "Exchange": 18}}, {"addr": "221 Kallang Bahru Lion Building", "label": "Yard 4", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "30 Kerong Lane", "label": "Yard 5", "prices": {"Load": 26, "Collect": 18, "Delivery": 8, "Exchange": 18}}, {"addr": "76 Sungei Tengah Road", "label": "Yard 6", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "980 Upper Changi Road North Singapore 507708(Prison HQ)", "label": "Yard 7", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}], "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918fkeq", "name": "WeBuild", "type": "land", "sites": [{"addr": "120 Hillview Ave", "label": "Yard 1", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}], "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918fsbo", "name": "WIKA Instrumentation Pte Ltd", "type": "land", "sites": [{"addr": "13 Kian Teck Crescent", "label": "Yard 1", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918f38h", "name": "Wilkie Development Pte Ltd", "type": "land", "sites": [{"addr": "12 New Industrial Road", "label": "Yard 1", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918fz34", "name": "World of Wood Pte Ltd", "type": "land", "sites": [{"addr": "35 Tannery Road, #01-07, Ruby Industrial Complex", "label": "Yard 1", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}], "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918fh09", "name": "W'Ray Construction Pte Ltd", "type": "land", "sites": [{"addr": "22 Scotts Road, Goodwood Park Hotel", "label": "Yard 1", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "25 Tuas Ave 4", "label": "Yard 2", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "1 Cove Grove", "label": "Yard 3"}, {"addr": "1 Media Link", "label": "Yard 4"}, {"addr": "30 Changi North Cresent", "label": "Yard 5"}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrmwaycfytt", "name": "Glory SIP Pte Ltd", "type": "land", "sites": [{"addr": "50 Tuas Avenue 11, 02-05", "label": "Yard 1", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cms6sx0w2c6g", "name": "Ecozeal", "type": "land", "sites": [], "prices": {}, "contacts": [], "salesRep": ""}, {"id": "cms775mx619a", "name": "ST Engineering", "type": "land", "sites": [{"addr": "6 Tuas South Street 15", "label": "Yard 1", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "Benoi", "label": "Yard 2", "prices": {"Load": 27.5, "Collect": 19.5, "Delivery": 8, "Exchange": 19.5}}, {"addr": "Gul", "label": "Yard 3", "prices": {"Load": 27.5, "Collect": 19.5, "Delivery": 8, "Exchange": 19.5}}, {"addr": "61a Tuas Nexus Drive", "label": "Yard 4", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {}, "contacts": [], "salesRep": ""}, {"id": "cms8d1q5thfo", "name": "ST Engineering Marine Ltd.", "type": "land", "sites": [{"addr": "ST Engineering Marine - Benoi Yard", "label": "Yard 1", "prices": {}}, {"addr": "ST Engineering Marine - Gul Yard", "label": "Yard 2", "prices": {}}, {"addr": "CDPL Tuas", "label": "Yard 3", "prices": {}}, {"addr": "61A Tuas Nexus Drive (IWMF Package 1)", "label": "Yard 4", "prices": {}}], "prices": {}, "contacts": [], "salesRep": ""}]}	237	2026-07-31 08:40:36.336+00
\.


--
-- Data for Name: approved_domains; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.approved_domains (domain, client_id, account_limit, accounts_used, added_by, added_at) FROM stdin;
\.


--
-- Data for Name: audit_log; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.audit_log (id, at, actor, action, entity, entity_id, before, after) FROM stdin;
2	2026-07-29 07:49:32.986085+00	admin	customers.upsert	customers	EXP	{"name": "123 Express", "active": true, "client_id": "EXP", "sales_rep": null, "created_at": "2026-07-24T15:15:51.944859+00:00", "contact_name": null, "contact_email": null, "contact_phone": null, "payment_terms": null, "xero_contact_id": null}	{"name": "123 Express", "client_id": "EXP"}
3	2026-07-29 07:49:32.992718+00	admin	sites.upsert	sites	EXP_001	{"active": true, "address": "60 Kaki Bukit Place, #06-14 Eunos Techpark", "site_id": "EXP_001", "client_id": "EXP", "site_name": "123 Express", "created_at": "2026-07-24T15:15:51.944859+00:00", "contact_name": null, "contact_email": null, "contact_phone": null}	{"active": true, "address": "60 Kaki Bukit Place, #06-14 Eunos Techpark", "site_id": "EXP_001", "client_id": "EXP", "site_name": "123 Express", "contact_name": null, "contact_email": null, "contact_phone": null}
4	2026-07-29 07:57:07.313471+00	legacy-key	rate_card.replace	rate_card	EXP_001	[{"price": 23, "job_type": "Collect", "valid_from": "2026-01-01"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-01-01"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-01-01"}, {"price": 1.01, "job_type": "Sell", "valid_from": "2026-01-01"}]	[{"price": 23, "job_type": "Exchange"}, {"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 1.01, "job_type": "Sell"}]
5	2026-07-29 08:03:20.497163+00	admin	customers.upsert	customers	EXP	{"name": "123 Express", "active": true, "client_id": "EXP", "sales_rep": null, "created_at": "2026-07-24T15:15:51.944859+00:00", "contact_name": null, "contact_email": null, "contact_phone": null, "payment_terms": null, "xero_contact_id": null}	{"name": "123 Express", "client_id": "EXP"}
6	2026-07-29 08:03:20.562252+00	admin	rate_card.replace	rate_card	EXP_001	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-29"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-29"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-29"}, {"price": 1.01, "job_type": "Sell", "valid_from": "2026-07-29"}]	[{"price": 23, "job_type": "Exchange"}, {"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}]
7	2026-07-29 08:03:20.585047+00	admin	sites.upsert	sites	EXP_001	{"active": true, "address": "60 Kaki Bukit Place, #06-14 Eunos Techpark", "site_id": "EXP_001", "client_id": "EXP", "site_name": "123 Express", "created_at": "2026-07-24T15:15:51.944859+00:00", "contact_name": null, "contact_email": null, "contact_phone": null}	{"active": true, "address": "60 Kaki Bukit Place, #06-14 Eunos Techpark", "site_id": "EXP_001", "client_id": "EXP", "site_name": "123 Express", "contact_name": null, "contact_email": null, "contact_phone": null}
8	2026-07-29 09:21:18.195636+00	admin	sites.upsert	sites	LIR_001	{"active": true, "address": "Carton", "site_id": "LIR_001", "client_id": "LIR", "site_name": "Lirich", "created_at": "2026-07-24T15:15:51.944859+00:00", "contact_name": null, "contact_email": null, "contact_phone": null}	{"active": true, "address": "23 Gul Drive", "site_id": "LIR_001", "client_id": "LIR", "site_name": "Lirich", "contact_name": null, "contact_email": null, "contact_phone": null}
9	2026-07-29 09:21:18.370036+00	admin	sites.upsert	sites	LIR_002	{"active": true, "address": "Metal", "site_id": "LIR_002", "client_id": "LIR", "site_name": "Lirich", "created_at": "2026-07-24T15:15:51.944859+00:00", "contact_name": null, "contact_email": null, "contact_phone": null}	{"active": false, "address": "Metal", "site_id": "LIR_002", "client_id": "LIR", "site_name": "Lirich", "contact_name": null, "contact_email": null, "contact_phone": null}
10	2026-07-29 09:21:18.465268+00	admin	sites.upsert	sites	LIR_003	{"active": true, "address": "Plastics", "site_id": "LIR_003", "client_id": "LIR", "site_name": "Lirich", "created_at": "2026-07-24T15:15:51.944859+00:00", "contact_name": null, "contact_email": null, "contact_phone": null}	{"active": false, "address": "Plastics", "site_id": "LIR_003", "client_id": "LIR", "site_name": "Lirich", "contact_name": null, "contact_email": null, "contact_phone": null}
11	2026-07-29 09:21:18.546652+00	admin	sites.upsert	sites	LIR_004	{"active": true, "address": "Beejoo", "site_id": "LIR_004", "client_id": "LIR", "site_name": "Lirich", "created_at": "2026-07-24T15:15:51.944859+00:00", "contact_name": null, "contact_email": null, "contact_phone": null}	{"active": false, "address": "Beejoo", "site_id": "LIR_004", "client_id": "LIR", "site_name": "Lirich", "contact_name": null, "contact_email": null, "contact_phone": null}
12	2026-07-29 09:21:18.631718+00	admin	sites.upsert	sites	LIR_005	{"active": true, "address": "NEA Tuas", "site_id": "LIR_005", "client_id": "LIR", "site_name": "Lirich", "created_at": "2026-07-24T15:15:51.944859+00:00", "contact_name": null, "contact_email": null, "contact_phone": null}	{"active": false, "address": "NEA Tuas", "site_id": "LIR_005", "client_id": "LIR", "site_name": "Lirich", "contact_name": null, "contact_email": null, "contact_phone": null}
13	2026-07-29 09:21:18.717033+00	admin	sites.upsert	sites	LIR_006	{"active": true, "address": "Others", "site_id": "LIR_006", "client_id": "LIR", "site_name": "Lirich", "created_at": "2026-07-27T17:56:07.661878+00:00", "contact_name": null, "contact_email": null, "contact_phone": null}	{"active": false, "address": "Others", "site_id": "LIR_006", "client_id": "LIR", "site_name": "Lirich", "contact_name": null, "contact_email": null, "contact_phone": null}
14	2026-07-29 09:21:18.788242+00	admin	sites.upsert	sites	SLS_003	{"active": true, "address": "Others", "site_id": "SLS_003", "client_id": "SLS", "site_name": "SLS", "created_at": "2026-07-27T17:56:07.661878+00:00", "contact_name": "Venkatesh", "contact_email": null, "contact_phone": "92200324"}	{"active": false, "address": "Others", "site_id": "SLS_003", "client_id": "SLS", "site_name": "SLS", "contact_name": null, "contact_email": null, "contact_phone": null}
15	2026-07-29 09:43:56.80782+00	admin	customers.upsert	customers	RAD	{"name": "Radha Exports Pte Ltd", "active": true, "client_id": "RAD", "sales_rep": null, "created_at": "2026-07-24T15:15:51.944859+00:00", "contact_name": null, "contact_email": null, "contact_phone": null, "payment_terms": null, "xero_contact_id": null}	{"name": "Radha Exports Pte Ltd", "client_id": "RAD"}
16	2026-07-29 09:43:56.845104+00	admin	sites.upsert	sites	RAD_003	{"active": true, "address": "118 Pioneer Road L7", "site_id": "RAD_003", "client_id": "RAD", "site_name": "Radha Exports Pte Ltd", "created_at": "2026-07-24T15:15:51.944859+00:00", "contact_name": null, "contact_email": null, "contact_phone": null}	{"active": true, "address": "118 Pioneer Road L7", "site_id": "RAD_003", "client_id": "RAD", "site_name": "Radha Exports Pte Ltd", "contact_name": "Eugene / Poornima", "contact_email": null, "contact_phone": "81614185 / 81572014"}
17	2026-07-29 09:43:56.909711+00	admin	rate_card.replace	rate_card	RAD_003	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Exchange"}, {"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}]
18	2026-07-29 09:46:40.720545+00	admin	customers.upsert	customers	RAD	{"name": "Radha Exports Pte Ltd", "active": true, "client_id": "RAD", "sales_rep": null, "created_at": "2026-07-24T15:15:51.944859+00:00", "contact_name": null, "contact_email": null, "contact_phone": null, "payment_terms": null, "xero_contact_id": null}	{"name": "Radha Exports Pte Ltd", "client_id": "RAD"}
19	2026-07-29 09:46:40.721644+00	admin	rate_card.replace	rate_card	RAD_001	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Exchange"}, {"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}]
20	2026-07-29 09:46:40.803743+00	admin	sites.upsert	sites	RAD_001	{"active": true, "address": "118 Pioneer Road L1", "site_id": "RAD_001", "client_id": "RAD", "site_name": "Radha Exports Pte Ltd", "created_at": "2026-07-24T15:15:51.944859+00:00", "contact_name": null, "contact_email": null, "contact_phone": null}	{"active": true, "address": "118 Pioneer Road L1", "site_id": "RAD_001", "client_id": "RAD", "site_name": "Radha Exports Pte Ltd", "contact_name": null, "contact_email": null, "contact_phone": "82982405 / 9185 8431"}
21	2026-07-29 09:46:40.852423+00	admin	customers.upsert	customers	SHI	{"name": "Shin Ya O Ya Pte Ltd", "active": true, "client_id": "SHI", "sales_rep": null, "created_at": "2026-07-24T15:15:51.944859+00:00", "contact_name": null, "contact_email": null, "contact_phone": null, "payment_terms": null, "xero_contact_id": null}	{"name": "Shin Ya O Ya Pte Ltd", "client_id": "SHI"}
22	2026-07-29 09:46:40.892647+00	admin	rate_card.replace	rate_card	SHI_002	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Exchange"}, {"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}]
23	2026-07-29 09:46:40.928816+00	admin	sites.upsert	sites	SHI_002	{"active": true, "address": "6 Chin Bee Ave L9", "site_id": "SHI_002", "client_id": "SHI", "site_name": "Shin Ya O Ya Pte Ltd", "created_at": "2026-07-24T15:15:51.944859+00:00", "contact_name": null, "contact_email": null, "contact_phone": null}	{"active": true, "address": "6 Chin Bee Ave L9", "site_id": "SHI_002", "client_id": "SHI", "site_name": "Shin Ya O Ya Pte Ltd", "contact_name": null, "contact_email": null, "contact_phone": "8919 2975"}
24	2026-07-29 09:46:40.954414+00	admin	customers.upsert	customers	TONG	{"name": "Tong Hock Pte Ltd", "active": true, "client_id": "TONG", "sales_rep": null, "created_at": "2026-07-24T15:15:51.944859+00:00", "contact_name": null, "contact_email": null, "contact_phone": null, "payment_terms": null, "xero_contact_id": null}	{"name": "Tong Hock Pte Ltd", "client_id": "TONG"}
25	2026-07-29 09:46:41.032005+00	admin	sites.upsert	sites	TONG_003	{"active": true, "address": "14 Tractor Road", "site_id": "TONG_003", "client_id": "TONG", "site_name": "Tong Hock Pte Ltd", "created_at": "2026-07-24T15:15:51.944859+00:00", "contact_name": null, "contact_email": null, "contact_phone": null}	{"active": true, "address": "14 Tractor Road", "site_id": "TONG_003", "client_id": "TONG", "site_name": "Tong Hock Pte Ltd", "contact_name": null, "contact_email": null, "contact_phone": "88206384"}
26	2026-07-29 14:10:47.194674+00	admin	sites.upsert	sites	HYU_002	\N	{"active": true, "address": "31 Tuas West Drive, Lamppost 74F", "site_id": "HYU_002", "client_id": "HYU", "site_name": "Hyundai Engineering & Construction Co., Ltd", "contact_name": "Liton", "contact_email": null, "contact_phone": "88960490"}
27	2026-07-29 14:10:47.231145+00	admin	rate_card.replace	rate_card	HYU_002	[]	[{"price": 8, "job_type": "Sell"}]
28	2026-07-29 14:14:14.19258+00	admin	sites.upsert	sites	HYU_002	{"active": true, "address": "31 Tuas West Drive, Lamppost 74F", "site_id": "HYU_002", "client_id": "HYU", "site_name": "Hyundai Engineering & Construction Co., Ltd", "created_at": "2026-07-29T14:10:47.111952+00:00", "contact_name": "Liton", "contact_email": null, "contact_phone": "88960490"}	{"active": true, "address": "31 Tuas West Drive, Lamppost 74F", "site_id": "HYU_002", "client_id": "HYU", "site_name": "Hyundai Engineering & Construction Co., Ltd", "contact_name": "Liton", "contact_email": null, "contact_phone": "88960490"}
29	2026-07-29 14:14:14.211928+00	admin	customers.upsert	customers	HYU	{"name": "Hyundai Engineering & Construction Co., Ltd", "active": true, "client_id": "HYU", "sales_rep": null, "created_at": "2026-07-24T15:15:51.944859+00:00", "contact_name": null, "contact_email": null, "contact_phone": null, "payment_terms": null, "xero_contact_id": null}	{"name": "Hyundai Engineering & Construction Co., Ltd", "client_id": "HYU"}
30	2026-07-29 14:14:14.373275+00	admin	rate_card.replace	rate_card	HYU_002	[{"price": 8, "job_type": "Sell", "valid_from": "2026-07-29"}]	[{"price": 13, "job_type": "Exchange"}, {"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}]
31	2026-07-29 15:41:31.713487+00	admin	rate_card.replace	rate_card	HYU_002	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-29"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-29"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-29"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 8, "job_type": "Sell"}]
32	2026-07-30 00:35:38.088664+00	admin	customers.upsert	customers	ECO	\N	{"name": "Ecozeal", "client_id": "ECO"}
33	2026-07-30 00:35:38.124905+00	admin	sites.upsert	sites	ECO_001	\N	{"active": true, "address": null, "site_id": "ECO_001", "client_id": "ECO", "site_name": "Ecozeal", "contact_name": null, "contact_email": null, "contact_phone": null}
34	2026-07-30 03:03:59.286913+00	admin	rate_card.replace	rate_card	ABS_001	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
35	2026-07-30 03:03:59.396265+00	admin	rate_card.replace	rate_card	ABS_002	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
36	2026-07-30 03:03:59.50747+00	admin	rate_card.replace	rate_card	ACR_001	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
37	2026-07-30 03:03:59.6105+00	admin	rate_card.replace	rate_card	ACR_002	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
38	2026-07-30 03:03:59.704618+00	admin	rate_card.replace	rate_card	ACR_003	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
39	2026-07-30 03:03:59.800099+00	admin	rate_card.replace	rate_card	ACR_004	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
40	2026-07-30 03:03:59.907967+00	admin	rate_card.replace	rate_card	ADV_001	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
42	2026-07-30 03:04:00.103448+00	admin	rate_card.replace	rate_card	ALL_001	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
43	2026-07-30 03:04:00.238883+00	admin	rate_card.replace	rate_card	ALLI_001	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
44	2026-07-30 03:04:00.38874+00	admin	rate_card.replace	rate_card	ALLI_002	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
45	2026-07-30 03:04:00.500206+00	admin	rate_card.replace	rate_card	ALLI_003	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
46	2026-07-30 03:04:00.592019+00	admin	rate_card.replace	rate_card	APE_001	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
47	2026-07-30 03:04:00.682601+00	admin	rate_card.replace	rate_card	APE_002	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
49	2026-07-30 03:04:00.877966+00	admin	rate_card.replace	rate_card	ART_001	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
50	2026-07-30 03:04:00.969797+00	admin	rate_card.replace	rate_card	ASL_001	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
41	2026-07-30 03:04:00.010925+00	admin	rate_card.replace	rate_card	AJK_001	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
48	2026-07-30 03:04:00.769925+00	admin	rate_card.replace	rate_card	ARC_001	[{"price": 18, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 18, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 18, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 18, "job_type": "Exchange"}, {"price": 26, "job_type": "Load"}]
55	2026-07-30 03:04:01.54069+00	admin	rate_card.replace	rate_card	BAB_003	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
62	2026-07-30 03:04:02.305557+00	admin	rate_card.replace	rate_card	BCW_006	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}, {"price": 31, "job_type": "Load", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
69	2026-07-30 03:04:02.956959+00	admin	rate_card.replace	rate_card	CAR_001	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
76	2026-07-30 03:04:03.863812+00	admin	rate_card.replace	rate_card	CHI_003	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
86	2026-07-30 03:04:04.855079+00	admin	rate_card.replace	rate_card	ENGI_002	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
93	2026-07-30 03:04:05.530106+00	admin	rate_card.replace	rate_card	ENGI_009	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
100	2026-07-30 03:04:06.16514+00	admin	rate_card.replace	rate_card	ENGI_016	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
107	2026-07-30 03:04:06.787936+00	admin	rate_card.replace	rate_card	ENGL_005	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
114	2026-07-30 03:04:07.761196+00	admin	rate_card.replace	rate_card	EPO_001	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
121	2026-07-30 03:04:08.345576+00	admin	rate_card.replace	rate_card	GLO_001	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
128	2026-07-30 03:04:08.948587+00	admin	rate_card.replace	rate_card	GSE_007	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
51	2026-07-30 03:04:01.065291+00	admin	rate_card.replace	rate_card	AST_001	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
58	2026-07-30 03:04:01.875548+00	admin	rate_card.replace	rate_card	BCW_002	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}, {"price": 31, "job_type": "Load", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
65	2026-07-30 03:04:02.568946+00	admin	rate_card.replace	rate_card	BND_002	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
72	2026-07-30 03:04:03.24036+00	admin	rate_card.replace	rate_card	CBM_001	[{"price": 18, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 18, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 18, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 18, "job_type": "Exchange"}, {"price": 26, "job_type": "Load"}]
79	2026-07-30 03:04:04.138035+00	admin	rate_card.replace	rate_card	CNC_001	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
84	2026-07-30 03:04:04.679059+00	admin	rate_card.replace	rate_card	ENG_001	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
91	2026-07-30 03:04:05.338693+00	admin	rate_card.replace	rate_card	ENGI_007	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
98	2026-07-30 03:04:05.998709+00	admin	rate_card.replace	rate_card	ENGI_014	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
105	2026-07-30 03:04:06.614894+00	admin	rate_card.replace	rate_card	ENGL_003	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
112	2026-07-30 03:04:07.206471+00	admin	rate_card.replace	rate_card	ENGL_010	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
119	2026-07-30 03:04:08.17954+00	admin	rate_card.replace	rate_card	FAX_001	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
126	2026-07-30 03:04:08.780093+00	admin	rate_card.replace	rate_card	GSE_005	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
133	2026-07-30 03:04:09.367804+00	admin	rate_card.replace	rate_card	HCG_002	[{"price": 18, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 18, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 18, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 18, "job_type": "Exchange"}, {"price": 26, "job_type": "Load"}]
52	2026-07-30 03:04:01.213675+00	admin	rate_card.replace	rate_card	AVE_001	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
59	2026-07-30 03:04:01.968398+00	admin	rate_card.replace	rate_card	BCW_003	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}, {"price": 31, "job_type": "Load", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
66	2026-07-30 03:04:02.658892+00	admin	rate_card.replace	rate_card	BND_003	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
73	2026-07-30 03:04:03.324551+00	admin	rate_card.replace	rate_card	CHA_001	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
80	2026-07-30 03:04:04.248394+00	admin	rate_card.replace	rate_card	CPH_001	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
85	2026-07-30 03:04:04.768373+00	admin	rate_card.replace	rate_card	ENGI_001	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
92	2026-07-30 03:04:05.443904+00	admin	rate_card.replace	rate_card	ENGI_008	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
99	2026-07-30 03:04:06.082475+00	admin	rate_card.replace	rate_card	ENGI_015	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
106	2026-07-30 03:04:06.708286+00	admin	rate_card.replace	rate_card	ENGL_004	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
113	2026-07-30 03:04:07.285681+00	admin	rate_card.replace	rate_card	ENGL_011	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
120	2026-07-30 03:04:08.262776+00	admin	rate_card.replace	rate_card	GEO_001	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
127	2026-07-30 03:04:08.870417+00	admin	rate_card.replace	rate_card	GSE_006	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
134	2026-07-30 03:04:09.472558+00	admin	rate_card.replace	rate_card	HEP_001	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
53	2026-07-30 03:04:01.349701+00	admin	rate_card.replace	rate_card	BAB_001	[{"price": 18, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 18, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 18, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 18, "job_type": "Exchange"}, {"price": 26, "job_type": "Load"}]
60	2026-07-30 03:04:02.058198+00	admin	rate_card.replace	rate_card	BCW_004	[{"price": 18, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 18, "job_type": "Exchange", "valid_from": "2026-07-23"}, {"price": 26, "job_type": "Load", "valid_from": "2026-07-23"}]	[{"price": 18, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 18, "job_type": "Exchange"}, {"price": 26, "job_type": "Load"}]
67	2026-07-30 03:04:02.782843+00	admin	rate_card.replace	rate_card	BND_004	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
74	2026-07-30 03:04:03.665704+00	admin	rate_card.replace	rate_card	CHI_001	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
81	2026-07-30 03:04:04.384433+00	admin	rate_card.replace	rate_card	CRE_001	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
90	2026-07-30 03:04:05.230018+00	admin	rate_card.replace	rate_card	ENGI_006	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
97	2026-07-30 03:04:05.914996+00	admin	rate_card.replace	rate_card	ENGI_013	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
104	2026-07-30 03:04:06.508063+00	admin	rate_card.replace	rate_card	ENGL_002	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
111	2026-07-30 03:04:07.101738+00	admin	rate_card.replace	rate_card	ENGL_009	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
118	2026-07-30 03:04:08.096057+00	admin	rate_card.replace	rate_card	EXP_001	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-29"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-29"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-29"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
125	2026-07-30 03:04:08.691109+00	admin	rate_card.replace	rate_card	GSE_004	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
132	2026-07-30 03:04:09.295011+00	admin	rate_card.replace	rate_card	HCG_001	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
139	2026-07-30 03:04:09.90367+00	admin	rate_card.replace	rate_card	HPR_001	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
54	2026-07-30 03:04:01.44237+00	admin	rate_card.replace	rate_card	BAB_002	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
61	2026-07-30 03:04:02.147137+00	admin	rate_card.replace	rate_card	BCW_005	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}, {"price": 31, "job_type": "Load", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
68	2026-07-30 03:04:02.868509+00	admin	rate_card.replace	rate_card	CAL_001	[{"price": 18, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 18, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 18, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 18, "job_type": "Exchange"}, {"price": 26, "job_type": "Load"}]
75	2026-07-30 03:04:03.767226+00	admin	rate_card.replace	rate_card	CHI_002	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
82	2026-07-30 03:04:04.477072+00	admin	rate_card.replace	rate_card	DSV_001	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
87	2026-07-30 03:04:04.940641+00	admin	rate_card.replace	rate_card	ENGI_003	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
94	2026-07-30 03:04:05.624688+00	admin	rate_card.replace	rate_card	ENGI_010	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
101	2026-07-30 03:04:06.250624+00	admin	rate_card.replace	rate_card	ENGI_017	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
108	2026-07-30 03:04:06.867338+00	admin	rate_card.replace	rate_card	ENGL_006	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
115	2026-07-30 03:04:07.846772+00	admin	rate_card.replace	rate_card	EUR_001	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
122	2026-07-30 03:04:08.425361+00	admin	rate_card.replace	rate_card	GSE_001	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
129	2026-07-30 03:04:09.033736+00	admin	rate_card.replace	rate_card	GWC_001	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
136	2026-07-30 03:04:09.633312+00	admin	rate_card.replace	rate_card	HEP_003	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
56	2026-07-30 03:04:01.632948+00	admin	rate_card.replace	rate_card	BAB_004	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
63	2026-07-30 03:04:02.396192+00	admin	rate_card.replace	rate_card	BCW_007	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}, {"price": 31, "job_type": "Load", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
70	2026-07-30 03:04:03.054969+00	admin	rate_card.replace	rate_card	CAT_001	[{"price": 18, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 18, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 18, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 18, "job_type": "Exchange"}, {"price": 26, "job_type": "Load"}]
77	2026-07-30 03:04:03.954313+00	admin	rate_card.replace	rate_card	CHU_001	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
89	2026-07-30 03:04:05.136937+00	admin	rate_card.replace	rate_card	ENGI_005	[{"price": 18, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 18, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 18, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 18, "job_type": "Exchange"}, {"price": 26, "job_type": "Load"}]
96	2026-07-30 03:04:05.789373+00	admin	rate_card.replace	rate_card	ENGI_012	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
103	2026-07-30 03:04:06.419582+00	admin	rate_card.replace	rate_card	ENGL_001	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
110	2026-07-30 03:04:07.024683+00	admin	rate_card.replace	rate_card	ENGL_008	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
117	2026-07-30 03:04:08.020242+00	admin	rate_card.replace	rate_card	EVE_001	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
124	2026-07-30 03:04:08.606104+00	admin	rate_card.replace	rate_card	GSE_003	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
131	2026-07-30 03:04:09.206018+00	admin	rate_card.replace	rate_card	HAI_001	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
138	2026-07-30 03:04:09.81597+00	admin	rate_card.replace	rate_card	HOT_001	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
145	2026-07-30 03:04:10.441519+00	admin	rate_card.replace	rate_card	INV_001	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
57	2026-07-30 03:04:01.734853+00	admin	rate_card.replace	rate_card	BCW_001	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}, {"price": 21, "job_type": "Load", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
64	2026-07-30 03:04:02.481999+00	admin	rate_card.replace	rate_card	BND_001	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
71	2026-07-30 03:04:03.145352+00	admin	rate_card.replace	rate_card	CAT_002	[{"price": 18, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 18, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 18, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 18, "job_type": "Exchange"}, {"price": 26, "job_type": "Load"}]
78	2026-07-30 03:04:04.04969+00	admin	rate_card.replace	rate_card	CLE_001	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
83	2026-07-30 03:04:04.585677+00	admin	rate_card.replace	rate_card	DYN_001	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
88	2026-07-30 03:04:05.025653+00	admin	rate_card.replace	rate_card	ENGI_004	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
95	2026-07-30 03:04:05.707587+00	admin	rate_card.replace	rate_card	ENGI_011	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
102	2026-07-30 03:04:06.338178+00	admin	rate_card.replace	rate_card	ENGI_018	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
109	2026-07-30 03:04:06.949237+00	admin	rate_card.replace	rate_card	ENGL_007	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
116	2026-07-30 03:04:07.932098+00	admin	rate_card.replace	rate_card	EUR_002	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
123	2026-07-30 03:04:08.525522+00	admin	rate_card.replace	rate_card	GSE_002	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
130	2026-07-30 03:04:09.118156+00	admin	rate_card.replace	rate_card	GYM_001	[{"price": 18, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 18, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 18, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 18, "job_type": "Exchange"}, {"price": 26, "job_type": "Load"}]
137	2026-07-30 03:04:09.718934+00	admin	rate_card.replace	rate_card	HON_001	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
135	2026-07-30 03:04:09.555973+00	admin	rate_card.replace	rate_card	HEP_002	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
142	2026-07-30 03:04:10.151012+00	admin	rate_card.replace	rate_card	HYD_001	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
149	2026-07-30 03:04:10.793636+00	admin	rate_card.replace	rate_card	LEN_001	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
154	2026-07-30 03:04:11.516199+00	admin	rate_card.replace	rate_card	NEA_001	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
162	2026-07-30 03:04:12.487277+00	admin	rate_card.replace	rate_card	RAD_001	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-29"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-29"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-29"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
169	2026-07-30 03:04:13.309123+00	admin	rate_card.replace	rate_card	SAV_002	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
176	2026-07-30 03:04:14.093622+00	admin	rate_card.replace	rate_card	SAVI_005	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
183	2026-07-30 03:04:14.865626+00	admin	rate_card.replace	rate_card	SIND_002	[{"price": 18, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 18, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 18, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 18, "job_type": "Exchange"}, {"price": 26, "job_type": "Load"}]
190	2026-07-30 03:04:15.621631+00	admin	rate_card.replace	rate_card	SPR_003	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
140	2026-07-30 03:04:09.982038+00	admin	rate_card.replace	rate_card	HUA_001	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
147	2026-07-30 03:04:10.624302+00	admin	rate_card.replace	rate_card	LAU_001	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
163	2026-07-30 03:04:12.608981+00	admin	rate_card.replace	rate_card	RAD_002	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
170	2026-07-30 03:04:13.413529+00	admin	rate_card.replace	rate_card	SAV_003	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
177	2026-07-30 03:04:14.21088+00	admin	rate_card.replace	rate_card	SEA_001	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
184	2026-07-30 03:04:14.968112+00	admin	rate_card.replace	rate_card	SINH_001	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
191	2026-07-30 03:04:15.738391+00	admin	rate_card.replace	rate_card	STA_001	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
196	2026-07-30 03:04:16.742049+00	admin	rate_card.replace	rate_card	STS_005	[{"price": 18, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 18, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 18, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 18, "job_type": "Exchange"}, {"price": 26, "job_type": "Load"}]
141	2026-07-30 03:04:10.069878+00	admin	rate_card.replace	rate_card	HUN_001	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
148	2026-07-30 03:04:10.712267+00	admin	rate_card.replace	rate_card	LCH_001	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
156	2026-07-30 03:04:11.762978+00	admin	rate_card.replace	rate_card	POH_001	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
161	2026-07-30 03:04:12.363182+00	admin	rate_card.replace	rate_card	QUA_001	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
168	2026-07-30 03:04:13.173593+00	admin	rate_card.replace	rate_card	SAV_001	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
175	2026-07-30 03:04:13.9828+00	admin	rate_card.replace	rate_card	SAVI_004	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
182	2026-07-30 03:04:14.756682+00	admin	rate_card.replace	rate_card	SIND_001	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
189	2026-07-30 03:04:15.508377+00	admin	rate_card.replace	rate_card	SPR_002	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
143	2026-07-30 03:04:10.271976+00	admin	rate_card.replace	rate_card	HYU_001	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
150	2026-07-30 03:04:10.900992+00	admin	rate_card.replace	rate_card	LEX_001	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
158	2026-07-30 03:04:11.987839+00	admin	rate_card.replace	rate_card	POH_003	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
165	2026-07-30 03:04:12.820356+00	admin	rate_card.replace	rate_card	RAD_004	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
172	2026-07-30 03:04:13.638518+00	admin	rate_card.replace	rate_card	SAVI_001	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
179	2026-07-30 03:04:14.434536+00	admin	rate_card.replace	rate_card	SHI_002	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-29"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-29"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-29"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
186	2026-07-30 03:04:15.173456+00	admin	rate_card.replace	rate_card	SLS_002	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
193	2026-07-30 03:04:15.975155+00	admin	rate_card.replace	rate_card	STS_002	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
144	2026-07-30 03:04:10.355917+00	admin	rate_card.replace	rate_card	HYU_002	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-29"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-29"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-29"}, {"price": 8, "job_type": "Sell", "valid_from": "2026-07-29"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 8, "job_type": "Sell"}, {"price": 21, "job_type": "Load"}]
151	2026-07-30 03:04:10.9909+00	admin	rate_card.replace	rate_card	LIM_001	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
159	2026-07-30 03:04:12.115024+00	admin	rate_card.replace	rate_card	POH_004	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
166	2026-07-30 03:04:12.954821+00	admin	rate_card.replace	rate_card	REM_001	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
173	2026-07-30 03:04:13.751267+00	admin	rate_card.replace	rate_card	SAVI_002	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
180	2026-07-30 03:04:14.543691+00	admin	rate_card.replace	rate_card	SIE_001	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
187	2026-07-30 03:04:15.278894+00	admin	rate_card.replace	rate_card	SNI_001	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
194	2026-07-30 03:04:16.467246+00	admin	rate_card.replace	rate_card	STS_003	[{"price": 18, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 18, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 18, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 18, "job_type": "Exchange"}, {"price": 26, "job_type": "Load"}]
146	2026-07-30 03:04:10.539679+00	admin	rate_card.replace	rate_card	IWA_001	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
153	2026-07-30 03:04:11.174601+00	admin	rate_card.replace	rate_card	MEC_001	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
157	2026-07-30 03:04:11.876023+00	admin	rate_card.replace	rate_card	POH_002	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
164	2026-07-30 03:04:12.715988+00	admin	rate_card.replace	rate_card	RAD_003	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-29"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-29"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-29"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
171	2026-07-30 03:04:13.525957+00	admin	rate_card.replace	rate_card	SAV_004	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
178	2026-07-30 03:04:14.332179+00	admin	rate_card.replace	rate_card	SHI_001	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
185	2026-07-30 03:04:15.069701+00	admin	rate_card.replace	rate_card	SLS_001	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
192	2026-07-30 03:04:15.849149+00	admin	rate_card.replace	rate_card	STS_001	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
152	2026-07-30 03:04:11.069453+00	admin	rate_card.replace	rate_card	MAT_001	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
155	2026-07-30 03:04:11.634448+00	admin	rate_card.replace	rate_card	PAX_001	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
160	2026-07-30 03:04:12.238123+00	admin	rate_card.replace	rate_card	PSA_001	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
167	2026-07-30 03:04:13.063008+00	admin	rate_card.replace	rate_card	RJH_001	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
174	2026-07-30 03:04:13.864566+00	admin	rate_card.replace	rate_card	SAVI_003	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
181	2026-07-30 03:04:14.655527+00	admin	rate_card.replace	rate_card	SIN_001	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
188	2026-07-30 03:04:15.400312+00	admin	rate_card.replace	rate_card	SPR_001	[{"price": 18, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 18, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 18, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 18, "job_type": "Exchange"}, {"price": 26, "job_type": "Load"}]
195	2026-07-30 03:04:16.574344+00	admin	rate_card.replace	rate_card	STS_004	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
197	2026-07-30 03:08:04.452103+00	admin	rate_card.replace	rate_card	STS_006	[{"price": 18, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 18, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 18, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 18, "job_type": "Exchange"}, {"price": 26, "job_type": "Load"}]
198	2026-07-30 03:08:04.606808+00	admin	rate_card.replace	rate_card	STX_001	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
199	2026-07-30 03:08:04.733127+00	admin	rate_card.replace	rate_card	STX_002	[{"price": 19.5, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 19.5, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 19.5, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 19.5, "job_type": "Exchange"}, {"price": 27.5, "job_type": "Load"}]
200	2026-07-30 03:08:04.843813+00	admin	rate_card.replace	rate_card	STX_003	[{"price": 19.5, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 19.5, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 19.5, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 19.5, "job_type": "Exchange"}, {"price": 27.5, "job_type": "Load"}]
201	2026-07-30 03:08:04.950907+00	admin	rate_card.replace	rate_card	STX_004	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
202	2026-07-30 03:08:05.177207+00	admin	rate_card.replace	rate_card	SUM_001	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
203	2026-07-30 03:08:05.290705+00	admin	rate_card.replace	rate_card	SUN_001	[{"price": 18, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 18, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 18, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 18, "job_type": "Exchange"}, {"price": 26, "job_type": "Load"}]
210	2026-07-30 03:08:06.12817+00	admin	rate_card.replace	rate_card	SYST_002	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
215	2026-07-30 03:08:06.635382+00	admin	rate_card.replace	rate_card	TOH_001	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
222	2026-07-30 03:08:07.4095+00	admin	rate_card.replace	rate_card	TONG_006	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
229	2026-07-30 03:08:08.189061+00	admin	rate_card.replace	rate_card	URB_001	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
236	2026-07-30 03:08:09.037083+00	admin	rate_card.replace	rate_card	WAH_007	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
204	2026-07-30 03:08:05.416058+00	admin	rate_card.replace	rate_card	SUN_002	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
216	2026-07-30 03:08:06.747653+00	admin	rate_card.replace	rate_card	TON_001	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
223	2026-07-30 03:08:07.516733+00	admin	rate_card.replace	rate_card	TONG_007	[{"price": 18, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 18, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 18, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 18, "job_type": "Exchange"}, {"price": 26, "job_type": "Load"}]
230	2026-07-30 03:08:08.295515+00	admin	rate_card.replace	rate_card	WAH_001	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
237	2026-07-30 03:08:09.142407+00	admin	rate_card.replace	rate_card	WEB_001	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
205	2026-07-30 03:08:05.538354+00	admin	rate_card.replace	rate_card	SUN_003	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
217	2026-07-30 03:08:06.852067+00	admin	rate_card.replace	rate_card	TONG_001	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
224	2026-07-30 03:08:07.643822+00	admin	rate_card.replace	rate_card	TONG_008	[{"price": 18, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 18, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 18, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 18, "job_type": "Exchange"}, {"price": 26, "job_type": "Load"}]
231	2026-07-30 03:08:08.405966+00	admin	rate_card.replace	rate_card	WAH_002	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
238	2026-07-30 03:08:09.256903+00	admin	rate_card.replace	rate_card	WIK_001	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
206	2026-07-30 03:08:05.643568+00	admin	rate_card.replace	rate_card	SUN_004	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
211	2026-07-30 03:08:06.25513+00	admin	rate_card.replace	rate_card	TAI_001	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
218	2026-07-30 03:08:06.965639+00	admin	rate_card.replace	rate_card	TONG_002	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
225	2026-07-30 03:08:07.748629+00	admin	rate_card.replace	rate_card	TONG_009	[{"price": 18, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 18, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 18, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 18, "job_type": "Exchange"}, {"price": 26, "job_type": "Load"}]
232	2026-07-30 03:08:08.542293+00	admin	rate_card.replace	rate_card	WAH_003	[{"price": 18, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 18, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 18, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 18, "job_type": "Exchange"}, {"price": 26, "job_type": "Load"}]
239	2026-07-30 03:08:09.399914+00	admin	rate_card.replace	rate_card	WIL_001	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
207	2026-07-30 03:08:05.758595+00	admin	rate_card.replace	rate_card	SUN_005	[{"price": 18, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 18, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 18, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 18, "job_type": "Exchange"}, {"price": 26, "job_type": "Load"}]
212	2026-07-30 03:08:06.348959+00	admin	rate_card.replace	rate_card	TEC_001	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
219	2026-07-30 03:08:07.068613+00	admin	rate_card.replace	rate_card	TONG_003	[{"price": 18, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 18, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 18, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 18, "job_type": "Exchange"}, {"price": 26, "job_type": "Load"}]
226	2026-07-30 03:08:07.855972+00	admin	rate_card.replace	rate_card	TOP_001	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
233	2026-07-30 03:08:08.681793+00	admin	rate_card.replace	rate_card	WAH_004	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
240	2026-07-30 03:08:09.506232+00	admin	rate_card.replace	rate_card	WOR_001	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
208	2026-07-30 03:08:05.893022+00	admin	rate_card.replace	rate_card	SYS_001	[{"price": 18, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 18, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 18, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 18, "job_type": "Exchange"}, {"price": 26, "job_type": "Load"}]
213	2026-07-30 03:08:06.447873+00	admin	rate_card.replace	rate_card	TECH_001	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
220	2026-07-30 03:08:07.182203+00	admin	rate_card.replace	rate_card	TONG_004	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
227	2026-07-30 03:08:07.977752+00	admin	rate_card.replace	rate_card	TRA_001	[{"price": 18, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 18, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 18, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 18, "job_type": "Exchange"}, {"price": 26, "job_type": "Load"}]
234	2026-07-30 03:08:08.803249+00	admin	rate_card.replace	rate_card	WAH_005	[{"price": 18, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 18, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 18, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 18, "job_type": "Exchange"}, {"price": 26, "job_type": "Load"}]
241	2026-07-30 03:08:09.607277+00	admin	rate_card.replace	rate_card	WRA_001	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
209	2026-07-30 03:08:05.994139+00	admin	rate_card.replace	rate_card	SYST_001	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
214	2026-07-30 03:08:06.542231+00	admin	rate_card.replace	rate_card	TECK_001	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
221	2026-07-30 03:08:07.304313+00	admin	rate_card.replace	rate_card	TONG_005	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
228	2026-07-30 03:08:08.076886+00	admin	rate_card.replace	rate_card	TST_001	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
235	2026-07-30 03:08:08.934118+00	admin	rate_card.replace	rate_card	WAH_006	[{"price": 23, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 23, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 23, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 23, "job_type": "Exchange"}, {"price": 31, "job_type": "Load"}]
242	2026-07-30 03:08:09.713022+00	admin	rate_card.replace	rate_card	WRA_002	[{"price": 13, "job_type": "Collect", "valid_from": "2026-07-23"}, {"price": 8, "job_type": "Delivery", "valid_from": "2026-07-23"}, {"price": 13, "job_type": "Exchange", "valid_from": "2026-07-23"}]	[{"price": 13, "job_type": "Collect"}, {"price": 8, "job_type": "Delivery"}, {"price": 13, "job_type": "Exchange"}, {"price": 21, "job_type": "Load"}]
243	2026-07-30 07:01:51.61358+00	admin	customers.upsert	customers	STX	{"name": "ST", "active": true, "client_id": "STX", "sales_rep": null, "created_at": "2026-07-24T15:15:51.944859+00:00", "contact_name": null, "contact_email": null, "contact_phone": null, "payment_terms": null, "xero_contact_id": null}	{"name": "ST Engineering", "client_id": "STX"}
244	2026-07-30 07:01:51.636636+00	admin	sites.upsert	sites	STX_001	{"active": true, "address": "6 Tuas South Street 15", "site_id": "STX_001", "client_id": "STX", "site_name": "ST", "created_at": "2026-07-24T15:15:51.944859+00:00", "contact_name": null, "contact_email": null, "contact_phone": null}	{"active": true, "address": "6 Tuas South Street 15", "site_id": "STX_001", "client_id": "STX", "site_name": "ST Engineering", "contact_name": null, "contact_email": null, "contact_phone": null}
245	2026-07-30 07:01:51.753186+00	admin	sites.upsert	sites	STX_002	{"active": true, "address": "Benoi", "site_id": "STX_002", "client_id": "STX", "site_name": "ST", "created_at": "2026-07-24T15:15:51.944859+00:00", "contact_name": null, "contact_email": null, "contact_phone": null}	{"active": true, "address": "Benoi", "site_id": "STX_002", "client_id": "STX", "site_name": "ST Engineering", "contact_name": null, "contact_email": null, "contact_phone": null}
246	2026-07-30 07:01:51.83284+00	admin	sites.upsert	sites	STX_003	{"active": true, "address": "Gul", "site_id": "STX_003", "client_id": "STX", "site_name": "ST", "created_at": "2026-07-24T15:15:51.944859+00:00", "contact_name": null, "contact_email": null, "contact_phone": null}	{"active": true, "address": "Gul", "site_id": "STX_003", "client_id": "STX", "site_name": "ST Engineering", "contact_name": null, "contact_email": null, "contact_phone": null}
247	2026-07-30 07:01:51.922394+00	admin	sites.upsert	sites	STX_004	{"active": true, "address": "61a Tuas Nexus Drive", "site_id": "STX_004", "client_id": "STX", "site_name": "ST", "created_at": "2026-07-24T15:15:51.944859+00:00", "contact_name": null, "contact_email": null, "contact_phone": null}	{"active": true, "address": "61a Tuas Nexus Drive", "site_id": "STX_004", "client_id": "STX", "site_name": "ST Engineering", "contact_name": null, "contact_email": null, "contact_phone": null}
249	2026-07-30 20:48:58.342355+00	admin	jobcard.set	jobcard	2026-07-30|5|trip:46:tonnage	{"value": "0"}	{"value": "10"}
250	2026-07-30 20:49:08.054269+00	admin	jobcard.set	jobcard	2026-07-30|5|trip:46:tonnage	{"value": "0"}	{"value": "0"}
251	2026-07-30 20:49:13.199909+00	admin	jobcard.set	jobcard	2026-07-30|5|trip:46:tonnage	{"value": "0"}	{"value": "10"}
252	2026-07-30 20:51:38.97822+00	admin	jobcard.set	jobcard	2026-07-30|5|trip:46:tonnage	{"value": "0"}	{"value": "0"}
253	2026-07-30 20:51:45.588961+00	admin	jobcard.set	jobcard	2026-07-30|5|trip:46:tonnage	{"value": "0"}	{"value": "03"}
254	2026-07-30 20:51:49.223986+00	admin	jobcard.set	jobcard	2026-07-30|5|trip:46:tonnage	{"value": "0"}	{"value": "0"}
255	2026-07-31 01:21:02.389054+00	admin	adjustment.add	collections	43109	{"net_kg": "3630"}	{"net_kg": "3600", "reason": "3600"}
256	2026-07-31 01:34:17.637186+00	legacy-key	adjustment.add	collections	43109	{"net_kg": "3630"}	{"net_kg": "3630", "reason": "Revert test adjustment (console Adjust verification) - back to original weighed value"}
257	2026-07-31 04:39:05.038499+00	admin	adjustment.add	collections	26065	{"net_kg": "7710"}	{"net_kg": "7700", "reason": "Weight correction (operator console)"}
258	2026-07-31 04:40:11.244199+00	admin	adjustment.add	collections	26065	{"net_kg": "7710"}	{"net_kg": "7710", "reason": "Weight correction (operator console)"}
\.


--
-- Data for Name: bins; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.bins (bin_id, bin_type, volume_m3, tare_kg, owner, purchase_cost, active) FROM stdin;
5028	5 ft	\N	\N	Lirich	\N	t
5038	5 ft	\N	\N	Lirich	\N	t
5044	5 ft	\N	\N	Lirich	\N	t
5046	5 ft	\N	\N	Lirich	\N	t
5047	5 ft	\N	\N	Lirich	\N	t
5051	5 ft	\N	\N	Lirich	\N	t
5056	5 ft	\N	\N	Lirich	\N	t
5057	5 ft	\N	\N	Lirich	\N	t
5058	5 ft	\N	\N	Lirich	\N	t
5060	5 ft	\N	\N	Lirich	\N	t
5064	5 ft	\N	\N	Lirich	\N	t
5069	5 ft	\N	\N	Lirich	\N	t
5073	5 ft	\N	\N	Lirich	\N	t
5079	5 ft	\N	\N	Lirich	\N	t
5081	5 ft	\N	\N	Lirich	\N	t
5083	5 ft	\N	\N	Lirich	\N	t
5084	5 ft	\N	\N	Lirich	\N	t
5086	5 ft	\N	\N	Lirich	\N	t
5089	5 ft	\N	\N	Lirich	\N	t
5092	5 ft	\N	\N	Lirich	\N	t
5096	5 ft	\N	\N	Lirich	\N	t
5106	5 ft	\N	\N	Lirich	\N	t
5108	5 ft	\N	\N	Lirich	\N	t
5116	5 ft	\N	\N	Lirich	\N	t
5123	5 ft	\N	\N	Lirich	\N	t
5135	5 ft	\N	\N	Lirich	\N	t
5142	5 ft	\N	\N	Lirich	\N	t
5147	5 ft	\N	\N	Lirich	\N	t
5151	5 ft	\N	\N	Lirich	\N	t
5153	5 ft	\N	\N	Lirich	\N	t
5160	5 ft	\N	\N	Lirich	\N	t
5162	5 ft	\N	\N	Lirich	\N	t
5169	5 ft	\N	\N	Lirich	\N	t
5176	5 ft	\N	\N	Lirich	\N	t
5194	5 ft	\N	\N	Lirich	\N	t
5196	5 ft	\N	\N	Lirich	\N	t
5197	5 ft	\N	\N	Lirich	\N	t
5198	5 ft	\N	\N	Lirich	\N	t
5199	5 ft	\N	\N	Lirich	\N	t
5203	5 ft	\N	\N	Lirich	\N	t
5204	5 ft	\N	\N	Lirich	\N	t
5210	5 ft	\N	\N	Lirich	\N	t
5211	5 ft	\N	\N	Lirich	\N	t
5213	5 ft	\N	\N	Lirich	\N	t
5217	5 ft	\N	\N	Lirich	\N	t
5220	5 ft	\N	\N	Lirich	\N	t
5221	5 ft	\N	\N	Lirich	\N	t
5222	5 ft	\N	\N	Lirich	\N	t
5232	5 ft	\N	\N	Lirich	\N	t
5239	5 ft	\N	\N	Lirich	\N	t
5240	5 ft	\N	\N	Lirich	\N	t
5245	5 ft	\N	\N	Lirich	\N	t
5247	5 ft	\N	\N	Lirich	\N	t
660L-TBD	660L	\N	\N	Lirich	\N	t
7006	7 ft	\N	\N	Lirich	\N	t
7016	7 ft	\N	\N	Lirich	\N	t
7017	7 ft	\N	\N	Lirich	\N	t
7022	7 ft	\N	\N	Lirich	\N	t
8007	7 ft	\N	\N	Lirich	\N	t
\.


--
-- Data for Name: collections; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.collections (do_no, source, job_no, do_date, do_type, trip_type, site_id, vessel_name, berth, vehicle_id, driver_id, job_type, waste_type, bin_in, bin_out, vol_cat_a, vol_cat_b, vol_cat_c, vol_cat_d, vol_cat_e, vol_cat_f, vol_total_m3, gross_kg, tare_kg, net_kg, weigh_ticket_no, weigh_location, weight_source, gps_lat, gps_lng, gps_accuracy_m, gps_captured_at, photo_do_ref, photo_sig_ref, photo_weigh_ref, receipt_ref, disposal_facility, xero_invoice_id, backfill_notes, synced_at, sludge_requested_t, sludge_actual_t, dispose_to) FROM stdin;
24242	backfill	\N	2026-06-02	land	Exchange	SAV_001	\N	\N	XE4491D	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill from DO scan (Jun 2026) — DATE NOT LEGIBLE on DO — verify | DATE NOT LEGIBLE on DO — verify	2026-07-24 15:15:51.944859+00	\N	\N	\N
24191	backfill	\N	2026-06-08	land	Exchange	SAV_001	\N	\N	\N	\N	\N	General Waste	5197	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill from DO scan (Jun 2026) — Bin In/Out handwriting unclear — verify | Bin In/Out handwriting unclear — verify	2026-07-24 15:15:51.944859+00	\N	\N	\N
23636	backfill	\N	\N	land	Exchange	SAV_001	\N	\N	XE6221D	\N	\N	General Waste	\N	5240	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill from DO scan (Jun 2026) — Date 05 or 09 Jun — verify | Date 05 or 09 Jun — verify	2026-07-24 15:15:51.944859+00	\N	\N	\N
18791	backfill	\N	2026-06-27	vessel	PSA Vessel	PIL_001	KOTA KARIM	B05	XE7126P	YAO_JUN	\N	Vessel Waste	\N	\N	0.90	0.00	0.70	0.04	0.01	2.00	3.65	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill | rechecked	2026-07-24 15:15:51.944859+00	\N	\N	\N
18792	backfill	\N	2026-06-28	vessel	PSA Vessel	PIL_001	KOTA SURIA	B05	XE7126P	YAO_JUN	\N	Vessel Waste	\N	\N	0.80	0.02	0.40	0.01	0.00	\N	1.32	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill; FADED scan — Cat values (incl F) unclear, verify | rechecked	2026-07-24 15:15:51.944859+00	\N	\N	\N
18917	backfill	\N	2026-04-04	vessel	PSA Vessel	PIL_001	KOTA KARIM	B06	XE6221D	SATHISH	\N	Vessel Waste	\N	\N	1.30	0.02	1.40	0.02	0.01	0.80	3.55	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill; Incl oily rags; DO marked ONLY FOR RECEIPT | rechecked	2026-07-24 15:15:51.944859+00	\N	\N	\N
18931	backfill	\N	2026-05-01	vessel	PSA Vessel	PIL_001	KOTA SURIA	B06	XE6221D	SATHISH	\N	Vessel Waste	\N	\N	0.80	0.02	0.40	0.02	0.02	0.00	1.26	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill | rechecked	2026-07-24 15:15:51.944859+00	\N	\N	\N
18932	backfill	\N	2026-05-02	vessel	PSA Vessel	PIL_001	KOTA NABIL	B05	XE6221D	SATHISH	\N	Vessel Waste	\N	\N	0.80	0.00	0.20	0.00	0.10	0.40	1.50	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill | rechecked	2026-07-24 15:15:51.944859+00	\N	\N	\N
18933	backfill	\N	2026-05-07	vessel	PSA Vessel	PIL_001	KOTA RUKUN	B05	XE6221D	SATHISH	\N	Vessel Waste	\N	\N	1.30	0.00	0.80	0.00	0.00	0.50	2.60	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill | rechecked	2026-07-24 15:15:51.944859+00	\N	\N	\N
18938	backfill	\N	2026-05-07	vessel	PSA Vessel	PIL_001	KOTA NAGA	P04	XE6221D	SATHISH	\N	Vessel Waste	\N	\N	0.40	0.03	0.70	0.00	0.00	0.30	1.43	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill | rechecked	2026-07-24 15:15:51.944859+00	\N	\N	\N
18940	backfill	\N	2026-05-08	vessel	PSA Vessel	PIL_001	KOTA GAYA	B05	XE6221D	SATHISH	\N	Vessel Waste	\N	\N	0.70	0.00	0.70	0.01	0.00	0.59	2.00	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill; Incl 0.2 m3 oil rags | rechecked	2026-07-24 15:15:51.944859+00	\N	\N	\N
18943	backfill	\N	2026-05-13	vessel	PSA Vessel	PIL_001	KOTA MANIS	B06	XE6221D	SATHISH	\N	Vessel Waste	\N	\N	0.60	0.02	0.40	0.00	0.00	0.28	1.30	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill | rechecked	2026-07-24 15:15:51.944859+00	\N	\N	\N
18947	backfill	\N	2026-05-24	vessel	PSA Vessel	PIL_001	KOTA HAKIM	P08	XE6221D	SATHISH	\N	Vessel Waste	\N	\N	0.00	0.00	0.00	0.02	0.00	1.10	1.12	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill; Mostly oily rags | rechecked	2026-07-24 15:15:51.944859+00	\N	\N	\N
18950	backfill	\N	2026-05-25	vessel	PSA Vessel	PIL_001	KOTA CANTIK	B05	XE6221D	SATHISH	\N	Vessel Waste	\N	\N	1.00	0.00	1.00	0.00	0.01	0.60	2.61	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill; Incl 0.1 m3 oily rags | rechecked	2026-07-24 15:15:51.944859+00	\N	\N	\N
23947	backfill	\N	2026-06-30	land	Exchange	SAV_001	\N	\N	XE6221D	\N	\N	General Waste	5079	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	bin_out_raw=5032 | remarks=Backfill from DO scan (Jun 2026)	2026-07-24 15:15:51.944859+00	\N	\N	\N
24066	backfill	\N	2026-06-30	land	Exchange	SAV_001	\N	\N	\N	\N	\N	General Waste	\N	5084	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill from DO scan (Jun 2026) — Bin In/Out unclear — verify | Bin In/Out unclear — verify	2026-07-24 15:15:51.944859+00	\N	\N	\N
26931	backfill	\N	2026-05-02	land	Exchange	PAX_001	\N	\N	XE5457Y	\N	\N	General Waste	\N	5089	\N	\N	\N	\N	\N	\N	\N	14010.0	17630.0	3620.0	884	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by MORTHY-K009910	2026-07-24 15:15:51.944859+00	\N	\N	\N
26932	backfill	\N	2026-05-02	land	Exchange	PAX_001	\N	\N	XE5457Y	\N	\N	General Waste	5089	5160	\N	\N	\N	\N	\N	\N	\N	14590.0	18910.0	4260.0	885	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by BALA-K009902	2026-07-24 15:15:51.944859+00	\N	\N	\N
26934	backfill	\N	2026-05-02	land	Exchange	PAX_001	\N	\N	XE5457Y	\N	\N	General Waste	\N	5089	\N	\N	\N	\N	\N	\N	\N	14410.0	21080.0	6670.0	887	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by BALA-K009902; DO 26933 not in this batch (gap) | DO 26933 not in this batch (gap)	2026-07-24 15:15:51.944859+00	\N	\N	\N
26935	backfill	\N	2026-05-02	land	Exchange	PAX_001	\N	\N	XE5457Y	\N	\N	General Waste	5069	\N	\N	\N	\N	\N	\N	\N	\N	14730.0	17410.0	2690.0	891	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by MURU-K001956	2026-07-24 15:15:51.944859+00	\N	\N	\N
25769	backfill	\N	2026-05-04	land	Exchange	PAX_001	\N	\N	XE4491D	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	14470.0	20550.0	6080.0	892	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by MURU-K001956	2026-07-24 15:15:51.944859+00	\N	\N	\N
25770	backfill	\N	2026-05-04	land	Exchange	PAX_001	\N	\N	XE4491D	\N	\N	General Waste	\N	5069	\N	\N	\N	\N	\N	\N	\N	14940.0	17460.0	2620.0	894	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by WILLIAM NG-K007671; Gross ~14,940 — verify | Gross ~14,940 — verify	2026-07-24 15:15:51.944859+00	\N	\N	\N
25774	backfill	\N	2026-05-05	land	Exchange	PAX_001	\N	\N	XE4491D	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	14860.0	16150.0	1290.0	898	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	bin_in_raw=5224 | remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by AMIR-K12898	2026-07-24 15:15:51.944859+00	\N	\N	\N
25775	backfill	\N	2026-05-05	land	Exchange	PAX_001	\N	\N	XE4491D	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	14380.0	17370.0	2990.0	902	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by AMIR-K12898	2026-07-24 15:15:51.944859+00	\N	\N	\N
25778	backfill	\N	2026-05-06	land	Exchange	PAX_001	\N	\N	XE4491D	\N	\N	General Waste	5194	\N	\N	\N	\N	\N	\N	\N	\N	14400.0	17740.0	3340.0	908	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	bin_out_raw=5224 | remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by AMIR-K12898	2026-07-24 15:15:51.944859+00	\N	\N	\N
25779	backfill	\N	2026-05-06	land	Exchange	PAX_001	\N	\N	XE4491D	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	14980.0	16220.0	1240.0	910	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	bin_in_raw=5224 | remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by AMIR-K12898	2026-07-24 15:15:51.944859+00	\N	\N	\N
25783	backfill	\N	2026-05-07	land	Exchange	PAX_001	\N	\N	XE4491D	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	14790.0	17160.0	2370.0	916	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	bin_out_raw=5224 | remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by MURU-K001956	2026-07-24 15:15:51.944859+00	\N	\N	\N
25794	backfill	\N	2026-05-09	land	Exchange	PAX_001	\N	\N	XE4491D	\N	\N	General Waste	\N	5069	\N	\N	\N	\N	\N	\N	\N	14610.0	16810.0	2230.0	957	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by BALA-K009902; Bin Out reading 5069/8069 — verify | Bin Out reading 5069/8069 — verify	2026-07-24 15:15:51.944859+00	\N	\N	\N
25790	backfill	\N	2026-05-08	land	Exchange	PAX_001	\N	\N	XE4491D	\N	\N	General Waste	5160	5194	\N	\N	\N	\N	\N	\N	\N	14790.0	16500.0	1710.0	952	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by MUSTAFA	2026-07-24 15:15:51.944859+00	\N	\N	\N
25786	backfill	\N	2026-05-08	land	Exchange	PAX_001	\N	\N	XE4491D	\N	\N	General Waste	5160	5194	\N	\N	\N	\N	\N	\N	\N	14700.0	17240.0	2540.0	932	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by AMIR-K12898; Same bins as DO 25790 — verify | Same bins as DO 25790 — verify	2026-07-24 15:15:51.944859+00	\N	\N	\N
25787	backfill	\N	2026-05-08	land	Exchange	PAX_001	\N	\N	XE4491D	\N	\N	General Waste	5194	\N	\N	\N	\N	\N	\N	\N	\N	14430.0	18700.0	4270.0	936	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by AMIR-K12898; DO date blank; used weighbridge date | DO date blank; used weighbridge date	2026-07-24 15:15:51.944859+00	\N	\N	\N
25789	backfill	\N	2026-05-08	land	Exchange	PAX_001	\N	\N	XE4491D	\N	\N	General Waste	5069	5160	\N	\N	\N	\N	\N	\N	\N	15180.0	18960.0	3780.0	947	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by MUSTAFA	2026-07-24 15:15:51.944859+00	\N	\N	\N
26789	backfill	\N	2026-05-11	land	Exchange	PAX_001	\N	\N	XE6221D	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	14010.0	16180.0	2170.0	970	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by AMIR-K12898	2026-07-24 15:15:51.944859+00	\N	\N	\N
26790	backfill	\N	2026-05-11	land	Exchange	PAX_001	\N	\N	XE6221D	\N	\N	General Waste	\N	5160	\N	\N	\N	\N	\N	\N	\N	14170.0	20880.0	6710.0	975	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by AMIR-K12898	2026-07-24 15:15:51.944859+00	\N	\N	\N
26795	backfill	\N	2026-05-11	land	Exchange	PAX_001	\N	\N	XE6221D	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	14230.0	19450.0	5220.0	983	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by AMIR-K12898	2026-07-24 15:15:51.944859+00	\N	\N	\N
26806	backfill	\N	2026-05-12	land	Exchange	PAX_001	\N	\N	XE6221D	\N	\N	General Waste	5135	\N	\N	\N	\N	\N	\N	\N	\N	14080.0	16420.0	2340.0	994	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by MUSTAFA	2026-07-24 15:15:51.944859+00	\N	\N	\N
26801	backfill	\N	2026-05-12	land	Exchange	PAX_001	\N	\N	XE6221D	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	14150.0	16920.0	2470.0	986	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by MUSTAFA	2026-07-24 15:15:51.944859+00	\N	\N	\N
26802	backfill	\N	2026-05-12	land	Exchange	PAX_001	\N	\N	XE6221D	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	14190.0	16510.0	2320.0	988	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by AMIR-K12898	2026-07-24 15:15:51.944859+00	\N	\N	\N
26813	backfill	\N	2026-05-13	land	Exchange	PAX_001	\N	\N	XE6221D	\N	\N	General Waste	5135	\N	\N	\N	\N	\N	\N	\N	\N	14020.0	14310.0	290.0	1002	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by AMIR-K12898	2026-07-24 15:15:51.944859+00	\N	\N	\N
26812	backfill	\N	2026-05-13	land	Exchange	PAX_001	\N	\N	XE6221D	\N	\N	General Waste	\N	5135	\N	\N	\N	\N	\N	\N	\N	14100.0	17670.0	3570.0	1001	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by AMIR-K12898	2026-07-24 15:15:51.944859+00	\N	\N	\N
26822	backfill	\N	2026-05-15	land	Exchange	PAX_001	\N	\N	XE6221D	\N	\N	General Waste	\N	5204	\N	\N	\N	\N	\N	\N	\N	14250.0	16970.0	2720.0	1025	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by MORTHY-K00910	2026-07-24 15:15:51.944859+00	\N	\N	\N
26826	backfill	\N	2026-05-16	land	Exchange	PAX_001	\N	\N	XE6221D	\N	\N	General Waste	5194	5058	\N	\N	\N	\N	\N	\N	\N	14060.0	16080.0	2020.0	1031	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by AMIR-K12898	2026-07-24 15:15:51.944859+00	\N	\N	\N
26828	backfill	\N	2026-05-16	land	Exchange	PAX_001	\N	\N	XE6221D	\N	\N	General Waste	5047	\N	\N	\N	\N	\N	\N	\N	\N	14730.0	15920.0	1110.0	1036	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by AMIR-K12898	2026-07-24 15:15:51.944859+00	\N	\N	\N
43191	live	\N	2026-07-30	land	Exchange	STX_001	\N	\N	XE7126P	YAO_JUN	Exchange	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	16350.0	13950.0	2400.0	LR46	\N	weighbridge	\N	\N	\N	\N	https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms72uum7-DO-97-1.jpg	\N	\N	\N	\N	\N	app_trip_id=53 | bin_photos=https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms72uu5y-BININ-97-1.jpg\nhttps://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms72uuhw-BINOUT-97-1.jpg | bin_in_raw=6005 | bin_out_raw=6005 | job_no=97	2026-07-30 05:51:31.495+00	\N	\N	\N
LR26/04/0194	backfill	\N	2026-04-30	\N	\N	STE_001	\N	\N	\N	\N	\N	Used Tyre Fender	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	3730.0	\N	\N	invoice	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1 trip; PO 3020394416; inv $4,139.82	2026-07-31 03:02:32.106388+00	\N	\N	\N
LR26/04/0195	backfill	\N	2026-04-30	\N	\N	STE_002	\N	\N	\N	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	249150.0	\N	\N	invoice	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	59 trips; PO 3020393606; inv $26,642.11	2026-07-31 03:02:32.106388+00	\N	\N	\N
23482	backfill	\N	2026-05-25	land	Exchange	PAX_001	\N	\N	XE5457Y	\N	\N	General Waste	5162	\N	\N	\N	\N	\N	\N	\N	\N	14510.0	17520.0	3010.0	1128	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by MUSTAFA	2026-07-24 15:15:51.944859+00	\N	\N	\N
23483	backfill	\N	2026-05-25	land	Exchange	PAX_001	\N	\N	XE5457Y	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	14100.0	18190.0	4090.0	1130	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by AMIR-K12898	2026-07-24 15:15:51.944859+00	\N	\N	\N
23486	backfill	\N	2026-05-25	land	Exchange	PAX_001	\N	\N	XE5457Y	\N	\N	General Waste	\N	5162	\N	\N	\N	\N	\N	\N	\N	14470.0	19070.0	3600.0	1138	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by AMIR-K12898	2026-07-24 15:15:51.944859+00	\N	\N	\N
23491	backfill	\N	2026-05-26	land	Exchange	PAX_001	\N	\N	XE5457Y	\N	\N	General Waste	5108	\N	\N	\N	\N	\N	\N	\N	\N	14240.0	16720.0	2480.0	1153	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by AMIR-K12898	2026-07-24 15:15:51.944859+00	\N	\N	\N
23488	backfill	\N	2026-05-26	land	Exchange	PAX_001	\N	\N	XE5457Y	\N	\N	General Waste	5038	\N	\N	\N	\N	\N	\N	\N	\N	14790.0	17970.0	3190.0	1144	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by AMIR-K12898	2026-07-24 15:15:51.944859+00	\N	\N	\N
23493	backfill	\N	2026-05-28	land	Exchange	PAX_001	\N	\N	XE5457Y	\N	\N	General Waste	5056	5038	\N	\N	\N	\N	\N	\N	\N	14710.0	18950.0	4240.0	1175	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by MUSTAFA	2026-07-24 15:15:51.944859+00	\N	\N	\N
23494	backfill	\N	2026-05-28	land	Exchange	PAX_001	\N	\N	XE5457Y	\N	\N	General Waste	5038	5108	\N	\N	\N	\N	\N	\N	\N	14650.0	16980.0	2330.0	1177	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by MURU-K001956	2026-07-24 15:15:51.944859+00	\N	\N	\N
23496	backfill	\N	2026-05-28	land	Exchange	PAX_001	\N	\N	XE5457Y	\N	\N	General Waste	5044	5056	\N	\N	\N	\N	\N	\N	\N	14670.0	17450.0	2780.0	1179	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by BALA-K009902	2026-07-24 15:15:51.944859+00	\N	\N	\N
23706	backfill	\N	2026-05-29	land	Exchange	PAX_001	\N	\N	XE5457Y	\N	\N	General Waste	5084	5232	\N	\N	\N	\N	\N	\N	\N	14730.0	17710.0	2980.0	1193	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by MURU-K001956	2026-07-24 15:15:51.944859+00	\N	\N	\N
23499	backfill	\N	2026-05-29	land	Exchange	PAX_001	\N	\N	XE5457Y	\N	\N	General Waste	5232	5038	\N	\N	\N	\N	\N	\N	\N	14560.0	16550.0	1990.0	1184	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by MUSTAFA	2026-07-24 15:15:51.944859+00	\N	\N	\N
23707	backfill	\N	2026-05-30	land	Exchange	PAX_001	\N	\N	XE5457Y	\N	\N	General Waste	5232	5044	\N	\N	\N	\N	\N	\N	\N	14730.0	18310.0	3580.0	1196	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by BALA-K009902; DO remark: SEND BIN | DO remark: SEND BIN	2026-07-24 15:15:51.944859+00	\N	\N	\N
LR26/04/0196	backfill	\N	2026-04-30	\N	\N	STE_002	\N	\N	\N	\N	\N	Wood Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	49530.0	\N	\N	invoice	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	12 trips; PO 3020393606; inv $4,316.83	2026-07-31 03:02:32.106388+00	\N	\N	\N
LR26/04/0197	backfill	\N	2026-04-30	\N	\N	STE_002	\N	\N	\N	\N	\N	Rubber Fender	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1800.0	\N	\N	invoice	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1 trip; PO 3020393606; inv $2,036.12	2026-07-31 03:02:32.106388+00	\N	\N	\N
LR26/04/0199	backfill	\N	2026-04-23	\N	\N	STE_002	\N	\N	\N	\N	\N	Yokohama Fender	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	440.0	\N	\N	invoice	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	vessel ENERGETIC; PO 3020395060; inv $553.72	2026-07-31 03:02:32.106388+00	\N	\N	\N
LR26/04/0200	backfill	\N	2026-04-23	\N	\N	STE_002	\N	\N	\N	\N	\N	Old Paint	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	invoice	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	20L x33 + 5L x80 cans; vessel SEA AMETHYST; PO 3020395060; inv $218.00	2026-07-31 03:02:32.106388+00	\N	\N	\N
LR26/05/0169	backfill	\N	2026-05-19	\N	\N	STE_001	\N	\N	\N	\N	\N	Misc (Electrode Stud Ends + NDT Chemical Cans)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	invoice	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2 lots @ $44.50; ref 3020394448; inv $97.01	2026-07-31 03:02:32.106388+00	\N	\N	\N
LR26/05/0240	backfill	\N	2026-05-31	\N	\N	STE_001	\N	\N	\N	\N	\N	Wood Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	81490.0	\N	\N	invoice	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	25 trips; PO 3020398080; inv $7,503.42	2026-07-31 03:02:32.106388+00	\N	\N	\N
LR26/05/0241	backfill	\N	2026-05-31	\N	\N	STE_001	\N	\N	\N	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	138400.0	\N	\N	invoice	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	24 trips; PO 3020398080; inv $14,149.07	2026-07-31 03:02:32.106388+00	\N	\N	\N
LR26/05/0242	backfill	\N	2026-05-31	\N	\N	STE_002	\N	\N	\N	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	213600.0	\N	\N	invoice	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	45 trips; PO 3020396389; inv $22,426.97	2026-07-31 03:02:32.106388+00	\N	\N	\N
LR26/05/0243	backfill	\N	2026-05-31	\N	\N	STE_002	\N	\N	\N	\N	\N	Wood Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	35630.0	\N	\N	invoice	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	8 trips; PO 3020396389; inv $3,057.11	2026-07-31 03:02:32.106388+00	\N	\N	\N
LR26/05/0244	backfill	\N	2026-05-31	\N	\N	STE_002	\N	\N	\N	\N	\N	Rubber Fender	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	14380.0	\N	\N	invoice	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	3 trips; PO 3020396389; inv $15,896.56	2026-07-31 03:02:32.106388+00	\N	\N	\N
LR26/05/0245	backfill	\N	2026-05-31	\N	\N	STE_002	\N	\N	\N	\N	\N	Used Tyre	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	invoice	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	15 pcs @ $3; 1 trip; PO 3020396389; inv $123.17	2026-07-31 03:02:32.106388+00	\N	\N	\N
24184	backfill	\N	2026-06-06	\N	\N	STE_004	\N	\N	\N	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	6100.0	\N	\N	invoice	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	DO#24184; IWMF Pkg 1; PO 3020397117; part of inv LR26/06/0010	2026-07-31 03:02:32.106388+00	\N	\N	\N
23710	backfill	\N	2026-05-30	land	Exchange	PAX_001	\N	\N	XE5457Y	\N	\N	General Waste	\N	5084	\N	\N	\N	\N	\N	\N	\N	14180.0	19930.0	5750.0	1210	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by BALA-K009902	2026-07-24 15:15:51.944859+00	\N	\N	\N
26809	backfill	\N	2026-05-13	land	Exchange	PAX_001	\N	\N	XE6221D	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	13990.0	14950.0	970.0	998	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by AMIR-K12898 | pt7 missing-middle	2026-07-24 15:15:51.944859+00	\N	\N	\N
26815	backfill	\N	2026-05-14	land	Exchange	PAX_001	\N	\N	XE6221D	\N	\N	General Waste	5079	\N	\N	\N	\N	\N	\N	\N	\N	14390.0	14800.0	410.0	1003	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by MURU-K001956 | pt7 missing-middle	2026-07-24 15:15:51.944859+00	\N	\N	\N
26816	backfill	\N	2026-05-14	land	Exchange	PAX_001	\N	\N	XE6221D	\N	\N	General Waste	\N	5135	\N	\N	\N	\N	\N	\N	\N	14300.0	16020.0	1720.0	1006	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by AMIR-K12898 | pt7 missing-middle	2026-07-24 15:15:51.944859+00	\N	\N	\N
26820	backfill	\N	2026-05-14	land	Exchange	PAX_001	\N	\N	XE6221D	\N	\N	General Waste	5204	5079	\N	\N	\N	\N	\N	\N	\N	14420.0	15810.0	1390.0	1010	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by MORTHY-K000910 | pt7 missing-middle	2026-07-24 15:15:51.944859+00	\N	\N	\N
26821	backfill	\N	2026-05-15	land	Exchange	PAX_001	\N	\N	XE6221D	\N	\N	General Waste	5058	\N	\N	\N	\N	\N	\N	\N	\N	14610.0	15610.0	1000.0	1023	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by MUSTAFA | pt7 missing-middle	2026-07-24 15:15:51.944859+00	\N	\N	\N
17902	backfill	\N	2026-05-28	vessel	PSA Vessel	PIL_001	KOTA LEKAS	B06	XE6221D	SATHISH	\N	Vessel Waste	\N	\N	0.80	0.06	0.60	0.02	0.00	0.80	2.40	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill; Cat I 0.12 m3; 0.20 m3 oily rags | Cat I 0.12 m3; 0.20 m3 oily rags	2026-07-24 15:15:51.944859+00	\N	\N	\N
17903	backfill	\N	2026-05-29	vessel	PSA Vessel	PIL_001	KOTA SAHABAT	B06	XE6221D	SATHISH	\N	Vessel Waste	\N	\N	0.30	0.04	0.30	0.00	0.00	0.40	1.04	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill	2026-07-24 15:15:51.944859+00	\N	\N	\N
17904	backfill	\N	2026-05-30	vessel	PSA Vessel	PIL_001	KOTA SEGAR	B05	XE6221D	SATHISH	\N	Vessel Waste	\N	\N	0.40	0.00	0.40	0.02	0.00	0.20	1.02	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill	2026-07-24 15:15:51.944859+00	\N	\N	\N
17906	backfill	\N	2026-05-31	vessel	PSA Vessel	PIL_001	KOTA CARUM	B06	XE6221D	SATHISH	\N	Vessel Waste	\N	\N	1.20	0.00	0.60	0.00	0.03	0.30	2.13	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill	2026-07-24 15:15:51.944859+00	\N	\N	\N
17907	backfill	\N	2026-06-02	vessel	PSA Vessel	PIL_001	KOTA GANDING	B06	XE6221D	SATHISH	\N	Vessel Waste	\N	\N	0.50	0.02	0.40	0.01	0.00	0.40	1.34	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill; Cat I E-waste 0.01 m3 | Cat I E-waste 0.01 m3	2026-07-24 15:15:51.944859+00	\N	\N	\N
17911	backfill	\N	2026-06-05	vessel	PSA Vessel	PIL_001	KOTA RAJIN	B05	XE6221D	SATHISH	\N	Vessel Waste	\N	\N	0.20	0.02	0.20	0.02	0.00	0.20	0.66	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill; Cat I E-waste 0.02 m3 | Cat I E-waste 0.02 m3	2026-07-24 15:15:51.944859+00	\N	\N	\N
17919	backfill	\N	2026-06-13	vessel	PSA Vessel	PIL_001	KOTA LEMBAH	B06	XE6221D	SATHISH	\N	Vessel Waste	\N	\N	0.80	0.00	0.50	0.00	0.08	0.30	1.68	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill	2026-07-24 15:15:51.944859+00	\N	\N	\N
17920	backfill	\N	2026-06-13	vessel	PSA Vessel	PIL_001	KOTA SETIA	B05	XE6221D	SATHISH	\N	Vessel Waste	\N	\N	1.20	0.00	0.30	0.02	0.00	0.40	1.92	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill	2026-07-24 15:15:51.944859+00	\N	\N	\N
17921	backfill	\N	2026-06-14	vessel	PSA Vessel	PIL_001	KOTA MACHAN	B06	XE6221D	SATHISH	\N	Vessel Waste	\N	\N	0.40	0.00	0.40	0.01	0.00	0.20	1.01	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill	2026-07-24 15:15:51.944859+00	\N	\N	\N
17925	backfill	\N	2026-06-18	vessel	PSA Vessel	PIL_001	KOTA RESTU	B06	XE5457Y	SATHISH	\N	Vessel Waste	\N	\N	0.50	0.02	0.40	0.00	0.00	0.30	1.22	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill	2026-07-24 15:15:51.944859+00	\N	\N	\N
17927	backfill	\N	2026-06-20	vessel	PSA Vessel	PIL_001	KOTA JAYA	B05	XE5457Y	SATHISH	\N	Vessel Waste	\N	\N	0.50	0.00	0.50	0.02	0.00	0.40	1.42	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill	2026-07-24 15:15:51.944859+00	\N	\N	\N
17930	backfill	\N	2026-06-22	vessel	PSA Vessel	PIL_001	KOTA HAKIM	B06	XE6221D	SATHISH	\N	Vessel Waste	\N	\N	0.00	0.00	0.20	0.00	0.10	0.70	1.00	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill; Total blank on DO (computed); Cat E incinerator ashes | Total blank on DO (computed); Cat E incinerator ashes	2026-07-24 15:15:51.944859+00	\N	\N	\N
17932	backfill	\N	2026-06-23	vessel	PSA Vessel	PIL_001	SELATAN DAMAI	B05	XE6221D	SATHISH	\N	Vessel Waste	\N	\N	0.60	0.02	0.20	0.02	0.00	0.40	1.24	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill	2026-07-24 15:15:51.944859+00	\N	\N	\N
17933	backfill	\N	2026-06-24	vessel	PSA Vessel	PIL_001	KOTA DUNIA	B05	XE6221D	SATHISH	\N	Vessel Waste	\N	\N	1.00	0.04	0.30	0.00	0.00	0.10	1.44	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill	2026-07-24 15:15:51.944859+00	\N	\N	\N
17934	backfill	\N	2026-06-24	vessel	PSA Vessel	PIL_001	KOTA NALURI	B06	XE6221D	SATHISH	\N	Vessel Waste	\N	\N	0.80	0.00	0.40	0.02	0.01	0.50	1.73	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill	2026-07-24 15:15:51.944859+00	\N	\N	\N
17935	backfill	\N	2026-06-25	vessel	PSA Vessel	PIL_001	KOTA EBONY	B05	XE6221D	SATHISH	\N	Vessel Waste	\N	\N	0.50	0.04	0.50	0.02	0.08	0.60	1.74	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill	2026-07-24 15:15:51.944859+00	\N	\N	\N
17936	backfill	\N	2026-06-26	vessel	PSA Vessel	PIL_001	KOTA CARUM	B05	XE6221D	SATHISH	\N	Vessel Waste	\N	\N	1.20	0.00	0.60	0.01	0.03	0.30	2.14	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill	2026-07-24 15:15:51.944859+00	\N	\N	\N
17938	backfill	\N	2026-06-28	vessel	PSA Vessel	PIL_001	KOTA SALAM	B05	XE6221D	SATHISH	\N	Vessel Waste	\N	\N	0.80	0.04	0.40	0.02	0.04	0.80	2.10	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill	2026-07-24 15:15:51.944859+00	\N	\N	\N
APP-T51	live	\N	2026-07-30	land	Exchange	SAVI_003	\N	\N	XE7126P	YAO_JUN	Exchange	General Waste	\N	5151	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	app_trip_id=51 | bin_photos=https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms6ylj60-BININ-95-1.jpg\nhttps://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms6yljh2-BINOUT-95-1.jpg | bin_in_raw=L29 | job_no=95	2026-07-30 03:33:44.788+00	\N	\N	\N
18622	backfill	\N	2026-04-28	vessel	PSA Vessel	PIL_001	KOTA DUNIA	B07	XE6221D	KARTHIK	\N	Vessel Waste	\N	\N	1.00	0.06	0.60	0.00	0.00	0.10	1.76	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill	2026-07-24 15:15:51.944859+00	\N	\N	\N
18624	backfill	\N	2026-05-07	vessel	PSA Vessel	PIL_001	KOTA MACHAN	B07	XE5457Y	KARTHIK	\N	Vessel Waste	\N	\N	0.40	0.00	0.40	0.01	0.00	0.20	1.01	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill	2026-07-24 15:15:51.944859+00	\N	\N	\N
18627	backfill	\N	2026-05-14	vessel	PSA Vessel	PIL_001	KOTA NEBULA	B08	XE5457Y	KARTHIK	\N	Vessel Waste	\N	\N	0.60	0.00	0.60	0.00	0.00	0.30	1.50	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill	2026-07-24 15:15:51.944859+00	\N	\N	\N
18629	backfill	\N	2026-05-18	vessel	PSA Vessel	PIL_001	KOTA GADANG	B05	XE5457Y	KARTHIK	\N	Vessel Waste	\N	\N	0.30	0.00	0.30	0.00	0.00	0.10	0.70	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill	2026-07-24 15:15:51.944859+00	\N	\N	\N
18630	backfill	\N	2026-05-19	vessel	PSA Vessel	PIL_001	KOTA NALURI	B05	XE5457Y	KARTHIK	\N	Vessel Waste	\N	\N	1.20	0.00	0.70	0.03	0.03	0.60	2.56	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill	2026-07-24 15:15:51.944859+00	\N	\N	\N
18039	backfill	\N	2026-05-10	vessel	PSA Vessel	PIL_001	KOTA GANDING	B08	XE7126P	YAO_JUN	\N	Vessel Waste	\N	\N	0.40	0.02	0.30	0.00	0.00	0.30	1.02	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill	2026-07-24 15:15:51.944859+00	\N	\N	\N
18631	backfill	\N	2026-05-20	vessel	PSA Vessel	PIL_001	KOTA NEKAD	B06	XE5457Y	KARTHIK	\N	Vessel Waste	\N	\N	0.70	0.00	0.60	0.02	0.00	0.50	1.82	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill; Oily rags 0.2 m3 | Oily rags 0.2 m3	2026-07-24 15:15:51.944859+00	\N	\N	\N
18634	backfill	\N	2026-05-27	vessel	PSA Vessel	PIL_001	KOTA LARIS	B06	XE5457Y	KARTHIK	\N	Vessel Waste	\N	\N	1.20	0.00	0.80	0.02	0.01	0.50	2.53	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill; Incl 0.2 m3 oily rags | Incl 0.2 m3 oily rags	2026-07-24 15:15:51.944859+00	\N	\N	\N
18751	backfill	\N	2026-05-28	vessel	PSA Vessel	PIL_001	KOTA RAJIN	B05	XE7126P	YAO_JUN	\N	Vessel Waste	\N	\N	0.30	0.04	0.30	0.02	0.00	0.30	0.98	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill; Cat I E-waste 0.02 m3; plate verify | Cat I E-waste 0.02 m3; plate verify	2026-07-24 15:15:51.944859+00	\N	\N	\N
18752	backfill	\N	2026-05-29	vessel	PSA Vessel	PIL_001	KOTA RANCAK	B06	XE7126P	YAO_JUN	\N	Vessel Waste	\N	\N	0.40	0.00	0.60	0.02	0.00	0.20	1.22	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill; plate verify | plate verify	2026-07-24 15:15:51.944859+00	\N	\N	\N
18755	backfill	\N	2026-05-31	vessel	PSA Vessel	PIL_001	KOTA LAWA	B05	XE7126P	YAO_JUN	\N	Vessel Waste	\N	\N	1.10	0.00	1.10	0.02	0.00	1.10	3.32	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill; plate verify | plate verify	2026-07-24 15:15:51.944859+00	\N	\N	\N
18757	backfill	\N	2026-06-01	vessel	PSA Vessel	PIL_001	KOTA RESTU	B06	XE7126P	YAO_JUN	\N	Vessel Waste	\N	\N	0.50	0.03	0.40	0.02	0.00	0.40	1.35	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill; plate verify | plate verify	2026-07-24 15:15:51.944859+00	\N	\N	\N
18758	backfill	\N	2026-06-02	vessel	PSA Vessel	PIL_001	KOTA CEPAT	B06	XE7126P	YAO_JUN	\N	Vessel Waste	\N	\N	0.50	0.00	0.40	0.02	0.00	0.40	1.32	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill; Faded scan — verify; 0.25 m3 solid sludge | Faded scan — verify; 0.25 m3 solid sludge	2026-07-24 15:15:51.944859+00	\N	\N	\N
18760	backfill	\N	2026-06-03	vessel	PSA Vessel	PIL_001	KOTA LARIS	B05	XE7126P	YAO_JUN	\N	Vessel Waste	\N	\N	0.30	0.00	0.30	0.00	0.00	0.10	0.70	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill; 0.05 m3 oily rags; plate verify | 0.05 m3 oily rags; plate verify	2026-07-24 15:15:51.944859+00	\N	\N	\N
18762	backfill	\N	2026-06-05	vessel	PSA Vessel	PIL_001	KOTA JOHAN	B05	XE7126P	YAO_JUN	\N	Vessel Waste	\N	\N	0.50	0.02	0.60	0.02	0.00	0.62	1.80	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill; Cat I 0.04 m3 | Cat I 0.04 m3	2026-07-24 15:15:51.944859+00	\N	\N	\N
18763	backfill	\N	2026-06-06	vessel	PSA Vessel	PIL_001	KOTA NAGA	B05	XE7126P	YAO_JUN	\N	Vessel Waste	\N	\N	0.45	0.03	0.95	0.00	0.00	0.40	1.83	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill	2026-07-24 15:15:51.944859+00	\N	\N	\N
18767	backfill	\N	2026-06-09	vessel	PSA Vessel	PIL_001	KOTA CEMPAKA	B07	XE7126P	YAO_JUN	\N	Vessel Waste	\N	\N	0.70	0.03	0.50	0.01	0.00	0.20	1.44	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill	2026-07-24 15:15:51.944859+00	\N	\N	\N
18771	backfill	\N	2026-06-11	vessel	PSA Vessel	PIL_001	KOTA NABIL	B07	XE7126P	YAO_JUN	\N	Vessel Waste	\N	\N	0.80	0.00	0.30	0.00	0.03	0.40	1.53	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill	2026-07-24 15:15:51.944859+00	\N	\N	\N
18772	backfill	\N	2026-06-11	vessel	PSA Vessel	PIL_001	KOTA LOCENG	B06	XE7126P	YAO_JUN	\N	Vessel Waste	\N	\N	1.50	0.03	1.10	0.02	0.01	0.50	3.16	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill; Cat A 1.1/1.5 unclear | Cat A 1.1/1.5 unclear	2026-07-24 15:15:51.944859+00	\N	\N	\N
18779	backfill	\N	2026-06-17	vessel	PSA Vessel	PIL_001	KOTA GANDING	B06	XE7126P	YAO_JUN	\N	Vessel Waste	\N	\N	0.40	0.02	0.30	0.00	0.00	0.30	1.02	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill	2026-07-24 15:15:51.944859+00	\N	\N	\N
18782	backfill	\N	2026-06-18	vessel	PSA Vessel	PIL_001	KOTA MAKMUR	B07	XE7126P	YAO_JUN	\N	Vessel Waste	\N	\N	0.60	0.00	0.60	0.02	0.00	0.60	1.82	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill	2026-07-24 15:15:51.944859+00	\N	\N	\N
18783	backfill	\N	2026-06-22	vessel	PSA Vessel	PIL_001	SALERNO EXPRESS	B07	XE7126P	YAO_JUN	\N	Vessel Waste	\N	\N	0.40	0.00	0.40	0.00	0.00	0.50	1.30	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill	2026-07-24 15:15:51.944859+00	\N	\N	\N
18785	backfill	\N	2026-06-22	vessel	PSA Vessel	PIL_001	KOTA DUTA	B05	XE7126P	YAO_JUN	\N	Vessel Waste	\N	\N	0.90	0.00	0.40	0.01	0.02	0.70	2.03	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill; Incl 0.5 m3 oily rags | Incl 0.5 m3 oily rags	2026-07-24 15:15:51.944859+00	\N	\N	\N
18790	backfill	\N	2026-06-26	vessel	PSA Vessel	PIL_001	KOTA SAHABAT	B06	XE7126P	YAO_JUN	\N	Vessel Waste	\N	\N	0.50	0.04	0.50	0.02	0.00	0.50	1.56	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill	2026-07-24 15:15:51.944859+00	\N	\N	\N
23637	backfill	\N	2026-06-09	standard	\N	SAV_001	\N	\N	XE6221D	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	reocr 24Jul2026 from SAVILLS BLUE HUB (1) (1).pdf | bin_in_raw=L51 | bin_out_raw=L29 | location=Bay-109 | job=exchange	2026-07-24 15:45:07.605862+00	\N	\N	\N
24200	backfill	\N	2026-06-09	standard	\N	SAV_001	\N	\N	\N	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	reocr 24Jul2026 from SAVILLS BLUE HUB (1) (1).pdf | bin_in_raw=5196? | bin_out_raw=L48 | location=L6 | date digit unclear (read 09/06/26) - verify	2026-07-24 15:45:07.605862+00	\N	\N	\N
25860	backfill	\N	2026-06-13	standard	\N	SAV_001	\N	\N	XE4491D	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	reocr 24Jul2026 from SAVILLS BLUE HUB (1) (1).pdf | bin_in_raw=5057? | bin_out_raw=5092? | location=Level-6-609 | job=exchange | bin digits unclear	2026-07-24 15:45:07.605862+00	\N	\N	\N
23748	backfill	\N	2026-06-15	standard	\N	SAV_001	\N	\N	\N	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	reocr 24Jul2026 from SAVILLS BLUE HUB (1) (1).pdf | bin_in_raw=5147? | bin_out_raw=L29 | location=L3 | bin_in unclear	2026-07-24 15:45:07.605862+00	\N	\N	\N
24120	backfill	\N	2026-06-18	standard	\N	SAV_001	\N	\N	\N	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	reocr 24Jul2026 from SAVILLS BLUE HUB (1) (1).pdf | bin_in_raw=5108? | bin_out_raw=5197? | location=L4 | bin digits unclear	2026-07-24 15:45:07.605862+00	\N	\N	\N
24121	backfill	\N	2026-06-18	standard	\N	SAV_001	\N	\N	\N	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	reocr 24Jul2026 from SAVILLS BLUE HUB (1) (1).pdf | bin_in_raw=5197? | bin_out_raw=5055? | location=L6 | bin digits unclear	2026-07-24 15:45:07.605862+00	\N	\N	\N
23902	backfill	\N	2026-06-20	standard	\N	SAV_001	\N	\N	XE5457Y	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	reocr 24Jul2026 from SAVILLS BLUE HUB (1) (1).pdf | bin_in_raw=5032 | bin_out_raw=L51 | location=Bay-109 | job=exchange	2026-07-24 15:45:07.605862+00	\N	\N	\N
23528	backfill	\N	2026-06-22	standard	\N	SAV_001	\N	\N	\N	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	reocr 24Jul2026 from SAVILLS BLUE HUB (1) (1).pdf | bin_in_raw=L31? | bin_out_raw=5147? | location=L3 | bin_in unclear	2026-07-24 15:45:07.605862+00	\N	\N	\N
23905	backfill	\N	2026-06-22	standard	\N	SAV_001	\N	\N	XE6221D	\N	\N	General Waste	5213	5197	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	reocr 24Jul2026 from SAVILLS BLUE HUB (1) (1).pdf | bin_in_raw=5213 | bin_out_raw=5197 | location=Level-6 | job=exchange	2026-07-24 15:45:07.605862+00	\N	\N	\N
24301	backfill	\N	2026-06-24	standard	\N	SAV_001	\N	\N	\N	\N	\N	General Waste	\N	5213	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	reocr 24Jul2026 from SAVILLS BLUE HUB (1) (1).pdf | bin_in_raw=5054? | bin_out_raw=5213 | location=L6 | bin_in unclear	2026-07-24 15:45:07.605862+00	\N	\N	\N
24451	backfill	\N	2026-06-29	standard	\N	SAV_001	\N	\N	XE4491D	\N	\N	General Waste	5222	5108	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	reocr 24Jul2026 from SAVILLS BLUE HUB (1) (1).pdf | bin_in_raw=5222 | bin_out_raw=5108 | job=exchange	2026-07-24 15:45:07.605862+00	\N	\N	\N
26062	live	\N	2026-07-30	land	Exchange	SAVI_001	\N	\N	XE7126P	YAO_JUN	Exchange	General Waste	\N	5151	\N	\N	\N	\N	\N	\N	\N	15010.0	14320.0	690.0	LR44	\N	weighbridge	\N	\N	\N	\N	https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms6ymuzj-DO-95-1.jpg	\N	\N	\N	\N	\N	app_trip_id=51 | bin_photos=https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms6ylj60-BININ-95-1.jpg\nhttps://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms6yljh2-BINOUT-95-1.jpg | bin_in_raw=L29 | job_no=95	2026-07-30 03:55:27.227+00	\N	\N	\N
26063	live	\N	2026-07-30	land	Exchange	FAX_001	\N	\N	XE7126P	YAO_JUN	Exchange	Wood Waste	5151	5089	\N	\N	\N	\N	\N	\N	\N	18200.0	14050.0	4150.0	LR45	\N	weighbridge	\N	\N	\N	\N	https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms709mp2-DO-96-1.jpg	\N	\N	\N	\N	\N	app_trip_id=52 | bin_photos=https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms7022jl-BININ-96-1.jpg\nhttps://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms7022tw-BINOUT-96-1.jpg | job_no=96	2026-07-30 04:53:27.475+00	\N	\N	\N
APP-T31	live	\N	2026-07-27	land	Exchange	STX_001	\N	\N	XE7126P	YAO_JUN	Exchange	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	20760.0	15750.0	5010.0	LR19	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	app_trip_id=31 | bin_photos=https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms31ynjl-BININ-52-1.jpg\nhttps://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms31ynw7-BINOUT-52-1.jpg | bin_in_raw=8000 | bin_out_raw=8000 | job_no=52	2026-07-27 09:57:10.165+00	\N	\N	\N
26200	live	\N	2026-07-27	land	Exchange	SAVI_001	\N	\N	XE7126P	YAO_JUN	Exchange	General Waste	5196	\N	\N	\N	\N	\N	\N	\N	\N	14830.0	14120.0	710.0	LR20	\N	weighbridge	\N	\N	\N	\N	https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms33hlzc-DO-53-1.jpg	\N	\N	\N	\N	\N	app_trip_id=32 | bin_photos=https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms33hlne-BININ-53-1.jpg\nhttps://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms33hlvi-BINOUT-53-1.jpg | bin_out_raw=L26 | job_no=53	2026-07-27 11:04:35.36+00	\N	\N	\N
APP-T33	live	\N	2026-07-28	land	Dump	BEE_001	\N	\N	\N	YAO_JUN	Dump	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	17310.0	14150.0	3160.0	LR21	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	app_trip_id=33 | bin_photos=https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms3z2m8u-BIN-68-1.jpg | job_no=68	2026-07-28 01:39:57.301+00	\N	\N	\N
26052	live	\N	2026-07-28	land	Exchange	RAD_001	\N	\N	XE7126P	YAO_JUN	Exchange	Wood Waste	\N	7017	\N	\N	\N	\N	\N	\N	\N	17820.0	15150.0	2670.0	LR22	\N	weighbridge	\N	\N	\N	\N	https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms433tej-DO-70-1.jpg	\N	\N	\N	\N	\N	app_trip_id=34 | bin_photos=https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms433t2h-BININ-70-1.jpg\nhttps://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms433tap-BINOUT-70-1.jpg | bin_in_raw=R11 | job_no=70	2026-07-28 03:52:47.735+00	\N	\N	\N
26053	live	\N	2026-07-28	land	Exchange	RAD_001	\N	\N	XE7126P	YAO_JUN	Exchange	Wood Waste	7017	7006	\N	\N	\N	\N	\N	\N	\N	16980.0	14520.0	2460.0	LR23	\N	weighbridge	\N	\N	\N	\N	https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms451p83-DO-69-1.jpg	\N	\N	\N	\N	\N	app_trip_id=35 | bin_photos=https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms451ots-BININ-69-1.jpg\nhttps://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms451p23-BINOUT-69-1.jpg | job_no=69	2026-07-28 04:41:10.933+00	\N	\N	\N
APP-T36	live	\N	2026-07-29	land	Exchange	EVE_001	\N	\N	XE7126P	YAO_JUN	Exchange	General Waste	5047	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	app_trip_id=36 | bin_photos=https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5atplk-BININ-71-1.jpg\nhttps://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5atpuq-BINOUT-71-1.jpg | bin_out_raw=L57 | job_no=71	2026-07-28 23:40:29.416+00	\N	\N	\N
26057	live	\N	2026-07-29	land	Exchange	EVE_001	\N	\N	XE7126P	YAO_JUN	Exchange	General Waste	5047	\N	\N	\N	\N	\N	\N	\N	\N	16840.0	14450.0	2390.0	LR24	\N	weighbridge	\N	\N	\N	\N	https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5b71vv-DO-71-1.jpg	\N	\N	\N	\N	\N	app_trip_id=36 | bin_photos=https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5atplk-BININ-71-1.jpg\nhttps://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5atpuq-BINOUT-71-1.jpg | bin_out_raw=L57 | job_no=71	2026-07-28 23:58:34.371+00	\N	\N	\N
23306	backfill	\N	2026-05-18	land	Exchange	PAX_001	\N	\N	XE8496P	\N	\N	General Waste	\N	5047	\N	\N	\N	\N	\N	\N	\N	14710.0	21870.0	7130.0	1042	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by AMIR-K12898	2026-07-24 15:15:51.944859+00	\N	\N	\N
23307	backfill	\N	2026-05-18	land	Exchange	PAX_001	\N	\N	XE8496P	\N	\N	General Waste	\N	5194	\N	\N	\N	\N	\N	\N	\N	14850.0	17380.0	2530.0	1045	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by AMIR-K12898; Bin In unclear — verify | Bin In unclear — verify	2026-07-24 15:15:51.944859+00	\N	\N	\N
23310	backfill	\N	2026-05-18	land	Exchange	PAX_001	\N	\N	XE8496P	\N	\N	General Waste	5108	\N	\N	\N	\N	\N	\N	\N	\N	14240.0	17650.0	3410.0	1052	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by AMIR-K12898	2026-07-24 15:15:51.944859+00	\N	\N	\N
23312	backfill	\N	2026-05-19	land	Exchange	PAX_001	\N	\N	XE8496P	\N	\N	General Waste	5096	5108	\N	\N	\N	\N	\N	\N	\N	14710.0	17010.0	2300.0	1055	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by LOH MG-K001775	2026-07-24 15:15:51.944859+00	\N	\N	\N
APP-T26	live	\N	2026-07-27	land	Delivery	SYS_001	\N	\N	XE7126P	YAO_JUN	Delivery	General Waste	5092	\N	\N	\N	\N	\N	\N	\N	\N	3.0	2.0	1.0	LR38	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	app_trip_id=26 | bin_photos=https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms2uzua3-BININ-47-1.jpg | job_no=47	2026-07-29 23:51:24.044+00	\N	\N	\N
130359	live	\N	2026-07-27	land	Exchange	HCG_001	\N	\N	XE7126P	YAO_JUN	Exchange	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	3.0	2.0	1.0	LR39	\N	weighbridge	\N	\N	\N	\N	https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms31xbw7-DO-51-1.jpg	\N	\N	\N	\N	\N	app_trip_id=30 | bin_photos=https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms31xbl4-BININ-51-1.jpg\nhttps://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms31xbql-BINOUT-51-1.jpg | bin_in_raw=5132 | bin_out_raw=5070 | job_no=51	2026-07-29 23:51:30.955+00	\N	\N	\N
23321	backfill	\N	2026-05-20	land	Exchange	PAX_001	\N	\N	XE8496P	\N	\N	General Waste	5046	5047	\N	\N	\N	\N	\N	\N	\N	14760.0	18580.0	3820.0	1081	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by AMIR-K12898; Bin Out unclear — verify | Bin Out unclear — verify	2026-07-24 15:15:51.944859+00	\N	\N	\N
23318	backfill	\N	2026-05-20	land	Exchange	PAX_001	\N	\N	XE8496P	\N	\N	General Waste	\N	5096	\N	\N	\N	\N	\N	\N	\N	11610.0	16690.0	5070.0	1070	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by MURU-K001956	2026-07-24 15:15:51.944859+00	\N	\N	\N
23323	backfill	\N	2026-05-21	land	Exchange	PAX_001	\N	\N	XE8496P	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	14430.0	16620.0	2190.0	1087	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by MUSTAFA; Bin In unclear — verify | Bin In unclear — verify	2026-07-24 15:15:51.944859+00	\N	\N	\N
23328	backfill	\N	2026-05-21	land	Exchange	PAX_001	\N	\N	XE8496P	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	14290.0	18110.0	3820.0	1089	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	bin_out_raw=5040 | bin_in_raw=735 | remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by AMIR-K12898; Bin In/Out unclear — verify | Bin In/Out unclear — verify	2026-07-24 15:15:51.944859+00	\N	\N	\N
23329	backfill	\N	2026-05-22	land	Exchange	PAX_001	\N	\N	XE8496P	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	14250.0	18470.0	4220.0	1091	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by AMIR-K12898; Bin Out unclear — verify | Bin Out unclear — verify	2026-07-24 15:15:51.944859+00	\N	\N	\N
23330	backfill	\N	2026-05-22	land	Exchange	PAX_001	\N	\N	XE8496P	\N	\N	General Waste	5060	5135	\N	\N	\N	\N	\N	\N	\N	14750.0	17380.0	2630.0	1104	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by AMIR-K12898	2026-07-24 15:15:51.944859+00	\N	\N	\N
23305	backfill	\N	2026-05-23	land	Exchange	PAX_001	\N	\N	XE8496P	\N	\N	General Waste	\N	5060	\N	\N	\N	\N	\N	\N	\N	14170.0	17990.0	3820.0	1101	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by BALA-K009902	2026-07-24 15:15:51.944859+00	\N	\N	\N
23334	backfill	\N	2026-05-23	land	Exchange	PAX_001	\N	\N	XE8496P	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	15030.0	16240.0	1240.0	1107	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by AMIR-K12898; Bin In unclear — verify | Bin In unclear — verify	2026-07-24 15:15:51.944859+00	\N	\N	\N
18040	backfill	\N	2026-05-10	vessel	PSA Vessel	PIL_001	KOTA SELAMAT	B06	XE7126P	YAO_JUN	\N	Vessel Waste	\N	\N	0.60	0.00	0.50	0.01	0.00	0.30	1.41	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill; Oily rags in bags 0.25 m3 | Oily rags in bags 0.25 m3	2026-07-24 15:15:51.944859+00	\N	\N	\N
18044	backfill	\N	2026-05-16	vessel	PSA Vessel	PIL_001	KOTA PAHLAWAN	B05	XE7126P	YAO_JUN	\N	Vessel Waste	\N	\N	1.20	0.00	0.60	0.04	0.14	0.40	2.38	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill	2026-07-24 15:15:51.944859+00	\N	\N	\N
18047	backfill	\N	2026-05-25	vessel	PSA Vessel	PIL_001	KOTA MAKMUR	B06	XE7126P	YAO_JUN	\N	Vessel Waste	\N	\N	0.80	0.00	0.60	0.02	0.00	0.80	2.22	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill; Oily rags 0.2 m3 | Oily rags 0.2 m3	2026-07-24 15:15:51.944859+00	\N	\N	\N
18049	backfill	\N	2026-05-26	vessel	PSA Vessel	PIL_001	KOTA SABAS	B05	XE7126P	YAO_JUN	\N	Vessel Waste	\N	\N	0.50	0.02	0.60	0.02	0.01	0.40	1.55	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill	2026-07-24 15:15:51.944859+00	\N	\N	\N
18050	backfill	\N	2026-05-27	vessel	PSA Vessel	PIL_001	KOTA SELAMAT	B06	XE7126P	YAO_JUN	\N	Vessel Waste	\N	\N	0.60	0.00	0.40	0.01	0.00	0.20	1.21	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill	2026-07-24 15:15:51.944859+00	\N	\N	\N
43184	live	\N	2026-07-29	land	Exchange	STX_001	\N	\N	XE7126P	YAO_JUN	Exchange	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	16870.0	14050.0	2820.0	LR25	\N	weighbridge	\N	\N	\N	\N	https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5soxqm-DO-72-1.jpg	\N	\N	\N	\N	\N	app_trip_id=37 | bin_photos=https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5soxc5-BININ-72-1.jpg\nhttps://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5soxml-BINOUT-72-1.jpg | bin_in_raw=6006 | bin_out_raw=6006 | job_no=72	2026-07-29 08:00:54.54+00	\N	\N	\N
43183	live	\N	2026-07-29	land	Exchange	STX_001	\N	\N	XE7126P	YAO_JUN	Exchange	Wood Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	17620.0	15830.0	1790.0	LR26	\N	weighbridge	\N	\N	\N	\N	https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5sqrw2-DO-73-1.jpg	\N	\N	\N	\N	\N	app_trip_id=38 | bin_photos=https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5sqrla-BININ-73-1.jpg\nhttps://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5sqrrd-BINOUT-73-1.jpg | bin_in_raw=8000 | bin_out_raw=8000 | job_no=73	2026-07-29 08:02:19.61+00	\N	\N	\N
43186	live	\N	2026-07-29	land	Exchange	STX_001	\N	\N	XE7126P	YAO_JUN	Exchange	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	16580.0	13950.0	2630.0	LR27	\N	weighbridge	\N	\N	\N	\N	https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5ss9vo-DO-74-1.jpg	\N	\N	\N	\N	\N	app_trip_id=39 | bin_photos=https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5ss9ma-BININ-74-1.jpg\nhttps://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5ss9rk-BINOUT-74-1.jpg | bin_in_raw=6005 | bin_out_raw=6005 | job_no=74	2026-07-29 08:03:29.649+00	\N	\N	\N
APP-T41	live	\N	2026-07-29	land	Exchange	NEA_001	\N	\N	XE7126P	YAO_JUN	Exchange	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	23250.0	15860.0	7390.0	LR29	\N	weighbridge	\N	\N	\N	\N	https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5svumm-DO-76-1.jpg	\N	\N	\N	\N	\N	app_trip_id=41 | bin_photos=https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5svucu-BININ-76-1.jpg\nhttps://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5svuiu-BINOUT-76-1.jpg | bin_in_raw=R13 | bin_out_raw=R13 | job_no=76	2026-07-29 08:06:28.103+00	\N	\N	\N
26058	live	\N	2026-07-29	land	Exchange	GSE_001	\N	\N	XE7126P	YAO_JUN	Exchange	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	15790.0	14050.0	1740.0	LR30	\N	weighbridge	\N	\N	\N	\N	https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5sy3bv-DO-77-1.jpg	\N	\N	\N	\N	\N	app_trip_id=42 | bin_photos=https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5sy324-BININ-77-1.jpg\nhttps://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5sy370-BINOUT-77-1.jpg | bin_in_raw=L804 | bin_out_raw=L808 | job_no=77	2026-07-29 08:07:59.392+00	\N	\N	\N
26060	live	\N	2026-07-29	land	Exchange	HYU_001	\N	\N	XE7126P	YAO_JUN	Exchange	General Waste	5079	5079	\N	\N	\N	\N	\N	\N	\N	18710.0	14150.0	4560.0	LR32	\N	weighbridge	\N	\N	\N	\N	https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5t6plv-DO-78-1.jpg	\N	\N	\N	\N	\N	app_trip_id=43 | bin_photos=https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5t6p8d-BININ-78-1.jpg\nhttps://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5t6pem-BINOUT-78-1.jpg | job_no=78	2026-07-29 10:50:10.018+00	\N	\N	\N
APP-T44	live	\N	2026-07-29	land	Exchange	NEA_001	\N	\N	XE7126P	YAO_JUN	Exchange	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	22490.0	15610.0	6880.0	LR31	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	app_trip_id=44 | bin_photos=https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5xviy1-BININ-79-1.jpg\nhttps://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5xvjmq-BINOUT-79-1.jpg | bin_in_raw=R02 | bin_out_raw=R02 | job_no=79	2026-07-29 10:26:06.274+00	\N	\N	\N
APP-T49	live	\N	2026-07-30	land	\N	ECO_001	\N	\N	XE8496P	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	0.0	0.0	0.0	\N	\N	weighbridge	\N	\N	\N	\N	https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms6vl45v-DO-94-1.jpg	https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms6vl4ed-SIG-94-1.jpg	\N	\N	\N	\N	app_trip_id=49 | bin_photos=https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms701kqr-BININ-94-1.jpg\nhttps://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms701lfz-BINOUT-94-1.jpg | bin_in_raw=R13 | bin_out_raw=R13 | job_no=94	2026-07-30 06:49:37.464+00	\N	\N	\N
26059	live	\N	2026-07-29	land	Exchange	INV_001	\N	\N	XE7126P	YAO_JUN	Exchange	General Waste	5079	\N	\N	\N	\N	\N	\N	\N	\N	16310.0	14100.0	2210.0	LR33	\N	weighbridge	\N	\N	\N	\N	https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5zmsyg-DO-80-1.jpg	\N	\N	\N	\N	\N	app_trip_id=45 | bin_photos=https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5zmslm-BININ-80-1.jpg\nhttps://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5zmstf-BINOUT-80-1.jpg | bin_out_raw=5224 | job_no=80	2026-07-29 12:41:31.337+00	\N	\N	\N
41767	live	\N	2026-07-15	land	Load	BCW_001	\N	\N	XE7126P	YAO_JUN	Load	Wood Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	3.0	2.0	1.0	LR34	\N	weighbridge	\N	\N	\N	\N	https://drive.google.com/uc?export=view&id=1FjqgXtP6_HEjulcsh5XRY624R0ZLCABz	\N	\N	\N	\N	\N	app_trip_id=12 | bin_photos=https://drive.google.com/uc?export=view&id=1PEcHHSrsgmdw_FYGmwz2SXf_YQIkItmt\nhttps://drive.google.com/uc?export=view&id=1rENbGVPDnU17thW_8d7IvoIsCzn7s8os | bin_in_raw=R13 | bin_out_raw=R13 | job_no=5	2026-07-29 23:50:53.287+00	\N	\N	\N
130352	live	\N	2026-07-15	land	Exchange	HCG_001	\N	\N	XE7126P	YAO_JUN	Exchange	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	3.0	2.0	1.0	LR35	\N	weighbridge	\N	\N	\N	\N	https://drive.google.com/uc?export=view&id=1Ep2VBalTd9LvuG-sgK2WQM-XndKvkaeF	\N	\N	\N	\N	\N	app_trip_id=14 | bin_photos=https://drive.google.com/uc?export=view&id=18ZwPbi7_6RWP8GelyM2jj_v9C7O9yyMf\nhttps://drive.google.com/uc?export=view&id=1_ujAtz5uxQsJBsui_YII3hBEoUSl5luo | bin_in_raw=5070号 | bin_out_raw=5193 | job_no=7	2026-07-29 23:51:01.527+00	\N	\N	\N
LR26/02/0112	backfill	\N	2026-02-28	\N	\N	STE_001	\N	\N	\N	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	106080.0	\N	\N	invoice	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE monthly aggregate; 23 trips; PO 3020388477; inv $11,186.19	2026-07-31 03:02:32.106388+00	\N	\N	\N
APP-T52	live	\N	2026-07-30	land	Exchange	FAX_001	\N	\N	XE7126P	YAO_JUN	Exchange	General Waste	5151	5089	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	app_trip_id=52 | bin_photos=https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms7022jl-BININ-96-1.jpg\nhttps://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms7022tw-BINOUT-96-1.jpg | job_no=96	2026-07-30 04:14:36.005+00	\N	\N	\N
13036	live	\N	2026-07-30	land	Exchange	HCG_001	\N	\N	XE7126P	YAO_JUN	Exchange	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	3.0	2.0	1.0	LR47	\N	weighbridge	\N	\N	\N	\N	https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms776qx7-DO-98-1.jpg	\N	\N	\N	\N	\N	app_trip_id=54 | bin_photos=https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms776qh3-BININ-98-1.jpg\nhttps://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms776qqi-BINOUT-98-1.jpg | bin_in_raw=5070 | bin_out_raw=5132 | job_no=98	2026-07-30 07:34:24.911+00	\N	\N	\N
LR26/02/0113	backfill	\N	2026-02-26	\N	\N	STE_001	\N	\N	\N	\N	\N	Used Tyre Fender	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	4950.0	\N	\N	invoice	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1 trip; PO 3020388477; inv $5,469.62	2026-07-31 03:02:32.106388+00	\N	\N	\N
LR26/02/0114	backfill	\N	2026-02-28	\N	\N	STE_002	\N	\N	\N	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	197800.0	\N	\N	invoice	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	49 trips; PO 3020388002; inv $21,311.24	2026-07-31 03:02:32.106388+00	\N	\N	\N
LR26/02/0115	backfill	\N	2026-02-28	\N	\N	STE_002	\N	\N	\N	\N	\N	Wood Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	36200.0	\N	\N	invoice	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	11 trips; PO 3020388002; inv $3,325.15	2026-07-31 03:02:32.106388+00	\N	\N	\N
LR26/03/0253	backfill	\N	2026-03-31	\N	\N	STE_001	\N	\N	\N	\N	\N	Concrete Stone	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	25490.0	\N	\N	invoice	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	site not stated on invoice (assumed Benoi - VERIFY); 1 trip; ref 3020392527; inv $2,767.73	2026-07-31 03:02:32.106388+00	\N	\N	\N
26061	live	\N	2026-07-30	land	Delivery	HYU_001	\N	\N	XE7126P	YAO_JUN	Delivery	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	21070.0	14050.0	7020.0	LR42	\N	weighbridge	\N	\N	\N	\N	https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms6u83mv-DO-93-1.jpg	\N	\N	\N	\N	\N	app_trip_id=48 | bin_photos=https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms6u83cm-BININ-93-1.jpg | bin_in_raw=L29 | job_no=93	2026-07-30 03:00:14.756+00	\N	\N	\N
LR26/03/0269	backfill	\N	2026-03-31	\N	\N	STE_001	\N	\N	\N	\N	\N	Wood Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	61480.0	\N	\N	invoice	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	21 trips; PO 3020391381; inv $5,824.13	2026-07-31 03:02:32.106388+00	\N	\N	\N
LR26/03/0270	backfill	\N	2026-03-31	\N	\N	STE_001	\N	\N	\N	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	154520.0	\N	\N	invoice	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	29 trips; PO 3020391381; inv $15,960.48	2026-07-31 03:02:32.106388+00	\N	\N	\N
LR26/03/0271	backfill	\N	2026-03-31	\N	\N	STE_002	\N	\N	\N	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	263750.0	\N	\N	invoice	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	66 trips; PO 3020390997; inv $28,465.90	2026-07-31 03:02:32.106388+00	\N	\N	\N
LR26/03/0272	backfill	\N	2026-03-31	\N	\N	STE_002	\N	\N	\N	\N	\N	Wood Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	85020.0	\N	\N	invoice	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	20 trips; PO 3020390997; inv $7,364.32	2026-07-31 03:02:32.106388+00	\N	\N	\N
LR26/03/0273	backfill	\N	2026-03-31	\N	\N	STE_002	\N	\N	\N	\N	\N	Used Tyre	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	invoice	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	11 pcs @ $3; 1 trip; PO 3020390997; inv $110.09	2026-07-31 03:02:32.106388+00	\N	\N	\N
LR26/03/0274	backfill	\N	2026-03-31	\N	\N	STE_002	\N	\N	\N	\N	\N	Used Rubber Fender	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	3570.0	\N	\N	invoice	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1 trip; PO 3020390997; inv $3,965.42	2026-07-31 03:02:32.106388+00	\N	\N	\N
LR26/04/0056	backfill	\N	2026-04-10	\N	\N	STE_003	\N	\N	\N	\N	\N	OTC Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	10290.0	\N	\N	invoice	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	3 trips; ref 3020391689; inv $1,266.56; evidence: DO & Ticket (CDPL Tuas).pdf	2026-07-31 03:02:32.106388+00	\N	\N	\N
LR26/04/0192	backfill	\N	2026-04-30	\N	\N	STE_001	\N	\N	\N	\N	\N	Wood Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	63020.0	\N	\N	invoice	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	21 trips; PO 3020394416; inv $5,929.88	2026-07-31 03:02:32.106388+00	\N	\N	\N
LR26/04/0193	backfill	\N	2026-04-30	\N	\N	STE_001	\N	\N	\N	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	160070.0	\N	\N	invoice	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	29 trips; PO 3020394416; inv $16,456.54	2026-07-31 03:02:32.106388+00	\N	\N	\N
25865	backfill	\N	2026-06-15	\N	\N	STE_004	\N	\N	\N	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	3990.0	\N	\N	invoice	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	DO#25865; IWMF Pkg 1; PO 3020397117; part of inv LR26/06/0010	2026-07-31 03:02:32.106388+00	\N	\N	\N
25887	backfill	\N	2026-06-19	\N	\N	STE_004	\N	\N	\N	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	4400.0	\N	\N	invoice	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	DO#25887; IWMF Pkg 1; PO 3020397117; part of inv LR26/06/0010	2026-07-31 03:02:32.106388+00	\N	\N	\N
23853	backfill	\N	2026-06-22	\N	\N	STE_004	\N	\N	\N	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	3710.0	\N	\N	invoice	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	DO#23853; IWMF Pkg 1; PO 3020397117; part of inv LR26/06/0010	2026-07-31 03:02:32.106388+00	\N	\N	\N
24307	backfill	\N	2026-06-26	\N	\N	STE_004	\N	\N	\N	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	3800.0	\N	\N	invoice	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	DO#24307; IWMF Pkg 1; PO 3020397117; inv LR26/06/0010 total $2,336.96 covers all 5 DOs (22.00 t)	2026-07-31 03:02:32.106388+00	\N	\N	\N
LR26/06/0336	backfill	\N	2026-06-30	\N	\N	STE_002	\N	\N	\N	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	277380.0	\N	\N	invoice	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	70 trips; PO 3020399503; inv $29,980.62	2026-07-31 03:02:32.106388+00	\N	\N	\N
LR26/06/0337	backfill	\N	2026-06-30	\N	\N	STE_002	\N	\N	\N	\N	\N	Wood Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	50110.0	\N	\N	invoice	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	15 trips; PO 3020399503; inv $4,585.55	2026-07-31 03:02:32.106388+00	\N	\N	\N
LR26/06/0338	backfill	\N	2026-06-30	\N	\N	STE_002	\N	\N	\N	\N	\N	Rubber Fender	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	6170.0	\N	\N	invoice	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1 trip; PO 3020399503; inv $6,799.42	2026-07-31 03:02:32.106388+00	\N	\N	\N
LR26/06/0339	backfill	\N	2026-06-30	\N	\N	STE_001	\N	\N	\N	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	168080.0	\N	\N	invoice	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	32 trips; PO 3020400459; inv $17,394.83	2026-07-31 03:02:32.106388+00	\N	\N	\N
LR26/06/0340	backfill	\N	2026-06-30	\N	\N	STE_001	\N	\N	\N	\N	\N	Wood Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	71840.0	\N	\N	invoice	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	23 trips; PO 3020400459; inv $6,688.15	2026-07-31 03:02:32.106388+00	\N	\N	\N
LR26/06/0341	backfill	\N	2026-06-30	\N	\N	STE_001	\N	\N	\N	\N	\N	Concrete Stone	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	55570.0	\N	\N	invoice	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	7 trips; ref 3020400856; inv $8,660.70	2026-07-31 03:02:32.106388+00	\N	\N	\N
26066	live	\N	2026-07-31	land	\N	ECO_001	\N	\N	XE7126P	YAO_JUN	\N	Hardcore Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	3.0	2.0	1.0	LR51	\N	weighbridge	\N	\N	\N	\N	https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms8g1hlh-DO-114-1.jpg	https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms8g1hvv-SIG-114-1.jpg	\N	\N	\N	\N	app_trip_id=59 | bin_in_raw=3013 | job_no=114	2026-07-31 04:30:07.16+00	\N	\N	\N
26065	live	\N	2026-07-31	land	Load	HYU_001	\N	\N	XE7126P	YAO_JUN	Load	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	21760.0	14050.0	7710.0	LR50	\N	weighbridge	\N	\N	\N	\N	https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms8d759v-DO-112-1.jpg	https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms8d75e1-SIG-112-1.jpg	\N	\N	\N	\N	app_trip_id=57 | bin_photos=https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms8d74vt-BININ-112-1.jpg\nhttps://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms8d755c-BINOUT-112-1.jpg | bin_in_raw=L808 | bin_out_raw=L808 | job_no=112	2026-07-31 04:27:43.455+00	\N	\N	\N
43198	live	\N	2026-07-31	land	Exchange	\N	\N	\N	XE7126P	YAO_JUN	Exchange	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	21070.0	17090.0	3980.0	LR53	\N	weighbridge	\N	\N	\N	\N	https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms8owh95-DO-115-1.jpg	\N	\N	\N	\N	\N	app_trip_id=61 | bin_photos=https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms8owgjr-BININ-115-1.jpg\nhttps://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms8owh4y-BINOUT-115-1.jpg | bin_in_raw=COMPACTOR | bin_out_raw=COMPACTOR | job_no=115	2026-07-31 08:38:13.899+00	\N	\N	\N
26300	live	\N	2026-07-31	land	Exchange	POH_001	\N	\N	XE8496P	\N	Exchange	General Waste	5213	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms8dp4jq-DO-100-1.jpg	https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms8dp4o9-SIG-100-1.jpg	\N	\N	\N	\N	app_trip_id=58 | dispose_to=Lirich Resources Pte Ltd | bin_photos=https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms8dp492-BINOUT-100-1.jpg | bin_out_raw=L24 | job_no=100	2026-07-31 03:24:12.679+00	\N	\N	Lirich Resources Pte Ltd
APP-T62	live	\N	2026-07-31	land	Exchange	NEA_001	\N	\N	XE7126P	YAO_JUN	Exchange	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	21070.0	17090.0	3980.0	LR54	\N	weighbridge	\N	\N	\N	\N	https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms8ozotx-DO-116-1.jpg	\N	\N	\N	\N	\N	app_trip_id=62 | bin_photos=https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms8ozoku-BININ-116-1.jpg\nhttps://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms8ozop7-BINOUT-116-1.jpg | job_no=116	2026-07-31 08:40:36.249+00	\N	\N	\N
26064	live	\N	2026-07-31	land	Exchange	TOP_001	\N	\N	XE7126P	YAO_JUN	Exchange	General Waste	5056	\N	\N	\N	\N	\N	\N	\N	\N	17810.0	14100.0	3710.0	LR48	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	app_trip_id=55 | dispose_to=Lirich Resources Pte Ltd | bin_photos=https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms86dtbl-BININ-110-1.jpg\nhttps://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms86dtjw-BINOUT-110-1.jpg | bin_out_raw=L808 | job_no=110	2026-07-31 01:46:17.328+00	\N	\N	Lirich Resources Pte Ltd
APP-T56	live	\N	2026-07-31	land	Dump	BEE_001	\N	\N	\N	\N	Dump	Wood Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	0.0	0.0	0.0	\N	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	app_trip_id=56 | dispose_to=Bee Joo | bin_photos=https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms86y17q-BIN-99-1.jpg | job_no=99	2026-07-31 01:08:17.558+00	\N	\N	Bee Joo
APP-T60	live	\N	2026-07-31	land	Exchange	\N	\N	\N	XE7126P	YAO_JUN	Exchange	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	17500.0	13950.0	3550.0	LR52	\N	weighbridge	\N	\N	\N	\N	https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms8m6yuq-DO-111-1.jpg	\N	\N	\N	\N	\N	app_trip_id=60 | dispose_to=Lirich Resources Pte Ltd | bin_photos=https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms8m6yfg-BININ-111-1.jpg\nhttps://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms8m6yp2-BINOUT-111-1.jpg | bin_in_raw=6006 | bin_out_raw=6006 | job_no=111	2026-07-31 07:23:02.908+00	\N	\N	Lirich Resources Pte Ltd
STE-DS-21898	backfill	\N	2026-01-20	\N	\N	STE_001	\N	\N	XE5457Y	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	21310.0	14240.0	7070.0	LR20355	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 21898 | bins: BIN-5116 RB3-0414 RB3-0423 RB5-0804 | Driver Gnanakumar	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-21903	backfill	\N	2026-01-20	\N	\N	STE_001	\N	\N	XE5457Y	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	19950.0	14250.0	5700.0	LR20357	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 21903 | bins: BIN-L807 RB3-0401 RB5-8401 RB3-0417 | Chit bin 'L 807'	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-21904	backfill	\N	2026-01-20	\N	\N	STE_001	\N	\N	XE5457Y	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	20160.0	14250.0	5910.0	LR20358	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 21904 | bins: BIN-5114? RB3-0401 RB5-8401 RB3-0417 | ? DS handwritten bin reads 5114 but chit bin no = 5116 - possible DS mis-write	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-21905	backfill	\N	2026-01-21	\N	\N	STE_001	\N	\N	XE5457Y	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	19970.0	14240.0	5730.0	LR20373	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 21905 | bins: BIN-L807 RB3-0401 RB3-0417 RB5-8401	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-21909	backfill	\N	2026-01-22	\N	\N	STE_001	\N	\N	XE5457Y	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	18150.0	14240.0	3910.0	LR20374	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 21909 | bins: BIN-5116 RB3-0401 RB3-0471? RB5-8401 | ? second RB ref could be RB3-0417 (handwriting reads 0471)	2026-07-31 18:08:00.568866+00	\N	\N	\N
26197	live	\N	2026-07-27	land	Exchange	QUA_001	\N	\N	XE7126P	YAO_JUN	Exchange	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	16770.0	14200.0	2570.0	LR18	\N	weighbridge	\N	\N	\N	\N	https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms31u58y-DO-50-1.jpg	\N	\N	\N	\N	\N	app_trip_id=29 | dispose_to=Lirich Resources Pte Ltd | bin_photos=https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms31u4uy-BININ-50-1.jpg\nhttps://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms31u53y-BINOUT-50-1.jpg | bin_in_raw=L46 | bin_out_raw=L46 | job_no=50	2026-07-27 09:53:42.916+00	\N	\N	Lirich Resources Pte Ltd
26198	live	\N	2026-07-27	land	Exchange	ENGL_001	\N	\N	XE7126P	YAO_JUN	Exchange	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	16790.0	14100.0	2690.0	LR16	\N	weighbridge	\N	\N	\N	\N	https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms2v45mh-DO-48-1.jpg	\N	\N	\N	\N	\N	app_trip_id=27 | dispose_to=Lirich Resources Pte Ltd | bin_photos=https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms2v45as-BININ-48-1.jpg\nhttps://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms2v45hg-BINOUT-48-1.jpg | bin_in_raw=L26 | bin_out_raw=5098 | job_no=48	2026-07-27 06:45:26.407+00	\N	\N	Lirich Resources Pte Ltd
APP-T28	live	\N	2026-07-27	land	Exchange	ENGL_001	\N	\N	XE7126P	YAO_JUN	Exchange	General Waste	5198	\N	\N	\N	\N	\N	\N	\N	\N	17580.0	14100.0	3480.0	LR17	\N	weighbridge	\N	\N	\N	\N	https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms2xeqp9-DO-49-1.jpg	\N	\N	\N	\N	\N	app_trip_id=28 | dispose_to=Lirich Resources Pte Ltd | bin_photos=https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms2xeq8v-BININ-49-1.jpg\nhttps://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms2xeqky-BINOUT-49-1.jpg | bin_out_raw=L51 | job_no=49	2026-07-27 07:49:36.743+00	\N	\N	Lirich Resources Pte Ltd
APP-T40	live	\N	2026-07-29	land	Exchange	NEA_001	\N	\N	XE7126P	YAO_JUN	Exchange	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	22470.0	15860.0	6610.0	LR28	\N	weighbridge	\N	\N	\N	\N	https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5su85q-DO-75-1.jpg	\N	\N	\N	\N	\N	app_trip_id=40 | dispose_to=NEA | bin_photos=https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5su7xq-BININ-75-1.jpg\nhttps://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms5su81m-BINOUT-75-1.jpg | bin_in_raw=R13 | bin_out_raw=R13 | job_no=75	2026-07-29 08:05:09.046+00	\N	\N	NEA
APP-T46	live	\N	2026-07-30	land	Dump	BEE_001	\N	\N	\N	YAO_JUN	Dump	Wood Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	20470.0	15470.0	5000.0	LR43	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	app_trip_id=46 | dispose_to=Bee Joo | bin_photos=https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms6rc9rj-BIN-86-1.jpg | job_no=86	2026-07-30 03:52:22.656+00	\N	\N	Bee Joo
130354	live	\N	2026-07-16	land	Exchange	HCG_001	\N	\N	XE7126P	YAO_JUN	Exchange	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	3.0	2.0	1.0	LR36	\N	weighbridge	\N	\N	\N	\N	https://drive.google.com/uc?export=view&id=1u3CpdU1tSn2qsNIbCRvfqw4ser-eHTZe	\N	\N	\N	\N	\N	app_trip_id=19 | dispose_to=HCG Environmental Pte Ltd | bin_photos=https://drive.google.com/uc?export=view&id=1AGLyIHSUjlboegCEa3HWSyYsxX7hPiZJ\nhttps://drive.google.com/uc?export=view&id=14C5rcRXjWYFSWgdgu1mjR-d8Ar_0zXtg | bin_in_raw=5132 | bin_out_raw=5072 | job_no=20	2026-07-29 23:51:09.223+00	\N	\N	HCG Environmental Pte Ltd
130353	live	\N	2026-07-16	land	Exchange	HCG_001	\N	\N	XE7126P	YAO_JUN	Exchange	Wood Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	3.0	2.0	1.0	LR37	\N	weighbridge	\N	\N	\N	\N	https://drive.google.com/uc?export=view&id=1B-1uZfGzmgynG8FVhsGnZyZL1AZ24IPa	\N	\N	\N	\N	\N	app_trip_id=18 | dispose_to=HCG Environmental Pte Ltd | bin_photos=https://drive.google.com/uc?export=view&id=1ATztqAtb0SB81wvu9WFUVIhAYfyn7-Nt\nhttps://drive.google.com/uc?export=view&id=17lqHyCkKkt3gRNlwNvAPsLe7QrWmDxcn | bin_in_raw=5193 | bin_out_raw=5132 | job_no=21	2026-07-29 23:51:17.037+00	\N	\N	HCG Environmental Pte Ltd
APP-T55	live	\N	2026-07-31	land	Exchange	TOP_001	\N	\N	XE7126P	YAO_JUN	Exchange	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	app_trip_id=55 | dispose_to=Lirich Resources Pte Ltd | bin_photos=https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms86dtbl-BININ-110-1.jpg\nhttps://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms86dtjw-BINOUT-110-1.jpg | bin_in_raw=5 56 | bin_out_raw=L808 | job_no=110	2026-07-30 23:59:27.862+00	\N	\N	Lirich Resources Pte Ltd
43109	live	\N	2026-07-30	land	Exchange	STX_001	\N	\N	XE7126P	YAO_JUN	Exchange	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	17730.0	14100.0	3630.0	LR40	\N	weighbridge	\N	\N	\N	\N	https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms6wbvrq-DO-87-1.jpg	https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms6wbvv6-SIG-87-1.jpg	\N	\N	\N	\N	app_trip_id=50 | dispose_to=Lirich Resources Pte Ltd | bin_photos=https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms6wbvag-BININ-87-1.jpg\nhttps://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/ms6wbvjf-BINOUT-87-1.jpg | bin_in_raw=6006 | bin_out_raw=6006 | job_no=87	2026-07-30 02:49:33.259+00	\N	\N	Lirich Resources Pte Ltd
STE-DS-21855	backfill	\N	2026-01-02	\N	\N	STE_001	\N	\N	XE5457Y	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	20800.0	14300.0	6500.0	LR20251	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 21855 | bins: BIN-6002 RB5-0804 RB3-0414 RB3-0423 | Location J4; handwritten 20800 on DS matches chit gross	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-21859	backfill	\N	2026-01-06	\N	\N	STE_001	\N	\N	XE5457Y	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	21440.0	13900.0	7540.0	LR20283	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 21859 | bins: BIN-6002 RB5-0804 RB3-0414 RB3-0423 | DS dated 06/01 but chit time-out 07/01/2026 10:42; vehicle XE8496P struck out and replaced with XE5457Y on DS	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-21862	backfill	\N	2026-01-06	\N	\N	STE_001	\N	\N	XE5457Y	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	19900.0	14200.0	5700.0	LR20279	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 21862 | bins: BIN-6000 RB5-0804 RB3-0414 RB3-0423 | DS dated 06/01 but chit time-out 07/01/2026 10:27; handwritten '+1000' annotation on DS (purpose unclear)	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-21866	backfill	\N	2026-01-08	\N	\N	STE_001	\N	\N	XE5457Y	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	19080.0	14350.0	4730.0	LR20295	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 21866 | bins: BIN-6002 RB5-0804 RB3-0414 RB3-0423	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-21865	backfill	\N	2026-01-09	\N	\N	STE_001	\N	\N	XE5457Y	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	16740.0	14220.0	2520.0	LR20298	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 21865 | bins: BIN-6002 RB5-0804 RB3-0414 RB3-0423	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-21871	backfill	\N	2026-01-09	\N	\N	STE_001	\N	\N	XE5457Y	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	19050.0	14300.0	4750.0	LR20299	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 21871 | bins: BIN-6003 RB5-0804 RB3-0414 RB3-0423 | DS date digit ambiguous (07? or 09?); security stamp 09 JAN 2026 and chit 09/01/2026 22:23 so 09 used; chit bin 6003 matches DS	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-21876	backfill	\N	2026-01-12	\N	\N	STE_001	\N	\N	XE5457Y	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	19110.0	14240.0	4870.0	LR20396	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 21876 | bins: BIN-6003 RB3-0414 RB3-0423 RB5-0804 | Driver R. Karthik	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-21875	backfill	\N	2026-01-13	\N	\N	STE_001	\N	\N	XE5457Y	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	18900.0	14240.0	4660.0	LR20399	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 21875 | bins: BIN-6003 RB3-0401 RB5-8400 RB5-8401 | RB refs handwriting: RB5-8400/RB5-8401 slightly unclear	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-21878	backfill	\N	2026-01-13	\N	\N	STE_001	\N	\N	XE5457Y	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	18390.0	14240.0	4150.0	LR20398	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 21878 | bins: BIN-6002 RB3-0414 RB3-0423 RB5-0804	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-21882	backfill	\N	2026-01-15	\N	\N	STE_001	\N	\N	XE5457Y	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	17570.0	14250.0	3320.0	LR20402	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 21882 | bins: BIN-6003 RB3-0414 RB3-0423 RB5-0804	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-21889	backfill	\N	2026-01-16	\N	\N	STE_001	\N	\N	XE5457Y	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	18940.0	14240.0	4700.0	LR20403	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 21889 | bins: BIN-6002 RB3-0414 RB3-0423 RB5-0804	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-21891	backfill	\N	2026-01-16	\N	\N	STE_001	\N	\N	XE5457Y	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	16660.0	14240.0	2420.0	LR20405	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 21891 | bins: BIN-6000 RB3-0414 RB3-0423 RB5-0804	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-21911	backfill	\N	2026-01-23	\N	\N	STE_001	\N	\N	XE5457Y	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	18550.0	14240.0	4310.0	LR20407	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 21911 | bins: BIN-807 RB3-0401 RB3-0471? RB5-8401 | ? second RB ref could be RB3-0417; chit bin 807	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-21919	backfill	\N	2026-01-26	\N	\N	STE_001	\N	\N	XE5457Y	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	19960.0	14240.0	5720.0	LR20428	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 21919 | bins: BIN-6002 RB3-0401 RB3-0471? RB5-8401 | ? second RB ref could be RB3-0417; chit time 14:28	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-21923	backfill	\N	2026-01-26	\N	\N	STE_001	\N	\N	XE5457Y	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	20860.0	14210.0	6650.0	LR20426	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 21923 | bins: BIN-5116 RB5-0115 RB3-0417 RB5-8401 | Chit time 11:15 (earlier than DS 21919 same day); OUT 1108hrs noted on DS	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-21925	backfill	\N	2026-01-27	\N	\N	STE_001	\N	\N	XE5457Y	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	18810.0	14240.0	4570.0	LR20437	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 21925 | bins: BIN-6000 RB5-0115 RB3-0417 RB5-8401	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-21930	backfill	\N	2026-01-28	\N	\N	STE_001	\N	\N	XE5457Y	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	19860.0	14230.0	5630.0	LR20450	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 21930 | bins: BIN-6002 RB5-0115 RB5-8401 RB3-0417 | DS date digit ambiguous (24? or 28?); security stamp 28 JAN 2026 and chit 28/01/2026 16:17 so 28 used	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-21934	backfill	\N	2026-01-29	\N	\N	STE_001	\N	\N	XE5457Y	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	17210.0	14230.0	2980.0	LR20446	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 21934 | bins: BIN-6001 RB5-0115 RB3-0417 RB5-8401	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-21937	backfill	\N	2026-01-30	\N	\N	STE_001	\N	\N	XE5457Y	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	17680.0	14230.0	3450.0	LR20459	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 21937 | bins: BIN-6002 RB5-0115 RB3-0417 RB5-8401 | Third RB ref written 'RB-8401' (assumed RB5-8401)	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-21940	backfill	\N	2026-01-30	\N	\N	STE_001	\N	\N	XE5457Y	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	18030.0	14260.0	3770.0	LR20460	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 21940 | bins: BIN-6001 RB5-0115 RB3-0417 RB5-8401	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-21857	backfill	\N	2026-01-02	\N	\N	STE_001	\N	\N	XE5457Y	\N	\N	Wood Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	15800.0	14250.0	1550.0	LR20250	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 21857 | bins: BIN 6003 | Form date handwritten 02/02/2026 (month error); security stamp 02 JAN 2026 and chit 02/01/2026 confirm January	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-21861	backfill	\N	2026-01-07	\N	\N	STE_001	\N	\N	XE5457Y	\N	\N	Wood Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	17930.0	14100.0	3830.0	LR20284	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 21861 | bins: BIN 6003 | Form dated/stamped 06 JAN 2026; chit timed 07/01/2026 10:45 (weighed next morning)	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-21867	backfill	\N	2026-01-07	\N	\N	STE_001	\N	\N	XE5457Y	\N	\N	Wood Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	18180.0	14240.0	3940.0	LR20296	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 21867 | bins: BIN 6000	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-21863	backfill	\N	2026-01-08	\N	\N	STE_001	\N	\N	XE5457Y	\N	\N	Wood Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	16040.0	14140.0	1900.0	LR20294	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 21863 | bins: BIN 6002 | Handwritten on form: 16040 / 1.9T (matches chit)	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-21868	backfill	\N	2026-01-08	\N	\N	STE_001	\N	\N	XE5457Y	\N	\N	Wood Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	17390.0	14250.0	3140.0	LR20293	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 21868 | bins: BIN 6000 | Handwritten on form: 3.14T (matches chit)	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-21869	backfill	\N	2026-01-09	\N	\N	STE_001	\N	\N	XE5457Y	\N	\N	Wood Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	16480.0	14150.0	2330.0	LR20297	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 21869 | bins: BIN 6000	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-21873	backfill	\N	2026-01-09	\N	\N	STE_001	\N	\N	XE5457Y	\N	\N	Wood Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	16150.0	14200.0	1950.0	LR20300	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 21873 | bins: BIN 6000	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-21877	backfill	\N	2026-01-12	\N	\N	STE_001	\N	\N	XE5457Y	\N	\N	Wood Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	15320.0	14240.0	1080.0	LR20395	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 21877 | bins: BIN 6000	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-21880	backfill	\N	2026-01-13	\N	\N	STE_001	\N	\N	XE5457Y	\N	\N	Wood Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	15780.0	14240.0	1540.0	LR20397	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 21880 | bins: BIN 6000	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-21883	backfill	\N	2026-01-14	\N	\N	STE_001	\N	\N	XE5457Y	\N	\N	Wood Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	15660.0	14240.0	1420.0	LR20400	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 21883 | bins: BIN 6000? | Bin no not written on form; chit shows Bin 6000	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-21881	backfill	\N	2026-01-15	\N	\N	STE_001	\N	\N	XE5457Y	\N	\N	Wood Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	15580.0	14240.0	1340.0	LR20401	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 21881 | bins: BIN 6000	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-21890	backfill	\N	2026-01-16	\N	\N	STE_001	\N	\N	XE5457Y	\N	\N	Wood Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	16000.0	14240.0	1760.0	LR20404	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 21890 | bins: BIN 6003	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-21899	backfill	\N	2026-01-19	\N	\N	STE_001	\N	\N	XE5457Y	\N	\N	Wood Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	16850.0	14240.0	2610.0	LR20354	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 21899 | bins: BIN 6003	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-21901	backfill	\N	2026-01-20	\N	\N	STE_001	\N	\N	XE5457Y	\N	\N	Wood Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	17850.0	14240.0	3610.0	LR20356	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 21901 | bins: BIN 6003	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-21907	backfill	\N	2026-01-21	\N	\N	STE_001	\N	\N	XE5457Y	\N	\N	Wood Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	16950.0	14240.0	2710.0	LR20372	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 21907 | bins: BIN 6003	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-21914	backfill	\N	2026-01-23	\N	\N	STE_001	\N	\N	XE5457Y	\N	\N	Wood Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	17350.0	14240.0	3110.0	LR20408	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 21914 | bins: BIN 6003	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-21921	backfill	\N	2026-01-26	\N	\N	STE_001	\N	\N	XE5457Y	\N	\N	Wood Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	17520.0	14260.0	3260.0	LR20427	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 21921 | bins: BIN 6003	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-21924	backfill	\N	2026-01-26	\N	\N	STE_001	\N	\N	XE5457Y	\N	\N	Wood Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	18010.0	14270.0	3740.0	LR20429	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 21924 | bins: BIN 6003 | Form date reads 25/01/2026? but security stamp 26 JAN 2026 and chit 26/01/2026 15:04 - dated by chit	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-21927	backfill	\N	2026-01-27	\N	\N	STE_001	\N	\N	XE5457Y	\N	\N	Wood Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	17020.0	14230.0	2790.0	LR20436	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 21927 | bins: BIN 6003	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-21929	backfill	\N	2026-01-28	\N	\N	STE_001	\N	\N	XE5457Y	\N	\N	Wood Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	16230.0	14280.0	1950.0	LR20448	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 21929 | bins: BIN 6003	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-21935	backfill	\N	2026-01-29	\N	\N	STE_001	\N	\N	XE5457Y	\N	\N	Wood Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	17030.0	14280.0	2750.0	LR20445	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 21935 | bins: BIN 6003	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-21941	backfill	\N	2026-01-30	\N	\N	STE_001	\N	\N	XE5457Y	\N	\N	Wood Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	16430.0	14320.0	2110.0	LR20461	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 21941 | bins: BIN 6003	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-21938	backfill	\N	2026-01-30	\N	\N	STE_001	\N	\N	\N	\N	\N	Oversized Wood Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	21220.0	19640.0	1580.0	145990	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 21938 | bins:  | vehicle_raw=XE6557P? | OVERSIZED WOOD line: Tang Hai Hardware external weighbridge chit 145990 (first/second weight); form vehicle handwriting unclear (XE 6?9? / 6957P?) - chit shows XE6557P; collector Liew T.Y; no bin ref on form	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-42062	backfill	\N	2026-01-02	\N	\N	STE_002	\N	\N	XE5457Y	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	20500.0	14200.0	6300.0	LR20253	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 42062 | bins: RG1 3140; RG1 3137; bin 6000	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-42064	backfill	\N	2026-01-02	\N	\N	STE_002	\N	\N	XE5457Y	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	19000.0	14350.0	4650.0	LR20252	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 42064 | bins: RG1 3112; RG1 3139; bin 6002	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-42069	backfill	\N	2026-01-04	\N	\N	STE_002	\N	\N	XE5457Y	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	19960.0	14240.0	5720.0	LR20262	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 42069 | bins: RG1 3109; RG1 3140; bin 6002	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-42070	backfill	\N	2026-01-04	\N	\N	STE_002	\N	\N	XE5457Y	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	18480.0	14240.0	4240.0	LR20263	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 42070 | bins: RG1 3137; RG1 3112; bin 6000	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-42072	backfill	\N	2026-01-04	\N	\N	STE_002	\N	\N	XE5457Y	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	20160.0	14240.0	5920.0	LR20265	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 42072 | bins: RG1 3132; RG1 3116; bin 6002	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-42081	backfill	\N	2026-01-05	\N	\N	STE_002	\N	\N	\N	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	18830.0	13900.0	4930.0	LR20269	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 42081 | bins: RG1 3139; RG1 3130; bin 6002 | vehicle_raw=XE2665H	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-42082	backfill	\N	2026-01-05	\N	\N	STE_002	\N	\N	\N	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	19850.0	13970.0	5880.0	LR20270	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 42082 | bins: RG1 3140; RG1 3137; bin 6000 | vehicle_raw=XE2665H	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-42088	backfill	\N	2026-01-06	\N	\N	STE_002	\N	\N	\N	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	18650.0	13900.0	4750.0	LR20274	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 42088 | bins: RG1 3137; RG1 3112; bin 6000 | vehicle_raw=XE2665H	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-42093	backfill	\N	2026-01-07	\N	\N	STE_002	\N	\N	XE5457Y	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	18060.0	14280.0	3780.0	LR20406	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 42093 | bins: RG1 3140; RG1 3137; bin 6000 | ticket no out of sequence (chit printed same date 07/01)	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-42096	backfill	\N	2026-01-08	\N	\N	STE_002	\N	\N	\N	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	19870.0	13900.0	5970.0	LR20288	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 42096 | bins: RG1 3139; RG1 3132; bin 6002 | vehicle_raw=XE2665H | form vehicle XE2665H; chit XE2665H	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-42098	backfill	\N	2026-01-08	\N	\N	STE_002	\N	\N	\N	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	21630.0	13950.0	7680.0	LR20289	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 42098 | bins: RG1 3112; RG1 3116; bin 6000 | vehicle_raw=XE2665H	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-42102	backfill	\N	2026-01-09	\N	\N	STE_002	\N	\N	\N	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	17080.0	13900.0	3180.0	LR20302	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 42102 | bins: RG1 3109; RG1 3146; bin 6000 | vehicle_raw=XE2665H	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-42105	backfill	\N	2026-01-09	\N	\N	STE_002	\N	\N	\N	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	18350.0	13950.0	4400.0	LR20304	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 42105 | bins: RG1 3140; RG1 3069; bin 6002 | vehicle_raw=XE2665H	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-42108	backfill	\N	2026-01-10	\N	\N	STE_002	\N	\N	\N	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	20850.0	13900.0	6950.0	LR20309	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 42108 | bins: RG1 3144; RG1 3146; bin 6000 | vehicle_raw=XE2665H	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-42109	backfill	\N	2026-01-10	\N	\N	STE_002	\N	\N	\N	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	18690.0	13950.0	4740.0	LR20310	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 42109 | bins: RG1 3109; RG1 3069; bin 6002 | vehicle_raw=XE2665H	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-42110	backfill	\N	2026-01-11	\N	\N	STE_002	\N	\N	\N	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	16420.0	13900.0	2520.0	LR20311	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 42110 | bins: RG1 3138; RG1 3144; bin 6002 | vehicle_raw=XE2665H	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-42111	backfill	\N	2026-01-11	\N	\N	STE_002	\N	\N	\N	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	18460.0	13950.0	4510.0	LR20312	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 42111 | bins: RG1 3069; RG1 3137; bin 6000 | vehicle_raw=XE2665H	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-42122	backfill	\N	2026-01-13	\N	\N	STE_002	\N	\N	XE5457Y	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	16750.0	14290.0	2460.0	LR20324	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 42122 | bins: RG1 3146; RG1 3109; bin 6000	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-42127	backfill	\N	2026-01-14	\N	\N	STE_002	\N	\N	XE5457Y	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	17500.0	14280.0	3220.0	LR20339	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 42127 | bins: RG1 3144; RG1 3146; bin 6000 | paired chit is LR20339 (handwritten 17510/14250 on form matches this chit)	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-42128	backfill	\N	2026-01-14	\N	\N	STE_002	\N	\N	XE5457Y	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	20400.0	14380.0	6020.0	LR20338	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 42128 | bins: RG1 3136; RG1 3132; bin 6002 | chit order reversed vs form order (handwritten 20410/16820 on form matches this chit)	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-42131	backfill	\N	2026-01-15	\N	\N	STE_002	\N	\N	XE5457Y	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	18600.0	14300.0	4300.0	LR20337	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 42131 | bins: RG1 3112; RG1 3144; bin 6000	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-42138	backfill	\N	2026-01-16	\N	\N	STE_002	\N	\N	XE5457Y	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	19500.0	14300.0	5200.0	LR20349	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 42138 | bins: RG1 3112; RG1 3132; bin 6002	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-42140	backfill	\N	2026-01-17	\N	\N	STE_002	\N	\N	XE5457Y	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	18500.0	14250.0	4250.0	LR20351	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 42140 | bins: RG1 3136; RG1 3132; bin 6000	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-42143	backfill	\N	2026-01-18	\N	\N	STE_002	\N	\N	XE5457Y	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	17800.0	14350.0	3450.0	LR20352	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 42143 | bins: RG1 3141; RG1 3136; bin 6002	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-42145	backfill	\N	2026-01-19	\N	\N	STE_002	\N	\N	XE5457Y	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	18380.0	14240.0	4140.0	LR20390	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 42145 | bins: RG1 3141; RG1 3136; bin 6002	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-42147	backfill	\N	2026-01-20	\N	\N	STE_002	\N	\N	XE5457Y	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	18580.0	14240.0	4340.0	LR20392	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 42147 | bins: RG1 3069; RG1 3145; bin 6002	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-42150	backfill	\N	2026-01-20	\N	\N	STE_002	\N	\N	XE5457Y	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	17860.0	14240.0	3620.0	LR20393	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 42150 | bins: RG1 3137; RG1 3141; bin 6000	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-42159	backfill	\N	2026-01-21	\N	\N	STE_002	\N	\N	XE5457Y	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	18280.0	14240.0	4040.0	LR20375	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 42159 | bins: RG1 3112; RG1 3136; bin 6000	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-42165	backfill	\N	2026-01-22	\N	\N	STE_002	\N	\N	XE5457Y	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	17960.0	14240.0	3720.0	LR20376	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 42165 | bins: RG1 3069; RG1 3137; bin 6000	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-42172	backfill	\N	2026-01-23	\N	\N	STE_002	\N	\N	XE5457Y	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	17960.0	14240.0	3720.0	LR20412	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 42172 | bins: RG1 3138; RG1 3145; bin 6002	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-42174	backfill	\N	2026-01-23	\N	\N	STE_002	\N	\N	XE5457Y	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	18560.0	14240.0	4320.0	LR20413	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 42174 | bins: RG1 3136; RG1 3132; bin 6000	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-42177	backfill	\N	2026-01-24	\N	\N	STE_002	\N	\N	XE5457Y	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	18370.0	14240.0	4130.0	LR20414	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 42177 | bins: RG1 3069; RG1 3109; bin 6000	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-42178	backfill	\N	2026-01-24	\N	\N	STE_002	\N	\N	XE5457Y	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	17860.0	14240.0	3620.0	LR20415	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 42178 | bins: RG1 3146; RG1 3145; bin 6005	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-42182	backfill	\N	2026-01-25	\N	\N	STE_002	\N	\N	XE5457Y	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	17370.0	14240.0	3130.0	LR20431	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 42182 | bins: RG1 3112; RG1 3136; bin 6005	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-42183	backfill	\N	2026-01-25	\N	\N	STE_002	\N	\N	XE5457Y	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	18280.0	14240.0	4040.0	LR20432	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 42183 | bins: RG1 3141; RG1 3132; bin 6006	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-42188	backfill	\N	2026-01-26	\N	\N	STE_002	\N	\N	XE5457Y	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	18320.0	14240.0	4080.0	LR20424	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 42188 | bins: RG1 3069; RG1 3146; bin 6005	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-42189	backfill	\N	2026-01-26	\N	\N	STE_002	\N	\N	XE5457Y	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	17510.0	14240.0	3270.0	LR20425	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 42189 | bins: RG1 3112; RG1 3137; bin 6003 | chit bin no 6003	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-42194	backfill	\N	2026-01-27	\N	\N	STE_002	\N	\N	XE5457Y	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	19010.0	14240.0	4770.0	LR20439	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 42194 | bins: RG1 3137; RG1 3138; bin 6003	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-42195	backfill	\N	2026-01-27	\N	\N	STE_002	\N	\N	XE5457Y	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	18970.0	14240.0	4730.0	LR20440	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 42195 | bins: RG1 3141; RG1 3146; bin 6005	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-42200	backfill	\N	2026-01-28	\N	\N	STE_002	\N	\N	XE5457Y	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	18150.0	14240.0	3910.0	LR20442	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 42200 | bins: RG1 3132; RG1 3136; bin 6003	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-42203	backfill	\N	2026-01-29	\N	\N	STE_002	\N	\N	XE5457Y	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	19770.0	14240.0	5530.0	LR20456	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 42203 | bins: RG1 3112; RG1 3137; bin 6005	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-42206	backfill	\N	2026-01-29	\N	\N	STE_002	\N	\N	XE5457Y	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	18350.0	14240.0	4110.0	LR20455	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 42206 | bins: RG1 3143; RG1 3116; bin 6003 | chit order reversed vs form order (LR20455 13:45 bin 6003 matches this form)	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-42207	backfill	\N	2026-01-30	\N	\N	STE_002	\N	\N	XE5457Y	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	17370.0	14240.0	3130.0	LR20453	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 42207 | bins: RG1 3146; RG1 3136; bin 6005	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-42213	backfill	\N	2026-01-31	\N	\N	STE_002	\N	\N	XE5457Y	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	18790.0	14240.0	4550.0	LR20466	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 42213 | bins: RG1 3146; RG1 3109; bin 6003	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-42214	backfill	\N	2026-01-31	\N	\N	STE_002	\N	\N	XE5457Y	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	18370.0	14240.0	4130.0	LR20467	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 42214 | bins: RG1 3137; RG1 3141; bin 6005	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-42065	backfill	\N	2026-01-02	\N	\N	STE_002	\N	\N	XE5457Y	\N	\N	Wood Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	18200.0	15000.0	3200.0	LR20254	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 42065 | bins: RGI 3116 / RGI 3130 / bin 8000 | JOB 202008	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-42071	backfill	\N	2026-01-04	\N	\N	STE_002	\N	\N	XE5457Y	\N	\N	Wood Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	17510.0	15150.0	2360.0	LR20264	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 42071 | bins: RGI 3139 / RGI 3094 / bin 8000 | JOB 202008	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-42089	backfill	\N	2026-01-06	\N	\N	STE_002	\N	\N	\N	\N	\N	Wood Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	22380.0	15100.0	7280.0	LR20273	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 42089 | bins: RGI 3139 / RGI 3094 / bin 8000 | vehicle_raw=XE2665H | JOB 202008; vehicle handwriting on form unclear - taken from weighing chit	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-42100	backfill	\N	2026-01-09	\N	\N	STE_002	\N	\N	\N	\N	\N	Wood Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	18630.0	15050.0	3580.0	LR20301	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 42100 | bins: RGI 3112 / RGI 3140 / bin 8000 | vehicle_raw=XE2665H | JOB 202008; vehicle handwriting on form unclear - taken from weighing chit	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-42112	backfill	\N	2026-01-11	\N	\N	STE_002	\N	\N	\N	\N	\N	Wood Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	18430.0	15100.0	3330.0	LR20313	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 42112 | bins: RGI 3112 / RGI 3139 / bin 8000 | vehicle_raw=XE2665H | JOB 202008; vehicle handwriting on form unclear - taken from weighing chit	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-42116	backfill	\N	2026-01-12	\N	\N	STE_002	\N	\N	XE5457Y	\N	\N	Wood Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	16900.0	15500.0	1400.0	LR20321	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 42116 | bins: RGI 3132 / RGI 3136 / bin 8000 | JOB 202008	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-42130	backfill	\N	2026-01-15	\N	\N	STE_002	\N	\N	XE5457Y	\N	\N	Wood Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	17750.0	14950.0	2800.0	LR20336	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 42130 | bins: RGI 3145 / RGI 3137 / bin 8000 | JOB 202008	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-42144	backfill	\N	2026-01-18	\N	\N	STE_002	\N	\N	XE5457Y	\N	\N	Wood Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	17050.0	14900.0	2150.0	LR20353	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 42144 | bins: RGI 3146 / RGI 3109 / bin 8000 | JOB 202008	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-42151	backfill	\N	2026-01-20	\N	\N	STE_002	\N	\N	XE5457Y	\N	\N	Wood Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	18710.0	15500.0	3210.0	LR20394	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 42151 | bins: RGI 3132 / RGI 3136 / bin 8000 | JOB 202008	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-42181	backfill	\N	2026-01-25	\N	\N	STE_002	\N	\N	XE5457Y	\N	\N	Wood Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	18790.0	15500.0	3290.0	LR20430	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 42181 | bins: RGI 3145? / RGI 3069 / bin 8000 | JOB 202008; first bin ref handwritten 31/15 - could be 3145 or 3115 ?	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-42198	backfill	\N	2026-01-28	\N	\N	STE_002	\N	\N	XE5457Y	\N	\N	Wood Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	18380.0	15500.0	2880.0	LR20441	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 42198 | bins: RGI 3112 / RGI 3137 / bin 8000 | JOB 202008	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-42208	backfill	\N	2026-01-30	\N	\N	STE_002	\N	\N	XE5457Y	\N	\N	Wood Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	17800.0	15500.0	2300.0	LR20454	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 42208 | bins: RGI 3069 / RGI 3109 / bin 8000 | JOB 202008	2026-07-31 18:08:00.568866+00	\N	\N	\N
STE-DS-42103	backfill	\N	2026-01-09	\N	\N	STE_002	\N	\N	\N	\N	\N	Used Fender	\N	\N	\N	\N	\N	\N	\N	\N	\N	15490.0	13900.0	1590.0	LR20303	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	STE D/S form 42103 | bins: RGI 3130 / bin 6000 | vehicle_raw=XE2665H | JOB 121001; Others: Used Fender; vessel Pacific Hawk?; chit product OLD FENDERS	2026-07-31 18:08:00.568866+00	\N	\N	\N
\.


--
-- Data for Name: customers; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.customers (client_id, name, payment_terms, sales_rep, xero_contact_id, active, created_at, contact_name, contact_phone, contact_email) FROM stdin;
ABS	Absolut Properties Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
ACR	Acreation Group Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
ADV	Advanced Substrate Technologies Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
AJK	AJK	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
ALL	Allalloy Dynaweld Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
ALLI	Allied Container Services Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
APE	Apex Sealing Technologies Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
ARC	Archibiz	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
ART	Artdecor Design Studio Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
ASL	ASL Proworld Solution Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
AST	Astore Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
AVE	Aver Asia (S) Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
BAB	Babu	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
ENG	Eng Lee Logistics Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
ENGI	Engie Services Singapore Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
ENGL	Eng Leng Contractors Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
EPO	Epont Building Services Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
EUR	Euro Pac Logistics Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
EVE	EverTeam Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
FAX	Faxolif Industries Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
GEO	Geoinnovations Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
GLO	Glory SIP Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
GSE	GS Engineering and Construction Corporation	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
GWC	GWC	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
GYM	Gymsportz	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
HAI	Haid Biotechnology Industry (Singapore) Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
HCG	HCG	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
HEP	He Ping Development Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
HON	Hong Hang Hardware	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
HOT	Hotel Royal Singapore	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
HPR	H1 Projects Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
HUA	Huationg Contractor	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
HUN	Huntsman (S) Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
HYD	Hydroproof	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
INV	INVX Asia Pacific Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
IWA	Iwatech	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
LAU	Lau Choy Seng Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
LCH	LCH Logistics Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
LEN	Leng Aik Engineering	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
LEX	LexBuild International Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
LIM	Lim Siang Huat Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
LIR	Lirich	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
MAT	Matrix Cooling (Singapore) Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
MEC	Mecom GreenBuild (Singapore) Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
NEA	NEA	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
PAX	PaxOcean Singapore Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
PIL	Pacific International Lines	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
POH	Poh Tiong Choon Logistics Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
PSA	PSA Port Ecosystem (Sea) Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
QUA	Qualicoat Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
REM	REMEX Minerals Singapore Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
RJH	RJ Hydralics	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
SAV	Savills Property Management Pte Ltd (Blue Hub)	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
SAVI	Savills Property Management Pte Ltd (Green Hub)	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
SEA	Seatrium Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
SIE	Siew Kong Glass Makers Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
SIN	Sin Hong Hardware Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
SIND	Sindac Cleaning Services Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
SINH	Sin Hong Poh Metal Trading	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
SLS	SLS	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
SNI	Snip Avenue Holdings	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
SPR	Springlife Maintenance Service Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
STA	Stamford Tyres	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
STS	STSM	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
SUM	Sumber Indah Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
SUN	Sun City Maintenance Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
SYS	Sys-Mac Automation Engineering Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
SYST	System Foundation Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
TAI	Tai Lee Tong	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
TEC	Technicair Singapore Services Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
TECH	Technigroup Far East Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
TECK	Teck Sang Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
TOH	Toh Ban Seng	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
TON	Tong Carriage (S) Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
TOP	Top Star Builder Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
TRA	Tracebuild	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
TRE	T3 Reources Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
TST	TSTL	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
URB	Urban Group Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
WAH	Wah & Hua Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
WEB	WeBuild	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
WIK	WIKA Instrumentation Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
WIL	Wilkie Development Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
WOR	World of Wood Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
WRA	W'Ray Construction Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
HYU	Hyundai Engineering & Construction Co., Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
EXP	123 Express	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
ECO	Ecozeal	\N	\N	\N	t	2026-07-30 00:35:38.037853+00	\N	\N	\N
RAD	Radha Exports Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
SHI	Shin Ya O Ya Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
TONG	Tong Hock Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
STX	ST Engineering	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
STE	ST Engineering Marine Ltd.	\N	\N	\N	t	2026-07-31 03:02:32.106388+00	\N	\N	\N
BCW	B&C Waste	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
BEE	Beejoo	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
BND	BNDC (Fairprice)	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
CAL	Calvary Carpentry Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
CAR	Cargo International	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
CAT	Caterpillar	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
CBM	CBM Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
CHA	Chateraise	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
CHI	Chiong Construction	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
CHU	Chuan Seng Leong	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
CLE	Cleanis-Tee	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
CNC	CNCCS Engineering and Construction Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
CPH	C & P Holdings Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
CRE	CrestSA Marine & Offshore Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
DSV	DSV	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
DYN	Dyna Cool	\N	\N	\N	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
\.


--
-- Data for Name: drivers; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.drivers (driver_id, name, phone, active) FROM stdin;
YAO_JUN	Yao Jun	\N	t
SATHISH	Sathish	\N	t
KARTHIK	Karthik	\N	t
\.


--
-- Data for Name: facilities; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.facilities (facility_id, name, route) FROM stdin;
TUAS_WTE	Tuas Waste-to-Energy Plant	WtE
SEMAKAU	Semakau Landfill	landfill
TRS	TRS Environment	recovery
LIRICH_YARD	Lirich Yard (sort/store)	recovery
\.


--
-- Data for Name: factors; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.factors (id, domain, key, route, value, unit, basis, source_ref, valid_from) FROM stdin;
3	waste	general_waste	WtE	0.111500	tCO2e/t	SEFR 2025 (Singapore Emission Factors Registry, NEA-sourced, netzerohub.sg): general waste incineration/WtE 0.1115 tCO2e/t. Rebased 2026-07-31 (was indicative 0.35).	\N	2026-07-31
4	avoided	general_waste	recovery	0.111500	tCO2e/t	Avoided WtE emissions per tonne diverted to recovery = SEFR general-waste incineration factor 0.1115 tCO2e/t (conservative; excludes material-recovery credits). Rebased 2026-07-31 (was indicative 0.46).	\N	2026-07-31
1	fuel	diesel	\N	2.678000	kgCO2e/L	Diesel 2.678 kgCO2e/L - IPCC 2006 / NEA M&R-aligned default. Confirmed 2026-07-31.	\N	2026-07-24
2	grid	sg_grid	\N	0.402000	kgCO2e/kWh	EMA Singapore Grid Emission Factor 2024 = 0.402 kgCO2/kWh (official; basis for carbon-tax reporting from Jan 2026).	\N	2026-07-24
5	avoided	paper	recovery	0.900000	tCO2e/t	Material-recovery credit - indicative only, NOT used in live carbon calc (general-waste avoided factor applies). Verify vs SEFR before any client-facing use.	\N	2026-07-24
6	avoided	plastics	recovery	1.100000	tCO2e/t	Material-recovery credit - indicative only, NOT used in live carbon calc (general-waste avoided factor applies). Verify vs SEFR before any client-facing use.	\N	2026-07-24
7	avoided	metals	recovery	1.500000	tCO2e/t	Material-recovery credit - indicative only, NOT used in live carbon calc (general-waste avoided factor applies). Verify vs SEFR before any client-facing use.	\N	2026-07-24
8	waste	plastics	WtE	2.762500	tCO2e/t	SEFR 2025 (NEA-sourced): plastics incineration 2.7625 tCO2e/t.	\N	2026-07-31
\.


--
-- Data for Name: fuel_log; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.fuel_log (id, vehicle_id, fill_date, litres, cost, odometer_km, entered_by, source, fuel_type, cartrack_co2_g, synced_at) FROM stdin;
1	XE4491D	2026-07-28	122.20	\N	\N	cartrack-est	cartrack	diesel	\N	2026-07-29 04:17:15.452+00
2	XE5457Y	2026-07-28	65.80	\N	\N	cartrack-est	cartrack	diesel	\N	2026-07-29 04:17:15.953+00
3	XE6221D	2026-07-28	85.30	\N	\N	cartrack-est	cartrack	diesel	\N	2026-07-29 04:17:16.444+00
4	XE8496P	2026-07-28	0.00	\N	\N	cartrack-est	cartrack	diesel	\N	2026-07-29 04:17:16.888+00
5	XE7126P	2026-07-28	59.15	\N	\N	cartrack-est	cartrack	diesel	\N	2026-07-29 04:17:17.313+00
6	XE4491D	2026-07-29	99.25	\N	\N	cartrack-est	cartrack	diesel	\N	2026-07-29 19:00:09.608+00
7	XE5457Y	2026-07-29	36.30	\N	\N	cartrack-est	cartrack	diesel	\N	2026-07-29 19:00:11.15+00
8	XE6221D	2026-07-29	141.75	\N	\N	cartrack-est	cartrack	diesel	\N	2026-07-29 19:00:12.135+00
9	XE8496P	2026-07-29	94.55	\N	\N	cartrack-est	cartrack	diesel	\N	2026-07-29 19:00:13.527+00
10	XE7126P	2026-07-29	89.75	\N	\N	cartrack-est	cartrack	diesel	\N	2026-07-29 19:00:13.972+00
11	XE4491D	2026-07-30	26.95	\N	\N	cartrack-est	cartrack	diesel	\N	2026-07-30 19:00:06.478+00
12	XE5457Y	2026-07-30	82.30	\N	\N	cartrack-est	cartrack	diesel	\N	2026-07-30 19:00:08.384+00
13	XE6221D	2026-07-30	64.80	\N	\N	cartrack-est	cartrack	diesel	\N	2026-07-30 19:00:09.023+00
14	XE8496P	2026-07-30	108.10	\N	\N	cartrack-est	cartrack	diesel	\N	2026-07-30 19:00:10.534+00
15	XE7126P	2026-07-30	83.80	\N	\N	cartrack-est	cartrack	diesel	\N	2026-07-30 19:00:12.264+00
16	XE4491D	2026-07-31	35.75	\N	\N	cartrack-est	cartrack	diesel	\N	2026-07-31 19:00:06.991+00
17	XE5457Y	2026-07-31	82.15	\N	\N	cartrack-est	cartrack	diesel	\N	2026-07-31 19:00:07.962+00
18	XE6221D	2026-07-31	120.55	\N	\N	cartrack-est	cartrack	diesel	\N	2026-07-31 19:00:08.504+00
19	XE8496P	2026-07-31	73.85	\N	\N	cartrack-est	cartrack	diesel	\N	2026-07-31 19:00:09.715+00
20	XE7126P	2026-07-31	160.70	\N	\N	cartrack-est	cartrack	diesel	\N	2026-07-31 19:00:11.263+00
\.


--
-- Data for Name: interest_leads; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.interest_leads (id, email, source, page, ip, user_agent, created_at) FROM stdin;
\.


--
-- Data for Name: jobcard_overrides; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.jobcard_overrides (id, card_date, driver_id, field_key, old_value, new_value, actor, at) FROM stdin;
1	2026-07-30	5	trip:46:tonnage	0	10	admin	2026-07-30 20:48:58.274175+00
2	2026-07-30	5	trip:46:tonnage	0	0	admin	2026-07-30 20:49:08.034225+00
3	2026-07-30	5	trip:46:tonnage	0	10	admin	2026-07-30 20:49:13.178649+00
4	2026-07-30	5	trip:46:tonnage	0	0	admin	2026-07-30 20:51:38.874579+00
5	2026-07-30	5	trip:46:tonnage	0	03	admin	2026-07-30 20:51:45.521091+00
6	2026-07-30	5	trip:46:tonnage	0	0	admin	2026-07-30 20:51:49.200841+00
\.


--
-- Data for Name: jobs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.jobs (job_no, job_date, status, site_id, contact, task, bin_size, waste_type, dump_to, driver_id, started_at, created_at) FROM stdin;
\.


--
-- Data for Name: maintenance; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.maintenance (id, vehicle_id, service_date, description, cost, photo_ref) FROM stdin;
\.


--
-- Data for Name: odometer_log; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.odometer_log (id, vehicle_id, read_date, odometer_km, source, distance_km, cartrack_co2_g, synced_at) FROM stdin;
5	XE4491D	2026-07-28	80972	cartrack	244.4	\N	2026-07-29 04:17:15.381+00
6	XE5457Y	2026-07-28	59344	cartrack	131.6	\N	2026-07-29 04:17:15.892+00
7	XE6221D	2026-07-28	82610	cartrack	170.6	\N	2026-07-29 04:17:16.401+00
8	XE8496P	2026-07-28	52924	cartrack	0	\N	2026-07-29 04:17:16.832+00
9	XE7126P	2026-07-28	52423	cartrack	118.3	\N	2026-07-29 04:17:17.265+00
10	XE4491D	2026-07-29	81111	cartrack	198.5	\N	2026-07-29 19:00:09.502+00
11	XE5457Y	2026-07-29	59361	cartrack	72.6	\N	2026-07-29 19:00:11.108+00
12	XE6221D	2026-07-29	82790	cartrack	283.5	\N	2026-07-29 19:00:12.074+00
13	XE8496P	2026-07-29	53050	cartrack	189.1	\N	2026-07-29 19:00:13.486+00
14	XE7126P	2026-07-29	52541	cartrack	179.5	\N	2026-07-29 19:00:13.932+00
15	XE4491D	2026-07-30	81165	cartrack	53.9	\N	2026-07-30 19:00:06.364+00
16	XE5457Y	2026-07-30	59526	cartrack	164.6	\N	2026-07-30 19:00:08.335+00
17	XE6221D	2026-07-30	82920	cartrack	129.6	\N	2026-07-30 19:00:08.972+00
18	XE8496P	2026-07-30	53266	cartrack	216.2	\N	2026-07-30 19:00:10.481+00
19	XE7126P	2026-07-30	52708	cartrack	167.6	\N	2026-07-30 19:00:12.223+00
20	XE4491D	2026-07-31	81236	cartrack	71.5	\N	2026-07-31 19:00:06.885+00
21	XE5457Y	2026-07-31	59690	cartrack	164.3	\N	2026-07-31 19:00:07.917+00
22	XE6221D	2026-07-31	83161	cartrack	241.1	\N	2026-07-31 19:00:08.423+00
23	XE8496P	2026-07-31	53414	cartrack	147.7	\N	2026-07-31 19:00:09.668+00
24	XE7126P	2026-07-31	53030	cartrack	321.4	\N	2026-07-31 19:00:11.219+00
\.


--
-- Data for Name: onward_disposal; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.onward_disposal (id, do_no, hop_no, facility_id, moved_date, receipt_ref) FROM stdin;
\.


--
-- Data for Name: portal_accounts; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.portal_accounts (id, email, display_name, client_id, status, requested_at, provisioned_at, notes) FROM stdin;
\.


--
-- Data for Name: rate_card; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.rate_card (id, site_id, job_type, price, valid_from, created_by) FROM stdin;
2618	STS_006	Collect	18.00	2026-07-23	portal
2619	STS_006	Delivery	8.00	2026-07-23	portal
2620	STS_006	Exchange	18.00	2026-07-23	portal
2621	STS_006	Load	26.00	2026-07-30	portal
2646	SUN_002	Collect	23.00	2026-07-23	portal
2647	SUN_002	Delivery	8.00	2026-07-23	portal
2648	SUN_002	Exchange	23.00	2026-07-23	portal
2649	SUN_002	Load	31.00	2026-07-30	portal
2694	TON_001	Collect	13.00	2026-07-23	portal
2695	TON_001	Delivery	8.00	2026-07-23	portal
2696	TON_001	Exchange	13.00	2026-07-23	portal
2697	TON_001	Load	21.00	2026-07-30	portal
2722	TONG_007	Collect	18.00	2026-07-23	portal
2723	TONG_007	Delivery	8.00	2026-07-23	portal
2724	TONG_007	Exchange	18.00	2026-07-23	portal
2725	TONG_007	Load	26.00	2026-07-30	portal
2750	WAH_001	Collect	23.00	2026-07-23	portal
2751	WAH_001	Delivery	8.00	2026-07-23	portal
2752	WAH_001	Exchange	23.00	2026-07-23	portal
2753	WAH_001	Load	31.00	2026-07-30	portal
2778	WEB_001	Collect	23.00	2026-07-23	portal
2779	WEB_001	Delivery	8.00	2026-07-23	portal
2780	WEB_001	Exchange	23.00	2026-07-23	portal
2781	WEB_001	Load	31.00	2026-07-30	portal
1388	BEE_001	Dump	18.00	2026-07-23	sheet
2622	STX_001	Collect	13.00	2026-07-23	portal
2623	STX_001	Delivery	8.00	2026-07-23	portal
2624	STX_001	Exchange	13.00	2026-07-23	portal
2625	STX_001	Load	21.00	2026-07-30	portal
2650	SUN_003	Collect	23.00	2026-07-23	portal
2651	SUN_003	Delivery	8.00	2026-07-23	portal
2652	SUN_003	Exchange	23.00	2026-07-23	portal
2653	SUN_003	Load	31.00	2026-07-30	portal
2698	TONG_001	Collect	13.00	2026-07-23	portal
2699	TONG_001	Delivery	8.00	2026-07-23	portal
2700	TONG_001	Exchange	13.00	2026-07-23	portal
2701	TONG_001	Load	21.00	2026-07-30	portal
2726	TONG_008	Collect	18.00	2026-07-23	portal
2727	TONG_008	Delivery	8.00	2026-07-23	portal
2728	TONG_008	Exchange	18.00	2026-07-23	portal
2729	TONG_008	Load	26.00	2026-07-30	portal
2754	WAH_002	Collect	23.00	2026-07-23	portal
2755	WAH_002	Delivery	8.00	2026-07-23	portal
2756	WAH_002	Exchange	23.00	2026-07-23	portal
2757	WAH_002	Load	31.00	2026-07-30	portal
2782	WIK_001	Collect	13.00	2026-07-23	portal
2783	WIK_001	Delivery	8.00	2026-07-23	portal
2784	WIK_001	Exchange	13.00	2026-07-23	portal
2785	WIK_001	Load	21.00	2026-07-30	portal
2626	STX_002	Collect	19.50	2026-07-23	portal
2627	STX_002	Delivery	8.00	2026-07-23	portal
2628	STX_002	Exchange	19.50	2026-07-23	portal
2629	STX_002	Load	27.50	2026-07-30	portal
2654	SUN_004	Collect	23.00	2026-07-23	portal
2655	SUN_004	Delivery	8.00	2026-07-23	portal
2656	SUN_004	Exchange	23.00	2026-07-23	portal
2657	SUN_004	Load	31.00	2026-07-30	portal
2674	TAI_001	Collect	23.00	2026-07-23	portal
2675	TAI_001	Delivery	8.00	2026-07-23	portal
2676	TAI_001	Exchange	23.00	2026-07-23	portal
2677	TAI_001	Load	31.00	2026-07-30	portal
2702	TONG_002	Collect	23.00	2026-07-23	portal
2703	TONG_002	Delivery	8.00	2026-07-23	portal
2704	TONG_002	Exchange	23.00	2026-07-23	portal
2705	TONG_002	Load	31.00	2026-07-30	portal
2730	TONG_009	Collect	18.00	2026-07-23	portal
2731	TONG_009	Delivery	8.00	2026-07-23	portal
2732	TONG_009	Exchange	18.00	2026-07-23	portal
2733	TONG_009	Load	26.00	2026-07-30	portal
2758	WAH_003	Collect	18.00	2026-07-23	portal
2759	WAH_003	Delivery	8.00	2026-07-23	portal
2760	WAH_003	Exchange	18.00	2026-07-23	portal
2761	WAH_003	Load	26.00	2026-07-30	portal
2786	WIL_001	Collect	13.00	2026-07-23	portal
2787	WIL_001	Delivery	8.00	2026-07-23	portal
2788	WIL_001	Exchange	13.00	2026-07-23	portal
2789	WIL_001	Load	21.00	2026-07-30	portal
2630	STX_003	Collect	19.50	2026-07-23	portal
2631	STX_003	Delivery	8.00	2026-07-23	portal
2632	STX_003	Exchange	19.50	2026-07-23	portal
2633	STX_003	Load	27.50	2026-07-30	portal
2658	SUN_005	Collect	18.00	2026-07-23	portal
2659	SUN_005	Delivery	8.00	2026-07-23	portal
2660	SUN_005	Exchange	18.00	2026-07-23	portal
2661	SUN_005	Load	26.00	2026-07-30	portal
2678	TEC_001	Collect	23.00	2026-07-23	portal
2679	TEC_001	Delivery	8.00	2026-07-23	portal
2680	TEC_001	Exchange	23.00	2026-07-23	portal
2681	TEC_001	Load	31.00	2026-07-30	portal
2706	TONG_003	Collect	18.00	2026-07-23	portal
2707	TONG_003	Delivery	8.00	2026-07-23	portal
2708	TONG_003	Exchange	18.00	2026-07-23	portal
2709	TONG_003	Load	26.00	2026-07-30	portal
2734	TOP_001	Collect	23.00	2026-07-23	portal
2735	TOP_001	Delivery	8.00	2026-07-23	portal
2736	TOP_001	Exchange	23.00	2026-07-23	portal
2737	TOP_001	Load	31.00	2026-07-30	portal
2762	WAH_004	Collect	23.00	2026-07-23	portal
2763	WAH_004	Delivery	8.00	2026-07-23	portal
2764	WAH_004	Exchange	23.00	2026-07-23	portal
2765	WAH_004	Load	31.00	2026-07-30	portal
2790	WOR_001	Collect	23.00	2026-07-23	portal
2791	WOR_001	Delivery	8.00	2026-07-23	portal
2792	WOR_001	Exchange	23.00	2026-07-23	portal
2793	WOR_001	Load	31.00	2026-07-30	portal
1650	LIR_001	Delivery	8.00	2026-07-23	sheet
1651	LIR_001	Sell	13.00	2026-07-23	sheet
2634	STX_004	Collect	13.00	2026-07-23	portal
2635	STX_004	Delivery	8.00	2026-07-23	portal
2636	STX_004	Exchange	13.00	2026-07-23	portal
2637	STX_004	Load	21.00	2026-07-30	portal
2662	SYS_001	Collect	18.00	2026-07-23	portal
2663	SYS_001	Delivery	8.00	2026-07-23	portal
2664	SYS_001	Exchange	18.00	2026-07-23	portal
2665	SYS_001	Load	26.00	2026-07-30	portal
2682	TECH_001	Collect	23.00	2026-07-23	portal
2683	TECH_001	Delivery	8.00	2026-07-23	portal
2684	TECH_001	Exchange	23.00	2026-07-23	portal
2685	TECH_001	Load	31.00	2026-07-30	portal
2710	TONG_004	Collect	13.00	2026-07-23	portal
2711	TONG_004	Delivery	8.00	2026-07-23	portal
2712	TONG_004	Exchange	13.00	2026-07-23	portal
2713	TONG_004	Load	21.00	2026-07-30	portal
2738	TRA_001	Collect	18.00	2026-07-23	portal
2739	TRA_001	Delivery	8.00	2026-07-23	portal
2740	TRA_001	Exchange	18.00	2026-07-23	portal
2741	TRA_001	Load	26.00	2026-07-30	portal
2766	WAH_005	Collect	18.00	2026-07-23	portal
2767	WAH_005	Delivery	8.00	2026-07-23	portal
2768	WAH_005	Exchange	18.00	2026-07-23	portal
2769	WAH_005	Load	26.00	2026-07-30	portal
2794	WRA_001	Collect	23.00	2026-07-23	portal
2795	WRA_001	Delivery	8.00	2026-07-23	portal
2796	WRA_001	Exchange	23.00	2026-07-23	portal
2797	WRA_001	Load	31.00	2026-07-30	portal
2638	SUM_001	Collect	13.00	2026-07-23	portal
2639	SUM_001	Delivery	8.00	2026-07-23	portal
2640	SUM_001	Exchange	13.00	2026-07-23	portal
2641	SUM_001	Load	21.00	2026-07-30	portal
2666	SYST_001	Collect	13.00	2026-07-23	portal
2667	SYST_001	Delivery	8.00	2026-07-23	portal
2668	SYST_001	Exchange	13.00	2026-07-23	portal
1985	ACR_004	Collect	23.00	2026-07-23	portal
1986	ACR_004	Delivery	8.00	2026-07-23	portal
1987	ACR_004	Exchange	23.00	2026-07-23	portal
1988	ACR_004	Load	31.00	2026-07-30	portal
2013	APE_001	Collect	13.00	2026-07-23	portal
2014	APE_001	Delivery	8.00	2026-07-23	portal
2015	APE_001	Exchange	13.00	2026-07-23	portal
2016	APE_001	Load	21.00	2026-07-30	portal
2041	BAB_001	Collect	18.00	2026-07-23	portal
2042	BAB_001	Delivery	8.00	2026-07-23	portal
2043	BAB_001	Exchange	18.00	2026-07-23	portal
2044	BAB_001	Load	26.00	2026-07-30	portal
2069	BCW_004	Collect	18.00	2026-07-23	portal
2070	BCW_004	Delivery	8.00	2026-07-23	portal
2071	BCW_004	Exchange	18.00	2026-07-23	portal
2072	BCW_004	Load	26.00	2026-07-30	portal
2097	BND_004	Collect	13.00	2026-07-23	portal
2098	BND_004	Delivery	8.00	2026-07-23	portal
2099	BND_004	Exchange	13.00	2026-07-23	portal
2100	BND_004	Load	21.00	2026-07-30	portal
2125	CHI_001	Collect	23.00	2026-07-23	portal
2126	CHI_001	Delivery	8.00	2026-07-23	portal
2127	CHI_001	Exchange	23.00	2026-07-23	portal
2128	CHI_001	Load	31.00	2026-07-30	portal
2153	CRE_001	Collect	13.00	2026-07-23	portal
2154	CRE_001	Delivery	8.00	2026-07-23	portal
2155	CRE_001	Exchange	13.00	2026-07-23	portal
2156	CRE_001	Load	21.00	2026-07-30	portal
2173	ENGI_002	Collect	23.00	2026-07-23	portal
2174	ENGI_002	Delivery	8.00	2026-07-23	portal
2175	ENGI_002	Exchange	23.00	2026-07-23	portal
2176	ENGI_002	Load	31.00	2026-07-30	portal
2201	ENGI_009	Collect	13.00	2026-07-23	portal
2202	ENGI_009	Delivery	8.00	2026-07-23	portal
2203	ENGI_009	Exchange	13.00	2026-07-23	portal
2204	ENGI_009	Load	21.00	2026-07-30	portal
2229	ENGI_016	Collect	23.00	2026-07-23	portal
2230	ENGI_016	Delivery	8.00	2026-07-23	portal
2231	ENGI_016	Exchange	23.00	2026-07-23	portal
2232	ENGI_016	Load	31.00	2026-07-30	portal
2257	ENGL_005	Collect	13.00	2026-07-23	portal
2258	ENGL_005	Delivery	8.00	2026-07-23	portal
2259	ENGL_005	Exchange	13.00	2026-07-23	portal
2260	ENGL_005	Load	21.00	2026-07-30	portal
2285	EPO_001	Collect	13.00	2026-07-23	portal
2286	EPO_001	Delivery	8.00	2026-07-23	portal
2287	EPO_001	Exchange	13.00	2026-07-23	portal
2288	EPO_001	Load	21.00	2026-07-30	portal
2313	GLO_001	Collect	13.00	2026-07-23	portal
2314	GLO_001	Delivery	8.00	2026-07-23	portal
2315	GLO_001	Exchange	13.00	2026-07-23	portal
2316	GLO_001	Load	21.00	2026-07-30	portal
2341	GSE_007	Collect	23.00	2026-07-23	portal
2342	GSE_007	Delivery	8.00	2026-07-23	portal
2343	GSE_007	Exchange	23.00	2026-07-23	portal
2344	GSE_007	Load	31.00	2026-07-30	portal
2369	HEP_002	Collect	23.00	2026-07-23	portal
2370	HEP_002	Delivery	8.00	2026-07-23	portal
2371	HEP_002	Exchange	23.00	2026-07-23	portal
2372	HEP_002	Load	31.00	2026-07-30	portal
2397	HYD_001	Collect	13.00	2026-07-23	portal
2398	HYD_001	Delivery	8.00	2026-07-23	portal
2399	HYD_001	Exchange	13.00	2026-07-23	portal
2669	SYST_001	Load	21.00	2026-07-30	portal
2686	TECK_001	Collect	13.00	2026-07-23	portal
2687	TECK_001	Delivery	8.00	2026-07-23	portal
2688	TECK_001	Exchange	13.00	2026-07-23	portal
2689	TECK_001	Load	21.00	2026-07-30	portal
2714	TONG_005	Collect	23.00	2026-07-23	portal
2715	TONG_005	Delivery	8.00	2026-07-23	portal
2716	TONG_005	Exchange	23.00	2026-07-23	portal
2717	TONG_005	Load	31.00	2026-07-30	portal
2742	TST_001	Collect	13.00	2026-07-23	portal
2743	TST_001	Delivery	8.00	2026-07-23	portal
2744	TST_001	Exchange	13.00	2026-07-23	portal
2745	TST_001	Load	21.00	2026-07-30	portal
2770	WAH_006	Collect	23.00	2026-07-23	portal
2771	WAH_006	Delivery	8.00	2026-07-23	portal
2772	WAH_006	Exchange	23.00	2026-07-23	portal
2773	WAH_006	Load	31.00	2026-07-30	portal
2798	WRA_002	Collect	13.00	2026-07-23	portal
2799	WRA_002	Delivery	8.00	2026-07-23	portal
2800	WRA_002	Exchange	13.00	2026-07-23	portal
2801	WRA_002	Load	21.00	2026-07-30	portal
2642	SUN_001	Collect	18.00	2026-07-23	portal
2643	SUN_001	Delivery	8.00	2026-07-23	portal
2644	SUN_001	Exchange	18.00	2026-07-23	portal
2645	SUN_001	Load	26.00	2026-07-30	portal
2670	SYST_002	Collect	13.00	2026-07-23	portal
2671	SYST_002	Delivery	8.00	2026-07-23	portal
2672	SYST_002	Exchange	13.00	2026-07-23	portal
2673	SYST_002	Load	21.00	2026-07-30	portal
1989	ADV_001	Collect	13.00	2026-07-23	portal
1990	ADV_001	Delivery	8.00	2026-07-23	portal
1991	ADV_001	Exchange	13.00	2026-07-23	portal
1992	ADV_001	Load	21.00	2026-07-30	portal
2017	APE_002	Collect	13.00	2026-07-23	portal
2018	APE_002	Delivery	8.00	2026-07-23	portal
2019	APE_002	Exchange	13.00	2026-07-23	portal
2020	APE_002	Load	21.00	2026-07-30	portal
2045	BAB_002	Collect	23.00	2026-07-23	portal
2046	BAB_002	Delivery	8.00	2026-07-23	portal
2047	BAB_002	Exchange	23.00	2026-07-23	portal
2048	BAB_002	Load	31.00	2026-07-30	portal
2073	BCW_005	Collect	23.00	2026-07-23	portal
2074	BCW_005	Delivery	8.00	2026-07-23	portal
2075	BCW_005	Exchange	23.00	2026-07-23	portal
2076	BCW_005	Load	31.00	2026-07-30	portal
2101	CAL_001	Collect	18.00	2026-07-23	portal
2102	CAL_001	Delivery	8.00	2026-07-23	portal
2103	CAL_001	Exchange	18.00	2026-07-23	portal
2104	CAL_001	Load	26.00	2026-07-30	portal
2129	CHI_002	Collect	23.00	2026-07-23	portal
2130	CHI_002	Delivery	8.00	2026-07-23	portal
2131	CHI_002	Exchange	23.00	2026-07-23	portal
2132	CHI_002	Load	31.00	2026-07-30	portal
2157	DSV_001	Collect	13.00	2026-07-23	portal
2158	DSV_001	Delivery	8.00	2026-07-23	portal
2159	DSV_001	Exchange	13.00	2026-07-23	portal
2160	DSV_001	Load	21.00	2026-07-30	portal
2177	ENGI_003	Collect	13.00	2026-07-23	portal
2178	ENGI_003	Delivery	8.00	2026-07-23	portal
2179	ENGI_003	Exchange	13.00	2026-07-23	portal
2180	ENGI_003	Load	21.00	2026-07-30	portal
2205	ENGI_010	Collect	13.00	2026-07-23	portal
2206	ENGI_010	Delivery	8.00	2026-07-23	portal
2207	ENGI_010	Exchange	13.00	2026-07-23	portal
2208	ENGI_010	Load	21.00	2026-07-30	portal
2233	ENGI_017	Collect	23.00	2026-07-23	portal
2234	ENGI_017	Delivery	8.00	2026-07-23	portal
2235	ENGI_017	Exchange	23.00	2026-07-23	portal
2236	ENGI_017	Load	31.00	2026-07-30	portal
2261	ENGL_006	Collect	13.00	2026-07-23	portal
2262	ENGL_006	Delivery	8.00	2026-07-23	portal
2263	ENGL_006	Exchange	13.00	2026-07-23	portal
2264	ENGL_006	Load	21.00	2026-07-30	portal
2289	EUR_001	Collect	13.00	2026-07-23	portal
2290	EUR_001	Delivery	8.00	2026-07-23	portal
2291	EUR_001	Exchange	13.00	2026-07-23	portal
2292	EUR_001	Load	21.00	2026-07-30	portal
2317	GSE_001	Collect	13.00	2026-07-23	portal
2318	GSE_001	Delivery	8.00	2026-07-23	portal
2319	GSE_001	Exchange	13.00	2026-07-23	portal
2320	GSE_001	Load	21.00	2026-07-30	portal
2345	GWC_001	Collect	13.00	2026-07-23	portal
2346	GWC_001	Delivery	8.00	2026-07-23	portal
2347	GWC_001	Exchange	13.00	2026-07-23	portal
2348	GWC_001	Load	21.00	2026-07-30	portal
2373	HEP_003	Collect	23.00	2026-07-23	portal
2374	HEP_003	Delivery	8.00	2026-07-23	portal
2375	HEP_003	Exchange	23.00	2026-07-23	portal
2376	HEP_003	Load	31.00	2026-07-30	portal
2401	HYU_001	Collect	23.00	2026-07-23	portal
2402	HYU_001	Delivery	8.00	2026-07-23	portal
2403	HYU_001	Exchange	23.00	2026-07-23	portal
2404	HYU_001	Load	31.00	2026-07-30	portal
2430	LEX_001	Collect	13.00	2026-07-23	portal
2431	LEX_001	Delivery	8.00	2026-07-23	portal
2432	LEX_001	Exchange	13.00	2026-07-23	portal
2433	LEX_001	Load	21.00	2026-07-30	portal
2482	RAD_002	Collect	13.00	2026-07-23	portal
2483	RAD_002	Delivery	8.00	2026-07-23	portal
2484	RAD_002	Exchange	13.00	2026-07-23	portal
2485	RAD_002	Load	21.00	2026-07-30	portal
2510	SAV_003	Collect	13.00	2026-07-23	portal
2511	SAV_003	Delivery	8.00	2026-07-23	portal
2512	SAV_003	Exchange	13.00	2026-07-23	portal
2513	SAV_003	Load	21.00	2026-07-30	portal
2538	SEA_001	Collect	23.00	2026-07-23	portal
2539	SEA_001	Delivery	8.00	2026-07-23	portal
2540	SEA_001	Exchange	23.00	2026-07-23	portal
2541	SEA_001	Load	31.00	2026-07-30	portal
2548	SHI_002	Exchange	13.00	2026-07-29	portal
2549	SHI_002	Load	21.00	2026-07-30	portal
2566	SINH_001	Collect	23.00	2026-07-23	portal
2567	SINH_001	Delivery	8.00	2026-07-23	portal
2568	SINH_001	Exchange	23.00	2026-07-23	portal
2569	SINH_001	Load	31.00	2026-07-30	portal
2574	SLS_002	Collect	13.00	2026-07-23	portal
2575	SLS_002	Delivery	8.00	2026-07-23	portal
2576	SLS_002	Exchange	13.00	2026-07-23	portal
2577	SLS_002	Load	21.00	2026-07-30	portal
2578	SNI_001	Collect	23.00	2026-07-23	portal
2579	SNI_001	Delivery	8.00	2026-07-23	portal
2580	SNI_001	Exchange	23.00	2026-07-23	portal
2581	SNI_001	Load	31.00	2026-07-30	portal
2591	SPR_003	Delivery	8.00	2026-07-23	portal
2592	SPR_003	Exchange	23.00	2026-07-23	portal
2593	SPR_003	Load	31.00	2026-07-30	portal
2594	STA_001	Collect	23.00	2026-07-23	portal
2595	STA_001	Delivery	8.00	2026-07-23	portal
2596	STA_001	Exchange	23.00	2026-07-23	portal
2597	STA_001	Load	31.00	2026-07-30	portal
2598	STS_001	Collect	23.00	2026-07-23	portal
1965	ABS_001	Collect	23.00	2026-07-23	portal
1966	ABS_001	Delivery	8.00	2026-07-23	portal
1967	ABS_001	Exchange	23.00	2026-07-23	portal
1968	ABS_001	Load	31.00	2026-07-30	portal
1993	AJK_001	Collect	13.00	2026-07-23	portal
1994	AJK_001	Delivery	8.00	2026-07-23	portal
1995	AJK_001	Exchange	13.00	2026-07-23	portal
1996	AJK_001	Load	21.00	2026-07-30	portal
2021	ARC_001	Collect	18.00	2026-07-23	portal
2022	ARC_001	Delivery	8.00	2026-07-23	portal
2023	ARC_001	Exchange	18.00	2026-07-23	portal
2024	ARC_001	Load	26.00	2026-07-30	portal
2049	BAB_003	Collect	23.00	2026-07-23	portal
2050	BAB_003	Delivery	8.00	2026-07-23	portal
2051	BAB_003	Exchange	23.00	2026-07-23	portal
2052	BAB_003	Load	31.00	2026-07-30	portal
2077	BCW_006	Collect	23.00	2026-07-23	portal
2078	BCW_006	Delivery	8.00	2026-07-23	portal
2079	BCW_006	Exchange	23.00	2026-07-23	portal
2080	BCW_006	Load	31.00	2026-07-30	portal
2105	CAR_001	Collect	13.00	2026-07-23	portal
2106	CAR_001	Delivery	8.00	2026-07-23	portal
2107	CAR_001	Exchange	13.00	2026-07-23	portal
2108	CAR_001	Load	21.00	2026-07-30	portal
2133	CHI_003	Collect	13.00	2026-07-23	portal
2134	CHI_003	Delivery	8.00	2026-07-23	portal
2135	CHI_003	Exchange	13.00	2026-07-23	portal
2136	CHI_003	Load	21.00	2026-07-30	portal
2169	ENGI_001	Collect	23.00	2026-07-23	portal
2170	ENGI_001	Delivery	8.00	2026-07-23	portal
2171	ENGI_001	Exchange	23.00	2026-07-23	portal
2172	ENGI_001	Load	31.00	2026-07-30	portal
2197	ENGI_008	Collect	23.00	2026-07-23	portal
2198	ENGI_008	Delivery	8.00	2026-07-23	portal
2199	ENGI_008	Exchange	23.00	2026-07-23	portal
2200	ENGI_008	Load	31.00	2026-07-30	portal
2225	ENGI_015	Collect	13.00	2026-07-23	portal
2226	ENGI_015	Delivery	8.00	2026-07-23	portal
2227	ENGI_015	Exchange	13.00	2026-07-23	portal
2228	ENGI_015	Load	21.00	2026-07-30	portal
2247	ENGL_002	Exchange	13.00	2026-07-23	portal
2248	ENGL_002	Load	21.00	2026-07-30	portal
2253	ENGL_004	Collect	13.00	2026-07-23	portal
2254	ENGL_004	Delivery	8.00	2026-07-23	portal
2255	ENGL_004	Exchange	13.00	2026-07-23	portal
2256	ENGL_004	Load	21.00	2026-07-30	portal
2273	ENGL_009	Collect	13.00	2026-07-23	portal
2274	ENGL_009	Delivery	8.00	2026-07-23	portal
2275	ENGL_009	Exchange	13.00	2026-07-23	portal
2276	ENGL_009	Load	21.00	2026-07-30	portal
2281	ENGL_011	Collect	13.00	2026-07-23	portal
2282	ENGL_011	Delivery	8.00	2026-07-23	portal
2283	ENGL_011	Exchange	13.00	2026-07-23	portal
2284	ENGL_011	Load	21.00	2026-07-30	portal
2301	EXP_001	Collect	23.00	2026-07-29	portal
2302	EXP_001	Delivery	8.00	2026-07-29	portal
2303	EXP_001	Exchange	23.00	2026-07-29	portal
2304	EXP_001	Load	31.00	2026-07-30	portal
2309	GEO_001	Collect	23.00	2026-07-23	portal
2310	GEO_001	Delivery	8.00	2026-07-23	portal
2311	GEO_001	Exchange	23.00	2026-07-23	portal
2312	GEO_001	Load	31.00	2026-07-30	portal
2329	GSE_004	Collect	23.00	2026-07-23	portal
2330	GSE_004	Delivery	8.00	2026-07-23	portal
2331	GSE_004	Exchange	23.00	2026-07-23	portal
2332	GSE_004	Load	31.00	2026-07-30	portal
2337	GSE_006	Collect	23.00	2026-07-23	portal
2338	GSE_006	Delivery	8.00	2026-07-23	portal
2339	GSE_006	Exchange	23.00	2026-07-23	portal
2340	GSE_006	Load	31.00	2026-07-30	portal
2357	HCG_001	Collect	13.00	2026-07-23	portal
2358	HCG_001	Delivery	8.00	2026-07-23	portal
2359	HCG_001	Exchange	13.00	2026-07-23	portal
2360	HCG_001	Load	21.00	2026-07-30	portal
2365	HEP_001	Collect	23.00	2026-07-23	portal
2366	HEP_001	Delivery	8.00	2026-07-23	portal
2367	HEP_001	Exchange	23.00	2026-07-23	portal
2368	HEP_001	Load	31.00	2026-07-30	portal
2385	HPR_001	Collect	23.00	2026-07-23	portal
2386	HPR_001	Delivery	8.00	2026-07-23	portal
2387	HPR_001	Exchange	23.00	2026-07-23	portal
2388	HPR_001	Load	31.00	2026-07-30	portal
2393	HUN_001	Collect	23.00	2026-07-23	portal
2394	HUN_001	Delivery	8.00	2026-07-23	portal
2395	HUN_001	Exchange	23.00	2026-07-23	portal
2396	HUN_001	Load	31.00	2026-07-30	portal
2414	IWA_001	Collect	13.00	2026-07-23	portal
2415	IWA_001	Delivery	8.00	2026-07-23	portal
2416	IWA_001	Exchange	13.00	2026-07-23	portal
2417	IWA_001	Load	21.00	2026-07-30	portal
2422	LCH_001	Collect	13.00	2026-07-23	portal
2423	LCH_001	Delivery	8.00	2026-07-23	portal
2424	LCH_001	Exchange	13.00	2026-07-23	portal
2425	LCH_001	Load	21.00	2026-07-30	portal
2442	MEC_001	Collect	13.00	2026-07-23	portal
2443	MEC_001	Delivery	8.00	2026-07-23	portal
2444	MEC_001	Exchange	13.00	2026-07-23	portal
2445	MEC_001	Load	21.00	2026-07-30	portal
2454	POH_001	Collect	13.00	2026-07-23	portal
2455	POH_001	Delivery	8.00	2026-07-23	portal
2456	POH_001	Exchange	13.00	2026-07-23	portal
2457	POH_001	Load	21.00	2026-07-30	portal
2466	POH_004	Collect	13.00	2026-07-23	portal
2467	POH_004	Delivery	8.00	2026-07-23	portal
2468	POH_004	Exchange	13.00	2026-07-23	portal
2469	POH_004	Load	21.00	2026-07-30	portal
2474	QUA_001	Collect	13.00	2026-07-23	portal
2475	QUA_001	Delivery	8.00	2026-07-23	portal
2476	QUA_001	Exchange	13.00	2026-07-23	portal
2477	QUA_001	Load	21.00	2026-07-30	portal
2690	TOH_001	Collect	23.00	2026-07-23	portal
2691	TOH_001	Delivery	8.00	2026-07-23	portal
2692	TOH_001	Exchange	23.00	2026-07-23	portal
1969	ABS_002	Collect	23.00	2026-07-23	portal
1970	ABS_002	Delivery	8.00	2026-07-23	portal
1971	ABS_002	Exchange	23.00	2026-07-23	portal
1972	ABS_002	Load	31.00	2026-07-30	portal
1997	ALL_001	Collect	13.00	2026-07-23	portal
1998	ALL_001	Delivery	8.00	2026-07-23	portal
1999	ALL_001	Exchange	13.00	2026-07-23	portal
2000	ALL_001	Load	21.00	2026-07-30	portal
2025	ART_001	Collect	23.00	2026-07-23	portal
2026	ART_001	Delivery	8.00	2026-07-23	portal
2027	ART_001	Exchange	23.00	2026-07-23	portal
2028	ART_001	Load	31.00	2026-07-30	portal
2053	BAB_004	Collect	23.00	2026-07-23	portal
2054	BAB_004	Delivery	8.00	2026-07-23	portal
2055	BAB_004	Exchange	23.00	2026-07-23	portal
2056	BAB_004	Load	31.00	2026-07-30	portal
2081	BCW_007	Collect	23.00	2026-07-23	portal
2082	BCW_007	Delivery	8.00	2026-07-23	portal
2083	BCW_007	Exchange	23.00	2026-07-23	portal
2084	BCW_007	Load	31.00	2026-07-30	portal
2109	CAT_001	Collect	18.00	2026-07-23	portal
2110	CAT_001	Delivery	8.00	2026-07-23	portal
2111	CAT_001	Exchange	18.00	2026-07-23	portal
2112	CAT_001	Load	26.00	2026-07-30	portal
2137	CHU_001	Collect	23.00	2026-07-23	portal
2138	CHU_001	Delivery	8.00	2026-07-23	portal
2139	CHU_001	Exchange	23.00	2026-07-23	portal
2140	CHU_001	Load	31.00	2026-07-30	portal
2185	ENGI_005	Collect	18.00	2026-07-23	portal
2186	ENGI_005	Delivery	8.00	2026-07-23	portal
2187	ENGI_005	Exchange	18.00	2026-07-23	portal
2188	ENGI_005	Load	26.00	2026-07-30	portal
2213	ENGI_012	Collect	23.00	2026-07-23	portal
2214	ENGI_012	Delivery	8.00	2026-07-23	portal
2215	ENGI_012	Exchange	23.00	2026-07-23	portal
2216	ENGI_012	Load	31.00	2026-07-30	portal
2241	ENGL_001	Collect	13.00	2026-07-23	portal
2242	ENGL_001	Delivery	8.00	2026-07-23	portal
2243	ENGL_001	Exchange	13.00	2026-07-23	portal
2244	ENGL_001	Load	21.00	2026-07-30	portal
2269	ENGL_008	Collect	13.00	2026-07-23	portal
2270	ENGL_008	Delivery	8.00	2026-07-23	portal
2271	ENGL_008	Exchange	13.00	2026-07-23	portal
2272	ENGL_008	Load	21.00	2026-07-30	portal
2297	EVE_001	Collect	13.00	2026-07-23	portal
2298	EVE_001	Delivery	8.00	2026-07-23	portal
2299	EVE_001	Exchange	13.00	2026-07-23	portal
2300	EVE_001	Load	21.00	2026-07-30	portal
2325	GSE_003	Collect	23.00	2026-07-23	portal
2326	GSE_003	Delivery	8.00	2026-07-23	portal
2327	GSE_003	Exchange	23.00	2026-07-23	portal
2328	GSE_003	Load	31.00	2026-07-30	portal
2353	HAI_001	Collect	13.00	2026-07-23	portal
2354	HAI_001	Delivery	8.00	2026-07-23	portal
2355	HAI_001	Exchange	13.00	2026-07-23	portal
2356	HAI_001	Load	21.00	2026-07-30	portal
2381	HOT_001	Collect	23.00	2026-07-23	portal
2382	HOT_001	Delivery	8.00	2026-07-23	portal
2383	HOT_001	Exchange	23.00	2026-07-23	portal
2384	HOT_001	Load	31.00	2026-07-30	portal
2400	HYD_001	Load	21.00	2026-07-30	portal
2410	INV_001	Collect	13.00	2026-07-23	portal
2411	INV_001	Delivery	8.00	2026-07-23	portal
2412	INV_001	Exchange	13.00	2026-07-23	portal
2413	INV_001	Load	21.00	2026-07-30	portal
2426	LEN_001	Collect	13.00	2026-07-23	portal
2427	LEN_001	Delivery	8.00	2026-07-23	portal
2428	LEN_001	Exchange	13.00	2026-07-23	portal
2429	LEN_001	Load	21.00	2026-07-30	portal
2438	MAT_001	Collect	13.00	2026-07-23	portal
2439	MAT_001	Delivery	8.00	2026-07-23	portal
2440	MAT_001	Exchange	13.00	2026-07-23	portal
2441	MAT_001	Load	21.00	2026-07-30	portal
2446	NEA_001	Collect	13.00	2026-07-23	portal
2447	NEA_001	Delivery	8.00	2026-07-23	portal
2448	NEA_001	Exchange	13.00	2026-07-23	portal
2449	NEA_001	Load	21.00	2026-07-30	portal
2450	PAX_001	Collect	13.00	2026-07-23	portal
2451	PAX_001	Delivery	8.00	2026-07-23	portal
2452	PAX_001	Exchange	13.00	2026-07-23	portal
2453	PAX_001	Load	21.00	2026-07-30	portal
2462	POH_003	Collect	13.00	2026-07-23	portal
2463	POH_003	Delivery	8.00	2026-07-23	portal
2464	POH_003	Exchange	13.00	2026-07-23	portal
2465	POH_003	Load	21.00	2026-07-30	portal
2470	PSA_001	Collect	13.00	2026-07-23	portal
2471	PSA_001	Delivery	8.00	2026-07-23	portal
2472	PSA_001	Exchange	13.00	2026-07-23	portal
2473	PSA_001	Load	21.00	2026-07-30	portal
2490	RAD_004	Collect	13.00	2026-07-23	portal
2491	RAD_004	Delivery	8.00	2026-07-23	portal
2492	RAD_004	Exchange	13.00	2026-07-23	portal
2493	RAD_004	Load	21.00	2026-07-30	portal
2498	RJH_001	Collect	23.00	2026-07-23	portal
2499	RJH_001	Delivery	8.00	2026-07-23	portal
2500	RJH_001	Exchange	23.00	2026-07-23	portal
2501	RJH_001	Load	31.00	2026-07-30	portal
2518	SAVI_001	Collect	13.00	2026-07-23	portal
2519	SAVI_001	Delivery	8.00	2026-07-23	portal
2520	SAVI_001	Exchange	13.00	2026-07-23	portal
2521	SAVI_001	Load	21.00	2026-07-30	portal
2526	SAVI_003	Collect	13.00	2026-07-23	portal
2527	SAVI_003	Delivery	8.00	2026-07-23	portal
2528	SAVI_003	Exchange	13.00	2026-07-23	portal
2529	SAVI_003	Load	21.00	2026-07-30	portal
2546	SHI_002	Collect	13.00	2026-07-29	portal
2547	SHI_002	Delivery	8.00	2026-07-29	portal
2693	TOH_001	Load	31.00	2026-07-30	portal
2718	TONG_006	Collect	13.00	2026-07-23	portal
2719	TONG_006	Delivery	8.00	2026-07-23	portal
1973	ACR_001	Collect	23.00	2026-07-23	portal
1974	ACR_001	Delivery	8.00	2026-07-23	portal
1975	ACR_001	Exchange	23.00	2026-07-23	portal
1976	ACR_001	Load	31.00	2026-07-30	portal
2001	ALLI_001	Collect	13.00	2026-07-23	portal
2002	ALLI_001	Delivery	8.00	2026-07-23	portal
2003	ALLI_001	Exchange	13.00	2026-07-23	portal
2004	ALLI_001	Load	21.00	2026-07-30	portal
2029	ASL_001	Collect	13.00	2026-07-23	portal
2030	ASL_001	Delivery	8.00	2026-07-23	portal
2031	ASL_001	Exchange	13.00	2026-07-23	portal
2032	ASL_001	Load	21.00	2026-07-30	portal
2057	BCW_001	Collect	13.00	2026-07-23	portal
2058	BCW_001	Delivery	8.00	2026-07-23	portal
2059	BCW_001	Exchange	13.00	2026-07-23	portal
2060	BCW_001	Load	21.00	2026-07-30	portal
2085	BND_001	Collect	13.00	2026-07-23	portal
2086	BND_001	Delivery	8.00	2026-07-23	portal
2087	BND_001	Exchange	13.00	2026-07-23	portal
2088	BND_001	Load	21.00	2026-07-30	portal
2113	CAT_002	Collect	18.00	2026-07-23	portal
2114	CAT_002	Delivery	8.00	2026-07-23	portal
2115	CAT_002	Exchange	18.00	2026-07-23	portal
2116	CAT_002	Load	26.00	2026-07-30	portal
2141	CLE_001	Collect	13.00	2026-07-23	portal
2142	CLE_001	Delivery	8.00	2026-07-23	portal
2143	CLE_001	Exchange	13.00	2026-07-23	portal
2144	CLE_001	Load	21.00	2026-07-30	portal
2161	DYN_001	Collect	13.00	2026-07-23	portal
2162	DYN_001	Delivery	8.00	2026-07-23	portal
2163	DYN_001	Exchange	13.00	2026-07-23	portal
2164	DYN_001	Load	21.00	2026-07-30	portal
2181	ENGI_004	Collect	23.00	2026-07-23	portal
2182	ENGI_004	Delivery	8.00	2026-07-23	portal
2183	ENGI_004	Exchange	23.00	2026-07-23	portal
2184	ENGI_004	Load	31.00	2026-07-30	portal
2209	ENGI_011	Collect	23.00	2026-07-23	portal
2210	ENGI_011	Delivery	8.00	2026-07-23	portal
2211	ENGI_011	Exchange	23.00	2026-07-23	portal
2212	ENGI_011	Load	31.00	2026-07-30	portal
2237	ENGI_018	Collect	23.00	2026-07-23	portal
2238	ENGI_018	Delivery	8.00	2026-07-23	portal
2239	ENGI_018	Exchange	23.00	2026-07-23	portal
2240	ENGI_018	Load	31.00	2026-07-30	portal
2265	ENGL_007	Collect	13.00	2026-07-23	portal
2266	ENGL_007	Delivery	8.00	2026-07-23	portal
2267	ENGL_007	Exchange	13.00	2026-07-23	portal
2268	ENGL_007	Load	21.00	2026-07-30	portal
2293	EUR_002	Collect	13.00	2026-07-23	portal
2294	EUR_002	Delivery	8.00	2026-07-23	portal
2295	EUR_002	Exchange	13.00	2026-07-23	portal
2296	EUR_002	Load	21.00	2026-07-30	portal
2321	GSE_002	Collect	23.00	2026-07-23	portal
2322	GSE_002	Delivery	8.00	2026-07-23	portal
2323	GSE_002	Exchange	23.00	2026-07-23	portal
2324	GSE_002	Load	31.00	2026-07-30	portal
2349	GYM_001	Collect	18.00	2026-07-23	portal
2350	GYM_001	Delivery	8.00	2026-07-23	portal
2351	GYM_001	Exchange	18.00	2026-07-23	portal
2352	GYM_001	Load	26.00	2026-07-30	portal
2377	HON_001	Collect	13.00	2026-07-23	portal
2378	HON_001	Delivery	8.00	2026-07-23	portal
2379	HON_001	Exchange	13.00	2026-07-23	portal
2380	HON_001	Load	21.00	2026-07-30	portal
2405	HYU_002	Collect	13.00	2026-07-29	portal
2406	HYU_002	Delivery	8.00	2026-07-29	portal
2407	HYU_002	Exchange	13.00	2026-07-29	portal
2408	HYU_002	Sell	8.00	2026-07-29	portal
2409	HYU_002	Load	21.00	2026-07-30	portal
2434	LIM_001	Collect	13.00	2026-07-23	portal
2435	LIM_001	Delivery	8.00	2026-07-23	portal
2436	LIM_001	Exchange	13.00	2026-07-23	portal
2437	LIM_001	Load	21.00	2026-07-30	portal
2458	POH_002	Collect	13.00	2026-07-23	portal
2459	POH_002	Delivery	8.00	2026-07-23	portal
2460	POH_002	Exchange	13.00	2026-07-23	portal
2461	POH_002	Load	21.00	2026-07-30	portal
2486	RAD_003	Collect	13.00	2026-07-29	portal
2487	RAD_003	Delivery	8.00	2026-07-29	portal
2488	RAD_003	Exchange	13.00	2026-07-29	portal
2489	RAD_003	Load	21.00	2026-07-30	portal
2494	REM_001	Collect	13.00	2026-07-23	portal
2495	REM_001	Delivery	8.00	2026-07-23	portal
2496	REM_001	Exchange	13.00	2026-07-23	portal
2497	REM_001	Load	21.00	2026-07-30	portal
2514	SAV_004	Collect	13.00	2026-07-23	portal
2515	SAV_004	Delivery	8.00	2026-07-23	portal
2516	SAV_004	Exchange	13.00	2026-07-23	portal
2517	SAV_004	Load	21.00	2026-07-30	portal
2522	SAVI_002	Collect	13.00	2026-07-23	portal
2523	SAVI_002	Delivery	8.00	2026-07-23	portal
2524	SAVI_002	Exchange	13.00	2026-07-23	portal
2525	SAVI_002	Load	21.00	2026-07-30	portal
2542	SHI_001	Collect	13.00	2026-07-23	portal
2543	SHI_001	Delivery	8.00	2026-07-23	portal
2544	SHI_001	Exchange	13.00	2026-07-23	portal
2545	SHI_001	Load	21.00	2026-07-30	portal
2550	SIE_001	Collect	13.00	2026-07-23	portal
2551	SIE_001	Delivery	8.00	2026-07-23	portal
2552	SIE_001	Exchange	13.00	2026-07-23	portal
2553	SIE_001	Load	21.00	2026-07-30	portal
2554	SIN_001	Collect	13.00	2026-07-23	portal
2555	SIN_001	Delivery	8.00	2026-07-23	portal
2556	SIN_001	Exchange	13.00	2026-07-23	portal
2557	SIN_001	Load	21.00	2026-07-30	portal
2570	SLS_001	Collect	13.00	2026-07-23	portal
2571	SLS_001	Delivery	8.00	2026-07-23	portal
2720	TONG_006	Exchange	13.00	2026-07-23	portal
2721	TONG_006	Load	21.00	2026-07-30	portal
2746	URB_001	Collect	23.00	2026-07-23	portal
1977	ACR_002	Collect	23.00	2026-07-23	portal
1978	ACR_002	Delivery	8.00	2026-07-23	portal
1979	ACR_002	Exchange	23.00	2026-07-23	portal
1980	ACR_002	Load	31.00	2026-07-30	portal
2005	ALLI_002	Collect	13.00	2026-07-23	portal
2006	ALLI_002	Delivery	8.00	2026-07-23	portal
2007	ALLI_002	Exchange	13.00	2026-07-23	portal
2008	ALLI_002	Load	21.00	2026-07-30	portal
2033	AST_001	Collect	23.00	2026-07-23	portal
2034	AST_001	Delivery	8.00	2026-07-23	portal
2035	AST_001	Exchange	23.00	2026-07-23	portal
2036	AST_001	Load	31.00	2026-07-30	portal
2061	BCW_002	Collect	23.00	2026-07-23	portal
2062	BCW_002	Delivery	8.00	2026-07-23	portal
2063	BCW_002	Exchange	23.00	2026-07-23	portal
2064	BCW_002	Load	31.00	2026-07-30	portal
2089	BND_002	Collect	13.00	2026-07-23	portal
2090	BND_002	Delivery	8.00	2026-07-23	portal
2091	BND_002	Exchange	13.00	2026-07-23	portal
2092	BND_002	Load	21.00	2026-07-30	portal
2117	CBM_001	Collect	18.00	2026-07-23	portal
2118	CBM_001	Delivery	8.00	2026-07-23	portal
2119	CBM_001	Exchange	18.00	2026-07-23	portal
2120	CBM_001	Load	26.00	2026-07-30	portal
2145	CNC_001	Collect	23.00	2026-07-23	portal
2146	CNC_001	Delivery	8.00	2026-07-23	portal
2147	CNC_001	Exchange	23.00	2026-07-23	portal
2148	CNC_001	Load	31.00	2026-07-30	portal
2165	ENG_001	Collect	13.00	2026-07-23	portal
2166	ENG_001	Delivery	8.00	2026-07-23	portal
2167	ENG_001	Exchange	13.00	2026-07-23	portal
2168	ENG_001	Load	21.00	2026-07-30	portal
2193	ENGI_007	Collect	23.00	2026-07-23	portal
2194	ENGI_007	Delivery	8.00	2026-07-23	portal
2195	ENGI_007	Exchange	23.00	2026-07-23	portal
2196	ENGI_007	Load	31.00	2026-07-30	portal
2221	ENGI_014	Collect	23.00	2026-07-23	portal
2222	ENGI_014	Delivery	8.00	2026-07-23	portal
2223	ENGI_014	Exchange	23.00	2026-07-23	portal
2224	ENGI_014	Load	31.00	2026-07-30	portal
2249	ENGL_003	Collect	13.00	2026-07-23	portal
2250	ENGL_003	Delivery	8.00	2026-07-23	portal
2251	ENGL_003	Exchange	13.00	2026-07-23	portal
2252	ENGL_003	Load	21.00	2026-07-30	portal
2277	ENGL_010	Collect	13.00	2026-07-23	portal
2278	ENGL_010	Delivery	8.00	2026-07-23	portal
2279	ENGL_010	Exchange	13.00	2026-07-23	portal
2280	ENGL_010	Load	21.00	2026-07-30	portal
2305	FAX_001	Collect	13.00	2026-07-23	portal
2306	FAX_001	Delivery	8.00	2026-07-23	portal
2307	FAX_001	Exchange	13.00	2026-07-23	portal
2308	FAX_001	Load	21.00	2026-07-30	portal
2333	GSE_005	Collect	23.00	2026-07-23	portal
2334	GSE_005	Delivery	8.00	2026-07-23	portal
2335	GSE_005	Exchange	23.00	2026-07-23	portal
2336	GSE_005	Load	31.00	2026-07-30	portal
2361	HCG_002	Collect	18.00	2026-07-23	portal
2362	HCG_002	Delivery	8.00	2026-07-23	portal
2363	HCG_002	Exchange	18.00	2026-07-23	portal
2364	HCG_002	Load	26.00	2026-07-30	portal
2389	HUA_001	Collect	23.00	2026-07-23	portal
2390	HUA_001	Delivery	8.00	2026-07-23	portal
2391	HUA_001	Exchange	23.00	2026-07-23	portal
2392	HUA_001	Load	31.00	2026-07-30	portal
2418	LAU_001	Collect	13.00	2026-07-23	portal
2419	LAU_001	Delivery	8.00	2026-07-23	portal
2420	LAU_001	Exchange	13.00	2026-07-23	portal
2421	LAU_001	Load	21.00	2026-07-30	portal
2478	RAD_001	Collect	13.00	2026-07-29	portal
2479	RAD_001	Delivery	8.00	2026-07-29	portal
2480	RAD_001	Exchange	13.00	2026-07-29	portal
2481	RAD_001	Load	21.00	2026-07-30	portal
2502	SAV_001	Collect	13.00	2026-07-23	portal
2503	SAV_001	Delivery	8.00	2026-07-23	portal
2504	SAV_001	Exchange	13.00	2026-07-23	portal
2505	SAV_001	Load	21.00	2026-07-30	portal
2506	SAV_002	Collect	13.00	2026-07-23	portal
2507	SAV_002	Delivery	8.00	2026-07-23	portal
2508	SAV_002	Exchange	13.00	2026-07-23	portal
2509	SAV_002	Load	21.00	2026-07-30	portal
2530	SAVI_004	Collect	13.00	2026-07-23	portal
2531	SAVI_004	Delivery	8.00	2026-07-23	portal
2532	SAVI_004	Exchange	13.00	2026-07-23	portal
2533	SAVI_004	Load	21.00	2026-07-30	portal
2534	SAVI_005	Collect	13.00	2026-07-23	portal
2535	SAVI_005	Delivery	8.00	2026-07-23	portal
2536	SAVI_005	Exchange	13.00	2026-07-23	portal
2537	SAVI_005	Load	21.00	2026-07-30	portal
2558	SIND_001	Collect	13.00	2026-07-23	portal
2559	SIND_001	Delivery	8.00	2026-07-23	portal
2560	SIND_001	Exchange	13.00	2026-07-23	portal
2561	SIND_001	Load	21.00	2026-07-30	portal
2562	SIND_002	Collect	18.00	2026-07-23	portal
2563	SIND_002	Delivery	8.00	2026-07-23	portal
2564	SIND_002	Exchange	18.00	2026-07-23	portal
2565	SIND_002	Load	26.00	2026-07-30	portal
2572	SLS_001	Exchange	13.00	2026-07-23	portal
2573	SLS_001	Load	21.00	2026-07-30	portal
2582	SPR_001	Collect	18.00	2026-07-23	portal
2583	SPR_001	Delivery	8.00	2026-07-23	portal
2584	SPR_001	Exchange	18.00	2026-07-23	portal
2585	SPR_001	Load	26.00	2026-07-30	portal
2586	SPR_002	Collect	13.00	2026-07-23	portal
2587	SPR_002	Delivery	8.00	2026-07-23	portal
2588	SPR_002	Exchange	13.00	2026-07-23	portal
2589	SPR_002	Load	21.00	2026-07-30	portal
2590	SPR_003	Collect	23.00	2026-07-23	portal
2747	URB_001	Delivery	8.00	2026-07-23	portal
1981	ACR_003	Collect	23.00	2026-07-23	portal
1982	ACR_003	Delivery	8.00	2026-07-23	portal
1983	ACR_003	Exchange	23.00	2026-07-23	portal
1984	ACR_003	Load	31.00	2026-07-30	portal
2009	ALLI_003	Collect	13.00	2026-07-23	portal
2010	ALLI_003	Delivery	8.00	2026-07-23	portal
2011	ALLI_003	Exchange	13.00	2026-07-23	portal
2012	ALLI_003	Load	21.00	2026-07-30	portal
2037	AVE_001	Collect	13.00	2026-07-23	portal
2038	AVE_001	Delivery	8.00	2026-07-23	portal
2039	AVE_001	Exchange	13.00	2026-07-23	portal
2040	AVE_001	Load	21.00	2026-07-30	portal
2065	BCW_003	Collect	23.00	2026-07-23	portal
2066	BCW_003	Delivery	8.00	2026-07-23	portal
2067	BCW_003	Exchange	23.00	2026-07-23	portal
2068	BCW_003	Load	31.00	2026-07-30	portal
2093	BND_003	Collect	13.00	2026-07-23	portal
2094	BND_003	Delivery	8.00	2026-07-23	portal
2095	BND_003	Exchange	13.00	2026-07-23	portal
2096	BND_003	Load	21.00	2026-07-30	portal
2121	CHA_001	Collect	13.00	2026-07-23	portal
2122	CHA_001	Delivery	8.00	2026-07-23	portal
2123	CHA_001	Exchange	13.00	2026-07-23	portal
2124	CHA_001	Load	21.00	2026-07-30	portal
2149	CPH_001	Collect	13.00	2026-07-23	portal
2150	CPH_001	Delivery	8.00	2026-07-23	portal
2151	CPH_001	Exchange	13.00	2026-07-23	portal
2152	CPH_001	Load	21.00	2026-07-30	portal
2189	ENGI_006	Collect	23.00	2026-07-23	portal
2190	ENGI_006	Delivery	8.00	2026-07-23	portal
2191	ENGI_006	Exchange	23.00	2026-07-23	portal
2192	ENGI_006	Load	31.00	2026-07-30	portal
2217	ENGI_013	Collect	23.00	2026-07-23	portal
2218	ENGI_013	Delivery	8.00	2026-07-23	portal
2219	ENGI_013	Exchange	23.00	2026-07-23	portal
2220	ENGI_013	Load	31.00	2026-07-30	portal
2245	ENGL_002	Collect	13.00	2026-07-23	portal
2246	ENGL_002	Delivery	8.00	2026-07-23	portal
2748	URB_001	Exchange	23.00	2026-07-23	portal
1890	TRE_001	Sell	13.00	2026-07-23	sheet
2749	URB_001	Load	31.00	2026-07-30	portal
2774	WAH_007	Collect	23.00	2026-07-23	portal
2775	WAH_007	Delivery	8.00	2026-07-23	portal
2776	WAH_007	Exchange	23.00	2026-07-23	portal
2777	WAH_007	Load	31.00	2026-07-30	portal
2599	STS_001	Delivery	8.00	2026-07-23	portal
2600	STS_001	Exchange	23.00	2026-07-23	portal
2601	STS_001	Load	31.00	2026-07-30	portal
2602	STS_002	Collect	23.00	2026-07-23	portal
2603	STS_002	Delivery	8.00	2026-07-23	portal
2604	STS_002	Exchange	23.00	2026-07-23	portal
2605	STS_002	Load	31.00	2026-07-30	portal
2606	STS_003	Collect	18.00	2026-07-23	portal
2607	STS_003	Delivery	8.00	2026-07-23	portal
2608	STS_003	Exchange	18.00	2026-07-23	portal
2609	STS_003	Load	26.00	2026-07-30	portal
2610	STS_004	Collect	13.00	2026-07-23	portal
2611	STS_004	Delivery	8.00	2026-07-23	portal
2612	STS_004	Exchange	13.00	2026-07-23	portal
2613	STS_004	Load	21.00	2026-07-30	portal
2614	STS_005	Collect	18.00	2026-07-23	portal
2615	STS_005	Delivery	8.00	2026-07-23	portal
2616	STS_005	Exchange	18.00	2026-07-23	portal
2617	STS_005	Load	26.00	2026-07-30	portal
\.


--
-- Data for Name: ref_lists; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.ref_lists (kind, value) FROM stdin;
waste	General Waste
waste	Wood Waste
waste	Metal Waste
waste	Plastic Waste
waste	Hardcore Waste
waste	Food Waste
waste	Vessel Waste
dump	Lirich Resources Pte Ltd
dump	NEA
dump	WDL
dump	Bee Joo
dump	Kim Hock
dump	Wah & Hua
dump	TRS Environment
bin_type	3 ft
bin_type	Compactor
\.


--
-- Data for Name: sites; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.sites (site_id, client_id, site_name, address, active, created_at, contact_name, contact_phone, contact_email) FROM stdin;
ABS_001	ABS	Absolut Properties Pte Ltd	163 Marine Parade Road, Marine Meadows Condo	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
ABS_002	ABS	Absolut Properties Pte Ltd	173 Jalan Loyang Besar, Ocean Front Suites Condo	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
AJK_001	AJK	AJK	24 Tuas Ave 8	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
AVE_001	AVE	Aver Asia (S) Pte Ltd	14 Benoi Place	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
BAB_001	BAB	Babu	80 Mandai Lake Road	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
BAB_002	BAB	Babu	Blk 5 Haig Road #07-463	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
BAB_003	BAB	Babu	900 Bedok North Road	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
BAB_004	BAB	Babu	2 Stadium Walk	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
BCW_001	BCW	B&C Waste	16 Gul Crescent	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
BCW_002	BCW	B&C Waste	513 Kampong Bahru Road Keppel Distripark	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
BCW_003	BCW	B&C Waste	Upper Changi Road, Summer Garden Condo	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
BCW_004	BCW	B&C Waste	2 Mandai Link	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
BCW_005	BCW	B&C Waste	Peck Seah Street	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
BCW_006	BCW	B&C Waste	7 Changi South Street 2	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
BCW_007	BCW	B&C Waste	26 Loyang Drive	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
BEE_001	BEE	Beejoo	5 Sungei Kadut Street 6	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
BND_001	BND	BNDC (Fairprice)	1 Buroh Lane L4	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
BND_002	BND	BNDC (Fairprice)	28 Tuas Ave 13	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
BND_003	BND	BNDC (Fairprice)	5 Joo Koon Circle	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
BND_004	BND	BNDC (Fairprice)	7 Sunview Road	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
CAL_001	CAL	Calvary Carpentry Pte Ltd	54 Senoko Road	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
CAR_001	CAR	Cargo International	20 Gul Way, #05-04	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
CAT_001	CAT	Caterpillar	14 Tractor Road	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
CAT_002	CAT	Caterpillar	7 Tractor Road	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
CBM_001	CBM	CBM Pte Ltd	501 Old Choa Chu Kang Road, Home Team Academy	t	2026-07-24 15:15:51.944859+00	Rizab	8019 5329	\N
CHA_001	CHA	Chateraise	8 Jalan Besut L3	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
CHI_001	CHI	Chiong Construction	10 Serangoon Ave 4	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
CHI_002	CHI	Chiong Construction	13 Serangoon Ave 3	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
CHI_003	CHI	Chiong Construction	60 Blk A Jurong West Street 42	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
CHU_001	CHU	Chuan Seng Leong	21 Benoi Sector #03-03	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
CLE_001	CLE	Cleanis-Tee	8 Jalan Papan	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
CNC_001	CNC	CNCCS Engineering and Construction Pte Ltd	15 Tembusu Crescent, #08-01, COGENT.	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
CPH_001	CPH	C & P Holdings Pte Ltd	46 Penjuru Lane	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
CRE_001	CRE	CrestSA Marine & Offshore Pte Ltd	15 Pandan Road	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
DSV_001	DSV	DSV	24 Penjuru Road, #09-05/06 (Loading Bay 2)	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
DYN_001	DYN	Dyna Cool	2 Bukit Batok Street 24, #03-19 Skytech	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
ENG_001	ENG	Eng Lee Logistics Pte Ltd	9 Gul Circle	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
ENGI_001	ENGI	Engie Services Singapore Pte Ltd	1 Canning Rise Singapore 179868	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
ENGI_002	ENGI	Engie Services Singapore Pte Ltd	1 Empress Place	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
ENGI_003	ENGI	Engie Services Singapore Pte Ltd	1 Jurong East st 21, Ng Teng Fong Hospital	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
ENGI_004	ENGI	Engie Services Singapore Pte Ltd	100 Victoria Street, Basement 2, Loading Bay	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
ENGI_005	ENGI	Engie Services Singapore Pte Ltd	17 Woodlands Drive 17, Woodlands Health Campus	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
ENGI_006	ENGI	Engie Services Singapore Pte Ltd	2 Simei Street 3, Changi General Hospital	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
ENGI_007	ENGI	Engie Services Singapore Pte Ltd	20 Airport Boulevard Changi Airport	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
ENGI_008	ENGI	Engie Services Singapore Pte Ltd	28 Irrawaddy Road, New Phoenix Park. (Ministry of Home Affairs)	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
ENGI_009	ENGI	Engie Services Singapore Pte Ltd	32 Jurong Port Road, Heritage Center	t	2026-07-24 15:15:51.944859+00	Sunder	8267 7685	\N
ENGI_010	ENGI	Engie Services Singapore Pte Ltd	4A Tuas Bay Street	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
ENGI_011	ENGI	Engie Services Singapore Pte Ltd	65 Airport Boulevard, #B2-63, Changi Airport T3	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
ENGI_012	ENGI	Engie Services Singapore Pte Ltd	9 Kallang Place	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
ENGI_013	ENGI	Engie Services Singapore Pte Ltd	93 Stamford Road, National Museum of Singapore	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
ENGI_014	ENGI	Engie Services Singapore Pte Ltd	Changi Airport T2 Basement	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
ENGI_015	ENGI	Engie Services Singapore Pte Ltd	2 Tuas Bay Street	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
ENGI_017	ENGI	Engie Services Singapore Pte Ltd	1 Media Link	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
ENGI_018	ENGI	Engie Services Singapore Pte Ltd	30 Changi North Cresent	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
ENGL_001	ENGL	Eng Leng Contractors Pte Ltd	1 CleanTech Loop	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
ENGL_002	ENGL	Eng Leng Contractors Pte Ltd	1 Gul Circle, JTC Logistics Hub	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
ENGL_003	ENGL	Eng Leng Contractors Pte Ltd	16 Tuas Ave 1, JTC Space @ Tuas	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
ENGL_004	ENGL	Eng Leng Contractors Pte Ltd	2 Tukang Innovation Grove	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
ENGL_005	ENGL	Eng Leng Contractors Pte Ltd	28A Penjuru Close Bin Centre	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
ENGL_006	ENGL	Eng Leng Contractors Pte Ltd	8 Buroh Street	t	2026-07-24 15:15:51.944859+00	Ezwan	98644193	\N
ENGL_007	ENGL	Eng Leng Contractors Pte Ltd	8 Jurong Town Hall Rd, JTC Summit Building	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
ENGL_008	ENGL	Eng Leng Contractors Pte Ltd	Jalan Papan LP 15	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
ENGL_009	ENGL	Eng Leng Contractors Pte Ltd	Pandan Loop, Blk K, (Phase 1), Bin Centre	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
ENGL_010	ENGL	Eng Leng Contractors Pte Ltd	Pandan Loop, Blk X, (Phase 3), Bin Centre	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
ENGL_011	ENGL	Eng Leng Contractors Pte Ltd	15 Jalan Terusan	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
EUR_002	EUR	Euro Pac Logistics Pte Ltd	52 Tanjong Penjuru #04-92	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
EVE_001	EVE	EverTeam Pte Ltd	60 Benoi Road	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
FAX_001	FAX	Faxolif Industries Pte Ltd	75 Tech Park Crescent	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
GEO_001	GEO	Geoinnovations Pte Ltd	5 Kwong Ming Road	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
EXP_001	EXP	123 Express	60 Kaki Bukit Place, #06-14 Eunos Techpark	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
HYU_002	HYU	Hyundai Engineering & Construction Co., Ltd	31 Tuas West Drive, Lamppost 74F	t	2026-07-29 14:10:47.111952+00	Liton	88960490	\N
EPO_001	EPO	Epont Building Services Pte Ltd	1 Tuas View Place, Westlink One, #02-01	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
EUR_001	EUR	Euro Pac Logistics Pte Ltd	42 Tanjong Penjuru Road	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
GLO_001	GLO	Glory SIP Pte Ltd	50 Tuas Avenue 11, 02-05	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
GSE_001	GSE	GS Engineering and Construction Corporation	Nicoll Highway LP 120F	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
GSE_002	GSE	GS Engineering and Construction Corporation	Nicoll Highway LP 131F	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
GSE_003	GSE	GS Engineering and Construction Corporation	Nicoll Highway, LP 132F	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
GSE_004	GSE	GS Engineering and Construction Corporation	Ophir Road LP 14/1F	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
GSE_005	GSE	GS Engineering and Construction Corporation	Ophir Road, LP 30F	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
GSE_006	GSE	GS Engineering and Construction Corporation	Republic Boulevard LP 4F	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
GSE_007	GSE	GS Engineering and Construction Corporation	Victoria Street, LP 64F	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
GYM_001	GYM	Gymsportz	7, Block B Mandai Link, #05-27 Mandai Connection	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
HAI_001	HAI	Haid Biotechnology Industry (Singapore) Pte Ltd	46 Gul Drive	t	2026-07-24 15:15:51.944859+00	Yvonne	89101994	\N
HCG_001	HCG	HCG	8 Tuas View Circuit	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
HCG_002	HCG	HCG	79 Anson Road	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
HEP_001	HEP	He Ping Development Pte Ltd	32 Tras Street	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
HEP_002	HEP	He Ping Development Pte Ltd	38 Beach Road, South Beach Tower	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
HEP_003	HEP	He Ping Development Pte Ltd	51 Tanjong Pagar Road	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
HON_001	HON	Hong Hang Hardware	35 Pioneer Road	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
HOT_001	HOT	Hotel Royal Singapore	36 Newton Road	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
HPR_001	HPR	H1 Projects Pte Ltd	107 Jalan Pari Burong	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
HUA_001	HUA	Huationg Contractor	Tanah Merah Coast Road LP 509	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
HUN_001	HUN	Huntsman (S) Pte Ltd	10 Seraya Ave	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
HYD_001	HYD	Hydroproof	The Aries, 51 Science Park	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
HYU_001	HYU	Hyundai Engineering & Construction Co., Ltd	100 Beach Road	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
INV_001	INV	INVX Asia Pacific Pte Ltd	80 Tuas West Drive	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
IWA_001	IWA	Iwatech	2 Kian Teck Drive	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
LAU_001	LAU	Lau Choy Seng Pte Ltd	30 Tuas West Avenue	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
LCH_001	LCH	LCH Logistics Pte Ltd	3 Pioneer Sector 3	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
LEN_001	LEN	Leng Aik Engineering	17 Soon Lee Road	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
LEX_001	LEX	LexBuild International Pte Ltd	11 Tuas Bay Close, #04-01/02	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
LIM_001	LIM	Lim Siang Huat Pte Ltd	6 Fishery Port Road L3	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
MAT_001	MAT	Matrix Cooling (Singapore) Pte Ltd	10 Buroh Street, #07-01, Westconnect Building	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
MEC_001	MEC	Mecom GreenBuild (Singapore) Pte Ltd	23 Jurong Port Road	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
NEA_001	NEA	NEA	NEA Tuas	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
PAX_001	PAX	PaxOcean Singapore Pte Ltd	5 Jalan Samulun	t	2026-07-24 15:15:51.944859+00	Muthu	8455 3465	\N
PIL_001	PIL	Pacific International Lines	PSA berths - vessel operations	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
POH_001	POH	Poh Tiong Choon Logistics Ltd	21 Ayer Merbau, Jurong Island	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
POH_002	POH	Poh Tiong Choon Logistics Ltd	48 Pandan Road L1	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
POH_003	POH	Poh Tiong Choon Logistics Ltd	48 Pandan Road L3	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
POH_004	POH	Poh Tiong Choon Logistics Ltd	48 Pandan Road L6	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
PSA_001	PSA	PSA Port Ecosystem (Sea) Pte Ltd	24 Penjuru Road. #05-06	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
QUA_001	QUA	Qualicoat Pte Ltd	5 Gul Drive	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
RAD_002	RAD	Radha Exports Pte Ltd	118 Pioneer Road L4	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
RAD_004	RAD	Radha Exports Pte Ltd	6 Fishery Port, L5M	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
REM_001	REM	REMEX Minerals Singapore Pte Ltd	98 Tuas South Ave 3 (Inside NEA building)	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
RJH_001	RJH	RJ Hydralics	83 Tagore Lane	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
SAV_001	SAV	Savills Property Management Pte Ltd (Blue Hub)	10 Sunview Road L109	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
SAV_002	SAV	Savills Property Management Pte Ltd (Blue Hub)	10 Sunview Road L309	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
SAV_003	SAV	Savills Property Management Pte Ltd (Blue Hub)	10 Sunview Road L407	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
SAV_004	SAV	Savills Property Management Pte Ltd (Blue Hub)	10 Sunview Road L609	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
SAVI_001	SAVI	Savills Property Management Pte Ltd (Green Hub)	11 Pioneer Turn L2	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
SAVI_002	SAVI	Savills Property Management Pte Ltd (Green Hub)	11 Pioneer Turn L401	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
SAVI_003	SAVI	Savills Property Management Pte Ltd (Green Hub)	11 Pioneer Turn L407	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
SAVI_004	SAVI	Savills Property Management Pte Ltd (Green Hub)	11 Pioneer Turn L601	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
SAVI_005	SAVI	Savills Property Management Pte Ltd (Green Hub)	11 Pioneer Turn L8	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
SEA_001	SEA	Seatrium Pte Ltd	60 Admiralty Road West	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
SHI_001	SHI	Shin Ya O Ya Pte Ltd	6 Chin Bee Ave L5	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
SIE_001	SIE	Siew Kong Glass Makers Pte Ltd	43 Joo Koon Circle	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
SIN_001	SIN	Sin Hong Hardware Pte Ltd	3 Kian Teck Crescent	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
SIND_001	SIND	Sindac Cleaning Services Pte Ltd	1H Pine Grove, Pine Grove Condo	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
SIND_002	SIND	Sindac Cleaning Services Pte Ltd	20 Woodlands Crescent, Northoaks Condo	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
SINH_001	SINH	Sin Hong Poh Metal Trading	59 Tampines Industrial Ave	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
SLS_001	SLS	SLS	No. 9 Tuas South Avenue 19, #01-99	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
LIR_001	LIR	Lirich	23 Gul Drive	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
RAD_003	RAD	Radha Exports Pte Ltd	118 Pioneer Road L7	t	2026-07-24 15:15:51.944859+00	Eugene / Poornima	81614185 / 81572014	\N
RAD_001	RAD	Radha Exports Pte Ltd	118 Pioneer Road L1	t	2026-07-24 15:15:51.944859+00	\N	82982405 / 9185 8431	\N
SHI_002	SHI	Shin Ya O Ya Pte Ltd	6 Chin Bee Ave L9	t	2026-07-24 15:15:51.944859+00	\N	8919 2975	\N
ECO_001	ECO	Ecozeal	\N	t	2026-07-30 00:35:38.053219+00	\N	\N	\N
ACR_001	ACR	Acreation Group Pte Ltd	19 Jalan Mesin	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
ACR_002	ACR	Acreation Group Pte Ltd	9 Raffles Boulevard	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
ACR_003	ACR	Acreation Group Pte Ltd	Engku Aman Road	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
ACR_004	ACR	Acreation Group Pte Ltd	Orchard Gateway, 277 Orchard Road	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
ADV_001	ADV	Advanced Substrate Technologies Pte Ltd	47A Jalan Buroh	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
ALL_001	ALL	Allalloy Dynaweld Pte Ltd	10 Tuas Link 1	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
ALLI_001	ALLI	Allied Container Services Pte Ltd	10 Tuas Ave 6	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
ALLI_002	ALLI	Allied Container Services Pte Ltd	15 Pioneer Crescent	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
ALLI_003	ALLI	Allied Container Services Pte Ltd	25 Penjuru Lane Yard 3	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
APE_001	APE	Apex Sealing Technologies Pte Ltd	19 Tuas South Street 5	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
APE_002	APE	Apex Sealing Technologies Pte Ltd	Tuas Basin Lane	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
ARC_001	ARC	Archibiz	Blk A 30 Kranji Loop, #06-05 Timmac @ Kranji	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
ART_001	ART	Artdecor Design Studio Pte Ltd	2 Defu South Street 1, #05-03, JTC Industrial City	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
ASL_001	ASL	ASL Proworld Solution Pte Ltd	8 Pandan Crescent	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
AST_001	AST	Astore Pte Ltd	43 Keppel Road	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
ENGI_016	ENGI	Engie Services Singapore Pte Ltd	1 Cove Grove	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
SLS_002	SLS	SLS	VSMC site office Gate 3	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
SNI_001	SNI	Snip Avenue Holdings	9 Changi South Street 3, loading bay	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
SPR_001	SPR	Springlife Maintenance Service Pte Ltd	21 Ang Mo Kio Ave 9, Nuovo Condo	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
SPR_002	SPR	Springlife Maintenance Service Pte Ltd	464 Corporation Road, Parc Vista Condo	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
SPR_003	SPR	Springlife Maintenance Service Pte Ltd	88 Flora Road, Edelweiss Park Condo	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
STA_001	STA	Stamford Tyres	19 Lok Yang Way	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
STS_001	STS	STSM	15 Pasir Ris Street 21	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
STS_002	STS	STSM	47 Hougang Avenue 1	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
STS_003	STS	STSM	Blk 15 Toa Payoh Lorong 7	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
TONG_005	TONG	Tong Hock Pte Ltd	2 Peach Garden, Peach Garden condo	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
TONG_007	TONG	Tong Hock Pte Ltd	58 Woodlands Drive 16, La Casa Condo	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
TONG_008	TONG	Tong Hock Pte Ltd	7 Tractor Road	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
TONG_009	TONG	Tong Hock Pte Ltd	1 Woodlands Terrace	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
TOP_001	TOP	Top Star Builder Pte Ltd	50 Playfair road	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
TRA_001	TRA	Tracebuild	1 Woodlands Street 31, Fu Chun Community Club	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
TRE_001	TRE	T3 Reources Pte Ltd	16 Gul Street 3	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
TST_001	TST	TSTL	19 Tuas Street	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
URB_001	URB	Urban Group Pte Ltd	200 Netheravon Road	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
WAH_001	WAH	Wah & Hua Pte Ltd	17 Kallang Junction, #01-01, Singapore 339274	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
WAH_002	WAH	Wah & Hua Pte Ltd	19 Loyang Way	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
WAH_003	WAH	Wah & Hua Pte Ltd	22 Woodlands Link	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
WAH_004	WAH	Wah & Hua Pte Ltd	221 Kallang Bahru Lion Building	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
WAH_005	WAH	Wah & Hua Pte Ltd	30 Kerong Lane	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
WAH_006	WAH	Wah & Hua Pte Ltd	76 Sungei Tengah Road	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
WAH_007	WAH	Wah & Hua Pte Ltd	980 Upper Changi Road North Singapore 507708(Prison HQ)	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
WEB_001	WEB	WeBuild	120 Hillview Ave	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
WIK_001	WIK	WIKA Instrumentation Pte Ltd	13 Kian Teck Crescent	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
WIL_001	WIL	Wilkie Development Pte Ltd	12 New Industrial Road	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
WOR_001	WOR	World of Wood Pte Ltd	35 Tannery Road, #01-07, Ruby Industrial Complex	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
WRA_001	WRA	W''Ray Construction Pte Ltd	22 Scotts Road, Goodwood Park Hotel	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
WRA_002	WRA	W''Ray Construction Pte Ltd	25 Tuas Ave 4	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
STE_001	STE	Benoi Yard	ST Engineering Marine - Benoi Yard	t	2026-07-31 03:02:32.106388+00	\N	\N	\N
STE_002	STE	Gul Yard	ST Engineering Marine - Gul Yard	t	2026-07-31 03:02:32.106388+00	\N	\N	\N
STE_003	STE	CDPL Tuas	CDPL Tuas	t	2026-07-31 03:02:32.106388+00	\N	\N	\N
STE_004	STE	Tuas Nexus	61A Tuas Nexus Drive (IWMF Package 1)	t	2026-07-31 03:02:32.106388+00	\N	\N	\N
GWC_001	GWC	GWC	449 Clementi Ave 3, #01-259	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
TONG_003	TONG	Tong Hock Pte Ltd	14 Tractor Road	t	2026-07-24 15:15:51.944859+00	\N	88206384	\N
STX_001	STX	ST Engineering	6 Tuas South Street 15	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
STX_002	STX	ST Engineering	Benoi	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
STX_003	STX	ST Engineering	Gul	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
STX_004	STX	ST Engineering	61a Tuas Nexus Drive	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
STS_004	STS	STSM	Blk 61 Jurong West Street 65, Jurong West Secondary School (JWSS)	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
STS_005	STS	STSM	Blk 64 Lorong 5 Toa Payoh - Lot no. 24	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
STS_006	STS	STSM	Blk 698 West Coast Road, Commonwealth Secondary School (CWSS)	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
SUM_001	SUM	Sumber Indah Pte Ltd	1 Tuas View Close	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
SUN_001	SUN	Sun City Maintenance Pte Ltd	300 Mandai Road, Mandai Crematorium and Columbarium	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
SUN_002	SUN	Sun City Maintenance Pte Ltd	55 Changi South Ave 1	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
SUN_003	SUN	Sun City Maintenance Pte Ltd	SUTD Building 2, 8 Somapah Road, loading bay	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
SUN_004	SUN	Sun City Maintenance Pte Ltd	SUTD Building 3, 8 somapah Road , with access via the Changi Street carpark entrance	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
SUN_005	SUN	Sun City Maintenance Pte Ltd	Yishun Columbarium, 569 Yishun Ring Road	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
SYS_001	SYS	Sys-Mac Automation Engineering Pte Ltd	2 Woodlands Sector 1, #05-18	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
SYST_001	SYST	System Foundation Pte Ltd	21A Tuas South Place	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
SYST_002	SYST	System Foundation Pte Ltd	45 Tuas View Place	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
TAI_001	TAI	Tai Lee Tong	No 11, Lorong 21A Geylang	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
TEC_001	TEC	Technicair Singapore Services Pte Ltd	16 Jalan Tan Tock Seng	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
TECH_001	TECH	Technigroup Far East Pte Ltd	Outram Road	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
TECK_001	TECK	Teck Sang Pte Ltd	30A Quality Road	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
TOH_001	TOH	Toh Ban Seng	Seletar Westlink LP 103	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
TON_001	TON	Tong Carriage (S) Pte Ltd	30 Toh Guan Road	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
TONG_001	TONG	Tong Hock Pte Ltd	10 Pandan Crescent	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
TONG_002	TONG	Tong Hock Pte Ltd	1206A East Coast Park	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
TONG_004	TONG	Tong Hock Pte Ltd	19 Tuas Street	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
TONG_006	TONG	Tong Hock Pte Ltd	2 Pioneer Sector 1	t	2026-07-24 15:15:51.944859+00	\N	\N	\N
\.


--
-- Data for Name: vehicles; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.vehicles (vehicle_id, vtype, active) FROM stdin;
XE5457Y	diesel	t
XE6221D	diesel	t
XE4491D	diesel	t
XE6204D	diesel	t
XE7126P	diesel	t
XE8496P	diesel	t
\.


--
-- Data for Name: yard_inbound; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.yard_inbound (id, log_date, waste_type, source_name, source_addr, qty_t, remarks, entered_by, created_at) FROM stdin;
\.


--
-- Data for Name: yard_stock; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.yard_stock (id, take_date, waste_type, qty_t, remarks, entered_by, created_at) FROM stdin;
\.


--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: realtime; Owner: -
--

COPY realtime.schema_migrations (version, inserted_at) FROM stdin;
20211116024918	2026-07-24 10:08:09
20211116045059	2026-07-24 10:08:09
20211116050929	2026-07-24 10:08:09
20211116051442	2026-07-24 10:08:09
20211116212300	2026-07-24 10:08:09
20211116213355	2026-07-24 10:08:09
20211116213934	2026-07-24 10:08:09
20211116214523	2026-07-24 10:08:09
20211122062447	2026-07-24 10:08:09
20211124070109	2026-07-24 10:08:09
20211202204204	2026-07-24 10:08:09
20211202204605	2026-07-24 10:08:09
20211210212804	2026-07-24 10:08:09
20211228014915	2026-07-24 10:08:09
20220107221237	2026-07-24 10:08:09
20220228202821	2026-07-24 10:08:09
20220312004840	2026-07-24 10:08:09
20220603231003	2026-07-24 10:08:09
20220603232444	2026-07-24 10:08:09
20220615214548	2026-07-24 10:08:09
20220712093339	2026-07-24 10:08:09
20220908172859	2026-07-24 10:08:09
20220916233421	2026-07-24 10:08:09
20230119133233	2026-07-24 10:08:09
20230128025114	2026-07-24 10:08:09
20230128025212	2026-07-24 10:08:09
20230227211149	2026-07-24 10:08:09
20230228184745	2026-07-24 10:08:09
20230308225145	2026-07-24 10:08:09
20230328144023	2026-07-24 10:08:09
20231018144023	2026-07-24 10:08:09
20231204144023	2026-07-24 10:08:09
20231204144024	2026-07-24 10:08:09
20231204144025	2026-07-24 10:08:09
20240108234812	2026-07-24 10:08:09
20240109165339	2026-07-24 10:08:09
20240227174441	2026-07-24 10:08:09
20240311171622	2026-07-24 10:08:09
20240321100241	2026-07-24 10:08:09
20240401105812	2026-07-24 10:08:09
20240418121054	2026-07-24 10:08:09
20240523004032	2026-07-24 10:08:09
20240618124746	2026-07-24 10:08:09
20240801235015	2026-07-24 10:08:09
20240805133720	2026-07-24 10:08:09
20240827160934	2026-07-24 10:08:09
20240919163303	2026-07-24 10:08:09
20240919163305	2026-07-24 10:08:09
20241019105805	2026-07-24 10:08:09
20241030150047	2026-07-24 10:08:09
20241108114728	2026-07-24 10:08:09
20241121104152	2026-07-24 10:08:09
20241130184212	2026-07-24 10:08:09
20241220035512	2026-07-24 10:08:09
20241220123912	2026-07-24 10:08:09
20241224161212	2026-07-24 10:08:09
20250107150512	2026-07-24 10:08:09
20250110162412	2026-07-24 10:08:09
20250123174212	2026-07-24 10:08:09
20250128220012	2026-07-24 10:08:09
20250506224012	2026-07-24 10:08:09
20250523164012	2026-07-24 10:08:09
20250714121412	2026-07-24 10:08:09
20250905041441	2026-07-24 10:08:09
20251103001201	2026-07-24 10:08:09
20251120212548	2026-07-24 10:08:09
20251120215549	2026-07-24 10:08:09
20260218120000	2026-07-24 10:08:09
20260326120000	2026-07-24 10:08:09
20260514120000	2026-07-24 10:08:09
20260527120000	2026-07-24 10:08:09
20260528120000	2026-07-24 10:08:09
20260603120000	2026-07-24 10:08:09
20260605120000	2026-07-24 10:08:09
20260606110000	2026-07-24 10:08:09
20260616120000	2026-07-24 10:08:09
20260624120000	2026-07-24 10:08:09
20260626120000	2026-07-24 10:08:09
20260706120000	2026-07-24 10:08:09
20260707120000	2026-07-24 10:08:09
20260709120000	2026-07-24 10:08:09
\.


--
-- Data for Name: subscription; Type: TABLE DATA; Schema: realtime; Owner: -
--

COPY realtime.subscription (id, subscription_id, entity, filters, claims, created_at, action_filter, selected_columns) FROM stdin;
\.


--
-- Data for Name: buckets; Type: TABLE DATA; Schema: storage; Owner: -
--

COPY storage.buckets (id, name, owner, created_at, updated_at, public, avif_autodetection, file_size_limit, allowed_mime_types, owner_id, type) FROM stdin;
do-photos	do-photos	\N	2026-07-24 16:50:07.610059+00	2026-07-24 16:50:07.610059+00	t	f	\N	\N	\N	STANDARD
\.


--
-- Data for Name: buckets_analytics; Type: TABLE DATA; Schema: storage; Owner: -
--

COPY storage.buckets_analytics (name, type, format, created_at, updated_at, id, deleted_at) FROM stdin;
\.


--
-- Data for Name: buckets_vectors; Type: TABLE DATA; Schema: storage; Owner: -
--

COPY storage.buckets_vectors (id, type, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: migrations; Type: TABLE DATA; Schema: storage; Owner: -
--

COPY storage.migrations (id, name, hash, executed_at) FROM stdin;
0	create-migrations-table	e18db593bcde2aca2a408c4d1100f6abba2195df	2026-07-24 10:08:49.175818
1	initialmigration	6ab16121fbaa08bbd11b712d05f358f9b555d777	2026-07-24 10:08:49.258102
2	storage-schema	f6a1fa2c93cbcd16d4e487b362e45fca157a8dbd	2026-07-24 10:08:49.264223
3	pathtoken-column	2cb1b0004b817b29d5b0a971af16bafeede4b70d	2026-07-24 10:08:49.315784
4	add-migrations-rls	427c5b63fe1c5937495d9c635c263ee7a5905058	2026-07-24 10:08:49.34347
5	add-size-functions	79e081a1455b63666c1294a440f8ad4b1e6a7f84	2026-07-24 10:08:49.349362
6	change-column-name-in-get-size	ded78e2f1b5d7e616117897e6443a925965b30d2	2026-07-24 10:08:49.35809
7	add-rls-to-buckets	e7e7f86adbc51049f341dfe8d30256c1abca17aa	2026-07-24 10:08:49.363054
8	add-public-to-buckets	fd670db39ed65f9d08b01db09d6202503ca2bab3	2026-07-24 10:08:49.373062
9	fix-search-function	af597a1b590c70519b464a4ab3be54490712796b	2026-07-24 10:08:49.379338
10	search-files-search-function	b595f05e92f7e91211af1bbfe9c6a13bb3391e16	2026-07-24 10:08:49.385383
11	add-trigger-to-auto-update-updated_at-column	7425bdb14366d1739fa8a18c83100636d74dcaa2	2026-07-24 10:08:49.393186
12	add-automatic-avif-detection-flag	8e92e1266eb29518b6a4c5313ab8f29dd0d08df9	2026-07-24 10:08:49.402274
13	add-bucket-custom-limits	cce962054138135cd9a8c4bcd531598684b25e7d	2026-07-24 10:08:49.407875
14	use-bytes-for-max-size	941c41b346f9802b411f06f30e972ad4744dad27	2026-07-24 10:08:49.413557
15	add-can-insert-object-function	934146bc38ead475f4ef4b555c524ee5d66799e5	2026-07-24 10:08:49.453184
16	add-version	76debf38d3fd07dcfc747ca49096457d95b1221b	2026-07-24 10:08:49.461816
17	drop-owner-foreign-key	f1cbb288f1b7a4c1eb8c38504b80ae2a0153d101	2026-07-24 10:08:49.468199
18	add_owner_id_column_deprecate_owner	e7a511b379110b08e2f214be852c35414749fe66	2026-07-24 10:08:49.477147
19	alter-default-value-objects-id	02e5e22a78626187e00d173dc45f58fa66a4f043	2026-07-24 10:08:49.497007
20	list-objects-with-delimiter	cd694ae708e51ba82bf012bba00caf4f3b6393b7	2026-07-24 10:08:49.506234
21	s3-multipart-uploads	8c804d4a566c40cd1e4cc5b3725a664a9303657f	2026-07-24 10:08:49.515232
22	s3-multipart-uploads-big-ints	9737dc258d2397953c9953d9b86920b8be0cdb73	2026-07-24 10:08:49.537423
23	optimize-search-function	9d7e604cddc4b56a5422dc68c9313f4a1b6f132c	2026-07-24 10:08:49.55518
24	operation-function	8312e37c2bf9e76bbe841aa5fda889206d2bf8aa	2026-07-24 10:08:49.559834
25	custom-metadata	d974c6057c3db1c1f847afa0e291e6165693b990	2026-07-24 10:08:49.56614
26	objects-prefixes	215cabcb7f78121892a5a2037a09fedf9a1ae322	2026-07-24 10:08:49.572387
27	search-v2	859ba38092ac96eb3964d83bf53ccc0b141663a6	2026-07-24 10:08:49.576602
28	object-bucket-name-sorting	c73a2b5b5d4041e39705814fd3a1b95502d38ce4	2026-07-24 10:08:49.580754
29	create-prefixes	ad2c1207f76703d11a9f9007f821620017a66c21	2026-07-24 10:08:49.585789
30	update-object-levels	2be814ff05c8252fdfdc7cfb4b7f5c7e17f0bed6	2026-07-24 10:08:49.589952
31	objects-level-index	b40367c14c3440ec75f19bbce2d71e914ddd3da0	2026-07-24 10:08:49.594
32	backward-compatible-index-on-objects	e0c37182b0f7aee3efd823298fb3c76f1042c0f7	2026-07-24 10:08:49.598632
33	backward-compatible-index-on-prefixes	b480e99ed951e0900f033ec4eb34b5bdcb4e3d49	2026-07-24 10:08:49.602646
34	optimize-search-function-v1	ca80a3dc7bfef894df17108785ce29a7fc8ee456	2026-07-24 10:08:49.606663
35	add-insert-trigger-prefixes	458fe0ffd07ec53f5e3ce9df51bfdf4861929ccc	2026-07-24 10:08:49.610636
36	optimise-existing-functions	6ae5fca6af5c55abe95369cd4f93985d1814ca8f	2026-07-24 10:08:49.614865
37	add-bucket-name-length-trigger	3944135b4e3e8b22d6d4cbb568fe3b0b51df15c1	2026-07-24 10:08:49.619465
38	iceberg-catalog-flag-on-buckets	02716b81ceec9705aed84aa1501657095b32e5c5	2026-07-24 10:08:49.624539
39	add-search-v2-sort-support	6706c5f2928846abee18461279799ad12b279b78	2026-07-24 10:08:49.637497
40	fix-prefix-race-conditions-optimized	7ad69982ae2d372b21f48fc4829ae9752c518f6b	2026-07-24 10:08:49.641446
41	add-object-level-update-trigger	07fcf1a22165849b7a029deed059ffcde08d1ae0	2026-07-24 10:08:49.645751
42	rollback-prefix-triggers	771479077764adc09e2ea2043eb627503c034cd4	2026-07-24 10:08:49.650131
43	fix-object-level	84b35d6caca9d937478ad8a797491f38b8c2979f	2026-07-24 10:08:49.654177
44	vector-bucket-type	99c20c0ffd52bb1ff1f32fb992f3b351e3ef8fb3	2026-07-24 10:08:49.658275
45	vector-buckets	049e27196d77a7cb76497a85afae669d8b230953	2026-07-24 10:08:49.663112
46	buckets-objects-grants	fedeb96d60fefd8e02ab3ded9fbde05632f84aed	2026-07-24 10:08:49.674976
47	iceberg-table-metadata	649df56855c24d8b36dd4cc1aeb8251aa9ad42c2	2026-07-24 10:08:49.680512
48	iceberg-catalog-ids	e0e8b460c609b9999ccd0df9ad14294613eed939	2026-07-24 10:08:49.688194
49	buckets-objects-grants-postgres	072b1195d0d5a2f888af6b2302a1938dd94b8b3d	2026-07-24 10:08:49.712547
50	search-v2-optimised	6323ac4f850aa14e7387eb32102869578b5bd478	2026-07-24 10:08:49.717735
51	index-backward-compatible-search	2ee395d433f76e38bcd3856debaf6e0e5b674011	2026-07-24 10:08:50.4503
52	drop-not-used-indexes-and-functions	5cc44c8696749ac11dd0dc37f2a3802075f3a171	2026-07-24 10:08:50.452404
53	drop-index-lower-name	d0cb18777d9e2a98ebe0bc5cc7a42e57ebe41854	2026-07-24 10:08:50.464653
54	drop-index-object-level	6289e048b1472da17c31a7eba1ded625a6457e67	2026-07-24 10:08:50.467408
55	prevent-direct-deletes	262a4798d5e0f2e7c8970232e03ce8be695d5819	2026-07-24 10:08:50.469192
56	fix-optimized-search-function	b823ed1e418101032fa01374edc9a436e54e3ed4	2026-07-24 10:08:50.47465
57	s3-multipart-uploads-metadata	f127886e00d1b374fadbc7c6b31e09336aad5287	2026-07-24 10:08:50.480262
58	operation-ergonomics	00ca5d483b3fe0d522133d9002ccc5df98365120	2026-07-24 10:08:50.484875
59	drop-unused-functions	38456f13e39691c2bbb4b5151d0d1cdbabd4a8c4	2026-07-24 10:08:50.490262
60	optimize-existing-functions-again	db35e1c91a9201e59f4fef8d972c2f277d68b157	2026-07-24 10:08:50.494891
\.


--
-- Data for Name: objects; Type: TABLE DATA; Schema: storage; Owner: -
--

COPY storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) FROM stdin;
a2e812d0-30b6-4735-adfa-eb4f616b487e	do-photos	mrzbayza-BININ-43-1.jpg	\N	2026-07-24 19:07:17.293815+00	2026-07-24 19:07:17.293815+00	2026-07-24 19:07:17.293815+00	{"eTag": "\\"e6de1330bcd5d161d095a6545f8fb7e0\\"", "size": 126487, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-24T19:07:18.000Z", "contentLength": 126487, "httpStatusCode": 200}	5b28730c-69db-413e-a84e-ca4d05aa20f7	\N	{}
f88b1ae1-7942-49bd-9749-923c7e885737	do-photos	ms5t6p8d-BININ-78-1.jpg	\N	2026-07-29 08:14:28.086174+00	2026-07-29 08:14:28.086174+00	2026-07-29 08:14:28.086174+00	{"eTag": "\\"8897432ebc027cf02675042ba5da835b\\"", "size": 354132, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-29T08:14:29.000Z", "contentLength": 354132, "httpStatusCode": 200}	8179800b-c255-4bdc-a42e-30eed07d9b6d	\N	{}
344f6e6e-4b8e-4028-a546-2ce9315490ee	do-photos	mrzbaz6l-BINOUT-43-1.jpg	\N	2026-07-24 19:07:17.439235+00	2026-07-24 19:07:17.439235+00	2026-07-24 19:07:17.439235+00	{"eTag": "\\"e6de1330bcd5d161d095a6545f8fb7e0\\"", "size": 126487, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-24T19:07:18.000Z", "contentLength": 126487, "httpStatusCode": 200}	2b3ae022-6d76-4be9-a2e8-55dcabf5da4d	\N	{}
94cd0f1c-8f1b-4492-8caa-508e1f1627bb	do-photos	mrzbazaa-DO-43-1.jpg	\N	2026-07-24 19:07:17.568546+00	2026-07-24 19:07:17.568546+00	2026-07-24 19:07:17.568546+00	{"eTag": "\\"e6de1330bcd5d161d095a6545f8fb7e0\\"", "size": 126487, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-24T19:07:18.000Z", "contentLength": 126487, "httpStatusCode": 200}	ca6af05e-d355-4002-9ed4-5c6580d813f7	\N	{}
daddd4bf-7568-4bdc-999c-ef860f14d122	do-photos	ms5t6pem-BINOUT-78-1.jpg	\N	2026-07-29 08:14:28.352091+00	2026-07-29 08:14:28.352091+00	2026-07-29 08:14:28.352091+00	{"eTag": "\\"7228e5f791d3676fb510731ac0cefb05\\"", "size": 399179, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-29T08:14:29.000Z", "contentLength": 399179, "httpStatusCode": 200}	450b16af-7e80-488b-acce-6689dc91a754	\N	{}
6da9ddc2-fb74-49ef-8808-d8db60c5f29c	do-photos	mrzcgqcw-DO-44-1.jpg	\N	2026-07-24 19:39:45.618481+00	2026-07-24 19:39:45.618481+00	2026-07-24 19:39:45.618481+00	{"eTag": "\\"e6de1330bcd5d161d095a6545f8fb7e0\\"", "size": 126487, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-24T19:39:46.000Z", "contentLength": 126487, "httpStatusCode": 200}	12b38056-ecb5-4f45-9217-d36b46466160	\N	{}
d4b0f7e7-d959-4c1a-8dc4-5f5806ce46c7	do-photos	mrzdbczv-DO-45-1.jpg	\N	2026-07-24 20:03:34.651945+00	2026-07-24 20:03:34.651945+00	2026-07-24 20:03:34.651945+00	{"eTag": "\\"e6de1330bcd5d161d095a6545f8fb7e0\\"", "size": 126487, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-24T20:03:35.000Z", "contentLength": 126487, "httpStatusCode": 200}	51a4b237-3064-43f5-b156-6e0e67657fca	\N	{}
ef620a0f-20be-4c47-a5b4-51098221dbaa	do-photos	ms5t6plv-DO-78-1.jpg	\N	2026-07-29 08:14:28.544886+00	2026-07-29 08:14:28.544886+00	2026-07-29 08:14:28.544886+00	{"eTag": "\\"92535a345f3d6f381f60e063a49ac422\\"", "size": 254468, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-29T08:14:29.000Z", "contentLength": 254468, "httpStatusCode": 200}	fb0b33dd-96a5-4a1e-93e4-7c828640b2b4	\N	{}
e2b6526e-a3a6-4fe6-ae98-874bd2d8e03f	do-photos	ms2uzua3-BININ-47-1.jpg	\N	2026-07-27 06:41:48.840607+00	2026-07-27 06:41:48.840607+00	2026-07-27 06:41:48.840607+00	{"eTag": "\\"89bab78537b36a323339783b99f2b32c\\"", "size": 309823, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-27T06:41:49.000Z", "contentLength": 309823, "httpStatusCode": 200}	aa61dc22-b40f-4253-9136-4ec078c566b0	\N	{}
9742b166-5dd8-4842-aa4d-00759aa339ae	do-photos	ms2v45as-BININ-48-1.jpg	\N	2026-07-27 06:45:09.656912+00	2026-07-27 06:45:09.656912+00	2026-07-27 06:45:09.656912+00	{"eTag": "\\"9dcd3ce471a40bf5e2ea634f3540d95b\\"", "size": 418745, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-27T06:45:10.000Z", "contentLength": 418745, "httpStatusCode": 200}	cd73989a-92f9-4831-96d5-16de3343c0f7	\N	{}
05f89778-4f8d-44b4-896b-b40ace9a6dcb	do-photos	ms6u83cm-BININ-93-1.jpg	\N	2026-07-30 01:31:18.977084+00	2026-07-30 01:31:18.977084+00	2026-07-30 01:31:18.977084+00	{"eTag": "\\"bdb1c328531e819fc2feb2677ae3adfe\\"", "size": 454203, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-30T01:31:19.000Z", "contentLength": 454203, "httpStatusCode": 200}	102fa0ee-6740-4164-8aa6-e1ff35d73a51	\N	{}
cb025df4-5f79-4739-8749-6713f32adaa2	do-photos	ms2v45hg-BINOUT-48-1.jpg	\N	2026-07-27 06:45:09.849312+00	2026-07-27 06:45:09.849312+00	2026-07-27 06:45:09.849312+00	{"eTag": "\\"be16599939e922a375009f8ca23db46f\\"", "size": 306900, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-27T06:45:10.000Z", "contentLength": 306900, "httpStatusCode": 200}	dd76eb89-e99d-4b88-8460-feb4a56d87ee	\N	{}
51223c13-d3d2-4b6e-a117-4206d419a321	do-photos	ms2v45mh-DO-48-1.jpg	\N	2026-07-27 06:45:10.01679+00	2026-07-27 06:45:10.01679+00	2026-07-27 06:45:10.01679+00	{"eTag": "\\"ded4b81a7359a83e23210449d8ff081b\\"", "size": 245209, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-27T06:45:10.000Z", "contentLength": 245209, "httpStatusCode": 200}	242d9662-2207-4b95-84dd-98f32fc95c2b	\N	{}
4741ddf2-1231-41fe-beeb-498fd5582ca2	do-photos	ms2xeq8v-BININ-49-1.jpg	\N	2026-07-27 07:49:22.84573+00	2026-07-27 07:49:22.84573+00	2026-07-27 07:49:22.84573+00	{"eTag": "\\"00cac5e2257571d529fb8ee88343fb23\\"", "size": 387883, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-27T07:49:23.000Z", "contentLength": 387883, "httpStatusCode": 200}	75b09c36-b9ba-4cf4-95d5-a22a82a3c751	\N	{}
4f1e2a4f-9840-4eaf-9567-55ab58eb5d9b	do-photos	ms2xeqky-BINOUT-49-1.jpg	\N	2026-07-27 07:49:23.005356+00	2026-07-27 07:49:23.005356+00	2026-07-27 07:49:23.005356+00	{"eTag": "\\"30dde33b5a6ff48f1636d49c552b707b\\"", "size": 214905, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-27T07:49:23.000Z", "contentLength": 214905, "httpStatusCode": 200}	ea7e981e-0c6b-4aff-b24b-71844e68e393	\N	{}
65d0bfce-745c-4414-9a00-1242b02d553c	do-photos	ms2xeqp9-DO-49-1.jpg	\N	2026-07-27 07:49:23.165365+00	2026-07-27 07:49:23.165365+00	2026-07-27 07:49:23.165365+00	{"eTag": "\\"89bab78537b36a323339783b99f2b32c\\"", "size": 309823, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-27T07:49:24.000Z", "contentLength": 309823, "httpStatusCode": 200}	7603563f-d8b4-442e-936e-775523761ec0	\N	{}
0049e622-bbd1-4eb8-a983-daed55a71911	do-photos	ms31u4uy-BININ-50-1.jpg	\N	2026-07-27 09:53:19.970504+00	2026-07-27 09:53:19.970504+00	2026-07-27 09:53:19.970504+00	{"eTag": "\\"03fdc2475dd0dbb3a14fa7a062961232\\"", "size": 288035, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-27T09:53:20.000Z", "contentLength": 288035, "httpStatusCode": 200}	faf63c16-d04e-41be-8bc1-e1ea289bd5ae	\N	{}
7b77d7d1-8f90-4160-9b7a-14f8318e20a7	do-photos	ms5xviy1-BININ-79-1.jpg	\N	2026-07-29 10:25:44.930448+00	2026-07-29 10:25:44.930448+00	2026-07-29 10:25:44.930448+00	{"eTag": "\\"6be4e8bf8b4d50cd9a868ad5c2c343c4\\"", "size": 109360, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-29T10:25:45.000Z", "contentLength": 109360, "httpStatusCode": 200}	05ef1440-cd3a-4b9a-90f8-97b5c9610a24	\N	{}
ca94f65e-4f33-4c38-96d2-f35c8e8fdadb	do-photos	ms31u53y-BINOUT-50-1.jpg	\N	2026-07-27 09:53:20.129813+00	2026-07-27 09:53:20.129813+00	2026-07-27 09:53:20.129813+00	{"eTag": "\\"03fdc2475dd0dbb3a14fa7a062961232\\"", "size": 288035, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-27T09:53:21.000Z", "contentLength": 288035, "httpStatusCode": 200}	e0d3c939-af36-4190-b65a-42986dcb2414	\N	{}
f124f578-7097-4d1c-afc6-0d0f740c2b65	do-photos	ms31u58y-DO-50-1.jpg	\N	2026-07-27 09:53:20.294564+00	2026-07-27 09:53:20.294564+00	2026-07-27 09:53:20.294564+00	{"eTag": "\\"3a638e239ed05370aeee58626f9f521a\\"", "size": 243112, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-27T09:53:21.000Z", "contentLength": 243112, "httpStatusCode": 200}	36eae2c3-b809-41fb-bae5-89493b5e0d34	\N	{}
05002088-44e2-46b9-8402-638680f2329a	do-photos	ms5xvjmq-BINOUT-79-1.jpg	\N	2026-07-29 10:25:45.654682+00	2026-07-29 10:25:45.654682+00	2026-07-29 10:25:45.654682+00	{"eTag": "\\"6be4e8bf8b4d50cd9a868ad5c2c343c4\\"", "size": 109360, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-29T10:25:46.000Z", "contentLength": 109360, "httpStatusCode": 200}	c0e9cb39-b965-4eb4-a816-40bc2867f8d9	\N	{}
73219e00-d8ee-4afe-b6f0-e14e45bc08d6	do-photos	ms31xbl4-BININ-51-1.jpg	\N	2026-07-27 09:55:48.5373+00	2026-07-27 09:55:48.5373+00	2026-07-27 09:55:48.5373+00	{"eTag": "\\"aa30d907a511ada493dda10f151da190\\"", "size": 277241, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-27T09:55:49.000Z", "contentLength": 277241, "httpStatusCode": 200}	af0c9ad5-7736-4b1f-a829-75074121f269	\N	{}
f66d2a24-e39e-4533-8464-0713a33268b7	do-photos	ms31xbql-BINOUT-51-1.jpg	\N	2026-07-27 09:55:48.739089+00	2026-07-27 09:55:48.739089+00	2026-07-27 09:55:48.739089+00	{"eTag": "\\"db25a048873ae0afe9c04714342db209\\"", "size": 308566, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-27T09:55:49.000Z", "contentLength": 308566, "httpStatusCode": 200}	8bda53c3-84e4-410b-8d73-4b82bd9cc14e	\N	{}
48a4de1b-47c2-4b51-a0e6-fae9573c43e9	do-photos	ms6u83mv-DO-93-1.jpg	\N	2026-07-30 01:31:19.134674+00	2026-07-30 01:31:19.134674+00	2026-07-30 01:31:19.134674+00	{"eTag": "\\"046e98f781de7fae30fbe8a406e1c234\\"", "size": 283661, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-30T01:31:20.000Z", "contentLength": 283661, "httpStatusCode": 200}	3d2a0c39-f537-4523-9acf-87514ec55915	\N	{}
74e19b73-ca50-4bdb-b4d8-f3f4bf7b4bd9	do-photos	ms31xbw7-DO-51-1.jpg	\N	2026-07-27 09:55:49.109891+00	2026-07-27 09:55:49.109891+00	2026-07-27 09:55:49.109891+00	{"eTag": "\\"98fda90f3ebfd55a3d0c15f232bf14cf\\"", "size": 240548, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-27T09:55:50.000Z", "contentLength": 240548, "httpStatusCode": 200}	eb184a56-dd19-4450-8b78-904dbc8361db	\N	{}
999ed74f-d73f-4711-bc55-ae3aa36273e0	do-photos	ms31ynjl-BININ-52-1.jpg	\N	2026-07-27 09:56:50.95253+00	2026-07-27 09:56:50.95253+00	2026-07-27 09:56:50.95253+00	{"eTag": "\\"baf727db83381ca7c6def6b78b3d9b7b\\"", "size": 323975, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-27T09:56:51.000Z", "contentLength": 323975, "httpStatusCode": 200}	043975eb-8752-4b99-bc94-c2d7eb3b377e	\N	{}
8f331f64-ac56-4902-be73-a9c8a1e1613a	do-photos	ms6ylj60-BININ-95-1.jpg	\N	2026-07-30 03:33:44.500446+00	2026-07-30 03:33:44.500446+00	2026-07-30 03:33:44.500446+00	{"eTag": "\\"cb5426c292f9fad7a3486b99f7f0977d\\"", "size": 171957, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-30T03:33:45.000Z", "contentLength": 171957, "httpStatusCode": 200}	0549b07a-15e2-428e-a478-bd867d12abab	\N	{}
a4b3297f-307d-4235-92b5-e7faa95a2294	do-photos	ms31ynw7-BINOUT-52-1.jpg	\N	2026-07-27 09:56:51.099213+00	2026-07-27 09:56:51.099213+00	2026-07-27 09:56:51.099213+00	{"eTag": "\\"baf727db83381ca7c6def6b78b3d9b7b\\"", "size": 323975, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-27T09:56:52.000Z", "contentLength": 323975, "httpStatusCode": 200}	ed66b10f-c7b4-4fb1-adf3-7753bc99b38f	\N	{}
d8ebff91-2ddc-4ee3-b8c8-aa157ff59599	do-photos	ms33hlne-BININ-53-1.jpg	\N	2026-07-27 10:39:34.373781+00	2026-07-27 10:39:34.373781+00	2026-07-27 10:39:34.373781+00	{"eTag": "\\"cdd32a24b70dba39afcf49698062324d\\"", "size": 205978, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-27T10:39:35.000Z", "contentLength": 205978, "httpStatusCode": 200}	505869a1-2d78-4498-92cf-8b5b15267f80	\N	{}
3d052df1-7d62-46e5-b58d-238d9d0e4a1a	do-photos	ms33hlvi-BINOUT-53-1.jpg	\N	2026-07-27 10:39:34.519253+00	2026-07-27 10:39:34.519253+00	2026-07-27 10:39:34.519253+00	{"eTag": "\\"c67352d5edc0c6acc4796e858e2b8b2d\\"", "size": 216653, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-27T10:39:35.000Z", "contentLength": 216653, "httpStatusCode": 200}	eda58654-8a60-4c17-841d-803557c1880e	\N	{}
992acc65-f7de-42bc-9b3e-6ead9231f71d	do-photos	ms33hlzc-DO-53-1.jpg	\N	2026-07-27 10:39:34.644786+00	2026-07-27 10:39:34.644786+00	2026-07-27 10:39:34.644786+00	{"eTag": "\\"9f31af74b06cce8d420191da74ded93c\\"", "size": 145112, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-27T10:39:35.000Z", "contentLength": 145112, "httpStatusCode": 200}	ce4dfbb4-dd07-466e-b57b-46b44f801da0	\N	{}
b787e613-db19-401f-984d-a01e8f0dafe4	do-photos	ms3z2m8u-BIN-68-1.jpg	\N	2026-07-28 01:23:43.025198+00	2026-07-28 01:23:43.025198+00	2026-07-28 01:23:43.025198+00	{"eTag": "\\"15a06a249ac0731fd16f95616c78c202\\"", "size": 192677, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-28T01:23:43.000Z", "contentLength": 192677, "httpStatusCode": 200}	33334d5f-5726-4309-a5f7-30b6d76a035a	\N	{}
ac75dcbf-d1c4-41bd-9335-dbc7594cef61	do-photos	ms433t2h-BININ-70-1.jpg	\N	2026-07-28 03:16:36.962375+00	2026-07-28 03:16:36.962375+00	2026-07-28 03:16:36.962375+00	{"eTag": "\\"2b48442c2a08c20754f494c1b945d6f9\\"", "size": 308640, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-28T03:16:37.000Z", "contentLength": 308640, "httpStatusCode": 200}	a29cccef-48c6-4e9c-8597-6601f9f1e922	\N	{}
94f10673-d89c-475c-9cb9-cb405d6a51e4	do-photos	ms5zmslm-BININ-80-1.jpg	\N	2026-07-29 11:14:56.753345+00	2026-07-29 11:14:56.753345+00	2026-07-29 11:14:56.753345+00	{"eTag": "\\"b1db9b7012e0d006acd77ca2f672d9b3\\"", "size": 289296, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-29T11:14:57.000Z", "contentLength": 289296, "httpStatusCode": 200}	5325481c-291f-436a-8fa2-d04121420ab8	\N	{}
094ad843-f36f-4be8-b8b9-c81bc0437a01	do-photos	ms433tap-BINOUT-70-1.jpg	\N	2026-07-28 03:16:37.109293+00	2026-07-28 03:16:37.109293+00	2026-07-28 03:16:37.109293+00	{"eTag": "\\"e6d50f408eb7ae4bbf113ed41a35008f\\"", "size": 280755, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-28T03:16:38.000Z", "contentLength": 280755, "httpStatusCode": 200}	d3c518b3-c7ce-4b6e-8554-7ac1b6c53d21	\N	{}
177c16ef-27e1-4dcd-b725-ea00212f8ae7	do-photos	ms433tej-DO-70-1.jpg	\N	2026-07-28 03:16:37.28863+00	2026-07-28 03:16:37.28863+00	2026-07-28 03:16:37.28863+00	{"eTag": "\\"62b9cc0610cff56dfa48b97923fffdda\\"", "size": 258425, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-28T03:16:38.000Z", "contentLength": 258425, "httpStatusCode": 200}	f80c637a-53a1-44a4-8dcd-6cbef5444ba4	\N	{}
74850299-2741-4637-86b8-ba543d663f65	do-photos	ms5zmstf-BINOUT-80-1.jpg	\N	2026-07-29 11:14:56.926479+00	2026-07-29 11:14:56.926479+00	2026-07-29 11:14:56.926479+00	{"eTag": "\\"a0b00a895bc3e7375bff79ba45f87569\\"", "size": 292989, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-29T11:14:57.000Z", "contentLength": 292989, "httpStatusCode": 200}	b0569b1a-25ea-4dc2-a58b-1e0bb72dc69d	\N	{}
408728b9-b245-4816-9011-0cf59eb02c4e	do-photos	ms451ots-BININ-69-1.jpg	\N	2026-07-28 04:10:57.368568+00	2026-07-28 04:10:57.368568+00	2026-07-28 04:10:57.368568+00	{"eTag": "\\"5d460229a9f91aabce8fb88a2c68a174\\"", "size": 301085, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-28T04:10:58.000Z", "contentLength": 301085, "httpStatusCode": 200}	8cb43ccf-465e-4fa8-9b61-d565ac681b1d	\N	{}
f80aaab4-f03a-4f10-b87b-40a38d5a8466	do-photos	ms451p23-BINOUT-69-1.jpg	\N	2026-07-28 04:10:57.620028+00	2026-07-28 04:10:57.620028+00	2026-07-28 04:10:57.620028+00	{"eTag": "\\"86ec596ff3dff2f06d80d348ee6bf76b\\"", "size": 329315, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-28T04:10:58.000Z", "contentLength": 329315, "httpStatusCode": 200}	f775c80f-4700-41c9-b8d3-a0ea5a34b5f3	\N	{}
9929d66e-67b7-48b5-ae27-f65011f903ab	do-photos	ms5zmsyg-DO-80-1.jpg	\N	2026-07-29 11:14:57.089014+00	2026-07-29 11:14:57.089014+00	2026-07-29 11:14:57.089014+00	{"eTag": "\\"f58cc5ae35af5c53b4c396693ed61b4c\\"", "size": 200423, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-29T11:14:58.000Z", "contentLength": 200423, "httpStatusCode": 200}	38a4328a-b4a6-429e-bd88-988e81805e35	\N	{}
9768079c-42c9-4665-b614-e03832b25704	do-photos	ms451p83-DO-69-1.jpg	\N	2026-07-28 04:10:57.794011+00	2026-07-28 04:10:57.794011+00	2026-07-28 04:10:57.794011+00	{"eTag": "\\"16ce105743d471b4f74f0250b55c715a\\"", "size": 252043, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-28T04:10:58.000Z", "contentLength": 252043, "httpStatusCode": 200}	1165fc37-d727-4a5f-98f1-30ae2c194686	\N	{}
568b0766-198a-4ef4-ab40-c03c4bc7ac33	do-photos	ms5atplk-BININ-71-1.jpg	\N	2026-07-28 23:40:29.082177+00	2026-07-28 23:40:29.082177+00	2026-07-28 23:40:29.082177+00	{"eTag": "\\"7d7815312af02255b3af0e2db8bb3ed4\\"", "size": 292773, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-28T23:40:30.000Z", "contentLength": 292773, "httpStatusCode": 200}	01fd959a-9edc-498c-93c7-2b81e07f7843	\N	{}
6852edc1-d03e-4d18-80a0-522388dfeaa6	do-photos	ms6vl45v-DO-94-1.jpg	\N	2026-07-30 02:09:26.07607+00	2026-07-30 02:09:26.07607+00	2026-07-30 02:09:26.07607+00	{"eTag": "\\"72bf26caa14936a104ee99ea59881d1f\\"", "size": 469360, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-30T02:09:27.000Z", "contentLength": 469360, "httpStatusCode": 200}	0ec13a48-1534-4819-aa3c-8d99d14aa4e7	\N	{}
29250a31-fe72-4154-92df-1136ca33ec0b	do-photos	ms5atpuq-BINOUT-71-1.jpg	\N	2026-07-28 23:40:29.27837+00	2026-07-28 23:40:29.27837+00	2026-07-28 23:40:29.27837+00	{"eTag": "\\"cf50342877c7fc98f78d18888a5f3f8f\\"", "size": 329708, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-28T23:40:30.000Z", "contentLength": 329708, "httpStatusCode": 200}	ef9e9544-b0ae-4f84-ab51-f4590e0bb551	\N	{}
14a6ec32-8c35-467b-bdd5-7b4492ddf0dd	do-photos	ms5b71vv-DO-71-1.jpg	\N	2026-07-28 23:50:51.505618+00	2026-07-28 23:50:51.505618+00	2026-07-28 23:50:51.505618+00	{"eTag": "\\"f62b56132d3e4c508ad37fa188025938\\"", "size": 209781, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-28T23:50:52.000Z", "contentLength": 209781, "httpStatusCode": 200}	3da04c55-6b7a-4d5e-af62-c4d1be49fa52	\N	{}
2c10542a-1707-44a6-ab2b-02cf8ce2591d	do-photos	ms5soxc5-BININ-72-1.jpg	\N	2026-07-29 08:00:38.944727+00	2026-07-29 08:00:38.944727+00	2026-07-29 08:00:38.944727+00	{"eTag": "\\"f5cc6be90c7dae157ce7af8aa374368b\\"", "size": 303121, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-29T08:00:39.000Z", "contentLength": 303121, "httpStatusCode": 200}	785b9299-030d-4bbf-b050-c547a01fc4e8	\N	{}
bab214d8-4a45-4212-9ebc-b8da468e9e67	do-photos	ms5soxml-BINOUT-72-1.jpg	\N	2026-07-29 08:00:39.087811+00	2026-07-29 08:00:39.087811+00	2026-07-29 08:00:39.087811+00	{"eTag": "\\"f5cc6be90c7dae157ce7af8aa374368b\\"", "size": 303121, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-29T08:00:40.000Z", "contentLength": 303121, "httpStatusCode": 200}	42dfc52c-c764-4c72-b026-dd0ca98f7b1a	\N	{}
7ec65c23-4c47-4b9b-ab4e-8c730ac301ef	do-photos	ms5soxqm-DO-72-1.jpg	\N	2026-07-29 08:00:39.259754+00	2026-07-29 08:00:39.259754+00	2026-07-29 08:00:39.259754+00	{"eTag": "\\"45f312e23543db6da1e67d8c6d539476\\"", "size": 225406, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-29T08:00:40.000Z", "contentLength": 225406, "httpStatusCode": 200}	fdef2477-c4f9-4cee-bf53-7a7461a7e76e	\N	{}
6dd0714b-858a-4edb-8106-ebc806badc9f	do-photos	ms5sqrla-BININ-73-1.jpg	\N	2026-07-29 08:02:04.657226+00	2026-07-29 08:02:04.657226+00	2026-07-29 08:02:04.657226+00	{"eTag": "\\"3c6c0126428f5b084ef4384680dee803\\"", "size": 389006, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-29T08:02:05.000Z", "contentLength": 389006, "httpStatusCode": 200}	beb6a87f-4574-42a9-9ed6-ff1f573a900a	\N	{}
6df10128-1983-41ad-a199-771287e47e00	do-photos	ms6rc9rj-BIN-86-1.jpg	\N	2026-07-30 00:10:35.01847+00	2026-07-30 00:10:35.01847+00	2026-07-30 00:10:35.01847+00	{"eTag": "\\"4da756c5848e8b085724b029a4f59a3c\\"", "size": 179573, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-30T00:10:36.000Z", "contentLength": 179573, "httpStatusCode": 200}	0936b722-ab05-4ea9-a684-d723f9fe20ff	\N	{}
0de7502d-c38c-4d37-ba3f-dfdc1800c3d0	do-photos	ms5sqrrd-BINOUT-73-1.jpg	\N	2026-07-29 08:02:04.821476+00	2026-07-29 08:02:04.821476+00	2026-07-29 08:02:04.821476+00	{"eTag": "\\"d2899b1bde64bc1b5c3bcb9b1111f7ec\\"", "size": 406997, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-29T08:02:05.000Z", "contentLength": 406997, "httpStatusCode": 200}	bc55dc76-a6d5-480f-b5ba-a8f62ee21038	\N	{}
c56077fc-b233-4ebe-9ee1-e72c9c4e3660	do-photos	ms5sqrw2-DO-73-1.jpg	\N	2026-07-29 08:02:04.995031+00	2026-07-29 08:02:04.995031+00	2026-07-29 08:02:04.995031+00	{"eTag": "\\"ec9d52faa90e158fe282e287b21cb308\\"", "size": 253523, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-29T08:02:05.000Z", "contentLength": 253523, "httpStatusCode": 200}	1e518ae0-11c2-45f8-9d6f-0af4ea9478e6	\N	{}
47fdb20d-19e9-4615-8b6d-fdff666c2bb6	do-photos	ms6vl4ed-SIG-94-1.jpg	\N	2026-07-30 02:09:26.195618+00	2026-07-30 02:09:26.195618+00	2026-07-30 02:09:26.195618+00	{"eTag": "\\"4394ed0f0f7517c9581dcab1f3a3c871\\"", "size": 4202, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-30T02:09:27.000Z", "contentLength": 4202, "httpStatusCode": 200}	8dfd76ef-9fb8-4d73-b4b8-c82b16daf752	\N	{}
04338110-97d8-4676-b060-a5952926753b	do-photos	ms5ss9ma-BININ-74-1.jpg	\N	2026-07-29 08:03:14.640472+00	2026-07-29 08:03:14.640472+00	2026-07-29 08:03:14.640472+00	{"eTag": "\\"d03fa4b6faaf0bb148cc177d383ed114\\"", "size": 304260, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-29T08:03:15.000Z", "contentLength": 304260, "httpStatusCode": 200}	2d777b62-bd04-4f77-95c9-bf599158940a	\N	{}
e21c95d7-f7a9-4150-ab2a-d8eec381fb1c	do-photos	ms5ss9rk-BINOUT-74-1.jpg	\N	2026-07-29 08:03:14.786505+00	2026-07-29 08:03:14.786505+00	2026-07-29 08:03:14.786505+00	{"eTag": "\\"d03fa4b6faaf0bb148cc177d383ed114\\"", "size": 304260, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-29T08:03:15.000Z", "contentLength": 304260, "httpStatusCode": 200}	6febb906-cf71-44a3-8749-f046fbfd026a	\N	{}
c0847090-7464-43dc-a358-1eb539019031	do-photos	ms6yljh2-BINOUT-95-1.jpg	\N	2026-07-30 03:33:44.665397+00	2026-07-30 03:33:44.665397+00	2026-07-30 03:33:44.665397+00	{"eTag": "\\"bf9c3257a87a8abff5c3742c45f83362\\"", "size": 207968, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-30T03:33:45.000Z", "contentLength": 207968, "httpStatusCode": 200}	d02a3966-f9c9-49ab-9abe-bd4ab0aa2a8e	\N	{}
f09101e4-4c9f-4581-8d68-ed9f6382b0d8	do-photos	ms5ss9vo-DO-74-1.jpg	\N	2026-07-29 08:03:14.999332+00	2026-07-29 08:03:14.999332+00	2026-07-29 08:03:14.999332+00	{"eTag": "\\"5c8b399ba1df0e2e6541fc85d092019a\\"", "size": 257698, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-29T08:03:15.000Z", "contentLength": 257698, "httpStatusCode": 200}	3bf8c914-4f67-471d-95c5-d4d6b43cdaab	\N	{}
6031501e-c076-4721-84d3-924c50720060	do-photos	ms5su7xq-BININ-75-1.jpg	\N	2026-07-29 08:04:45.723359+00	2026-07-29 08:04:45.723359+00	2026-07-29 08:04:45.723359+00	{"eTag": "\\"8cf98d069947fa70b0d47c268729537d\\"", "size": 116712, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-29T08:04:46.000Z", "contentLength": 116712, "httpStatusCode": 200}	8d58e06e-adbb-4b09-abf6-b07fbdae3bf2	\N	{}
3423f829-58ea-4793-ada4-62c9f71922a9	do-photos	ms701kqr-BININ-94-1.jpg	\N	2026-07-30 04:14:12.617492+00	2026-07-30 04:14:12.617492+00	2026-07-30 04:14:12.617492+00	{"eTag": "\\"fea792b0ef144464851fe3c3ce3a3ef7\\"", "size": 334112, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-30T04:14:13.000Z", "contentLength": 334112, "httpStatusCode": 200}	311773ea-8098-499d-a956-3a09ea14166c	\N	{}
1285f24f-b626-4214-8ad6-32311e0bfcf4	do-photos	ms5su81m-BINOUT-75-1.jpg	\N	2026-07-29 08:04:45.87886+00	2026-07-29 08:04:45.87886+00	2026-07-29 08:04:45.87886+00	{"eTag": "\\"8cf98d069947fa70b0d47c268729537d\\"", "size": 116712, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-29T08:04:46.000Z", "contentLength": 116712, "httpStatusCode": 200}	8785ff38-2307-4a0f-bca0-fe4af6f4bda1	\N	{}
864f8945-0b96-4ebf-b745-f8573be5fa6e	do-photos	ms5su85q-DO-75-1.jpg	\N	2026-07-29 08:04:45.988047+00	2026-07-29 08:04:45.988047+00	2026-07-29 08:04:45.988047+00	{"eTag": "\\"8cf98d069947fa70b0d47c268729537d\\"", "size": 116712, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-29T08:04:46.000Z", "contentLength": 116712, "httpStatusCode": 200}	014d8cb9-00c0-4715-8aaf-ab0fa853b6ad	\N	{}
bfe33d7b-9534-4aa3-ac18-3da6f097351d	do-photos	ms5svucu-BININ-76-1.jpg	\N	2026-07-29 08:06:01.49315+00	2026-07-29 08:06:01.49315+00	2026-07-29 08:06:01.49315+00	{"eTag": "\\"c0af5e574e710dddecc31009978b3e4f\\"", "size": 121156, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-29T08:06:02.000Z", "contentLength": 121156, "httpStatusCode": 200}	b6aeed8b-0d62-4db1-ba96-1f3b0edbdcbb	\N	{}
259f78ed-e32e-485f-b400-5877b2e61499	do-photos	ms5svuiu-BINOUT-76-1.jpg	\N	2026-07-29 08:06:01.64164+00	2026-07-29 08:06:01.64164+00	2026-07-29 08:06:01.64164+00	{"eTag": "\\"c0af5e574e710dddecc31009978b3e4f\\"", "size": 121156, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-29T08:06:02.000Z", "contentLength": 121156, "httpStatusCode": 200}	dd60dd1d-37c1-4a1d-8e6b-af2d6104fe78	\N	{}
04897e0d-5be2-4055-b21a-2978a4ab1f19	do-photos	ms5svumm-DO-76-1.jpg	\N	2026-07-29 08:06:01.791273+00	2026-07-29 08:06:01.791273+00	2026-07-29 08:06:01.791273+00	{"eTag": "\\"c0af5e574e710dddecc31009978b3e4f\\"", "size": 121156, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-29T08:06:02.000Z", "contentLength": 121156, "httpStatusCode": 200}	c1599212-cb71-42c0-ac2a-58f8df2c72cb	\N	{}
3e40e350-3c1a-46c1-b2aa-f3fdcbf1a64f	do-photos	ms5sy324-BININ-77-1.jpg	\N	2026-07-29 08:07:46.057716+00	2026-07-29 08:07:46.057716+00	2026-07-29 08:07:46.057716+00	{"eTag": "\\"e8702dea9c1b0d2ddbefb65f108dbc12\\"", "size": 213840, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-29T08:07:47.000Z", "contentLength": 213840, "httpStatusCode": 200}	b8a34bad-4cdc-45a3-bcf3-15e76b33a9e6	\N	{}
9d1ed8df-6a20-492c-a61d-ceddd5f1e479	do-photos	ms6t5ylt-BININ-92-1.jpg	\N	2026-07-30 01:01:39.997792+00	2026-07-30 01:01:39.997792+00	2026-07-30 01:01:39.997792+00	{"eTag": "\\"bdb1c328531e819fc2feb2677ae3adfe\\"", "size": 454203, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-30T01:01:40.000Z", "contentLength": 454203, "httpStatusCode": 200}	917a3a3d-18b9-45c5-b968-b2277d5a2c84	\N	{}
ea6bf4a6-79c3-4a5b-b622-d808cb222bab	do-photos	ms5sy370-BINOUT-77-1.jpg	\N	2026-07-29 08:07:46.242405+00	2026-07-29 08:07:46.242405+00	2026-07-29 08:07:46.242405+00	{"eTag": "\\"c32ab61a9c94ae600c7b6f9238bd17fd\\"", "size": 327166, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-29T08:07:47.000Z", "contentLength": 327166, "httpStatusCode": 200}	ec2ce9e4-79ed-42a3-841c-3ac4e5a31870	\N	{}
e7f1234d-fa89-48f0-a30d-6e6d88084c00	do-photos	ms5sy3bv-DO-77-1.jpg	\N	2026-07-29 08:07:46.382067+00	2026-07-29 08:07:46.382067+00	2026-07-29 08:07:46.382067+00	{"eTag": "\\"5cd246849387d5f9917193549a0ef443\\"", "size": 248291, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-29T08:07:47.000Z", "contentLength": 248291, "httpStatusCode": 200}	f33c7454-ee7b-482f-a4d3-10f0c3284ba2	\N	{}
e5bc0ba1-ca2e-4567-82e8-663a5bf8b57b	do-photos	ms6t5yzk-BINOUT-92-1.jpg	\N	2026-07-30 01:01:40.483181+00	2026-07-30 01:01:40.483181+00	2026-07-30 01:01:40.483181+00	{"eTag": "\\"bdb1c328531e819fc2feb2677ae3adfe\\"", "size": 454203, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-30T01:01:41.000Z", "contentLength": 454203, "httpStatusCode": 200}	032f3818-e352-46c9-b817-1939fb747437	\N	{}
8edddf26-fcc2-442f-b3e8-4ce5bf795ff2	do-photos	ms6t5zcv-DO-92-1.jpg	\N	2026-07-30 01:01:40.60038+00	2026-07-30 01:01:40.60038+00	2026-07-30 01:01:40.60038+00	{"eTag": "\\"046e98f781de7fae30fbe8a406e1c234\\"", "size": 283661, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-30T01:01:41.000Z", "contentLength": 283661, "httpStatusCode": 200}	d85a5fa5-4d95-4f19-b0e5-62881a32b308	\N	{}
f3dd7738-bb64-4780-9d1c-6d88410114b1	do-photos	ms6wbvag-BININ-87-1.jpg	\N	2026-07-30 02:30:14.304885+00	2026-07-30 02:30:14.304885+00	2026-07-30 02:30:14.304885+00	{"eTag": "\\"ac347573b95120421dfdb5629e6936e3\\"", "size": 322351, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-30T02:30:15.000Z", "contentLength": 322351, "httpStatusCode": 200}	7cdd82a2-b69e-4f87-b778-d8784c0018ea	\N	{}
172c5960-c268-4c73-a8b5-5c6161933cce	do-photos	ms6wbvjf-BINOUT-87-1.jpg	\N	2026-07-30 02:30:14.542277+00	2026-07-30 02:30:14.542277+00	2026-07-30 02:30:14.542277+00	{"eTag": "\\"ac347573b95120421dfdb5629e6936e3\\"", "size": 322351, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-30T02:30:15.000Z", "contentLength": 322351, "httpStatusCode": 200}	96507ef4-617c-4aa8-98dc-f198fe5874d9	\N	{}
1b1e447a-92d9-4081-b0e4-e4b0a97e11c3	do-photos	ms6wbvrq-DO-87-1.jpg	\N	2026-07-30 02:30:14.73512+00	2026-07-30 02:30:14.73512+00	2026-07-30 02:30:14.73512+00	{"eTag": "\\"692257d85d6465a69c4560c3302a0d3c\\"", "size": 270393, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-30T02:30:15.000Z", "contentLength": 270393, "httpStatusCode": 200}	ad8c5658-23e1-4a57-be56-30f47214b219	\N	{}
de9909fa-e922-4c95-a3de-dcd0ad717ca1	do-photos	ms6wbvv6-SIG-87-1.jpg	\N	2026-07-30 02:30:14.843424+00	2026-07-30 02:30:14.843424+00	2026-07-30 02:30:14.843424+00	{"eTag": "\\"a6399e28cb62eb187458d4fe34ee671e\\"", "size": 4077, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-30T02:30:15.000Z", "contentLength": 4077, "httpStatusCode": 200}	1f87bdfb-bb13-419b-a0a6-dc2df613e4d8	\N	{}
5b9bc6f1-6b63-4294-9771-697650eb4a6c	do-photos	ms6ymuzj-DO-95-1.jpg	\N	2026-07-30 03:34:46.257816+00	2026-07-30 03:34:46.257816+00	2026-07-30 03:34:46.257816+00	{"eTag": "\\"54a8cc9372088cf9c2b11e1bac73819e\\"", "size": 211820, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-30T03:34:47.000Z", "contentLength": 211820, "httpStatusCode": 200}	20213c08-2b77-4e45-88a4-8be91c34cd40	\N	{}
70756de6-2edf-4d67-bdef-0e4e7a083248	do-photos	ms701lfz-BINOUT-94-1.jpg	\N	2026-07-30 04:14:13.369569+00	2026-07-30 04:14:13.369569+00	2026-07-30 04:14:13.369569+00	{"eTag": "\\"314916170aad40d3b4fc3f9ed0b3910c\\"", "size": 301990, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-30T04:14:14.000Z", "contentLength": 301990, "httpStatusCode": 200}	5687f605-e483-46fc-ba3e-97e69aa81b2b	\N	{}
f2de82a2-361b-4304-8691-88dc813a1243	do-photos	ms7022jl-BININ-96-1.jpg	\N	2026-07-30 04:14:35.643389+00	2026-07-30 04:14:35.643389+00	2026-07-30 04:14:35.643389+00	{"eTag": "\\"1763785e1b78cac82280d2e02d6cc7d3\\"", "size": 301335, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-30T04:14:36.000Z", "contentLength": 301335, "httpStatusCode": 200}	5cdedf8f-9015-437c-bce3-1932ba2b0234	\N	{}
fde941bc-4c38-455d-a0b1-340e82aace56	do-photos	ms7022tw-BINOUT-96-1.jpg	\N	2026-07-30 04:14:35.884508+00	2026-07-30 04:14:35.884508+00	2026-07-30 04:14:35.884508+00	{"eTag": "\\"87d25a0071bf361409fe5b840b971802\\"", "size": 451935, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-30T04:14:36.000Z", "contentLength": 451935, "httpStatusCode": 200}	4bbab44e-05d4-43c6-bd8c-b366e98c4714	\N	{}
34a29f9e-e6c4-4c4d-a48a-bded01df18fa	do-photos	ms709mp2-DO-96-1.jpg	\N	2026-07-30 04:20:28.32421+00	2026-07-30 04:20:28.32421+00	2026-07-30 04:20:28.32421+00	{"eTag": "\\"e0cf61f669a9c214384ed6b44382b1cb\\"", "size": 286054, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-30T04:20:29.000Z", "contentLength": 286054, "httpStatusCode": 200}	0eacf290-0492-4db4-b53d-36e0022dfcf1	\N	{}
c841c36d-8a8f-4be3-8004-f05283190c23	do-photos	ms72uu5y-BININ-97-1.jpg	\N	2026-07-30 05:32:57.138874+00	2026-07-30 05:32:57.138874+00	2026-07-30 05:32:57.138874+00	{"eTag": "\\"169c795d0bee0d2c5673b9cde908168c\\"", "size": 296844, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-30T05:32:58.000Z", "contentLength": 296844, "httpStatusCode": 200}	258a4970-3cf3-43f4-bf59-eaae50efd05b	\N	{}
b2053913-99ae-422d-84d1-cb6f5e7439ca	do-photos	ms72uuhw-BINOUT-97-1.jpg	\N	2026-07-30 05:32:57.317367+00	2026-07-30 05:32:57.317367+00	2026-07-30 05:32:57.317367+00	{"eTag": "\\"169c795d0bee0d2c5673b9cde908168c\\"", "size": 296844, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-30T05:32:58.000Z", "contentLength": 296844, "httpStatusCode": 200}	c766d200-e0f8-4a4e-9801-b51f26dc25c0	\N	{}
869f4214-f49a-4ef7-83e4-5ba89f11857c	do-photos	ms72uum7-DO-97-1.jpg	\N	2026-07-30 05:32:57.474568+00	2026-07-30 05:32:57.474568+00	2026-07-30 05:32:57.474568+00	{"eTag": "\\"62bc516b26efc1caa11e981148a8ca0a\\"", "size": 260870, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-30T05:32:58.000Z", "contentLength": 260870, "httpStatusCode": 200}	40e7b15f-1900-4673-8ce2-d76cb912e7e7	\N	{}
b120d7e3-9634-46c8-a984-22ff1814285e	do-photos	ms776qh3-BININ-98-1.jpg	\N	2026-07-30 07:34:10.567003+00	2026-07-30 07:34:10.567003+00	2026-07-30 07:34:10.567003+00	{"eTag": "\\"9a0651d15a496bc2066b5287274dafda\\"", "size": 356137, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-30T07:34:11.000Z", "contentLength": 356137, "httpStatusCode": 200}	3fd94487-cfb3-4d6c-bc0b-2eeda9429e32	\N	{}
14c60dca-dba5-47dc-b748-2aa24e09cbd3	do-photos	ms776qqi-BINOUT-98-1.jpg	\N	2026-07-30 07:34:10.803163+00	2026-07-30 07:34:10.803163+00	2026-07-30 07:34:10.803163+00	{"eTag": "\\"9a0651d15a496bc2066b5287274dafda\\"", "size": 356137, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-30T07:34:11.000Z", "contentLength": 356137, "httpStatusCode": 200}	de73bc85-f750-48d6-9986-9e5754b42882	\N	{}
c00bac2b-de0b-4e0d-a2de-e2cd9fb46d1b	do-photos	ms776qx7-DO-98-1.jpg	\N	2026-07-30 07:34:10.974078+00	2026-07-30 07:34:10.974078+00	2026-07-30 07:34:10.974078+00	{"eTag": "\\"8c2ed73889fc6731857558972c72bf55\\"", "size": 281991, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-30T07:34:11.000Z", "contentLength": 281991, "httpStatusCode": 200}	6049f0d9-be75-4fc2-99f4-dec787103988	\N	{}
dc0566c2-8989-42f5-b9ab-7533eb03f318	do-photos	ms86dtbl-BININ-110-1.jpg	\N	2026-07-30 23:59:27.370849+00	2026-07-30 23:59:27.370849+00	2026-07-30 23:59:27.370849+00	{"eTag": "\\"ecd9e6d88245fd28101a2ace23cd272c\\"", "size": 221862, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-30T23:59:28.000Z", "contentLength": 221862, "httpStatusCode": 200}	5ab7fb10-2543-4bf8-bf8f-bbfe578e922e	\N	{}
ab7bb0a5-dc6a-48f1-bbba-d23f152e96e2	do-photos	ms86dtjw-BINOUT-110-1.jpg	\N	2026-07-30 23:59:27.585857+00	2026-07-30 23:59:27.585857+00	2026-07-30 23:59:27.585857+00	{"eTag": "\\"b1431b2864b0a0c22df5a5c008ce5e20\\"", "size": 337885, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-30T23:59:28.000Z", "contentLength": 337885, "httpStatusCode": 200}	6e2f1481-5be6-4121-8b85-7b0d8422e2a7	\N	{}
2ec5d7c4-bddf-4c2e-8b47-2f22402cfd0a	do-photos	ms86y17q-BIN-99-1.jpg	\N	2026-07-31 00:15:10.770056+00	2026-07-31 00:15:10.770056+00	2026-07-31 00:15:10.770056+00	{"eTag": "\\"19bc101e3d828ddc38cd17d7c74d75c9\\"", "size": 189509, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-31T00:15:11.000Z", "contentLength": 189509, "httpStatusCode": 200}	4e184807-4609-4f9d-a094-a8ed22e31fc8	\N	{}
f38a7d99-f269-4b1e-8ab8-37aa91cb5c00	do-photos	ms873vwg-DO-110-1.jpg	\N	2026-07-31 00:19:44.071877+00	2026-07-31 00:19:44.071877+00	2026-07-31 00:19:44.071877+00	{"eTag": "\\"4d4ffc5e7f9b90b63302e4493327521a\\"", "size": 212484, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-31T00:19:45.000Z", "contentLength": 212484, "httpStatusCode": 200}	dde1bbcb-e1f7-4523-99d7-46807bf003a5	\N	{}
2f529093-82a3-42a5-93e0-1c8885aa0275	do-photos	ms8d74vt-BININ-112-1.jpg	\N	2026-07-31 03:10:13.133165+00	2026-07-31 03:10:13.133165+00	2026-07-31 03:10:13.133165+00	{"eTag": "\\"c966083aa4f885a6e2d5c2136c24aa26\\"", "size": 434221, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-31T03:10:14.000Z", "contentLength": 434221, "httpStatusCode": 200}	bf52a7f9-ff33-4a5b-ab10-e7ed61d7af24	\N	{}
6c1fb602-ad15-42b3-b626-4126cdf8745d	do-photos	ms8d755c-BINOUT-112-1.jpg	\N	2026-07-31 03:10:13.301581+00	2026-07-31 03:10:13.301581+00	2026-07-31 03:10:13.301581+00	{"eTag": "\\"c966083aa4f885a6e2d5c2136c24aa26\\"", "size": 434221, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-31T03:10:14.000Z", "contentLength": 434221, "httpStatusCode": 200}	79af14c3-a4fd-4598-956e-8a69cb346b9a	\N	{}
5fb565a9-71c6-41e8-99b3-f3353dc98d1e	do-photos	ms8d759v-DO-112-1.jpg	\N	2026-07-31 03:10:13.44459+00	2026-07-31 03:10:13.44459+00	2026-07-31 03:10:13.44459+00	{"eTag": "\\"efd355c1ffd75c674aa498f684e52214\\"", "size": 283409, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-31T03:10:14.000Z", "contentLength": 283409, "httpStatusCode": 200}	d422afb7-a638-4a91-8cba-a85d6dbb1da1	\N	{}
77e0ca99-219e-49a4-8b77-2c287ff95b6e	do-photos	ms8d75e1-SIG-112-1.jpg	\N	2026-07-31 03:10:13.543845+00	2026-07-31 03:10:13.543845+00	2026-07-31 03:10:13.543845+00	{"eTag": "\\"0cd5b1ee72027ac5f61902f519bd47e4\\"", "size": 3697, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-31T03:10:14.000Z", "contentLength": 3697, "httpStatusCode": 200}	830f6943-a94e-410f-a890-8cc4226685f3	\N	{}
9385a07a-9060-496b-8223-5d3511b30c85	do-photos	ms8dp492-BINOUT-100-1.jpg	\N	2026-07-31 03:24:12.145369+00	2026-07-31 03:24:12.145369+00	2026-07-31 03:24:12.145369+00	{"eTag": "\\"33ff6a303c9265733c42e2351943bf05\\"", "size": 393983, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-31T03:24:13.000Z", "contentLength": 393983, "httpStatusCode": 200}	31d7ab7d-3f5a-4e74-bbbb-bab4d3dc323f	\N	{}
51fb86a3-1f75-4e38-94c2-294edefdad6e	do-photos	ms8dp4jq-DO-100-1.jpg	\N	2026-07-31 03:24:12.32573+00	2026-07-31 03:24:12.32573+00	2026-07-31 03:24:12.32573+00	{"eTag": "\\"1a85f5060b7ff167f14099022f336573\\"", "size": 308724, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-31T03:24:13.000Z", "contentLength": 308724, "httpStatusCode": 200}	b2472eee-1bb5-4574-ba59-f45e08b66fcb	\N	{}
b58ed589-1a6b-4769-99a7-8e161bcada48	do-photos	ms8dp4o9-SIG-100-1.jpg	\N	2026-07-31 03:24:12.441637+00	2026-07-31 03:24:12.441637+00	2026-07-31 03:24:12.441637+00	{"eTag": "\\"2b55a081cd054a6b68dbc86beeb55bbb\\"", "size": 4694, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-31T03:24:13.000Z", "contentLength": 4694, "httpStatusCode": 200}	c7fd2995-fef0-4f1e-942b-f2c20286a5e8	\N	{}
644107be-f635-49ec-ac65-f18032ebf3e9	do-photos	ms8g1hlh-DO-114-1.jpg	\N	2026-07-31 04:29:48.585687+00	2026-07-31 04:29:48.585687+00	2026-07-31 04:29:48.585687+00	{"eTag": "\\"2ce4bfe2f36a5a14b4dd6d7bc5093efb\\"", "size": 196304, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-31T04:29:49.000Z", "contentLength": 196304, "httpStatusCode": 200}	05b74abe-447c-4c4f-8512-f282ef742488	\N	{}
8bc10243-f9f6-4761-a3e5-03db0e7f25e4	do-photos	ms8g1hvv-SIG-114-1.jpg	\N	2026-07-31 04:29:48.700252+00	2026-07-31 04:29:48.700252+00	2026-07-31 04:29:48.700252+00	{"eTag": "\\"570695288ddb5266520915fc47c8d998\\"", "size": 3764, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-31T04:29:49.000Z", "contentLength": 3764, "httpStatusCode": 200}	d84d55b3-e48e-4bc6-8ae4-4b4d0da19ab2	\N	{}
e8945b7e-eefe-4780-80e8-48e4384b9375	do-photos	ms8m6yfg-BININ-111-1.jpg	\N	2026-07-31 07:22:01.299962+00	2026-07-31 07:22:01.299962+00	2026-07-31 07:22:01.299962+00	{"eTag": "\\"7a36717d143073a4731243d233882618\\"", "size": 261550, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-31T07:22:02.000Z", "contentLength": 261550, "httpStatusCode": 200}	da76ec6d-10f2-4bbb-8b1b-50d0ddc91b0c	\N	{}
29fe8103-6f2f-4a23-a8a9-8aaeee50d15a	do-photos	ms8m6yp2-BINOUT-111-1.jpg	\N	2026-07-31 07:22:01.505893+00	2026-07-31 07:22:01.505893+00	2026-07-31 07:22:01.505893+00	{"eTag": "\\"c37d6e4d49c207bdb4f747ea2cf71b85\\"", "size": 335342, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-31T07:22:02.000Z", "contentLength": 335342, "httpStatusCode": 200}	1a12c33f-3e5f-4e3e-918d-ef90768b7ff8	\N	{}
1686d9c2-865b-454d-978c-e7961d025941	do-photos	ms8m6yuq-DO-111-1.jpg	\N	2026-07-31 07:22:01.686415+00	2026-07-31 07:22:01.686415+00	2026-07-31 07:22:01.686415+00	{"eTag": "\\"08fd98d9882b5cc544a3f4ba71cc38ff\\"", "size": 239473, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-31T07:22:02.000Z", "contentLength": 239473, "httpStatusCode": 200}	2f62d276-7861-44a8-aaed-387b7b69f3dc	\N	{}
f5b959a6-0be4-4818-9b05-b5580879172d	do-photos	ms8owgjr-BININ-115-1.jpg	\N	2026-07-31 08:37:50.848774+00	2026-07-31 08:37:50.848774+00	2026-07-31 08:37:50.848774+00	{"eTag": "\\"873673c96902af8458df9228358bf6c6\\"", "size": 242088, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-31T08:37:51.000Z", "contentLength": 242088, "httpStatusCode": 200}	ceef183d-11a0-4839-bc40-b8360705c0bf	\N	{}
3bc9ecbf-a3ef-442c-9a7b-ce91aec14068	do-photos	ms8owh4y-BINOUT-115-1.jpg	\N	2026-07-31 08:37:51.008166+00	2026-07-31 08:37:51.008166+00	2026-07-31 08:37:51.008166+00	{"eTag": "\\"873673c96902af8458df9228358bf6c6\\"", "size": 242088, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-31T08:37:51.000Z", "contentLength": 242088, "httpStatusCode": 200}	cc7939cd-89b4-4a50-b345-86fc131d7ff0	\N	{}
2b570d55-e85e-4561-b480-67c7dbe05be3	do-photos	ms8owh95-DO-115-1.jpg	\N	2026-07-31 08:37:51.131598+00	2026-07-31 08:37:51.131598+00	2026-07-31 08:37:51.131598+00	{"eTag": "\\"9a23f968ee6a598e9d638095fc6a1b69\\"", "size": 245155, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-31T08:37:52.000Z", "contentLength": 245155, "httpStatusCode": 200}	020627e6-a3a3-40df-9053-9d01091eb2b0	\N	{}
827e9ee7-acdd-4ca7-ae9b-27c4b6085159	do-photos	ms8ozoku-BININ-116-1.jpg	\N	2026-07-31 08:40:20.625384+00	2026-07-31 08:40:20.625384+00	2026-07-31 08:40:20.625384+00	{"eTag": "\\"9261b115c2a00e1aa2cc31f0faf6e685\\"", "size": 124442, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-31T08:40:21.000Z", "contentLength": 124442, "httpStatusCode": 200}	86344c8d-04d4-421c-b436-eb69b45e4019	\N	{}
cc4c73c9-0745-40b7-b2a2-5ca27b494cb4	do-photos	ms8ozop7-BINOUT-116-1.jpg	\N	2026-07-31 08:40:20.793036+00	2026-07-31 08:40:20.793036+00	2026-07-31 08:40:20.793036+00	{"eTag": "\\"9261b115c2a00e1aa2cc31f0faf6e685\\"", "size": 124442, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-31T08:40:21.000Z", "contentLength": 124442, "httpStatusCode": 200}	7c7b5e2e-86d6-4302-bb16-d4beed326ff6	\N	{}
9df25361-285b-4d39-b9e5-45bcbb0e78f5	do-photos	ms8ozotx-DO-116-1.jpg	\N	2026-07-31 08:40:20.934444+00	2026-07-31 08:40:20.934444+00	2026-07-31 08:40:20.934444+00	{"eTag": "\\"9261b115c2a00e1aa2cc31f0faf6e685\\"", "size": 124442, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-31T08:40:21.000Z", "contentLength": 124442, "httpStatusCode": 200}	ceb3ea21-6142-4f3f-8214-2ba22a457e8d	\N	{}
\.


--
-- Data for Name: s3_multipart_uploads; Type: TABLE DATA; Schema: storage; Owner: -
--

COPY storage.s3_multipart_uploads (id, in_progress_size, upload_signature, bucket_id, key, version, owner_id, created_at, user_metadata, metadata) FROM stdin;
\.


--
-- Data for Name: s3_multipart_uploads_parts; Type: TABLE DATA; Schema: storage; Owner: -
--

COPY storage.s3_multipart_uploads_parts (id, upload_id, size, part_number, bucket_id, key, etag, owner_id, version, created_at) FROM stdin;
\.


--
-- Data for Name: vector_indexes; Type: TABLE DATA; Schema: storage; Owner: -
--

COPY storage.vector_indexes (id, name, bucket_id, data_type, dimension, distance_metric, metadata_configuration, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: secrets; Type: TABLE DATA; Schema: vault; Owner: -
--

COPY vault.secrets (id, name, description, secret, key_id, nonce, created_at, updated_at) FROM stdin;
\.


--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE SET; Schema: auth; Owner: -
--

SELECT pg_catalog.setval('auth.refresh_tokens_id_seq', 1, false);


--
-- Name: jobid_seq; Type: SEQUENCE SET; Schema: cron; Owner: -
--

SELECT pg_catalog.setval('cron.jobid_seq', 1, true);


--
-- Name: runid_seq; Type: SEQUENCE SET; Schema: cron; Owner: -
--

SELECT pg_catalog.setval('cron.runid_seq', 3, true);


--
-- Name: adjustments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.adjustments_id_seq', 15, true);


--
-- Name: audit_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.audit_log_id_seq', 258, true);


--
-- Name: factors_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.factors_id_seq', 8, true);


--
-- Name: fuel_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.fuel_log_id_seq', 20, true);


--
-- Name: interest_leads_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.interest_leads_id_seq', 2, true);


--
-- Name: jobcard_overrides_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.jobcard_overrides_id_seq', 6, true);


--
-- Name: maintenance_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.maintenance_id_seq', 1, false);


--
-- Name: odometer_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.odometer_log_id_seq', 24, true);


--
-- Name: onward_disposal_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.onward_disposal_id_seq', 1, false);


--
-- Name: portal_accounts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.portal_accounts_id_seq', 1, false);


--
-- Name: rate_card_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.rate_card_id_seq', 2801, true);


--
-- Name: yard_inbound_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.yard_inbound_id_seq', 1, false);


--
-- Name: yard_stock_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.yard_stock_id_seq', 1, false);


--
-- Name: subscription_id_seq; Type: SEQUENCE SET; Schema: realtime; Owner: -
--

SELECT pg_catalog.setval('realtime.subscription_id_seq', 1, false);


--
-- Name: mfa_amr_claims amr_id_pk; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_amr_claims
    ADD CONSTRAINT amr_id_pk PRIMARY KEY (id);


--
-- Name: audit_log_entries audit_log_entries_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.audit_log_entries
    ADD CONSTRAINT audit_log_entries_pkey PRIMARY KEY (id);


--
-- Name: custom_oauth_providers custom_oauth_providers_identifier_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.custom_oauth_providers
    ADD CONSTRAINT custom_oauth_providers_identifier_key UNIQUE (identifier);


--
-- Name: custom_oauth_providers custom_oauth_providers_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.custom_oauth_providers
    ADD CONSTRAINT custom_oauth_providers_pkey PRIMARY KEY (id);


--
-- Name: flow_state flow_state_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.flow_state
    ADD CONSTRAINT flow_state_pkey PRIMARY KEY (id);


--
-- Name: identities identities_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.identities
    ADD CONSTRAINT identities_pkey PRIMARY KEY (id);


--
-- Name: identities identities_provider_id_provider_unique; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.identities
    ADD CONSTRAINT identities_provider_id_provider_unique UNIQUE (provider_id, provider);


--
-- Name: instances instances_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.instances
    ADD CONSTRAINT instances_pkey PRIMARY KEY (id);


--
-- Name: mfa_amr_claims mfa_amr_claims_session_id_authentication_method_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_amr_claims
    ADD CONSTRAINT mfa_amr_claims_session_id_authentication_method_pkey UNIQUE (session_id, authentication_method);


--
-- Name: mfa_challenges mfa_challenges_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_challenges
    ADD CONSTRAINT mfa_challenges_pkey PRIMARY KEY (id);


--
-- Name: mfa_factors mfa_factors_last_challenged_at_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_factors
    ADD CONSTRAINT mfa_factors_last_challenged_at_key UNIQUE (last_challenged_at);


--
-- Name: mfa_factors mfa_factors_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_factors
    ADD CONSTRAINT mfa_factors_pkey PRIMARY KEY (id);


--
-- Name: oauth_authorizations oauth_authorizations_authorization_code_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_authorizations
    ADD CONSTRAINT oauth_authorizations_authorization_code_key UNIQUE (authorization_code);


--
-- Name: oauth_authorizations oauth_authorizations_authorization_id_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_authorizations
    ADD CONSTRAINT oauth_authorizations_authorization_id_key UNIQUE (authorization_id);


--
-- Name: oauth_authorizations oauth_authorizations_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_authorizations
    ADD CONSTRAINT oauth_authorizations_pkey PRIMARY KEY (id);


--
-- Name: oauth_client_states oauth_client_states_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_client_states
    ADD CONSTRAINT oauth_client_states_pkey PRIMARY KEY (id);


--
-- Name: oauth_clients oauth_clients_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_clients
    ADD CONSTRAINT oauth_clients_pkey PRIMARY KEY (id);


--
-- Name: oauth_consents oauth_consents_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_consents
    ADD CONSTRAINT oauth_consents_pkey PRIMARY KEY (id);


--
-- Name: oauth_consents oauth_consents_user_client_unique; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_consents
    ADD CONSTRAINT oauth_consents_user_client_unique UNIQUE (user_id, client_id);


--
-- Name: one_time_tokens one_time_tokens_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.one_time_tokens
    ADD CONSTRAINT one_time_tokens_pkey PRIMARY KEY (id);


--
-- Name: refresh_tokens refresh_tokens_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.refresh_tokens
    ADD CONSTRAINT refresh_tokens_pkey PRIMARY KEY (id);


--
-- Name: refresh_tokens refresh_tokens_token_unique; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.refresh_tokens
    ADD CONSTRAINT refresh_tokens_token_unique UNIQUE (token);


--
-- Name: saml_providers saml_providers_entity_id_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_providers
    ADD CONSTRAINT saml_providers_entity_id_key UNIQUE (entity_id);


--
-- Name: saml_providers saml_providers_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_providers
    ADD CONSTRAINT saml_providers_pkey PRIMARY KEY (id);


--
-- Name: saml_relay_states saml_relay_states_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_relay_states
    ADD CONSTRAINT saml_relay_states_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: sso_domains sso_domains_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sso_domains
    ADD CONSTRAINT sso_domains_pkey PRIMARY KEY (id);


--
-- Name: sso_providers sso_providers_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sso_providers
    ADD CONSTRAINT sso_providers_pkey PRIMARY KEY (id);


--
-- Name: users users_phone_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.users
    ADD CONSTRAINT users_phone_key UNIQUE (phone);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: webauthn_challenges webauthn_challenges_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.webauthn_challenges
    ADD CONSTRAINT webauthn_challenges_pkey PRIMARY KEY (id);


--
-- Name: webauthn_credentials webauthn_credentials_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.webauthn_credentials
    ADD CONSTRAINT webauthn_credentials_pkey PRIMARY KEY (id);


--
-- Name: adjustments adjustments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adjustments
    ADD CONSTRAINT adjustments_pkey PRIMARY KEY (id);


--
-- Name: app_state app_state_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.app_state
    ADD CONSTRAINT app_state_pkey PRIMARY KEY (id);


--
-- Name: approved_domains approved_domains_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.approved_domains
    ADD CONSTRAINT approved_domains_pkey PRIMARY KEY (domain);


--
-- Name: audit_log audit_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_log
    ADD CONSTRAINT audit_log_pkey PRIMARY KEY (id);


--
-- Name: bins bins_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bins
    ADD CONSTRAINT bins_pkey PRIMARY KEY (bin_id);


--
-- Name: collections collections_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collections
    ADD CONSTRAINT collections_pkey PRIMARY KEY (do_no);


--
-- Name: customers customers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_pkey PRIMARY KEY (client_id);


--
-- Name: drivers drivers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.drivers
    ADD CONSTRAINT drivers_pkey PRIMARY KEY (driver_id);


--
-- Name: facilities facilities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.facilities
    ADD CONSTRAINT facilities_pkey PRIMARY KEY (facility_id);


--
-- Name: factors factors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.factors
    ADD CONSTRAINT factors_pkey PRIMARY KEY (id);


--
-- Name: fuel_log fuel_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fuel_log
    ADD CONSTRAINT fuel_log_pkey PRIMARY KEY (id);


--
-- Name: interest_leads interest_leads_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.interest_leads
    ADD CONSTRAINT interest_leads_pkey PRIMARY KEY (id);


--
-- Name: jobcard_overrides jobcard_overrides_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.jobcard_overrides
    ADD CONSTRAINT jobcard_overrides_pkey PRIMARY KEY (id);


--
-- Name: jobs jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.jobs
    ADD CONSTRAINT jobs_pkey PRIMARY KEY (job_no);


--
-- Name: maintenance maintenance_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance
    ADD CONSTRAINT maintenance_pkey PRIMARY KEY (id);


--
-- Name: odometer_log odometer_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.odometer_log
    ADD CONSTRAINT odometer_log_pkey PRIMARY KEY (id);


--
-- Name: onward_disposal onward_disposal_do_no_hop_no_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.onward_disposal
    ADD CONSTRAINT onward_disposal_do_no_hop_no_key UNIQUE (do_no, hop_no);


--
-- Name: onward_disposal onward_disposal_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.onward_disposal
    ADD CONSTRAINT onward_disposal_pkey PRIMARY KEY (id);


--
-- Name: portal_accounts portal_accounts_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.portal_accounts
    ADD CONSTRAINT portal_accounts_email_key UNIQUE (email);


--
-- Name: portal_accounts portal_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.portal_accounts
    ADD CONSTRAINT portal_accounts_pkey PRIMARY KEY (id);


--
-- Name: rate_card rate_card_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rate_card
    ADD CONSTRAINT rate_card_pkey PRIMARY KEY (id);


--
-- Name: rate_card rate_card_site_id_job_type_valid_from_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rate_card
    ADD CONSTRAINT rate_card_site_id_job_type_valid_from_key UNIQUE (site_id, job_type, valid_from);


--
-- Name: ref_lists ref_lists_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ref_lists
    ADD CONSTRAINT ref_lists_pkey PRIMARY KEY (kind, value);


--
-- Name: sites sites_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sites
    ADD CONSTRAINT sites_pkey PRIMARY KEY (site_id);


--
-- Name: vehicles vehicles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicles
    ADD CONSTRAINT vehicles_pkey PRIMARY KEY (vehicle_id);


--
-- Name: yard_inbound yard_inbound_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.yard_inbound
    ADD CONSTRAINT yard_inbound_pkey PRIMARY KEY (id);


--
-- Name: yard_stock yard_stock_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.yard_stock
    ADD CONSTRAINT yard_stock_pkey PRIMARY KEY (id);


--
-- Name: messages messages_payload_exclusive; Type: CHECK CONSTRAINT; Schema: realtime; Owner: -
--

ALTER TABLE realtime.messages
    ADD CONSTRAINT messages_payload_exclusive CHECK (((payload IS NULL) OR (binary_payload IS NULL))) NOT VALID;


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: realtime; Owner: -
--

ALTER TABLE ONLY realtime.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id, inserted_at);


--
-- Name: subscription pk_subscription; Type: CONSTRAINT; Schema: realtime; Owner: -
--

ALTER TABLE ONLY realtime.subscription
    ADD CONSTRAINT pk_subscription PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: realtime; Owner: -
--

ALTER TABLE ONLY realtime.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: buckets_analytics buckets_analytics_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.buckets_analytics
    ADD CONSTRAINT buckets_analytics_pkey PRIMARY KEY (id);


--
-- Name: buckets buckets_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.buckets
    ADD CONSTRAINT buckets_pkey PRIMARY KEY (id);


--
-- Name: buckets_vectors buckets_vectors_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.buckets_vectors
    ADD CONSTRAINT buckets_vectors_pkey PRIMARY KEY (id);


--
-- Name: migrations migrations_name_key; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.migrations
    ADD CONSTRAINT migrations_name_key UNIQUE (name);


--
-- Name: migrations migrations_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.migrations
    ADD CONSTRAINT migrations_pkey PRIMARY KEY (id);


--
-- Name: objects objects_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.objects
    ADD CONSTRAINT objects_pkey PRIMARY KEY (id);


--
-- Name: s3_multipart_uploads_parts s3_multipart_uploads_parts_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.s3_multipart_uploads_parts
    ADD CONSTRAINT s3_multipart_uploads_parts_pkey PRIMARY KEY (id);


--
-- Name: s3_multipart_uploads s3_multipart_uploads_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.s3_multipart_uploads
    ADD CONSTRAINT s3_multipart_uploads_pkey PRIMARY KEY (id);


--
-- Name: vector_indexes vector_indexes_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.vector_indexes
    ADD CONSTRAINT vector_indexes_pkey PRIMARY KEY (id);


--
-- Name: audit_logs_instance_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX audit_logs_instance_id_idx ON auth.audit_log_entries USING btree (instance_id);


--
-- Name: confirmation_token_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX confirmation_token_idx ON auth.users USING btree (confirmation_token) WHERE ((confirmation_token)::text !~ '^[0-9 ]*$'::text);


--
-- Name: custom_oauth_providers_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX custom_oauth_providers_created_at_idx ON auth.custom_oauth_providers USING btree (created_at);


--
-- Name: custom_oauth_providers_enabled_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX custom_oauth_providers_enabled_idx ON auth.custom_oauth_providers USING btree (enabled);


--
-- Name: custom_oauth_providers_identifier_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX custom_oauth_providers_identifier_idx ON auth.custom_oauth_providers USING btree (identifier);


--
-- Name: custom_oauth_providers_provider_type_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX custom_oauth_providers_provider_type_idx ON auth.custom_oauth_providers USING btree (provider_type);


--
-- Name: email_change_token_current_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX email_change_token_current_idx ON auth.users USING btree (email_change_token_current) WHERE ((email_change_token_current)::text !~ '^[0-9 ]*$'::text);


--
-- Name: email_change_token_new_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX email_change_token_new_idx ON auth.users USING btree (email_change_token_new) WHERE ((email_change_token_new)::text !~ '^[0-9 ]*$'::text);


--
-- Name: factor_id_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX factor_id_created_at_idx ON auth.mfa_factors USING btree (user_id, created_at);


--
-- Name: flow_state_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX flow_state_created_at_idx ON auth.flow_state USING btree (created_at DESC);


--
-- Name: identities_email_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX identities_email_idx ON auth.identities USING btree (email text_pattern_ops);


--
-- Name: INDEX identities_email_idx; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON INDEX auth.identities_email_idx IS 'Auth: Ensures indexed queries on the email column';


--
-- Name: identities_user_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX identities_user_id_idx ON auth.identities USING btree (user_id);


--
-- Name: idx_auth_code; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX idx_auth_code ON auth.flow_state USING btree (auth_code);


--
-- Name: idx_oauth_client_states_created_at; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX idx_oauth_client_states_created_at ON auth.oauth_client_states USING btree (created_at);


--
-- Name: idx_user_id_auth_method; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX idx_user_id_auth_method ON auth.flow_state USING btree (user_id, authentication_method);


--
-- Name: idx_users_created_at_desc; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX idx_users_created_at_desc ON auth.users USING btree (created_at DESC);


--
-- Name: idx_users_email; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX idx_users_email ON auth.users USING btree (email);


--
-- Name: idx_users_last_sign_in_at_desc; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX idx_users_last_sign_in_at_desc ON auth.users USING btree (last_sign_in_at DESC);


--
-- Name: idx_users_name; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX idx_users_name ON auth.users USING btree (((raw_user_meta_data ->> 'name'::text))) WHERE ((raw_user_meta_data ->> 'name'::text) IS NOT NULL);


--
-- Name: mfa_challenge_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX mfa_challenge_created_at_idx ON auth.mfa_challenges USING btree (created_at DESC);


--
-- Name: mfa_factors_user_friendly_name_unique; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX mfa_factors_user_friendly_name_unique ON auth.mfa_factors USING btree (friendly_name, user_id) WHERE (TRIM(BOTH FROM friendly_name) <> ''::text);


--
-- Name: mfa_factors_user_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX mfa_factors_user_id_idx ON auth.mfa_factors USING btree (user_id);


--
-- Name: oauth_auth_pending_exp_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX oauth_auth_pending_exp_idx ON auth.oauth_authorizations USING btree (expires_at) WHERE (status = 'pending'::auth.oauth_authorization_status);


--
-- Name: oauth_clients_deleted_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX oauth_clients_deleted_at_idx ON auth.oauth_clients USING btree (deleted_at);


--
-- Name: oauth_consents_active_client_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX oauth_consents_active_client_idx ON auth.oauth_consents USING btree (client_id) WHERE (revoked_at IS NULL);


--
-- Name: oauth_consents_active_user_client_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX oauth_consents_active_user_client_idx ON auth.oauth_consents USING btree (user_id, client_id) WHERE (revoked_at IS NULL);


--
-- Name: oauth_consents_user_order_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX oauth_consents_user_order_idx ON auth.oauth_consents USING btree (user_id, granted_at DESC);


--
-- Name: one_time_tokens_relates_to_hash_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX one_time_tokens_relates_to_hash_idx ON auth.one_time_tokens USING hash (relates_to);


--
-- Name: one_time_tokens_token_hash_hash_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX one_time_tokens_token_hash_hash_idx ON auth.one_time_tokens USING hash (token_hash);


--
-- Name: one_time_tokens_user_id_token_type_key; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX one_time_tokens_user_id_token_type_key ON auth.one_time_tokens USING btree (user_id, token_type);


--
-- Name: reauthentication_token_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX reauthentication_token_idx ON auth.users USING btree (reauthentication_token) WHERE ((reauthentication_token)::text !~ '^[0-9 ]*$'::text);


--
-- Name: recovery_token_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX recovery_token_idx ON auth.users USING btree (recovery_token) WHERE ((recovery_token)::text !~ '^[0-9 ]*$'::text);


--
-- Name: refresh_tokens_instance_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX refresh_tokens_instance_id_idx ON auth.refresh_tokens USING btree (instance_id);


--
-- Name: refresh_tokens_instance_id_user_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX refresh_tokens_instance_id_user_id_idx ON auth.refresh_tokens USING btree (instance_id, user_id);


--
-- Name: refresh_tokens_parent_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX refresh_tokens_parent_idx ON auth.refresh_tokens USING btree (parent);


--
-- Name: refresh_tokens_session_id_revoked_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX refresh_tokens_session_id_revoked_idx ON auth.refresh_tokens USING btree (session_id, revoked);


--
-- Name: refresh_tokens_updated_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX refresh_tokens_updated_at_idx ON auth.refresh_tokens USING btree (updated_at DESC);


--
-- Name: saml_providers_sso_provider_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX saml_providers_sso_provider_id_idx ON auth.saml_providers USING btree (sso_provider_id);


--
-- Name: saml_relay_states_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX saml_relay_states_created_at_idx ON auth.saml_relay_states USING btree (created_at DESC);


--
-- Name: saml_relay_states_for_email_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX saml_relay_states_for_email_idx ON auth.saml_relay_states USING btree (for_email);


--
-- Name: saml_relay_states_sso_provider_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX saml_relay_states_sso_provider_id_idx ON auth.saml_relay_states USING btree (sso_provider_id);


--
-- Name: sessions_not_after_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX sessions_not_after_idx ON auth.sessions USING btree (not_after DESC);


--
-- Name: sessions_oauth_client_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX sessions_oauth_client_id_idx ON auth.sessions USING btree (oauth_client_id);


--
-- Name: sessions_user_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX sessions_user_id_idx ON auth.sessions USING btree (user_id);


--
-- Name: sso_domains_domain_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX sso_domains_domain_idx ON auth.sso_domains USING btree (lower(domain));


--
-- Name: sso_domains_sso_provider_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX sso_domains_sso_provider_id_idx ON auth.sso_domains USING btree (sso_provider_id);


--
-- Name: sso_providers_resource_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX sso_providers_resource_id_idx ON auth.sso_providers USING btree (lower(resource_id));


--
-- Name: sso_providers_resource_id_pattern_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX sso_providers_resource_id_pattern_idx ON auth.sso_providers USING btree (resource_id text_pattern_ops);


--
-- Name: unique_phone_factor_per_user; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX unique_phone_factor_per_user ON auth.mfa_factors USING btree (user_id, phone);


--
-- Name: user_id_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX user_id_created_at_idx ON auth.sessions USING btree (user_id, created_at);


--
-- Name: users_email_partial_key; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX users_email_partial_key ON auth.users USING btree (email) WHERE (is_sso_user = false);


--
-- Name: INDEX users_email_partial_key; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON INDEX auth.users_email_partial_key IS 'Auth: A partial unique index that applies only when is_sso_user is false';


--
-- Name: users_instance_id_email_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX users_instance_id_email_idx ON auth.users USING btree (instance_id, lower((email)::text));


--
-- Name: users_instance_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX users_instance_id_idx ON auth.users USING btree (instance_id);


--
-- Name: users_is_anonymous_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX users_is_anonymous_idx ON auth.users USING btree (is_anonymous);


--
-- Name: webauthn_challenges_expires_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX webauthn_challenges_expires_at_idx ON auth.webauthn_challenges USING btree (expires_at);


--
-- Name: webauthn_challenges_user_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX webauthn_challenges_user_id_idx ON auth.webauthn_challenges USING btree (user_id);


--
-- Name: webauthn_credentials_credential_id_key; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX webauthn_credentials_credential_id_key ON auth.webauthn_credentials USING btree (credential_id);


--
-- Name: webauthn_credentials_user_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX webauthn_credentials_user_id_idx ON auth.webauthn_credentials USING btree (user_id);


--
-- Name: adjustments_do_no_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX adjustments_do_no_idx ON public.adjustments USING btree (do_no);


--
-- Name: audit_log_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX audit_log_at_idx ON public.audit_log USING btree (at DESC);


--
-- Name: audit_log_entity_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX audit_log_entity_idx ON public.audit_log USING btree (entity, entity_id);


--
-- Name: collections_do_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX collections_do_date_idx ON public.collections USING btree (do_date);


--
-- Name: collections_site_id_do_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX collections_site_id_do_date_idx ON public.collections USING btree (site_id, do_date);


--
-- Name: collections_source_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX collections_source_idx ON public.collections USING btree (source);


--
-- Name: fuel_log_cartrack_uq; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX fuel_log_cartrack_uq ON public.fuel_log USING btree (vehicle_id, fill_date) WHERE (source = 'cartrack'::text);


--
-- Name: jc_ovr_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX jc_ovr_idx ON public.jobcard_overrides USING btree (card_date, driver_id);


--
-- Name: odometer_log_cartrack_uq; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX odometer_log_cartrack_uq ON public.odometer_log USING btree (vehicle_id, read_date) WHERE (source = 'cartrack'::text);


--
-- Name: ix_realtime_subscription_entity; Type: INDEX; Schema: realtime; Owner: -
--

CREATE INDEX ix_realtime_subscription_entity ON realtime.subscription USING btree (entity);


--
-- Name: messages_inserted_at_topic_index; Type: INDEX; Schema: realtime; Owner: -
--

CREATE INDEX messages_inserted_at_topic_index ON ONLY realtime.messages USING btree (inserted_at DESC, topic) WHERE ((extension = 'broadcast'::text) AND (private IS TRUE));


--
-- Name: subscription_subscription_id_entity_filters_action_filter_selec; Type: INDEX; Schema: realtime; Owner: -
--

CREATE UNIQUE INDEX subscription_subscription_id_entity_filters_action_filter_selec ON realtime.subscription USING btree (subscription_id, entity, filters, action_filter, COALESCE(selected_columns, '{}'::text[]));


--
-- Name: bname; Type: INDEX; Schema: storage; Owner: -
--

CREATE UNIQUE INDEX bname ON storage.buckets USING btree (name);


--
-- Name: bucketid_objname; Type: INDEX; Schema: storage; Owner: -
--

CREATE UNIQUE INDEX bucketid_objname ON storage.objects USING btree (bucket_id, name);


--
-- Name: buckets_analytics_unique_name_idx; Type: INDEX; Schema: storage; Owner: -
--

CREATE UNIQUE INDEX buckets_analytics_unique_name_idx ON storage.buckets_analytics USING btree (name) WHERE (deleted_at IS NULL);


--
-- Name: idx_multipart_uploads_list; Type: INDEX; Schema: storage; Owner: -
--

CREATE INDEX idx_multipart_uploads_list ON storage.s3_multipart_uploads USING btree (bucket_id, key, created_at);


--
-- Name: idx_objects_bucket_id_name; Type: INDEX; Schema: storage; Owner: -
--

CREATE INDEX idx_objects_bucket_id_name ON storage.objects USING btree (bucket_id, name COLLATE "C");


--
-- Name: idx_objects_bucket_id_name_lower; Type: INDEX; Schema: storage; Owner: -
--

CREATE INDEX idx_objects_bucket_id_name_lower ON storage.objects USING btree (bucket_id, lower(name) COLLATE "C");


--
-- Name: name_prefix_search; Type: INDEX; Schema: storage; Owner: -
--

CREATE INDEX name_prefix_search ON storage.objects USING btree (name text_pattern_ops);


--
-- Name: vector_indexes_name_bucket_id_idx; Type: INDEX; Schema: storage; Owner: -
--

CREATE UNIQUE INDEX vector_indexes_name_bucket_id_idx ON storage.vector_indexes USING btree (name, bucket_id);


--
-- Name: subscription tr_check_filters; Type: TRIGGER; Schema: realtime; Owner: -
--

CREATE TRIGGER tr_check_filters BEFORE INSERT OR UPDATE ON realtime.subscription FOR EACH ROW EXECUTE FUNCTION realtime.subscription_check_filters();


--
-- Name: buckets enforce_bucket_name_length_trigger; Type: TRIGGER; Schema: storage; Owner: -
--

CREATE TRIGGER enforce_bucket_name_length_trigger BEFORE INSERT OR UPDATE OF name ON storage.buckets FOR EACH ROW EXECUTE FUNCTION storage.enforce_bucket_name_length();


--
-- Name: buckets protect_buckets_delete; Type: TRIGGER; Schema: storage; Owner: -
--

CREATE TRIGGER protect_buckets_delete BEFORE DELETE ON storage.buckets FOR EACH STATEMENT EXECUTE FUNCTION storage.protect_delete();


--
-- Name: objects protect_objects_delete; Type: TRIGGER; Schema: storage; Owner: -
--

CREATE TRIGGER protect_objects_delete BEFORE DELETE ON storage.objects FOR EACH STATEMENT EXECUTE FUNCTION storage.protect_delete();


--
-- Name: objects update_objects_updated_at; Type: TRIGGER; Schema: storage; Owner: -
--

CREATE TRIGGER update_objects_updated_at BEFORE UPDATE ON storage.objects FOR EACH ROW EXECUTE FUNCTION storage.update_updated_at_column();


--
-- Name: identities identities_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.identities
    ADD CONSTRAINT identities_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: mfa_amr_claims mfa_amr_claims_session_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_amr_claims
    ADD CONSTRAINT mfa_amr_claims_session_id_fkey FOREIGN KEY (session_id) REFERENCES auth.sessions(id) ON DELETE CASCADE;


--
-- Name: mfa_challenges mfa_challenges_auth_factor_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_challenges
    ADD CONSTRAINT mfa_challenges_auth_factor_id_fkey FOREIGN KEY (factor_id) REFERENCES auth.mfa_factors(id) ON DELETE CASCADE;


--
-- Name: mfa_factors mfa_factors_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_factors
    ADD CONSTRAINT mfa_factors_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: oauth_authorizations oauth_authorizations_client_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_authorizations
    ADD CONSTRAINT oauth_authorizations_client_id_fkey FOREIGN KEY (client_id) REFERENCES auth.oauth_clients(id) ON DELETE CASCADE;


--
-- Name: oauth_authorizations oauth_authorizations_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_authorizations
    ADD CONSTRAINT oauth_authorizations_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: oauth_consents oauth_consents_client_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_consents
    ADD CONSTRAINT oauth_consents_client_id_fkey FOREIGN KEY (client_id) REFERENCES auth.oauth_clients(id) ON DELETE CASCADE;


--
-- Name: oauth_consents oauth_consents_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_consents
    ADD CONSTRAINT oauth_consents_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: one_time_tokens one_time_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.one_time_tokens
    ADD CONSTRAINT one_time_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: refresh_tokens refresh_tokens_session_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.refresh_tokens
    ADD CONSTRAINT refresh_tokens_session_id_fkey FOREIGN KEY (session_id) REFERENCES auth.sessions(id) ON DELETE CASCADE;


--
-- Name: saml_providers saml_providers_sso_provider_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_providers
    ADD CONSTRAINT saml_providers_sso_provider_id_fkey FOREIGN KEY (sso_provider_id) REFERENCES auth.sso_providers(id) ON DELETE CASCADE;


--
-- Name: saml_relay_states saml_relay_states_flow_state_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_relay_states
    ADD CONSTRAINT saml_relay_states_flow_state_id_fkey FOREIGN KEY (flow_state_id) REFERENCES auth.flow_state(id) ON DELETE CASCADE;


--
-- Name: saml_relay_states saml_relay_states_sso_provider_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_relay_states
    ADD CONSTRAINT saml_relay_states_sso_provider_id_fkey FOREIGN KEY (sso_provider_id) REFERENCES auth.sso_providers(id) ON DELETE CASCADE;


--
-- Name: sessions sessions_oauth_client_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sessions
    ADD CONSTRAINT sessions_oauth_client_id_fkey FOREIGN KEY (oauth_client_id) REFERENCES auth.oauth_clients(id) ON DELETE CASCADE;


--
-- Name: sessions sessions_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sessions
    ADD CONSTRAINT sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: sso_domains sso_domains_sso_provider_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sso_domains
    ADD CONSTRAINT sso_domains_sso_provider_id_fkey FOREIGN KEY (sso_provider_id) REFERENCES auth.sso_providers(id) ON DELETE CASCADE;


--
-- Name: webauthn_challenges webauthn_challenges_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.webauthn_challenges
    ADD CONSTRAINT webauthn_challenges_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: webauthn_credentials webauthn_credentials_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.webauthn_credentials
    ADD CONSTRAINT webauthn_credentials_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: adjustments adjustments_do_no_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adjustments
    ADD CONSTRAINT adjustments_do_no_fkey FOREIGN KEY (do_no) REFERENCES public.collections(do_no);


--
-- Name: approved_domains approved_domains_client_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.approved_domains
    ADD CONSTRAINT approved_domains_client_id_fkey FOREIGN KEY (client_id) REFERENCES public.customers(client_id);


--
-- Name: collections collections_bin_in_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collections
    ADD CONSTRAINT collections_bin_in_fkey FOREIGN KEY (bin_in) REFERENCES public.bins(bin_id);


--
-- Name: collections collections_bin_out_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collections
    ADD CONSTRAINT collections_bin_out_fkey FOREIGN KEY (bin_out) REFERENCES public.bins(bin_id);


--
-- Name: collections collections_disposal_facility_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collections
    ADD CONSTRAINT collections_disposal_facility_fkey FOREIGN KEY (disposal_facility) REFERENCES public.facilities(facility_id);


--
-- Name: collections collections_driver_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collections
    ADD CONSTRAINT collections_driver_id_fkey FOREIGN KEY (driver_id) REFERENCES public.drivers(driver_id);


--
-- Name: collections collections_job_no_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collections
    ADD CONSTRAINT collections_job_no_fkey FOREIGN KEY (job_no) REFERENCES public.jobs(job_no);


--
-- Name: collections collections_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collections
    ADD CONSTRAINT collections_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(site_id);


--
-- Name: collections collections_vehicle_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collections
    ADD CONSTRAINT collections_vehicle_id_fkey FOREIGN KEY (vehicle_id) REFERENCES public.vehicles(vehicle_id);


--
-- Name: fuel_log fuel_log_vehicle_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fuel_log
    ADD CONSTRAINT fuel_log_vehicle_id_fkey FOREIGN KEY (vehicle_id) REFERENCES public.vehicles(vehicle_id);


--
-- Name: jobs jobs_driver_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.jobs
    ADD CONSTRAINT jobs_driver_id_fkey FOREIGN KEY (driver_id) REFERENCES public.drivers(driver_id);


--
-- Name: jobs jobs_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.jobs
    ADD CONSTRAINT jobs_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(site_id);


--
-- Name: maintenance maintenance_vehicle_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance
    ADD CONSTRAINT maintenance_vehicle_id_fkey FOREIGN KEY (vehicle_id) REFERENCES public.vehicles(vehicle_id);


--
-- Name: odometer_log odometer_log_vehicle_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.odometer_log
    ADD CONSTRAINT odometer_log_vehicle_id_fkey FOREIGN KEY (vehicle_id) REFERENCES public.vehicles(vehicle_id);


--
-- Name: onward_disposal onward_disposal_do_no_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.onward_disposal
    ADD CONSTRAINT onward_disposal_do_no_fkey FOREIGN KEY (do_no) REFERENCES public.collections(do_no);


--
-- Name: onward_disposal onward_disposal_facility_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.onward_disposal
    ADD CONSTRAINT onward_disposal_facility_id_fkey FOREIGN KEY (facility_id) REFERENCES public.facilities(facility_id);


--
-- Name: portal_accounts portal_accounts_client_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.portal_accounts
    ADD CONSTRAINT portal_accounts_client_id_fkey FOREIGN KEY (client_id) REFERENCES public.customers(client_id);


--
-- Name: rate_card rate_card_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rate_card
    ADD CONSTRAINT rate_card_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.sites(site_id);


--
-- Name: sites sites_client_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sites
    ADD CONSTRAINT sites_client_id_fkey FOREIGN KEY (client_id) REFERENCES public.customers(client_id);


--
-- Name: objects objects_bucketId_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.objects
    ADD CONSTRAINT "objects_bucketId_fkey" FOREIGN KEY (bucket_id) REFERENCES storage.buckets(id);


--
-- Name: s3_multipart_uploads s3_multipart_uploads_bucket_id_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.s3_multipart_uploads
    ADD CONSTRAINT s3_multipart_uploads_bucket_id_fkey FOREIGN KEY (bucket_id) REFERENCES storage.buckets(id);


--
-- Name: s3_multipart_uploads_parts s3_multipart_uploads_parts_bucket_id_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.s3_multipart_uploads_parts
    ADD CONSTRAINT s3_multipart_uploads_parts_bucket_id_fkey FOREIGN KEY (bucket_id) REFERENCES storage.buckets(id);


--
-- Name: s3_multipart_uploads_parts s3_multipart_uploads_parts_upload_id_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.s3_multipart_uploads_parts
    ADD CONSTRAINT s3_multipart_uploads_parts_upload_id_fkey FOREIGN KEY (upload_id) REFERENCES storage.s3_multipart_uploads(id) ON DELETE CASCADE;


--
-- Name: vector_indexes vector_indexes_bucket_id_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.vector_indexes
    ADD CONSTRAINT vector_indexes_bucket_id_fkey FOREIGN KEY (bucket_id) REFERENCES storage.buckets_vectors(id);


--
-- Name: audit_log_entries; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.audit_log_entries ENABLE ROW LEVEL SECURITY;

--
-- Name: flow_state; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.flow_state ENABLE ROW LEVEL SECURITY;

--
-- Name: identities; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.identities ENABLE ROW LEVEL SECURITY;

--
-- Name: instances; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.instances ENABLE ROW LEVEL SECURITY;

--
-- Name: mfa_amr_claims; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.mfa_amr_claims ENABLE ROW LEVEL SECURITY;

--
-- Name: mfa_challenges; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.mfa_challenges ENABLE ROW LEVEL SECURITY;

--
-- Name: mfa_factors; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.mfa_factors ENABLE ROW LEVEL SECURITY;

--
-- Name: one_time_tokens; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.one_time_tokens ENABLE ROW LEVEL SECURITY;

--
-- Name: refresh_tokens; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.refresh_tokens ENABLE ROW LEVEL SECURITY;

--
-- Name: saml_providers; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.saml_providers ENABLE ROW LEVEL SECURITY;

--
-- Name: saml_relay_states; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.saml_relay_states ENABLE ROW LEVEL SECURITY;

--
-- Name: schema_migrations; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.schema_migrations ENABLE ROW LEVEL SECURITY;

--
-- Name: sessions; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.sessions ENABLE ROW LEVEL SECURITY;

--
-- Name: sso_domains; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.sso_domains ENABLE ROW LEVEL SECURITY;

--
-- Name: sso_providers; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.sso_providers ENABLE ROW LEVEL SECURITY;

--
-- Name: users; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.users ENABLE ROW LEVEL SECURITY;

--
-- Name: adjustments; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.adjustments ENABLE ROW LEVEL SECURITY;

--
-- Name: app_state; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.app_state ENABLE ROW LEVEL SECURITY;

--
-- Name: approved_domains; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.approved_domains ENABLE ROW LEVEL SECURITY;

--
-- Name: audit_log; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.audit_log ENABLE ROW LEVEL SECURITY;

--
-- Name: bins; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.bins ENABLE ROW LEVEL SECURITY;

--
-- Name: collections; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.collections ENABLE ROW LEVEL SECURITY;

--
-- Name: customers; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;

--
-- Name: drivers; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.drivers ENABLE ROW LEVEL SECURITY;

--
-- Name: facilities; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.facilities ENABLE ROW LEVEL SECURITY;

--
-- Name: factors; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.factors ENABLE ROW LEVEL SECURITY;

--
-- Name: fuel_log; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.fuel_log ENABLE ROW LEVEL SECURITY;

--
-- Name: interest_leads; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.interest_leads ENABLE ROW LEVEL SECURITY;

--
-- Name: interest_leads interest_leads_anon_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY interest_leads_anon_insert ON public.interest_leads FOR INSERT TO authenticated, anon WITH CHECK (true);


--
-- Name: jobcard_overrides; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.jobcard_overrides ENABLE ROW LEVEL SECURITY;

--
-- Name: jobs; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.jobs ENABLE ROW LEVEL SECURITY;

--
-- Name: maintenance; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.maintenance ENABLE ROW LEVEL SECURITY;

--
-- Name: odometer_log; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.odometer_log ENABLE ROW LEVEL SECURITY;

--
-- Name: onward_disposal; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.onward_disposal ENABLE ROW LEVEL SECURITY;

--
-- Name: portal_accounts; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.portal_accounts ENABLE ROW LEVEL SECURITY;

--
-- Name: rate_card; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.rate_card ENABLE ROW LEVEL SECURITY;

--
-- Name: ref_lists; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.ref_lists ENABLE ROW LEVEL SECURITY;

--
-- Name: sites; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.sites ENABLE ROW LEVEL SECURITY;

--
-- Name: vehicles; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.vehicles ENABLE ROW LEVEL SECURITY;

--
-- Name: yard_inbound; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.yard_inbound ENABLE ROW LEVEL SECURITY;

--
-- Name: yard_stock; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.yard_stock ENABLE ROW LEVEL SECURITY;

--
-- Name: messages; Type: ROW SECURITY; Schema: realtime; Owner: -
--

ALTER TABLE realtime.messages ENABLE ROW LEVEL SECURITY;

--
-- Name: buckets; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.buckets ENABLE ROW LEVEL SECURITY;

--
-- Name: buckets_analytics; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.buckets_analytics ENABLE ROW LEVEL SECURITY;

--
-- Name: buckets_vectors; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.buckets_vectors ENABLE ROW LEVEL SECURITY;

--
-- Name: migrations; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.migrations ENABLE ROW LEVEL SECURITY;

--
-- Name: objects; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

--
-- Name: s3_multipart_uploads; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.s3_multipart_uploads ENABLE ROW LEVEL SECURITY;

--
-- Name: s3_multipart_uploads_parts; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.s3_multipart_uploads_parts ENABLE ROW LEVEL SECURITY;

--
-- Name: vector_indexes; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.vector_indexes ENABLE ROW LEVEL SECURITY;

--
-- Name: supabase_realtime; Type: PUBLICATION; Schema: -; Owner: -
--

CREATE PUBLICATION supabase_realtime WITH (publish = 'insert, update, delete, truncate');


--
-- Name: issue_graphql_placeholder; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER issue_graphql_placeholder ON sql_drop
         WHEN TAG IN ('DROP EXTENSION')
   EXECUTE FUNCTION extensions.set_graphql_placeholder();


--
-- Name: issue_pg_cron_access; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER issue_pg_cron_access ON ddl_command_end
         WHEN TAG IN ('CREATE EXTENSION')
   EXECUTE FUNCTION extensions.grant_pg_cron_access();


--
-- Name: issue_pg_graphql_access; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER issue_pg_graphql_access ON ddl_command_end
         WHEN TAG IN ('CREATE EXTENSION')
   EXECUTE FUNCTION extensions.grant_pg_graphql_access();


--
-- Name: issue_pg_net_access; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER issue_pg_net_access ON ddl_command_end
         WHEN TAG IN ('CREATE EXTENSION')
   EXECUTE FUNCTION extensions.grant_pg_net_access();


--
-- Name: pgrst_ddl_watch; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER pgrst_ddl_watch ON ddl_command_end
   EXECUTE FUNCTION extensions.pgrst_ddl_watch();


--
-- Name: pgrst_drop_watch; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER pgrst_drop_watch ON sql_drop
   EXECUTE FUNCTION extensions.pgrst_drop_watch();


--
-- PostgreSQL database dump complete
--

\unrestrict Ar07BeEGEIfFD2VhXEbIeIKIc2ecfAx7vKJ0ShCUu1oB6HMIaWukUk61bw5UH8o

