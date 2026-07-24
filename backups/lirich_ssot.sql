--
-- PostgreSQL database dump
--

\restrict Hf1bXP79njgH7Yx1frOa8HcRwVVHPg5Rgde3TkUzUPikv6tyH6HZ9l7iiF8xZLt

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
    CONSTRAINT collections_source_check CHECK ((source = ANY (ARRAY['live'::text, 'backfill'::text]))),
    CONSTRAINT collections_weight_source_check CHECK ((weight_source = ANY (ARRAY['weighbridge'::text, 'volume_est'::text])))
);


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
    created_at timestamp with time zone DEFAULT now() NOT NULL
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
    entered_by text
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
    odometer_km integer NOT NULL,
    source text
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
    created_at timestamp with time zone DEFAULT now() NOT NULL
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
-- Data for Name: adjustments; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.adjustments (id, do_no, field, old_value, new_value, reason, adjusted_by, adjusted_at) FROM stdin;
1	23636	do_date	\N	2026-06-09	Re-OCR of scan p3: date clearly reads 09/06/26 (was blank in backfill)	claude re-ocr 24Jul2026	2026-07-24 15:45:07.605862+00
2	23947	do_date	2026-06-30	2026-06-20	Re-OCR of scan p15: date reads 20/06/26, original backfill had 30/06/26 - verify against invoice	claude re-ocr 24Jul2026	2026-07-24 15:45:07.605862+00
\.


