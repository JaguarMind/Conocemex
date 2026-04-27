


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


CREATE EXTENSION IF NOT EXISTS "pg_net" WITH SCHEMA "extensions";






COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pg_trgm" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "postgis" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE TYPE "public"."accessibility_need" AS ENUM (
    'none',
    'wheelchair'
);


ALTER TYPE "public"."accessibility_need" OWNER TO "postgres";


CREATE TYPE "public"."budget_range" AS ENUM (
    'low',
    'medium',
    'high'
);


ALTER TYPE "public"."budget_range" OWNER TO "postgres";


CREATE TYPE "public"."community_role" AS ENUM (
    'member',
    'moderator',
    'admin'
);


ALTER TYPE "public"."community_role" OWNER TO "postgres";


CREATE TYPE "public"."dietary_restriction" AS ENUM (
    'none',
    'vegetarian',
    'vegan',
    'gluten_free',
    'halal',
    'kosher'
);


ALTER TYPE "public"."dietary_restriction" OWNER TO "postgres";


CREATE TYPE "public"."language_proficiency" AS ENUM (
    'native',
    'fluent',
    'basic'
);


ALTER TYPE "public"."language_proficiency" OWNER TO "postgres";


CREATE TYPE "public"."notification_type" AS ENUM (
    'hotspot',
    'new_client',
    'payment',
    'survey',
    'general'
);


ALTER TYPE "public"."notification_type" OWNER TO "postgres";


CREATE TYPE "public"."offering_type" AS ENUM (
    'product',
    'service'
);


ALTER TYPE "public"."offering_type" OWNER TO "postgres";


CREATE TYPE "public"."payment_method" AS ENUM (
    'stripe',
    'mercado_pago',
    'cash'
);


ALTER TYPE "public"."payment_method" OWNER TO "postgres";


CREATE TYPE "public"."payment_status" AS ENUM (
    'pending',
    'completed',
    'failed',
    'refunded'
);


ALTER TYPE "public"."payment_status" OWNER TO "postgres";


CREATE TYPE "public"."price_type" AS ENUM (
    'fixed',
    'from',
    'hourly',
    'per_person',
    'quote'
);


ALTER TYPE "public"."price_type" OWNER TO "postgres";


CREATE TYPE "public"."question_type" AS ENUM (
    'single_choice',
    'multiple_choice',
    'rating',
    'text'
);


ALTER TYPE "public"."question_type" OWNER TO "postgres";


CREATE TYPE "public"."route_type" AS ENUM (
    'gastronomica',
    'cultural',
    'compras',
    'mixta'
);


ALTER TYPE "public"."route_type" OWNER TO "postgres";


CREATE TYPE "public"."survey_type" AS ENUM (
    'post_visit',
    'demand',
    'trend',
    'experience',
    'vote',
    'onboarding'
);


ALTER TYPE "public"."survey_type" OWNER TO "postgres";


CREATE TYPE "public"."user_role" AS ENUM (
    'microempresario',
    'turista',
    'admin'
);


ALTER TYPE "public"."user_role" OWNER TO "postgres";


CREATE TYPE "public"."visit_source" AS ENUM (
    'recommendation',
    'map',
    'route',
    'qr'
);


ALTER TYPE "public"."visit_source" OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."bump_community_member_count"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin
  if tg_op = 'INSERT' then
    update communities
       set member_count = member_count + 1,
           updated_at   = now()
     where id = new.community_id;
    return new;
  elsif tg_op = 'DELETE' then
    update communities
       set member_count = greatest(member_count - 1, 0),
           updated_at   = now()
     where id = old.community_id;
    return old;
  end if;
  return null;
end $$;


ALTER FUNCTION "public"."bump_community_member_count"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."businesses_nearby"("p_lat" double precision, "p_lng" double precision, "p_radius_m" integer DEFAULT 3000, "p_limit" integer DEFAULT 100) RETURNS TABLE("business_id" "uuid", "business_name" "text", "category_slug" "text", "category_icon" "text", "latitude" double precision, "longitude" double precision, "distance_m" numeric, "cover_image_url" "text", "is_verified" boolean, "total_visits" integer, "average_rating" double precision)
    LANGUAGE "sql" STABLE
    AS $$
  select 
    b.id,
    b.name,
    c.slug,
    c.icon,
    b.latitude,
    b.longitude,
    round(ST_Distance(
      b.location,
      ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography
    )::numeric, 0) as distance_m,
    b.cover_image_url,
    b.is_verified,
    b.total_visits,
    b.average_rating
  from businesses b
  join categories c on c.id = b.category_id
  where b.is_active = true
    and ST_DWithin(
      b.location,
      ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography,
      p_radius_m
    )
  order by ST_Distance(
    b.location,
    ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography
  ) asc
  limit p_limit;
$$;


