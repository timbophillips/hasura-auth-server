--
-- PostgreSQL database dump
--

-- Dumped from database version 12.5 (Ubuntu 12.5-1.pgdg16.04+1)
-- Dumped by pg_dump version 12.1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: hdb_catalog; Type: SCHEMA; Schema: -; Owner: cvewqhxnukolnw
--

CREATE SCHEMA "hdb_catalog";


ALTER SCHEMA hdb_catalog OWNER TO cvewqhxnukolnw;

--
-- Name: hdb_pro_catalog; Type: SCHEMA; Schema: -; Owner: cvewqhxnukolnw
--

CREATE SCHEMA "hdb_pro_catalog";


ALTER SCHEMA hdb_pro_catalog OWNER TO cvewqhxnukolnw;

--
-- Name: hdb_views; Type: SCHEMA; Schema: -; Owner: cvewqhxnukolnw
--

CREATE SCHEMA "hdb_views";


ALTER SCHEMA hdb_views OWNER TO cvewqhxnukolnw;

--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "public";


--
-- Name: EXTENSION "pgcrypto"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "pgcrypto" IS 'cryptographic functions';


--
-- Name: check_violation("text"); Type: FUNCTION; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

CREATE FUNCTION "hdb_catalog"."check_violation"("msg" "text") RETURNS boolean
    LANGUAGE "plpgsql"
    AS $$
  BEGIN
    RAISE check_violation USING message=msg;
  END;
$$;


ALTER FUNCTION "hdb_catalog"."check_violation"("msg" "text") OWNER TO cvewqhxnukolnw;

--
-- Name: event_trigger_table_name_update(); Type: FUNCTION; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

CREATE FUNCTION "hdb_catalog"."event_trigger_table_name_update"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  IF (NEW.table_schema, NEW.table_name) <> (OLD.table_schema, OLD.table_name)  THEN
    UPDATE hdb_catalog.event_triggers
    SET schema_name = NEW.table_schema, table_name = NEW.table_name
    WHERE (schema_name, table_name) = (OLD.table_schema, OLD.table_name);
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION "hdb_catalog"."event_trigger_table_name_update"() OWNER TO cvewqhxnukolnw;

--
-- Name: hdb_schema_update_event_notifier(); Type: FUNCTION; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

CREATE FUNCTION "hdb_catalog"."hdb_schema_update_event_notifier"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
  DECLARE
    instance_id uuid;
    occurred_at timestamptz;
    invalidations json;
    curr_rec record;
  BEGIN
    instance_id = NEW.instance_id;
    occurred_at = NEW.occurred_at;
    invalidations = NEW.invalidations;
    PERFORM pg_notify('hasura_schema_update', json_build_object(
      'instance_id', instance_id,
      'occurred_at', occurred_at,
      'invalidations', invalidations
      )::text);
    RETURN curr_rec;
  END;
$$;


ALTER FUNCTION "hdb_catalog"."hdb_schema_update_event_notifier"() OWNER TO cvewqhxnukolnw;

--
-- Name: inject_table_defaults("text", "text", "text", "text"); Type: FUNCTION; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

CREATE FUNCTION "hdb_catalog"."inject_table_defaults"("view_schema" "text", "view_name" "text", "tab_schema" "text", "tab_name" "text") RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
    DECLARE
        r RECORD;
    BEGIN
      FOR r IN SELECT column_name, column_default FROM information_schema.columns WHERE table_schema = tab_schema AND table_name = tab_name AND column_default IS NOT NULL LOOP
          EXECUTE format('ALTER VIEW %I.%I ALTER COLUMN %I SET DEFAULT %s;', view_schema, view_name, r.column_name, r.column_default);
      END LOOP;
    END;
$$;


ALTER FUNCTION "hdb_catalog"."inject_table_defaults"("view_schema" "text", "view_name" "text", "tab_schema" "text", "tab_name" "text") OWNER TO cvewqhxnukolnw;

--
-- Name: insert_event_log("text", "text", "text", "text", "json"); Type: FUNCTION; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

CREATE FUNCTION "hdb_catalog"."insert_event_log"("schema_name" "text", "table_name" "text", "trigger_name" "text", "op" "text", "row_data" "json") RETURNS "text"
    LANGUAGE "plpgsql"
    AS $$
  DECLARE
    id text;
    payload json;
    session_variables json;
    server_version_num int;
    trace_context json;
  BEGIN
    id := gen_random_uuid();
    server_version_num := current_setting('server_version_num');
    IF server_version_num >= 90600 THEN
      session_variables := current_setting('hasura.user', 't');
      trace_context := current_setting('hasura.tracecontext', 't');
    ELSE
      BEGIN
        session_variables := current_setting('hasura.user');
      EXCEPTION WHEN OTHERS THEN
                  session_variables := NULL;
      END;
      BEGIN
        trace_context := current_setting('hasura.tracecontext');
      EXCEPTION WHEN OTHERS THEN
        trace_context := NULL;
      END;
    END IF;
    payload := json_build_object(
      'op', op,
      'data', row_data,
      'session_variables', session_variables,
      'trace_context', trace_context
    );
    INSERT INTO hdb_catalog.event_log
                (id, schema_name, table_name, trigger_name, payload)
    VALUES
    (id, schema_name, table_name, trigger_name, payload);
    RETURN id;
  END;
$$;


ALTER FUNCTION "hdb_catalog"."insert_event_log"("schema_name" "text", "table_name" "text", "trigger_name" "text", "op" "text", "row_data" "json") OWNER TO cvewqhxnukolnw;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: event_invocation_logs; Type: TABLE; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

CREATE TABLE "hdb_catalog"."event_invocation_logs" (
    "id" "text" DEFAULT "public"."gen_random_uuid"() NOT NULL,
    "event_id" "text",
    "status" integer,
    "request" "json",
    "response" "json",
    "created_at" timestamp without time zone DEFAULT "now"()
);


ALTER TABLE hdb_catalog.event_invocation_logs OWNER TO cvewqhxnukolnw;

--
-- Name: event_log; Type: TABLE; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

CREATE TABLE "hdb_catalog"."event_log" (
    "id" "text" DEFAULT "public"."gen_random_uuid"() NOT NULL,
    "schema_name" "text" NOT NULL,
    "table_name" "text" NOT NULL,
    "trigger_name" "text" NOT NULL,
    "payload" "jsonb" NOT NULL,
    "delivered" boolean DEFAULT false NOT NULL,
    "error" boolean DEFAULT false NOT NULL,
    "tries" integer DEFAULT 0 NOT NULL,
    "created_at" timestamp without time zone DEFAULT "now"(),
    "locked" boolean DEFAULT false NOT NULL,
    "next_retry_at" timestamp without time zone,
    "archived" boolean DEFAULT false NOT NULL
);


ALTER TABLE hdb_catalog.event_log OWNER TO cvewqhxnukolnw;

--
-- Name: event_triggers; Type: TABLE; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

CREATE TABLE "hdb_catalog"."event_triggers" (
    "name" "text" NOT NULL,
    "type" "text" NOT NULL,
    "schema_name" "text" NOT NULL,
    "table_name" "text" NOT NULL,
    "configuration" "json",
    "comment" "text"
);


ALTER TABLE hdb_catalog.event_triggers OWNER TO cvewqhxnukolnw;

--
-- Name: hdb_action; Type: TABLE; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

CREATE TABLE "hdb_catalog"."hdb_action" (
    "action_name" "text" NOT NULL,
    "action_defn" "jsonb" NOT NULL,
    "comment" "text",
    "is_system_defined" boolean DEFAULT false
);


ALTER TABLE hdb_catalog.hdb_action OWNER TO cvewqhxnukolnw;

--
-- Name: hdb_action_log; Type: TABLE; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

CREATE TABLE "hdb_catalog"."hdb_action_log" (
    "id" "uuid" DEFAULT "public"."gen_random_uuid"() NOT NULL,
    "action_name" "text",
    "input_payload" "jsonb" NOT NULL,
    "request_headers" "jsonb" NOT NULL,
    "session_variables" "jsonb" NOT NULL,
    "response_payload" "jsonb",
    "errors" "jsonb",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "response_received_at" timestamp with time zone,
    "status" "text" NOT NULL,
    CONSTRAINT "hdb_action_log_status_check" CHECK (("status" = ANY (ARRAY['created'::"text", 'processing'::"text", 'completed'::"text", 'error'::"text"])))
);


ALTER TABLE hdb_catalog.hdb_action_log OWNER TO cvewqhxnukolnw;

--
-- Name: hdb_action_permission; Type: TABLE; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

CREATE TABLE "hdb_catalog"."hdb_action_permission" (
    "action_name" "text" NOT NULL,
    "role_name" "text" NOT NULL,
    "definition" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "comment" "text"
);


ALTER TABLE hdb_catalog.hdb_action_permission OWNER TO cvewqhxnukolnw;

--
-- Name: hdb_allowlist; Type: TABLE; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

CREATE TABLE "hdb_catalog"."hdb_allowlist" (
    "collection_name" "text"
);


ALTER TABLE hdb_catalog.hdb_allowlist OWNER TO cvewqhxnukolnw;