--
-- Data for Name: app_state; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.app_state (id, state, rev, updated_at) FROM stdin;
1	{"rev": 9, "seq": {"do": 1, "job": 45, "vdo": 17921, "trip": 25, "ticket": 15}, "bins": [{"no": "5028", "size": "5 ft", "source": "seed", "status": "yard", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5038", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5044", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5046", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5047", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5051", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5056", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5057", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5058", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5060", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5064", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5069", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5073", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5079", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5081", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5083", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5084", "size": "5 ft", "source": "seed", "status": "yard", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5086", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5089", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5092", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5096", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5106", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5108", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5116", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5123", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5135", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5142", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5147", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5151", "size": "5 ft", "source": "seed", "status": "client", "siteIdx": 0, "clientId": "cmrkt9187zx3", "firstSeen": "2026-07-14"}, {"no": "5153", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5160", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5162", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5169", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5176", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5194", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5196", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5197", "size": "5 ft", "source": "seed", "status": "client", "siteIdx": 0, "clientId": "c1", "firstSeen": "2026-07-14"}, {"no": "5198", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5199", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5203", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5204", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5210", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5211", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5213", "size": "5 ft", "source": "seed", "status": "yard", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5217", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5220", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5221", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5222", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5232", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5239", "size": "5 ft", "source": "seed", "status": "yard", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5240", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "5245", "size": "5 ft", "source": "seed", "status": "client", "siteIdx": 0, "clientId": "cmrkt918auof", "firstSeen": "2026-07-14"}, {"no": "5247", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "7006", "size": "7 ft", "source": "seed", "status": "client", "siteIdx": 0, "clientId": "cmrkt9187ws7", "firstSeen": "2026-07-14"}, {"no": "7016", "size": "7 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "7017", "size": "7 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "7022", "size": "7 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "8007", "size": "7 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "L802", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "L806", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "L807", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "L808", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "L809", "size": "5 ft", "source": "seed", "status": "unknown", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "R08", "size": "5 ft", "source": "driver", "status": "client", "siteIdx": 0, "clientId": "c1", "firstSeen": "2026-07-14"}, {"no": "Y111", "size": "5 ft", "source": "driver", "status": "yard", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-14"}, {"no": "L801", "size": "", "source": "driver", "status": "client", "siteIdx": 0, "clientId": "cmrkt91878od", "firstSeen": "2026-07-15"}, {"no": "L805", "size": "", "source": "driver", "status": "yard", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-15"}, {"no": "L53", "size": "", "source": "driver", "status": "client", "siteIdx": 0, "clientId": "cmrkt91878od", "firstSeen": "2026-07-15"}, {"no": "5109", "size": "5 ft", "source": "driver", "status": "client", "siteIdx": 2, "clientId": "cmrkt918ag06", "firstSeen": "2026-07-15"}, {"no": "5072", "size": "5 ft", "source": "driver", "status": "yard", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-15"}, {"no": "5070", "size": "5 ft", "source": "driver", "status": "yard", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-15"}, {"no": "R13", "size": "7 ft", "source": "driver", "status": "yard", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-15"}, {"no": "5033", "size": "5 ft", "source": "driver", "status": "client", "siteIdx": 0, "clientId": "cmrkt9187x1k", "firstSeen": "2026-07-15"}, {"no": "5070号", "size": "5 ft", "source": "driver", "status": "client", "siteIdx": 1, "clientId": "cmrkt9189v5w", "firstSeen": "2026-07-15"}, {"no": "5193", "size": "5 ft", "source": "driver", "status": "client", "siteIdx": 1, "clientId": "cmrkt9189v5w", "firstSeen": "2026-07-15"}, {"no": "R21", "size": "7 ft", "source": "driver", "status": "yard", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-15"}, {"no": "8005", "size": "7 ft", "source": "driver", "status": "yard", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-16"}, {"no": "L57", "size": "5 ft", "source": "driver", "status": "client", "siteIdx": 0, "clientId": "cmrkt9189j9t", "firstSeen": "2026-07-16"}, {"no": "5132", "size": "5 ft", "source": "driver", "status": "client", "siteIdx": 1, "clientId": "cmrkt9189v5w", "firstSeen": "2026-07-16"}, {"no": "6002", "size": "5 ft", "source": "driver", "status": "yard", "siteIdx": 0, "clientId": null, "firstSeen": "2026-07-20"}], "jobs": [{"id": 3, "date": "2026-07-15", "_addr": "48 Pandan Road L3", "_task": "Exchange", "price": 13, "waste": "General Waste", "dumpTo": "", "status": "done", "_client": "Poh Tiong Choon Logistics Ltd", "_driver": "Yao Jun", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 2, "_contact": "", "clientId": "cmrkt918ag06", "distance": 0, "driverId": 5, "createdAt": "2026-07-15T10:45", "startedAt": "10:46", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1784083566810, "instructions": ""}, {"id": 4, "date": "2026-07-14", "_addr": "79 Anson Road", "_task": "Exchange", "price": 18, "waste": "Wood Waste", "dumpTo": "", "status": "done", "_client": "HCG", "_driver": "Yao Jun", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 1, "_contact": "", "clientId": "cmrkt9189v5w", "distance": 0, "driverId": 5, "createdAt": "2026-07-14T13:07", "startedAt": "13:10", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1784092230111, "instructions": ""}, {"id": 5, "date": "2026-07-15", "_addr": "26 Loyang Drive", "_task": "Load", "price": 31, "waste": "General Waste", "dumpTo": "", "status": "done", "_client": "B&C Waste", "_driver": "Yao Jun", "binSize": "7 ft", "jobType": "Load", "siteIdx": 6, "_contact": "", "clientId": "cmrkt91878od", "distance": 0, "driverId": 5, "createdAt": "2026-07-15T14:47", "startedAt": "15:14", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1784099668422, "instructions": ""}, {"id": 6, "date": "2026-07-15", "_addr": "47A Jalan Buroh", "_task": "Exchange", "price": 13, "waste": "General Waste", "dumpTo": "", "status": "done", "_client": "Advanced Substrate Technologies Pte Ltd", "_driver": "Yao Jun", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 0, "_contact": "", "clientId": "cmrkt9187x1k", "distance": 0, "driverId": 5, "createdAt": "2026-07-15T15:10", "startedAt": "17:53", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1784109223975, "instructions": ""}, {"id": 7, "date": "2026-07-15", "_addr": "79 Anson Road", "_task": "Exchange", "price": 18, "waste": "General Waste", "dumpTo": "", "status": "done", "_client": "HCG", "_driver": "Yao Jun", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 1, "_contact": "", "clientId": "cmrkt9189v5w", "distance": 0, "driverId": 5, "createdAt": "2026-07-15T15:13", "startedAt": "18:52", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1784112771627, "instructions": ""}, {"id": 8, "date": "2026-07-15", "_addr": "54 Senoko Road", "_task": "Exchange", "price": 18, "waste": "General Waste", "dumpTo": "Lirich Resources Pte Ltd", "status": "assigned", "_client": "Calvary Carpentry Pte Ltd", "_driver": "Sathish", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 0, "_contact": "", "clientId": "cmrkt91889mm", "distance": 30, "driverId": 1, "createdAt": "2026-07-15T21:21", "contactIdx": 0, "surcharges": [], "instructions": "7:30-8:00am\\nContact - 86807640"}, {"id": 9, "date": "2026-07-15", "_addr": "46 Gul Drive", "_task": "Delivery", "price": 8, "waste": "Carton Boxes", "dumpTo": "Lirich Resources Pte Ltd", "status": "assigned", "_client": "Haid Biotechnology Industry (Singapore) Pte Ltd", "_driver": "Sathish", "binSize": "5 ft", "jobType": "Delivery", "siteIdx": 0, "_contact": "", "clientId": "cmrkt9189g55", "distance": 1.1, "driverId": 1, "createdAt": "2026-07-15T21:23", "contactIdx": 0, "surcharges": [], "instructions": ""}, {"id": 10, "date": "2026-07-15", "_addr": "46 Gul Drive", "_task": "Collect", "price": 13, "waste": "Carton Boxes", "dumpTo": "Lirich Resources Pte Ltd", "status": "in_progress", "_client": "Haid Biotechnology Industry (Singapore) Pte Ltd", "_driver": "Sathish", "binSize": "5 ft", "jobType": "Collect", "siteIdx": 0, "_contact": "", "clientId": "cmrkt9189g55", "distance": 1.1, "driverId": 1, "createdAt": "2026-07-15T21:24", "startedAt": "17:51", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1784281884954, "instructions": "Collect bin 10:00am"}, {"id": 11, "date": "2026-07-15", "_addr": "Benoi", "_task": "Exchange", "price": 13, "waste": "General Waste", "dumpTo": "Lirich Resources Pte Ltd", "status": "in_progress", "_client": "ST", "_driver": "Sathish", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 1, "_contact": "", "clientId": "cmrkt918dn4k", "distance": 2.3, "driverId": 1, "createdAt": "2026-07-15T21:26", "startedAt": "19:21", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1784287270474, "instructions": ""}, {"id": 12, "date": "2026-07-15", "_addr": "6 Chin Bee Ave L5", "_task": "Exchange", "price": 13, "waste": "General Waste", "dumpTo": "Lirich Resources Pte Ltd", "status": "in_progress", "_client": "Shin Ya O Ya Pte Ltd", "_driver": "Sathish", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 0, "_contact": "", "clientId": "cmrkt918dq77", "distance": 0, "driverId": 1, "createdAt": "2026-07-15T21:28", "startedAt": "14:41", "contactIdx": 0, "surcharges": [], "instructions": ""}, {"id": 13, "date": "2026-07-15", "_addr": "6 Chin Bee Ave L5", "_task": "Exchange", "price": 13, "waste": "General Waste", "dumpTo": "Lirich Resources Pte Ltd", "status": "done", "_client": "Shin Ya O Ya Pte Ltd", "_driver": "Yao Jun", "binSize": "7 ft", "jobType": "Exchange", "siteIdx": 0, "_contact": "", "clientId": "cmrkt918dq77", "distance": 0, "driverId": 5, "createdAt": "2026-07-15T22:25", "startedAt": "22:59", "contactIdx": 0, "surcharges": ["after7v"], "acceptedAtMs": 1784127557628, "instructions": ""}, {"id": 14, "date": "2026-07-15", "_addr": "8 Pandan Crescent", "_task": "Exchange", "price": 13, "waste": "General Waste", "dumpTo": "Lirich Resources Pte Ltd", "status": "done", "_client": "ASL Proworld Solution Pte Ltd", "_driver": "Yao Jun", "binSize": "7 ft", "jobType": "Exchange", "siteIdx": 0, "_contact": "", "clientId": "cmrkt9187ws7", "distance": 13.1, "driverId": 5, "createdAt": "2026-07-15T22:46", "startedAt": "08:45", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1784162742439, "instructions": "PIC - Jun Hong 88894769"}, {"id": 15, "date": "2026-07-15", "_addr": "60 Benoi Road", "_task": "Exchange", "price": 13, "waste": "General Waste", "dumpTo": "Lirich Resources Pte Ltd", "status": "done", "_client": "EverTeam Pte Ltd", "_driver": "Yao Jun", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 0, "_contact": "", "clientId": "cmrkt9189j9t", "distance": 1.9, "driverId": 5, "createdAt": "2026-07-15T22:48", "startedAt": "09:59", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1784167147780, "instructions": "PIC - Anwar 80792542"}, {"id": 16, "date": "2026-07-15", "_addr": "5 Jalan Samulun", "_task": "Exchange", "price": 13, "waste": "General Waste", "dumpTo": "Lirich Resources Pte Ltd", "status": "assigned", "_client": "PaxOcean Singapore Pte Ltd", "_driver": "Liu", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 0, "_contact": "", "clientId": "cmrkt918askd", "distance": 4.6, "driverId": 4, "createdAt": "2026-07-15T22:52", "contactIdx": 0, "surcharges": [], "instructions": "Morning \\nMuthu- 84553465"}, {"id": 17, "date": "2026-07-15", "_addr": "5 Jalan Samulun", "_task": "Exchange", "price": 13, "waste": "General Waste", "dumpTo": "Lirich Resources Pte Ltd", "status": "assigned", "_client": "PaxOcean Singapore Pte Ltd", "_driver": "Liu", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 0, "_contact": "", "clientId": "cmrkt918askd", "distance": 4.6, "driverId": 4, "createdAt": "2026-07-15T22:53", "contactIdx": 0, "surcharges": [], "instructions": "Afternoon\\nMuthu- 84553465"}, {"id": 18, "date": "2026-07-15", "_addr": "6 Tuas South Street 15", "_task": "Exchange", "price": 13, "waste": "General Waste", "dumpTo": "Lirich Resources Pte Ltd", "status": "assigned", "_client": "ST", "_driver": "Liu", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 0, "_contact": "", "clientId": "cmrkt918dn4k", "distance": 8.4, "driverId": 4, "createdAt": "2026-07-15T22:55", "contactIdx": 0, "surcharges": [], "instructions": "Rate will change in the system $19.50"}, {"id": 19, "date": "2026-07-15", "_addr": "Peck Seah Street", "_task": "Exchange", "price": 23, "waste": "General Waste", "dumpTo": "", "status": "assigned", "_client": "B&C Waste", "_driver": "Liu", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 4, "_contact": "", "clientId": "cmrkt91878od", "distance": 26.7, "driverId": 4, "createdAt": "2026-07-15T22:58", "contactIdx": 0, "surcharges": [], "instructions": "Call 1 hour before go\\nAvoid.lunch time 12pm-1pm\\nAnamul- 85236820"}, {"id": 20, "date": "2026-07-16", "_addr": "79 Anson Road", "_task": "Exchange", "price": 18, "waste": "General Waste", "dumpTo": "HCG Environmental Pte Ltd", "status": "done", "_client": "HCG", "_driver": "Yao Jun", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 1, "_contact": "", "clientId": "cmrkt9189v5w", "distance": 32, "driverId": 5, "createdAt": "2026-07-16T09:35", "startedAt": "14:32", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1784183568667, "instructions": "Trip rate is $23"}, {"id": 21, "date": "2026-07-16", "_addr": "79 Anson Road", "_task": "Exchange", "price": 18, "waste": "General Waste", "dumpTo": "HCG Environmental Pte Ltd", "status": "done", "_client": "HCG", "_driver": "Yao Jun", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 1, "_contact": "", "clientId": "cmrkt9189v5w", "distance": 32, "driverId": 5, "createdAt": "2026-07-16T09:37", "startedAt": "10:43", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1784169791187, "instructions": "Trip rate is $23"}, {"id": 22, "date": "2026-07-16", "_addr": "13 Kian Teck Crescent", "_task": "Exchange", "price": 13, "waste": "General Waste", "dumpTo": "Lirich Resources Pte Ltd", "status": "in_progress", "_client": "WIKA Instrumentation Pte Ltd", "_driver": "Kumar", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 0, "_contact": "", "clientId": "cmrkt918fsbo", "distance": 3.8, "driverId": 3, "createdAt": "2026-07-16T13:56", "startedAt": "22:35", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1784212514524, "instructions": ""}, {"id": 23, "date": "2026-07-17", "_addr": "9 Gul Circle", "_task": "Exchange", "price": 13, "waste": "Carton Boxes", "dumpTo": "", "status": "void", "_client": "Eng Lee Logistics Pte Ltd", "_driver": "Sathish", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 0, "_contact": "Jacky", "clientId": "c1", "distance": 0, "driverId": 1, "createdAt": "2026-07-17T17:35", "contactIdx": 0, "surcharges": [], "instructions": ""}, {"id": 24, "date": "2026-07-17", "_addr": "9 Gul Circle", "_task": "Exchange", "price": 13, "waste": "Carton Boxes", "dumpTo": "", "status": "void", "_client": "Eng Lee Logistics Pte Ltd", "_driver": "Sathish", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 0, "_contact": "Jacky", "clientId": "c1", "distance": 0, "driverId": 1, "createdAt": "2026-07-17T19:21", "startedAt": "19:22", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1784287355671, "instructions": ""}, {"id": 25, "date": "2026-07-17", "_addr": "9 Gul Circle", "_task": "Exchange", "price": 13, "waste": "Carton Boxes", "dumpTo": "", "status": "in_progress", "_client": "Eng Lee Logistics Pte Ltd", "_driver": "Test Driver", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 0, "_contact": "Jacky", "clientId": "c1", "distance": 0, "driverId": 6, "createdAt": "2026-07-17T20:52", "startedAt": "20:52", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1784292770918, "instructions": ""}, {"id": 26, "date": "2026-07-17", "_addr": "15 Tuas Ave 8", "_task": "Exchange", "price": 13, "waste": "Carton Boxes", "dumpTo": "", "status": "in_progress", "_client": "Eng Lee Logistics Pte Ltd", "_driver": "Test Driver", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 1, "_contact": "Jacky", "clientId": "c1", "distance": 0, "driverId": 6, "createdAt": "2026-07-17T21:25", "startedAt": "21:25", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1784294732895, "instructions": ""}, {"id": 27, "date": "2026-07-17", "_addr": "9 Gul Circle", "_task": "Exchange", "price": 13, "waste": "Carton Boxes", "dumpTo": "Asia Recycling Resources Pte Ltd", "status": "void", "_client": "Eng Lee Logistics Pte Ltd", "_driver": "Sathish", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 0, "_contact": "Jacky", "clientId": "c1", "distance": 1.2, "driverId": 1, "createdAt": "2026-07-17T21:36", "contactIdx": 0, "surcharges": [], "instructions": ""}, {"id": 28, "date": "2026-07-17", "_addr": "9 Gul Circle", "_task": "Exchange", "price": 13, "waste": "Carton Boxes", "dumpTo": "", "status": "in_progress", "_client": "Eng Lee Logistics Pte Ltd", "_driver": "Test Driver", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 0, "_contact": "Jacky", "clientId": "c1", "distance": 0, "driverId": 6, "createdAt": "2026-07-17T21:37", "startedAt": "21:38", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1784295480487, "instructions": ""}, {"id": 29, "date": "2026-07-18", "_addr": "5 Sungei Kadut Street 6", "_task": "Dump", "price": 18, "waste": "Wood Waste", "dumpTo": "Bee Joo", "status": "assigned", "_client": "Beejoo", "_driver": "Sathish", "binSize": "5 ft", "jobType": "Dump", "siteIdx": 0, "_contact": "", "clientId": "cmrkt9187viy", "distance": 0, "driverId": 1, "createdAt": "2026-07-17T22:00", "contactIdx": 0, "surcharges": [], "instructions": ""}, {"id": 30, "date": "2026-07-20", "_addr": "5 Sungei Kadut Street 6", "_task": "Dump", "price": 18, "waste": "Wood Waste", "dumpTo": "Bee Joo", "status": "assigned", "_client": "Beejoo", "_driver": "Liu", "binSize": "7 ft", "jobType": "Dump", "siteIdx": 0, "_contact": "", "clientId": "cmrkt9187viy", "distance": 0, "driverId": 4, "createdAt": "2026-07-19T20:46", "contactIdx": 0, "surcharges": [], "instructions": ""}, {"id": 31, "date": "2026-07-20", "_addr": "1 Tuas View Place, Westlink One, #02-01", "_task": "Delivery", "price": 8, "waste": "General Waste", "dumpTo": "", "status": "assigned", "_client": "Epont Building Services Pte Ltd", "_driver": "Liu", "binSize": "5 ft", "jobType": "Delivery", "siteIdx": 0, "_contact": "", "clientId": "cmrkt9189ewq", "distance": 0, "driverId": 4, "createdAt": "2026-07-19T20:48", "contactIdx": 0, "surcharges": [], "instructions": ""}, {"id": 32, "date": "2026-07-19", "_addr": "5 Sungei Kadut Street 6", "_task": "Dump", "price": 18, "waste": "Wood Waste", "dumpTo": "Bee Joo", "status": "done", "_client": "Beejoo", "_driver": "Yao Jun", "binSize": "7 ft", "jobType": "Dump", "siteIdx": 0, "_contact": "", "clientId": "cmrkt9187viy", "distance": 0, "driverId": 5, "createdAt": "2026-07-19T20:49", "startedAt": "07:50", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1784505051464, "instructions": ""}, {"id": 33, "date": "2026-07-20", "_addr": "Benoi", "_task": "Exchange", "price": 19.5, "waste": "General Waste", "dumpTo": "Lirich Resources Pte Ltd", "status": "done", "_client": "ST", "_driver": "Yao Jun", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 1, "_contact": "", "clientId": "cmrkt918dn4k", "distance": 2.3, "driverId": 5, "createdAt": "2026-07-19T20:50", "startedAt": "09:21", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1784510460438, "instructions": ""}, {"id": 34, "date": "2026-07-20", "_addr": "5 Sungei Kadut Street 6", "_task": "Dump", "price": 18, "waste": "Wood Waste", "dumpTo": "Bee Joo", "status": "assigned", "_client": "Beejoo", "_driver": "Kumar", "binSize": "7 ft", "jobType": "Dump", "siteIdx": 0, "_contact": "", "clientId": "cmrkt9187viy", "distance": 0, "driverId": 3, "createdAt": "2026-07-19T20:52", "contactIdx": 0, "surcharges": [], "instructions": ""}, {"id": 35, "date": "2026-07-20", "_addr": "118 Pioneer Rd L1", "_task": "Delivery", "price": 8, "waste": "General Waste", "dumpTo": "", "status": "assigned", "_client": "Radha Exports Pte Ltd", "_driver": "Kumar", "binSize": "7 ft", "jobType": "Delivery", "siteIdx": 0, "_contact": "Radha", "clientId": "c2", "distance": 0, "driverId": 3, "createdAt": "2026-07-19T20:53", "contactIdx": 0, "surcharges": [], "instructions": ""}, {"id": 36, "date": "2026-07-20", "_addr": "61a Tuas Nexus Drive", "_task": "Exchange", "price": 13, "waste": "General Waste", "dumpTo": "Lirich Resources Pte Ltd", "status": "assigned", "_client": "ST", "_driver": "Kumar", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 3, "_contact": "", "clientId": "cmrkt918dn4k", "distance": 7, "driverId": 3, "createdAt": "2026-07-19T20:54", "contactIdx": 0, "surcharges": [], "instructions": ""}, {"id": 37, "date": "2026-07-20", "_addr": "5 Sungei Kadut Street 6", "_task": "Dump", "price": 18, "waste": "Wood Waste", "dumpTo": "Bee Joo", "status": "assigned", "_client": "Beejoo", "_driver": "Sathish", "binSize": "7 ft", "jobType": "Dump", "siteIdx": 0, "_contact": "", "clientId": "cmrkt9187viy", "distance": 0, "driverId": 1, "createdAt": "2026-07-19T20:56", "contactIdx": 0, "surcharges": [], "instructions": ""}, {"id": 38, "date": "2026-07-20", "_addr": "5 Jalan Samulun", "_task": "Exchange", "price": 13, "waste": "General Waste", "dumpTo": "Lirich Resources Pte Ltd", "status": "assigned", "_client": "PaxOcean Singapore Pte Ltd", "_driver": "Sathish", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 0, "_contact": "", "clientId": "cmrkt918askd", "distance": 4.6, "driverId": 1, "createdAt": "2026-07-19T20:57", "contactIdx": 0, "surcharges": [], "instructions": "Morning"}, {"id": 39, "date": "2026-07-20", "_addr": "5 Jalan Samulun", "_task": "Exchange", "price": 13, "waste": "General Waste", "dumpTo": "Lirich Resources Pte Ltd", "status": "assigned", "_client": "PaxOcean Singapore Pte Ltd", "_driver": "Sathish", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 0, "_contact": "", "clientId": "cmrkt918askd", "distance": 4.6, "driverId": 1, "createdAt": "2026-07-19T20:58", "contactIdx": 0, "surcharges": [], "instructions": "Afternoon"}, {"id": 40, "date": "2026-07-20", "_addr": "5 Sungei Kadut Street 6", "_task": "Dump", "price": 18, "waste": "Wood Waste", "dumpTo": "Bee Joo", "status": "assigned", "_client": "Beejoo", "_driver": "Karthik", "binSize": "5 ft", "jobType": "Dump", "siteIdx": 0, "_contact": "", "clientId": "cmrkt9187viy", "distance": 0, "driverId": 2, "createdAt": "2026-07-19T20:59", "contactIdx": 0, "surcharges": [], "instructions": ""}, {"id": 41, "date": "2026-07-20", "_addr": "46 Gul Drive", "_task": "Exchange", "price": 13, "waste": "General Waste", "dumpTo": "Lirich Resources Pte Ltd", "status": "assigned", "_client": "Haid Biotechnology Industry (Singapore) Pte Ltd", "_driver": "Karthik", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 0, "_contact": "", "clientId": "cmrkt9189g55", "distance": 1.1, "driverId": 2, "createdAt": "2026-07-19T21:01", "contactIdx": 0, "surcharges": [], "instructions": "Exchange 660L Bin"}, {"id": 42, "date": "2026-07-20", "_addr": "Gul", "_task": "Exchange", "price": 19.5, "waste": "General Waste", "dumpTo": "Lirich Resources Pte Ltd", "status": "assigned", "_client": "ST", "_driver": "Karthik", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 2, "_contact": "", "clientId": "cmrkt918dn4k", "distance": 0.4, "driverId": 2, "createdAt": "2026-07-19T21:02", "contactIdx": 0, "surcharges": [], "instructions": ""}, {"id": 43, "date": "2026-07-25", "_addr": "9 Gul Circle", "_task": "Exchange", "_test": true, "price": 13, "waste": "General Waste", "dumpTo": "", "status": "done", "_client": "Eng Lee Logistics Pte Ltd", "_driver": "Test Driver", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 0, "_contact": "Jacky", "clientId": "c1", "distance": 0, "driverId": 6, "createdAt": "2026-07-25T03:04", "startedAt": "03:04", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1784919884770, "instructions": ""}, {"id": 44, "date": "2026-07-25", "_addr": "9 Gul Circle", "_task": "Exchange", "price": 13, "waste": "General Waste", "dumpTo": "", "status": "done", "_client": "Eng Lee Logistics Pte Ltd", "_driver": "Sathish", "binSize": "5 ft", "jobType": "Exchange", "siteIdx": 0, "_contact": "Jacky", "clientId": "c1", "distance": 0, "driverId": 1, "createdAt": "2026-07-25T03:35", "startedAt": "03:35", "contactIdx": 0, "surcharges": [], "acceptedAtMs": 1784921751375, "instructions": "testing"}], "trips": [{"id": 1, "tDO": 1784043316345, "_pay": 13, "date": "2026-07-14", "doNo": 2222, "tEnd": 1784043310829, "_addr": "9 Gul Circle", "_type": "Exchange", "binIn": "R08", "jobId": 1, "price": 13, "waste": "Carton Boxes", "_sales": "Patrick", "_surch": "", "binOut": "5239", "doType": "land", "photos": [{"id": "1tgLjlHKUm5ozfJk0IirMSAiTJH9hsYXy", "url": "https://drive.google.com/uc?export=view&id=1tgLjlHKUm5ozfJk0IirMSAiTJH9hsYXy", "kind": "in", "thumb": "https://drive.google.com/thumbnail?id=1tgLjlHKUm5ozfJk0IirMSAiTJH9hsYXy&sz=w240"}, {"id": "1nNhVZLTnxMbl7SymXuG1pSbtRaXcBn1u", "url": "https://drive.google.com/uc?export=view&id=1nNhVZLTnxMbl7SymXuG1pSbtRaXcBn1u", "kind": "out", "thumb": "https://drive.google.com/thumbnail?id=1nNhVZLTnxMbl7SymXuG1pSbtRaXcBn1u&sz=w240"}, {"id": "1jU2lhFs_tSB04dr4OLqJyLdhvUwMvuVp", "url": "https://drive.google.com/uc?export=view&id=1jU2lhFs_tSB04dr4OLqJyLdhvUwMvuVp", "kind": "do", "thumb": "https://drive.google.com/thumbnail?id=1jU2lhFs_tSB04dr4OLqJyLdhvUwMvuVp&sz=w240"}, {"id": "1g37CnCn4F9V53xxWtJ0ukpFRSGrQqBYt", "url": "https://drive.google.com/uc?export=view&id=1g37CnCn4F9V53xxWtJ0ukpFRSGrQqBYt", "kind": "signature", "thumb": "https://drive.google.com/thumbnail?id=1g37CnCn4F9V53xxWtJ0ukpFRSGrQqBYt&sz=w240"}], "tBinIn": 1784043299719, "vessel": null, "weight": {"net": 11, "tare": 1, "gross": 12, "ticket": "LR2"}, "_charge": 13, "_client": "Eng Lee Logistics Pte Ltd", "_driver": "Sathish", "jobType": "Exchange", "remarks": "", "sigName": "m", "tAccept": 1784043239862, "tBinOut": 1784043310829, "tServer": 1784043329809, "tWeight": 0, "timeEnd": "23:35", "tonnAdj": 0, "tonnage": 0, "clientId": "c1", "distance": 0, "driverId": 1, "invoiced": false, "disposeTo": "", "timeStart": "23:34", "vehicleNo": "1234", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": [], "sigPosition": "o"}, {"id": 2, "tDO": 1784043369307, "_pay": 13, "date": "2026-07-14", "doNo": 1233, "tEnd": 1784043363952, "_addr": "9 Gul Circle", "_type": "Exchange", "binIn": "5197", "jobId": 1, "price": 13, "waste": "Metal Waste", "_sales": "Patrick", "_surch": "", "binOut": "Y111", "doType": "land", "photos": [{"id": "1W5NA-QihPP2re3kzsnG7GaVEwTZxxJUR", "url": "https://drive.google.com/uc?export=view&id=1W5NA-QihPP2re3kzsnG7GaVEwTZxxJUR", "kind": "in", "thumb": "https://drive.google.com/thumbnail?id=1W5NA-QihPP2re3kzsnG7GaVEwTZxxJUR&sz=w240"}, {"id": "1Fdvfh3ULw_38sOkADQVlNUICSe-gOH7B", "url": "https://drive.google.com/uc?export=view&id=1Fdvfh3ULw_38sOkADQVlNUICSe-gOH7B", "kind": "out", "thumb": "https://drive.google.com/thumbnail?id=1Fdvfh3ULw_38sOkADQVlNUICSe-gOH7B&sz=w240"}, {"id": "14hohAWmRlA3sAES9ITVXKT1M2m2Gfa5E", "url": "https://drive.google.com/uc?export=view&id=14hohAWmRlA3sAES9ITVXKT1M2m2Gfa5E", "kind": "do", "thumb": "https://drive.google.com/thumbnail?id=14hohAWmRlA3sAES9ITVXKT1M2m2Gfa5E&sz=w240"}, {"id": "19JjJfTKn5IexrPNACe7UAWbZYtajLA7l", "url": "https://drive.google.com/uc?export=view&id=19JjJfTKn5IexrPNACe7UAWbZYtajLA7l", "kind": "signature", "thumb": "https://drive.google.com/thumbnail?id=19JjJfTKn5IexrPNACe7UAWbZYtajLA7l&sz=w240"}], "tBinIn": 1784043358329, "vessel": null, "weight": {"net": 61, "tare": 50, "gross": 111, "ticket": "LR1"}, "_charge": 13, "_client": "Eng Lee Logistics Pte Ltd", "_driver": "Sathish", "jobType": "Exchange", "remarks": "", "sigName": "1qq", "tAccept": 1784043239862, "tBinOut": 1784043363952, "tServer": 1784043423958, "tWeight": 0, "timeEnd": "23:36", "tonnAdj": 0, "tonnage": 0, "clientId": "c1", "distance": 0, "driverId": 1, "invoiced": false, "disposeTo": "", "timeStart": "23:35", "vehicleNo": "2234", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["Metal Waste"], "sigPosition": "999"}, {"id": 3, "tDO": 1784071515005, "_pay": 13, "date": "2026-07-15", "doNo": 26138, "tEnd": 1784071247206, "_addr": "16 Gul Crescent", "_type": "Collect / Exchange — Middle", "binIn": "L801", "jobId": null, "price": null, "waste": "General Waste", "_sales": "", "_surch": "", "binOut": "5245", "doType": "land", "photos": [{"id": "1qFlDqwT8YofpcCAcfXCUKbLjQ1j5ySv7", "url": "https://drive.google.com/uc?export=view&id=1qFlDqwT8YofpcCAcfXCUKbLjQ1j5ySv7", "kind": "in", "thumb": "https://drive.google.com/thumbnail?id=1qFlDqwT8YofpcCAcfXCUKbLjQ1j5ySv7&sz=w240"}, {"id": "1V7UfpThw3CZqRPaKyh_PF8EIW2m4yO0K", "url": "https://drive.google.com/uc?export=view&id=1V7UfpThw3CZqRPaKyh_PF8EIW2m4yO0K", "kind": "out", "thumb": "https://drive.google.com/thumbnail?id=1V7UfpThw3CZqRPaKyh_PF8EIW2m4yO0K&sz=w240"}, {"id": "1SZoxdC0PYt-oNTBfbhzJlo-4Xrq4RYqk", "url": "https://drive.google.com/uc?export=view&id=1SZoxdC0PYt-oNTBfbhzJlo-4Xrq4RYqk", "kind": "do", "thumb": "https://drive.google.com/thumbnail?id=1SZoxdC0PYt-oNTBfbhzJlo-4Xrq4RYqk&sz=w240"}], "tBinIn": 1784071231427, "typeId": "col_m", "vessel": null, "weight": {"net": 2350, "tare": 14100, "gross": 16450, "ticket": "LR6"}, "_charge": "", "_client": "Eng Leng Contractors Pte Ltd", "_driver": "Yao Jun", "jobType": "", "remarks": "", "sigName": "", "tAccept": 0, "tBinOut": 1784071247206, "tServer": 1784072079535, "tWeight": 0, "timeEnd": "07:20", "tonnAdj": 0, "tonnage": 0, "clientId": "cmrkt91888e3", "distance": 0, "driverId": 5, "invoiced": false, "disposeTo": "", "timeStart": "07:20", "vehicleNo": "XE7126P", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["General Waste"], "sigPosition": ""}, {"id": 4, "tDO": 1784074542634, "_pay": 13, "date": "2026-07-15", "doNo": 26139, "tEnd": 1784074019313, "_addr": "11 Tuas Bay Close, #04-01/02", "_type": "Collect / Exchange — Middle", "binIn": "5245", "jobId": null, "price": null, "waste": "General Waste", "_sales": "", "_surch": "", "binOut": "5151", "doType": "land", "photos": [{"id": "1xMrJ-p4atIc61RrIB2OPbcCEH1lwWvcE", "url": "https://drive.google.com/uc?export=view&id=1xMrJ-p4atIc61RrIB2OPbcCEH1lwWvcE", "kind": "in", "thumb": "https://drive.google.com/thumbnail?id=1xMrJ-p4atIc61RrIB2OPbcCEH1lwWvcE&sz=w240"}, {"id": "1H7qG_zGX_aUeH7jQx7KTpN9TNm8ozY7V", "url": "https://drive.google.com/uc?export=view&id=1H7qG_zGX_aUeH7jQx7KTpN9TNm8ozY7V", "kind": "out", "thumb": "https://drive.google.com/thumbnail?id=1H7qG_zGX_aUeH7jQx7KTpN9TNm8ozY7V&sz=w240"}, {"id": "1g_FGtC-FjZGGVDEwHB75vb0APek6EvtQ", "url": "https://drive.google.com/uc?export=view&id=1g_FGtC-FjZGGVDEwHB75vb0APek6EvtQ", "kind": "do", "thumb": "https://drive.google.com/thumbnail?id=1g_FGtC-FjZGGVDEwHB75vb0APek6EvtQ&sz=w240"}], "tBinIn": 1784074010542, "typeId": "col_m", "vessel": null, "weight": {"net": 2370, "tare": 14050, "gross": 16420, "ticket": "LR4"}, "_charge": "", "_client": "LexBuild International Pte Ltd", "_driver": "Yao Jun", "jobType": "", "remarks": "", "sigName": "", "tAccept": 0, "tBinOut": 1784074019313, "tServer": 1784074555682, "tWeight": 0, "timeEnd": "08:06", "tonnAdj": 0, "tonnage": 0, "clientId": "cmrkt918auof", "distance": 0, "driverId": 5, "invoiced": false, "disposeTo": "", "timeStart": "08:06", "vehicleNo": "XE7126P", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["General Waste"], "sigPosition": ""}, {"id": 5, "tDO": 1784076200794, "_pay": 13, "date": "2026-07-15", "doNo": 24436, "tEnd": 1784075742933, "_addr": "16 Gul Crescent", "_type": "Collect / Exchange — Middle", "binIn": "L805", "jobId": null, "price": null, "waste": "General Waste", "_sales": "", "_surch": "", "binOut": "L53", "doType": "land", "photos": [{"id": "1Vb1CWUVz51t5tfF_hZCj6SH5XxrwIRqO", "url": "https://drive.google.com/uc?export=view&id=1Vb1CWUVz51t5tfF_hZCj6SH5XxrwIRqO", "kind": "in", "thumb": "https://drive.google.com/thumbnail?id=1Vb1CWUVz51t5tfF_hZCj6SH5XxrwIRqO&sz=w240"}, {"id": "1vHghJ-AqSLjYQm7RBpY6-5IveejK09zj", "url": "https://drive.google.com/uc?export=view&id=1vHghJ-AqSLjYQm7RBpY6-5IveejK09zj", "kind": "out", "thumb": "https://drive.google.com/thumbnail?id=1vHghJ-AqSLjYQm7RBpY6-5IveejK09zj&sz=w240"}, {"id": "1JgZ4XwuS7NQ1dpvXJTx-CHO3P-q5pUwK", "url": "https://drive.google.com/uc?export=view&id=1JgZ4XwuS7NQ1dpvXJTx-CHO3P-q5pUwK", "kind": "do", "thumb": "https://drive.google.com/thumbnail?id=1JgZ4XwuS7NQ1dpvXJTx-CHO3P-q5pUwK&sz=w240"}, {"id": "1T9vDX9FiLrGdDqH9lXssT5Gg4M4z8leq", "url": "https://drive.google.com/uc?export=view&id=1T9vDX9FiLrGdDqH9lXssT5Gg4M4z8leq", "kind": "gross", "thumb": "https://drive.google.com/thumbnail?id=1T9vDX9FiLrGdDqH9lXssT5Gg4M4z8leq&sz=w240"}, {"id": "1xmEMxQ9_zgOxLN5ZYPATfPaygFyDwQPd", "url": "https://drive.google.com/uc?export=view&id=1xmEMxQ9_zgOxLN5ZYPATfPaygFyDwQPd", "kind": "signature", "thumb": "https://drive.google.com/thumbnail?id=1xmEMxQ9_zgOxLN5ZYPATfPaygFyDwQPd&sz=w240"}], "tBinIn": 1784075733368, "typeId": "col_m", "vessel": null, "weight": null, "_charge": "", "_client": "B&C Waste", "_driver": "Liu", "jobType": "", "remarks": "", "sigName": "", "tAccept": 0, "tBinOut": 1784075742933, "tServer": 1784076241962, "tWeight": 1784076231052, "timeEnd": "08:35", "tonnAdj": 0, "tonnage": 0, "clientId": "cmrkt91878od", "distance": 0, "driverId": 4, "invoiced": false, "disposeTo": "", "timeStart": "08:35", "vehicleNo": "XE8496P", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["General Waste"], "sigPosition": ""}, {"id": 6, "tDO": 1784077013616, "_pay": 13, "date": "2026-07-15", "doNo": 26140, "tEnd": 1784076916734, "_addr": "14 Benoi Place", "_type": "Collect / Exchange — Middle", "binIn": "5151", "jobId": null, "price": null, "waste": "General Waste", "_sales": "", "_surch": "", "binOut": "5109", "doType": "land", "photos": [{"id": "1UuOmAHMaagpi9UMdSCnQnGkO8qPsX9Y1", "url": "https://drive.google.com/uc?export=view&id=1UuOmAHMaagpi9UMdSCnQnGkO8qPsX9Y1", "kind": "in", "thumb": "https://drive.google.com/thumbnail?id=1UuOmAHMaagpi9UMdSCnQnGkO8qPsX9Y1&sz=w240"}, {"id": "1RrkuoJNVT6YpB5uhK_pcrDrdOrRGprox", "url": "https://drive.google.com/uc?export=view&id=1RrkuoJNVT6YpB5uhK_pcrDrdOrRGprox", "kind": "out", "thumb": "https://drive.google.com/thumbnail?id=1RrkuoJNVT6YpB5uhK_pcrDrdOrRGprox&sz=w240"}, {"id": "1hcfmrIjFaC0y6K5yw7HH-56xL9a7StIZ", "url": "https://drive.google.com/uc?export=view&id=1hcfmrIjFaC0y6K5yw7HH-56xL9a7StIZ", "kind": "do", "thumb": "https://drive.google.com/thumbnail?id=1hcfmrIjFaC0y6K5yw7HH-56xL9a7StIZ&sz=w240"}], "tBinIn": 1784076911151, "typeId": "col_m", "vessel": null, "weight": {"net": 2180, "tare": 13900, "gross": 16080, "ticket": "LR5"}, "_charge": "", "_client": "Aver Asia (S) Pte Ltd", "_driver": "Yao Jun", "jobType": "", "remarks": "", "sigName": "", "tAccept": 0, "tBinOut": 1784076916734, "tServer": 1784077020268, "tWeight": 0, "timeEnd": "08:55", "tonnAdj": 0, "tonnage": 0, "clientId": "cmrkt9187zx3", "distance": 0, "driverId": 5, "invoiced": false, "disposeTo": "", "timeStart": "08:55", "vehicleNo": "XE7126P", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["General Waste"], "sigPosition": ""}, {"id": 7, "tDO": 1784079687110, "_pay": 13, "date": "2026-07-15", "doNo": 24437, "tEnd": 1784079351735, "_addr": "16 Gul Crescent", "_type": "Collect / Exchange — Middle", "binIn": "L53", "jobId": null, "price": null, "waste": "General Waste", "_sales": "", "_surch": "", "binOut": "L805", "doType": "land", "photos": [{"id": "1kVvuBCuKOorb_nsmiffYmiIuV9w9KJsc", "url": "https://drive.google.com/uc?export=view&id=1kVvuBCuKOorb_nsmiffYmiIuV9w9KJsc", "kind": "in", "thumb": "https://drive.google.com/thumbnail?id=1kVvuBCuKOorb_nsmiffYmiIuV9w9KJsc&sz=w240"}, {"id": "1OpCe92IT-B0nMP72derqw3kS3MopnedW", "url": "https://drive.google.com/uc?export=view&id=1OpCe92IT-B0nMP72derqw3kS3MopnedW", "kind": "out", "thumb": "https://drive.google.com/thumbnail?id=1OpCe92IT-B0nMP72derqw3kS3MopnedW&sz=w240"}, {"id": "1DAJiNSy0Ri877eCvQLsDO_lEp2ePg-xt", "url": "https://drive.google.com/uc?export=view&id=1DAJiNSy0Ri877eCvQLsDO_lEp2ePg-xt", "kind": "do", "thumb": "https://drive.google.com/thumbnail?id=1DAJiNSy0Ri877eCvQLsDO_lEp2ePg-xt&sz=w240"}, {"id": "1vvTxGEOC5zH20IJLRKYEfYiGIyRs6tVr", "url": "https://drive.google.com/uc?export=view&id=1vvTxGEOC5zH20IJLRKYEfYiGIyRs6tVr", "kind": "gross", "thumb": "https://drive.google.com/thumbnail?id=1vvTxGEOC5zH20IJLRKYEfYiGIyRs6tVr&sz=w240"}, {"id": "1sug1rNwNtmyyJxKKTicGHI9iUe7HW4Ca", "url": "https://drive.google.com/uc?export=view&id=1sug1rNwNtmyyJxKKTicGHI9iUe7HW4Ca", "kind": "signature", "thumb": "https://drive.google.com/thumbnail?id=1sug1rNwNtmyyJxKKTicGHI9iUe7HW4Ca&sz=w240"}], "tBinIn": 1784079344671, "typeId": "col_m", "vessel": null, "weight": null, "_charge": "", "_client": "B&C Waste", "_driver": "Liu", "jobType": "", "remarks": "", "sigName": "", "tAccept": 0, "tBinOut": 1784079351735, "tServer": 1784079750044, "tWeight": 1784079740316, "timeEnd": "09:35", "tonnAdj": 0, "tonnage": 0, "clientId": "cmrkt91878od", "distance": 0, "driverId": 4, "invoiced": false, "disposeTo": "", "timeStart": "09:35", "vehicleNo": "XE8496P", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["General Waste"], "sigPosition": ""}, {"id": 8, "tDO": 1784083739701, "_pay": 13, "date": "2026-07-15", "doNo": 26141, "tEnd": 1784083734080, "_addr": "48 Pandan Road L3", "_type": "Exchange", "binIn": "5109", "jobId": 3, "price": 13, "waste": "General Waste", "_sales": "", "_surch": "", "binOut": "5028", "doType": "land", "photos": [{"id": "19YTk0k2rnjHXzGglV37GqYja2f7y-I8N", "url": "https://drive.google.com/uc?export=view&id=19YTk0k2rnjHXzGglV37GqYja2f7y-I8N", "kind": "in", "thumb": "https://drive.google.com/thumbnail?id=19YTk0k2rnjHXzGglV37GqYja2f7y-I8N&sz=w240"}, {"id": "1xiSWQVckX3IhOkwZbeTW4SUH0s7GBPlL", "url": "https://drive.google.com/uc?export=view&id=1xiSWQVckX3IhOkwZbeTW4SUH0s7GBPlL", "kind": "out", "thumb": "https://drive.google.com/thumbnail?id=1xiSWQVckX3IhOkwZbeTW4SUH0s7GBPlL&sz=w240"}, {"id": "1-XIrWYwbV7gABY5ubsMK542N7UXHNLK9", "url": "https://drive.google.com/uc?export=view&id=1-XIrWYwbV7gABY5ubsMK542N7UXHNLK9", "kind": "do", "thumb": "https://drive.google.com/thumbnail?id=1-XIrWYwbV7gABY5ubsMK542N7UXHNLK9&sz=w240"}], "tBinIn": 1784083726402, "typeId": "send", "vessel": null, "weight": {"net": 2770, "tare": 14100, "gross": 16870, "ticket": "LR3"}, "_charge": 13, "_client": "Poh Tiong Choon Logistics Ltd", "_driver": "Yao Jun", "jobType": "Exchange", "remarks": "", "sigName": "", "tAccept": 1784083566810, "tBinOut": 1784083734080, "tServer": 1784083789210, "tWeight": 0, "timeEnd": "10:48", "tonnAdj": 0, "tonnage": 0, "clientId": "cmrkt918ag06", "distance": 0, "driverId": 5, "invoiced": false, "disposeTo": "", "timeStart": "10:48", "vehicleNo": "XE7126P", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["General Waste"], "sigPosition": ""}, {"id": 9, "tDO": 1784083822099, "_pay": 0, "date": "2026-07-15", "doNo": 26141, "tEnd": 1784083818920, "_addr": "48 Pandan Road L3", "_type": "Exchange", "binIn": "5109", "jobId": 3, "price": 0, "waste": "General Waste", "_sales": "", "_surch": "", "binOut": "5028", "doType": "land", "photos": [{"id": "12fNbQQoIi-uZ0KvTs-oGaRqUiRkPIS2Y", "url": "https://drive.google.com/uc?export=view&id=12fNbQQoIi-uZ0KvTs-oGaRqUiRkPIS2Y", "kind": "in", "thumb": "https://drive.google.com/thumbnail?id=12fNbQQoIi-uZ0KvTs-oGaRqUiRkPIS2Y&sz=w240"}, {"id": "1tOsRtuWobrSWnGrUfy9KqvDlHwA6lPdw", "url": "https://drive.google.com/uc?export=view&id=1tOsRtuWobrSWnGrUfy9KqvDlHwA6lPdw", "kind": "out", "thumb": "https://drive.google.com/thumbnail?id=1tOsRtuWobrSWnGrUfy9KqvDlHwA6lPdw&sz=w240"}, {"id": "1i2KSiWHMwClaTfeVdFRaI7kjarrcoJ2J", "url": "https://drive.google.com/uc?export=view&id=1i2KSiWHMwClaTfeVdFRaI7kjarrcoJ2J", "kind": "do", "thumb": "https://drive.google.com/thumbnail?id=1i2KSiWHMwClaTfeVdFRaI7kjarrcoJ2J&sz=w240"}], "tBinIn": 1784083815170, "vessel": null, "weight": null, "_charge": 0, "_client": "Poh Tiong Choon Logistics Ltd", "_driver": "Yao Jun", "jobType": "Exchange", "remarks": "DUPLICATE of Trip #8 (same Job #3 / DO 26141) — voided by office, no pay/charge", "sigName": "", "tAccept": 1784083566810, "tBinOut": 1784083818920, "tServer": 1784083842987, "tWeight": 0, "timeEnd": "10:50", "tonnAdj": 0, "tonnage": 0, "clientId": "cmrkt918ag06", "distance": 0, "driverId": 5, "invoiced": false, "disposeTo": "", "timeStart": "10:50", "vehicleNo": "XE7126P", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["General Waste"], "sigPosition": ""}, {"id": 10, "tDO": 1784092488976, "_pay": 18, "date": "2026-07-15", "doNo": 130351, "tEnd": 1784093095025, "_addr": "79 Anson Road", "_type": "Exchange", "binIn": "5072", "jobId": 4, "price": 18, "waste": "Wood Waste", "_sales": "", "_surch": "", "binOut": "5070", "doType": "land", "photos": [{"id": "10vmRrXWJF4TA3IeMvYRKzYA2MDFG7HTZ", "url": "https://drive.google.com/uc?export=view&id=10vmRrXWJF4TA3IeMvYRKzYA2MDFG7HTZ", "kind": "do", "thumb": "https://drive.google.com/thumbnail?id=10vmRrXWJF4TA3IeMvYRKzYA2MDFG7HTZ&sz=w240"}, {"id": "1XNcbU-Umw02k_OAUdsjGPIroIZQbwCQi", "url": "https://drive.google.com/uc?export=view&id=1XNcbU-Umw02k_OAUdsjGPIroIZQbwCQi", "kind": "in", "thumb": "https://drive.google.com/thumbnail?id=1XNcbU-Umw02k_OAUdsjGPIroIZQbwCQi&sz=w240"}, {"id": "1cV2ElhMxZMaqJBqGctop7WFdW4eyNxS1", "url": "https://drive.google.com/uc?export=view&id=1cV2ElhMxZMaqJBqGctop7WFdW4eyNxS1", "kind": "out", "thumb": "https://drive.google.com/thumbnail?id=1cV2ElhMxZMaqJBqGctop7WFdW4eyNxS1&sz=w240"}], "tBinIn": 1784093090592, "typeId": "send", "vessel": null, "weight": {"net": 2560, "tare": 14810, "gross": 17370, "ticket": "LR7"}, "_charge": 18, "_client": "HCG", "_driver": "Yao Jun", "jobType": "Exchange", "remarks": "", "sigName": "", "tAccept": 1784092230111, "tBinOut": 1784093095025, "tServer": 1784092560713, "tWeight": 0, "timeEnd": "13:24", "tonnAdj": 0, "tonnage": 0, "clientId": "cmrkt9189v5w", "distance": 0, "driverId": 5, "invoiced": false, "disposeTo": "", "timeStart": "13:24", "vehicleNo": "XE7126P", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["Wood Waste"], "sigPosition": ""}, {"id": 11, "tDO": 1784092777431, "_pay": 0, "date": "2026-07-15", "doNo": 130351, "tEnd": 1784093066201, "_addr": "79 Anson Road", "_type": "Exchange", "binIn": "5072", "jobId": 4, "price": 0, "waste": "Wood Waste", "_sales": "", "_surch": "", "binOut": "5070", "doType": "land", "photos": [{"id": "1hX3uiC98aNawe_rMVCijSs5zOpCsUrJI", "url": "https://drive.google.com/uc?export=view&id=1hX3uiC98aNawe_rMVCijSs5zOpCsUrJI", "kind": "in", "thumb": "https://drive.google.com/thumbnail?id=1hX3uiC98aNawe_rMVCijSs5zOpCsUrJI&sz=w240"}, {"id": "1KjuYwJCPwMX793jzhttYKtONraoZXE-6", "url": "https://drive.google.com/uc?export=view&id=1KjuYwJCPwMX793jzhttYKtONraoZXE-6", "kind": "out", "thumb": "https://drive.google.com/thumbnail?id=1KjuYwJCPwMX793jzhttYKtONraoZXE-6&sz=w240"}, {"id": "1CoZdMsbdT9CP8-S-DhQPaDjcTDscWMC8", "url": "https://drive.google.com/uc?export=view&id=1CoZdMsbdT9CP8-S-DhQPaDjcTDscWMC8", "kind": "do", "thumb": "https://drive.google.com/thumbnail?id=1CoZdMsbdT9CP8-S-DhQPaDjcTDscWMC8&sz=w240"}], "tBinIn": 1784093061131, "vessel": null, "weight": null, "_charge": 0, "_client": "HCG", "_driver": "Yao Jun", "jobType": "Exchange", "remarks": "DUPLICATE of Trip #10 (same Job #4 / DO 130351) — voided by office, no pay/charge", "sigName": "", "tAccept": 1784092230111, "tBinOut": 1784093066201, "tServer": 1784093074379, "tWeight": 0, "timeEnd": "13:24", "tonnAdj": 0, "tonnage": 0, "clientId": "cmrkt9189v5w", "distance": 0, "driverId": 5, "invoiced": false, "disposeTo": "", "timeStart": "13:24", "vehicleNo": "XE7126P", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["Wood Waste"], "sigPosition": ""}, {"id": 12, "tDO": 1784101592533, "_pay": 31, "date": "2026-07-15", "doNo": 41767, "tEnd": 1784101577412, "_addr": "26 Loyang Drive", "_type": "Load", "binIn": "R13", "jobId": 5, "price": 31, "waste": "Wood Waste", "_sales": "", "_surch": "", "binOut": "R13", "doType": "land", "photos": [{"id": "1PEcHHSrsgmdw_FYGmwz2SXf_YQIkItmt", "url": "https://drive.google.com/uc?export=view&id=1PEcHHSrsgmdw_FYGmwz2SXf_YQIkItmt", "kind": "in", "thumb": "https://drive.google.com/thumbnail?id=1PEcHHSrsgmdw_FYGmwz2SXf_YQIkItmt&sz=w240"}, {"id": "1rENbGVPDnU17thW_8d7IvoIsCzn7s8os", "url": "https://drive.google.com/uc?export=view&id=1rENbGVPDnU17thW_8d7IvoIsCzn7s8os", "kind": "out", "thumb": "https://drive.google.com/thumbnail?id=1rENbGVPDnU17thW_8d7IvoIsCzn7s8os&sz=w240"}, {"id": "1FjqgXtP6_HEjulcsh5XRY624R0ZLCABz", "url": "https://drive.google.com/uc?export=view&id=1FjqgXtP6_HEjulcsh5XRY624R0ZLCABz", "kind": "do", "thumb": "https://drive.google.com/thumbnail?id=1FjqgXtP6_HEjulcsh5XRY624R0ZLCABz&sz=w240"}], "tBinIn": 1784101561860, "vessel": null, "weight": null, "_charge": 31, "_client": "B&C Waste", "_driver": "Yao Jun", "jobType": "Load", "remarks": "", "sigName": "", "tAccept": 1784099668422, "tBinOut": 1784101577412, "tServer": 1784101625150, "tWeight": 0, "timeEnd": "15:46", "tonnAdj": 0, "tonnage": 0, "clientId": "cmrkt91878od", "distance": 0, "driverId": 5, "invoiced": false, "disposeTo": "", "timeStart": "15:46", "vehicleNo": "XE7126P", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["Wood Waste"], "sigPosition": ""}, {"id": 13, "tDO": 1784111702513, "_pay": 13, "date": "2026-07-15", "doNo": 26143, "tEnd": 1784111098580, "_addr": "47A Jalan Buroh", "_type": "Exchange", "binIn": "5033", "jobId": 6, "price": 13, "waste": "General Waste", "_sales": "", "_surch": "", "binOut": "5084", "doType": "land", "photos": [{"id": "1rXel9yA366uv2L-HZinhFWS-oR6ms0o_", "url": "https://drive.google.com/uc?export=view&id=1rXel9yA366uv2L-HZinhFWS-oR6ms0o_", "kind": "in", "thumb": "https://drive.google.com/thumbnail?id=1rXel9yA366uv2L-HZinhFWS-oR6ms0o_&sz=w240"}, {"id": "1WgF0l6sHzhrXvHuKlhwvATkp4WhkyUio", "url": "https://drive.google.com/uc?export=view&id=1WgF0l6sHzhrXvHuKlhwvATkp4WhkyUio", "kind": "out", "thumb": "https://drive.google.com/thumbnail?id=1WgF0l6sHzhrXvHuKlhwvATkp4WhkyUio&sz=w240"}, {"id": "1kzwOoTewqvBR5Kn9oY-izITJsqgi7meO", "url": "https://drive.google.com/uc?export=view&id=1kzwOoTewqvBR5Kn9oY-izITJsqgi7meO", "kind": "do", "thumb": "https://drive.google.com/thumbnail?id=1kzwOoTewqvBR5Kn9oY-izITJsqgi7meO&sz=w240"}], "tBinIn": 1784111092703, "vessel": null, "weight": {"net": 1180, "tare": 14100, "gross": 15280, "ticket": "LR8"}, "_charge": 13, "_client": "Advanced Substrate Technologies Pte Ltd", "_driver": "Yao Jun", "jobType": "Exchange", "remarks": "", "sigName": "", "tAccept": 1784109223975, "tBinOut": 1784111098580, "tServer": 1784111729097, "tWeight": 0, "timeEnd": "18:24", "tonnAdj": 0, "tonnage": 0, "clientId": "cmrkt9187x1k", "distance": 0, "driverId": 5, "invoiced": false, "disposeTo": "", "timeStart": "18:24", "vehicleNo": "XE7126P", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["General Waste"], "sigPosition": ""}, {"id": 14, "tDO": 1784116479514, "_pay": 18, "date": "2026-07-15", "doNo": 130352, "tEnd": 1784116593955, "_addr": "79 Anson Road", "_type": "Exchange", "binIn": "5070号", "jobId": 7, "price": 18, "waste": "General Waste", "_sales": "", "_surch": "", "binOut": "5193", "doType": "land", "photos": [{"id": "18ZwPbi7_6RWP8GelyM2jj_v9C7O9yyMf", "url": "https://drive.google.com/uc?export=view&id=18ZwPbi7_6RWP8GelyM2jj_v9C7O9yyMf", "kind": "in", "thumb": "https://drive.google.com/thumbnail?id=18ZwPbi7_6RWP8GelyM2jj_v9C7O9yyMf&sz=w240"}, {"id": "1_ujAtz5uxQsJBsui_YII3hBEoUSl5luo", "url": "https://drive.google.com/uc?export=view&id=1_ujAtz5uxQsJBsui_YII3hBEoUSl5luo", "kind": "out", "thumb": "https://drive.google.com/thumbnail?id=1_ujAtz5uxQsJBsui_YII3hBEoUSl5luo&sz=w240"}, {"id": "1Ep2VBalTd9LvuG-sgK2WQM-XndKvkaeF", "url": "https://drive.google.com/uc?export=view&id=1Ep2VBalTd9LvuG-sgK2WQM-XndKvkaeF", "kind": "do", "thumb": "https://drive.google.com/thumbnail?id=1Ep2VBalTd9LvuG-sgK2WQM-XndKvkaeF&sz=w240"}], "tBinIn": 1784116504583, "vessel": null, "weight": null, "_charge": 18, "_client": "HCG", "_driver": "Yao Jun", "jobType": "Exchange", "remarks": "", "sigName": "", "tAccept": 1784112771627, "tBinOut": 1784116593955, "tServer": 1784116628918, "tWeight": 0, "timeEnd": "19:56", "tonnAdj": 0, "tonnage": 0, "clientId": "cmrkt9189v5w", "distance": 0, "driverId": 5, "invoiced": false, "disposeTo": "", "timeStart": "19:55", "vehicleNo": "XE7126P", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["General Waste"], "sigPosition": ""}, {"id": 15, "tDO": 1784127628883, "_pay": 18, "date": "2026-07-15", "doNo": 26144, "tEnd": 1784127597933, "_addr": "6 Chin Bee Ave L5", "_type": "Exchange", "binIn": "R21", "jobId": 13, "price": 13, "waste": "General Waste", "_sales": "", "_surch": "After 7pm (Vessel)", "binOut": "R21", "doType": "land", "photos": [{"id": "1lfk9MOCXXDDDuHDnxXrHJVNny9-yf1ou", "url": "https://drive.google.com/uc?export=view&id=1lfk9MOCXXDDDuHDnxXrHJVNny9-yf1ou", "kind": "in", "thumb": "https://drive.google.com/thumbnail?id=1lfk9MOCXXDDDuHDnxXrHJVNny9-yf1ou&sz=w240"}, {"id": "1tmhM2nspeUP1UwWxAgN-P_o4W2z9UCuv", "url": "https://drive.google.com/uc?export=view&id=1tmhM2nspeUP1UwWxAgN-P_o4W2z9UCuv", "kind": "out", "thumb": "https://drive.google.com/thumbnail?id=1tmhM2nspeUP1UwWxAgN-P_o4W2z9UCuv&sz=w240"}, {"id": "1c_btJQYx-ktkRL5ka8IqE9sRrag6XB0k", "url": "https://drive.google.com/uc?export=view&id=1c_btJQYx-ktkRL5ka8IqE9sRrag6XB0k", "kind": "do", "thumb": "https://drive.google.com/thumbnail?id=1c_btJQYx-ktkRL5ka8IqE9sRrag6XB0k&sz=w240"}], "tBinIn": 1784127593575, "vessel": null, "weight": {"net": 1300, "tare": 14050, "gross": 15350, "ticket": "LR9"}, "_charge": 13, "_client": "Shin Ya O Ya Pte Ltd", "_driver": "Yao Jun", "jobType": "Exchange", "remarks": "", "sigName": "", "tAccept": 1784127557628, "tBinOut": 1784127597933, "tServer": 1784127668045, "tWeight": 0, "timeEnd": "22:59", "tonnAdj": 0, "tonnage": 0, "clientId": "cmrkt918dq77", "distance": 0, "driverId": 5, "invoiced": false, "disposeTo": "Lirich Resources Pte Ltd", "timeStart": "22:59", "vehicleNo": "XE7126P", "weightAdj": 0, "surcharges": ["after7v"], "wasteOther": "", "wasteTypes": ["General Waste"], "sigPosition": ""}, {"id": 16, "tDO": 1784163115843, "_pay": 13, "date": "2026-07-16", "doNo": 26145, "tEnd": 1784163061350, "_addr": "8 Pandan Crescent", "_type": "Exchange", "binIn": "7006", "jobId": 14, "price": 13, "waste": "General Waste", "_sales": "", "_surch": "", "binOut": "8005", "doType": "land", "photos": [{"id": "18mGbQqsLMEDnKkwLGo7e2yJQD3188dkX", "url": "https://drive.google.com/uc?export=view&id=18mGbQqsLMEDnKkwLGo7e2yJQD3188dkX", "kind": "in", "thumb": "https://drive.google.com/thumbnail?id=18mGbQqsLMEDnKkwLGo7e2yJQD3188dkX&sz=w240"}, {"id": "1O26ckVh6NLtPzOPMUpM323OyFQ1rr75m", "url": "https://drive.google.com/uc?export=view&id=1O26ckVh6NLtPzOPMUpM323OyFQ1rr75m", "kind": "out", "thumb": "https://drive.google.com/thumbnail?id=1O26ckVh6NLtPzOPMUpM323OyFQ1rr75m&sz=w240"}, {"id": "1mLurR3mtqgY0cmYLUIgUWSwsxuEAVGDL", "url": "https://drive.google.com/uc?export=view&id=1mLurR3mtqgY0cmYLUIgUWSwsxuEAVGDL", "kind": "do", "thumb": "https://drive.google.com/thumbnail?id=1mLurR3mtqgY0cmYLUIgUWSwsxuEAVGDL&sz=w240"}], "tBinIn": 1784163053131, "vessel": null, "weight": {"net": 2130, "tare": 14650, "gross": 16780, "ticket": "LR10"}, "_charge": 13, "_client": "ASL Proworld Solution Pte Ltd", "_driver": "Yao Jun", "jobType": "Exchange", "remarks": "", "sigName": "", "tAccept": 1784162742439, "tBinOut": 1784163061350, "tServer": 1784163151992, "tWeight": 0, "timeEnd": "08:51", "tonnAdj": 0, "tonnage": 0, "clientId": "cmrkt9187ws7", "distance": 13.1, "driverId": 5, "invoiced": false, "disposeTo": "Lirich Resources Pte Ltd", "timeStart": "08:50", "vehicleNo": "XE7126P", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["General Waste"], "sigPosition": ""}, {"id": 17, "tDO": 1784167594817, "_pay": 13, "date": "2026-07-16", "doNo": 26146, "tEnd": 1784167171816, "_addr": "60 Benoi Road", "_type": "Exchange", "binIn": "L57", "jobId": 15, "price": 13, "waste": "General Waste", "_sales": "", "_surch": "", "binOut": "5213", "doType": "land", "photos": [{"id": "1AHAR0zEKuGBzXVNQ1bpGQeAnNQPw8bVY", "url": "https://drive.google.com/uc?export=view&id=1AHAR0zEKuGBzXVNQ1bpGQeAnNQPw8bVY", "kind": "in", "thumb": "https://drive.google.com/thumbnail?id=1AHAR0zEKuGBzXVNQ1bpGQeAnNQPw8bVY&sz=w240"}, {"id": "10my5iLMP6bf3h6_hdxSB9ZGpGpxKfS_L", "url": "https://drive.google.com/uc?export=view&id=10my5iLMP6bf3h6_hdxSB9ZGpGpxKfS_L", "kind": "out", "thumb": "https://drive.google.com/thumbnail?id=10my5iLMP6bf3h6_hdxSB9ZGpGpxKfS_L&sz=w240"}, {"id": "1tsvTulFhjZpII0jjDYAFFDIq8OhpDJbt", "url": "https://drive.google.com/uc?export=view&id=1tsvTulFhjZpII0jjDYAFFDIq8OhpDJbt", "kind": "do", "thumb": "https://drive.google.com/thumbnail?id=1tsvTulFhjZpII0jjDYAFFDIq8OhpDJbt&sz=w240"}], "tBinIn": 1784167164967, "vessel": null, "weight": {"net": 15965, "tare": 1395, "gross": 17360, "ticket": "LR11"}, "_charge": 13, "_client": "EverTeam Pte Ltd", "_driver": "Yao Jun", "jobType": "Exchange", "remarks": "", "sigName": "", "tAccept": 1784167147780, "tBinOut": 1784167171816, "tServer": 1784167619295, "tWeight": 0, "timeEnd": "09:59", "tonnAdj": 0, "tonnage": 0, "clientId": "cmrkt9189j9t", "distance": 1.9, "driverId": 5, "invoiced": false, "disposeTo": "Lirich Resources Pte Ltd", "timeStart": "09:59", "vehicleNo": "XE7126P", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["General Waste"], "sigPosition": ""}, {"id": 18, "tDO": 1784172031973, "_pay": 18, "date": "2026-07-16", "doNo": 130353, "tEnd": 1784171589576, "_addr": "79 Anson Road", "_type": "Exchange", "binIn": "5193", "jobId": 21, "price": 18, "waste": "Wood Waste", "_sales": "", "_surch": "", "binOut": "5132", "doType": "land", "photos": [{"id": "1ATztqAtb0SB81wvu9WFUVIhAYfyn7-Nt", "url": "https://drive.google.com/uc?export=view&id=1ATztqAtb0SB81wvu9WFUVIhAYfyn7-Nt", "kind": "in", "thumb": "https://drive.google.com/thumbnail?id=1ATztqAtb0SB81wvu9WFUVIhAYfyn7-Nt&sz=w240"}, {"id": "17lqHyCkKkt3gRNlwNvAPsLe7QrWmDxcn", "url": "https://drive.google.com/uc?export=view&id=17lqHyCkKkt3gRNlwNvAPsLe7QrWmDxcn", "kind": "out", "thumb": "https://drive.google.com/thumbnail?id=17lqHyCkKkt3gRNlwNvAPsLe7QrWmDxcn&sz=w240"}, {"id": "1B-1uZfGzmgynG8FVhsGnZyZL1AZ24IPa", "url": "https://drive.google.com/uc?export=view&id=1B-1uZfGzmgynG8FVhsGnZyZL1AZ24IPa", "kind": "do", "thumb": "https://drive.google.com/thumbnail?id=1B-1uZfGzmgynG8FVhsGnZyZL1AZ24IPa&sz=w240"}], "tBinIn": 1784171582853, "vessel": null, "weight": null, "_charge": 18, "_client": "HCG", "_driver": "Yao Jun", "jobType": "Exchange", "remarks": "", "sigName": "", "tAccept": 1784169791187, "tBinOut": 1784171589576, "tServer": 1784172041720, "tWeight": 0, "timeEnd": "11:13", "tonnAdj": 0, "tonnage": 0, "clientId": "cmrkt9189v5w", "distance": 32, "driverId": 5, "invoiced": false, "disposeTo": "HCG Environmental Pte Ltd", "timeStart": "11:13", "vehicleNo": "XE7126P", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["Wood Waste"], "sigPosition": ""}, {"id": 19, "tDO": 1784184620264, "_pay": 18, "date": "2026-07-16", "doNo": 130354, "tEnd": 1784184586430, "_addr": "79 Anson Road", "_type": "Exchange", "binIn": "5132", "jobId": 20, "price": 18, "waste": "General Waste", "_sales": "", "_surch": "", "binOut": "5072", "doType": "land", "photos": [{"id": "1AGLyIHSUjlboegCEa3HWSyYsxX7hPiZJ", "url": "https://drive.google.com/uc?export=view&id=1AGLyIHSUjlboegCEa3HWSyYsxX7hPiZJ", "kind": "in", "thumb": "https://drive.google.com/thumbnail?id=1AGLyIHSUjlboegCEa3HWSyYsxX7hPiZJ&sz=w240"}, {"id": "14C5rcRXjWYFSWgdgu1mjR-d8Ar_0zXtg", "url": "https://drive.google.com/uc?export=view&id=14C5rcRXjWYFSWgdgu1mjR-d8Ar_0zXtg", "kind": "out", "thumb": "https://drive.google.com/thumbnail?id=14C5rcRXjWYFSWgdgu1mjR-d8Ar_0zXtg&sz=w240"}, {"id": "1u3CpdU1tSn2qsNIbCRvfqw4ser-eHTZe", "url": "https://drive.google.com/uc?export=view&id=1u3CpdU1tSn2qsNIbCRvfqw4ser-eHTZe", "kind": "do", "thumb": "https://drive.google.com/thumbnail?id=1u3CpdU1tSn2qsNIbCRvfqw4ser-eHTZe&sz=w240"}], "tBinIn": 1784184554590, "vessel": null, "weight": null, "_charge": 18, "_client": "HCG", "_driver": "Yao Jun", "jobType": "Exchange", "remarks": "", "sigName": "", "tAccept": 1784183568667, "tBinOut": 1784184586430, "tServer": 1784184652222, "tWeight": 0, "timeEnd": "14:49", "tonnAdj": 0, "tonnage": 0, "clientId": "cmrkt9189v5w", "distance": 32, "driverId": 5, "invoiced": false, "disposeTo": "HCG Environmental Pte Ltd", "timeStart": "14:49", "vehicleNo": "XE7126P", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["General Waste"], "sigPosition": ""}, {"id": 20, "tDO": 1784296282125, "_pay": 13, "date": "2026-07-17", "doNo": 26218, "tEnd": 0, "_addr": "9 Gul Circle", "_type": "Exchange", "binIn": "", "jobId": 28, "price": 13, "waste": "General Waste", "_sales": "Patrick", "_surch": "", "binOut": "", "doType": "land", "photos": [{"id": "1-CyxHvyBN_IBRTt5dvT_6HqpxvGX75qx", "url": "https://drive.google.com/uc?export=view&id=1-CyxHvyBN_IBRTt5dvT_6HqpxvGX75qx", "kind": "do", "thumb": "https://drive.google.com/thumbnail?id=1-CyxHvyBN_IBRTt5dvT_6HqpxvGX75qx&sz=w240"}, {"id": "1CyfT6Af8Q0HOzu_fAEJQEzXufiF9Rki6", "url": "https://drive.google.com/uc?export=view&id=1CyfT6Af8Q0HOzu_fAEJQEzXufiF9Rki6", "kind": "signature", "thumb": "https://drive.google.com/thumbnail?id=1CyfT6Af8Q0HOzu_fAEJQEzXufiF9Rki6&sz=w240"}], "tBinIn": 0, "vessel": null, "weight": null, "_charge": 13, "_client": "Eng Lee Logistics Pte Ltd", "_driver": "Test Driver", "jobType": "Exchange", "remarks": "", "sigName": "", "tAccept": 1784295480487, "tBinOut": 0, "tServer": 1784296361691, "tWeight": 0, "timeEnd": "", "tonnAdj": 0, "tonnage": 0, "clientId": "c1", "distance": 0, "driverId": 6, "invoiced": false, "disposeTo": "", "timeStart": "", "vehicleNo": "X1234Y", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["General Waste"], "sigPosition": ""}, {"id": 21, "tDO": 0, "_pay": 18, "date": "2026-07-20", "doNo": 0, "tEnd": 1784506951000, "_addr": "5 Sungei Kadut Street 6", "_type": "Dump", "binIn": "", "jobId": 32, "price": 18, "waste": "Wood Waste", "_sales": "", "_surch": "", "binOut": "", "doType": "land", "photos": [{"id": "1vju9VBTIMjv-VqYyv0DmoLe_KWPfoVT5", "ts": 1784506957000, "url": "https://drive.google.com/uc?export=view&id=1vju9VBTIMjv-VqYyv0DmoLe_KWPfoVT5", "kind": "bin", "thumb": "https://drive.google.com/thumbnail?id=1vju9VBTIMjv-VqYyv0DmoLe_KWPfoVT5&sz=w240"}, {"id": "1xYyxvfoFVRxF-drM1skSojB-f4f6JfUY", "ts": 1784506951000, "url": "https://drive.google.com/uc?export=view&id=1xYyxvfoFVRxF-drM1skSojB-f4f6JfUY", "kind": "bin", "thumb": "https://drive.google.com/thumbnail?id=1xYyxvfoFVRxF-drM1skSojB-f4f6JfUY&sz=w240"}], "tBinIn": 0, "vessel": null, "weight": {"net": 5170, "tare": 15640, "gross": 20810, "ticket": "LR12"}, "_charge": 18, "_client": "Beejoo", "_driver": "Yao Jun", "jobType": "Dump", "remarks": "", "sigName": "", "tAccept": 1784505051464, "tBinOut": 0, "tServer": 1784507031650, "tWeight": 0, "timeEnd": "08:22", "tonnAdj": 0, "tonnage": 0, "clientId": "cmrkt9187viy", "distance": 0, "driverId": 5, "invoiced": false, "disposeTo": "Bee Joo", "timeStart": "07:50", "vehicleNo": "", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": [], "sigPosition": ""}, {"id": 22, "tDO": 1784510392000, "_pay": 19.5, "date": "2026-07-20", "doNo": 0, "tEnd": 1784509583000, "_addr": "Benoi", "_type": "Exchange", "binIn": "6002", "jobId": 33, "price": 19.5, "waste": "General Waste", "_sales": "", "_surch": "", "binOut": "6002", "doType": "land", "photos": [{"id": "1p_VkTnz1WRtmY4rssV6Rq0TK9JBlYTFO", "ts": 1784509583000, "url": "https://drive.google.com/uc?export=view&id=1p_VkTnz1WRtmY4rssV6Rq0TK9JBlYTFO", "kind": "in", "thumb": "https://drive.google.com/thumbnail?id=1p_VkTnz1WRtmY4rssV6Rq0TK9JBlYTFO&sz=w240"}, {"id": "133wnotINTbCw8ooglK5xZmstd46QZxlp", "ts": 1784509583000, "url": "https://drive.google.com/uc?export=view&id=133wnotINTbCw8ooglK5xZmstd46QZxlp", "kind": "out", "thumb": "https://drive.google.com/thumbnail?id=133wnotINTbCw8ooglK5xZmstd46QZxlp&sz=w240"}, {"id": "1I3c4p7BgTju6vffkDPM7x6s1uBJ26gCw", "ts": 1784510392000, "url": "https://drive.google.com/uc?export=view&id=1I3c4p7BgTju6vffkDPM7x6s1uBJ26gCw", "kind": "do", "thumb": "https://drive.google.com/thumbnail?id=1I3c4p7BgTju6vffkDPM7x6s1uBJ26gCw&sz=w240"}], "tBinIn": 1784509583000, "vessel": null, "weight": {"net": 4430, "tare": 14100, "gross": 18530, "ticket": "LR13"}, "_charge": 19.5, "_client": "ST", "_driver": "Yao Jun", "jobType": "Exchange", "remarks": "", "sigName": "", "tAccept": 1784510460438, "tBinOut": 1784509583000, "tServer": 1784510504417, "tWeight": 0, "timeEnd": "09:06", "tonnAdj": 0, "tonnage": 0, "clientId": "cmrkt918dn4k", "distance": 2.3, "driverId": 5, "invoiced": false, "disposeTo": "Lirich Resources Pte Ltd", "timeStart": "09:06", "vehicleNo": "XE7126P", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["General Waste"], "sigPosition": ""}, {"id": 23, "tDO": 1784920014000, "_pay": 13, "date": "2026-07-25", "doNo": 0, "tEnd": 1784920014000, "_addr": "9 Gul Circle", "_test": true, "_type": "Exchange", "binIn": "", "jobId": 43, "price": 13, "waste": "General Waste", "_sales": "Patrick", "_surch": "", "binOut": "", "doType": "land", "photos": [{"id": "mrzbayza-BININ-43-1.jpg", "ts": 1784920014000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/mrzbayza-BININ-43-1.jpg", "kind": "in", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/mrzbayza-BININ-43-1.jpg"}, {"id": "mrzbaz6l-BINOUT-43-1.jpg", "ts": 1784920014000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/mrzbaz6l-BINOUT-43-1.jpg", "kind": "out", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/mrzbaz6l-BINOUT-43-1.jpg"}, {"id": "mrzbazaa-DO-43-1.jpg", "ts": 1784920014000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/mrzbazaa-DO-43-1.jpg", "kind": "do", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/mrzbazaa-DO-43-1.jpg"}], "tBinIn": 1784920014000, "vessel": null, "weight": null, "_charge": 13, "_client": "Eng Lee Logistics Pte Ltd", "_driver": "Test Driver", "jobType": "Exchange", "remarks": "", "sigName": "", "tAccept": 1784919884770, "tBinOut": 1784920014000, "tServer": 1784920037014, "tWeight": 0, "timeEnd": "03:06", "tonnAdj": 0, "tonnage": 0, "clientId": "c1", "distance": 0, "driverId": 6, "invoiced": false, "disposeTo": "", "timeStart": "03:06", "vehicleNo": "X1234Y", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["General Waste"], "sigPosition": ""}, {"id": 24, "tDO": 1784920014000, "_pay": 13, "date": "2026-07-25", "doNo": 99999, "tEnd": 0, "_addr": "9 Gul Circle", "_type": "Exchange", "binIn": "", "jobId": 44, "price": 13, "waste": "General Waste", "_sales": "Patrick", "_surch": "", "binOut": "", "doType": "land", "photos": [{"id": "mrzcgqcw-DO-44-1.jpg", "ts": 1784920014000, "url": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/mrzcgqcw-DO-44-1.jpg", "kind": "do", "thumb": "https://zjtvrlbyfeirnrlqgefo.supabase.co/storage/v1/object/public/do-photos/mrzcgqcw-DO-44-1.jpg"}], "tBinIn": 0, "vessel": null, "weight": {"net": 100, "tare": 900, "gross": 1000, "ticket": "LR14"}, "_charge": 13, "_client": "Eng Lee Logistics Pte Ltd", "_driver": "Sathish", "jobType": "Exchange", "remarks": "", "sigName": "", "tAccept": 1784921751375, "tBinOut": 0, "tServer": 1784921985392, "tWeight": 0, "timeEnd": "", "tonnAdj": 0, "tonnage": 0, "clientId": "c1", "distance": 0, "driverId": 1, "invoiced": false, "disposeTo": "", "timeStart": "", "vehicleNo": "2234", "weightAdj": 0, "surcharges": [], "wasteOther": "", "wasteTypes": ["General Waste"], "sigPosition": ""}], "clients": [{"id": "c1", "name": "Eng Lee Logistics Pte Ltd", "type": "land", "sites": [{"addr": "9 Gul Circle", "label": "Gul Circle yard", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "15 Tuas Ave 8", "label": "Tuas yard"}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [{"name": "Jacky", "phone": "84118884"}, {"name": "Mei Ling", "phone": "91234567"}], "salesRep": "Patrick"}, {"id": "c2", "name": "Radha Exports Pte Ltd", "type": "land", "sites": [{"addr": "118 Pioneer Rd L1", "label": "Pioneer Rd"}, {"addr": "118 Pioneer Road L1", "label": "Yard 2", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "118 Pioneer Road L4", "label": "Yard 3", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "118 Pioneer Road L7", "label": "Yard 4", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "6 Fishery Port, L5M", "label": "Yard 5", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [{"name": "Radha", "phone": ""}], "salesRep": "Marcus"}, {"id": "c3", "name": "Aspiration City", "type": "land", "sites": [{"addr": "Boon Lay Ave", "label": "Main"}], "contacts": [], "salesRep": "Patrick"}, {"id": "c4", "name": "SLG Construction", "type": "land", "sites": [{"addr": "Tuas South Ave 10", "label": "Main"}], "contacts": [], "salesRep": "Patrick"}, {"id": "c5", "name": "Tian Heng Eng", "type": "land", "sites": [{"addr": "Tractor Rd", "label": "Main"}], "contacts": [], "salesRep": "Marcus"}, {"id": "c6", "name": "Pacific International Lines", "type": "vessel", "sites": [{"addr": "PSA, BT Gate 2 Commercial Lane", "label": "PSA"}, {"addr": "PSA berths - vessel operations", "label": "Yard 2", "prices": {}}], "contacts": [{"name": "Ops Desk", "phone": ""}], "salesRep": "Marcus"}, {"id": "cmrkt918745o", "name": "123 Express", "type": "land", "sites": [{"addr": "60 Kaki Bukit Place, #06-14 Eunos Techpark", "label": "Yard 1", "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}}], "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}, "contacts": [], "salesRep": ""}, {"id": "cmrkt91876ld", "name": "Absolut Properties Pte Ltd", "type": "land", "sites": [{"addr": "163 Marine Parade Road, Marine Meadows Condo", "label": "Yard 1", "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "173 Jalan Loyang Besar, Ocean Front Suites Condo", "label": "Yard 2", "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}}], "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}, "contacts": [], "salesRep": ""}, {"id": "cmrkt9187gpn", "name": "Acreation Group Pte Ltd", "type": "land", "sites": [{"addr": "19 Jalan Mesin", "label": "Yard 1", "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "9 Raffles Boulevard", "label": "Yard 2", "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "Engku Aman Road", "label": "Yard 3", "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "Orchard Gateway, 277 Orchard Road", "label": "Yard 4", "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}}], "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}, "contacts": [], "salesRep": ""}, {"id": "cmrkt9187x1k", "name": "Advanced Substrate Technologies Pte Ltd", "type": "land", "sites": [{"addr": "47A Jalan Buroh", "label": "Yard 1", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt9187dcx", "name": "AJK", "type": "land", "sites": [{"addr": "24 Tuas Ave 8", "label": "Yard 1", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt9187ip5", "name": "Allalloy Dynaweld Pte Ltd", "type": "land", "sites": [{"addr": "10 Tuas Link 1", "label": "Yard 1", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt91872y0", "name": "Allied Container Services Pte Ltd", "type": "land", "sites": [{"addr": "10 Tuas Ave 6", "label": "Yard 1", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "15 Pioneer Crescent", "label": "Yard 2", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "25 Penjuru Lane Yard 3", "label": "Yard 3", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt9187co1", "name": "Apex Sealing Technologies Pte Ltd", "type": "land", "sites": [{"addr": "19 Tuas South Street 5", "label": "Yard 1", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "Tuas Basin Lane", "label": "Yard 2", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt91871qf", "name": "Archibiz", "type": "land", "sites": [{"addr": "Blk A 30 Kranji Loop, #06-05 Timmac @ Kranji", "label": "Yard 1", "prices": {"Collect": 18, "Delivery": 8, "Exchange": 18}}], "prices": {"Collect": 18, "Delivery": 8, "Exchange": 18}, "contacts": [], "salesRep": ""}, {"id": "cmrkt9187obq", "name": "Artdecor Design Studio Pte Ltd", "type": "land", "sites": [{"addr": "2 Defu South Street 1, #05-03, JTC Industrial City", "label": "Yard 1", "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}}], "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}, "contacts": [], "salesRep": ""}, {"id": "cmrkt9187ws7", "name": "ASL Proworld Solution Pte Ltd", "type": "land", "sites": [{"addr": "8 Pandan Crescent", "label": "Yard 1", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt9187n05", "name": "Astore Pte Ltd", "type": "land", "sites": [{"addr": "43 Keppel Road", "label": "Yard 1", "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}}], "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}, "contacts": [], "salesRep": ""}, {"id": "cmrkt9187zx3", "name": "Aver Asia (S) Pte Ltd", "type": "land", "sites": [{"addr": "14 Benoi Place", "label": "Yard 1", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt91878od", "name": "B&C Waste", "type": "land", "sites": [{"addr": "16 Gul Crescent", "label": "Yard 1", "prices": {"Load": 21, "Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "513 Kampong Bahru Road Keppel Distripark", "label": "Yard 2", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "Upper Changi Road, Summer Garden Condo", "label": "Yard 3", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "2 Mandai Link", "label": "Yard 4", "prices": {"Load": 26, "Collect": 18, "Delivery": 8, "Exchange": 18}}, {"addr": "Peck Seah Street", "label": "Yard 5", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "7 Changi South Street 2", "label": "Yard 6", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "26 Loyang Drive", "label": "Yard 7", "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}}], "prices": {"Load": 31, "Collect": 23, "Delivery": 8, "Exchange": 23}, "contacts": [], "salesRep": ""}, {"id": "cmrkt9187pck", "name": "Babu", "type": "land", "sites": [{"addr": "80 Mandai Lake Road", "label": "Yard 1", "prices": {"Collect": 18, "Delivery": 8, "Exchange": 18}}, {"addr": "Blk 5 Haig Road #07-463", "label": "Yard 2", "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "900 Bedok North Road", "label": "Yard 3", "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "2 Stadium Walk", "label": "Yard 4", "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}}], "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}, "contacts": [], "salesRep": ""}, {"id": "cmrkt9187viy", "name": "Beejoo", "type": "land", "sites": [{"addr": "5 Sungei Kadut Street 6", "label": "Yard 1", "prices": {"Dump": 18}}], "prices": {"Dump": 18}, "contacts": [], "salesRep": ""}, {"id": "cmrkt9187nen", "name": "BNDC (Fairprice)", "type": "land", "sites": [{"addr": "1 Buroh Lane L4", "label": "Yard 1", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "28 Tuas Ave 13", "label": "Yard 2", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "5 Joo Koon Circle", "label": "Yard 3", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "7 Sunview Road", "label": "Yard 4", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt9188ra9", "name": "C & P Holdings Pte Ltd", "type": "land", "sites": [{"addr": "46 Penjuru Lane", "label": "Yard 1", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt91889mm", "name": "Calvary Carpentry Pte Ltd", "type": "land", "sites": [{"addr": "54 Senoko Road", "label": "Yard 1", "prices": {"Collect": 18, "Delivery": 8, "Exchange": 18}}], "prices": {"Collect": 18, "Delivery": 8, "Exchange": 18}, "contacts": [], "salesRep": ""}, {"id": "cmrkt9188tnl", "name": "Cargo International", "type": "land", "sites": [{"addr": "20 Gul Way, #05-04", "label": "Yard 1", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt91889d7", "name": "Caterpillar", "type": "land", "sites": [{"addr": "14 Tractor Road", "label": "Yard 1", "prices": {"Collect": 18, "Delivery": 8, "Exchange": 18}}, {"addr": "7 Tractor Road", "label": "Yard 2", "prices": {"Collect": 18, "Delivery": 8, "Exchange": 18}}], "prices": {"Collect": 18, "Delivery": 8, "Exchange": 18}, "contacts": [], "salesRep": ""}, {"id": "cmrkt9188fou", "name": "CBM Pte Ltd", "type": "land", "sites": [{"addr": "501 Old Choa Chu Kang Road, Home Team Academy", "label": "Yard 1", "prices": {"Collect": 18, "Delivery": 8, "Exchange": 18}}], "prices": {"Collect": 18, "Delivery": 8, "Exchange": 18}, "contacts": [], "salesRep": ""}, {"id": "cmrkt91889z2", "name": "Chateraise", "type": "land", "sites": [{"addr": "8 Jalan Besut L3", "label": "Yard 1", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt9188wm8", "name": "Chiong Construction", "type": "land", "sites": [{"addr": "10 Serangoon Ave 4", "label": "Yard 1", "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "13 Serangoon Ave 3", "label": "Yard 2", "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "60 Blk A Jurong West Street 42", "label": "Yard 3", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt9188jxn", "name": "Chuan Seng Leong", "type": "land", "sites": [{"addr": "21 Benoi Sector #03-03", "label": "Yard 1", "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}}], "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}, "contacts": [], "salesRep": ""}, {"id": "cmrkt91886cl", "name": "Cleanis-Tee", "type": "land", "sites": [{"addr": "8 Jalan Papan", "label": "Yard 1", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt9188smd", "name": "CNCCS Engineering and Construction Pte Ltd", "type": "land", "sites": [{"addr": "15 Tembusu Crescent, #08-01, COGENT.", "label": "Yard 1", "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}}], "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}, "contacts": [], "salesRep": ""}, {"id": "cmrkt9188btv", "name": "CrestSA Marine & Offshore Pte Ltd", "type": "land", "sites": [{"addr": "15 Pandan Road", "label": "Yard 1", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt9188ahz", "name": "DSV", "type": "land", "sites": [{"addr": "24 Penjuru Road, #09-05/06 (Loading Bay 2)", "label": "Yard 1", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt91880wf", "name": "Dyna Cool", "type": "land", "sites": [{"addr": "2 Bukit Batok Street 24, #03-19 Skytech", "label": "Yard 1", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt91888e3", "name": "Eng Leng Contractors Pte Ltd", "type": "land", "sites": [{"addr": "1 CleanTech Loop", "label": "Yard 1", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "1 Gul Circle, JTC Logistics Hub", "label": "Yard 2", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "16 Tuas Ave 1, JTC Space @ Tuas", "label": "Yard 3", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "2 Tukang Innovation Grove", "label": "Yard 4", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "28A Penjuru Close Bin Centre", "label": "Yard 5", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "8 Buroh Street", "label": "Yard 6", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "8 Jurong Town Hall Rd, JTC Summit Building", "label": "Yard 7", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "Jalan Papan LP 15", "label": "Yard 8", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "Pandan Loop, Blk K, (Phase 1), Bin Centre", "label": "Yard 9", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "Pandan Loop, Blk X, (Phase 3), Bin Centre", "label": "Yard 10", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "15 Jalan Terusan", "label": "Yard 11", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918885s", "name": "Engie Services Singapore Pte Ltd", "type": "land", "sites": [{"addr": "1 Canning Rise Singapore 179868", "label": "Yard 1", "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "1 Empress Place", "label": "Yard 2", "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "1 Jurong East st 21, Ng Teng Fong Hospital", "label": "Yard 3", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "100 Victoria Street, Basement 2, Loading Bay", "label": "Yard 4", "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "17 Woodlands Drive 17, Woodlands Health Campus", "label": "Yard 5", "prices": {"Collect": 18, "Delivery": 8, "Exchange": 18}}, {"addr": "2 Simei Street 3, Changi General Hospital", "label": "Yard 6", "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "20 Airport Boulevard Changi Airport", "label": "Yard 7", "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "28 Irrawaddy Road, New Phoenix Park. (Ministry of Home Affairs)", "label": "Yard 8", "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "32 Jurong Port Road, Heritage Center", "label": "Yard 9", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "4A Tuas Bay Street", "label": "Yard 10", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "65 Airport Boulevard, #B2-63, Changi Airport T3", "label": "Yard 11", "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "9 Kallang Place", "label": "Yard 12", "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "93 Stamford Road, National Museum of Singapore", "label": "Yard 13", "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "Changi Airport T2 Basement", "label": "Yard 14", "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "2 Tuas Bay Street", "label": "Yard 15", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "1 Cove Grove", "label": "Yard 16", "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "1 Media Link", "label": "Yard 17", "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "30 Changi North Cresent", "label": "Yard 18", "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}}], "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}, "contacts": [], "salesRep": ""}, {"id": "cmrkt9189ewq", "name": "Epont Building Services Pte Ltd", "type": "land", "sites": [{"addr": "1 Tuas View Place, Westlink One, #02-01", "label": "Yard 1", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt91893rb", "name": "Euro Pac Logistics Pte Ltd", "type": "land", "sites": [{"addr": "42 Tanjong Penjuru Road", "label": "Yard 1", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "52 Tanjong Penjuru #04-92", "label": "Yard 2", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt9189j9t", "name": "EverTeam Pte Ltd", "type": "land", "sites": [{"addr": "60 Benoi Road", "label": "Yard 1", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt9189chy", "name": "Faxolif Industries Pte Ltd", "type": "land", "sites": [{"addr": "75 Tech Park Crescent", "label": "Yard 1", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt91891r8", "name": "Geoinnovations Pte Ltd", "type": "land", "sites": [{"addr": "5 Kwong Ming Road", "label": "Yard 1", "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}}], "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}, "contacts": [], "salesRep": ""}, {"id": "cmrkt9189hjd", "name": "GS Engineering and Construction Corporation", "type": "land", "sites": [{"addr": "Nicoll Highway LP 120F", "label": "Yard 1", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "Nicoll Highway LP 131F", "label": "Yard 2", "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "Nicoll Highway, LP 132F", "label": "Yard 3", "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "Ophir Road LP 14/1F", "label": "Yard 4", "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "Ophir Road, LP 30F", "label": "Yard 5", "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "Republic Boulevard LP 4F", "label": "Yard 6", "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "Victoria Street, LP 64F", "label": "Yard 7", "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}}], "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}, "contacts": [], "salesRep": ""}, {"id": "cmrkt9189rdg", "name": "GWC", "type": "land", "sites": [{"addr": "449 Clementi Ave 3, #01-259", "label": "Yard 1", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt9189clz", "name": "Gymsportz", "type": "land", "sites": [{"addr": "7, Block B Mandai Link, #05-27 Mandai Connection", "label": "Yard 1", "prices": {"Collect": 18, "Delivery": 8, "Exchange": 18}}], "prices": {"Collect": 18, "Delivery": 8, "Exchange": 18}, "contacts": [], "salesRep": ""}, {"id": "cmrkt9189uq4", "name": "H1 Projects Pte Ltd", "type": "land", "sites": [{"addr": "107 Jalan Pari Burong", "label": "Yard 1", "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}}], "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}, "contacts": [], "salesRep": ""}, {"id": "cmrkt9189g55", "name": "Haid Biotechnology Industry (Singapore) Pte Ltd", "type": "land", "sites": [{"addr": "46 Gul Drive", "label": "Yard 1", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt9189v5w", "name": "HCG", "type": "land", "sites": [{"addr": "8 Tuas View Circuit", "label": "Yard 1", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "79 Anson Road", "label": "Yard 2", "prices": {"Collect": 18, "Delivery": 8, "Exchange": 18}}], "prices": {"Collect": 18, "Delivery": 8, "Exchange": 18}, "contacts": [], "salesRep": ""}, {"id": "cmrkt9189qwx", "name": "He Ping Development Pte Ltd", "type": "land", "sites": [{"addr": "32 Tras Street", "label": "Yard 1", "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "38 Beach Road, South Beach Tower", "label": "Yard 2", "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "51 Tanjong Pagar Road", "label": "Yard 3", "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}}], "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}, "contacts": [], "salesRep": ""}, {"id": "cmrkt9189tvd", "name": "Hong Hang Hardware", "type": "land", "sites": [{"addr": "35 Pioneer Road", "label": "Yard 1", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt9189mv1", "name": "Hotel Royal Singapore", "type": "land", "sites": [{"addr": "36 Newton Road", "label": "Yard 1", "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}}], "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}, "contacts": [], "salesRep": ""}, {"id": "cmrkt91895ny", "name": "Huationg Contractor", "type": "land", "sites": [{"addr": "Tanah Merah Coast Road LP 509", "label": "Yard 1", "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}}], "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}, "contacts": [], "salesRep": ""}, {"id": "cmrkt9189zdz", "name": "Huntsman (S) Pte Ltd", "type": "land", "sites": [{"addr": "10 Seraya Ave", "label": "Yard 1", "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}}], "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}, "contacts": [], "salesRep": ""}, {"id": "cmrkt9189166", "name": "Hydroproof", "type": "land", "sites": [{"addr": "The Aries, 51 Science Park", "label": "Yard 1", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918azpz", "name": "Hyundai Engineering & Construction Co., Ltd", "type": "land", "sites": [{"addr": "100 Beach Road", "label": "Yard 1", "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}}], "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918as3h", "name": "INVX Asia Pacific Pte Ltd", "type": "land", "sites": [{"addr": "80 Tuas West Drive", "label": "Yard 1", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918ap5c", "name": "Iwatech", "type": "land", "sites": [{"addr": "2 Kian Teck Drive", "label": "Yard 1", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918avdw", "name": "Lau Choy Seng Pte Ltd", "type": "land", "sites": [{"addr": "30 Tuas West Avenue", "label": "Yard 1", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918a2es", "name": "LCH Logistics Pte Ltd", "type": "land", "sites": [{"addr": "3 Pioneer Sector 3", "label": "Yard 1", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918ao9s", "name": "Leng Aik Engineering", "type": "land", "sites": [{"addr": "17 Soon Lee Road", "label": "Yard 1", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918auof", "name": "LexBuild International Pte Ltd", "type": "land", "sites": [{"addr": "11 Tuas Bay Close, #04-01/02", "label": "Yard 1", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918ar8i", "name": "Lirich", "type": "land", "sites": [{"addr": "Carton", "label": "Yard 1", "prices": {"Sell": 13, "Delivery": 8}}, {"addr": "Metal", "label": "Yard 2", "prices": {"Sell": 13, "Delivery": 8}}, {"addr": "Plastics", "label": "Yard 3", "prices": {"Sell": 13, "Delivery": 8}}, {"addr": "Wood Waste", "label": "Yard 4"}, {"addr": "Rubbish", "label": "Yard 5"}, {"addr": "Beejoo", "label": "Yard 6", "prices": {"Dump": 18}}, {"addr": "NEA Tuas", "label": "Yard 7", "prices": {"Dump": 13}}], "prices": {"Dump": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918abew", "name": "Lim Siang Huat Pte Ltd", "type": "land", "sites": [{"addr": "6 Fishery Port Road L3", "label": "Yard 1", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918a2xv", "name": "Matrix Cooling (Singapore) Pte Ltd", "type": "land", "sites": [{"addr": "10 Buroh Street, #07-01, Westconnect Building", "label": "Yard 1", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918aw4z", "name": "Mecom GreenBuild (Singapore) Pte Ltd", "type": "land", "sites": [{"addr": "23 Jurong Port Road", "label": "Yard 1", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918ate4", "name": "NEA", "type": "land", "sites": [{"addr": "NEA Tuas", "label": "Yard 1", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918askd", "name": "PaxOcean Singapore Pte Ltd", "type": "land", "sites": [{"addr": "5 Jalan Samulun", "label": "Yard 1", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918ag06", "name": "Poh Tiong Choon Logistics Ltd", "type": "land", "sites": [{"addr": "21 Ayer Merbau, Jurong Island", "label": "Yard 1", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "48 Pandan Road L1", "label": "Yard 2", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "48 Pandan Road L3", "label": "Yard 3", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "48 Pandan Road L6", "label": "Yard 4", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918auyz", "name": "PSA Port Ecosystem (Sea) Pte Ltd", "type": "land", "sites": [{"addr": "24 Penjuru Road. #05-06", "label": "Yard 1", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918a8k1", "name": "Qualicoat Pte Ltd", "type": "land", "sites": [{"addr": "5 Gul Drive", "label": "Yard 1", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918aitb", "name": "REMEX Minerals Singapore Pte Ltd", "type": "land", "sites": [{"addr": "98 Tuas South Ave 3 (Inside NEA building)", "label": "Yard 1", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918apvn", "name": "RJ Hydralics", "type": "land", "sites": [{"addr": "83 Tagore Lane", "label": "Yard 1", "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}}], "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918auhe", "name": "Savills Property Management Pte Ltd (Blue Hub)", "type": "land", "sites": [{"addr": "10 Sunview Road L109", "label": "Yard 1", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "10 Sunview Road L309", "label": "Yard 2", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "10 Sunview Road L407", "label": "Yard 3", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "10 Sunview Road L609", "label": "Yard 4", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918aco2", "name": "Savills Property Management Pte Ltd (Green Hub)", "type": "land", "sites": [{"addr": "11 Pioneer Turn L2", "label": "Yard 1", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "11 Pioneer Turn L401", "label": "Yard 2", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "11 Pioneer Turn L407", "label": "Yard 3", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "11 Pioneer Turn L601", "label": "Yard 4", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "11 Pioneer Turn L8", "label": "Yard 5", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918du9v", "name": "Seatrium Pte Ltd", "type": "land", "sites": [{"addr": "60 Admiralty Road West", "label": "Yard 1", "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}}], "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918dq77", "name": "Shin Ya O Ya Pte Ltd", "type": "land", "sites": [{"addr": "6 Chin Bee Ave L5", "label": "Yard 1", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "6 Chin Bee Ave L9", "label": "Yard 2", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918dmr4", "name": "Siew Kong Glass Makers Pte Ltd", "type": "land", "sites": [{"addr": "43 Joo Koon Circle", "label": "Yard 1", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918d2ww", "name": "Sin Hong Hardware Pte Ltd", "type": "land", "sites": [{"addr": "3 Kian Teck Crescent", "label": "Yard 1", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918devh", "name": "Sin Hong Poh Metal Trading", "type": "land", "sites": [{"addr": "59 Tampines Industrial Ave", "label": "Yard 1", "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}}], "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918dvh6", "name": "Sindac Cleaning Services Pte Ltd", "type": "land", "sites": [{"addr": "1H Pine Grove, Pine Grove Condo", "label": "Yard 1", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "20 Woodlands Crescent, Northoaks Condo", "label": "Yard 2", "prices": {"Collect": 18, "Delivery": 8, "Exchange": 18}}], "prices": {"Collect": 18, "Delivery": 8, "Exchange": 18}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918diax", "name": "SLS", "type": "land", "sites": [{"addr": "No. 9 Tuas South Avenue 19, #01-99", "label": "Yard 1", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "VSMC site office Gate 3", "label": "Yard 2", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918dpo7", "name": "Snip Avenue Holdings", "type": "land", "sites": [{"addr": "9 Changi South Street 3, loading bay", "label": "Yard 1", "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}}], "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918dhx4", "name": "Springlife Maintenance Service Pte Ltd", "type": "land", "sites": [{"addr": "21 Ang Mo Kio Ave 9, Nuovo Condo", "label": "Yard 1", "prices": {"Collect": 18, "Delivery": 8, "Exchange": 18}}, {"addr": "464 Corporation Road, Parc Vista Condo", "label": "Yard 2", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "88 Flora Road, Edelweiss Park Condo", "label": "Yard 3", "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}}], "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918dn4k", "name": "ST", "type": "land", "sites": [{"addr": "6 Tuas South Street 15", "label": "Yard 1", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "Benoi", "label": "Yard 2", "prices": {"Collect": 19.5, "Delivery": 8, "Exchange": 19.5}}, {"addr": "Gul", "label": "Yard 3", "prices": {"Collect": 19.5, "Delivery": 8, "Exchange": 19.5}}, {"addr": "61a Tuas Nexus Drive", "label": "Yard 4", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918e1wj", "name": "Stamford Tyres", "type": "land", "sites": [{"addr": "19 Lok Yang Way", "label": "Yard 1", "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}}], "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918el54", "name": "STSM", "type": "land", "sites": [{"addr": "15 Pasir Ris Street 21", "label": "Yard 1", "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "47 Hougang Avenue 1", "label": "Yard 2", "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "Blk 15 Toa Payoh Lorong 7", "label": "Yard 3", "prices": {"Collect": 18, "Delivery": 8, "Exchange": 18}}, {"addr": "Blk 61 Jurong West Street 65, Jurong West Secondary School (JWSS)", "label": "Yard 4", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "Blk 64 Lorong 5 Toa Payoh - Lot no. 24", "label": "Yard 5", "prices": {"Collect": 18, "Delivery": 8, "Exchange": 18}}, {"addr": "Blk 698 West Coast Road, Commonwealth Secondary School (CWSS)", "label": "Yard 6", "prices": {"Collect": 18, "Delivery": 8, "Exchange": 18}}], "prices": {"Collect": 18, "Delivery": 8, "Exchange": 18}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918ehaz", "name": "Sumber Indah Pte Ltd", "type": "land", "sites": [{"addr": "1 Tuas View Close", "label": "Yard 1", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918em7e", "name": "Sun City Maintenance Pte Ltd", "type": "land", "sites": [{"addr": "300 Mandai Road, Mandai Crematorium and Columbarium", "label": "Yard 1", "prices": {"Collect": 18, "Delivery": 8, "Exchange": 18}}, {"addr": "55 Changi South Ave 1", "label": "Yard 2", "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "SUTD Building 2, 8 Somapah Road, loading bay", "label": "Yard 3", "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "SUTD Building 3, 8 somapah Road , with access via the Changi Street carpark entrance", "label": "Yard 4", "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "Yishun Columbarium, 569 Yishun Ring Road", "label": "Yard 5", "prices": {"Collect": 18, "Delivery": 8, "Exchange": 18}}], "prices": {"Collect": 18, "Delivery": 8, "Exchange": 18}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918eg0z", "name": "Sys-Mac Automation Engineering Pte Ltd", "type": "land", "sites": [{"addr": "2 Woodlands Sector 1, #05-18", "label": "Yard 1", "prices": {"Collect": 18, "Delivery": 8, "Exchange": 18}}], "prices": {"Collect": 18, "Delivery": 8, "Exchange": 18}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918efxl", "name": "System Foundation Pte Ltd", "type": "land", "sites": [{"addr": "21A Tuas South Place", "label": "Yard 1", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "45 Tuas View Place", "label": "Yard 2", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918ejrl", "name": "T3 Reources Pte Ltd", "type": "land", "sites": [{"addr": "16 Gul Street 3", "label": "Yard 1", "prices": {"Sell": 13}}], "prices": {"Sell": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918enlk", "name": "Tai Lee Tong", "type": "land", "sites": [{"addr": "No 11, Lorong 21A Geylang", "label": "Yard 1", "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}}], "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918e77h", "name": "Technigroup Far East Pte Ltd", "type": "land", "sites": [{"addr": "Outram Road", "label": "Yard 1", "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}}], "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918evff", "name": "Technicair Singapore Services Pte Ltd", "type": "land", "sites": [{"addr": "16 Jalan Tan Tock Seng", "label": "Yard 1", "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}}], "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918e0xf", "name": "Teck Sang Pte Ltd", "type": "land", "sites": [{"addr": "30A Quality Road", "label": "Yard 1", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918eczv", "name": "Toh Ban Seng", "type": "land", "sites": [{"addr": "Seletar Westlink LP 103", "label": "Yard 1", "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}}], "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918een0", "name": "Tong Carriage (S) Pte Ltd", "type": "land", "sites": [{"addr": "30 Toh Guan Road", "label": "Yard 1", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918ebot", "name": "Tong Hock Pte Ltd", "type": "land", "sites": [{"addr": "10 Pandan Crescent", "label": "Yard 1", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "1206A East Coast Park", "label": "Yard 2", "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "14 Tractor Road", "label": "Yard 3", "prices": {"Collect": 18, "Delivery": 8, "Exchange": 18}}, {"addr": "19 Tuas Street", "label": "Yard 4", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "2 Peach Garden, Peach Garden condo", "label": "Yard 5", "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "2 Pioneer Sector 1", "label": "Yard 6", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "58 Woodlands Drive 16, La Casa Condo", "label": "Yard 7", "prices": {"Collect": 18, "Delivery": 8, "Exchange": 18}}, {"addr": "7 Tractor Road", "label": "Yard 8", "prices": {"Collect": 18, "Delivery": 8, "Exchange": 18}}, {"addr": "1 Woodlands Terrace", "label": "Yard 9", "prices": {"Collect": 18, "Delivery": 8, "Exchange": 18}}], "prices": {"Collect": 18, "Delivery": 8, "Exchange": 18}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918fl15", "name": "Top Star Builder Pte Ltd", "type": "land", "sites": [{"addr": "50 Playfair road", "label": "Yard 1", "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}}], "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918fjc5", "name": "TSTL", "type": "land", "sites": [{"addr": "19 Tuas Street", "label": "Yard 1", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918fzog", "name": "Tracebuild", "type": "land", "sites": [{"addr": "1 Woodlands Street 31, Fu Chun Community Club", "label": "Yard 1", "prices": {"Collect": 18, "Delivery": 8, "Exchange": 18}}], "prices": {"Collect": 18, "Delivery": 8, "Exchange": 18}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918f6wq", "name": "Urban Group Pte Ltd", "type": "land", "sites": [{"addr": "200 Netheravon Road", "label": "Yard 1", "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}}], "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918frwu", "name": "Wah & Hua Pte Ltd", "type": "land", "sites": [{"addr": "17 Kallang Junction, #01-01, Singapore 339274", "label": "Yard 1", "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "19 Loyang Way", "label": "Yard 2", "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "22 Woodlands Link", "label": "Yard 3", "prices": {"Collect": 18, "Delivery": 8, "Exchange": 18}}, {"addr": "221 Kallang Bahru Lion Building", "label": "Yard 4", "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "30 Kerong Lane", "label": "Yard 5", "prices": {"Collect": 18, "Delivery": 8, "Exchange": 18}}, {"addr": "76 Sungei Tengah Road", "label": "Yard 6", "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "980 Upper Changi Road North Singapore 507708(Prison HQ)", "label": "Yard 7", "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}}], "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918fkeq", "name": "WeBuild", "type": "land", "sites": [{"addr": "120 Hillview Ave", "label": "Yard 1", "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}}], "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918fsbo", "name": "WIKA Instrumentation Pte Ltd", "type": "land", "sites": [{"addr": "13 Kian Teck Crescent", "label": "Yard 1", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918f38h", "name": "Wilkie Development Pte Ltd", "type": "land", "sites": [{"addr": "12 New Industrial Road", "label": "Yard 1", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918fz34", "name": "World of Wood Pte Ltd", "type": "land", "sites": [{"addr": "35 Tannery Road, #01-07, Ruby Industrial Complex", "label": "Yard 1", "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}}], "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}, "contacts": [], "salesRep": ""}, {"id": "cmrkt918fh09", "name": "W'Ray Construction Pte Ltd", "type": "land", "sites": [{"addr": "22 Scotts Road, Goodwood Park Hotel", "label": "Yard 1", "prices": {"Collect": 23, "Delivery": 8, "Exchange": 23}}, {"addr": "25 Tuas Ave 4", "label": "Yard 2", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}, {"addr": "1 Cove Grove", "label": "Yard 3"}, {"addr": "1 Media Link", "label": "Yard 4"}, {"addr": "30 Changi North Cresent", "label": "Yard 5"}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}, {"id": "cmrmwaycfytt", "name": "Glory SIP Pte Ltd", "type": "land", "sites": [{"addr": "50 Tuas Avenue 11, 02-05", "label": "Yard 1", "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}}], "prices": {"Collect": 13, "Delivery": 8, "Exchange": 13}, "contacts": [], "salesRep": ""}]}	9	2026-07-24 19:40:01.305+00
\.


--
-- Data for Name: approved_domains; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.approved_domains (domain, client_id, account_limit, accounts_used, added_by, added_at) FROM stdin;
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
7006	7 ft	\N	\N	Lirich	\N	t
7016	7 ft	\N	\N	Lirich	\N	t
7017	7 ft	\N	\N	Lirich	\N	t
7022	7 ft	\N	\N	Lirich	\N	t
8007	7 ft	\N	\N	Lirich	\N	t
\.


--
-- Data for Name: collections; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.collections (do_no, source, job_no, do_date, do_type, trip_type, site_id, vessel_name, berth, vehicle_id, driver_id, job_type, waste_type, bin_in, bin_out, vol_cat_a, vol_cat_b, vol_cat_c, vol_cat_d, vol_cat_e, vol_cat_f, vol_total_m3, gross_kg, tare_kg, net_kg, weigh_ticket_no, weigh_location, weight_source, gps_lat, gps_lng, gps_accuracy_m, gps_captured_at, photo_do_ref, photo_sig_ref, photo_weigh_ref, receipt_ref, disposal_facility, xero_invoice_id, backfill_notes, synced_at) FROM stdin;
24242	backfill	\N	2026-06-02	land	Exchange	SAV_001	\N	\N	XE4491D	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill from DO scan (Jun 2026) — DATE NOT LEGIBLE on DO — verify | DATE NOT LEGIBLE on DO — verify	2026-07-24 15:15:51.944859+00
24191	backfill	\N	2026-06-08	land	Exchange	SAV_001	\N	\N	\N	\N	\N	General Waste	5197	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill from DO scan (Jun 2026) — Bin In/Out handwriting unclear — verify | Bin In/Out handwriting unclear — verify	2026-07-24 15:15:51.944859+00
23636	backfill	\N	\N	land	Exchange	SAV_001	\N	\N	XE6221D	\N	\N	General Waste	\N	5240	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill from DO scan (Jun 2026) — Date 05 or 09 Jun — verify | Date 05 or 09 Jun — verify	2026-07-24 15:15:51.944859+00
18791	backfill	\N	2026-06-27	vessel	PSA Vessel	PIL_001	KOTA KARIM	B05	XE7126P	YAO_JUN	\N	Vessel Waste	\N	\N	0.90	0.00	0.70	0.04	0.01	2.00	3.65	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill | rechecked	2026-07-24 15:15:51.944859+00
18792	backfill	\N	2026-06-28	vessel	PSA Vessel	PIL_001	KOTA SURIA	B05	XE7126P	YAO_JUN	\N	Vessel Waste	\N	\N	0.80	0.02	0.40	0.01	0.00	\N	1.32	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill; FADED scan — Cat values (incl F) unclear, verify | rechecked	2026-07-24 15:15:51.944859+00
18917	backfill	\N	2026-04-04	vessel	PSA Vessel	PIL_001	KOTA KARIM	B06	XE6221D	SATHISH	\N	Vessel Waste	\N	\N	1.30	0.02	1.40	0.02	0.01	0.80	3.55	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill; Incl oily rags; DO marked ONLY FOR RECEIPT | rechecked	2026-07-24 15:15:51.944859+00
18931	backfill	\N	2026-05-01	vessel	PSA Vessel	PIL_001	KOTA SURIA	B06	XE6221D	SATHISH	\N	Vessel Waste	\N	\N	0.80	0.02	0.40	0.02	0.02	0.00	1.26	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill | rechecked	2026-07-24 15:15:51.944859+00
18932	backfill	\N	2026-05-02	vessel	PSA Vessel	PIL_001	KOTA NABIL	B05	XE6221D	SATHISH	\N	Vessel Waste	\N	\N	0.80	0.00	0.20	0.00	0.10	0.40	1.50	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill | rechecked	2026-07-24 15:15:51.944859+00
18933	backfill	\N	2026-05-07	vessel	PSA Vessel	PIL_001	KOTA RUKUN	B05	XE6221D	SATHISH	\N	Vessel Waste	\N	\N	1.30	0.00	0.80	0.00	0.00	0.50	2.60	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill | rechecked	2026-07-24 15:15:51.944859+00
18938	backfill	\N	2026-05-07	vessel	PSA Vessel	PIL_001	KOTA NAGA	P04	XE6221D	SATHISH	\N	Vessel Waste	\N	\N	0.40	0.03	0.70	0.00	0.00	0.30	1.43	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill | rechecked	2026-07-24 15:15:51.944859+00
18940	backfill	\N	2026-05-08	vessel	PSA Vessel	PIL_001	KOTA GAYA	B05	XE6221D	SATHISH	\N	Vessel Waste	\N	\N	0.70	0.00	0.70	0.01	0.00	0.59	2.00	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill; Incl 0.2 m3 oil rags | rechecked	2026-07-24 15:15:51.944859+00
18943	backfill	\N	2026-05-13	vessel	PSA Vessel	PIL_001	KOTA MANIS	B06	XE6221D	SATHISH	\N	Vessel Waste	\N	\N	0.60	0.02	0.40	0.00	0.00	0.28	1.30	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill | rechecked	2026-07-24 15:15:51.944859+00
18947	backfill	\N	2026-05-24	vessel	PSA Vessel	PIL_001	KOTA HAKIM	P08	XE6221D	SATHISH	\N	Vessel Waste	\N	\N	0.00	0.00	0.00	0.02	0.00	1.10	1.12	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill; Mostly oily rags | rechecked	2026-07-24 15:15:51.944859+00
18950	backfill	\N	2026-05-25	vessel	PSA Vessel	PIL_001	KOTA CANTIK	B05	XE6221D	SATHISH	\N	Vessel Waste	\N	\N	1.00	0.00	1.00	0.00	0.01	0.60	2.61	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill; Incl 0.1 m3 oily rags | rechecked	2026-07-24 15:15:51.944859+00
23947	backfill	\N	2026-06-30	land	Exchange	SAV_001	\N	\N	XE6221D	\N	\N	General Waste	5079	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	bin_out_raw=5032 | remarks=Backfill from DO scan (Jun 2026)	2026-07-24 15:15:51.944859+00
24066	backfill	\N	2026-06-30	land	Exchange	SAV_001	\N	\N	\N	\N	\N	General Waste	\N	5084	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill from DO scan (Jun 2026) — Bin In/Out unclear — verify | Bin In/Out unclear — verify	2026-07-24 15:15:51.944859+00
26931	backfill	\N	2026-05-02	land	Exchange	PAX_001	\N	\N	XE5457Y	\N	\N	General Waste	\N	5089	\N	\N	\N	\N	\N	\N	\N	14010.0	17630.0	3620.0	884	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by MORTHY-K009910	2026-07-24 15:15:51.944859+00
26932	backfill	\N	2026-05-02	land	Exchange	PAX_001	\N	\N	XE5457Y	\N	\N	General Waste	5089	5160	\N	\N	\N	\N	\N	\N	\N	14590.0	18910.0	4260.0	885	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by BALA-K009902	2026-07-24 15:15:51.944859+00
26934	backfill	\N	2026-05-02	land	Exchange	PAX_001	\N	\N	XE5457Y	\N	\N	General Waste	\N	5089	\N	\N	\N	\N	\N	\N	\N	14410.0	21080.0	6670.0	887	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by BALA-K009902; DO 26933 not in this batch (gap) | DO 26933 not in this batch (gap)	2026-07-24 15:15:51.944859+00
26935	backfill	\N	2026-05-02	land	Exchange	PAX_001	\N	\N	XE5457Y	\N	\N	General Waste	5069	\N	\N	\N	\N	\N	\N	\N	\N	14730.0	17410.0	2690.0	891	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by MURU-K001956	2026-07-24 15:15:51.944859+00
25769	backfill	\N	2026-05-04	land	Exchange	PAX_001	\N	\N	XE4491D	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	14470.0	20550.0	6080.0	892	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by MURU-K001956	2026-07-24 15:15:51.944859+00
25770	backfill	\N	2026-05-04	land	Exchange	PAX_001	\N	\N	XE4491D	\N	\N	General Waste	\N	5069	\N	\N	\N	\N	\N	\N	\N	14940.0	17460.0	2620.0	894	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by WILLIAM NG-K007671; Gross ~14,940 — verify | Gross ~14,940 — verify	2026-07-24 15:15:51.944859+00
25774	backfill	\N	2026-05-05	land	Exchange	PAX_001	\N	\N	XE4491D	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	14860.0	16150.0	1290.0	898	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	bin_in_raw=5224 | remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by AMIR-K12898	2026-07-24 15:15:51.944859+00
25775	backfill	\N	2026-05-05	land	Exchange	PAX_001	\N	\N	XE4491D	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	14380.0	17370.0	2990.0	902	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by AMIR-K12898	2026-07-24 15:15:51.944859+00
25778	backfill	\N	2026-05-06	land	Exchange	PAX_001	\N	\N	XE4491D	\N	\N	General Waste	5194	\N	\N	\N	\N	\N	\N	\N	\N	14400.0	17740.0	3340.0	908	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	bin_out_raw=5224 | remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by AMIR-K12898	2026-07-24 15:15:51.944859+00
25779	backfill	\N	2026-05-06	land	Exchange	PAX_001	\N	\N	XE4491D	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	14980.0	16220.0	1240.0	910	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	bin_in_raw=5224 | remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by AMIR-K12898	2026-07-24 15:15:51.944859+00
25783	backfill	\N	2026-05-07	land	Exchange	PAX_001	\N	\N	XE4491D	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	14790.0	17160.0	2370.0	916	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	bin_out_raw=5224 | remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by MURU-K001956	2026-07-24 15:15:51.944859+00
25794	backfill	\N	2026-05-09	land	Exchange	PAX_001	\N	\N	XE4491D	\N	\N	General Waste	\N	5069	\N	\N	\N	\N	\N	\N	\N	14610.0	16810.0	2230.0	957	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by BALA-K009902; Bin Out reading 5069/8069 — verify | Bin Out reading 5069/8069 — verify	2026-07-24 15:15:51.944859+00
25790	backfill	\N	2026-05-08	land	Exchange	PAX_001	\N	\N	XE4491D	\N	\N	General Waste	5160	5194	\N	\N	\N	\N	\N	\N	\N	14790.0	16500.0	1710.0	952	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by MUSTAFA	2026-07-24 15:15:51.944859+00
25786	backfill	\N	2026-05-08	land	Exchange	PAX_001	\N	\N	XE4491D	\N	\N	General Waste	5160	5194	\N	\N	\N	\N	\N	\N	\N	14700.0	17240.0	2540.0	932	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by AMIR-K12898; Same bins as DO 25790 — verify | Same bins as DO 25790 — verify	2026-07-24 15:15:51.944859+00
25787	backfill	\N	2026-05-08	land	Exchange	PAX_001	\N	\N	XE4491D	\N	\N	General Waste	5194	\N	\N	\N	\N	\N	\N	\N	\N	14430.0	18700.0	4270.0	936	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by AMIR-K12898; DO date blank; used weighbridge date | DO date blank; used weighbridge date	2026-07-24 15:15:51.944859+00
25789	backfill	\N	2026-05-08	land	Exchange	PAX_001	\N	\N	XE4491D	\N	\N	General Waste	5069	5160	\N	\N	\N	\N	\N	\N	\N	15180.0	18960.0	3780.0	947	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by MUSTAFA	2026-07-24 15:15:51.944859+00
26789	backfill	\N	2026-05-11	land	Exchange	PAX_001	\N	\N	XE6221D	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	14010.0	16180.0	2170.0	970	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by AMIR-K12898	2026-07-24 15:15:51.944859+00
26790	backfill	\N	2026-05-11	land	Exchange	PAX_001	\N	\N	XE6221D	\N	\N	General Waste	\N	5160	\N	\N	\N	\N	\N	\N	\N	14170.0	20880.0	6710.0	975	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by AMIR-K12898	2026-07-24 15:15:51.944859+00
26795	backfill	\N	2026-05-11	land	Exchange	PAX_001	\N	\N	XE6221D	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	14230.0	19450.0	5220.0	983	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by AMIR-K12898	2026-07-24 15:15:51.944859+00
26806	backfill	\N	2026-05-12	land	Exchange	PAX_001	\N	\N	XE6221D	\N	\N	General Waste	5135	\N	\N	\N	\N	\N	\N	\N	\N	14080.0	16420.0	2340.0	994	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by MUSTAFA	2026-07-24 15:15:51.944859+00
26801	backfill	\N	2026-05-12	land	Exchange	PAX_001	\N	\N	XE6221D	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	14150.0	16920.0	2470.0	986	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by MUSTAFA	2026-07-24 15:15:51.944859+00
26802	backfill	\N	2026-05-12	land	Exchange	PAX_001	\N	\N	XE6221D	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	14190.0	16510.0	2320.0	988	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by AMIR-K12898	2026-07-24 15:15:51.944859+00
26813	backfill	\N	2026-05-13	land	Exchange	PAX_001	\N	\N	XE6221D	\N	\N	General Waste	5135	\N	\N	\N	\N	\N	\N	\N	\N	14020.0	14310.0	290.0	1002	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by AMIR-K12898	2026-07-24 15:15:51.944859+00
26812	backfill	\N	2026-05-13	land	Exchange	PAX_001	\N	\N	XE6221D	\N	\N	General Waste	\N	5135	\N	\N	\N	\N	\N	\N	\N	14100.0	17670.0	3570.0	1001	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by AMIR-K12898	2026-07-24 15:15:51.944859+00
26822	backfill	\N	2026-05-15	land	Exchange	PAX_001	\N	\N	XE6221D	\N	\N	General Waste	\N	5204	\N	\N	\N	\N	\N	\N	\N	14250.0	16970.0	2720.0	1025	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by MORTHY-K00910	2026-07-24 15:15:51.944859+00
26826	backfill	\N	2026-05-16	land	Exchange	PAX_001	\N	\N	XE6221D	\N	\N	General Waste	5194	5058	\N	\N	\N	\N	\N	\N	\N	14060.0	16080.0	2020.0	1031	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by AMIR-K12898	2026-07-24 15:15:51.944859+00
26828	backfill	\N	2026-05-16	land	Exchange	PAX_001	\N	\N	XE6221D	\N	\N	General Waste	5047	\N	\N	\N	\N	\N	\N	\N	\N	14730.0	15920.0	1110.0	1036	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by AMIR-K12898	2026-07-24 15:15:51.944859+00
23306	backfill	\N	2026-05-18	land	Exchange	PAX_001	\N	\N	XE8496	\N	\N	General Waste	\N	5047	\N	\N	\N	\N	\N	\N	\N	14710.0	21870.0	7130.0	1042	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by AMIR-K12898	2026-07-24 15:15:51.944859+00
23307	backfill	\N	2026-05-18	land	Exchange	PAX_001	\N	\N	XE8496	\N	\N	General Waste	\N	5194	\N	\N	\N	\N	\N	\N	\N	14850.0	17380.0	2530.0	1045	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by AMIR-K12898; Bin In unclear — verify | Bin In unclear — verify	2026-07-24 15:15:51.944859+00
23310	backfill	\N	2026-05-18	land	Exchange	PAX_001	\N	\N	XE8496	\N	\N	General Waste	5108	\N	\N	\N	\N	\N	\N	\N	\N	14240.0	17650.0	3410.0	1052	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by AMIR-K12898	2026-07-24 15:15:51.944859+00
23312	backfill	\N	2026-05-19	land	Exchange	PAX_001	\N	\N	XE8496	\N	\N	General Waste	5096	5108	\N	\N	\N	\N	\N	\N	\N	14710.0	17010.0	2300.0	1055	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by LOH MG-K001775	2026-07-24 15:15:51.944859+00
23321	backfill	\N	2026-05-20	land	Exchange	PAX_001	\N	\N	XE8496	\N	\N	General Waste	5046	5047	\N	\N	\N	\N	\N	\N	\N	14760.0	18580.0	3820.0	1081	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by AMIR-K12898; Bin Out unclear — verify | Bin Out unclear — verify	2026-07-24 15:15:51.944859+00
23318	backfill	\N	2026-05-20	land	Exchange	PAX_001	\N	\N	XE8496	\N	\N	General Waste	\N	5096	\N	\N	\N	\N	\N	\N	\N	11610.0	16690.0	5070.0	1070	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by MURU-K001956	2026-07-24 15:15:51.944859+00
23323	backfill	\N	2026-05-21	land	Exchange	PAX_001	\N	\N	XE8496	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	14430.0	16620.0	2190.0	1087	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by MUSTAFA; Bin In unclear — verify | Bin In unclear — verify	2026-07-24 15:15:51.944859+00
23328	backfill	\N	2026-05-21	land	Exchange	PAX_001	\N	\N	XE8496	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	14290.0	18110.0	3820.0	1089	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	bin_out_raw=5040 | bin_in_raw=735 | remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by AMIR-K12898; Bin In/Out unclear — verify | Bin In/Out unclear — verify	2026-07-24 15:15:51.944859+00
23329	backfill	\N	2026-05-22	land	Exchange	PAX_001	\N	\N	XE8496	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	14250.0	18470.0	4220.0	1091	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by AMIR-K12898; Bin Out unclear — verify | Bin Out unclear — verify	2026-07-24 15:15:51.944859+00
23330	backfill	\N	2026-05-22	land	Exchange	PAX_001	\N	\N	XE8496	\N	\N	General Waste	5060	5135	\N	\N	\N	\N	\N	\N	\N	14750.0	17380.0	2630.0	1104	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by AMIR-K12898	2026-07-24 15:15:51.944859+00
23305	backfill	\N	2026-05-23	land	Exchange	PAX_001	\N	\N	XE8496	\N	\N	General Waste	\N	5060	\N	\N	\N	\N	\N	\N	\N	14170.0	17990.0	3820.0	1101	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by BALA-K009902	2026-07-24 15:15:51.944859+00
23334	backfill	\N	2026-05-23	land	Exchange	PAX_001	\N	\N	XE8496	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	15030.0	16240.0	1240.0	1107	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by AMIR-K12898; Bin In unclear — verify | Bin In unclear — verify	2026-07-24 15:15:51.944859+00
23482	backfill	\N	2026-05-25	land	Exchange	PAX_001	\N	\N	XE5457Y	\N	\N	General Waste	5162	\N	\N	\N	\N	\N	\N	\N	\N	14510.0	17520.0	3010.0	1128	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by MUSTAFA	2026-07-24 15:15:51.944859+00
23483	backfill	\N	2026-05-25	land	Exchange	PAX_001	\N	\N	XE5457Y	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	14100.0	18190.0	4090.0	1130	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by AMIR-K12898	2026-07-24 15:15:51.944859+00
23486	backfill	\N	2026-05-25	land	Exchange	PAX_001	\N	\N	XE5457Y	\N	\N	General Waste	\N	5162	\N	\N	\N	\N	\N	\N	\N	14470.0	19070.0	3600.0	1138	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by AMIR-K12898	2026-07-24 15:15:51.944859+00
23491	backfill	\N	2026-05-26	land	Exchange	PAX_001	\N	\N	XE5457Y	\N	\N	General Waste	5108	\N	\N	\N	\N	\N	\N	\N	\N	14240.0	16720.0	2480.0	1153	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by AMIR-K12898	2026-07-24 15:15:51.944859+00
23488	backfill	\N	2026-05-26	land	Exchange	PAX_001	\N	\N	XE5457Y	\N	\N	General Waste	5038	\N	\N	\N	\N	\N	\N	\N	\N	14790.0	17970.0	3190.0	1144	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by AMIR-K12898	2026-07-24 15:15:51.944859+00
23493	backfill	\N	2026-05-28	land	Exchange	PAX_001	\N	\N	XE5457Y	\N	\N	General Waste	5056	5038	\N	\N	\N	\N	\N	\N	\N	14710.0	18950.0	4240.0	1175	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by MUSTAFA	2026-07-24 15:15:51.944859+00
23494	backfill	\N	2026-05-28	land	Exchange	PAX_001	\N	\N	XE5457Y	\N	\N	General Waste	5038	5108	\N	\N	\N	\N	\N	\N	\N	14650.0	16980.0	2330.0	1177	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by MURU-K001956	2026-07-24 15:15:51.944859+00
23496	backfill	\N	2026-05-28	land	Exchange	PAX_001	\N	\N	XE5457Y	\N	\N	General Waste	5044	5056	\N	\N	\N	\N	\N	\N	\N	14670.0	17450.0	2780.0	1179	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by BALA-K009902	2026-07-24 15:15:51.944859+00
23706	backfill	\N	2026-05-29	land	Exchange	PAX_001	\N	\N	XE5457Y	\N	\N	General Waste	5084	5232	\N	\N	\N	\N	\N	\N	\N	14730.0	17710.0	2980.0	1193	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by MURU-K001956	2026-07-24 15:15:51.944859+00
23499	backfill	\N	2026-05-29	land	Exchange	PAX_001	\N	\N	XE5457Y	\N	\N	General Waste	5232	5038	\N	\N	\N	\N	\N	\N	\N	14560.0	16550.0	1990.0	1184	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by MUSTAFA	2026-07-24 15:15:51.944859+00
23707	backfill	\N	2026-05-30	land	Exchange	PAX_001	\N	\N	XE5457Y	\N	\N	General Waste	5232	5044	\N	\N	\N	\N	\N	\N	\N	14730.0	18310.0	3580.0	1196	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by BALA-K009902; DO remark: SEND BIN | DO remark: SEND BIN	2026-07-24 15:15:51.944859+00
23710	backfill	\N	2026-05-30	land	Exchange	PAX_001	\N	\N	XE5457Y	\N	\N	General Waste	\N	5084	\N	\N	\N	\N	\N	\N	\N	14180.0	19930.0	5750.0	1210	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by BALA-K009902	2026-07-24 15:15:51.944859+00
26809	backfill	\N	2026-05-13	land	Exchange	PAX_001	\N	\N	XE6221D	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	13990.0	14950.0	970.0	998	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by AMIR-K12898 | pt7 missing-middle	2026-07-24 15:15:51.944859+00
26815	backfill	\N	2026-05-14	land	Exchange	PAX_001	\N	\N	XE6221D	\N	\N	General Waste	5079	\N	\N	\N	\N	\N	\N	\N	\N	14390.0	14800.0	410.0	1003	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by MURU-K001956 | pt7 missing-middle	2026-07-24 15:15:51.944859+00
26816	backfill	\N	2026-05-14	land	Exchange	PAX_001	\N	\N	XE6221D	\N	\N	General Waste	\N	5135	\N	\N	\N	\N	\N	\N	\N	14300.0	16020.0	1720.0	1006	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by AMIR-K12898 | pt7 missing-middle	2026-07-24 15:15:51.944859+00
26820	backfill	\N	2026-05-14	land	Exchange	PAX_001	\N	\N	XE6221D	\N	\N	General Waste	5204	5079	\N	\N	\N	\N	\N	\N	\N	14420.0	15810.0	1390.0	1010	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by MORTHY-K000910 | pt7 missing-middle	2026-07-24 15:15:51.944859+00
26821	backfill	\N	2026-05-15	land	Exchange	PAX_001	\N	\N	XE6221D	\N	\N	General Waste	5058	\N	\N	\N	\N	\N	\N	\N	\N	14610.0	15610.0	1000.0	1023	\N	weighbridge	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Backfill DO + weighbridge (May 2026); 1x5FT; weighed by MUSTAFA | pt7 missing-middle	2026-07-24 15:15:51.944859+00
17902	backfill	\N	2026-05-28	vessel	PSA Vessel	PIL_001	KOTA LEKAS	B06	XE6221D	SATHISH	\N	Vessel Waste	\N	\N	0.80	0.06	0.60	0.02	0.00	0.80	2.40	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill; Cat I 0.12 m3; 0.20 m3 oily rags | Cat I 0.12 m3; 0.20 m3 oily rags	2026-07-24 15:15:51.944859+00
17903	backfill	\N	2026-05-29	vessel	PSA Vessel	PIL_001	KOTA SAHABAT	B06	XE6221D	SATHISH	\N	Vessel Waste	\N	\N	0.30	0.04	0.30	0.00	0.00	0.40	1.04	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill	2026-07-24 15:15:51.944859+00
17904	backfill	\N	2026-05-30	vessel	PSA Vessel	PIL_001	KOTA SEGAR	B05	XE6221D	SATHISH	\N	Vessel Waste	\N	\N	0.40	0.00	0.40	0.02	0.00	0.20	1.02	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill	2026-07-24 15:15:51.944859+00
17906	backfill	\N	2026-05-31	vessel	PSA Vessel	PIL_001	KOTA CARUM	B06	XE6221D	SATHISH	\N	Vessel Waste	\N	\N	1.20	0.00	0.60	0.00	0.03	0.30	2.13	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill	2026-07-24 15:15:51.944859+00
17907	backfill	\N	2026-06-02	vessel	PSA Vessel	PIL_001	KOTA GANDING	B06	XE6221D	SATHISH	\N	Vessel Waste	\N	\N	0.50	0.02	0.40	0.01	0.00	0.40	1.34	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill; Cat I E-waste 0.01 m3 | Cat I E-waste 0.01 m3	2026-07-24 15:15:51.944859+00
17911	backfill	\N	2026-06-05	vessel	PSA Vessel	PIL_001	KOTA RAJIN	B05	XE6221D	SATHISH	\N	Vessel Waste	\N	\N	0.20	0.02	0.20	0.02	0.00	0.20	0.66	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill; Cat I E-waste 0.02 m3 | Cat I E-waste 0.02 m3	2026-07-24 15:15:51.944859+00
17919	backfill	\N	2026-06-13	vessel	PSA Vessel	PIL_001	KOTA LEMBAH	B06	XE6221D	SATHISH	\N	Vessel Waste	\N	\N	0.80	0.00	0.50	0.00	0.08	0.30	1.68	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill	2026-07-24 15:15:51.944859+00
17920	backfill	\N	2026-06-13	vessel	PSA Vessel	PIL_001	KOTA SETIA	B05	XE6221D	SATHISH	\N	Vessel Waste	\N	\N	1.20	0.00	0.30	0.02	0.00	0.40	1.92	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill	2026-07-24 15:15:51.944859+00
17921	backfill	\N	2026-06-14	vessel	PSA Vessel	PIL_001	KOTA MACHAN	B06	XE6221D	SATHISH	\N	Vessel Waste	\N	\N	0.40	0.00	0.40	0.01	0.00	0.20	1.01	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill	2026-07-24 15:15:51.944859+00
17925	backfill	\N	2026-06-18	vessel	PSA Vessel	PIL_001	KOTA RESTU	B06	XE5457Y	SATHISH	\N	Vessel Waste	\N	\N	0.50	0.02	0.40	0.00	0.00	0.30	1.22	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill	2026-07-24 15:15:51.944859+00
17927	backfill	\N	2026-06-20	vessel	PSA Vessel	PIL_001	KOTA JAYA	B05	XE5457Y	SATHISH	\N	Vessel Waste	\N	\N	0.50	0.00	0.50	0.02	0.00	0.40	1.42	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill	2026-07-24 15:15:51.944859+00
17930	backfill	\N	2026-06-22	vessel	PSA Vessel	PIL_001	KOTA HAKIM	B06	XE6221D	SATHISH	\N	Vessel Waste	\N	\N	0.00	0.00	0.20	0.00	0.10	0.70	1.00	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill; Total blank on DO (computed); Cat E incinerator ashes | Total blank on DO (computed); Cat E incinerator ashes	2026-07-24 15:15:51.944859+00
17932	backfill	\N	2026-06-23	vessel	PSA Vessel	PIL_001	SELATAN DAMAI	B05	XE6221D	SATHISH	\N	Vessel Waste	\N	\N	0.60	0.02	0.20	0.02	0.00	0.40	1.24	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill	2026-07-24 15:15:51.944859+00
17933	backfill	\N	2026-06-24	vessel	PSA Vessel	PIL_001	KOTA DUNIA	B05	XE6221D	SATHISH	\N	Vessel Waste	\N	\N	1.00	0.04	0.30	0.00	0.00	0.10	1.44	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill	2026-07-24 15:15:51.944859+00
17934	backfill	\N	2026-06-24	vessel	PSA Vessel	PIL_001	KOTA NALURI	B06	XE6221D	SATHISH	\N	Vessel Waste	\N	\N	0.80	0.00	0.40	0.02	0.01	0.50	1.73	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill	2026-07-24 15:15:51.944859+00
17935	backfill	\N	2026-06-25	vessel	PSA Vessel	PIL_001	KOTA EBONY	B05	XE6221D	SATHISH	\N	Vessel Waste	\N	\N	0.50	0.04	0.50	0.02	0.08	0.60	1.74	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill	2026-07-24 15:15:51.944859+00
17936	backfill	\N	2026-06-26	vessel	PSA Vessel	PIL_001	KOTA CARUM	B05	XE6221D	SATHISH	\N	Vessel Waste	\N	\N	1.20	0.00	0.60	0.01	0.03	0.30	2.14	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill	2026-07-24 15:15:51.944859+00
17938	backfill	\N	2026-06-28	vessel	PSA Vessel	PIL_001	KOTA SALAM	B05	XE6221D	SATHISH	\N	Vessel Waste	\N	\N	0.80	0.04	0.40	0.02	0.04	0.80	2.10	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill	2026-07-24 15:15:51.944859+00
18039	backfill	\N	2026-05-10	vessel	PSA Vessel	PIL_001	KOTA GANDING	B08	XE7116D	YAO_JUN	\N	Vessel Waste	\N	\N	0.40	0.02	0.30	0.00	0.00	0.30	1.02	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill	2026-07-24 15:15:51.944859+00
18040	backfill	\N	2026-05-10	vessel	PSA Vessel	PIL_001	KOTA SELAMAT	B06	XE7116D	YAO_JUN	\N	Vessel Waste	\N	\N	0.60	0.00	0.50	0.01	0.00	0.30	1.41	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill; Oily rags in bags 0.25 m3 | Oily rags in bags 0.25 m3	2026-07-24 15:15:51.944859+00
18044	backfill	\N	2026-05-16	vessel	PSA Vessel	PIL_001	KOTA PAHLAWAN	B05	XE7116D	YAO_JUN	\N	Vessel Waste	\N	\N	1.20	0.00	0.60	0.04	0.14	0.40	2.38	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill	2026-07-24 15:15:51.944859+00
18047	backfill	\N	2026-05-25	vessel	PSA Vessel	PIL_001	KOTA MAKMUR	B06	XE7116D	YAO_JUN	\N	Vessel Waste	\N	\N	0.80	0.00	0.60	0.02	0.00	0.80	2.22	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill; Oily rags 0.2 m3 | Oily rags 0.2 m3	2026-07-24 15:15:51.944859+00
18049	backfill	\N	2026-05-26	vessel	PSA Vessel	PIL_001	KOTA SABAS	B05	XE7116D	YAO_JUN	\N	Vessel Waste	\N	\N	0.50	0.02	0.60	0.02	0.01	0.40	1.55	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill	2026-07-24 15:15:51.944859+00
18050	backfill	\N	2026-05-27	vessel	PSA Vessel	PIL_001	KOTA SELAMAT	B06	XE7116D	YAO_JUN	\N	Vessel Waste	\N	\N	0.60	0.00	0.40	0.01	0.00	0.20	1.21	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill	2026-07-24 15:15:51.944859+00
18622	backfill	\N	2026-04-28	vessel	PSA Vessel	PIL_001	KOTA DUNIA	B07	XE6221D	KARTHIK	\N	Vessel Waste	\N	\N	1.00	0.06	0.60	0.00	0.00	0.10	1.76	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill	2026-07-24 15:15:51.944859+00
18624	backfill	\N	2026-05-07	vessel	PSA Vessel	PIL_001	KOTA MACHAN	B07	XE5457Y	KARTHIK	\N	Vessel Waste	\N	\N	0.40	0.00	0.40	0.01	0.00	0.20	1.01	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill	2026-07-24 15:15:51.944859+00
18627	backfill	\N	2026-05-14	vessel	PSA Vessel	PIL_001	KOTA NEBULA	B08	XE5457Y	KARTHIK	\N	Vessel Waste	\N	\N	0.60	0.00	0.60	0.00	0.00	0.30	1.50	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill	2026-07-24 15:15:51.944859+00
18629	backfill	\N	2026-05-18	vessel	PSA Vessel	PIL_001	KOTA GADANG	B05	XE5457Y	KARTHIK	\N	Vessel Waste	\N	\N	0.30	0.00	0.30	0.00	0.00	0.10	0.70	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill	2026-07-24 15:15:51.944859+00
18630	backfill	\N	2026-05-19	vessel	PSA Vessel	PIL_001	KOTA NALURI	B05	XE5457Y	KARTHIK	\N	Vessel Waste	\N	\N	1.20	0.00	0.70	0.03	0.03	0.60	2.56	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill	2026-07-24 15:15:51.944859+00
18631	backfill	\N	2026-05-20	vessel	PSA Vessel	PIL_001	KOTA NEKAD	B06	XE5457Y	KARTHIK	\N	Vessel Waste	\N	\N	0.70	0.00	0.60	0.02	0.00	0.50	1.82	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill; Oily rags 0.2 m3 | Oily rags 0.2 m3	2026-07-24 15:15:51.944859+00
18634	backfill	\N	2026-05-27	vessel	PSA Vessel	PIL_001	KOTA LARIS	B06	XE5457Y	KARTHIK	\N	Vessel Waste	\N	\N	1.20	0.00	0.80	0.02	0.01	0.50	2.53	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill; Incl 0.2 m3 oily rags | Incl 0.2 m3 oily rags	2026-07-24 15:15:51.944859+00
18751	backfill	\N	2026-05-28	vessel	PSA Vessel	PIL_001	KOTA RAJIN	B05	XE7126P	YAO_JUN	\N	Vessel Waste	\N	\N	0.30	0.04	0.30	0.02	0.00	0.30	0.98	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill; Cat I E-waste 0.02 m3; plate verify | Cat I E-waste 0.02 m3; plate verify	2026-07-24 15:15:51.944859+00
18752	backfill	\N	2026-05-29	vessel	PSA Vessel	PIL_001	KOTA RANCAK	B06	XE7126P	YAO_JUN	\N	Vessel Waste	\N	\N	0.40	0.00	0.60	0.02	0.00	0.20	1.22	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill; plate verify | plate verify	2026-07-24 15:15:51.944859+00
18755	backfill	\N	2026-05-31	vessel	PSA Vessel	PIL_001	KOTA LAWA	B05	XE7126P	YAO_JUN	\N	Vessel Waste	\N	\N	1.10	0.00	1.10	0.02	0.00	1.10	3.32	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill; plate verify | plate verify	2026-07-24 15:15:51.944859+00
18757	backfill	\N	2026-06-01	vessel	PSA Vessel	PIL_001	KOTA RESTU	B06	XE7126P	YAO_JUN	\N	Vessel Waste	\N	\N	0.50	0.03	0.40	0.02	0.00	0.40	1.35	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill; plate verify | plate verify	2026-07-24 15:15:51.944859+00
18758	backfill	\N	2026-06-02	vessel	PSA Vessel	PIL_001	KOTA CEPAT	B06	XE7126P	YAO_JUN	\N	Vessel Waste	\N	\N	0.50	0.00	0.40	0.02	0.00	0.40	1.32	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill; Faded scan — verify; 0.25 m3 solid sludge | Faded scan — verify; 0.25 m3 solid sludge	2026-07-24 15:15:51.944859+00
18760	backfill	\N	2026-06-03	vessel	PSA Vessel	PIL_001	KOTA LARIS	B05	XE7126P	YAO_JUN	\N	Vessel Waste	\N	\N	0.30	0.00	0.30	0.00	0.00	0.10	0.70	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill; 0.05 m3 oily rags; plate verify | 0.05 m3 oily rags; plate verify	2026-07-24 15:15:51.944859+00
18762	backfill	\N	2026-06-05	vessel	PSA Vessel	PIL_001	KOTA JOHAN	B05	XE7126P	YAO_JUN	\N	Vessel Waste	\N	\N	0.50	0.02	0.60	0.02	0.00	0.62	1.80	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill; Cat I 0.04 m3 | Cat I 0.04 m3	2026-07-24 15:15:51.944859+00
18763	backfill	\N	2026-06-06	vessel	PSA Vessel	PIL_001	KOTA NAGA	B05	XE7126P	YAO_JUN	\N	Vessel Waste	\N	\N	0.45	0.03	0.95	0.00	0.00	0.40	1.83	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill	2026-07-24 15:15:51.944859+00
18767	backfill	\N	2026-06-09	vessel	PSA Vessel	PIL_001	KOTA CEMPAKA	B07	XE7126P	YAO_JUN	\N	Vessel Waste	\N	\N	0.70	0.03	0.50	0.01	0.00	0.20	1.44	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill	2026-07-24 15:15:51.944859+00
18771	backfill	\N	2026-06-11	vessel	PSA Vessel	PIL_001	KOTA NABIL	B07	XE7126P	YAO_JUN	\N	Vessel Waste	\N	\N	0.80	0.00	0.30	0.00	0.03	0.40	1.53	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill	2026-07-24 15:15:51.944859+00
18772	backfill	\N	2026-06-11	vessel	PSA Vessel	PIL_001	KOTA LOCENG	B06	XE7126P	YAO_JUN	\N	Vessel Waste	\N	\N	1.50	0.03	1.10	0.02	0.01	0.50	3.16	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill; Cat A 1.1/1.5 unclear | Cat A 1.1/1.5 unclear	2026-07-24 15:15:51.944859+00
18779	backfill	\N	2026-06-17	vessel	PSA Vessel	PIL_001	KOTA GANDING	B06	XE7126P	YAO_JUN	\N	Vessel Waste	\N	\N	0.40	0.02	0.30	0.00	0.00	0.30	1.02	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill	2026-07-24 15:15:51.944859+00
18782	backfill	\N	2026-06-18	vessel	PSA Vessel	PIL_001	KOTA MAKMUR	B07	XE7126P	YAO_JUN	\N	Vessel Waste	\N	\N	0.60	0.00	0.60	0.02	0.00	0.60	1.82	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill	2026-07-24 15:15:51.944859+00
18783	backfill	\N	2026-06-22	vessel	PSA Vessel	PIL_001	SALERNO EXPRESS	B07	XE7126P	YAO_JUN	\N	Vessel Waste	\N	\N	0.40	0.00	0.40	0.00	0.00	0.50	1.30	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill	2026-07-24 15:15:51.944859+00
18785	backfill	\N	2026-06-22	vessel	PSA Vessel	PIL_001	KOTA DUTA	B05	XE7126P	YAO_JUN	\N	Vessel Waste	\N	\N	0.90	0.00	0.40	0.01	0.02	0.70	2.03	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill; Incl 0.5 m3 oily rags | Incl 0.5 m3 oily rags	2026-07-24 15:15:51.944859+00
18790	backfill	\N	2026-06-26	vessel	PSA Vessel	PIL_001	KOTA SAHABAT	B06	XE7126P	YAO_JUN	\N	Vessel Waste	\N	\N	0.50	0.04	0.50	0.02	0.00	0.50	1.56	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	remarks=Vessel DO backfill	2026-07-24 15:15:51.944859+00
23637	backfill	\N	2026-06-09	standard	\N	SAV_001	\N	\N	XE6221D	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	reocr 24Jul2026 from SAVILLS BLUE HUB (1) (1).pdf | bin_in_raw=L51 | bin_out_raw=L29 | location=Bay-109 | job=exchange	2026-07-24 15:45:07.605862+00
24200	backfill	\N	2026-06-09	standard	\N	SAV_001	\N	\N	\N	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	reocr 24Jul2026 from SAVILLS BLUE HUB (1) (1).pdf | bin_in_raw=5196? | bin_out_raw=L48 | location=L6 | date digit unclear (read 09/06/26) - verify	2026-07-24 15:45:07.605862+00
25860	backfill	\N	2026-06-13	standard	\N	SAV_001	\N	\N	XE4491D	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	reocr 24Jul2026 from SAVILLS BLUE HUB (1) (1).pdf | bin_in_raw=5057? | bin_out_raw=5092? | location=Level-6-609 | job=exchange | bin digits unclear	2026-07-24 15:45:07.605862+00
23748	backfill	\N	2026-06-15	standard	\N	SAV_001	\N	\N	\N	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	reocr 24Jul2026 from SAVILLS BLUE HUB (1) (1).pdf | bin_in_raw=5147? | bin_out_raw=L29 | location=L3 | bin_in unclear	2026-07-24 15:45:07.605862+00
24120	backfill	\N	2026-06-18	standard	\N	SAV_001	\N	\N	\N	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	reocr 24Jul2026 from SAVILLS BLUE HUB (1) (1).pdf | bin_in_raw=5108? | bin_out_raw=5197? | location=L4 | bin digits unclear	2026-07-24 15:45:07.605862+00
24121	backfill	\N	2026-06-18	standard	\N	SAV_001	\N	\N	\N	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	reocr 24Jul2026 from SAVILLS BLUE HUB (1) (1).pdf | bin_in_raw=5197? | bin_out_raw=5055? | location=L6 | bin digits unclear	2026-07-24 15:45:07.605862+00
23902	backfill	\N	2026-06-20	standard	\N	SAV_001	\N	\N	XE5457Y	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	reocr 24Jul2026 from SAVILLS BLUE HUB (1) (1).pdf | bin_in_raw=5032 | bin_out_raw=L51 | location=Bay-109 | job=exchange	2026-07-24 15:45:07.605862+00
23528	backfill	\N	2026-06-22	standard	\N	SAV_001	\N	\N	\N	\N	\N	General Waste	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	reocr 24Jul2026 from SAVILLS BLUE HUB (1) (1).pdf | bin_in_raw=L31? | bin_out_raw=5147? | location=L3 | bin_in unclear	2026-07-24 15:45:07.605862+00
23905	backfill	\N	2026-06-22	standard	\N	SAV_001	\N	\N	XE6221D	\N	\N	General Waste	5213	5197	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	reocr 24Jul2026 from SAVILLS BLUE HUB (1) (1).pdf | bin_in_raw=5213 | bin_out_raw=5197 | location=Level-6 | job=exchange	2026-07-24 15:45:07.605862+00
24301	backfill	\N	2026-06-24	standard	\N	SAV_001	\N	\N	\N	\N	\N	General Waste	\N	5213	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	reocr 24Jul2026 from SAVILLS BLUE HUB (1) (1).pdf | bin_in_raw=5054? | bin_out_raw=5213 | location=L6 | bin_in unclear	2026-07-24 15:45:07.605862+00
24451	backfill	\N	2026-06-29	standard	\N	SAV_001	\N	\N	XE4491D	\N	\N	General Waste	5222	5108	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	volume_est	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	reocr 24Jul2026 from SAVILLS BLUE HUB (1) (1).pdf | bin_in_raw=5222 | bin_out_raw=5108 | job=exchange	2026-07-24 15:45:07.605862+00
\.


--
-- Data for Name: customers; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.customers (client_id, name, payment_terms, sales_rep, xero_contact_id, active, created_at) FROM stdin;
EXP	123 Express	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
ABS	Absolut Properties Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
ACR	Acreation Group Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
ADV	Advanced Substrate Technologies Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
AJK	AJK	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
ALL	Allalloy Dynaweld Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
ALLI	Allied Container Services Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
APE	Apex Sealing Technologies Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
ARC	Archibiz	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
ART	Artdecor Design Studio Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
ASL	ASL Proworld Solution Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
AST	Astore Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
AVE	Aver Asia (S) Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
BCW	B&C Waste	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
BAB	Babu	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
BEE	Beejoo	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
BND	BNDC (Fairprice)	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
CPH	C & P Holdings Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
CAL	Calvary Carpentry Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
CAR	Cargo International	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
CAT	Caterpillar	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
CBM	CBM Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
CHA	Chateraise	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
CHI	Chiong Construction	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
CHU	Chuan Seng Leong	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
CLE	Cleanis-Tee	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
CNC	CNCCS Engineering and Construction Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
CRE	CrestSA Marine & Offshore Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
DSV	DSV	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
DYN	Dyna Cool	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
ENG	Eng Lee Logistics Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
ENGL	Eng Leng Contractors Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
ENGI	Engie Services Singapore Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
EPO	Epont Building Services Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
EUR	Euro Pac Logistics Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
EVE	EverTeam Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
FAX	Faxolif Industries Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
GEO	Geoinnovations Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
GLO	Glory SIP Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
GSE	GS Engineering and Construction Corporation	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
GWC	GWC	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
GYM	Gymsportz	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
HPR	H1 Projects Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
HAI	Haid Biotechnology Industry (Singapore) Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
HCG	HCG	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
HEP	He Ping Development Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
HON	Hong Hang Hardware	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
HOT	Hotel Royal Singapore	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
HUA	Huationg Contractor	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
HUN	Huntsman (S) Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
HYD	Hydroproof	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
HYU	Hyundai Engineering & Construction Co., Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
INV	INVX Asia Pacific Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
IWA	Iwatech	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
LAU	Lau Choy Seng Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
LCH	LCH Logistics Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
LEN	Leng Aik Engineering	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
LEX	LexBuild International Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
LIM	Lim Siang Huat Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
LIR	Lirich	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
MAT	Matrix Cooling (Singapore) Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
MEC	Mecom GreenBuild (Singapore) Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
NEA	NEA	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
PAX	PaxOcean Singapore Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
POH	Poh Tiong Choon Logistics Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
PSA	PSA Port Ecosystem (Sea) Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
QUA	Qualicoat Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
RAD	Radha Exports Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
REM	REMEX Minerals Singapore Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
RJH	RJ Hydralics	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
SAV	Savills Property Management Pte Ltd (Blue Hub)	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
SAVI	Savills Property Management Pte Ltd (Green Hub)	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
SEA	Seatrium Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
SHI	Shin Ya O Ya Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
SIE	Siew Kong Glass Makers Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
SIN	Sin Hong Hardware Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
SINH	Sin Hong Poh Metal Trading	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
SIND	Sindac Cleaning Services Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
SLS	SLS	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
SNI	Snip Avenue Holdings	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
SPR	Springlife Maintenance Service Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
STX	ST	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
STA	Stamford Tyres	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
STS	STSM	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
SUM	Sumber Indah Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
SUN	Sun City Maintenance Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
SYS	Sys-Mac Automation Engineering Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
SYST	System Foundation Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
TRE	T3 Reources Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
TAI	Tai Lee Tong	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
TEC	Technicair Singapore Services Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
TECH	Technigroup Far East Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
TECK	Teck Sang Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
TOH	Toh Ban Seng	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
TON	Tong Carriage (S) Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
TONG	Tong Hock Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
TOP	Top Star Builder Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
TRA	Tracebuild	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
TST	TSTL	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
URB	Urban Group Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
WRA	W'Ray Construction Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
WAH	Wah & Hua Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
WEB	WeBuild	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
WIK	WIKA Instrumentation Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
WIL	Wilkie Development Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
WOR	World of Wood Pte Ltd	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
PIL	Pacific International Lines	\N	\N	\N	t	2026-07-24 15:15:51.944859+00
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
1	fuel	diesel	\N	2.678000	kgCO2e/L	indicative - verify before external reporting	\N	2026-07-24
2	grid	sg_grid	\N	0.402000	kgCO2e/kWh	EMA 2024 - verify	\N	2026-07-24
3	waste	general_waste	WtE	0.350000	tCO2e/t	indicative - verify	\N	2026-07-24
4	avoided	general_waste	recovery	0.460000	tCO2e/t	indicative - verify	\N	2026-07-24
5	avoided	paper	recovery	0.900000	tCO2e/t	indicative - verify	\N	2026-07-24
6	avoided	plastics	recovery	1.100000	tCO2e/t	indicative - verify	\N	2026-07-24
7	avoided	metals	recovery	1.500000	tCO2e/t	indicative - verify	\N	2026-07-24
\.


--
-- Data for Name: fuel_log; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.fuel_log (id, vehicle_id, fill_date, litres, cost, odometer_km, entered_by) FROM stdin;
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

COPY public.odometer_log (id, vehicle_id, read_date, odometer_km, source) FROM stdin;
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
1	EXP_001	Exchange	23.00	2026-07-24	\N
2	EXP_001	Collect	23.00	2026-07-24	\N
3	EXP_001	Delivery	8.00	2026-07-24	\N
4	ABS_001	Exchange	23.00	2026-07-24	\N
5	ABS_001	Collect	23.00	2026-07-24	\N
6	ABS_001	Delivery	8.00	2026-07-24	\N
7	ABS_002	Exchange	23.00	2026-07-24	\N
8	ABS_002	Collect	23.00	2026-07-24	\N
9	ABS_002	Delivery	8.00	2026-07-24	\N
10	ACR_001	Exchange	23.00	2026-07-24	\N
11	ACR_001	Collect	23.00	2026-07-24	\N
12	ACR_001	Delivery	8.00	2026-07-24	\N
13	ACR_002	Exchange	23.00	2026-07-24	\N
14	ACR_002	Collect	23.00	2026-07-24	\N
15	ACR_002	Delivery	8.00	2026-07-24	\N
16	ACR_003	Exchange	23.00	2026-07-24	\N
17	ACR_003	Collect	23.00	2026-07-24	\N
18	ACR_003	Delivery	8.00	2026-07-24	\N
19	ACR_004	Exchange	23.00	2026-07-24	\N
20	ACR_004	Collect	23.00	2026-07-24	\N
21	ACR_004	Delivery	8.00	2026-07-24	\N
22	ADV_001	Exchange	13.00	2026-07-24	\N
23	ADV_001	Collect	13.00	2026-07-24	\N
24	ADV_001	Delivery	8.00	2026-07-24	\N
25	AJK_001	Exchange	13.00	2026-07-24	\N
26	AJK_001	Collect	13.00	2026-07-24	\N
27	AJK_001	Delivery	8.00	2026-07-24	\N
28	ALL_001	Exchange	13.00	2026-07-24	\N
29	ALL_001	Collect	13.00	2026-07-24	\N
30	ALL_001	Delivery	8.00	2026-07-24	\N
31	ALLI_001	Exchange	13.00	2026-07-24	\N
32	ALLI_001	Collect	13.00	2026-07-24	\N
33	ALLI_001	Delivery	8.00	2026-07-24	\N
34	ALLI_002	Exchange	13.00	2026-07-24	\N
35	ALLI_002	Collect	13.00	2026-07-24	\N
36	ALLI_002	Delivery	8.00	2026-07-24	\N
37	ALLI_003	Exchange	13.00	2026-07-24	\N
38	ALLI_003	Collect	13.00	2026-07-24	\N
39	ALLI_003	Delivery	8.00	2026-07-24	\N
40	APE_001	Exchange	13.00	2026-07-24	\N
41	APE_001	Collect	13.00	2026-07-24	\N
42	APE_001	Delivery	8.00	2026-07-24	\N
43	APE_002	Exchange	13.00	2026-07-24	\N
44	APE_002	Collect	13.00	2026-07-24	\N
45	APE_002	Delivery	8.00	2026-07-24	\N
46	ARC_001	Exchange	18.00	2026-07-24	\N
47	ARC_001	Collect	18.00	2026-07-24	\N
48	ARC_001	Delivery	8.00	2026-07-24	\N
49	ART_001	Exchange	23.00	2026-07-24	\N
50	ART_001	Collect	23.00	2026-07-24	\N
51	ART_001	Delivery	8.00	2026-07-24	\N
52	ASL_001	Exchange	13.00	2026-07-24	\N
53	ASL_001	Collect	13.00	2026-07-24	\N
54	ASL_001	Delivery	8.00	2026-07-24	\N
55	AST_001	Exchange	23.00	2026-07-24	\N
56	AST_001	Collect	23.00	2026-07-24	\N
57	AST_001	Delivery	8.00	2026-07-24	\N
58	AVE_001	Exchange	13.00	2026-07-24	\N
59	AVE_001	Collect	13.00	2026-07-24	\N
60	AVE_001	Delivery	8.00	2026-07-24	\N
61	BCW_001	Exchange	13.00	2026-07-24	\N
62	BCW_001	Collect	13.00	2026-07-24	\N
63	BCW_001	Delivery	8.00	2026-07-24	\N
64	BCW_001	Load	21.00	2026-07-24	\N
65	BCW_002	Exchange	23.00	2026-07-24	\N
66	BCW_002	Collect	23.00	2026-07-24	\N
67	BCW_002	Delivery	8.00	2026-07-24	\N
68	BCW_002	Load	31.00	2026-07-24	\N
69	BCW_003	Exchange	23.00	2026-07-24	\N
70	BCW_003	Collect	23.00	2026-07-24	\N
71	BCW_003	Delivery	8.00	2026-07-24	\N
72	BCW_003	Load	31.00	2026-07-24	\N
73	BCW_004	Exchange	18.00	2026-07-24	\N
74	BCW_004	Collect	18.00	2026-07-24	\N
75	BCW_004	Delivery	8.00	2026-07-24	\N
76	BCW_004	Load	26.00	2026-07-24	\N
77	BCW_005	Exchange	23.00	2026-07-24	\N
78	BCW_005	Collect	23.00	2026-07-24	\N
79	BCW_005	Delivery	8.00	2026-07-24	\N
80	BCW_005	Load	31.00	2026-07-24	\N
81	BCW_006	Exchange	23.00	2026-07-24	\N
82	BCW_006	Collect	23.00	2026-07-24	\N
83	BCW_006	Delivery	8.00	2026-07-24	\N
84	BCW_006	Load	31.00	2026-07-24	\N
85	BCW_007	Exchange	23.00	2026-07-24	\N
86	BCW_007	Collect	23.00	2026-07-24	\N
87	BCW_007	Delivery	8.00	2026-07-24	\N
88	BCW_007	Load	31.00	2026-07-24	\N
89	BAB_001	Exchange	18.00	2026-07-24	\N
90	BAB_001	Collect	18.00	2026-07-24	\N
91	BAB_001	Delivery	8.00	2026-07-24	\N
92	BAB_002	Exchange	23.00	2026-07-24	\N
93	BAB_002	Collect	23.00	2026-07-24	\N
94	BAB_002	Delivery	8.00	2026-07-24	\N
95	BAB_003	Exchange	23.00	2026-07-24	\N
96	BAB_003	Collect	23.00	2026-07-24	\N
97	BAB_003	Delivery	8.00	2026-07-24	\N
98	BAB_004	Exchange	23.00	2026-07-24	\N
99	BAB_004	Collect	23.00	2026-07-24	\N
100	BAB_004	Delivery	8.00	2026-07-24	\N
101	BEE_001	Dump	18.00	2026-07-24	\N
102	BND_001	Exchange	13.00	2026-07-24	\N
103	BND_001	Collect	13.00	2026-07-24	\N
104	BND_001	Delivery	8.00	2026-07-24	\N
105	BND_002	Exchange	13.00	2026-07-24	\N
106	BND_002	Collect	13.00	2026-07-24	\N
107	BND_002	Delivery	8.00	2026-07-24	\N
108	BND_003	Exchange	13.00	2026-07-24	\N
109	BND_003	Collect	13.00	2026-07-24	\N
110	BND_003	Delivery	8.00	2026-07-24	\N
111	BND_004	Exchange	13.00	2026-07-24	\N
112	BND_004	Collect	13.00	2026-07-24	\N
113	BND_004	Delivery	8.00	2026-07-24	\N
114	CPH_001	Exchange	13.00	2026-07-24	\N
115	CPH_001	Collect	13.00	2026-07-24	\N
116	CPH_001	Delivery	8.00	2026-07-24	\N
117	CAL_001	Exchange	18.00	2026-07-24	\N
118	CAL_001	Collect	18.00	2026-07-24	\N
119	CAL_001	Delivery	8.00	2026-07-24	\N
120	CAR_001	Exchange	13.00	2026-07-24	\N
121	CAR_001	Collect	13.00	2026-07-24	\N
122	CAR_001	Delivery	8.00	2026-07-24	\N
123	CAT_001	Exchange	18.00	2026-07-24	\N
124	CAT_001	Collect	18.00	2026-07-24	\N
125	CAT_001	Delivery	8.00	2026-07-24	\N
126	CAT_002	Exchange	18.00	2026-07-24	\N
127	CAT_002	Collect	18.00	2026-07-24	\N
128	CAT_002	Delivery	8.00	2026-07-24	\N
129	CBM_001	Exchange	18.00	2026-07-24	\N
130	CBM_001	Collect	18.00	2026-07-24	\N
131	CBM_001	Delivery	8.00	2026-07-24	\N
132	CHA_001	Exchange	13.00	2026-07-24	\N
133	CHA_001	Collect	13.00	2026-07-24	\N
134	CHA_001	Delivery	8.00	2026-07-24	\N
135	CHI_001	Exchange	23.00	2026-07-24	\N
136	CHI_001	Collect	23.00	2026-07-24	\N
137	CHI_001	Delivery	8.00	2026-07-24	\N
138	CHI_002	Exchange	23.00	2026-07-24	\N
139	CHI_002	Collect	23.00	2026-07-24	\N
140	CHI_002	Delivery	8.00	2026-07-24	\N
141	CHI_003	Exchange	13.00	2026-07-24	\N
142	CHI_003	Collect	13.00	2026-07-24	\N
143	CHI_003	Delivery	8.00	2026-07-24	\N
144	CHU_001	Exchange	23.00	2026-07-24	\N
145	CHU_001	Collect	23.00	2026-07-24	\N
146	CHU_001	Delivery	8.00	2026-07-24	\N
147	CLE_001	Exchange	13.00	2026-07-24	\N
148	CLE_001	Collect	13.00	2026-07-24	\N
149	CLE_001	Delivery	8.00	2026-07-24	\N
150	CNC_001	Exchange	23.00	2026-07-24	\N
151	CNC_001	Collect	23.00	2026-07-24	\N
152	CNC_001	Delivery	8.00	2026-07-24	\N
153	CRE_001	Exchange	13.00	2026-07-24	\N
154	CRE_001	Collect	13.00	2026-07-24	\N
155	CRE_001	Delivery	8.00	2026-07-24	\N
156	DSV_001	Exchange	13.00	2026-07-24	\N
157	DSV_001	Collect	13.00	2026-07-24	\N
158	DSV_001	Delivery	8.00	2026-07-24	\N
159	DYN_001	Exchange	13.00	2026-07-24	\N
160	DYN_001	Collect	13.00	2026-07-24	\N
161	DYN_001	Delivery	8.00	2026-07-24	\N
162	ENG_001	Exchange	13.00	2026-07-24	\N
163	ENG_001	Collect	13.00	2026-07-24	\N
164	ENG_001	Delivery	8.00	2026-07-24	\N
165	ENGL_001	Exchange	13.00	2026-07-24	\N
166	ENGL_001	Collect	13.00	2026-07-24	\N
167	ENGL_001	Delivery	8.00	2026-07-24	\N
168	ENGL_002	Exchange	13.00	2026-07-24	\N
169	ENGL_002	Collect	13.00	2026-07-24	\N
170	ENGL_002	Delivery	8.00	2026-07-24	\N
171	ENGL_003	Exchange	13.00	2026-07-24	\N
172	ENGL_003	Collect	13.00	2026-07-24	\N
173	ENGL_003	Delivery	8.00	2026-07-24	\N
174	ENGL_004	Exchange	13.00	2026-07-24	\N
175	ENGL_004	Collect	13.00	2026-07-24	\N
176	ENGL_004	Delivery	8.00	2026-07-24	\N
177	ENGL_005	Exchange	13.00	2026-07-24	\N
178	ENGL_005	Collect	13.00	2026-07-24	\N
179	ENGL_005	Delivery	8.00	2026-07-24	\N
180	ENGL_006	Exchange	13.00	2026-07-24	\N
181	ENGL_006	Collect	13.00	2026-07-24	\N
182	ENGL_006	Delivery	8.00	2026-07-24	\N
183	ENGL_007	Exchange	13.00	2026-07-24	\N
184	ENGL_007	Collect	13.00	2026-07-24	\N
185	ENGL_007	Delivery	8.00	2026-07-24	\N
186	ENGL_008	Exchange	13.00	2026-07-24	\N
187	ENGL_008	Collect	13.00	2026-07-24	\N
188	ENGL_008	Delivery	8.00	2026-07-24	\N
189	ENGL_009	Exchange	13.00	2026-07-24	\N
190	ENGL_009	Collect	13.00	2026-07-24	\N
191	ENGL_009	Delivery	8.00	2026-07-24	\N
192	ENGL_010	Exchange	13.00	2026-07-24	\N
193	ENGL_010	Collect	13.00	2026-07-24	\N
194	ENGL_010	Delivery	8.00	2026-07-24	\N
195	ENGL_011	Exchange	13.00	2026-07-24	\N
196	ENGL_011	Collect	13.00	2026-07-24	\N
197	ENGL_011	Delivery	8.00	2026-07-24	\N
198	ENGI_001	Exchange	23.00	2026-07-24	\N
199	ENGI_001	Collect	23.00	2026-07-24	\N
200	ENGI_001	Delivery	8.00	2026-07-24	\N
201	ENGI_002	Exchange	23.00	2026-07-24	\N
202	ENGI_002	Collect	23.00	2026-07-24	\N
203	ENGI_002	Delivery	8.00	2026-07-24	\N
204	ENGI_003	Exchange	13.00	2026-07-24	\N
205	ENGI_003	Collect	13.00	2026-07-24	\N
206	ENGI_003	Delivery	8.00	2026-07-24	\N
207	ENGI_004	Exchange	23.00	2026-07-24	\N
208	ENGI_004	Collect	23.00	2026-07-24	\N
209	ENGI_004	Delivery	8.00	2026-07-24	\N
210	ENGI_005	Exchange	18.00	2026-07-24	\N
211	ENGI_005	Collect	18.00	2026-07-24	\N
212	ENGI_005	Delivery	8.00	2026-07-24	\N
213	ENGI_006	Exchange	23.00	2026-07-24	\N
214	ENGI_006	Collect	23.00	2026-07-24	\N
215	ENGI_006	Delivery	8.00	2026-07-24	\N
216	ENGI_007	Exchange	23.00	2026-07-24	\N
217	ENGI_007	Collect	23.00	2026-07-24	\N
218	ENGI_007	Delivery	8.00	2026-07-24	\N
219	ENGI_008	Exchange	23.00	2026-07-24	\N
220	ENGI_008	Collect	23.00	2026-07-24	\N
221	ENGI_008	Delivery	8.00	2026-07-24	\N
222	ENGI_009	Exchange	13.00	2026-07-24	\N
223	ENGI_009	Collect	13.00	2026-07-24	\N
224	ENGI_009	Delivery	8.00	2026-07-24	\N
225	ENGI_010	Exchange	13.00	2026-07-24	\N
226	ENGI_010	Collect	13.00	2026-07-24	\N
227	ENGI_010	Delivery	8.00	2026-07-24	\N
228	ENGI_011	Exchange	23.00	2026-07-24	\N
229	ENGI_011	Collect	23.00	2026-07-24	\N
230	ENGI_011	Delivery	8.00	2026-07-24	\N
231	ENGI_012	Exchange	23.00	2026-07-24	\N
232	ENGI_012	Collect	23.00	2026-07-24	\N
233	ENGI_012	Delivery	8.00	2026-07-24	\N
234	ENGI_013	Exchange	23.00	2026-07-24	\N
235	ENGI_013	Collect	23.00	2026-07-24	\N
236	ENGI_013	Delivery	8.00	2026-07-24	\N
237	ENGI_014	Exchange	23.00	2026-07-24	\N
238	ENGI_014	Collect	23.00	2026-07-24	\N
239	ENGI_014	Delivery	8.00	2026-07-24	\N
240	ENGI_015	Exchange	13.00	2026-07-24	\N
241	ENGI_015	Collect	13.00	2026-07-24	\N
242	ENGI_015	Delivery	8.00	2026-07-24	\N
243	EPO_001	Exchange	13.00	2026-07-24	\N
244	EPO_001	Collect	13.00	2026-07-24	\N
245	EPO_001	Delivery	8.00	2026-07-24	\N
246	EUR_001	Exchange	13.00	2026-07-24	\N
247	EUR_001	Collect	13.00	2026-07-24	\N
248	EUR_001	Delivery	8.00	2026-07-24	\N
249	EUR_002	Exchange	13.00	2026-07-24	\N
250	EUR_002	Collect	13.00	2026-07-24	\N
251	EUR_002	Delivery	8.00	2026-07-24	\N
252	EVE_001	Exchange	13.00	2026-07-24	\N
253	EVE_001	Collect	13.00	2026-07-24	\N
254	EVE_001	Delivery	8.00	2026-07-24	\N
255	FAX_001	Exchange	13.00	2026-07-24	\N
256	FAX_001	Collect	13.00	2026-07-24	\N
257	FAX_001	Delivery	8.00	2026-07-24	\N
258	GEO_001	Exchange	23.00	2026-07-24	\N
259	GEO_001	Collect	23.00	2026-07-24	\N
260	GEO_001	Delivery	8.00	2026-07-24	\N
261	GSE_001	Exchange	13.00	2026-07-24	\N
262	GSE_001	Collect	13.00	2026-07-24	\N
263	GSE_001	Delivery	8.00	2026-07-24	\N
264	GSE_002	Exchange	23.00	2026-07-24	\N
265	GSE_002	Collect	23.00	2026-07-24	\N
266	GSE_002	Delivery	8.00	2026-07-24	\N
267	GSE_003	Exchange	23.00	2026-07-24	\N
268	GSE_003	Collect	23.00	2026-07-24	\N
269	GSE_003	Delivery	8.00	2026-07-24	\N
270	GSE_004	Exchange	23.00	2026-07-24	\N
271	GSE_004	Collect	23.00	2026-07-24	\N
272	GSE_004	Delivery	8.00	2026-07-24	\N
273	GSE_005	Exchange	23.00	2026-07-24	\N
274	GSE_005	Collect	23.00	2026-07-24	\N
275	GSE_005	Delivery	8.00	2026-07-24	\N
276	GSE_006	Exchange	23.00	2026-07-24	\N
277	GSE_006	Collect	23.00	2026-07-24	\N
278	GSE_006	Delivery	8.00	2026-07-24	\N
279	GSE_007	Exchange	23.00	2026-07-24	\N
280	GSE_007	Collect	23.00	2026-07-24	\N
281	GSE_007	Delivery	8.00	2026-07-24	\N
282	GWC_001	Exchange	13.00	2026-07-24	\N
283	GWC_001	Collect	13.00	2026-07-24	\N
284	GWC_001	Delivery	8.00	2026-07-24	\N
285	GYM_001	Exchange	18.00	2026-07-24	\N
286	GYM_001	Collect	18.00	2026-07-24	\N
287	GYM_001	Delivery	8.00	2026-07-24	\N
288	HPR_001	Exchange	23.00	2026-07-24	\N
289	HPR_001	Collect	23.00	2026-07-24	\N
290	HPR_001	Delivery	8.00	2026-07-24	\N
291	HAI_001	Exchange	13.00	2026-07-24	\N
292	HAI_001	Collect	13.00	2026-07-24	\N
293	HAI_001	Delivery	8.00	2026-07-24	\N
294	HCG_001	Exchange	13.00	2026-07-24	\N
295	HCG_001	Collect	13.00	2026-07-24	\N
296	HCG_001	Delivery	8.00	2026-07-24	\N
297	HCG_002	Exchange	18.00	2026-07-24	\N
298	HCG_002	Collect	18.00	2026-07-24	\N
299	HCG_002	Delivery	8.00	2026-07-24	\N
300	HEP_001	Exchange	23.00	2026-07-24	\N
301	HEP_001	Collect	23.00	2026-07-24	\N
302	HEP_001	Delivery	8.00	2026-07-24	\N
303	HEP_002	Exchange	23.00	2026-07-24	\N
304	HEP_002	Collect	23.00	2026-07-24	\N
305	HEP_002	Delivery	8.00	2026-07-24	\N
306	HEP_003	Exchange	23.00	2026-07-24	\N
307	HEP_003	Collect	23.00	2026-07-24	\N
308	HEP_003	Delivery	8.00	2026-07-24	\N
309	HON_001	Exchange	13.00	2026-07-24	\N
310	HON_001	Collect	13.00	2026-07-24	\N
311	HON_001	Delivery	8.00	2026-07-24	\N
312	HOT_001	Exchange	23.00	2026-07-24	\N
313	HOT_001	Collect	23.00	2026-07-24	\N
314	HOT_001	Delivery	8.00	2026-07-24	\N
315	HUA_001	Exchange	23.00	2026-07-24	\N
316	HUA_001	Collect	23.00	2026-07-24	\N
317	HUA_001	Delivery	8.00	2026-07-24	\N
318	HUN_001	Exchange	23.00	2026-07-24	\N
319	HUN_001	Collect	23.00	2026-07-24	\N
320	HUN_001	Delivery	8.00	2026-07-24	\N
321	HYD_001	Exchange	13.00	2026-07-24	\N
322	HYD_001	Collect	13.00	2026-07-24	\N
323	HYD_001	Delivery	8.00	2026-07-24	\N
324	HYU_001	Exchange	23.00	2026-07-24	\N
325	HYU_001	Collect	23.00	2026-07-24	\N
326	HYU_001	Delivery	8.00	2026-07-24	\N
327	INV_001	Exchange	13.00	2026-07-24	\N
328	INV_001	Collect	13.00	2026-07-24	\N
329	INV_001	Delivery	8.00	2026-07-24	\N
330	IWA_001	Exchange	13.00	2026-07-24	\N
331	IWA_001	Collect	13.00	2026-07-24	\N
332	IWA_001	Delivery	8.00	2026-07-24	\N
333	LAU_001	Exchange	13.00	2026-07-24	\N
334	LAU_001	Collect	13.00	2026-07-24	\N
335	LAU_001	Delivery	8.00	2026-07-24	\N
336	LCH_001	Exchange	13.00	2026-07-24	\N
337	LCH_001	Collect	13.00	2026-07-24	\N
338	LCH_001	Delivery	8.00	2026-07-24	\N
339	LEN_001	Exchange	13.00	2026-07-24	\N
340	LEN_001	Collect	13.00	2026-07-24	\N
341	LEN_001	Delivery	8.00	2026-07-24	\N
342	LEX_001	Exchange	13.00	2026-07-24	\N
343	LEX_001	Collect	13.00	2026-07-24	\N
344	LEX_001	Delivery	8.00	2026-07-24	\N
345	LIR_001	Delivery	8.00	2026-07-24	\N
346	LIR_001	Sell	13.00	2026-07-24	\N
347	LIR_002	Delivery	8.00	2026-07-24	\N
348	LIR_002	Sell	13.00	2026-07-24	\N
349	LIR_003	Delivery	8.00	2026-07-24	\N
350	LIR_003	Sell	13.00	2026-07-24	\N
351	LIM_001	Exchange	13.00	2026-07-24	\N
352	LIM_001	Collect	13.00	2026-07-24	\N
353	LIM_001	Delivery	8.00	2026-07-24	\N
354	MAT_001	Exchange	13.00	2026-07-24	\N
355	MAT_001	Collect	13.00	2026-07-24	\N
356	MAT_001	Delivery	8.00	2026-07-24	\N
357	MEC_001	Exchange	13.00	2026-07-24	\N
358	MEC_001	Collect	13.00	2026-07-24	\N
359	MEC_001	Delivery	8.00	2026-07-24	\N
360	NEA_001	Exchange	13.00	2026-07-24	\N
361	NEA_001	Collect	13.00	2026-07-24	\N
362	NEA_001	Delivery	8.00	2026-07-24	\N
363	PAX_001	Exchange	13.00	2026-07-24	\N
364	PAX_001	Collect	13.00	2026-07-24	\N
365	PAX_001	Delivery	8.00	2026-07-24	\N
366	POH_001	Exchange	13.00	2026-07-24	\N
367	POH_001	Collect	13.00	2026-07-24	\N
368	POH_001	Delivery	8.00	2026-07-24	\N
369	POH_002	Exchange	13.00	2026-07-24	\N
370	POH_002	Collect	13.00	2026-07-24	\N
371	POH_002	Delivery	8.00	2026-07-24	\N
372	POH_003	Exchange	13.00	2026-07-24	\N
373	POH_003	Collect	13.00	2026-07-24	\N
374	POH_003	Delivery	8.00	2026-07-24	\N
375	POH_004	Exchange	13.00	2026-07-24	\N
376	POH_004	Collect	13.00	2026-07-24	\N
377	POH_004	Delivery	8.00	2026-07-24	\N
378	PSA_001	Exchange	13.00	2026-07-24	\N
379	PSA_001	Collect	13.00	2026-07-24	\N
380	PSA_001	Delivery	8.00	2026-07-24	\N
381	QUA_001	Exchange	13.00	2026-07-24	\N
382	QUA_001	Collect	13.00	2026-07-24	\N
383	QUA_001	Delivery	8.00	2026-07-24	\N
384	RAD_001	Exchange	13.00	2026-07-24	\N
385	RAD_001	Collect	13.00	2026-07-24	\N
386	RAD_001	Delivery	8.00	2026-07-24	\N
387	RAD_002	Exchange	13.00	2026-07-24	\N
388	RAD_002	Collect	13.00	2026-07-24	\N
389	RAD_002	Delivery	8.00	2026-07-24	\N
390	RAD_003	Exchange	13.00	2026-07-24	\N
391	RAD_003	Collect	13.00	2026-07-24	\N
392	RAD_003	Delivery	8.00	2026-07-24	\N
393	RAD_004	Exchange	13.00	2026-07-24	\N
394	RAD_004	Collect	13.00	2026-07-24	\N
395	RAD_004	Delivery	8.00	2026-07-24	\N
396	REM_001	Exchange	13.00	2026-07-24	\N
397	REM_001	Collect	13.00	2026-07-24	\N
398	REM_001	Delivery	8.00	2026-07-24	\N
399	RJH_001	Exchange	23.00	2026-07-24	\N
400	RJH_001	Collect	23.00	2026-07-24	\N
401	RJH_001	Delivery	8.00	2026-07-24	\N
402	SAV_001	Exchange	13.00	2026-07-24	\N
403	SAV_001	Collect	13.00	2026-07-24	\N
404	SAV_001	Delivery	8.00	2026-07-24	\N
405	SAV_002	Exchange	13.00	2026-07-24	\N
406	SAV_002	Collect	13.00	2026-07-24	\N
407	SAV_002	Delivery	8.00	2026-07-24	\N
408	SAV_003	Exchange	13.00	2026-07-24	\N
409	SAV_003	Collect	13.00	2026-07-24	\N
410	SAV_003	Delivery	8.00	2026-07-24	\N
411	SAV_004	Exchange	13.00	2026-07-24	\N
412	SAV_004	Collect	13.00	2026-07-24	\N
413	SAV_004	Delivery	8.00	2026-07-24	\N
414	SAVI_001	Exchange	13.00	2026-07-24	\N
415	SAVI_001	Collect	13.00	2026-07-24	\N
416	SAVI_001	Delivery	8.00	2026-07-24	\N
417	SAVI_002	Exchange	13.00	2026-07-24	\N
418	SAVI_002	Collect	13.00	2026-07-24	\N
419	SAVI_002	Delivery	8.00	2026-07-24	\N
420	SAVI_003	Exchange	13.00	2026-07-24	\N
421	SAVI_003	Collect	13.00	2026-07-24	\N
422	SAVI_003	Delivery	8.00	2026-07-24	\N
423	SAVI_004	Exchange	13.00	2026-07-24	\N
424	SAVI_004	Collect	13.00	2026-07-24	\N
425	SAVI_004	Delivery	8.00	2026-07-24	\N
426	SAVI_005	Exchange	13.00	2026-07-24	\N
427	SAVI_005	Collect	13.00	2026-07-24	\N
428	SAVI_005	Delivery	8.00	2026-07-24	\N
429	SEA_001	Exchange	23.00	2026-07-24	\N
430	SEA_001	Collect	23.00	2026-07-24	\N
431	SEA_001	Delivery	8.00	2026-07-24	\N
432	SHI_001	Exchange	13.00	2026-07-24	\N
433	SHI_001	Collect	13.00	2026-07-24	\N
434	SHI_001	Delivery	8.00	2026-07-24	\N
435	SHI_002	Exchange	13.00	2026-07-24	\N
436	SHI_002	Collect	13.00	2026-07-24	\N
437	SHI_002	Delivery	8.00	2026-07-24	\N
438	SIE_001	Exchange	13.00	2026-07-24	\N
439	SIE_001	Collect	13.00	2026-07-24	\N
440	SIE_001	Delivery	8.00	2026-07-24	\N
441	SIN_001	Exchange	13.00	2026-07-24	\N
442	SIN_001	Collect	13.00	2026-07-24	\N
443	SIN_001	Delivery	8.00	2026-07-24	\N
444	SINH_001	Exchange	23.00	2026-07-24	\N
445	SINH_001	Collect	23.00	2026-07-24	\N
446	SINH_001	Delivery	8.00	2026-07-24	\N
447	SIND_001	Exchange	13.00	2026-07-24	\N
448	SIND_001	Collect	13.00	2026-07-24	\N
449	SIND_001	Delivery	8.00	2026-07-24	\N
450	SIND_002	Exchange	18.00	2026-07-24	\N
451	SIND_002	Collect	18.00	2026-07-24	\N
452	SIND_002	Delivery	8.00	2026-07-24	\N
453	SLS_001	Exchange	13.00	2026-07-24	\N
454	SLS_001	Collect	13.00	2026-07-24	\N
455	SLS_001	Delivery	8.00	2026-07-24	\N
456	SLS_002	Exchange	13.00	2026-07-24	\N
457	SLS_002	Collect	13.00	2026-07-24	\N
458	SLS_002	Delivery	8.00	2026-07-24	\N
459	SNI_001	Exchange	23.00	2026-07-24	\N
460	SNI_001	Collect	23.00	2026-07-24	\N
461	SNI_001	Delivery	8.00	2026-07-24	\N
462	SPR_001	Exchange	18.00	2026-07-24	\N
463	SPR_001	Collect	18.00	2026-07-24	\N
464	SPR_001	Delivery	8.00	2026-07-24	\N
465	SPR_002	Exchange	13.00	2026-07-24	\N
466	SPR_002	Collect	13.00	2026-07-24	\N
467	SPR_002	Delivery	8.00	2026-07-24	\N
468	SPR_003	Exchange	23.00	2026-07-24	\N
469	SPR_003	Collect	23.00	2026-07-24	\N
470	SPR_003	Delivery	8.00	2026-07-24	\N
471	STX_001	Exchange	13.00	2026-07-24	\N
472	STX_001	Collect	13.00	2026-07-24	\N
473	STX_001	Delivery	8.00	2026-07-24	\N
474	STX_002	Exchange	19.50	2026-07-24	\N
475	STX_002	Collect	19.50	2026-07-24	\N
476	STX_002	Delivery	8.00	2026-07-24	\N
477	STX_003	Exchange	19.50	2026-07-24	\N
478	STX_003	Collect	19.50	2026-07-24	\N
479	STX_003	Delivery	8.00	2026-07-24	\N
480	STX_004	Exchange	13.00	2026-07-24	\N
481	STX_004	Collect	13.00	2026-07-24	\N
482	STX_004	Delivery	8.00	2026-07-24	\N
483	STA_001	Exchange	23.00	2026-07-24	\N
484	STA_001	Collect	23.00	2026-07-24	\N
485	STA_001	Delivery	8.00	2026-07-24	\N
486	STS_001	Exchange	23.00	2026-07-24	\N
487	STS_001	Collect	23.00	2026-07-24	\N
488	STS_001	Delivery	8.00	2026-07-24	\N
489	STS_002	Exchange	23.00	2026-07-24	\N
490	STS_002	Collect	23.00	2026-07-24	\N
491	STS_002	Delivery	8.00	2026-07-24	\N
492	STS_003	Exchange	18.00	2026-07-24	\N
493	STS_003	Collect	18.00	2026-07-24	\N
494	STS_003	Delivery	8.00	2026-07-24	\N
495	STS_004	Exchange	13.00	2026-07-24	\N
496	STS_004	Collect	13.00	2026-07-24	\N
497	STS_004	Delivery	8.00	2026-07-24	\N
498	STS_005	Exchange	18.00	2026-07-24	\N
499	STS_005	Collect	18.00	2026-07-24	\N
500	STS_005	Delivery	8.00	2026-07-24	\N
501	STS_006	Exchange	18.00	2026-07-24	\N
502	STS_006	Collect	18.00	2026-07-24	\N
503	STS_006	Delivery	8.00	2026-07-24	\N
504	SUM_001	Exchange	13.00	2026-07-24	\N
505	SUM_001	Collect	13.00	2026-07-24	\N
506	SUM_001	Delivery	8.00	2026-07-24	\N
507	SUN_001	Exchange	18.00	2026-07-24	\N
508	SUN_001	Collect	18.00	2026-07-24	\N
509	SUN_001	Delivery	8.00	2026-07-24	\N
510	SUN_002	Exchange	23.00	2026-07-24	\N
511	SUN_002	Collect	23.00	2026-07-24	\N
512	SUN_002	Delivery	8.00	2026-07-24	\N
513	SUN_003	Exchange	23.00	2026-07-24	\N
514	SUN_003	Collect	23.00	2026-07-24	\N
515	SUN_003	Delivery	8.00	2026-07-24	\N
516	SUN_004	Exchange	23.00	2026-07-24	\N
517	SUN_004	Collect	23.00	2026-07-24	\N
518	SUN_004	Delivery	8.00	2026-07-24	\N
519	SUN_005	Exchange	18.00	2026-07-24	\N
520	SUN_005	Collect	18.00	2026-07-24	\N
521	SUN_005	Delivery	8.00	2026-07-24	\N
522	SYS_001	Exchange	18.00	2026-07-24	\N
523	SYS_001	Collect	18.00	2026-07-24	\N
524	SYS_001	Delivery	8.00	2026-07-24	\N
525	SYST_001	Exchange	13.00	2026-07-24	\N
526	SYST_001	Collect	13.00	2026-07-24	\N
527	SYST_001	Delivery	8.00	2026-07-24	\N
528	SYST_002	Exchange	13.00	2026-07-24	\N
529	SYST_002	Collect	13.00	2026-07-24	\N
530	SYST_002	Delivery	8.00	2026-07-24	\N
531	TRE_001	Sell	13.00	2026-07-24	\N
532	TAI_001	Exchange	23.00	2026-07-24	\N
533	TAI_001	Collect	23.00	2026-07-24	\N
534	TAI_001	Delivery	8.00	2026-07-24	\N
535	TECH_001	Exchange	23.00	2026-07-24	\N
536	TECH_001	Collect	23.00	2026-07-24	\N
537	TECH_001	Delivery	8.00	2026-07-24	\N
538	TEC_001	Exchange	23.00	2026-07-24	\N
539	TEC_001	Collect	23.00	2026-07-24	\N
540	TEC_001	Delivery	8.00	2026-07-24	\N
541	TECK_001	Exchange	13.00	2026-07-24	\N
542	TECK_001	Collect	13.00	2026-07-24	\N
543	TECK_001	Delivery	8.00	2026-07-24	\N
544	TOH_001	Exchange	23.00	2026-07-24	\N
545	TOH_001	Collect	23.00	2026-07-24	\N
546	TOH_001	Delivery	8.00	2026-07-24	\N
547	TON_001	Exchange	13.00	2026-07-24	\N
548	TON_001	Collect	13.00	2026-07-24	\N
549	TON_001	Delivery	8.00	2026-07-24	\N
550	TONG_001	Exchange	13.00	2026-07-24	\N
551	TONG_001	Collect	13.00	2026-07-24	\N
552	TONG_001	Delivery	8.00	2026-07-24	\N
553	TONG_002	Exchange	23.00	2026-07-24	\N
554	TONG_002	Collect	23.00	2026-07-24	\N
555	TONG_002	Delivery	8.00	2026-07-24	\N
556	TONG_003	Exchange	18.00	2026-07-24	\N
557	TONG_003	Collect	18.00	2026-07-24	\N
558	TONG_003	Delivery	8.00	2026-07-24	\N
559	TONG_004	Exchange	13.00	2026-07-24	\N
560	TONG_004	Collect	13.00	2026-07-24	\N
561	TONG_004	Delivery	8.00	2026-07-24	\N
562	TONG_005	Exchange	23.00	2026-07-24	\N
563	TONG_005	Collect	23.00	2026-07-24	\N
564	TONG_005	Delivery	8.00	2026-07-24	\N
565	TONG_006	Exchange	13.00	2026-07-24	\N
566	TONG_006	Collect	13.00	2026-07-24	\N
567	TONG_006	Delivery	8.00	2026-07-24	\N
568	TONG_007	Exchange	18.00	2026-07-24	\N
569	TONG_007	Collect	18.00	2026-07-24	\N
570	TONG_007	Delivery	8.00	2026-07-24	\N
571	TONG_008	Exchange	18.00	2026-07-24	\N
572	TONG_008	Collect	18.00	2026-07-24	\N
573	TONG_008	Delivery	8.00	2026-07-24	\N
574	TONG_009	Exchange	18.00	2026-07-24	\N
575	TONG_009	Collect	18.00	2026-07-24	\N
576	TONG_009	Delivery	8.00	2026-07-24	\N
577	TOP_001	Exchange	23.00	2026-07-24	\N
578	TOP_001	Collect	23.00	2026-07-24	\N
579	TOP_001	Delivery	8.00	2026-07-24	\N
580	TST_001	Exchange	13.00	2026-07-24	\N
581	TST_001	Collect	13.00	2026-07-24	\N
582	TST_001	Delivery	8.00	2026-07-24	\N
583	TRA_001	Exchange	18.00	2026-07-24	\N
584	TRA_001	Collect	18.00	2026-07-24	\N
585	TRA_001	Delivery	8.00	2026-07-24	\N
586	URB_001	Exchange	23.00	2026-07-24	\N
587	URB_001	Collect	23.00	2026-07-24	\N
588	URB_001	Delivery	8.00	2026-07-24	\N
589	WAH_001	Exchange	23.00	2026-07-24	\N
590	WAH_001	Collect	23.00	2026-07-24	\N
591	WAH_001	Delivery	8.00	2026-07-24	\N
592	WAH_002	Exchange	23.00	2026-07-24	\N
593	WAH_002	Collect	23.00	2026-07-24	\N
594	WAH_002	Delivery	8.00	2026-07-24	\N
595	WAH_003	Exchange	18.00	2026-07-24	\N
596	WAH_003	Collect	18.00	2026-07-24	\N
597	WAH_003	Delivery	8.00	2026-07-24	\N
598	WAH_004	Exchange	23.00	2026-07-24	\N
599	WAH_004	Collect	23.00	2026-07-24	\N
600	WAH_004	Delivery	8.00	2026-07-24	\N
601	WAH_005	Exchange	18.00	2026-07-24	\N
602	WAH_005	Collect	18.00	2026-07-24	\N
603	WAH_005	Delivery	8.00	2026-07-24	\N
604	WAH_006	Exchange	23.00	2026-07-24	\N
605	WAH_006	Collect	23.00	2026-07-24	\N
606	WAH_006	Delivery	8.00	2026-07-24	\N
607	WAH_007	Exchange	23.00	2026-07-24	\N
608	WAH_007	Collect	23.00	2026-07-24	\N
609	WAH_007	Delivery	8.00	2026-07-24	\N
610	WEB_001	Exchange	23.00	2026-07-24	\N
611	WEB_001	Collect	23.00	2026-07-24	\N
612	WEB_001	Delivery	8.00	2026-07-24	\N
613	WIK_001	Exchange	13.00	2026-07-24	\N
614	WIK_001	Collect	13.00	2026-07-24	\N
615	WIK_001	Delivery	8.00	2026-07-24	\N
616	WIL_001	Exchange	13.00	2026-07-24	\N
617	WIL_001	Collect	13.00	2026-07-24	\N
618	WIL_001	Delivery	8.00	2026-07-24	\N
619	WOR_001	Exchange	23.00	2026-07-24	\N
620	WOR_001	Collect	23.00	2026-07-24	\N
621	WOR_001	Delivery	8.00	2026-07-24	\N
622	WRA_001	Exchange	23.00	2026-07-24	\N
623	WRA_001	Collect	23.00	2026-07-24	\N
624	WRA_001	Delivery	8.00	2026-07-24	\N
625	WRA_002	Exchange	13.00	2026-07-24	\N
626	WRA_002	Collect	13.00	2026-07-24	\N
627	WRA_002	Delivery	8.00	2026-07-24	\N
628	ENGI_016	Exchange	23.00	2026-07-24	\N
629	ENGI_016	Collect	23.00	2026-07-24	\N
630	ENGI_016	Delivery	8.00	2026-07-24	\N
631	ENGI_017	Exchange	23.00	2026-07-24	\N
632	ENGI_017	Collect	23.00	2026-07-24	\N
633	ENGI_017	Delivery	8.00	2026-07-24	\N
634	ENGI_018	Exchange	23.00	2026-07-24	\N
635	ENGI_018	Collect	23.00	2026-07-24	\N
636	ENGI_018	Delivery	8.00	2026-07-24	\N
637	GLO_001	Exchange	13.00	2026-07-24	\N
638	GLO_001	Collect	13.00	2026-07-24	\N
639	GLO_001	Delivery	8.00	2026-07-24	\N
640	LIR_004	Dump	18.00	2026-07-24	\N
641	LIR_005	Dump	13.00	2026-07-24	\N
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
\.


--
-- Data for Name: sites; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.sites (site_id, client_id, site_name, address, active, created_at) FROM stdin;
EXP_001	EXP	123 Express	60 Kaki Bukit Place, #06-14 Eunos Techpark	t	2026-07-24 15:15:51.944859+00
ABS_001	ABS	Absolut Properties Pte Ltd	163 Marine Parade Road, Marine Meadows Condo	t	2026-07-24 15:15:51.944859+00
ABS_002	ABS	Absolut Properties Pte Ltd	173 Jalan Loyang Besar, Ocean Front Suites Condo	t	2026-07-24 15:15:51.944859+00
ACR_001	ACR	Acreation Group Pte Ltd	19 Jalan Mesin	t	2026-07-24 15:15:51.944859+00
ACR_002	ACR	Acreation Group Pte Ltd	9 Raffles Boulevard	t	2026-07-24 15:15:51.944859+00
ACR_003	ACR	Acreation Group Pte Ltd	Engku Aman Road	t	2026-07-24 15:15:51.944859+00
ACR_004	ACR	Acreation Group Pte Ltd	Orchard Gateway, 277 Orchard Road	t	2026-07-24 15:15:51.944859+00
ADV_001	ADV	Advanced Substrate Technologies Pte Ltd	47A Jalan Buroh	t	2026-07-24 15:15:51.944859+00
AJK_001	AJK	AJK	24 Tuas Ave 8	t	2026-07-24 15:15:51.944859+00
ALL_001	ALL	Allalloy Dynaweld Pte Ltd	10 Tuas Link 1	t	2026-07-24 15:15:51.944859+00
ALLI_001	ALLI	Allied Container Services Pte Ltd	10 Tuas Ave 6	t	2026-07-24 15:15:51.944859+00
ALLI_002	ALLI	Allied Container Services Pte Ltd	15 Pioneer Crescent	t	2026-07-24 15:15:51.944859+00
ALLI_003	ALLI	Allied Container Services Pte Ltd	25 Penjuru Lane Yard 3	t	2026-07-24 15:15:51.944859+00
APE_001	APE	Apex Sealing Technologies Pte Ltd	19 Tuas South Street 5	t	2026-07-24 15:15:51.944859+00
APE_002	APE	Apex Sealing Technologies Pte Ltd	Tuas Basin Lane	t	2026-07-24 15:15:51.944859+00
ARC_001	ARC	Archibiz	Blk A 30 Kranji Loop, #06-05 Timmac @ Kranji	t	2026-07-24 15:15:51.944859+00
ART_001	ART	Artdecor Design Studio Pte Ltd	2 Defu South Street 1, #05-03, JTC Industrial City	t	2026-07-24 15:15:51.944859+00
ASL_001	ASL	ASL Proworld Solution Pte Ltd	8 Pandan Crescent	t	2026-07-24 15:15:51.944859+00
AST_001	AST	Astore Pte Ltd	43 Keppel Road	t	2026-07-24 15:15:51.944859+00
AVE_001	AVE	Aver Asia (S) Pte Ltd	14 Benoi Place	t	2026-07-24 15:15:51.944859+00
BCW_001	BCW	B&C Waste	16 Gul Crescent	t	2026-07-24 15:15:51.944859+00
BCW_002	BCW	B&C Waste	513 Kampong Bahru Road Keppel Distripark	t	2026-07-24 15:15:51.944859+00
BCW_003	BCW	B&C Waste	Upper Changi Road, Summer Garden Condo	t	2026-07-24 15:15:51.944859+00
BCW_004	BCW	B&C Waste	2 Mandai Link	t	2026-07-24 15:15:51.944859+00
BCW_005	BCW	B&C Waste	Peck Seah Street	t	2026-07-24 15:15:51.944859+00
BCW_006	BCW	B&C Waste	7 Changi South Street 2	t	2026-07-24 15:15:51.944859+00
BCW_007	BCW	B&C Waste	26 Loyang Drive	t	2026-07-24 15:15:51.944859+00
BAB_001	BAB	Babu	80 Mandai Lake Road	t	2026-07-24 15:15:51.944859+00
BAB_002	BAB	Babu	Blk 5 Haig Road #07-463	t	2026-07-24 15:15:51.944859+00
BAB_003	BAB	Babu	900 Bedok North Road	t	2026-07-24 15:15:51.944859+00
BAB_004	BAB	Babu	2 Stadium Walk	t	2026-07-24 15:15:51.944859+00
BEE_001	BEE	Beejoo	5 Sungei Kadut Street 6	t	2026-07-24 15:15:51.944859+00
BND_001	BND	BNDC (Fairprice)	1 Buroh Lane L4	t	2026-07-24 15:15:51.944859+00
BND_002	BND	BNDC (Fairprice)	28 Tuas Ave 13	t	2026-07-24 15:15:51.944859+00
BND_003	BND	BNDC (Fairprice)	5 Joo Koon Circle	t	2026-07-24 15:15:51.944859+00
BND_004	BND	BNDC (Fairprice)	7 Sunview Road	t	2026-07-24 15:15:51.944859+00
CPH_001	CPH	C & P Holdings Pte Ltd	46 Penjuru Lane	t	2026-07-24 15:15:51.944859+00
CAL_001	CAL	Calvary Carpentry Pte Ltd	54 Senoko Road	t	2026-07-24 15:15:51.944859+00
CAR_001	CAR	Cargo International	20 Gul Way, #05-04	t	2026-07-24 15:15:51.944859+00
CAT_001	CAT	Caterpillar	14 Tractor Road	t	2026-07-24 15:15:51.944859+00
CAT_002	CAT	Caterpillar	7 Tractor Road	t	2026-07-24 15:15:51.944859+00
CBM_001	CBM	CBM Pte Ltd	501 Old Choa Chu Kang Road, Home Team Academy	t	2026-07-24 15:15:51.944859+00
CHA_001	CHA	Chateraise	8 Jalan Besut L3	t	2026-07-24 15:15:51.944859+00
CHI_001	CHI	Chiong Construction	10 Serangoon Ave 4	t	2026-07-24 15:15:51.944859+00
CHI_002	CHI	Chiong Construction	13 Serangoon Ave 3	t	2026-07-24 15:15:51.944859+00
CHI_003	CHI	Chiong Construction	60 Blk A Jurong West Street 42	t	2026-07-24 15:15:51.944859+00
CHU_001	CHU	Chuan Seng Leong	21 Benoi Sector #03-03	t	2026-07-24 15:15:51.944859+00
CLE_001	CLE	Cleanis-Tee	8 Jalan Papan	t	2026-07-24 15:15:51.944859+00
CNC_001	CNC	CNCCS Engineering and Construction Pte Ltd	15 Tembusu Crescent, #08-01, COGENT.	t	2026-07-24 15:15:51.944859+00
CRE_001	CRE	CrestSA Marine & Offshore Pte Ltd	15 Pandan Road	t	2026-07-24 15:15:51.944859+00
DSV_001	DSV	DSV	24 Penjuru Road, #09-05/06 (Loading Bay 2)	t	2026-07-24 15:15:51.944859+00
DYN_001	DYN	Dyna Cool	2 Bukit Batok Street 24, #03-19 Skytech	t	2026-07-24 15:15:51.944859+00
ENG_001	ENG	Eng Lee Logistics Pte Ltd	9 Gul Circle	t	2026-07-24 15:15:51.944859+00
ENGL_001	ENGL	Eng Leng Contractors Pte Ltd	1 CleanTech Loop	t	2026-07-24 15:15:51.944859+00
ENGL_002	ENGL	Eng Leng Contractors Pte Ltd	1 Gul Circle, JTC Logistics Hub	t	2026-07-24 15:15:51.944859+00
ENGL_003	ENGL	Eng Leng Contractors Pte Ltd	16 Tuas Ave 1, JTC Space @ Tuas	t	2026-07-24 15:15:51.944859+00
ENGL_004	ENGL	Eng Leng Contractors Pte Ltd	2 Tukang Innovation Grove	t	2026-07-24 15:15:51.944859+00
ENGL_005	ENGL	Eng Leng Contractors Pte Ltd	28A Penjuru Close Bin Centre	t	2026-07-24 15:15:51.944859+00
ENGL_006	ENGL	Eng Leng Contractors Pte Ltd	8 Buroh Street	t	2026-07-24 15:15:51.944859+00
ENGL_007	ENGL	Eng Leng Contractors Pte Ltd	8 Jurong Town Hall Rd, JTC Summit Building	t	2026-07-24 15:15:51.944859+00
ENGL_008	ENGL	Eng Leng Contractors Pte Ltd	Jalan Papan LP 15	t	2026-07-24 15:15:51.944859+00
ENGL_009	ENGL	Eng Leng Contractors Pte Ltd	Pandan Loop, Blk K, (Phase 1), Bin Centre	t	2026-07-24 15:15:51.944859+00
ENGL_010	ENGL	Eng Leng Contractors Pte Ltd	Pandan Loop, Blk X, (Phase 3), Bin Centre	t	2026-07-24 15:15:51.944859+00
ENGL_011	ENGL	Eng Leng Contractors Pte Ltd	15 Jalan Terusan	t	2026-07-24 15:15:51.944859+00
ENGI_001	ENGI	Engie Services Singapore Pte Ltd	1 Canning Rise Singapore 179868	t	2026-07-24 15:15:51.944859+00
ENGI_002	ENGI	Engie Services Singapore Pte Ltd	1 Empress Place	t	2026-07-24 15:15:51.944859+00
ENGI_003	ENGI	Engie Services Singapore Pte Ltd	1 Jurong East st 21, Ng Teng Fong Hospital	t	2026-07-24 15:15:51.944859+00
ENGI_004	ENGI	Engie Services Singapore Pte Ltd	100 Victoria Street, Basement 2, Loading Bay	t	2026-07-24 15:15:51.944859+00
ENGI_005	ENGI	Engie Services Singapore Pte Ltd	17 Woodlands Drive 17, Woodlands Health Campus	t	2026-07-24 15:15:51.944859+00
ENGI_006	ENGI	Engie Services Singapore Pte Ltd	2 Simei Street 3, Changi General Hospital	t	2026-07-24 15:15:51.944859+00
ENGI_007	ENGI	Engie Services Singapore Pte Ltd	20 Airport Boulevard Changi Airport	t	2026-07-24 15:15:51.944859+00
ENGI_008	ENGI	Engie Services Singapore Pte Ltd	28 Irrawaddy Road, New Phoenix Park. (Ministry of Home Affairs)	t	2026-07-24 15:15:51.944859+00
ENGI_009	ENGI	Engie Services Singapore Pte Ltd	32 Jurong Port Road, Heritage Center	t	2026-07-24 15:15:51.944859+00
ENGI_010	ENGI	Engie Services Singapore Pte Ltd	4A Tuas Bay Street	t	2026-07-24 15:15:51.944859+00
ENGI_011	ENGI	Engie Services Singapore Pte Ltd	65 Airport Boulevard, #B2-63, Changi Airport T3	t	2026-07-24 15:15:51.944859+00
ENGI_012	ENGI	Engie Services Singapore Pte Ltd	9 Kallang Place	t	2026-07-24 15:15:51.944859+00
ENGI_013	ENGI	Engie Services Singapore Pte Ltd	93 Stamford Road, National Museum of Singapore	t	2026-07-24 15:15:51.944859+00
ENGI_014	ENGI	Engie Services Singapore Pte Ltd	Changi Airport T2 Basement	t	2026-07-24 15:15:51.944859+00
ENGI_015	ENGI	Engie Services Singapore Pte Ltd	2 Tuas Bay Street	t	2026-07-24 15:15:51.944859+00
STX_004	STX	ST	61a Tuas Nexus Drive	t	2026-07-24 15:15:51.944859+00
EPO_001	EPO	Epont Building Services Pte Ltd	1 Tuas View Place, Westlink One, #02-01	t	2026-07-24 15:15:51.944859+00
EUR_001	EUR	Euro Pac Logistics Pte Ltd	42 Tanjong Penjuru Road	t	2026-07-24 15:15:51.944859+00
EUR_002	EUR	Euro Pac Logistics Pte Ltd	52 Tanjong Penjuru #04-92	t	2026-07-24 15:15:51.944859+00
EVE_001	EVE	EverTeam Pte Ltd	60 Benoi Road	t	2026-07-24 15:15:51.944859+00
FAX_001	FAX	Faxolif Industries Pte Ltd	75 Tech Park Crescent	t	2026-07-24 15:15:51.944859+00
GEO_001	GEO	Geoinnovations Pte Ltd	5 Kwong Ming Road	t	2026-07-24 15:15:51.944859+00
GSE_001	GSE	GS Engineering and Construction Corporation	Nicoll Highway LP 120F	t	2026-07-24 15:15:51.944859+00
GSE_002	GSE	GS Engineering and Construction Corporation	Nicoll Highway LP 131F	t	2026-07-24 15:15:51.944859+00
GSE_003	GSE	GS Engineering and Construction Corporation	Nicoll Highway, LP 132F	t	2026-07-24 15:15:51.944859+00
GSE_004	GSE	GS Engineering and Construction Corporation	Ophir Road LP 14/1F	t	2026-07-24 15:15:51.944859+00
GSE_005	GSE	GS Engineering and Construction Corporation	Ophir Road, LP 30F	t	2026-07-24 15:15:51.944859+00
GSE_006	GSE	GS Engineering and Construction Corporation	Republic Boulevard LP 4F	t	2026-07-24 15:15:51.944859+00
GSE_007	GSE	GS Engineering and Construction Corporation	Victoria Street, LP 64F	t	2026-07-24 15:15:51.944859+00
GWC_001	GWC	GWC	449 Clementi Ave 3, #01-259	t	2026-07-24 15:15:51.944859+00
GYM_001	GYM	Gymsportz	7, Block B Mandai Link, #05-27 Mandai Connection	t	2026-07-24 15:15:51.944859+00
HPR_001	HPR	H1 Projects Pte Ltd	107 Jalan Pari Burong	t	2026-07-24 15:15:51.944859+00
HAI_001	HAI	Haid Biotechnology Industry (Singapore) Pte Ltd	46 Gul Drive	t	2026-07-24 15:15:51.944859+00
HCG_001	HCG	HCG	8 Tuas View Circuit	t	2026-07-24 15:15:51.944859+00
HCG_002	HCG	HCG	79 Anson Road	t	2026-07-24 15:15:51.944859+00
HEP_001	HEP	He Ping Development Pte Ltd	32 Tras Street	t	2026-07-24 15:15:51.944859+00
HEP_002	HEP	He Ping Development Pte Ltd	38 Beach Road, South Beach Tower	t	2026-07-24 15:15:51.944859+00
HEP_003	HEP	He Ping Development Pte Ltd	51 Tanjong Pagar Road	t	2026-07-24 15:15:51.944859+00
HON_001	HON	Hong Hang Hardware	35 Pioneer Road	t	2026-07-24 15:15:51.944859+00
HOT_001	HOT	Hotel Royal Singapore	36 Newton Road	t	2026-07-24 15:15:51.944859+00
HUA_001	HUA	Huationg Contractor	Tanah Merah Coast Road LP 509	t	2026-07-24 15:15:51.944859+00
HUN_001	HUN	Huntsman (S) Pte Ltd	10 Seraya Ave	t	2026-07-24 15:15:51.944859+00
HYD_001	HYD	Hydroproof	The Aries, 51 Science Park	t	2026-07-24 15:15:51.944859+00
HYU_001	HYU	Hyundai Engineering & Construction Co., Ltd	100 Beach Road	t	2026-07-24 15:15:51.944859+00
INV_001	INV	INVX Asia Pacific Pte Ltd	80 Tuas West Drive	t	2026-07-24 15:15:51.944859+00
IWA_001	IWA	Iwatech	2 Kian Teck Drive	t	2026-07-24 15:15:51.944859+00
LAU_001	LAU	Lau Choy Seng Pte Ltd	30 Tuas West Avenue	t	2026-07-24 15:15:51.944859+00
LCH_001	LCH	LCH Logistics Pte Ltd	3 Pioneer Sector 3	t	2026-07-24 15:15:51.944859+00
LEN_001	LEN	Leng Aik Engineering	17 Soon Lee Road	t	2026-07-24 15:15:51.944859+00
LEX_001	LEX	LexBuild International Pte Ltd	11 Tuas Bay Close, #04-01/02	t	2026-07-24 15:15:51.944859+00
LIR_001	LIR	Lirich	Carton	t	2026-07-24 15:15:51.944859+00
LIR_002	LIR	Lirich	Metal	t	2026-07-24 15:15:51.944859+00
LIR_003	LIR	Lirich	Plastics	t	2026-07-24 15:15:51.944859+00
LIM_001	LIM	Lim Siang Huat Pte Ltd	6 Fishery Port Road L3	t	2026-07-24 15:15:51.944859+00
MAT_001	MAT	Matrix Cooling (Singapore) Pte Ltd	10 Buroh Street, #07-01, Westconnect Building	t	2026-07-24 15:15:51.944859+00
MEC_001	MEC	Mecom GreenBuild (Singapore) Pte Ltd	23 Jurong Port Road	t	2026-07-24 15:15:51.944859+00
NEA_001	NEA	NEA	NEA Tuas	t	2026-07-24 15:15:51.944859+00
PAX_001	PAX	PaxOcean Singapore Pte Ltd	5 Jalan Samulun	t	2026-07-24 15:15:51.944859+00
POH_001	POH	Poh Tiong Choon Logistics Ltd	21 Ayer Merbau, Jurong Island	t	2026-07-24 15:15:51.944859+00
POH_002	POH	Poh Tiong Choon Logistics Ltd	48 Pandan Road L1	t	2026-07-24 15:15:51.944859+00
POH_003	POH	Poh Tiong Choon Logistics Ltd	48 Pandan Road L3	t	2026-07-24 15:15:51.944859+00
POH_004	POH	Poh Tiong Choon Logistics Ltd	48 Pandan Road L6	t	2026-07-24 15:15:51.944859+00
PSA_001	PSA	PSA Port Ecosystem (Sea) Pte Ltd	24 Penjuru Road. #05-06	t	2026-07-24 15:15:51.944859+00
QUA_001	QUA	Qualicoat Pte Ltd	5 Gul Drive	t	2026-07-24 15:15:51.944859+00
RAD_001	RAD	Radha Exports Pte Ltd	118 Pioneer Road L1	t	2026-07-24 15:15:51.944859+00
RAD_002	RAD	Radha Exports Pte Ltd	118 Pioneer Road L4	t	2026-07-24 15:15:51.944859+00
RAD_003	RAD	Radha Exports Pte Ltd	118 Pioneer Road L7	t	2026-07-24 15:15:51.944859+00
RAD_004	RAD	Radha Exports Pte Ltd	6 Fishery Port, L5M	t	2026-07-24 15:15:51.944859+00
REM_001	REM	REMEX Minerals Singapore Pte Ltd	98 Tuas South Ave 3 (Inside NEA building)	t	2026-07-24 15:15:51.944859+00
RJH_001	RJH	RJ Hydralics	83 Tagore Lane	t	2026-07-24 15:15:51.944859+00
SAV_001	SAV	Savills Property Management Pte Ltd (Blue Hub)	10 Sunview Road L109	t	2026-07-24 15:15:51.944859+00
SAV_002	SAV	Savills Property Management Pte Ltd (Blue Hub)	10 Sunview Road L309	t	2026-07-24 15:15:51.944859+00
SAV_003	SAV	Savills Property Management Pte Ltd (Blue Hub)	10 Sunview Road L407	t	2026-07-24 15:15:51.944859+00
SAV_004	SAV	Savills Property Management Pte Ltd (Blue Hub)	10 Sunview Road L609	t	2026-07-24 15:15:51.944859+00
SAVI_001	SAVI	Savills Property Management Pte Ltd (Green Hub)	11 Pioneer Turn L2	t	2026-07-24 15:15:51.944859+00
SAVI_002	SAVI	Savills Property Management Pte Ltd (Green Hub)	11 Pioneer Turn L401	t	2026-07-24 15:15:51.944859+00
SAVI_003	SAVI	Savills Property Management Pte Ltd (Green Hub)	11 Pioneer Turn L407	t	2026-07-24 15:15:51.944859+00
SAVI_004	SAVI	Savills Property Management Pte Ltd (Green Hub)	11 Pioneer Turn L601	t	2026-07-24 15:15:51.944859+00
SAVI_005	SAVI	Savills Property Management Pte Ltd (Green Hub)	11 Pioneer Turn L8	t	2026-07-24 15:15:51.944859+00
SEA_001	SEA	Seatrium Pte Ltd	60 Admiralty Road West	t	2026-07-24 15:15:51.944859+00
SHI_001	SHI	Shin Ya O Ya Pte Ltd	6 Chin Bee Ave L5	t	2026-07-24 15:15:51.944859+00
SHI_002	SHI	Shin Ya O Ya Pte Ltd	6 Chin Bee Ave L9	t	2026-07-24 15:15:51.944859+00
SIE_001	SIE	Siew Kong Glass Makers Pte Ltd	43 Joo Koon Circle	t	2026-07-24 15:15:51.944859+00
SIN_001	SIN	Sin Hong Hardware Pte Ltd	3 Kian Teck Crescent	t	2026-07-24 15:15:51.944859+00
SINH_001	SINH	Sin Hong Poh Metal Trading	59 Tampines Industrial Ave	t	2026-07-24 15:15:51.944859+00
SIND_001	SIND	Sindac Cleaning Services Pte Ltd	1H Pine Grove, Pine Grove Condo	t	2026-07-24 15:15:51.944859+00
SIND_002	SIND	Sindac Cleaning Services Pte Ltd	20 Woodlands Crescent, Northoaks Condo	t	2026-07-24 15:15:51.944859+00
SLS_001	SLS	SLS	No. 9 Tuas South Avenue 19, #01-99	t	2026-07-24 15:15:51.944859+00
SLS_002	SLS	SLS	VSMC site office Gate 3	t	2026-07-24 15:15:51.944859+00
SNI_001	SNI	Snip Avenue Holdings	9 Changi South Street 3, loading bay	t	2026-07-24 15:15:51.944859+00
SPR_001	SPR	Springlife Maintenance Service Pte Ltd	21 Ang Mo Kio Ave 9, Nuovo Condo	t	2026-07-24 15:15:51.944859+00
SPR_002	SPR	Springlife Maintenance Service Pte Ltd	464 Corporation Road, Parc Vista Condo	t	2026-07-24 15:15:51.944859+00
SPR_003	SPR	Springlife Maintenance Service Pte Ltd	88 Flora Road, Edelweiss Park Condo	t	2026-07-24 15:15:51.944859+00
STX_001	STX	ST	6 Tuas South Street 15	t	2026-07-24 15:15:51.944859+00
STX_002	STX	ST	Benoi	t	2026-07-24 15:15:51.944859+00
STX_003	STX	ST	Gul	t	2026-07-24 15:15:51.944859+00
STA_001	STA	Stamford Tyres	19 Lok Yang Way	t	2026-07-24 15:15:51.944859+00
STS_001	STS	STSM	15 Pasir Ris Street 21	t	2026-07-24 15:15:51.944859+00
STS_002	STS	STSM	47 Hougang Avenue 1	t	2026-07-24 15:15:51.944859+00
STS_003	STS	STSM	Blk 15 Toa Payoh Lorong 7	t	2026-07-24 15:15:51.944859+00
STS_004	STS	STSM	Blk 61 Jurong West Street 65, Jurong West Secondary School (JWSS)	t	2026-07-24 15:15:51.944859+00
STS_005	STS	STSM	Blk 64 Lorong 5 Toa Payoh - Lot no. 24	t	2026-07-24 15:15:51.944859+00
STS_006	STS	STSM	Blk 698 West Coast Road, Commonwealth Secondary School (CWSS)	t	2026-07-24 15:15:51.944859+00
SUM_001	SUM	Sumber Indah Pte Ltd	1 Tuas View Close	t	2026-07-24 15:15:51.944859+00
SUN_001	SUN	Sun City Maintenance Pte Ltd	300 Mandai Road, Mandai Crematorium and Columbarium	t	2026-07-24 15:15:51.944859+00
SUN_002	SUN	Sun City Maintenance Pte Ltd	55 Changi South Ave 1	t	2026-07-24 15:15:51.944859+00
SUN_003	SUN	Sun City Maintenance Pte Ltd	SUTD Building 2, 8 Somapah Road, loading bay	t	2026-07-24 15:15:51.944859+00
SUN_004	SUN	Sun City Maintenance Pte Ltd	SUTD Building 3, 8 somapah Road , with access via the Changi Street carpark entrance	t	2026-07-24 15:15:51.944859+00
SUN_005	SUN	Sun City Maintenance Pte Ltd	Yishun Columbarium, 569 Yishun Ring Road	t	2026-07-24 15:15:51.944859+00
SYS_001	SYS	Sys-Mac Automation Engineering Pte Ltd	2 Woodlands Sector 1, #05-18	t	2026-07-24 15:15:51.944859+00
SYST_001	SYST	System Foundation Pte Ltd	21A Tuas South Place	t	2026-07-24 15:15:51.944859+00
SYST_002	SYST	System Foundation Pte Ltd	45 Tuas View Place	t	2026-07-24 15:15:51.944859+00
TRE_001	TRE	T3 Reources Pte Ltd	16 Gul Street 3	t	2026-07-24 15:15:51.944859+00
TAI_001	TAI	Tai Lee Tong	No 11, Lorong 21A Geylang	t	2026-07-24 15:15:51.944859+00
TECH_001	TECH	Technigroup Far East Pte Ltd	Outram Road	t	2026-07-24 15:15:51.944859+00
TEC_001	TEC	Technicair Singapore Services Pte Ltd	16 Jalan Tan Tock Seng	t	2026-07-24 15:15:51.944859+00
TECK_001	TECK	Teck Sang Pte Ltd	30A Quality Road	t	2026-07-24 15:15:51.944859+00
TOH_001	TOH	Toh Ban Seng	Seletar Westlink LP 103	t	2026-07-24 15:15:51.944859+00
TON_001	TON	Tong Carriage (S) Pte Ltd	30 Toh Guan Road	t	2026-07-24 15:15:51.944859+00
TONG_001	TONG	Tong Hock Pte Ltd	10 Pandan Crescent	t	2026-07-24 15:15:51.944859+00
TONG_002	TONG	Tong Hock Pte Ltd	1206A East Coast Park	t	2026-07-24 15:15:51.944859+00
TONG_003	TONG	Tong Hock Pte Ltd	14 Tractor Road	t	2026-07-24 15:15:51.944859+00
TONG_004	TONG	Tong Hock Pte Ltd	19 Tuas Street	t	2026-07-24 15:15:51.944859+00
TONG_005	TONG	Tong Hock Pte Ltd	2 Peach Garden, Peach Garden condo	t	2026-07-24 15:15:51.944859+00
TONG_006	TONG	Tong Hock Pte Ltd	2 Pioneer Sector 1	t	2026-07-24 15:15:51.944859+00
TONG_007	TONG	Tong Hock Pte Ltd	58 Woodlands Drive 16, La Casa Condo	t	2026-07-24 15:15:51.944859+00
TONG_008	TONG	Tong Hock Pte Ltd	7 Tractor Road	t	2026-07-24 15:15:51.944859+00
TONG_009	TONG	Tong Hock Pte Ltd	1 Woodlands Terrace	t	2026-07-24 15:15:51.944859+00
TOP_001	TOP	Top Star Builder Pte Ltd	50 Playfair road	t	2026-07-24 15:15:51.944859+00
TST_001	TST	TSTL	19 Tuas Street	t	2026-07-24 15:15:51.944859+00
TRA_001	TRA	Tracebuild	1 Woodlands Street 31, Fu Chun Community Club	t	2026-07-24 15:15:51.944859+00
URB_001	URB	Urban Group Pte Ltd	200 Netheravon Road	t	2026-07-24 15:15:51.944859+00
WAH_001	WAH	Wah & Hua Pte Ltd	17 Kallang Junction, #01-01, Singapore 339274	t	2026-07-24 15:15:51.944859+00
WAH_002	WAH	Wah & Hua Pte Ltd	19 Loyang Way	t	2026-07-24 15:15:51.944859+00
WAH_003	WAH	Wah & Hua Pte Ltd	22 Woodlands Link	t	2026-07-24 15:15:51.944859+00
WAH_004	WAH	Wah & Hua Pte Ltd	221 Kallang Bahru Lion Building	t	2026-07-24 15:15:51.944859+00
WAH_005	WAH	Wah & Hua Pte Ltd	30 Kerong Lane	t	2026-07-24 15:15:51.944859+00
WAH_006	WAH	Wah & Hua Pte Ltd	76 Sungei Tengah Road	t	2026-07-24 15:15:51.944859+00
WAH_007	WAH	Wah & Hua Pte Ltd	980 Upper Changi Road North Singapore 507708(Prison HQ)	t	2026-07-24 15:15:51.944859+00
WEB_001	WEB	WeBuild	120 Hillview Ave	t	2026-07-24 15:15:51.944859+00
WIK_001	WIK	WIKA Instrumentation Pte Ltd	13 Kian Teck Crescent	t	2026-07-24 15:15:51.944859+00
WIL_001	WIL	Wilkie Development Pte Ltd	12 New Industrial Road	t	2026-07-24 15:15:51.944859+00
WOR_001	WOR	World of Wood Pte Ltd	35 Tannery Road, #01-07, Ruby Industrial Complex	t	2026-07-24 15:15:51.944859+00
WRA_001	WRA	W''Ray Construction Pte Ltd	22 Scotts Road, Goodwood Park Hotel	t	2026-07-24 15:15:51.944859+00
WRA_002	WRA	W''Ray Construction Pte Ltd	25 Tuas Ave 4	t	2026-07-24 15:15:51.944859+00
ENGI_016	ENGI	Engie Services Singapore Pte Ltd	1 Cove Grove	t	2026-07-24 15:15:51.944859+00
ENGI_017	ENGI	Engie Services Singapore Pte Ltd	1 Media Link	t	2026-07-24 15:15:51.944859+00
ENGI_018	ENGI	Engie Services Singapore Pte Ltd	30 Changi North Cresent	t	2026-07-24 15:15:51.944859+00
GLO_001	GLO	Glory SIP Pte Ltd	50 Tuas Avenue 11, 02-05	t	2026-07-24 15:15:51.944859+00
LIR_004	LIR	Lirich	Beejoo	t	2026-07-24 15:15:51.944859+00
LIR_005	LIR	Lirich	NEA Tuas	t	2026-07-24 15:15:51.944859+00
PIL_001	PIL	Pacific International Lines	PSA berths - vessel operations	t	2026-07-24 15:15:51.944859+00
\.


--
-- Data for Name: vehicles; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.vehicles (vehicle_id, vtype, active) FROM stdin;
XE5457Y	\N	t
XE6221D	\N	t
XE4491D	\N	t
XE8496	\N	t
XE6204D	\N	t
XE7116D	\N	t
XE7126P	\N	t
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
344f6e6e-4b8e-4028-a546-2ce9315490ee	do-photos	mrzbaz6l-BINOUT-43-1.jpg	\N	2026-07-24 19:07:17.439235+00	2026-07-24 19:07:17.439235+00	2026-07-24 19:07:17.439235+00	{"eTag": "\\"e6de1330bcd5d161d095a6545f8fb7e0\\"", "size": 126487, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-24T19:07:18.000Z", "contentLength": 126487, "httpStatusCode": 200}	2b3ae022-6d76-4be9-a2e8-55dcabf5da4d	\N	{}
94cd0f1c-8f1b-4492-8caa-508e1f1627bb	do-photos	mrzbazaa-DO-43-1.jpg	\N	2026-07-24 19:07:17.568546+00	2026-07-24 19:07:17.568546+00	2026-07-24 19:07:17.568546+00	{"eTag": "\\"e6de1330bcd5d161d095a6545f8fb7e0\\"", "size": 126487, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-24T19:07:18.000Z", "contentLength": 126487, "httpStatusCode": 200}	ca6af05e-d355-4002-9ed4-5c6580d813f7	\N	{}
6da9ddc2-fb74-49ef-8808-d8db60c5f29c	do-photos	mrzcgqcw-DO-44-1.jpg	\N	2026-07-24 19:39:45.618481+00	2026-07-24 19:39:45.618481+00	2026-07-24 19:39:45.618481+00	{"eTag": "\\"e6de1330bcd5d161d095a6545f8fb7e0\\"", "size": 126487, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2026-07-24T19:39:46.000Z", "contentLength": 126487, "httpStatusCode": 200}	12b38056-ecb5-4f45-9217-d36b46466160	\N	{}
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
-- Name: adjustments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.adjustments_id_seq', 10, true);


--
-- Name: factors_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.factors_id_seq', 7, true);


--
-- Name: fuel_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.fuel_log_id_seq', 1, false);


--
-- Name: maintenance_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.maintenance_id_seq', 1, false);


--
-- Name: odometer_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.odometer_log_id_seq', 1, false);


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

SELECT pg_catalog.setval('public.rate_card_id_seq', 641, true);


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

\unrestrict Hf1bXP79njgH7Yx1frOa8HcRwVVHPg5Rgde3TkUzUPikv6tyH6HZ9l7iiF8xZLt