ALTER FUNCTION "public"."businesses_nearby"("p_lat" double precision, "p_lng" double precision, "p_radius_m" integer, "p_limit" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."calculate_gini"("business_ids" "uuid"[]) RETURNS numeric
    LANGUAGE "plpgsql"
    AS $$
declare
  v_n integer;
  v_sum_visits numeric;
  v_gini numeric;
begin
  with vals as (
    select coalesce(total_visits, 0)::numeric as v
    from businesses
    where id = any(business_ids)
    order by total_visits asc
  ),
  indexed as (
    select v, row_number() over () as i, count(*) over () as n
    from vals
  )
  select 
    max(n),
    sum(v),
    case 
      when sum(v) = 0 then 0
      else (2.0 * sum(i * v) - (max(n) + 1) * sum(v)) / (max(n) * sum(v))
    end
  into v_n, v_sum_visits, v_gini
  from indexed;
  
  return round(v_gini, 4);
end;
$$;


ALTER FUNCTION "public"."calculate_gini"("business_ids" "uuid"[]) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_config"("p_key" "text") RETURNS numeric
    LANGUAGE "sql" STABLE
    AS $$
  select value 
  from algorithm_config 
  where key = p_key;
$$;


ALTER FUNCTION "public"."get_config"("p_key" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_new_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
  INSERT INTO public.profiles (id, role, created_at, updated_at)
  VALUES (NEW.id, 'turista', now(), now());
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."handle_new_user"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."invoke_edge_function"("function_name" "text", "payload" "jsonb") RETURNS bigint
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'extensions', 'vault'
    AS $$
declare
  request_id bigint;
  anon_key text;
  function_url text := 'https://lcbgheoufqlrqimlxpei.supabase.co/functions/v1/' || function_name;
begin
  -- Lee la anon key desde el vault
  select decrypted_secret into anon_key
  from vault.decrypted_secrets
  where name = 'edge_anon_key'
  limit 1;

  if anon_key is null then
    raise warning 'edge_anon_key no encontrado en vault, no se invocó %', function_name;
    return null;
  end if;

  -- Llamada HTTP asíncrona (no bloquea la transacción del INSERT/UPDATE)
  select net.http_post(
    url := function_url,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || anon_key
    ),
    body := payload,
    timeout_milliseconds := 10000
  ) into request_id;

  return request_id;
end;
$$;


ALTER FUNCTION "public"."invoke_edge_function"("function_name" "text", "payload" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."is_admin"() RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  SELECT EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid() AND role = 'admin'
  );
$$;


ALTER FUNCTION "public"."is_admin"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."is_community_member"("_community_id" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    AS $$
  select exists (
    select 1
    from public.community_members
    where community_id = _community_id
      and profile_id   = auth.uid()
  );
$$;


ALTER FUNCTION "public"."is_community_member"("_community_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."mp_is_connected"("p_business_id" "uuid") RETURNS boolean
    LANGUAGE "sql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  select exists (
    select 1
    from public.mp_accounts ma
    join public.businesses b on b.id = ma.business_id
    where ma.business_id = p_business_id
      and b.owner_id = auth.uid()
      and ma.expires_at > now()
  );
$$;


ALTER FUNCTION "public"."mp_is_connected"("p_business_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."mp_oauth_states_cleanup"() RETURNS integer
    LANGUAGE "sql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  with deleted as (
    delete from public.mp_oauth_states
    where expires_at < now() - interval '1 hour'
    returning 1
  )
  select count(*)::int from deleted;
$$;


ALTER FUNCTION "public"."mp_oauth_states_cleanup"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."on_direct_message_insert"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
declare
  v_buyer uuid;
  v_owner uuid;
begin
  select buyer_id, owner_id into v_buyer, v_owner
    from conversations where id = new.conversation_id;

  update conversations set
    last_message_at      = new.created_at,
    last_message_preview = coalesce(left(new.content, 80), '📦 Producto compartido'),
    buyer_unread = buyer_unread + (case when new.sender_id = v_owner then 1 else 0 end),
    owner_unread = owner_unread + (case when new.sender_id = v_buyer then 1 else 0 end)
  where id = new.conversation_id;

  return new;
end $$;


ALTER FUNCTION "public"."on_direct_message_insert"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."open_conversation"("p_business_id" "uuid") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
declare
  v_owner uuid;
  v_conv_id uuid;
begin
  select owner_id into v_owner from businesses where id = p_business_id;
  if v_owner = auth.uid() then
    raise exception 'No puedes abrir una conversación con tu propio negocio';
  end if;

  insert into conversations (buyer_id, business_id, owner_id)
  values (auth.uid(), p_business_id, v_owner)
  on conflict (buyer_id, business_id) do update set buyer_id = excluded.buyer_id
  returning id into v_conv_id;

  return v_conv_id;
end $$;


ALTER FUNCTION "public"."open_conversation"("p_business_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."recommend_businesses_discovery"("p_tourist_id" "uuid", "p_lat" double precision, "p_lng" double precision, "p_radius_m" integer DEFAULT NULL::integer, "p_limit" integer DEFAULT NULL::integer) RETURNS TABLE("rank_position" integer, "business_id" "uuid", "business_name" "text", "category_slug" "text", "distance_m" numeric, "score_total" numeric, "score_relevance" numeric, "score_proximity" numeric, "score_quality" numeric, "score_exposure" numeric, "score_context" numeric, "reason_tag" "text", "is_verified" boolean, "total_visits" integer, "average_rating" double precision)
    LANGUAGE "plpgsql" STABLE
    AS $$
declare
  v_radius_m    integer;
  v_limit       integer;
  v_w_rel       numeric := get_config('weight.relevance');
  v_w_prox      numeric := get_config('weight.proximity');
  v_w_qual      numeric := get_config('weight.quality');
  v_w_exp       numeric := get_config('weight.exposure_boost');
  v_w_ctx       numeric := get_config('weight.context_fit');
  v_equity_slots       integer := get_config('discovery.equity_slots')::integer;
  v_equity_min_pos     integer := get_config('discovery.equity_min_position')::integer;
  v_equity_max_pos     integer := get_config('discovery.equity_max_position')::integer;
  v_floor_rating       numeric := get_config('quality_floor.min_rating');
  v_floor_reviews      integer := get_config('quality_floor.min_reviews')::integer;
  v_floor_new_days     integer := get_config('quality_floor.new_business_days')::integer;
  v_tourist_lang_id  uuid;
  v_tourist_diet     dietary_restriction;
  v_tourist_budget   budget_range;
begin
  v_radius_m := coalesce(p_radius_m, get_config('search.default_radius_m')::integer);
  v_limit    := coalesce(p_limit,    get_config('search.default_limit')::integer);

  select pl.language_id, p.dietary_restriction, p.budget_range
    into v_tourist_lang_id, v_tourist_diet, v_tourist_budget
  from profiles p
  left join profile_languages pl on pl.profile_id = p.id and pl.is_preferred = true
  where p.id = p_tourist_id;

  return query
  with 
  candidates as (
    select 
      b.id, b.name, b.category_id, b.is_verified, b.total_visits, b.average_rating, b.created_at,
      ST_Distance(
        b.location, 
        ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography
      ) as dist_m,
      (
        select count(*) from visits v 
        where v.business_id = b.id 
          and v.visited_at > now() - interval '24 hours'
      ) as visits_24h,
      (
        select count(*) from reviews r 
        where r.business_id = b.id
      ) as review_count
    from businesses b
    where b.is_active = true
      and ST_DWithin(
        b.location, 
        ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography, 
        v_radius_m
      )
  ),
  scored as (
    select 
      c.*,
      cat.slug as cat_slug,
      (
        0.80 * (
          (
            case when exists (
              select 1 from business_translations bt 
              where bt.business_id = c.id and bt.language_id = v_tourist_lang_id
            ) then 1.0 else 0.0 end
            +
            case when exists (
              select 1 from profile_category_interests pci
              where pci.profile_id = p_tourist_id and pci.category_id = c.category_id
            ) then 1.0 else 0.0 end
          ) / 2.0
        )
        +
        case 
          when v_tourist_diet = 'none' then 0.10
          when cat.slug <> 'gastronomia' then 0.10
          else 0.0
        end
        +
        case 
          when v_tourist_budget = 'high' and cat.slug in ('gastronomia','hospedaje','bienestar') then 0.10
          when v_tourist_budget = 'medium' then 0.10
          when v_tourist_budget = 'low' and cat.slug in ('artesanias','transporte','compras','tours') then 0.10
          else 0.0
        end
      )::numeric as s_relevance,
      exp(-c.dist_m / 1000.0)::numeric as s_proximity,
      (coalesce(c.average_rating, 3.0) / 5.0)::numeric as s_quality,
      (1.0 / (1.0 + c.visits_24h))::numeric as s_exposure,
      1.0::numeric as s_context
    from candidates c
    join categories cat on cat.id = c.category_id
  ),
  quality_ranked as (
    select 
      s.*,
      (
        v_w_rel  * s.s_relevance +
        v_w_prox * s.s_proximity +
        v_w_qual * s.s_quality +
        0.0      * s.s_exposure +
        v_w_ctx  * s.s_context
      )::numeric as s_quality_total,
      row_number() over (order by 
        v_w_rel  * s.s_relevance +
        v_w_prox * s.s_proximity +
        v_w_qual * s.s_quality +
        v_w_ctx  * s.s_context
        desc
      ) as quality_rank
    from scored s
  ),
  pool_a as (
    select *, 'top_quality'::text as reason_tag
    from quality_ranked
    where quality_rank <= v_limit - v_equity_slots
  ),
  pool_b_eligible as (
    select 
      s.*,
      (
        v_w_rel  * s.s_relevance +
        v_w_prox * s.s_proximity +
        v_w_qual * s.s_quality +
        v_w_exp  * s.s_exposure +
        v_w_ctx  * s.s_context
      )::numeric as s_discovery_total
    from scored s
    where s.visits_24h <= 2
      and s.id not in (select id from pool_a)
      and (
        s.is_verified = true
        or (s.average_rating >= v_floor_rating and s.review_count >= v_floor_reviews)
        or (s.created_at > now() - (v_floor_new_days || ' days')::interval and s.is_verified = true)
      )
  ),
  pool_b as (
    select 
      pbe.id, pbe.name, pbe.cat_slug, pbe.dist_m,
      pbe.s_discovery_total as s_quality_total,
      pbe.s_relevance, pbe.s_proximity, pbe.s_quality, pbe.s_exposure, pbe.s_context,
      pbe.is_verified, pbe.total_visits, pbe.average_rating,
      'equity_boost'::text as reason_tag,
      row_number() over (order by pbe.s_discovery_total desc) as pool_b_rank
    from pool_b_eligible pbe
  ),
  equity_positions as (
    select 
      pos,
      row_number() over (order by random()) as slot_n
    from generate_series(v_equity_min_pos, v_equity_max_pos) as pos
    limit v_equity_slots
  ),
  equity_placed as (
    select 
      ep.pos as final_position,
      pb.id, pb.name, pb.cat_slug, pb.dist_m, pb.s_quality_total,
      pb.s_relevance, pb.s_proximity, pb.s_quality, pb.s_exposure, pb.s_context,
      pb.reason_tag, pb.is_verified, pb.total_visits, pb.average_rating
    from pool_b pb
    join equity_positions ep on ep.slot_n = pb.pool_b_rank
    where pb.pool_b_rank <= v_equity_slots
  ),
  reserved_positions as (
    select final_position from equity_placed
  ),
  available_positions as (
    select p as final_position
    from generate_series(1, v_limit) as p
    where p not in (select final_position from reserved_positions)
    order by p
  ),
  pool_a_placed as (
    select 
      ap.final_position,
      pa.id, pa.name, pa.cat_slug, pa.dist_m, pa.s_quality_total,
      pa.s_relevance, pa.s_proximity, pa.s_quality, pa.s_exposure, pa.s_context,
      pa.reason_tag, pa.is_verified, pa.total_visits, pa.average_rating
    from (
      select *, row_number() over (order by quality_rank) as pa_n
      from pool_a
    ) pa
    join (
      select final_position, row_number() over (order by final_position) as ap_n
      from available_positions
    ) ap on ap.ap_n = pa.pa_n
  ),
  combined as (
    select * from equity_placed
    union all
    select * from pool_a_placed
  )
  select 
    c.final_position::integer as rank_position,
    c.id,
    c.name,
    c.cat_slug,
    round(c.dist_m::numeric, 0),
    round(c.s_quality_total, 4),
    round(c.s_relevance, 4),
    round(c.s_proximity, 4),
    round(c.s_quality, 4),
    round(c.s_exposure, 4),
    round(c.s_context, 4),
    c.reason_tag,
    c.is_verified,
    c.total_visits,
    c.average_rating
  from combined c
  order by c.final_position;
end;
$$;


ALTER FUNCTION "public"."recommend_businesses_discovery"("p_tourist_id" "uuid", "p_lat" double precision, "p_lng" double precision, "p_radius_m" integer, "p_limit" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."recommend_businesses_top_quality"("p_tourist_id" "uuid", "p_lat" double precision, "p_lng" double precision, "p_radius_m" integer DEFAULT NULL::integer, "p_limit" integer DEFAULT NULL::integer) RETURNS TABLE("business_id" "uuid", "business_name" "text", "category_slug" "text", "distance_m" numeric, "score_total" numeric, "score_relevance" numeric, "score_proximity" numeric, "score_quality" numeric, "score_exposure" numeric, "score_context" numeric, "reason_tag" "text", "is_verified" boolean, "total_visits" integer, "average_rating" double precision)
    LANGUAGE "plpgsql" STABLE
    AS $$
declare
  v_radius_m integer;
  v_limit    integer;
  v_w_rel    numeric := get_config('weight.relevance');
  v_w_prox   numeric := get_config('weight.proximity');
  v_w_qual   numeric := get_config('weight.quality');
  v_w_ctx    numeric := get_config('weight.context_fit');
  v_tourist_lang_id  uuid;
  v_tourist_diet     dietary_restriction;
  v_tourist_budget   budget_range;
begin
  v_radius_m := coalesce(p_radius_m, get_config('search.default_radius_m')::integer);
  v_limit    := coalesce(p_limit,    get_config('search.default_limit')::integer);

  select pl.language_id, p.dietary_restriction, p.budget_range
    into v_tourist_lang_id, v_tourist_diet, v_tourist_budget
  from profiles p
  left join profile_languages pl on pl.profile_id = p.id and pl.is_preferred = true
  where p.id = p_tourist_id;

  return query
  with 
  candidates as (
    select 
      b.id, b.name, b.category_id, b.is_verified, b.total_visits, b.average_rating,
      ST_Distance(
        b.location, 
        ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography
      ) as dist_m
    from businesses b
    where b.is_active = true
      and ST_DWithin(
        b.location, 
        ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography, 
        v_radius_m
      )
  ),
  scored as (
    select 
      c.*,
      cat.slug as cat_slug,
      -- ============================================================
      -- RELEVANCE v2: core multiplicativo (idioma + categoría)
      -- + bonus pequeños (dieta + presupuesto)
      -- ============================================================
      (
        -- Core: 0.80 * promedio(idioma_match, categoria_match)
        0.80 * (
          (
            case when exists (
              select 1 from business_translations bt 
              where bt.business_id = c.id and bt.language_id = v_tourist_lang_id
            ) then 1.0 else 0.0 end
            +
            case when exists (
              select 1 from profile_category_interests pci
              where pci.profile_id = p_tourist_id and pci.category_id = c.category_id
            ) then 1.0 else 0.0 end
          ) / 2.0
        )
        +
        -- Bonus dieta
        case 
          when v_tourist_diet = 'none' then 0.10
          when cat.slug <> 'gastronomia' then 0.10
          else 0.0
        end
        +
        -- Bonus presupuesto
        case 
          when v_tourist_budget = 'high' and cat.slug in ('gastronomia','hospedaje','bienestar') then 0.10
          when v_tourist_budget = 'medium' then 0.10
          when v_tourist_budget = 'low' and cat.slug in ('artesanias','transporte','compras','tours') then 0.10
          else 0.0
        end
      )::numeric as s_relevance,

      exp(-c.dist_m / 1000.0)::numeric as s_proximity,

      (coalesce(c.average_rating, 3.0) / 5.0)::numeric as s_quality,

      (1.0 / (1.0 + (
        select count(*) from visits v 
        where v.business_id = c.id 
          and v.visited_at > now() - interval '24 hours'
      )))::numeric as s_exposure,

      1.0::numeric as s_context
    from candidates c
    join categories cat on cat.id = c.category_id
  ),
  ranked as (
    select 
      s.*,
      (
        v_w_rel  * s.s_relevance +
        v_w_prox * s.s_proximity +
        v_w_qual * s.s_quality +
        0.0      * s.s_exposure +  -- top_quality: peso 0
        v_w_ctx  * s.s_context
      )::numeric as s_total
    from scored s
  )
  select 
    r.id,
    r.name,
    r.cat_slug,
    round(r.dist_m::numeric, 0) as distance_m,
    round(r.s_total, 4)         as score_total,
    round(r.s_relevance, 4),
    round(r.s_proximity, 4),
    round(r.s_quality, 4),
    round(r.s_exposure, 4),
    round(r.s_context, 4),
    'top_quality'::text         as reason_tag,
    r.is_verified,
    r.total_visits,
    r.average_rating
  from ranked r
  order by r.s_total desc
  limit v_limit;
end;
$$;


ALTER FUNCTION "public"."recommend_businesses_top_quality"("p_tourist_id" "uuid", "p_lat" double precision, "p_lng" double precision, "p_radius_m" integer, "p_limit" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rls_auto_enable"() RETURNS "event_trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'pg_catalog'
    AS $$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN
    SELECT *
    FROM pg_event_trigger_ddl_commands()
    WHERE command_tag IN ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
      AND object_type IN ('table','partitioned table')
  LOOP
     IF cmd.schema_name IS NOT NULL AND cmd.schema_name IN ('public') AND cmd.schema_name NOT IN ('pg_catalog','information_schema') AND cmd.schema_name NOT LIKE 'pg_toast%' AND cmd.schema_name NOT LIKE 'pg_temp%' THEN
      BEGIN
        EXECUTE format('alter table if exists %s enable row level security', cmd.object_identity);
        RAISE LOG 'rls_auto_enable: enabled RLS on %', cmd.object_identity;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE LOG 'rls_auto_enable: failed to enable RLS on %', cmd.object_identity;
      END;
     ELSE
        RAISE LOG 'rls_auto_enable: skip % (either system schema or not in enforced list: %.)', cmd.object_identity, cmd.schema_name;
     END IF;
  END LOOP;
END;
$$;


ALTER FUNCTION "public"."rls_auto_enable"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."set_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."tg_mp_accounts_set_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin
  new.updated_at := now();
  return new;
end;
$$;


ALTER FUNCTION "public"."tg_mp_accounts_set_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."trg_businesses_translate_description"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
begin
  -- Solo dispara si hay descripción no vacía
  if new.description is null or btrim(new.description) = '' then
    return new;
  end if;

  -- En UPDATE, solo si la descripción realmente cambió
  if tg_op = 'UPDATE' and old.description is not distinct from new.description then
    return new;
  end if;

  perform public.invoke_edge_function(
    'translate-business-description',
    jsonb_build_object(
      'business_id', new.id,
      'source_description', new.description,
      'source_lang', 'es',
      'overwrite', true
    )
  );

  return new;
end;
$$;


ALTER FUNCTION "public"."trg_businesses_translate_description"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."trg_offerings_translate"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
begin
  -- Solo dispara si hay source_name no vacío
  if new.source_name is null or btrim(new.source_name) = '' then
    return new;
  end if;

  -- En UPDATE, solo si source_name o source_description cambiaron
  if tg_op = 'UPDATE'
     and old.source_name is not distinct from new.source_name
     and old.source_description is not distinct from new.source_description then
    return new;
  end if;

  perform public.invoke_edge_function(
    'translate-offering-description',
    jsonb_build_object(
      'offering_id', new.id,
      'source_name', new.source_name,
      'source_description', new.source_description,
      'source_lang', 'es',
      'overwrite', true
    )
  );

  return new;
end;
$$;


ALTER FUNCTION "public"."trg_offerings_translate"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."trg_update_business_rating"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
declare
  v_business_id uuid;
begin
  v_business_id := coalesce(NEW.business_id, OLD.business_id);
  
  update businesses
  set average_rating = (
    select round(avg(rating)::numeric, 2)::float8
    from reviews
    where business_id = v_business_id
  ),
  updated_at = now()
  where id = v_business_id;
  
  return coalesce(NEW, OLD);
end;
$$;


ALTER FUNCTION "public"."trg_update_business_rating"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."trg_update_business_visits"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin
  update businesses
  set total_visits = total_visits + 1,
      updated_at = now()
  where id = NEW.business_id;
  return NEW;
end;
$$;


ALTER FUNCTION "public"."trg_update_business_visits"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_community_member_count"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE communities SET member_count = member_count + 1 WHERE id = NEW.community_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE communities SET member_count = member_count - 1 WHERE id = OLD.community_id;
  END IF;
  RETURN NULL;
END;
$$;


ALTER FUNCTION "public"."update_community_member_count"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."validate_message_content"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin
  if new.content is null
     and new.shared_business_id is null
     and new.shared_route_id    is null then
    raise exception 'Un mensaje debe tener texto, negocio o ruta compartida';
  end if;
  return new;
end $$;


ALTER FUNCTION "public"."validate_message_content"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."algorithm_config" (
    "key" "text" NOT NULL,
    "value" numeric NOT NULL,
    "description" "text",
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."algorithm_config" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."analytics_events" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid",
    "event_type" "text" NOT NULL,
    "event_data" "jsonb",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."analytics_events" OWNER TO "postgres";


COMMENT ON TABLE "public"."analytics_events" IS 'Eventos genéricos de la app (append-only). Anonimizable.';



COMMENT ON COLUMN "public"."analytics_events"."user_id" IS 'NULL permitido para eventos anónimos o tras borrar cuenta';



COMMENT ON COLUMN "public"."analytics_events"."event_type" IS 'page_view, search, filter, qr_scan, etc.';



CREATE TABLE IF NOT EXISTS "public"."business_images" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "business_id" "uuid" NOT NULL,
    "image_url" "text" NOT NULL,
    "alt_text" "text",
    "sort_order" integer DEFAULT 0 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."business_images" OWNER TO "postgres";


COMMENT ON TABLE "public"."business_images" IS 'Galería de imágenes del negocio (Cloudinary URLs)';



CREATE TABLE IF NOT EXISTS "public"."business_translations" (
    "business_id" "uuid" NOT NULL,
    "language_id" "uuid" NOT NULL,
    "description" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."business_translations" OWNER TO "postgres";


COMMENT ON TABLE "public"."business_translations" IS 'Descripciones del negocio en cada idioma (generadas por IA)';



CREATE TABLE IF NOT EXISTS "public"."businesses" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "owner_id" "uuid" NOT NULL,
    "category_id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "phone" "text",
    "address" "text",
    "latitude" double precision NOT NULL,
    "longitude" double precision NOT NULL,
    "location" "extensions"."geography"(Point,4326) GENERATED ALWAYS AS (("extensions"."st_setsrid"("extensions"."st_makepoint"("longitude", "latitude"), 4326))::"extensions"."geography") STORED,
    "schedule" "jsonb",
    "cover_image_url" "text",
    "is_verified" boolean DEFAULT false NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    "exposure_score" double precision DEFAULT 0 NOT NULL,
    "total_visits" integer DEFAULT 0 NOT NULL,
    "average_rating" double precision,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "description" "text",
    CONSTRAINT "valid_latitude" CHECK ((("latitude" >= ('-90'::integer)::double precision) AND ("latitude" <= (90)::double precision))),
    CONSTRAINT "valid_longitude" CHECK ((("longitude" >= ('-180'::integer)::double precision) AND ("longitude" <= (180)::double precision))),
    CONSTRAINT "valid_rating" CHECK ((("average_rating" IS NULL) OR (("average_rating" >= (0)::double precision) AND ("average_rating" <= (5)::double precision))))
);


ALTER TABLE "public"."businesses" OWNER TO "postgres";


COMMENT ON TABLE "public"."businesses" IS 'Tabla central: perfil digital de cada micronegocio turístico';



COMMENT ON COLUMN "public"."businesses"."location" IS 'Columna geográfica generada automáticamente desde lat/lng para búsquedas PostGIS';



COMMENT ON COLUMN "public"."businesses"."exposure_score" IS 'Score del algoritmo de balanceo justo de exposición (índice de Gini)';



COMMENT ON COLUMN "public"."businesses"."description" IS 'Descripción fuente en español escrita por el microempresario. Las traducciones a otros idiomas viven en business_translations y se generan por IA.';



CREATE TABLE IF NOT EXISTS "public"."categories" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "slug" "text" NOT NULL,
    "icon" "text",
    "sort_order" integer DEFAULT 0 NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."categories" OWNER TO "postgres";


COMMENT ON TABLE "public"."categories" IS 'Catálogo de giros: gastronomía, artesanías, hospedaje, etc.';



CREATE TABLE IF NOT EXISTS "public"."category_translations" (
    "category_id" "uuid" NOT NULL,
    "language_id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "description" "text"
);


ALTER TABLE "public"."category_translations" OWNER TO "postgres";


COMMENT ON TABLE "public"."category_translations" IS 'Traducciones de nombres y descripciones de categorías';



CREATE TABLE IF NOT EXISTS "public"."communities" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "creator_id" "uuid" NOT NULL,
    "slug" "text" NOT NULL,
    "name" "text" NOT NULL,
    "description" "text",
    "cover_image_url" "text",
    "icon_url" "text",
    "member_count" integer DEFAULT 0 NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "valid_member_count" CHECK (("member_count" >= 0)),
    CONSTRAINT "valid_slug" CHECK ((("slug" ~ '^[a-z0-9-]+$'::"text") AND (("char_length"("slug") >= 3) AND ("char_length"("slug") <= 50))))
);


ALTER TABLE "public"."communities" OWNER TO "postgres";


COMMENT ON TABLE "public"."communities" IS 'Comunidades temáticas creadas por usuarios. Abiertas en MVP.';



COMMENT ON COLUMN "public"."communities"."slug" IS 'URL-friendly: solo minúsculas, números y guiones';



COMMENT ON COLUMN "public"."communities"."member_count" IS 'Contador desnormalizado, actualizado por trigger';



CREATE TABLE IF NOT EXISTS "public"."community_members" (
    "community_id" "uuid" NOT NULL,
    "profile_id" "uuid" NOT NULL,
    "role" "public"."community_role" DEFAULT 'member'::"public"."community_role" NOT NULL,
    "joined_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."community_members" OWNER TO "postgres";


COMMENT ON TABLE "public"."community_members" IS 'Membresía N:M usuario-comunidad con rol';



CREATE TABLE IF NOT EXISTS "public"."community_messages" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "community_id" "uuid" NOT NULL,
    "sender_id" "uuid" NOT NULL,
    "content" "text",
    "shared_business_id" "uuid",
    "shared_route_id" "uuid",
    "reply_to_id" "uuid",
    "is_deleted" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "at_least_one_content" CHECK ((("content" IS NOT NULL) OR ("shared_business_id" IS NOT NULL) OR ("shared_route_id" IS NOT NULL)))
);

ALTER TABLE ONLY "public"."community_messages" REPLICA IDENTITY FULL;


ALTER TABLE "public"."community_messages" OWNER TO "postgres";


COMMENT ON TABLE "public"."community_messages" IS 'Mensajes del chat. Texto, share de negocio/ruta, o respuesta.';



CREATE TABLE IF NOT EXISTS "public"."conversations" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "buyer_id" "uuid" NOT NULL,
    "business_id" "uuid" NOT NULL,
    "owner_id" "uuid" NOT NULL,
    "last_message_at" timestamp with time zone,
    "last_message_preview" "text",
    "buyer_unread" integer DEFAULT 0 NOT NULL,
    "owner_unread" integer DEFAULT 0 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."conversations" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."direct_messages" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "conversation_id" "uuid" NOT NULL,
    "sender_id" "uuid" NOT NULL,
    "content" "text",
    "shared_offering_id" "uuid",
    "is_read" boolean DEFAULT false NOT NULL,
    "is_deleted" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "direct_messages_check" CHECK ((("content" IS NOT NULL) OR ("shared_offering_id" IS NOT NULL)))
);


ALTER TABLE "public"."direct_messages" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."geofences" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "latitude" double precision NOT NULL,
    "longitude" double precision NOT NULL,
    "location" "extensions"."geography"(Point,4326) GENERATED ALWAYS AS (("extensions"."st_setsrid"("extensions"."st_makepoint"("longitude", "latitude"), 4326))::"extensions"."geography") STORED,
    "radius_m" integer DEFAULT 500 NOT NULL,
    "threshold_users" integer NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "valid_geofence_latitude" CHECK ((("latitude" >= ('-90'::integer)::double precision) AND ("latitude" <= (90)::double precision))),
    CONSTRAINT "valid_geofence_longitude" CHECK ((("longitude" >= ('-180'::integer)::double precision) AND ("longitude" <= (180)::double precision))),
    CONSTRAINT "valid_radius" CHECK ((("radius_m" > 0) AND ("radius_m" <= 10000))),
    CONSTRAINT "valid_threshold" CHECK (("threshold_users" > 0))
);


ALTER TABLE "public"."geofences" OWNER TO "postgres";


COMMENT ON TABLE "public"."geofences" IS 'Zonas virtuales para detección de hotspots (Estadio Azteca, Zócalo, etc.)';



COMMENT ON COLUMN "public"."geofences"."radius_m" IS 'Radio en metros, máximo 10km';



COMMENT ON COLUMN "public"."geofences"."threshold_users" IS 'Umbral de usuarios para disparar evento hotspot';



CREATE TABLE IF NOT EXISTS "public"."hotspot_events" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "geofence_id" "uuid" NOT NULL,
    "user_count" integer NOT NULL,
    "detected_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "valid_user_count" CHECK (("user_count" > 0))
);


ALTER TABLE "public"."hotspot_events" OWNER TO "postgres";


COMMENT ON TABLE "public"."hotspot_events" IS 'Historial de detecciones de alta concentración de usuarios';



CREATE TABLE IF NOT EXISTS "public"."languages" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "code" "text" NOT NULL,
    "name_native" "text" NOT NULL,
    "name_es" "text" NOT NULL,
    "flag_emoji" "text",
    "is_active" boolean DEFAULT true NOT NULL
);


ALTER TABLE "public"."languages" OWNER TO "postgres";


COMMENT ON TABLE "public"."languages" IS 'Catálogo de idiomas soportados en la plataforma';



COMMENT ON COLUMN "public"."languages"."code" IS 'Código ISO 639-1: es, en, pt, fr';



CREATE TABLE IF NOT EXISTS "public"."message_reactions" (
    "message_id" "uuid" NOT NULL,
    "profile_id" "uuid" NOT NULL,
    "emoji" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "valid_emoji" CHECK ((("char_length"("emoji") >= 1) AND ("char_length"("emoji") <= 16)))
);

ALTER TABLE ONLY "public"."message_reactions" REPLICA IDENTITY FULL;


ALTER TABLE "public"."message_reactions" OWNER TO "postgres";


COMMENT ON TABLE "public"."message_reactions" IS 'Reacciones emoji a mensajes. Un usuario puede poner varios emojis distintos.';



CREATE TABLE IF NOT EXISTS "public"."mp_accounts" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "business_id" "uuid" NOT NULL,
    "mp_user_id" "text" NOT NULL,
    "public_key" "text",
    "live_mode" boolean DEFAULT false NOT NULL,
    "scope" "text",
    "access_token" "text" NOT NULL,
    "refresh_token" "text" NOT NULL,
    "expires_at" timestamp with time zone NOT NULL,
    "connected_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "last_refreshed_at" timestamp with time zone
);