--
-- Name: hdb_check_constraint; Type: VIEW; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

CREATE VIEW "hdb_catalog"."hdb_check_constraint" AS
 SELECT ("n"."nspname")::"text" AS "table_schema",
    ("ct"."relname")::"text" AS "table_name",
    ("r"."conname")::"text" AS "constraint_name",
    "pg_get_constraintdef"("r"."oid", true) AS "check"
   FROM (("pg_constraint" "r"
     JOIN "pg_class" "ct" ON (("r"."conrelid" = "ct"."oid")))
     JOIN "pg_namespace" "n" ON (("ct"."relnamespace" = "n"."oid")))
  WHERE ("r"."contype" = 'c'::"char");


ALTER TABLE hdb_catalog.hdb_check_constraint OWNER TO cvewqhxnukolnw;

--
-- Name: hdb_computed_field; Type: TABLE; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

CREATE TABLE "hdb_catalog"."hdb_computed_field" (
    "table_schema" "text" NOT NULL,
    "table_name" "text" NOT NULL,
    "computed_field_name" "text" NOT NULL,
    "definition" "jsonb" NOT NULL,
    "comment" "text"
);


ALTER TABLE hdb_catalog.hdb_computed_field OWNER TO cvewqhxnukolnw;

--
-- Name: hdb_computed_field_function; Type: VIEW; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

CREATE VIEW "hdb_catalog"."hdb_computed_field_function" AS
 SELECT "hdb_computed_field"."table_schema",
    "hdb_computed_field"."table_name",
    "hdb_computed_field"."computed_field_name",
        CASE
            WHEN ((("hdb_computed_field"."definition" -> 'function'::"text") ->> 'name'::"text") IS NULL) THEN ("hdb_computed_field"."definition" ->> 'function'::"text")
            ELSE (("hdb_computed_field"."definition" -> 'function'::"text") ->> 'name'::"text")
        END AS "function_name",
        CASE
            WHEN ((("hdb_computed_field"."definition" -> 'function'::"text") ->> 'schema'::"text") IS NULL) THEN 'public'::"text"
            ELSE (("hdb_computed_field"."definition" -> 'function'::"text") ->> 'schema'::"text")
        END AS "function_schema"
   FROM "hdb_catalog"."hdb_computed_field";


ALTER TABLE hdb_catalog.hdb_computed_field_function OWNER TO cvewqhxnukolnw;

--
-- Name: hdb_cron_event_invocation_logs; Type: TABLE; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