ALTER TABLE "public"."mp_accounts" OWNER TO "postgres";


COMMENT ON TABLE "public"."mp_accounts" IS 'OAuth de Mercado Pago por microempresario. Lectura/escritura solo vía Edge Function con service_role.';



COMMENT ON COLUMN "public"."mp_accounts"."mp_user_id" IS 'ID del vendedor en MP (campo user_id de la respuesta de /oauth/token).';



COMMENT ON COLUMN "public"."mp_accounts"."expires_at" IS 'Fecha de expiración del access_token. Renovar con refresh_token antes de esta fecha.';



CREATE TABLE IF NOT EXISTS "public"."mp_oauth_states" (
    "state" "text" NOT NULL,
    "business_id" "uuid" NOT NULL,
    "owner_id" "uuid" NOT NULL,
    "code_verifier" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "expires_at" timestamp with time zone DEFAULT ("now"() + '00:10:00'::interval) NOT NULL,
    "consumed_at" timestamp with time zone
);


ALTER TABLE "public"."mp_oauth_states" OWNER TO "postgres";


COMMENT ON TABLE "public"."mp_oauth_states" IS 'States temporales del flujo OAuth de MP. Solo escribe/lee Edge Functions con service_role.';



CREATE TABLE IF NOT EXISTS "public"."notifications" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "title" "text" NOT NULL,
    "body" "text" NOT NULL,
    "type" "public"."notification_type" NOT NULL,
    "data" "jsonb",
    "is_read" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."notifications" OWNER TO "postgres";


COMMENT ON TABLE "public"."notifications" IS 'Push notifications enviadas vía Firebase FCM';



COMMENT ON COLUMN "public"."notifications"."data" IS 'Payload para deep-linking (ej: {business_id, route_id})';



CREATE TABLE IF NOT EXISTS "public"."offering_translations" (
    "offering_id" "uuid" NOT NULL,
    "language_id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "description" "text"
);


ALTER TABLE "public"."offering_translations" OWNER TO "postgres";


COMMENT ON TABLE "public"."offering_translations" IS 'Nombres y descripciones de productos/servicios por idioma';



CREATE TABLE IF NOT EXISTS "public"."offerings" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "business_id" "uuid" NOT NULL,
    "type" "public"."offering_type" NOT NULL,
    "price_mxn" numeric(10,2) NOT NULL,
    "price_type" "public"."price_type" DEFAULT 'fixed'::"public"."price_type" NOT NULL,
    "duration_min" integer,
    "image_url" "text",
    "is_active" boolean DEFAULT true NOT NULL,
    "sort_order" integer DEFAULT 0 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "source_name" "text",
    "source_description" "text",
    CONSTRAINT "service_or_product_duration" CHECK (((("type" = 'product'::"public"."offering_type") AND ("duration_min" IS NULL)) OR ("type" = 'service'::"public"."offering_type"))),
    CONSTRAINT "valid_duration" CHECK ((("duration_min" IS NULL) OR ("duration_min" > 0))),
    CONSTRAINT "valid_price" CHECK (("price_mxn" >= (0)::numeric))
);


ALTER TABLE "public"."offerings" OWNER TO "postgres";


COMMENT ON TABLE "public"."offerings" IS 'Productos y servicios del negocio. Discriminador en type.';



COMMENT ON COLUMN "public"."offerings"."duration_min" IS 'Duración en minutos. Solo aplica a servicios.';



COMMENT ON COLUMN "public"."offerings"."source_name" IS 'Nombre fuente en español escrito por el microempresario. Las traducciones viven en offering_translations y se generan por IA.';



COMMENT ON COLUMN "public"."offerings"."source_description" IS 'Descripción fuente en español escrita por el microempresario. Las traducciones viven en offering_translations.';



CREATE TABLE IF NOT EXISTS "public"."profile_category_interests" (
    "profile_id" "uuid" NOT NULL,
    "category_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."profile_category_interests" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."profile_languages" (
    "profile_id" "uuid" NOT NULL,
    "language_id" "uuid" NOT NULL,
    "is_preferred" boolean DEFAULT false NOT NULL,
    "proficiency" "public"."language_proficiency",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."profile_languages" OWNER TO "postgres";


COMMENT ON TABLE "public"."profile_languages" IS 'Idiomas que habla cada usuario, con preferencia y nivel';



CREATE TABLE IF NOT EXISTS "public"."profiles" (
    "id" "uuid" NOT NULL,
    "role" "public"."user_role" DEFAULT 'turista'::"public"."user_role" NOT NULL,
    "full_name" "text",
    "avatar_url" "text",
    "nationality" "text",
    "phone" "text",
    "onboarding_completed" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "dietary_restriction" "public"."dietary_restriction" DEFAULT 'none'::"public"."dietary_restriction" NOT NULL,
    "budget_range" "public"."budget_range" DEFAULT 'medium'::"public"."budget_range" NOT NULL,
    "accessibility_need" "public"."accessibility_need" DEFAULT 'none'::"public"."accessibility_need" NOT NULL
);


ALTER TABLE "public"."profiles" OWNER TO "postgres";


COMMENT ON TABLE "public"."profiles" IS 'Perfil extendido de los usuarios (microempresarios, turistas, admins)';



COMMENT ON COLUMN "public"."profiles"."id" IS 'Referencia directa a auth.users.id de Supabase';



CREATE TABLE IF NOT EXISTS "public"."reviews" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "tourist_id" "uuid" NOT NULL,
    "business_id" "uuid" NOT NULL,
    "rating" smallint NOT NULL,
    "comment" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "valid_rating_range" CHECK ((("rating" >= 1) AND ("rating" <= 5)))
);


ALTER TABLE "public"."reviews" OWNER TO "postgres";


COMMENT ON TABLE "public"."reviews" IS 'Reseñas de turistas. Una reseña por par turista-negocio.';



CREATE TABLE IF NOT EXISTS "public"."route_stops" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "route_id" "uuid" NOT NULL,
    "business_id" "uuid" NOT NULL,
    "stop_order" integer NOT NULL,
    "estimated_time_min" integer,
    CONSTRAINT "valid_stop_order" CHECK (("stop_order" > 0)),
    CONSTRAINT "valid_stop_time" CHECK ((("estimated_time_min" IS NULL) OR ("estimated_time_min" > 0)))
);


ALTER TABLE "public"."route_stops" OWNER TO "postgres";


COMMENT ON TABLE "public"."route_stops" IS 'Paradas ordenadas de una ruta turística';



CREATE TABLE IF NOT EXISTS "public"."routes" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "tourist_id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "type" "public"."route_type" NOT NULL,
    "total_estimated_time_min" integer,
    "total_estimated_cost_mxn" numeric(10,2),
    "polyline" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "valid_cost" CHECK ((("total_estimated_cost_mxn" IS NULL) OR ("total_estimated_cost_mxn" >= (0)::numeric))),
    CONSTRAINT "valid_time" CHECK ((("total_estimated_time_min" IS NULL) OR ("total_estimated_time_min" > 0)))
);


ALTER TABLE "public"."routes" OWNER TO "postgres";


COMMENT ON TABLE "public"."routes" IS 'Rutas turísticas optimizadas generadas por el sistema';



COMMENT ON COLUMN "public"."routes"."polyline" IS 'Polyline codificada de Google Directions API';



CREATE TABLE IF NOT EXISTS "public"."survey_question_translations" (
    "question_id" "uuid" NOT NULL,
    "language_id" "uuid" NOT NULL,
    "question_text" "text" NOT NULL,
    "options" "jsonb"
);


ALTER TABLE "public"."survey_question_translations" OWNER TO "postgres";


COMMENT ON TABLE "public"."survey_question_translations" IS 'Texto de preguntas y opciones traducidas';



COMMENT ON COLUMN "public"."survey_question_translations"."options" IS 'Array JSON de opciones para single_choice y multiple_choice';



CREATE TABLE IF NOT EXISTS "public"."survey_questions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "survey_id" "uuid" NOT NULL,
    "question_type" "public"."question_type" NOT NULL,
    "sort_order" integer DEFAULT 0 NOT NULL
);


ALTER TABLE "public"."survey_questions" OWNER TO "postgres";


COMMENT ON TABLE "public"."survey_questions" IS 'Preguntas individuales de cada encuesta (el texto va en translations)';



CREATE TABLE IF NOT EXISTS "public"."survey_responses" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "survey_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "business_id" "uuid",
    "answers" "jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "answers_is_object" CHECK (("jsonb_typeof"("answers") = 'object'::"text"))
);


ALTER TABLE "public"."survey_responses" OWNER TO "postgres";


COMMENT ON TABLE "public"."survey_responses" IS 'Respuestas de usuarios a encuestas. business_id solo aplica en post_visit y vote.';



COMMENT ON COLUMN "public"."survey_responses"."answers" IS 'Objeto JSON con formato {question_id: answer}';



CREATE TABLE IF NOT EXISTS "public"."survey_translations" (
    "survey_id" "uuid" NOT NULL,
    "language_id" "uuid" NOT NULL,
    "title" "text" NOT NULL,
    "description" "text"
);


ALTER TABLE "public"."survey_translations" OWNER TO "postgres";


COMMENT ON TABLE "public"."survey_translations" IS 'Títulos y descripciones de las encuestas por idioma';



CREATE TABLE IF NOT EXISTS "public"."surveys" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "type" "public"."survey_type" NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."surveys" OWNER TO "postgres";


COMMENT ON TABLE "public"."surveys" IS 'Las 6 micro-encuestas del sistema: post_visit, demand, trend, experience, vote, onboarding';



CREATE TABLE IF NOT EXISTS "public"."training_progress" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "module_id" "text" NOT NULL,
    "module_name" "text" NOT NULL,
    "progress_percent" integer DEFAULT 0 NOT NULL,
    "completed_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "completion_consistency" CHECK (((("progress_percent" = 100) AND ("completed_at" IS NOT NULL)) OR (("progress_percent" < 100) AND ("completed_at" IS NULL)))),
    CONSTRAINT "valid_progress" CHECK ((("progress_percent" >= 0) AND ("progress_percent" <= 100)))
);


ALTER TABLE "public"."training_progress" OWNER TO "postgres";


COMMENT ON TABLE "public"."training_progress" IS 'Progreso de microempresarios en módulos de Coppel Emprende';



COMMENT ON COLUMN "public"."training_progress"."module_id" IS 'ID externo del módulo en la plataforma de Coppel Emprende';



CREATE TABLE IF NOT EXISTS "public"."transactions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "tourist_id" "uuid",
    "business_id" "uuid" NOT NULL,
    "amount_mxn" numeric(10,2) NOT NULL,
    "currency_original" "text" NOT NULL,
    "amount_original" numeric(10,2) NOT NULL,
    "exchange_rate" numeric(12,6) NOT NULL,
    "payment_method" "public"."payment_method" NOT NULL,
    "payment_provider_id" "text",
    "status" "public"."payment_status" DEFAULT 'pending'::"public"."payment_status" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "mp_preference_id" "text",
    CONSTRAINT "valid_amount_mxn" CHECK (("amount_mxn" > (0)::numeric)),
    CONSTRAINT "valid_amount_original" CHECK (("amount_original" > (0)::numeric)),
    CONSTRAINT "valid_currency_code" CHECK (("char_length"("currency_original") = 3)),
    CONSTRAINT "valid_exchange_rate" CHECK (("exchange_rate" > (0)::numeric))
);


ALTER TABLE "public"."transactions" OWNER TO "postgres";


COMMENT ON TABLE "public"."transactions" IS 'Pagos digitales (Stripe/MP) y registros de pagos en efectivo';



COMMENT ON COLUMN "public"."transactions"."amount_mxn" IS 'Lo que recibe el negocio, siempre en pesos mexicanos';



COMMENT ON COLUMN "public"."transactions"."currency_original" IS 'Código ISO 4217: USD, EUR, BRL, CAD, etc.';



COMMENT ON COLUMN "public"."transactions"."mp_preference_id" IS 'ID de la preferencia de Mercado Pago (Checkout Pro). Se llena al crear el cobro; el payment_id real llega después por webhook y se guarda en payment_provider_id.';



CREATE TABLE IF NOT EXISTS "public"."visits" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "tourist_id" "uuid" NOT NULL,
    "business_id" "uuid" NOT NULL,
    "source" "public"."visit_source" NOT NULL,
    "visited_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."visits" OWNER TO "postgres";


COMMENT ON TABLE "public"."visits" IS 'Registro de cada interacción turista-negocio para analytics y balanceo';



ALTER TABLE ONLY "public"."algorithm_config"
    ADD CONSTRAINT "algorithm_config_pkey" PRIMARY KEY ("key");



ALTER TABLE ONLY "public"."analytics_events"
    ADD CONSTRAINT "analytics_events_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."business_images"
    ADD CONSTRAINT "business_images_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."business_translations"
    ADD CONSTRAINT "business_translations_pkey" PRIMARY KEY ("business_id", "language_id");



ALTER TABLE ONLY "public"."businesses"
    ADD CONSTRAINT "businesses_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."categories"
    ADD CONSTRAINT "categories_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."categories"
    ADD CONSTRAINT "categories_slug_key" UNIQUE ("slug");



ALTER TABLE ONLY "public"."category_translations"
    ADD CONSTRAINT "category_translations_pkey" PRIMARY KEY ("category_id", "language_id");



ALTER TABLE ONLY "public"."communities"
    ADD CONSTRAINT "communities_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."communities"
    ADD CONSTRAINT "communities_slug_key" UNIQUE ("slug");



ALTER TABLE ONLY "public"."community_members"
    ADD CONSTRAINT "community_members_pkey" PRIMARY KEY ("community_id", "profile_id");



ALTER TABLE ONLY "public"."community_messages"
    ADD CONSTRAINT "community_messages_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."conversations"
    ADD CONSTRAINT "conversations_buyer_id_business_id_key" UNIQUE ("buyer_id", "business_id");



ALTER TABLE ONLY "public"."conversations"
    ADD CONSTRAINT "conversations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."direct_messages"
    ADD CONSTRAINT "direct_messages_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."geofences"
    ADD CONSTRAINT "geofences_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."hotspot_events"
    ADD CONSTRAINT "hotspot_events_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."languages"
    ADD CONSTRAINT "languages_code_key" UNIQUE ("code");



ALTER TABLE ONLY "public"."languages"
    ADD CONSTRAINT "languages_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."message_reactions"
    ADD CONSTRAINT "message_reactions_pkey" PRIMARY KEY ("message_id", "profile_id", "emoji");



ALTER TABLE ONLY "public"."mp_accounts"
    ADD CONSTRAINT "mp_accounts_business_unique" UNIQUE ("business_id");



ALTER TABLE ONLY "public"."mp_accounts"
    ADD CONSTRAINT "mp_accounts_mp_user_unique" UNIQUE ("mp_user_id");



ALTER TABLE ONLY "public"."mp_accounts"
    ADD CONSTRAINT "mp_accounts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."mp_oauth_states"
    ADD CONSTRAINT "mp_oauth_states_pkey" PRIMARY KEY ("state");



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."offering_translations"
    ADD CONSTRAINT "offering_translations_pkey" PRIMARY KEY ("offering_id", "language_id");



ALTER TABLE ONLY "public"."offerings"
    ADD CONSTRAINT "offerings_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."profile_category_interests"
    ADD CONSTRAINT "profile_category_interests_pkey" PRIMARY KEY ("profile_id", "category_id");