CREATE TABLE "hdb_catalog"."hdb_cron_event_invocation_logs" (
    "id" "text" DEFAULT "public"."gen_random_uuid"() NOT NULL,
    "event_id" "text",
    "status" integer,
    "request" "json",
    "response" "json",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE hdb_catalog.hdb_cron_event_invocation_logs OWNER TO cvewqhxnukolnw;

--
-- Name: hdb_cron_events; Type: TABLE; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

CREATE TABLE "hdb_catalog"."hdb_cron_events" (
    "id" "text" DEFAULT "public"."gen_random_uuid"() NOT NULL,
    "trigger_name" "text" NOT NULL,
    "scheduled_time" timestamp with time zone NOT NULL,
    "status" "text" DEFAULT 'scheduled'::"text" NOT NULL,
    "tries" integer DEFAULT 0 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "next_retry_at" timestamp with time zone,
    CONSTRAINT "valid_status" CHECK (("status" = ANY (ARRAY['scheduled'::"text", 'locked'::"text", 'delivered'::"text", 'error'::"text", 'dead'::"text"])))
);


ALTER TABLE hdb_catalog.hdb_cron_events OWNER TO cvewqhxnukolnw;

--
-- Name: hdb_cron_triggers; Type: TABLE; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

CREATE TABLE "hdb_catalog"."hdb_cron_triggers" (
    "name" "text" NOT NULL,
    "webhook_conf" "json" NOT NULL,
    "cron_schedule" "text" NOT NULL,
    "payload" "json",
    "retry_conf" "json",
    "header_conf" "json",
    "include_in_metadata" boolean DEFAULT false NOT NULL,
    "comment" "text"
);


ALTER TABLE hdb_catalog.hdb_cron_triggers OWNER TO cvewqhxnukolnw;

--
-- Name: hdb_cron_events_stats; Type: VIEW; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

CREATE VIEW "hdb_catalog"."hdb_cron_events_stats" AS
 SELECT "ct"."name",
    COALESCE("ce"."upcoming_events_count", (0)::bigint) AS "upcoming_events_count",
    COALESCE("ce"."max_scheduled_time", "now"()) AS "max_scheduled_time"
   FROM ("hdb_catalog"."hdb_cron_triggers" "ct"
     LEFT JOIN ( SELECT "hdb_cron_events"."trigger_name",
            "count"(*) AS "upcoming_events_count",
            "max"("hdb_cron_events"."scheduled_time") AS "max_scheduled_time"
           FROM "hdb_catalog"."hdb_cron_events"
          WHERE (("hdb_cron_events"."tries" = 0) AND ("hdb_cron_events"."status" = 'scheduled'::"text"))
          GROUP BY "hdb_cron_events"."trigger_name") "ce" ON (("ct"."name" = "ce"."trigger_name")));


ALTER TABLE hdb_catalog.hdb_cron_events_stats OWNER TO cvewqhxnukolnw;

--
-- Name: hdb_custom_types; Type: TABLE; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

CREATE TABLE "hdb_catalog"."hdb_custom_types" (
    "custom_types" "jsonb" NOT NULL
);


ALTER TABLE hdb_catalog.hdb_custom_types OWNER TO cvewqhxnukolnw;

--
-- Name: hdb_foreign_key_constraint; Type: VIEW; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

CREATE VIEW "hdb_catalog"."hdb_foreign_key_constraint" AS
 SELECT ("q"."table_schema")::"text" AS "table_schema",
    ("q"."table_name")::"text" AS "table_name",
    ("q"."constraint_name")::"text" AS "constraint_name",
    ("min"("q"."constraint_oid"))::integer AS "constraint_oid",
    "min"(("q"."ref_table_table_schema")::"text") AS "ref_table_table_schema",
    "min"(("q"."ref_table")::"text") AS "ref_table",
    "json_object_agg"("ac"."attname", "afc"."attname") AS "column_mapping",
    "min"(("q"."confupdtype")::"text") AS "on_update",
    "min"(("q"."confdeltype")::"text") AS "on_delete",
    "json_agg"("ac"."attname") AS "columns",
    "json_agg"("afc"."attname") AS "ref_columns"
   FROM ((( SELECT "ctn"."nspname" AS "table_schema",
            "ct"."relname" AS "table_name",
            "r"."conrelid" AS "table_id",
            "r"."conname" AS "constraint_name",
            "r"."oid" AS "constraint_oid",
            "cftn"."nspname" AS "ref_table_table_schema",
            "cft"."relname" AS "ref_table",
            "r"."confrelid" AS "ref_table_id",
            "r"."confupdtype",
            "r"."confdeltype",
            "unnest"("r"."conkey") AS "column_id",
            "unnest"("r"."confkey") AS "ref_column_id"
           FROM (((("pg_constraint" "r"
             JOIN "pg_class" "ct" ON (("r"."conrelid" = "ct"."oid")))
             JOIN "pg_namespace" "ctn" ON (("ct"."relnamespace" = "ctn"."oid")))
             JOIN "pg_class" "cft" ON (("r"."confrelid" = "cft"."oid")))
             JOIN "pg_namespace" "cftn" ON (("cft"."relnamespace" = "cftn"."oid")))
          WHERE ("r"."contype" = 'f'::"char")) "q"
     JOIN "pg_attribute" "ac" ON ((("q"."column_id" = "ac"."attnum") AND ("q"."table_id" = "ac"."attrelid"))))
     JOIN "pg_attribute" "afc" ON ((("q"."ref_column_id" = "afc"."attnum") AND ("q"."ref_table_id" = "afc"."attrelid"))))
  GROUP BY "q"."table_schema", "q"."table_name", "q"."constraint_name";


ALTER TABLE hdb_catalog.hdb_foreign_key_constraint OWNER TO cvewqhxnukolnw;

--
-- Name: hdb_function; Type: TABLE; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

CREATE TABLE "hdb_catalog"."hdb_function" (
    "function_schema" "text" NOT NULL,
    "function_name" "text" NOT NULL,
    "configuration" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "is_system_defined" boolean DEFAULT false
);


ALTER TABLE hdb_catalog.hdb_function OWNER TO cvewqhxnukolnw;

--
-- Name: hdb_function_agg; Type: VIEW; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

CREATE VIEW "hdb_catalog"."hdb_function_agg" AS
 SELECT ("p"."proname")::"text" AS "function_name",
    ("pn"."nspname")::"text" AS "function_schema",
    "pd"."description",
        CASE
            WHEN ("p"."provariadic" = (0)::"oid") THEN false
            ELSE true
        END AS "has_variadic",
        CASE
            WHEN (("p"."provolatile")::"text" = ('i'::character(1))::"text") THEN 'IMMUTABLE'::"text"
            WHEN (("p"."provolatile")::"text" = ('s'::character(1))::"text") THEN 'STABLE'::"text"
            WHEN (("p"."provolatile")::"text" = ('v'::character(1))::"text") THEN 'VOLATILE'::"text"
            ELSE NULL::"text"
        END AS "function_type",
    "pg_get_functiondef"("p"."oid") AS "function_definition",
    ("rtn"."nspname")::"text" AS "return_type_schema",
    ("rt"."typname")::"text" AS "return_type_name",
    ("rt"."typtype")::"text" AS "return_type_type",
    "p"."proretset" AS "returns_set",
    ( SELECT COALESCE("json_agg"("json_build_object"('schema', "q"."schema", 'name', "q"."name", 'type', "q"."type")), '[]'::"json") AS "coalesce"
           FROM ( SELECT "pt"."typname" AS "name",
                    "pns"."nspname" AS "schema",
                    "pt"."typtype" AS "type",
                    "pat"."ordinality"
                   FROM (("unnest"(COALESCE("p"."proallargtypes", ("p"."proargtypes")::"oid"[])) WITH ORDINALITY "pat"("oid", "ordinality")
                     LEFT JOIN "pg_type" "pt" ON (("pt"."oid" = "pat"."oid")))
                     LEFT JOIN "pg_namespace" "pns" ON (("pt"."typnamespace" = "pns"."oid")))
                  ORDER BY "pat"."ordinality") "q") AS "input_arg_types",
    "to_json"(COALESCE("p"."proargnames", ARRAY[]::"text"[])) AS "input_arg_names",
    "p"."pronargdefaults" AS "default_args",
    ("p"."oid")::integer AS "function_oid"
   FROM (((("pg_proc" "p"
     JOIN "pg_namespace" "pn" ON (("pn"."oid" = "p"."pronamespace")))
     JOIN "pg_type" "rt" ON (("rt"."oid" = "p"."prorettype")))
     JOIN "pg_namespace" "rtn" ON (("rtn"."oid" = "rt"."typnamespace")))
     LEFT JOIN "pg_description" "pd" ON (("p"."oid" = "pd"."objoid")))
  WHERE ((("pn"."nspname")::"text" !~~ 'pg_%'::"text") AND (("pn"."nspname")::"text" <> ALL (ARRAY['information_schema'::"text", 'hdb_catalog'::"text", 'hdb_views'::"text"])) AND (NOT (EXISTS ( SELECT 1
           FROM "pg_aggregate"
          WHERE (("pg_aggregate"."aggfnoid")::"oid" = "p"."oid")))));


ALTER TABLE hdb_catalog.hdb_function_agg OWNER TO cvewqhxnukolnw;

--
-- Name: hdb_function_info_agg; Type: VIEW; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

CREATE VIEW "hdb_catalog"."hdb_function_info_agg" AS
 SELECT "hdb_function_agg"."function_name",
    "hdb_function_agg"."function_schema",
    "row_to_json"(( SELECT "e".*::"record" AS "e"
           FROM ( SELECT "hdb_function_agg"."description",
                    "hdb_function_agg"."has_variadic",
                    "hdb_function_agg"."function_type",
                    "hdb_function_agg"."return_type_schema",
                    "hdb_function_agg"."return_type_name",
                    "hdb_function_agg"."return_type_type",
                    "hdb_function_agg"."returns_set",
                    "hdb_function_agg"."input_arg_types",
                    "hdb_function_agg"."input_arg_names",
                    "hdb_function_agg"."default_args",
                    ((EXISTS ( SELECT 1
                           FROM "information_schema"."tables"
                          WHERE ((("tables"."table_schema")::"name" = "hdb_function_agg"."return_type_schema") AND (("tables"."table_name")::"name" = "hdb_function_agg"."return_type_name")))) OR (EXISTS ( SELECT 1
                           FROM "pg_matviews"
                          WHERE (("pg_matviews"."schemaname" = "hdb_function_agg"."return_type_schema") AND ("pg_matviews"."matviewname" = "hdb_function_agg"."return_type_name"))))) AS "returns_table") "e")) AS "function_info"
   FROM "hdb_catalog"."hdb_function_agg";


ALTER TABLE hdb_catalog.hdb_function_info_agg OWNER TO cvewqhxnukolnw;

--
-- Name: hdb_permission; Type: TABLE; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

CREATE TABLE "hdb_catalog"."hdb_permission" (
    "table_schema" "name" NOT NULL,
    "table_name" "name" NOT NULL,
    "role_name" "text" NOT NULL,
    "perm_type" "text" NOT NULL,
    "perm_def" "jsonb" NOT NULL,
    "comment" "text",
    "is_system_defined" boolean DEFAULT false,
    CONSTRAINT "hdb_permission_perm_type_check" CHECK (("perm_type" = ANY (ARRAY['insert'::"text", 'select'::"text", 'update'::"text", 'delete'::"text"])))
);


ALTER TABLE hdb_catalog.hdb_permission OWNER TO cvewqhxnukolnw;

--
-- Name: hdb_permission_agg; Type: VIEW; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

CREATE VIEW "hdb_catalog"."hdb_permission_agg" AS
 SELECT "hdb_permission"."table_schema",
    "hdb_permission"."table_name",
    "hdb_permission"."role_name",
    "json_object_agg"("hdb_permission"."perm_type", "hdb_permission"."perm_def") AS "permissions"
   FROM "hdb_catalog"."hdb_permission"
  GROUP BY "hdb_permission"."table_schema", "hdb_permission"."table_name", "hdb_permission"."role_name";


ALTER TABLE hdb_catalog.hdb_permission_agg OWNER TO cvewqhxnukolnw;

--
-- Name: hdb_primary_key; Type: VIEW; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

CREATE VIEW "hdb_catalog"."hdb_primary_key" AS
 SELECT "tc"."table_schema",
    "tc"."table_name",
    "tc"."constraint_name",
    "json_agg"("constraint_column_usage"."column_name") AS "columns"
   FROM ("information_schema"."table_constraints" "tc"
     JOIN ( SELECT "x"."tblschema" AS "table_schema",
            "x"."tblname" AS "table_name",
            "x"."colname" AS "column_name",
            "x"."cstrname" AS "constraint_name"
           FROM ( SELECT DISTINCT "nr"."nspname",
                    "r"."relname",
                    "a"."attname",
                    "c"."conname"
                   FROM "pg_namespace" "nr",
                    "pg_class" "r",
                    "pg_attribute" "a",
                    "pg_depend" "d",
                    "pg_namespace" "nc",
                    "pg_constraint" "c"
                  WHERE (("nr"."oid" = "r"."relnamespace") AND ("r"."oid" = "a"."attrelid") AND ("d"."refclassid" = ('"pg_class"'::"regclass")::"oid") AND ("d"."refobjid" = "r"."oid") AND ("d"."refobjsubid" = "a"."attnum") AND ("d"."classid" = ('"pg_constraint"'::"regclass")::"oid") AND ("d"."objid" = "c"."oid") AND ("c"."connamespace" = "nc"."oid") AND ("c"."contype" = 'c'::"char") AND ("r"."relkind" = ANY (ARRAY['r'::"char", 'p'::"char"])) AND (NOT "a"."attisdropped"))
                UNION ALL
                 SELECT "nr"."nspname",
                    "r"."relname",
                    "a"."attname",
                    "c"."conname"
                   FROM "pg_namespace" "nr",
                    "pg_class" "r",
                    "pg_attribute" "a",
                    "pg_namespace" "nc",
                    "pg_constraint" "c"
                  WHERE (("nr"."oid" = "r"."relnamespace") AND ("r"."oid" = "a"."attrelid") AND ("nc"."oid" = "c"."connamespace") AND ("r"."oid" =
                        CASE "c"."contype"
                            WHEN 'f'::"char" THEN "c"."confrelid"
                            ELSE "c"."conrelid"
                        END) AND ("a"."attnum" = ANY (
                        CASE "c"."contype"
                            WHEN 'f'::"char" THEN "c"."confkey"
                            ELSE "c"."conkey"
                        END)) AND (NOT "a"."attisdropped") AND ("c"."contype" = ANY (ARRAY['p'::"char", 'u'::"char", 'f'::"char"])) AND ("r"."relkind" = ANY (ARRAY['r'::"char", 'p'::"char"])))) "x"("tblschema", "tblname", "colname", "cstrname")) "constraint_column_usage" ON (((("tc"."constraint_name")::"text" = ("constraint_column_usage"."constraint_name")::"text") AND (("tc"."table_schema")::"text" = ("constraint_column_usage"."table_schema")::"text") AND (("tc"."table_name")::"text" = ("constraint_column_usage"."table_name")::"text"))))
  WHERE (("tc"."constraint_type")::"text" = 'PRIMARY KEY'::"text")
  GROUP BY "tc"."table_schema", "tc"."table_name", "tc"."constraint_name";


ALTER TABLE hdb_catalog.hdb_primary_key OWNER TO cvewqhxnukolnw;

--
-- Name: hdb_query_collection; Type: TABLE; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

CREATE TABLE "hdb_catalog"."hdb_query_collection" (
    "collection_name" "text" NOT NULL,
    "collection_defn" "jsonb" NOT NULL,
    "comment" "text",
    "is_system_defined" boolean DEFAULT false
);


ALTER TABLE hdb_catalog.hdb_query_collection OWNER TO cvewqhxnukolnw;

--
-- Name: hdb_relationship; Type: TABLE; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

CREATE TABLE "hdb_catalog"."hdb_relationship" (
    "table_schema" "name" NOT NULL,
    "table_name" "name" NOT NULL,
    "rel_name" "text" NOT NULL,
    "rel_type" "text",
    "rel_def" "jsonb" NOT NULL,
    "comment" "text",
    "is_system_defined" boolean DEFAULT false,
    CONSTRAINT "hdb_relationship_rel_type_check" CHECK (("rel_type" = ANY (ARRAY['object'::"text", 'array'::"text"])))
);


ALTER TABLE hdb_catalog.hdb_relationship OWNER TO cvewqhxnukolnw;

--
-- Name: hdb_remote_relationship; Type: TABLE; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

CREATE TABLE "hdb_catalog"."hdb_remote_relationship" (
    "remote_relationship_name" "text" NOT NULL,
    "table_schema" "name" NOT NULL,
    "table_name" "name" NOT NULL,
    "definition" "jsonb" NOT NULL
);


ALTER TABLE hdb_catalog.hdb_remote_relationship OWNER TO cvewqhxnukolnw;

--
-- Name: hdb_role; Type: VIEW; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

CREATE VIEW "hdb_catalog"."hdb_role" AS
 SELECT DISTINCT "q"."role_name"
   FROM ( SELECT "hdb_permission"."role_name"
           FROM "hdb_catalog"."hdb_permission"
        UNION ALL
         SELECT "hdb_action_permission"."role_name"
           FROM "hdb_catalog"."hdb_action_permission") "q";


ALTER TABLE hdb_catalog.hdb_role OWNER TO cvewqhxnukolnw;

--
-- Name: hdb_scheduled_event_invocation_logs; Type: TABLE; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

CREATE TABLE "hdb_catalog"."hdb_scheduled_event_invocation_logs" (
    "id" "text" DEFAULT "public"."gen_random_uuid"() NOT NULL,
    "event_id" "text",
    "status" integer,
    "request" "json",
    "response" "json",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE hdb_catalog.hdb_scheduled_event_invocation_logs OWNER TO cvewqhxnukolnw;

--
-- Name: hdb_scheduled_events; Type: TABLE; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

CREATE TABLE "hdb_catalog"."hdb_scheduled_events" (
    "id" "text" DEFAULT "public"."gen_random_uuid"() NOT NULL,
    "webhook_conf" "json" NOT NULL,
    "scheduled_time" timestamp with time zone NOT NULL,
    "retry_conf" "json",
    "payload" "json",
    "header_conf" "json",
    "status" "text" DEFAULT 'scheduled'::"text" NOT NULL,
    "tries" integer DEFAULT 0 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "next_retry_at" timestamp with time zone,
    "comment" "text",
    CONSTRAINT "valid_status" CHECK (("status" = ANY (ARRAY['scheduled'::"text", 'locked'::"text", 'delivered'::"text", 'error'::"text", 'dead'::"text"])))
);


ALTER TABLE hdb_catalog.hdb_scheduled_events OWNER TO cvewqhxnukolnw;

--
-- Name: hdb_schema_update_event; Type: TABLE; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

CREATE TABLE "hdb_catalog"."hdb_schema_update_event" (
    "instance_id" "uuid" NOT NULL,
    "occurred_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "invalidations" "json" NOT NULL
);


ALTER TABLE hdb_catalog.hdb_schema_update_event OWNER TO cvewqhxnukolnw;

--
-- Name: hdb_table; Type: TABLE; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

CREATE TABLE "hdb_catalog"."hdb_table" (
    "table_schema" "name" NOT NULL,
    "table_name" "name" NOT NULL,
    "configuration" "jsonb",
    "is_system_defined" boolean DEFAULT false,
    "is_enum" boolean DEFAULT false NOT NULL
);


ALTER TABLE hdb_catalog.hdb_table OWNER TO cvewqhxnukolnw;

--
-- Name: hdb_table_info_agg; Type: VIEW; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

CREATE VIEW "hdb_catalog"."hdb_table_info_agg" AS
 SELECT "schema"."nspname" AS "table_schema",
    "table"."relname" AS "table_name",
    "jsonb_build_object"('oid', ("table"."oid")::integer, 'columns', COALESCE("columns"."info", '[]'::"jsonb"), 'primary_key', "primary_key"."info", 'unique_constraints', COALESCE("unique_constraints"."info", '[]'::"jsonb"), 'foreign_keys', COALESCE("foreign_key_constraints"."info", '[]'::"jsonb"), 'view_info',
        CASE "table"."relkind"
            WHEN 'v'::"char" THEN "jsonb_build_object"('is_updatable', (("pg_relation_is_updatable"(("table"."oid")::"regclass", true) & 4) = 4), 'is_insertable', (("pg_relation_is_updatable"(("table"."oid")::"regclass", true) & 8) = 8), 'is_deletable', (("pg_relation_is_updatable"(("table"."oid")::"regclass", true) & 16) = 16))
            ELSE NULL::"jsonb"
        END, 'description', "description"."description") AS "info"
   FROM (((((("pg_class" "table"
     JOIN "pg_namespace" "schema" ON (("schema"."oid" = "table"."relnamespace")))
     LEFT JOIN "pg_description" "description" ON ((("description"."classoid" = ('"pg_class"'::"regclass")::"oid") AND ("description"."objoid" = "table"."oid") AND ("description"."objsubid" = 0))))
     LEFT JOIN LATERAL ( SELECT "jsonb_agg"("jsonb_build_object"('name', "column"."attname", 'position', "column"."attnum", 'type', COALESCE("base_type"."typname", "type"."typname"), 'is_nullable', (NOT "column"."attnotnull"), 'description', "col_description"("table"."oid", ("column"."attnum")::integer))) AS "info"
           FROM (("pg_attribute" "column"
             LEFT JOIN "pg_type" "type" ON (("type"."oid" = "column"."atttypid")))
             LEFT JOIN "pg_type" "base_type" ON ((("type"."typtype" = 'd'::"char") AND ("base_type"."oid" = "type"."typbasetype"))))
          WHERE (("column"."attrelid" = "table"."oid") AND ("column"."attnum" > 0) AND (NOT "column"."attisdropped"))) "columns" ON (true))
     LEFT JOIN LATERAL ( SELECT "jsonb_build_object"('constraint', "jsonb_build_object"('name', "class"."relname", 'oid', ("class"."oid")::integer), 'columns', COALESCE("columns_1"."info", '[]'::"jsonb")) AS "info"
           FROM (("pg_index" "index"
             JOIN "pg_class" "class" ON (("class"."oid" = "index"."indexrelid")))
             LEFT JOIN LATERAL ( SELECT "jsonb_agg"("column"."attname") AS "info"
                   FROM "pg_attribute" "column"
                  WHERE (("column"."attrelid" = "table"."oid") AND ("column"."attnum" = ANY (("index"."indkey")::smallint[])))) "columns_1" ON (true))
          WHERE (("index"."indrelid" = "table"."oid") AND "index"."indisprimary")) "primary_key" ON (true))
     LEFT JOIN LATERAL ( SELECT "jsonb_agg"("jsonb_build_object"('name', "class"."relname", 'oid', ("class"."oid")::integer)) AS "info"
           FROM ("pg_index" "index"
             JOIN "pg_class" "class" ON (("class"."oid" = "index"."indexrelid")))
          WHERE (("index"."indrelid" = "table"."oid") AND "index"."indisunique" AND (NOT "index"."indisprimary"))) "unique_constraints" ON (true))
     LEFT JOIN LATERAL ( SELECT "jsonb_agg"("jsonb_build_object"('constraint', "jsonb_build_object"('name', "foreign_key"."constraint_name", 'oid', "foreign_key"."constraint_oid"), 'columns', "foreign_key"."columns", 'foreign_table', "jsonb_build_object"('schema', "foreign_key"."ref_table_table_schema", 'name', "foreign_key"."ref_table"), 'foreign_columns', "foreign_key"."ref_columns")) AS "info"
           FROM "hdb_catalog"."hdb_foreign_key_constraint" "foreign_key"
          WHERE (("foreign_key"."table_schema" = "schema"."nspname") AND ("foreign_key"."table_name" = "table"."relname"))) "foreign_key_constraints" ON (true))
  WHERE ("table"."relkind" = ANY (ARRAY['r'::"char", 't'::"char", 'v'::"char", 'm'::"char", 'f'::"char", 'p'::"char"]));


ALTER TABLE hdb_catalog.hdb_table_info_agg OWNER TO cvewqhxnukolnw;

--
-- Name: hdb_unique_constraint; Type: VIEW; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

CREATE VIEW "hdb_catalog"."hdb_unique_constraint" AS
 SELECT "tc"."table_name",
    "tc"."constraint_schema" AS "table_schema",
    "tc"."constraint_name",
    "json_agg"("kcu"."column_name") AS "columns"
   FROM ("information_schema"."table_constraints" "tc"
     JOIN "information_schema"."key_column_usage" "kcu" USING ("constraint_schema", "constraint_name"))
  WHERE (("tc"."constraint_type")::"text" = 'UNIQUE'::"text")
  GROUP BY "tc"."table_name", "tc"."constraint_schema", "tc"."constraint_name";


ALTER TABLE hdb_catalog.hdb_unique_constraint OWNER TO cvewqhxnukolnw;

--
-- Name: hdb_version; Type: TABLE; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

CREATE TABLE "hdb_catalog"."hdb_version" (
    "hasura_uuid" "uuid" DEFAULT "public"."gen_random_uuid"() NOT NULL,
    "version" "text" NOT NULL,
    "upgraded_on" timestamp with time zone NOT NULL,
    "cli_state" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "console_state" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL
);


ALTER TABLE hdb_catalog.hdb_version OWNER TO cvewqhxnukolnw;

--
-- Name: remote_schemas; Type: TABLE; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

CREATE TABLE "hdb_catalog"."remote_schemas" (
    "id" bigint NOT NULL,
    "name" "text",
    "definition" "json",
    "comment" "text"
);


ALTER TABLE hdb_catalog.remote_schemas OWNER TO cvewqhxnukolnw;

--
-- Name: remote_schemas_id_seq; Type: SEQUENCE; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

CREATE SEQUENCE "hdb_catalog"."remote_schemas_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE hdb_catalog.remote_schemas_id_seq OWNER TO cvewqhxnukolnw;

--
-- Name: remote_schemas_id_seq; Type: SEQUENCE OWNED BY; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

ALTER SEQUENCE "hdb_catalog"."remote_schemas_id_seq" OWNED BY "hdb_catalog"."remote_schemas"."id";


--
-- Name: hdb_instances_ref; Type: TABLE; Schema: hdb_pro_catalog; Owner: cvewqhxnukolnw
--

CREATE TABLE "hdb_pro_catalog"."hdb_instances_ref" (
    "instance_id" "uuid",
    "heartbeat_timestamp" timestamp without time zone
);


ALTER TABLE hdb_pro_catalog.hdb_instances_ref OWNER TO cvewqhxnukolnw;

--
-- Name: hdb_pro_config; Type: TABLE; Schema: hdb_pro_catalog; Owner: cvewqhxnukolnw
--

CREATE TABLE "hdb_pro_catalog"."hdb_pro_config" (
    "id" integer NOT NULL,
    "pro_config" "jsonb",
    "last_updated" timestamp without time zone DEFAULT "now"()
);


ALTER TABLE hdb_pro_catalog.hdb_pro_config OWNER TO cvewqhxnukolnw;

--
-- Name: hdb_pro_state; Type: TABLE; Schema: hdb_pro_catalog; Owner: cvewqhxnukolnw
--

CREATE TABLE "hdb_pro_catalog"."hdb_pro_state" (
    "id" integer NOT NULL,
    "hasura_pro_state" "jsonb",
    "schema_version" integer NOT NULL,
    "data_version" bigint NOT NULL,
    "last_updated" timestamp without time zone DEFAULT "now"()
);


ALTER TABLE hdb_pro_catalog.hdb_pro_state OWNER TO cvewqhxnukolnw;

--
-- Name: users; Type: TABLE; Schema: public; Owner: cvewqhxnukolnw
--

CREATE TABLE "public"."users" (
    "id" integer NOT NULL,
    "username" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "last_seen" timestamp with time zone,
    "role" "text" DEFAULT 'user'::"text" NOT NULL,
    "password" "text" DEFAULT 'cGFzc3dvcmQ='::"text",
    "roles" "text"[]
);


ALTER TABLE public.users OWNER TO cvewqhxnukolnw;

--
-- Name: online_users; Type: VIEW; Schema: public; Owner: cvewqhxnukolnw
--

CREATE VIEW "public"."online_users" AS
 SELECT "users"."id",
    "users"."last_seen"
   FROM "public"."users"
  WHERE ("users"."last_seen" >= ("now"() - '00:00:30'::interval));


ALTER TABLE public.online_users OWNER TO cvewqhxnukolnw;

--
-- Name: refresh_tokens; Type: TABLE; Schema: public; Owner: cvewqhxnukolnw
--

CREATE TABLE "public"."refresh_tokens" (
    "token" "text" NOT NULL,
    "user" integer NOT NULL,
    "expires" timestamp with time zone NOT NULL,
    "ip" "text" NOT NULL
);


ALTER TABLE public.refresh_tokens OWNER TO cvewqhxnukolnw;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: cvewqhxnukolnw
--

CREATE SEQUENCE "public"."users_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.users_id_seq OWNER TO cvewqhxnukolnw;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: cvewqhxnukolnw
--

ALTER SEQUENCE "public"."users_id_seq" OWNED BY "public"."users"."id";


--
-- Name: remote_schemas id; Type: DEFAULT; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

ALTER TABLE ONLY "hdb_catalog"."remote_schemas" ALTER COLUMN "id" SET DEFAULT "nextval"('"hdb_catalog"."remote_schemas_id_seq"'::"regclass");


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: cvewqhxnukolnw
--

ALTER TABLE ONLY "public"."users" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."users_id_seq"'::"regclass");


--
-- Data for Name: event_invocation_logs; Type: TABLE DATA; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

COPY "hdb_catalog"."event_invocation_logs" ("id", "event_id", "status", "request", "response", "created_at") FROM stdin;
\.


--
-- Data for Name: event_log; Type: TABLE DATA; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

COPY "hdb_catalog"."event_log" ("id", "schema_name", "table_name", "trigger_name", "payload", "delivered", "error", "tries", "created_at", "locked", "next_retry_at", "archived") FROM stdin;
\.


--
-- Data for Name: event_triggers; Type: TABLE DATA; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

COPY "hdb_catalog"."event_triggers" ("name", "type", "schema_name", "table_name", "configuration", "comment") FROM stdin;
\.


--
-- Data for Name: hdb_action; Type: TABLE DATA; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

COPY "hdb_catalog"."hdb_action" ("action_name", "action_defn", "comment", "is_system_defined") FROM stdin;
\.


--
-- Data for Name: hdb_action_log; Type: TABLE DATA; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

COPY "hdb_catalog"."hdb_action_log" ("id", "action_name", "input_payload", "request_headers", "session_variables", "response_payload", "errors", "created_at", "response_received_at", "status") FROM stdin;
\.


--
-- Data for Name: hdb_action_permission; Type: TABLE DATA; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

COPY "hdb_catalog"."hdb_action_permission" ("action_name", "role_name", "definition", "comment") FROM stdin;
\.


--
-- Data for Name: hdb_allowlist; Type: TABLE DATA; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

COPY "hdb_catalog"."hdb_allowlist" ("collection_name") FROM stdin;
\.


--
-- Data for Name: hdb_computed_field; Type: TABLE DATA; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

COPY "hdb_catalog"."hdb_computed_field" ("table_schema", "table_name", "computed_field_name", "definition", "comment") FROM stdin;
\.


--
-- Data for Name: hdb_cron_event_invocation_logs; Type: TABLE DATA; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

COPY "hdb_catalog"."hdb_cron_event_invocation_logs" ("id", "event_id", "status", "request", "response", "created_at") FROM stdin;
\.


--
-- Data for Name: hdb_cron_events; Type: TABLE DATA; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

COPY "hdb_catalog"."hdb_cron_events" ("id", "trigger_name", "scheduled_time", "status", "tries", "created_at", "next_retry_at") FROM stdin;
\.


--
-- Data for Name: hdb_cron_triggers; Type: TABLE DATA; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

COPY "hdb_catalog"."hdb_cron_triggers" ("name", "webhook_conf", "cron_schedule", "payload", "retry_conf", "header_conf", "include_in_metadata", "comment") FROM stdin;
\.


--
-- Data for Name: hdb_custom_types; Type: TABLE DATA; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

COPY "hdb_catalog"."hdb_custom_types" ("custom_types") FROM stdin;
\.


--
-- Data for Name: hdb_function; Type: TABLE DATA; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

COPY "hdb_catalog"."hdb_function" ("function_schema", "function_name", "configuration", "is_system_defined") FROM stdin;
\.


--
-- Data for Name: hdb_permission; Type: TABLE DATA; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

COPY "hdb_catalog"."hdb_permission" ("table_schema", "table_name", "role_name", "perm_type", "perm_def", "comment", "is_system_defined") FROM stdin;
public	online_users	user	select	{"filter": {}, "columns": ["id", "last_seen"], "computed_fields": [], "allow_aggregations": false}	\N	f
public	users	user	update	{"set": {}, "check": {"id": {"_eq": "X-Hasura-User-Id"}}, "filter": {"id": {"_eq": "X-Hasura-User-Id"}}, "columns": ["password"]}	\N	f
public	users	super-user	update	{"set": {}, "check": {"id": {"_eq": "X-Hasura-User-Id"}}, "filter": {"id": {"_eq": "X-Hasura-User-Id"}}, "columns": ["password"]}	\N	f
public	users	super-user	select	{"filter": {}, "columns": ["created_at", "id", "last_seen", "role", "roles", "username"], "computed_fields": [], "allow_aggregations": false}	\N	f
public	users	user	select	{"filter": {"id": {"_eq": "X-Hasura-User-Id"}}, "columns": ["created_at", "id", "last_seen", "password", "role", "roles", "username"], "computed_fields": [], "allow_aggregations": false}	\N	f
\.


--
-- Data for Name: hdb_query_collection; Type: TABLE DATA; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

COPY "hdb_catalog"."hdb_query_collection" ("collection_name", "collection_defn", "comment", "is_system_defined") FROM stdin;
\.


--
-- Data for Name: hdb_relationship; Type: TABLE DATA; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

COPY "hdb_catalog"."hdb_relationship" ("table_schema", "table_name", "rel_name", "rel_type", "rel_def", "comment", "is_system_defined") FROM stdin;
hdb_catalog	hdb_table	detail	object	{"manual_configuration": {"remote_table": {"name": "tables", "schema": "information_schema"}, "column_mapping": {"table_name": "table_name", "table_schema": "table_schema"}}}	\N	t
hdb_catalog	hdb_table	primary_key	object	{"manual_configuration": {"remote_table": {"name": "hdb_primary_key", "schema": "hdb_catalog"}, "column_mapping": {"table_name": "table_name", "table_schema": "table_schema"}}}	\N	t
hdb_catalog	hdb_table	columns	array	{"manual_configuration": {"remote_table": {"name": "columns", "schema": "information_schema"}, "column_mapping": {"table_name": "table_name", "table_schema": "table_schema"}}}	\N	t
hdb_catalog	hdb_table	foreign_key_constraints	array	{"manual_configuration": {"remote_table": {"name": "hdb_foreign_key_constraint", "schema": "hdb_catalog"}, "column_mapping": {"table_name": "table_name", "table_schema": "table_schema"}}}	\N	t
hdb_catalog	hdb_table	relationships	array	{"manual_configuration": {"remote_table": {"name": "hdb_relationship", "schema": "hdb_catalog"}, "column_mapping": {"table_name": "table_name", "table_schema": "table_schema"}}}	\N	t
hdb_catalog	hdb_table	permissions	array	{"manual_configuration": {"remote_table": {"name": "hdb_permission_agg", "schema": "hdb_catalog"}, "column_mapping": {"table_name": "table_name", "table_schema": "table_schema"}}}	\N	t
hdb_catalog	hdb_table	computed_fields	array	{"manual_configuration": {"remote_table": {"name": "hdb_computed_field", "schema": "hdb_catalog"}, "column_mapping": {"table_name": "table_name", "table_schema": "table_schema"}}}	\N	t
hdb_catalog	hdb_table	check_constraints	array	{"manual_configuration": {"remote_table": {"name": "hdb_check_constraint", "schema": "hdb_catalog"}, "column_mapping": {"table_name": "table_name", "table_schema": "table_schema"}}}	\N	t
hdb_catalog	hdb_table	unique_constraints	array	{"manual_configuration": {"remote_table": {"name": "hdb_unique_constraint", "schema": "hdb_catalog"}, "column_mapping": {"table_name": "table_name", "table_schema": "table_schema"}}}	\N	t
hdb_catalog	event_triggers	events	array	{"manual_configuration": {"remote_table": {"name": "event_log", "schema": "hdb_catalog"}, "column_mapping": {"name": "trigger_name"}}}	\N	t
hdb_catalog	event_log	trigger	object	{"manual_configuration": {"remote_table": {"name": "event_triggers", "schema": "hdb_catalog"}, "column_mapping": {"trigger_name": "name"}}}	\N	t
hdb_catalog	event_log	logs	array	{"foreign_key_constraint_on": {"table": {"name": "event_invocation_logs", "schema": "hdb_catalog"}, "column": "event_id"}}	\N	t
hdb_catalog	event_invocation_logs	event	object	{"foreign_key_constraint_on": "event_id"}	\N	t
hdb_catalog	hdb_function_agg	return_table_info	object	{"manual_configuration": {"remote_table": {"name": "hdb_table", "schema": "hdb_catalog"}, "column_mapping": {"return_type_name": "table_name", "return_type_schema": "table_schema"}}}	\N	t
hdb_catalog	hdb_action	permissions	array	{"manual_configuration": {"remote_table": {"name": "hdb_action_permission", "schema": "hdb_catalog"}, "column_mapping": {"action_name": "action_name"}}}	\N	t
hdb_catalog	hdb_role	action_permissions	array	{"manual_configuration": {"remote_table": {"name": "hdb_action_permission", "schema": "hdb_catalog"}, "column_mapping": {"role_name": "role_name"}}}	\N	t
hdb_catalog	hdb_role	permissions	array	{"manual_configuration": {"remote_table": {"name": "hdb_permission_agg", "schema": "hdb_catalog"}, "column_mapping": {"role_name": "role_name"}}}	\N	t
hdb_catalog	hdb_cron_triggers	cron_events	array	{"foreign_key_constraint_on": {"table": {"name": "hdb_cron_events", "schema": "hdb_catalog"}, "column": "trigger_name"}}	\N	t
hdb_catalog	hdb_cron_events	cron_trigger	object	{"foreign_key_constraint_on": "trigger_name"}	\N	t
hdb_catalog	hdb_cron_events	cron_event_logs	array	{"foreign_key_constraint_on": {"table": {"name": "hdb_cron_event_invocation_logs", "schema": "hdb_catalog"}, "column": "event_id"}}	\N	t
hdb_catalog	hdb_cron_event_invocation_logs	cron_event	object	{"foreign_key_constraint_on": "event_id"}	\N	t
hdb_catalog	hdb_scheduled_events	scheduled_event_logs	array	{"foreign_key_constraint_on": {"table": {"name": "hdb_scheduled_event_invocation_logs", "schema": "hdb_catalog"}, "column": "event_id"}}	\N	t
hdb_catalog	hdb_scheduled_event_invocation_logs	scheduled_event	object	{"foreign_key_constraint_on": "event_id"}	\N	t
public	online_users	user	object	{"manual_configuration": {"remote_table": {"name": "users", "schema": "public"}, "column_mapping": {"id": "id"}}}	\N	f
public	refresh_tokens	userByUser	object	{"foreign_key_constraint_on": "user"}	\N	f
public	users	refresh_tokens	array	{"foreign_key_constraint_on": {"table": {"name": "refresh_tokens", "schema": "public"}, "column": "user"}}	\N	f
\.


--
-- Data for Name: hdb_remote_relationship; Type: TABLE DATA; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

COPY "hdb_catalog"."hdb_remote_relationship" ("remote_relationship_name", "table_schema", "table_name", "definition") FROM stdin;
\.


--
-- Data for Name: hdb_scheduled_event_invocation_logs; Type: TABLE DATA; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

COPY "hdb_catalog"."hdb_scheduled_event_invocation_logs" ("id", "event_id", "status", "request", "response", "created_at") FROM stdin;
\.


--
-- Data for Name: hdb_scheduled_events; Type: TABLE DATA; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

COPY "hdb_catalog"."hdb_scheduled_events" ("id", "webhook_conf", "scheduled_time", "retry_conf", "payload", "header_conf", "status", "tries", "created_at", "next_retry_at", "comment") FROM stdin;
\.


--
-- Data for Name: hdb_schema_update_event; Type: TABLE DATA; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

COPY "hdb_catalog"."hdb_schema_update_event" ("instance_id", "occurred_at", "invalidations") FROM stdin;
33f4090b-9032-4832-8abc-3ee776e7256d	2021-02-21 05:37:52.426496+00	{"metadata":false,"remote_schemas":[]}
\.


--
-- Data for Name: hdb_table; Type: TABLE DATA; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

COPY "hdb_catalog"."hdb_table" ("table_schema", "table_name", "configuration", "is_system_defined", "is_enum") FROM stdin;
information_schema	tables	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
information_schema	schemata	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
information_schema	views	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
information_schema	columns	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
hdb_catalog	hdb_table	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
hdb_catalog	hdb_primary_key	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
hdb_catalog	hdb_foreign_key_constraint	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
hdb_catalog	hdb_relationship	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
hdb_catalog	hdb_permission_agg	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
hdb_catalog	hdb_computed_field	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
hdb_catalog	hdb_check_constraint	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
hdb_catalog	hdb_unique_constraint	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
hdb_catalog	hdb_remote_relationship	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
hdb_catalog	event_triggers	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
hdb_catalog	event_log	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
hdb_catalog	event_invocation_logs	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
hdb_catalog	hdb_function	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
hdb_catalog	hdb_function_agg	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
hdb_catalog	remote_schemas	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
hdb_catalog	hdb_version	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
hdb_catalog	hdb_query_collection	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
hdb_catalog	hdb_allowlist	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
hdb_catalog	hdb_custom_types	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
hdb_catalog	hdb_action_permission	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
hdb_catalog	hdb_action	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
hdb_catalog	hdb_action_log	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
hdb_catalog	hdb_role	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
hdb_catalog	hdb_cron_triggers	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
hdb_catalog	hdb_cron_events	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
hdb_catalog	hdb_cron_event_invocation_logs	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
hdb_catalog	hdb_scheduled_events	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
hdb_catalog	hdb_scheduled_event_invocation_logs	{"custom_root_fields": {}, "custom_column_names": {}}	t	f
public	users	{"custom_root_fields": {}, "custom_column_names": {}}	f	f
public	online_users	{"custom_root_fields": {}, "custom_column_names": {}}	f	f
public	refresh_tokens	{"custom_root_fields": {}, "custom_column_names": {}}	f	f
\.


--
-- Data for Name: hdb_version; Type: TABLE DATA; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

COPY "hdb_catalog"."hdb_version" ("hasura_uuid", "version", "upgraded_on", "cli_state", "console_state") FROM stdin;
cf671444-4f53-4fd7-8069-b7ae45e92657	40	2021-02-02 01:33:41.776785+00	{}	{"console_notifications": {"admin": {"date": "2021-02-21T12:32:03.426Z", "read": "default", "showBadge": false}, "d727d5f9-cda1-4594-b915-bbe4e52bd6a8": {"date": "2021-02-17T13:06:17.428Z", "read": "default", "showBadge": false}}, "telemetryNotificationShown": true}
\.


--
-- Data for Name: remote_schemas; Type: TABLE DATA; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

COPY "hdb_catalog"."remote_schemas" ("id", "name", "definition", "comment") FROM stdin;
\.


--
-- Data for Name: hdb_instances_ref; Type: TABLE DATA; Schema: hdb_pro_catalog; Owner: cvewqhxnukolnw
--

COPY "hdb_pro_catalog"."hdb_instances_ref" ("instance_id", "heartbeat_timestamp") FROM stdin;
\.


--
-- Data for Name: hdb_pro_config; Type: TABLE DATA; Schema: hdb_pro_catalog; Owner: cvewqhxnukolnw
--

COPY "hdb_pro_catalog"."hdb_pro_config" ("id", "pro_config", "last_updated") FROM stdin;
1	{"config": {"api_limits": {"enabled": false, "version": 0, "rate_limit": null, "depth_limit": null}, "project_configs": {"analyze_response_body": false, "analyze_query_variables": false}}, "pro_config_schema_version": 3}	2021-02-21 12:34:46.863149
\.


--
-- Data for Name: hdb_pro_state; Type: TABLE DATA; Schema: hdb_pro_catalog; Owner: cvewqhxnukolnw
--

COPY "hdb_pro_catalog"."hdb_pro_state" ("id", "hasura_pro_state", "schema_version", "data_version", "last_updated") FROM stdin;
\.


--
-- Data for Name: refresh_tokens; Type: TABLE DATA; Schema: public; Owner: cvewqhxnukolnw
--

COPY "public"."refresh_tokens" ("token", "user", "expires", "ip") FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: cvewqhxnukolnw
--

COPY "public"."users" ("id", "username", "created_at", "last_seen", "role", "password", "roles") FROM stdin;
5	Jess	2021-02-04 05:43:14.309059+00	\N	user	$2a$07$wCBCSnPUv6F/958XW92bDuH6/DIEJSHky1vUD/EHSw3JZz8OTSv06	\N
1	Dad	2021-02-04 05:42:16.227928+00	2021-02-04 05:58:31.945971+00	super-user	$2a$10$h3y3H1imUoqAPqYFU6vkDOTQPNhkEnvlS1y41vSQe5UlZsMlgFLk.	{user,super-user}
4	Lucy	2021-02-04 05:43:04.36552+00	\N	user	$2a$07$wCBCSnPUv6F/958XW92bDuH6/DIEJSHky1vUD/EHSw3JZz8OTSv06	\N
2	Mum	2021-02-04 05:42:23.631585+00	2021-02-04 06:02:11.595503+00	super-user	$2a$07$wCBCSnPUv6F/958XW92bDuH6/DIEJSHky1vUD/EHSw3JZz8OTSv06	\N
3	Molly	2021-02-04 05:42:52.988885+00	\N	user	$2a$07$wCBCSnPUv6F/958XW92bDuH6/DIEJSHky1vUD/EHSw3JZz8OTSv06	\N
\.


--
-- Name: remote_schemas_id_seq; Type: SEQUENCE SET; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

SELECT pg_catalog.setval('"hdb_catalog"."remote_schemas_id_seq"', 1, false);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: cvewqhxnukolnw
--

SELECT pg_catalog.setval('"public"."users_id_seq"', 5, true);


--
-- Name: event_invocation_logs event_invocation_logs_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

ALTER TABLE ONLY "hdb_catalog"."event_invocation_logs"
    ADD CONSTRAINT "event_invocation_logs_pkey" PRIMARY KEY ("id");


--
-- Name: event_log event_log_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

ALTER TABLE ONLY "hdb_catalog"."event_log"
    ADD CONSTRAINT "event_log_pkey" PRIMARY KEY ("id");


--
-- Name: event_triggers event_triggers_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

ALTER TABLE ONLY "hdb_catalog"."event_triggers"
    ADD CONSTRAINT "event_triggers_pkey" PRIMARY KEY ("name");


--
-- Name: hdb_action_log hdb_action_log_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

ALTER TABLE ONLY "hdb_catalog"."hdb_action_log"
    ADD CONSTRAINT "hdb_action_log_pkey" PRIMARY KEY ("id");


--
-- Name: hdb_action_permission hdb_action_permission_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

ALTER TABLE ONLY "hdb_catalog"."hdb_action_permission"
    ADD CONSTRAINT "hdb_action_permission_pkey" PRIMARY KEY ("action_name", "role_name");


--
-- Name: hdb_action hdb_action_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

ALTER TABLE ONLY "hdb_catalog"."hdb_action"
    ADD CONSTRAINT "hdb_action_pkey" PRIMARY KEY ("action_name");


--
-- Name: hdb_allowlist hdb_allowlist_collection_name_key; Type: CONSTRAINT; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

ALTER TABLE ONLY "hdb_catalog"."hdb_allowlist"
    ADD CONSTRAINT "hdb_allowlist_collection_name_key" UNIQUE ("collection_name");


--
-- Name: hdb_computed_field hdb_computed_field_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

ALTER TABLE ONLY "hdb_catalog"."hdb_computed_field"
    ADD CONSTRAINT "hdb_computed_field_pkey" PRIMARY KEY ("table_schema", "table_name", "computed_field_name");


--
-- Name: hdb_cron_event_invocation_logs hdb_cron_event_invocation_logs_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

ALTER TABLE ONLY "hdb_catalog"."hdb_cron_event_invocation_logs"
    ADD CONSTRAINT "hdb_cron_event_invocation_logs_pkey" PRIMARY KEY ("id");


--
-- Name: hdb_cron_events hdb_cron_events_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

ALTER TABLE ONLY "hdb_catalog"."hdb_cron_events"
    ADD CONSTRAINT "hdb_cron_events_pkey" PRIMARY KEY ("id");


--
-- Name: hdb_cron_triggers hdb_cron_triggers_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

ALTER TABLE ONLY "hdb_catalog"."hdb_cron_triggers"
    ADD CONSTRAINT "hdb_cron_triggers_pkey" PRIMARY KEY ("name");


--
-- Name: hdb_function hdb_function_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

ALTER TABLE ONLY "hdb_catalog"."hdb_function"
    ADD CONSTRAINT "hdb_function_pkey" PRIMARY KEY ("function_schema", "function_name");


--
-- Name: hdb_permission hdb_permission_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

ALTER TABLE ONLY "hdb_catalog"."hdb_permission"
    ADD CONSTRAINT "hdb_permission_pkey" PRIMARY KEY ("table_schema", "table_name", "role_name", "perm_type");


--
-- Name: hdb_query_collection hdb_query_collection_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

ALTER TABLE ONLY "hdb_catalog"."hdb_query_collection"
    ADD CONSTRAINT "hdb_query_collection_pkey" PRIMARY KEY ("collection_name");


--
-- Name: hdb_relationship hdb_relationship_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

ALTER TABLE ONLY "hdb_catalog"."hdb_relationship"
    ADD CONSTRAINT "hdb_relationship_pkey" PRIMARY KEY ("table_schema", "table_name", "rel_name");


--
-- Name: hdb_remote_relationship hdb_remote_relationship_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

ALTER TABLE ONLY "hdb_catalog"."hdb_remote_relationship"
    ADD CONSTRAINT "hdb_remote_relationship_pkey" PRIMARY KEY ("remote_relationship_name", "table_schema", "table_name");


--
-- Name: hdb_scheduled_event_invocation_logs hdb_scheduled_event_invocation_logs_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

ALTER TABLE ONLY "hdb_catalog"."hdb_scheduled_event_invocation_logs"
    ADD CONSTRAINT "hdb_scheduled_event_invocation_logs_pkey" PRIMARY KEY ("id");


--
-- Name: hdb_scheduled_events hdb_scheduled_events_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

ALTER TABLE ONLY "hdb_catalog"."hdb_scheduled_events"
    ADD CONSTRAINT "hdb_scheduled_events_pkey" PRIMARY KEY ("id");


--
-- Name: hdb_table hdb_table_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

ALTER TABLE ONLY "hdb_catalog"."hdb_table"
    ADD CONSTRAINT "hdb_table_pkey" PRIMARY KEY ("table_schema", "table_name");


--
-- Name: hdb_version hdb_version_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

ALTER TABLE ONLY "hdb_catalog"."hdb_version"
    ADD CONSTRAINT "hdb_version_pkey" PRIMARY KEY ("hasura_uuid");


--
-- Name: remote_schemas remote_schemas_name_key; Type: CONSTRAINT; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

ALTER TABLE ONLY "hdb_catalog"."remote_schemas"
    ADD CONSTRAINT "remote_schemas_name_key" UNIQUE ("name");


--
-- Name: remote_schemas remote_schemas_pkey; Type: CONSTRAINT; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

ALTER TABLE ONLY "hdb_catalog"."remote_schemas"
    ADD CONSTRAINT "remote_schemas_pkey" PRIMARY KEY ("id");


--
-- Name: hdb_pro_config hdb_pro_config_pkey; Type: CONSTRAINT; Schema: hdb_pro_catalog; Owner: cvewqhxnukolnw
--

ALTER TABLE ONLY "hdb_pro_catalog"."hdb_pro_config"
    ADD CONSTRAINT "hdb_pro_config_pkey" PRIMARY KEY ("id");


--
-- Name: hdb_pro_state hdb_pro_state_pkey; Type: CONSTRAINT; Schema: hdb_pro_catalog; Owner: cvewqhxnukolnw
--

ALTER TABLE ONLY "hdb_pro_catalog"."hdb_pro_state"
    ADD CONSTRAINT "hdb_pro_state_pkey" PRIMARY KEY ("id");


--
-- Name: refresh_tokens refresh_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: cvewqhxnukolnw
--

ALTER TABLE ONLY "public"."refresh_tokens"
    ADD CONSTRAINT "refresh_tokens_pkey" PRIMARY KEY ("token");


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: cvewqhxnukolnw
--

ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_pkey" PRIMARY KEY ("id");


--
-- Name: event_invocation_logs_event_id_idx; Type: INDEX; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

CREATE INDEX "event_invocation_logs_event_id_idx" ON "hdb_catalog"."event_invocation_logs" USING "btree" ("event_id");


--
-- Name: event_log_created_at_idx; Type: INDEX; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

CREATE INDEX "event_log_created_at_idx" ON "hdb_catalog"."event_log" USING "btree" ("created_at");


--
-- Name: event_log_delivered_idx; Type: INDEX; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

CREATE INDEX "event_log_delivered_idx" ON "hdb_catalog"."event_log" USING "btree" ("delivered");


--
-- Name: event_log_locked_idx; Type: INDEX; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

CREATE INDEX "event_log_locked_idx" ON "hdb_catalog"."event_log" USING "btree" ("locked");


--
-- Name: event_log_trigger_name_idx; Type: INDEX; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

CREATE INDEX "event_log_trigger_name_idx" ON "hdb_catalog"."event_log" USING "btree" ("trigger_name");


--
-- Name: hdb_cron_event_status; Type: INDEX; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

CREATE INDEX "hdb_cron_event_status" ON "hdb_catalog"."hdb_cron_events" USING "btree" ("status");


--
-- Name: hdb_scheduled_event_status; Type: INDEX; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

CREATE INDEX "hdb_scheduled_event_status" ON "hdb_catalog"."hdb_scheduled_events" USING "btree" ("status");


--
-- Name: hdb_schema_update_event_one_row; Type: INDEX; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

CREATE UNIQUE INDEX "hdb_schema_update_event_one_row" ON "hdb_catalog"."hdb_schema_update_event" USING "btree" ((("occurred_at" IS NOT NULL)));


--
-- Name: hdb_version_one_row; Type: INDEX; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

CREATE UNIQUE INDEX "hdb_version_one_row" ON "hdb_catalog"."hdb_version" USING "btree" ((("version" IS NOT NULL)));


--
-- Name: hdb_table event_trigger_table_name_update_trigger; Type: TRIGGER; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

CREATE TRIGGER "event_trigger_table_name_update_trigger" AFTER UPDATE ON "hdb_catalog"."hdb_table" FOR EACH ROW EXECUTE FUNCTION "hdb_catalog"."event_trigger_table_name_update"();


--
-- Name: hdb_schema_update_event hdb_schema_update_event_notifier; Type: TRIGGER; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

CREATE TRIGGER "hdb_schema_update_event_notifier" AFTER INSERT OR UPDATE ON "hdb_catalog"."hdb_schema_update_event" FOR EACH ROW EXECUTE FUNCTION "hdb_catalog"."hdb_schema_update_event_notifier"();


--
-- Name: event_invocation_logs event_invocation_logs_event_id_fkey; Type: FK CONSTRAINT; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

ALTER TABLE ONLY "hdb_catalog"."event_invocation_logs"
    ADD CONSTRAINT "event_invocation_logs_event_id_fkey" FOREIGN KEY ("event_id") REFERENCES "hdb_catalog"."event_log"("id");


--
-- Name: hdb_action_permission hdb_action_permission_action_name_fkey; Type: FK CONSTRAINT; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

ALTER TABLE ONLY "hdb_catalog"."hdb_action_permission"
    ADD CONSTRAINT "hdb_action_permission_action_name_fkey" FOREIGN KEY ("action_name") REFERENCES "hdb_catalog"."hdb_action"("action_name") ON UPDATE CASCADE;


--
-- Name: hdb_allowlist hdb_allowlist_collection_name_fkey; Type: FK CONSTRAINT; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

ALTER TABLE ONLY "hdb_catalog"."hdb_allowlist"
    ADD CONSTRAINT "hdb_allowlist_collection_name_fkey" FOREIGN KEY ("collection_name") REFERENCES "hdb_catalog"."hdb_query_collection"("collection_name");


--
-- Name: hdb_computed_field hdb_computed_field_table_schema_table_name_fkey; Type: FK CONSTRAINT; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

ALTER TABLE ONLY "hdb_catalog"."hdb_computed_field"
    ADD CONSTRAINT "hdb_computed_field_table_schema_table_name_fkey" FOREIGN KEY ("table_schema", "table_name") REFERENCES "hdb_catalog"."hdb_table"("table_schema", "table_name") ON UPDATE CASCADE;


--
-- Name: hdb_cron_event_invocation_logs hdb_cron_event_invocation_logs_event_id_fkey; Type: FK CONSTRAINT; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

ALTER TABLE ONLY "hdb_catalog"."hdb_cron_event_invocation_logs"
    ADD CONSTRAINT "hdb_cron_event_invocation_logs_event_id_fkey" FOREIGN KEY ("event_id") REFERENCES "hdb_catalog"."hdb_cron_events"("id") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: hdb_cron_events hdb_cron_events_trigger_name_fkey; Type: FK CONSTRAINT; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

ALTER TABLE ONLY "hdb_catalog"."hdb_cron_events"
    ADD CONSTRAINT "hdb_cron_events_trigger_name_fkey" FOREIGN KEY ("trigger_name") REFERENCES "hdb_catalog"."hdb_cron_triggers"("name") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: hdb_permission hdb_permission_table_schema_table_name_fkey; Type: FK CONSTRAINT; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

ALTER TABLE ONLY "hdb_catalog"."hdb_permission"
    ADD CONSTRAINT "hdb_permission_table_schema_table_name_fkey" FOREIGN KEY ("table_schema", "table_name") REFERENCES "hdb_catalog"."hdb_table"("table_schema", "table_name") ON UPDATE CASCADE;


--
-- Name: hdb_relationship hdb_relationship_table_schema_table_name_fkey; Type: FK CONSTRAINT; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

ALTER TABLE ONLY "hdb_catalog"."hdb_relationship"
    ADD CONSTRAINT "hdb_relationship_table_schema_table_name_fkey" FOREIGN KEY ("table_schema", "table_name") REFERENCES "hdb_catalog"."hdb_table"("table_schema", "table_name") ON UPDATE CASCADE;


--
-- Name: hdb_remote_relationship hdb_remote_relationship_table_schema_table_name_fkey; Type: FK CONSTRAINT; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

ALTER TABLE ONLY "hdb_catalog"."hdb_remote_relationship"
    ADD CONSTRAINT "hdb_remote_relationship_table_schema_table_name_fkey" FOREIGN KEY ("table_schema", "table_name") REFERENCES "hdb_catalog"."hdb_table"("table_schema", "table_name") ON UPDATE CASCADE;


--
-- Name: hdb_scheduled_event_invocation_logs hdb_scheduled_event_invocation_logs_event_id_fkey; Type: FK CONSTRAINT; Schema: hdb_catalog; Owner: cvewqhxnukolnw
--

ALTER TABLE ONLY "hdb_catalog"."hdb_scheduled_event_invocation_logs"
    ADD CONSTRAINT "hdb_scheduled_event_invocation_logs_event_id_fkey" FOREIGN KEY ("event_id") REFERENCES "hdb_catalog"."hdb_scheduled_events"("id") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: refresh_tokens refresh_tokens_user_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cvewqhxnukolnw
--

ALTER TABLE ONLY "public"."refresh_tokens"
    ADD CONSTRAINT "refresh_tokens_user_fkey" FOREIGN KEY ("user") REFERENCES "public"."users"("id") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