ALTER TABLE ONLY "public"."profile_languages"
    ADD CONSTRAINT "profile_languages_pkey" PRIMARY KEY ("profile_id", "language_id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."reviews"
    ADD CONSTRAINT "reviews_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."route_stops"
    ADD CONSTRAINT "route_stops_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."routes"
    ADD CONSTRAINT "routes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."survey_question_translations"
    ADD CONSTRAINT "survey_question_translations_pkey" PRIMARY KEY ("question_id", "language_id");



ALTER TABLE ONLY "public"."survey_questions"
    ADD CONSTRAINT "survey_questions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."survey_responses"
    ADD CONSTRAINT "survey_responses_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."survey_translations"
    ADD CONSTRAINT "survey_translations_pkey" PRIMARY KEY ("survey_id", "language_id");



ALTER TABLE ONLY "public"."surveys"
    ADD CONSTRAINT "surveys_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."training_progress"
    ADD CONSTRAINT "training_progress_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."transactions"
    ADD CONSTRAINT "transactions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."reviews"
    ADD CONSTRAINT "unique_review_per_tourist_business" UNIQUE ("tourist_id", "business_id");



ALTER TABLE ONLY "public"."route_stops"
    ADD CONSTRAINT "unique_stop_order_per_route" UNIQUE ("route_id", "stop_order");



ALTER TABLE ONLY "public"."training_progress"
    ADD CONSTRAINT "unique_user_module" UNIQUE ("user_id", "module_id");



ALTER TABLE ONLY "public"."visits"
    ADD CONSTRAINT "visits_pkey" PRIMARY KEY ("id");



CREATE INDEX "idx_analytics_event_data" ON "public"."analytics_events" USING "gin" ("event_data");



CREATE INDEX "idx_analytics_event_type_date" ON "public"."analytics_events" USING "btree" ("event_type", "created_at" DESC);



CREATE INDEX "idx_analytics_user_date" ON "public"."analytics_events" USING "btree" ("user_id", "created_at" DESC) WHERE ("user_id" IS NOT NULL);



CREATE INDEX "idx_business_images_business" ON "public"."business_images" USING "btree" ("business_id", "sort_order");



CREATE INDEX "idx_business_translations_lookup" ON "public"."business_translations" USING "btree" ("business_id", "language_id");



CREATE INDEX "idx_businesses_active_verified" ON "public"."businesses" USING "btree" ("is_active", "is_verified");



CREATE INDEX "idx_businesses_category" ON "public"."businesses" USING "btree" ("category_id") WHERE ("is_active" = true);



CREATE INDEX "idx_businesses_location" ON "public"."businesses" USING "gist" ("location");



CREATE INDEX "idx_businesses_location_gist" ON "public"."businesses" USING "gist" ("location");



CREATE INDEX "idx_businesses_name_trgm" ON "public"."businesses" USING "gin" ("name" "extensions"."gin_trgm_ops");



CREATE INDEX "idx_businesses_owner" ON "public"."businesses" USING "btree" ("owner_id");



CREATE INDEX "idx_categories_active_sort" ON "public"."categories" USING "btree" ("is_active", "sort_order");



CREATE INDEX "idx_communities_active" ON "public"."communities" USING "btree" ("is_active", "created_at" DESC);



CREATE INDEX "idx_communities_creator" ON "public"."communities" USING "btree" ("creator_id");



CREATE INDEX "idx_communities_name_trgm" ON "public"."communities" USING "gin" ("name" "extensions"."gin_trgm_ops");



CREATE INDEX "idx_community_members_profile" ON "public"."community_members" USING "btree" ("profile_id");



CREATE INDEX "idx_community_members_role" ON "public"."community_members" USING "btree" ("community_id", "role") WHERE ("role" = ANY (ARRAY['moderator'::"public"."community_role", 'admin'::"public"."community_role"]));



CREATE INDEX "idx_community_messages_community_date" ON "public"."community_messages" USING "btree" ("community_id", "created_at" DESC) WHERE ("is_deleted" = false);



CREATE INDEX "idx_community_messages_reply" ON "public"."community_messages" USING "btree" ("reply_to_id") WHERE ("reply_to_id" IS NOT NULL);



CREATE INDEX "idx_community_messages_sender" ON "public"."community_messages" USING "btree" ("sender_id");



CREATE INDEX "idx_conv_buyer" ON "public"."conversations" USING "btree" ("buyer_id", "last_message_at" DESC);



CREATE INDEX "idx_conv_owner" ON "public"."conversations" USING "btree" ("owner_id", "last_message_at" DESC);



CREATE INDEX "idx_dm_conv_time" ON "public"."direct_messages" USING "btree" ("conversation_id", "created_at" DESC) WHERE ("is_deleted" = false);



CREATE INDEX "idx_geofences_location" ON "public"."geofences" USING "gist" ("location") WHERE ("is_active" = true);



CREATE INDEX "idx_hotspot_events_geofence_date" ON "public"."hotspot_events" USING "btree" ("geofence_id", "detected_at" DESC);



CREATE INDEX "idx_hotspot_events_recent" ON "public"."hotspot_events" USING "btree" ("detected_at" DESC);



CREATE INDEX "idx_members_profile" ON "public"."community_members" USING "btree" ("profile_id");



CREATE INDEX "idx_message_reactions_message" ON "public"."message_reactions" USING "btree" ("message_id");



CREATE INDEX "idx_messages_community_created" ON "public"."community_messages" USING "btree" ("community_id", "created_at" DESC) WHERE ("is_deleted" = false);



CREATE INDEX "idx_notifications_user_date" ON "public"."notifications" USING "btree" ("user_id", "created_at" DESC);



CREATE INDEX "idx_notifications_user_unread" ON "public"."notifications" USING "btree" ("user_id", "created_at" DESC) WHERE ("is_read" = false);



CREATE INDEX "idx_offerings_business" ON "public"."offerings" USING "btree" ("business_id", "sort_order") WHERE ("is_active" = true);



CREATE INDEX "idx_offerings_type" ON "public"."offerings" USING "btree" ("type");



CREATE UNIQUE INDEX "idx_one_preferred_language_per_profile" ON "public"."profile_languages" USING "btree" ("profile_id") WHERE ("is_preferred" = true);



CREATE INDEX "idx_profile_category_interests_profile" ON "public"."profile_category_interests" USING "btree" ("profile_id");



CREATE INDEX "idx_profile_languages_language" ON "public"."profile_languages" USING "btree" ("language_id");



CREATE INDEX "idx_profile_languages_preferred" ON "public"."profile_languages" USING "btree" ("profile_id") WHERE ("is_preferred" = true);



CREATE INDEX "idx_profiles_role" ON "public"."profiles" USING "btree" ("role");



CREATE INDEX "idx_reactions_message" ON "public"."message_reactions" USING "btree" ("message_id");



CREATE INDEX "idx_reviews_business_date" ON "public"."reviews" USING "btree" ("business_id", "created_at" DESC);



CREATE INDEX "idx_reviews_business_id" ON "public"."reviews" USING "btree" ("business_id");



CREATE INDEX "idx_reviews_rating" ON "public"."reviews" USING "btree" ("business_id", "rating");



CREATE INDEX "idx_route_stops_business" ON "public"."route_stops" USING "btree" ("business_id");



CREATE INDEX "idx_route_stops_route" ON "public"."route_stops" USING "btree" ("route_id", "stop_order");



CREATE INDEX "idx_routes_tourist_date" ON "public"."routes" USING "btree" ("tourist_id", "created_at" DESC);



CREATE INDEX "idx_routes_type" ON "public"."routes" USING "btree" ("type");



CREATE INDEX "idx_survey_questions_survey" ON "public"."survey_questions" USING "btree" ("survey_id", "sort_order");



CREATE INDEX "idx_survey_responses_answers" ON "public"."survey_responses" USING "gin" ("answers");



CREATE INDEX "idx_survey_responses_business" ON "public"."survey_responses" USING "btree" ("business_id", "created_at" DESC) WHERE ("business_id" IS NOT NULL);



CREATE INDEX "idx_survey_responses_survey_date" ON "public"."survey_responses" USING "btree" ("survey_id", "created_at" DESC);



CREATE INDEX "idx_survey_responses_user" ON "public"."survey_responses" USING "btree" ("user_id", "created_at" DESC);



CREATE INDEX "idx_surveys_type_active" ON "public"."surveys" USING "btree" ("type") WHERE ("is_active" = true);



CREATE INDEX "idx_training_completed" ON "public"."training_progress" USING "btree" ("completed_at" DESC) WHERE ("completed_at" IS NOT NULL);



CREATE INDEX "idx_training_user" ON "public"."training_progress" USING "btree" ("user_id");



CREATE INDEX "idx_transactions_business_date" ON "public"."transactions" USING "btree" ("business_id", "created_at" DESC);



CREATE INDEX "idx_transactions_provider" ON "public"."transactions" USING "btree" ("payment_provider_id") WHERE ("payment_provider_id" IS NOT NULL);



CREATE INDEX "idx_transactions_status" ON "public"."transactions" USING "btree" ("status") WHERE ("status" = ANY (ARRAY['pending'::"public"."payment_status", 'failed'::"public"."payment_status"]));



CREATE INDEX "idx_transactions_tourist_date" ON "public"."transactions" USING "btree" ("tourist_id", "created_at" DESC);



CREATE INDEX "idx_visits_business_date" ON "public"."visits" USING "btree" ("business_id", "visited_at" DESC);



CREATE INDEX "idx_visits_business_id" ON "public"."visits" USING "btree" ("business_id");



CREATE INDEX "idx_visits_business_recent" ON "public"."visits" USING "btree" ("business_id", "visited_at" DESC);



CREATE INDEX "idx_visits_source" ON "public"."visits" USING "btree" ("source");



CREATE INDEX "idx_visits_tourist_date" ON "public"."visits" USING "btree" ("tourist_id", "visited_at" DESC);



CREATE INDEX "idx_visits_visited_at" ON "public"."visits" USING "btree" ("visited_at" DESC);



CREATE INDEX "mp_accounts_mp_user_id_idx" ON "public"."mp_accounts" USING "btree" ("mp_user_id");



CREATE INDEX "mp_oauth_states_expires_at_idx" ON "public"."mp_oauth_states" USING "btree" ("expires_at");



CREATE INDEX "transactions_mp_preference_id_idx" ON "public"."transactions" USING "btree" ("mp_preference_id") WHERE ("mp_preference_id" IS NOT NULL);



CREATE OR REPLACE TRIGGER "business_translations_set_updated_at" BEFORE UPDATE ON "public"."business_translations" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "businesses_set_updated_at" BEFORE UPDATE ON "public"."businesses" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "businesses_translate_description" AFTER INSERT OR UPDATE OF "description" ON "public"."businesses" FOR EACH ROW EXECUTE FUNCTION "public"."trg_businesses_translate_description"();



CREATE OR REPLACE TRIGGER "communities_set_updated_at" BEFORE UPDATE ON "public"."communities" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "community_members_count_trigger" AFTER INSERT OR DELETE ON "public"."community_members" FOR EACH ROW EXECUTE FUNCTION "public"."update_community_member_count"();



CREATE OR REPLACE TRIGGER "mp_accounts_set_updated_at" BEFORE UPDATE ON "public"."mp_accounts" FOR EACH ROW EXECUTE FUNCTION "public"."tg_mp_accounts_set_updated_at"();



CREATE OR REPLACE TRIGGER "offerings_set_updated_at" BEFORE UPDATE ON "public"."offerings" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "offerings_translate" AFTER INSERT OR UPDATE OF "source_name", "source_description" ON "public"."offerings" FOR EACH ROW EXECUTE FUNCTION "public"."trg_offerings_translate"();



CREATE OR REPLACE TRIGGER "profiles_set_updated_at" BEFORE UPDATE ON "public"."profiles" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "reviews_update_business_rating" AFTER INSERT OR DELETE OR UPDATE ON "public"."reviews" FOR EACH ROW EXECUTE FUNCTION "public"."trg_update_business_rating"();



CREATE OR REPLACE TRIGGER "trg_dm_insert" AFTER INSERT ON "public"."direct_messages" FOR EACH ROW EXECUTE FUNCTION "public"."on_direct_message_insert"();



CREATE OR REPLACE TRIGGER "trg_member_count" AFTER INSERT OR DELETE ON "public"."community_members" FOR EACH ROW EXECUTE FUNCTION "public"."bump_community_member_count"();



CREATE OR REPLACE TRIGGER "trg_validate_message" BEFORE INSERT OR UPDATE ON "public"."community_messages" FOR EACH ROW EXECUTE FUNCTION "public"."validate_message_content"();



CREATE OR REPLACE TRIGGER "visits_update_business_stats" AFTER INSERT ON "public"."visits" FOR EACH ROW EXECUTE FUNCTION "public"."trg_update_business_visits"();



ALTER TABLE ONLY "public"."analytics_events"
    ADD CONSTRAINT "analytics_events_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."business_images"
    ADD CONSTRAINT "business_images_business_id_fkey" FOREIGN KEY ("business_id") REFERENCES "public"."businesses"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."business_translations"
    ADD CONSTRAINT "business_translations_business_id_fkey" FOREIGN KEY ("business_id") REFERENCES "public"."businesses"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."business_translations"
    ADD CONSTRAINT "business_translations_language_id_fkey" FOREIGN KEY ("language_id") REFERENCES "public"."languages"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."businesses"
    ADD CONSTRAINT "businesses_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "public"."categories"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."businesses"
    ADD CONSTRAINT "businesses_owner_id_fkey" FOREIGN KEY ("owner_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."category_translations"
    ADD CONSTRAINT "category_translations_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "public"."categories"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."category_translations"
    ADD CONSTRAINT "category_translations_language_id_fkey" FOREIGN KEY ("language_id") REFERENCES "public"."languages"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."communities"
    ADD CONSTRAINT "communities_creator_id_fkey" FOREIGN KEY ("creator_id") REFERENCES "public"."profiles"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."community_members"
    ADD CONSTRAINT "community_members_community_id_fkey" FOREIGN KEY ("community_id") REFERENCES "public"."communities"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."community_members"
    ADD CONSTRAINT "community_members_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."community_messages"
    ADD CONSTRAINT "community_messages_community_id_fkey" FOREIGN KEY ("community_id") REFERENCES "public"."communities"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."community_messages"
    ADD CONSTRAINT "community_messages_reply_to_id_fkey" FOREIGN KEY ("reply_to_id") REFERENCES "public"."community_messages"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."community_messages"
    ADD CONSTRAINT "community_messages_sender_id_fkey" FOREIGN KEY ("sender_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."community_messages"
    ADD CONSTRAINT "community_messages_shared_business_id_fkey" FOREIGN KEY ("shared_business_id") REFERENCES "public"."businesses"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."community_messages"
    ADD CONSTRAINT "community_messages_shared_route_id_fkey" FOREIGN KEY ("shared_route_id") REFERENCES "public"."routes"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."conversations"
    ADD CONSTRAINT "conversations_business_id_fkey" FOREIGN KEY ("business_id") REFERENCES "public"."businesses"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."conversations"
    ADD CONSTRAINT "conversations_buyer_id_fkey" FOREIGN KEY ("buyer_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."conversations"
    ADD CONSTRAINT "conversations_owner_id_fkey" FOREIGN KEY ("owner_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."direct_messages"
    ADD CONSTRAINT "direct_messages_conversation_id_fkey" FOREIGN KEY ("conversation_id") REFERENCES "public"."conversations"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."direct_messages"
    ADD CONSTRAINT "direct_messages_sender_id_fkey" FOREIGN KEY ("sender_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."direct_messages"
    ADD CONSTRAINT "direct_messages_shared_offering_id_fkey" FOREIGN KEY ("shared_offering_id") REFERENCES "public"."offerings"("id");



ALTER TABLE ONLY "public"."hotspot_events"
    ADD CONSTRAINT "hotspot_events_geofence_id_fkey" FOREIGN KEY ("geofence_id") REFERENCES "public"."geofences"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."message_reactions"
    ADD CONSTRAINT "message_reactions_message_id_fkey" FOREIGN KEY ("message_id") REFERENCES "public"."community_messages"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."message_reactions"
    ADD CONSTRAINT "message_reactions_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."mp_accounts"
    ADD CONSTRAINT "mp_accounts_business_id_fkey" FOREIGN KEY ("business_id") REFERENCES "public"."businesses"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."mp_oauth_states"
    ADD CONSTRAINT "mp_oauth_states_business_id_fkey" FOREIGN KEY ("business_id") REFERENCES "public"."businesses"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."offering_translations"
    ADD CONSTRAINT "offering_translations_language_id_fkey" FOREIGN KEY ("language_id") REFERENCES "public"."languages"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."offering_translations"
    ADD CONSTRAINT "offering_translations_offering_id_fkey" FOREIGN KEY ("offering_id") REFERENCES "public"."offerings"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."offerings"
    ADD CONSTRAINT "offerings_business_id_fkey" FOREIGN KEY ("business_id") REFERENCES "public"."businesses"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."profile_category_interests"
    ADD CONSTRAINT "profile_category_interests_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "public"."categories"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."profile_category_interests"
    ADD CONSTRAINT "profile_category_interests_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."profile_languages"
    ADD CONSTRAINT "profile_languages_language_id_fkey" FOREIGN KEY ("language_id") REFERENCES "public"."languages"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."profile_languages"
    ADD CONSTRAINT "profile_languages_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."reviews"
    ADD CONSTRAINT "reviews_business_id_fkey" FOREIGN KEY ("business_id") REFERENCES "public"."businesses"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."reviews"
    ADD CONSTRAINT "reviews_tourist_id_fkey" FOREIGN KEY ("tourist_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."route_stops"
    ADD CONSTRAINT "route_stops_business_id_fkey" FOREIGN KEY ("business_id") REFERENCES "public"."businesses"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."route_stops"
    ADD CONSTRAINT "route_stops_route_id_fkey" FOREIGN KEY ("route_id") REFERENCES "public"."routes"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."routes"
    ADD CONSTRAINT "routes_tourist_id_fkey" FOREIGN KEY ("tourist_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."survey_question_translations"
    ADD CONSTRAINT "survey_question_translations_language_id_fkey" FOREIGN KEY ("language_id") REFERENCES "public"."languages"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."survey_question_translations"
    ADD CONSTRAINT "survey_question_translations_question_id_fkey" FOREIGN KEY ("question_id") REFERENCES "public"."survey_questions"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."survey_questions"
    ADD CONSTRAINT "survey_questions_survey_id_fkey" FOREIGN KEY ("survey_id") REFERENCES "public"."surveys"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."survey_responses"
    ADD CONSTRAINT "survey_responses_business_id_fkey" FOREIGN KEY ("business_id") REFERENCES "public"."businesses"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."survey_responses"
    ADD CONSTRAINT "survey_responses_survey_id_fkey" FOREIGN KEY ("survey_id") REFERENCES "public"."surveys"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."survey_responses"
    ADD CONSTRAINT "survey_responses_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."survey_translations"
    ADD CONSTRAINT "survey_translations_language_id_fkey" FOREIGN KEY ("language_id") REFERENCES "public"."languages"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."survey_translations"
    ADD CONSTRAINT "survey_translations_survey_id_fkey" FOREIGN KEY ("survey_id") REFERENCES "public"."surveys"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."training_progress"
    ADD CONSTRAINT "training_progress_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."transactions"
    ADD CONSTRAINT "transactions_business_id_fkey" FOREIGN KEY ("business_id") REFERENCES "public"."businesses"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."transactions"
    ADD CONSTRAINT "transactions_tourist_id_fkey" FOREIGN KEY ("tourist_id") REFERENCES "public"."profiles"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."visits"
    ADD CONSTRAINT "visits_business_id_fkey" FOREIGN KEY ("business_id") REFERENCES "public"."businesses"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."visits"
    ADD CONSTRAINT "visits_tourist_id_fkey" FOREIGN KEY ("tourist_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE "public"."algorithm_config" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."analytics_events" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "analytics_events_admin_read" ON "public"."analytics_events" FOR SELECT USING ("public"."is_admin"());



CREATE POLICY "analytics_events_user_insert" ON "public"."analytics_events" FOR INSERT WITH CHECK ((("auth"."uid"() = "user_id") OR ("user_id" IS NULL)));



CREATE POLICY "author_or_mod_delete" ON "public"."community_messages" FOR UPDATE USING ((("sender_id" = "auth"."uid"()) OR (EXISTS ( SELECT 1
   FROM "public"."community_members"
  WHERE (("community_members"."community_id" = "community_messages"."community_id") AND ("community_members"."profile_id" = "auth"."uid"()) AND ("community_members"."role" = ANY (ARRAY['moderator'::"public"."community_role", 'admin'::"public"."community_role"])))))));



CREATE POLICY "authors can update own messages" ON "public"."community_messages" FOR UPDATE TO "authenticated" USING (("sender_id" = "auth"."uid"())) WITH CHECK (("sender_id" = "auth"."uid"()));



ALTER TABLE "public"."business_images" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "business_images_admin_all" ON "public"."business_images" USING ("public"."is_admin"());



CREATE POLICY "business_images_owner_all" ON "public"."business_images" USING ((EXISTS ( SELECT 1
   FROM "public"."businesses" "b"
  WHERE (("b"."id" = "business_images"."business_id") AND ("b"."owner_id" = "auth"."uid"())))));



CREATE POLICY "business_images_public_read" ON "public"."business_images" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."businesses" "b"
  WHERE (("b"."id" = "business_images"."business_id") AND ("b"."is_active" = true) AND ("b"."is_verified" = true)))));



ALTER TABLE "public"."business_translations" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "business_translations_admin_all" ON "public"."business_translations" USING ("public"."is_admin"());



CREATE POLICY "business_translations_owner_all" ON "public"."business_translations" USING ((EXISTS ( SELECT 1
   FROM "public"."businesses" "b"
  WHERE (("b"."id" = "business_translations"."business_id") AND ("b"."owner_id" = "auth"."uid"())))));



CREATE POLICY "business_translations_public_read" ON "public"."business_translations" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."businesses" "b"
  WHERE (("b"."id" = "business_translations"."business_id") AND ("b"."is_active" = true) AND ("b"."is_verified" = true)))));



ALTER TABLE "public"."businesses" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "businesses_admin_all" ON "public"."businesses" USING ("public"."is_admin"());



CREATE POLICY "businesses_owner_insert" ON "public"."businesses" FOR INSERT WITH CHECK (("auth"."uid"() = "owner_id"));



CREATE POLICY "businesses_owner_read_own" ON "public"."businesses" FOR SELECT USING (("auth"."uid"() = "owner_id"));



CREATE POLICY "businesses_owner_update" ON "public"."businesses" FOR UPDATE USING (("auth"."uid"() = "owner_id"));



CREATE POLICY "businesses_public_read" ON "public"."businesses" FOR SELECT USING (("is_active" = true));



ALTER TABLE "public"."categories" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "categories_admin_all" ON "public"."categories" USING ("public"."is_admin"());



CREATE POLICY "categories_public_read" ON "public"."categories" FOR SELECT USING (("is_active" = true));



ALTER TABLE "public"."category_translations" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "category_translations_admin_all" ON "public"."category_translations" USING ("public"."is_admin"());



CREATE POLICY "category_translations_public_read" ON "public"."category_translations" FOR SELECT USING (true);



ALTER TABLE "public"."communities" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "communities_admin_all" ON "public"."communities" USING ("public"."is_admin"());



CREATE POLICY "communities_auth_create" ON "public"."communities" FOR INSERT WITH CHECK (("auth"."uid"() = "creator_id"));



CREATE POLICY "communities_creator_update" ON "public"."communities" FOR UPDATE USING (("auth"."uid"() = "creator_id"));



CREATE POLICY "communities_insert_self" ON "public"."communities" FOR INSERT WITH CHECK (("creator_id" = "auth"."uid"()));



CREATE POLICY "communities_public_read" ON "public"."communities" FOR SELECT USING (("is_active" = true));



CREATE POLICY "communities_read_active" ON "public"."communities" FOR SELECT USING (("is_active" = true));



CREATE POLICY "communities_update_creator_or_admin" ON "public"."communities" FOR UPDATE USING ((("creator_id" = "auth"."uid"()) OR (EXISTS ( SELECT 1
   FROM "public"."community_members"
  WHERE (("community_members"."community_id" = "communities"."id") AND ("community_members"."profile_id" = "auth"."uid"()) AND ("community_members"."role" = 'admin'::"public"."community_role"))))));



ALTER TABLE "public"."community_members" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "community_members_admin_all" ON "public"."community_members" USING ("public"."is_admin"());



CREATE POLICY "community_members_public_read" ON "public"."community_members" FOR SELECT USING (true);



CREATE POLICY "community_members_self_join" ON "public"."community_members" FOR INSERT WITH CHECK (("auth"."uid"() = "profile_id"));



CREATE POLICY "community_members_self_leave" ON "public"."community_members" FOR DELETE USING (("auth"."uid"() = "profile_id"));



ALTER TABLE "public"."community_messages" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "community_messages_admin_all" ON "public"."community_messages" USING ("public"."is_admin"());



CREATE POLICY "community_messages_member_read" ON "public"."community_messages" FOR SELECT USING ((("is_deleted" = false) AND (EXISTS ( SELECT 1
   FROM "public"."community_members" "cm"
  WHERE (("cm"."community_id" = "community_messages"."community_id") AND ("cm"."profile_id" = "auth"."uid"()))))));



CREATE POLICY "community_messages_member_send" ON "public"."community_messages" FOR INSERT WITH CHECK ((("auth"."uid"() = "sender_id") AND (EXISTS ( SELECT 1
   FROM "public"."community_members" "cm"
  WHERE (("cm"."community_id" = "community_messages"."community_id") AND ("cm"."profile_id" = "auth"."uid"()))))));



CREATE POLICY "community_messages_sender_delete" ON "public"."community_messages" FOR UPDATE USING (("auth"."uid"() = "sender_id"));



CREATE POLICY "conv_insert_buyer" ON "public"."conversations" FOR INSERT WITH CHECK ((("buyer_id" = "auth"."uid"()) AND ("owner_id" = ( SELECT "businesses"."owner_id"
   FROM "public"."businesses"
  WHERE ("businesses"."id" = "conversations"."business_id")))));



CREATE POLICY "conv_read_parties" ON "public"."conversations" FOR SELECT USING ((("auth"."uid"() = "buyer_id") OR ("auth"."uid"() = "owner_id")));



CREATE POLICY "conv_update_parties" ON "public"."conversations" FOR UPDATE USING ((("auth"."uid"() = "buyer_id") OR ("auth"."uid"() = "owner_id")));



ALTER TABLE "public"."conversations" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."direct_messages" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "dm_insert_parties" ON "public"."direct_messages" FOR INSERT WITH CHECK ((("sender_id" = "auth"."uid"()) AND (EXISTS ( SELECT 1
   FROM "public"."conversations" "c"
  WHERE (("c"."id" = "direct_messages"."conversation_id") AND (("auth"."uid"() = "c"."buyer_id") OR ("auth"."uid"() = "c"."owner_id")))))));



CREATE POLICY "dm_read_parties" ON "public"."direct_messages" FOR SELECT USING ((("is_deleted" = false) AND (EXISTS ( SELECT 1
   FROM "public"."conversations" "c"
  WHERE (("c"."id" = "direct_messages"."conversation_id") AND (("auth"."uid"() = "c"."buyer_id") OR ("auth"."uid"() = "c"."owner_id")))))));



CREATE POLICY "dm_update_parties" ON "public"."direct_messages" FOR UPDATE USING ((EXISTS ( SELECT 1
   FROM "public"."conversations" "c"
  WHERE (("c"."id" = "direct_messages"."conversation_id") AND (("auth"."uid"() = "c"."buyer_id") OR ("auth"."uid"() = "c"."owner_id"))))));



ALTER TABLE "public"."geofences" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "geofences_admin_all" ON "public"."geofences" USING ("public"."is_admin"());



CREATE POLICY "geofences_public_read" ON "public"."geofences" FOR SELECT USING (("is_active" = true));



ALTER TABLE "public"."hotspot_events" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "hotspot_events_admin_all" ON "public"."hotspot_events" USING ("public"."is_admin"());



CREATE POLICY "hotspot_events_public_read" ON "public"."hotspot_events" FOR SELECT USING (true);



ALTER TABLE "public"."languages" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "languages_admin_all" ON "public"."languages" USING ("public"."is_admin"());



CREATE POLICY "languages_public_read" ON "public"."languages" FOR SELECT USING (("is_active" = true));



CREATE POLICY "members can react" ON "public"."message_reactions" FOR INSERT TO "authenticated" WITH CHECK ((("profile_id" = "auth"."uid"()) AND (EXISTS ( SELECT 1
   FROM "public"."community_messages" "m"
  WHERE (("m"."id" = "message_reactions"."message_id") AND "public"."is_community_member"("m"."community_id"))))));



CREATE POLICY "members can read messages" ON "public"."community_messages" FOR SELECT TO "authenticated" USING (("public"."is_community_member"("community_id") AND ("is_deleted" = false)));



CREATE POLICY "members can read reactions" ON "public"."message_reactions" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."community_messages" "m"
  WHERE (("m"."id" = "message_reactions"."message_id") AND "public"."is_community_member"("m"."community_id")))));



CREATE POLICY "members can send messages" ON "public"."community_messages" FOR INSERT TO "authenticated" WITH CHECK ((("sender_id" = "auth"."uid"()) AND "public"."is_community_member"("community_id")));



CREATE POLICY "members_mod_kick" ON "public"."community_members" FOR DELETE USING ((EXISTS ( SELECT 1
   FROM "public"."community_members" "cm"
  WHERE (("cm"."community_id" = "community_members"."community_id") AND ("cm"."profile_id" = "auth"."uid"()) AND ("cm"."role" = ANY (ARRAY['moderator'::"public"."community_role", 'admin'::"public"."community_role"]))))));



CREATE POLICY "members_read_all" ON "public"."community_members" FOR SELECT USING (true);



CREATE POLICY "members_read_messages" ON "public"."community_messages" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."community_members"
  WHERE (("community_members"."community_id" = "community_messages"."community_id") AND ("community_members"."profile_id" = "auth"."uid"())))));



CREATE POLICY "members_self_join" ON "public"."community_members" FOR INSERT WITH CHECK ((("profile_id" = "auth"."uid"()) AND ("role" = 'member'::"public"."community_role")));



CREATE POLICY "members_self_leave" ON "public"."community_members" FOR DELETE USING (("profile_id" = "auth"."uid"()));



CREATE POLICY "members_send_messages" ON "public"."community_messages" FOR INSERT WITH CHECK ((("sender_id" = "auth"."uid"()) AND (EXISTS ( SELECT 1
   FROM "public"."community_members"
  WHERE (("community_members"."community_id" = "community_messages"."community_id") AND ("community_members"."profile_id" = "auth"."uid"()))))));



ALTER TABLE "public"."message_reactions" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "message_reactions_admin_all" ON "public"."message_reactions" USING ("public"."is_admin"());



CREATE POLICY "message_reactions_member_read" ON "public"."message_reactions" FOR SELECT USING (true);



CREATE POLICY "message_reactions_self_add" ON "public"."message_reactions" FOR INSERT WITH CHECK (("auth"."uid"() = "profile_id"));



CREATE POLICY "message_reactions_self_remove" ON "public"."message_reactions" FOR DELETE USING (("auth"."uid"() = "profile_id"));



CREATE POLICY "messages_insert_members" ON "public"."community_messages" FOR INSERT WITH CHECK ((("sender_id" = "auth"."uid"()) AND (EXISTS ( SELECT 1
   FROM "public"."community_members"
  WHERE (("community_members"."community_id" = "community_messages"."community_id") AND ("community_members"."profile_id" = "auth"."uid"()))))));



CREATE POLICY "messages_read_members" ON "public"."community_messages" FOR SELECT USING ((("is_deleted" = false) AND (EXISTS ( SELECT 1
   FROM "public"."community_members"
  WHERE (("community_members"."community_id" = "community_messages"."community_id") AND ("community_members"."profile_id" = "auth"."uid"()))))));



CREATE POLICY "messages_update_author_or_mod" ON "public"."community_messages" FOR UPDATE USING ((("sender_id" = "auth"."uid"()) OR (EXISTS ( SELECT 1
   FROM "public"."community_members"
  WHERE (("community_members"."community_id" = "community_messages"."community_id") AND ("community_members"."profile_id" = "auth"."uid"()) AND ("community_members"."role" = ANY (ARRAY['moderator'::"public"."community_role", 'admin'::"public"."community_role"])))))));



ALTER TABLE "public"."mp_accounts" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."mp_oauth_states" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "no client access" ON "public"."mp_oauth_states" TO "authenticated", "anon" USING (false) WITH CHECK (false);



CREATE POLICY "no client writes" ON "public"."mp_accounts" TO "authenticated" USING (false) WITH CHECK (false);



ALTER TABLE "public"."notifications" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "notifications_admin_all" ON "public"."notifications" USING ("public"."is_admin"());



CREATE POLICY "notifications_user_read_own" ON "public"."notifications" FOR SELECT USING (("auth"."uid"() = "user_id"));



CREATE POLICY "notifications_user_update_own" ON "public"."notifications" FOR UPDATE USING (("auth"."uid"() = "user_id"));



ALTER TABLE "public"."offering_translations" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "offering_translations_admin_all" ON "public"."offering_translations" USING ("public"."is_admin"());



CREATE POLICY "offering_translations_owner_all" ON "public"."offering_translations" USING ((EXISTS ( SELECT 1
   FROM ("public"."offerings" "o"
     JOIN "public"."businesses" "b" ON (("b"."id" = "o"."business_id")))
  WHERE (("o"."id" = "offering_translations"."offering_id") AND ("b"."owner_id" = "auth"."uid"())))));



CREATE POLICY "offering_translations_public_read" ON "public"."offering_translations" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM ("public"."offerings" "o"
     JOIN "public"."businesses" "b" ON (("b"."id" = "o"."business_id")))
  WHERE (("o"."id" = "offering_translations"."offering_id") AND ("o"."is_active" = true) AND ("b"."is_active" = true) AND ("b"."is_verified" = true)))));



ALTER TABLE "public"."offerings" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "offerings_admin_all" ON "public"."offerings" USING ("public"."is_admin"());



CREATE POLICY "offerings_owner_all" ON "public"."offerings" USING ((EXISTS ( SELECT 1
   FROM "public"."businesses" "b"
  WHERE (("b"."id" = "offerings"."business_id") AND ("b"."owner_id" = "auth"."uid"())))));



CREATE POLICY "offerings_public_read" ON "public"."offerings" FOR SELECT USING ((("is_active" = true) AND (EXISTS ( SELECT 1
   FROM "public"."businesses" "b"
  WHERE (("b"."id" = "offerings"."business_id") AND ("b"."is_active" = true) AND ("b"."is_verified" = true))))));



CREATE POLICY "owner can read own mp account" ON "public"."mp_accounts" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."businesses" "b"
  WHERE (("b"."id" = "mp_accounts"."business_id") AND ("b"."owner_id" = "auth"."uid"())))));



ALTER TABLE "public"."profile_category_interests" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."profile_languages" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "profile_languages_own" ON "public"."profile_languages" USING ((("auth"."uid"() = "profile_id") OR "public"."is_admin"()));



ALTER TABLE "public"."profiles" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "profiles_insert_own" ON "public"."profiles" FOR INSERT WITH CHECK (("auth"."uid"() = "id"));



CREATE POLICY "profiles_read_own" ON "public"."profiles" FOR SELECT USING ((("auth"."uid"() = "id") OR "public"."is_admin"()));



CREATE POLICY "profiles_update_own" ON "public"."profiles" FOR UPDATE USING ((("auth"."uid"() = "id") OR "public"."is_admin"()));



CREATE POLICY "reactions_delete_self" ON "public"."message_reactions" FOR DELETE USING (("profile_id" = "auth"."uid"()));



CREATE POLICY "reactions_insert_members" ON "public"."message_reactions" FOR INSERT WITH CHECK ((("profile_id" = "auth"."uid"()) AND (EXISTS ( SELECT 1
   FROM ("public"."community_messages" "m"
     JOIN "public"."community_members" "cm" ON (("cm"."community_id" = "m"."community_id")))
  WHERE (("m"."id" = "message_reactions"."message_id") AND ("cm"."profile_id" = "auth"."uid"()))))));



CREATE POLICY "reactions_read_members" ON "public"."message_reactions" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM ("public"."community_messages" "m"
     JOIN "public"."community_members" "cm" ON (("cm"."community_id" = "m"."community_id")))
  WHERE (("m"."id" = "message_reactions"."message_id") AND ("cm"."profile_id" = "auth"."uid"())))));



ALTER TABLE "public"."reviews" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "reviews_admin_all" ON "public"."reviews" USING ("public"."is_admin"());



CREATE POLICY "reviews_public_read" ON "public"."reviews" FOR SELECT USING (true);



CREATE POLICY "reviews_tourist_delete_own" ON "public"."reviews" FOR DELETE USING (("auth"."uid"() = "tourist_id"));



CREATE POLICY "reviews_tourist_insert" ON "public"."reviews" FOR INSERT WITH CHECK (("auth"."uid"() = "tourist_id"));



CREATE POLICY "reviews_tourist_update_own" ON "public"."reviews" FOR UPDATE USING (("auth"."uid"() = "tourist_id"));



ALTER TABLE "public"."route_stops" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "route_stops_admin_all" ON "public"."route_stops" USING ("public"."is_admin"());



CREATE POLICY "route_stops_tourist_all" ON "public"."route_stops" USING ((EXISTS ( SELECT 1
   FROM "public"."routes" "r"
  WHERE (("r"."id" = "route_stops"."route_id") AND ("r"."tourist_id" = "auth"."uid"())))));



ALTER TABLE "public"."routes" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "routes_admin_all" ON "public"."routes" USING ("public"."is_admin"());



CREATE POLICY "routes_tourist_all" ON "public"."routes" USING (("auth"."uid"() = "tourist_id"));



ALTER TABLE "public"."survey_question_translations" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "survey_question_translations_admin_all" ON "public"."survey_question_translations" USING ("public"."is_admin"());



CREATE POLICY "survey_question_translations_public_read" ON "public"."survey_question_translations" FOR SELECT USING (true);



ALTER TABLE "public"."survey_questions" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "survey_questions_admin_all" ON "public"."survey_questions" USING ("public"."is_admin"());



CREATE POLICY "survey_questions_public_read" ON "public"."survey_questions" FOR SELECT USING (true);



ALTER TABLE "public"."survey_responses" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "survey_responses_admin_all" ON "public"."survey_responses" USING ("public"."is_admin"());



CREATE POLICY "survey_responses_user_insert" ON "public"."survey_responses" FOR INSERT WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "survey_responses_user_read_own" ON "public"."survey_responses" FOR SELECT USING (("auth"."uid"() = "user_id"));



ALTER TABLE "public"."survey_translations" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "survey_translations_admin_all" ON "public"."survey_translations" USING ("public"."is_admin"());



CREATE POLICY "survey_translations_public_read" ON "public"."survey_translations" FOR SELECT USING (true);



ALTER TABLE "public"."surveys" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "surveys_admin_all" ON "public"."surveys" USING ("public"."is_admin"());



CREATE POLICY "surveys_public_read" ON "public"."surveys" FOR SELECT USING (("is_active" = true));



ALTER TABLE "public"."training_progress" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "training_progress_admin_all" ON "public"."training_progress" USING ("public"."is_admin"());



CREATE POLICY "training_progress_user_all" ON "public"."training_progress" USING (("auth"."uid"() = "user_id"));



ALTER TABLE "public"."transactions" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "transactions_admin_all" ON "public"."transactions" USING ("public"."is_admin"());



CREATE POLICY "transactions_owner_read" ON "public"."transactions" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."businesses" "b"
  WHERE (("b"."id" = "transactions"."business_id") AND ("b"."owner_id" = "auth"."uid"())))));



CREATE POLICY "transactions_tourist_insert" ON "public"."transactions" FOR INSERT WITH CHECK (("auth"."uid"() = "tourist_id"));



CREATE POLICY "transactions_tourist_read_own" ON "public"."transactions" FOR SELECT USING (("auth"."uid"() = "tourist_id"));



CREATE POLICY "users can remove own reaction" ON "public"."message_reactions" FOR DELETE TO "authenticated" USING (("profile_id" = "auth"."uid"()));



ALTER TABLE "public"."visits" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "visits_admin_all" ON "public"."visits" USING ("public"."is_admin"());



CREATE POLICY "visits_owner_read" ON "public"."visits" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."businesses" "b"
  WHERE (("b"."id" = "visits"."business_id") AND ("b"."owner_id" = "auth"."uid"())))));



CREATE POLICY "visits_tourist_insert" ON "public"."visits" FOR INSERT WITH CHECK (("auth"."uid"() = "tourist_id"));



CREATE POLICY "visits_tourist_read_own" ON "public"."visits" FOR SELECT USING (("auth"."uid"() = "tourist_id"));





ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";






ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."community_members";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."community_messages";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."conversations";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."direct_messages";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."hotspot_events";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."message_reactions";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."notifications";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."transactions";






GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";















































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































GRANT ALL ON FUNCTION "public"."bump_community_member_count"() TO "anon";
GRANT ALL ON FUNCTION "public"."bump_community_member_count"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."bump_community_member_count"() TO "service_role";



GRANT ALL ON FUNCTION "public"."businesses_nearby"("p_lat" double precision, "p_lng" double precision, "p_radius_m" integer, "p_limit" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."businesses_nearby"("p_lat" double precision, "p_lng" double precision, "p_radius_m" integer, "p_limit" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."businesses_nearby"("p_lat" double precision, "p_lng" double precision, "p_radius_m" integer, "p_limit" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."calculate_gini"("business_ids" "uuid"[]) TO "anon";
GRANT ALL ON FUNCTION "public"."calculate_gini"("business_ids" "uuid"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."calculate_gini"("business_ids" "uuid"[]) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_config"("p_key" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."get_config"("p_key" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_config"("p_key" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "service_role";



GRANT ALL ON FUNCTION "public"."invoke_edge_function"("function_name" "text", "payload" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."invoke_edge_function"("function_name" "text", "payload" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."invoke_edge_function"("function_name" "text", "payload" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."is_admin"() TO "anon";
GRANT ALL ON FUNCTION "public"."is_admin"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_admin"() TO "service_role";



GRANT ALL ON FUNCTION "public"."is_community_member"("_community_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."is_community_member"("_community_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_community_member"("_community_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."mp_is_connected"("p_business_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."mp_is_connected"("p_business_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."mp_is_connected"("p_business_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."mp_is_connected"("p_business_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."mp_oauth_states_cleanup"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."mp_oauth_states_cleanup"() TO "anon";
GRANT ALL ON FUNCTION "public"."mp_oauth_states_cleanup"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."mp_oauth_states_cleanup"() TO "service_role";



GRANT ALL ON FUNCTION "public"."on_direct_message_insert"() TO "anon";
GRANT ALL ON FUNCTION "public"."on_direct_message_insert"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."on_direct_message_insert"() TO "service_role";



GRANT ALL ON FUNCTION "public"."open_conversation"("p_business_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."open_conversation"("p_business_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."open_conversation"("p_business_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."recommend_businesses_discovery"("p_tourist_id" "uuid", "p_lat" double precision, "p_lng" double precision, "p_radius_m" integer, "p_limit" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."recommend_businesses_discovery"("p_tourist_id" "uuid", "p_lat" double precision, "p_lng" double precision, "p_radius_m" integer, "p_limit" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."recommend_businesses_discovery"("p_tourist_id" "uuid", "p_lat" double precision, "p_lng" double precision, "p_radius_m" integer, "p_limit" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."recommend_businesses_top_quality"("p_tourist_id" "uuid", "p_lat" double precision, "p_lng" double precision, "p_radius_m" integer, "p_limit" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."recommend_businesses_top_quality"("p_tourist_id" "uuid", "p_lat" double precision, "p_lng" double precision, "p_radius_m" integer, "p_limit" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."recommend_businesses_top_quality"("p_tourist_id" "uuid", "p_lat" double precision, "p_lng" double precision, "p_radius_m" integer, "p_limit" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."rls_auto_enable"() TO "anon";
GRANT ALL ON FUNCTION "public"."rls_auto_enable"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."rls_auto_enable"() TO "service_role";



GRANT ALL ON FUNCTION "public"."set_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_updated_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."tg_mp_accounts_set_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."tg_mp_accounts_set_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."tg_mp_accounts_set_updated_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."trg_businesses_translate_description"() TO "anon";
GRANT ALL ON FUNCTION "public"."trg_businesses_translate_description"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."trg_businesses_translate_description"() TO "service_role";



GRANT ALL ON FUNCTION "public"."trg_offerings_translate"() TO "anon";
GRANT ALL ON FUNCTION "public"."trg_offerings_translate"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."trg_offerings_translate"() TO "service_role";



GRANT ALL ON FUNCTION "public"."trg_update_business_rating"() TO "anon";
GRANT ALL ON FUNCTION "public"."trg_update_business_rating"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."trg_update_business_rating"() TO "service_role";



GRANT ALL ON FUNCTION "public"."trg_update_business_visits"() TO "anon";
GRANT ALL ON FUNCTION "public"."trg_update_business_visits"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."trg_update_business_visits"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_community_member_count"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_community_member_count"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_community_member_count"() TO "service_role";



GRANT ALL ON FUNCTION "public"."validate_message_content"() TO "anon";
GRANT ALL ON FUNCTION "public"."validate_message_content"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."validate_message_content"() TO "service_role";

















































































GRANT ALL ON TABLE "public"."algorithm_config" TO "anon";
GRANT ALL ON TABLE "public"."algorithm_config" TO "authenticated";
GRANT ALL ON TABLE "public"."algorithm_config" TO "service_role";



GRANT ALL ON TABLE "public"."analytics_events" TO "anon";
GRANT ALL ON TABLE "public"."analytics_events" TO "authenticated";
GRANT ALL ON TABLE "public"."analytics_events" TO "service_role";



GRANT ALL ON TABLE "public"."business_images" TO "anon";
GRANT ALL ON TABLE "public"."business_images" TO "authenticated";
GRANT ALL ON TABLE "public"."business_images" TO "service_role";



GRANT ALL ON TABLE "public"."business_translations" TO "anon";
GRANT ALL ON TABLE "public"."business_translations" TO "authenticated";
GRANT ALL ON TABLE "public"."business_translations" TO "service_role";



GRANT ALL ON TABLE "public"."businesses" TO "anon";
GRANT ALL ON TABLE "public"."businesses" TO "authenticated";
GRANT ALL ON TABLE "public"."businesses" TO "service_role";



GRANT ALL ON TABLE "public"."categories" TO "anon";
GRANT ALL ON TABLE "public"."categories" TO "authenticated";
GRANT ALL ON TABLE "public"."categories" TO "service_role";



GRANT ALL ON TABLE "public"."category_translations" TO "anon";
GRANT ALL ON TABLE "public"."category_translations" TO "authenticated";
GRANT ALL ON TABLE "public"."category_translations" TO "service_role";



GRANT ALL ON TABLE "public"."communities" TO "anon";
GRANT ALL ON TABLE "public"."communities" TO "authenticated";
GRANT ALL ON TABLE "public"."communities" TO "service_role";



GRANT ALL ON TABLE "public"."community_members" TO "anon";
GRANT ALL ON TABLE "public"."community_members" TO "authenticated";
GRANT ALL ON TABLE "public"."community_members" TO "service_role";



GRANT ALL ON TABLE "public"."community_messages" TO "anon";
GRANT ALL ON TABLE "public"."community_messages" TO "authenticated";
GRANT ALL ON TABLE "public"."community_messages" TO "service_role";



GRANT ALL ON TABLE "public"."conversations" TO "anon";
GRANT ALL ON TABLE "public"."conversations" TO "authenticated";
GRANT ALL ON TABLE "public"."conversations" TO "service_role";



GRANT ALL ON TABLE "public"."direct_messages" TO "anon";
GRANT ALL ON TABLE "public"."direct_messages" TO "authenticated";
GRANT ALL ON TABLE "public"."direct_messages" TO "service_role";



GRANT ALL ON TABLE "public"."geofences" TO "anon";
GRANT ALL ON TABLE "public"."geofences" TO "authenticated";
GRANT ALL ON TABLE "public"."geofences" TO "service_role";



GRANT ALL ON TABLE "public"."hotspot_events" TO "anon";
GRANT ALL ON TABLE "public"."hotspot_events" TO "authenticated";
GRANT ALL ON TABLE "public"."hotspot_events" TO "service_role";



GRANT ALL ON TABLE "public"."languages" TO "anon";
GRANT ALL ON TABLE "public"."languages" TO "authenticated";
GRANT ALL ON TABLE "public"."languages" TO "service_role";



GRANT ALL ON TABLE "public"."message_reactions" TO "anon";
GRANT ALL ON TABLE "public"."message_reactions" TO "authenticated";
GRANT ALL ON TABLE "public"."message_reactions" TO "service_role";



GRANT ALL ON TABLE "public"."mp_accounts" TO "anon";
GRANT ALL ON TABLE "public"."mp_accounts" TO "authenticated";
GRANT ALL ON TABLE "public"."mp_accounts" TO "service_role";



GRANT ALL ON TABLE "public"."mp_oauth_states" TO "anon";
GRANT ALL ON TABLE "public"."mp_oauth_states" TO "authenticated";
GRANT ALL ON TABLE "public"."mp_oauth_states" TO "service_role";



GRANT ALL ON TABLE "public"."notifications" TO "anon";
GRANT ALL ON TABLE "public"."notifications" TO "authenticated";
GRANT ALL ON TABLE "public"."notifications" TO "service_role";



GRANT ALL ON TABLE "public"."offering_translations" TO "anon";
GRANT ALL ON TABLE "public"."offering_translations" TO "authenticated";
GRANT ALL ON TABLE "public"."offering_translations" TO "service_role";



GRANT ALL ON TABLE "public"."offerings" TO "anon";
GRANT ALL ON TABLE "public"."offerings" TO "authenticated";
GRANT ALL ON TABLE "public"."offerings" TO "service_role";



GRANT ALL ON TABLE "public"."profile_category_interests" TO "anon";
GRANT ALL ON TABLE "public"."profile_category_interests" TO "authenticated";
GRANT ALL ON TABLE "public"."profile_category_interests" TO "service_role";



GRANT ALL ON TABLE "public"."profile_languages" TO "anon";
GRANT ALL ON TABLE "public"."profile_languages" TO "authenticated";
GRANT ALL ON TABLE "public"."profile_languages" TO "service_role";



GRANT ALL ON TABLE "public"."profiles" TO "anon";
GRANT ALL ON TABLE "public"."profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."profiles" TO "service_role";



GRANT ALL ON TABLE "public"."reviews" TO "anon";
GRANT ALL ON TABLE "public"."reviews" TO "authenticated";
GRANT ALL ON TABLE "public"."reviews" TO "service_role";



GRANT ALL ON TABLE "public"."route_stops" TO "anon";
GRANT ALL ON TABLE "public"."route_stops" TO "authenticated";
GRANT ALL ON TABLE "public"."route_stops" TO "service_role";



GRANT ALL ON TABLE "public"."routes" TO "anon";
GRANT ALL ON TABLE "public"."routes" TO "authenticated";
GRANT ALL ON TABLE "public"."routes" TO "service_role";



GRANT ALL ON TABLE "public"."survey_question_translations" TO "anon";
GRANT ALL ON TABLE "public"."survey_question_translations" TO "authenticated";
GRANT ALL ON TABLE "public"."survey_question_translations" TO "service_role";



GRANT ALL ON TABLE "public"."survey_questions" TO "anon";
GRANT ALL ON TABLE "public"."survey_questions" TO "authenticated";
GRANT ALL ON TABLE "public"."survey_questions" TO "service_role";



GRANT ALL ON TABLE "public"."survey_responses" TO "anon";
GRANT ALL ON TABLE "public"."survey_responses" TO "authenticated";
GRANT ALL ON TABLE "public"."survey_responses" TO "service_role";



GRANT ALL ON TABLE "public"."survey_translations" TO "anon";
GRANT ALL ON TABLE "public"."survey_translations" TO "authenticated";
GRANT ALL ON TABLE "public"."survey_translations" TO "service_role";



GRANT ALL ON TABLE "public"."surveys" TO "anon";
GRANT ALL ON TABLE "public"."surveys" TO "authenticated";
GRANT ALL ON TABLE "public"."surveys" TO "service_role";



GRANT ALL ON TABLE "public"."training_progress" TO "anon";
GRANT ALL ON TABLE "public"."training_progress" TO "authenticated";
GRANT ALL ON TABLE "public"."training_progress" TO "service_role";



GRANT ALL ON TABLE "public"."transactions" TO "anon";
GRANT ALL ON TABLE "public"."transactions" TO "authenticated";
GRANT ALL ON TABLE "public"."transactions" TO "service_role";



GRANT ALL ON TABLE "public"."visits" TO "anon";
GRANT ALL ON TABLE "public"."visits" TO "authenticated";
GRANT ALL ON TABLE "public"."visits" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";



































