


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


CREATE SCHEMA IF NOT EXISTS "auditoria";


ALTER SCHEMA "auditoria" OWNER TO "postgres";


CREATE SCHEMA IF NOT EXISTS "configuracion";


ALTER SCHEMA "configuracion" OWNER TO "postgres";


CREATE EXTENSION IF NOT EXISTS "pg_cron" WITH SCHEMA "pg_catalog";






CREATE SCHEMA IF NOT EXISTS "inventario";


ALTER SCHEMA "inventario" OWNER TO "postgres";


CREATE EXTENSION IF NOT EXISTS "pg_net" WITH SCHEMA "extensions";






COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE SCHEMA IF NOT EXISTS "rutas";


ALTER SCHEMA "rutas" OWNER TO "postgres";


CREATE SCHEMA IF NOT EXISTS "usuarios";


ALTER SCHEMA "usuarios" OWNER TO "postgres";


CREATE SCHEMA IF NOT EXISTS "vendedores";


ALTER SCHEMA "vendedores" OWNER TO "postgres";


CREATE SCHEMA IF NOT EXISTS "ventas";


ALTER SCHEMA "ventas" OWNER TO "postgres";


CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE OR REPLACE FUNCTION "auditoria"."fn_log_error_secure"("p_session_token" "text" DEFAULT NULL::"text", "p_nivel" "text" DEFAULT 'error'::"text", "p_mensaje" "text" DEFAULT NULL::"text", "p_stack_trace" "text" DEFAULT NULL::"text", "p_pantalla" "text" DEFAULT NULL::"text", "p_endpoint" "text" DEFAULT NULL::"text", "p_dispositivo" "text" DEFAULT NULL::"text", "p_os_version" "text" DEFAULT NULL::"text", "p_app_version" "text" DEFAULT NULL::"text", "p_metadata" "jsonb" DEFAULT NULL::"jsonb") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  ctx record;
  user_id text;
BEGIN
  IF p_session_token IS NOT NULL AND btrim(p_session_token) <> '' THEN
    BEGIN
      SELECT * INTO ctx FROM usuarios.fn_usuario_sesion(p_session_token);
      user_id := ctx.id::text;
    EXCEPTION WHEN OTHERS THEN
      user_id := NULL;
    END;
  END IF;
-- Datos INSERT omitidos para portafolio.

END;
$$;


ALTER FUNCTION "auditoria"."fn_log_error_secure"("p_session_token" "text", "p_nivel" "text", "p_mensaje" "text", "p_stack_trace" "text", "p_pantalla" "text", "p_endpoint" "text", "p_dispositivo" "text", "p_os_version" "text", "p_app_version" "text", "p_metadata" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "auditoria"."fn_trigger_auditoria"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
-- Datos INSERT omitidos para portafolio.

    RETURN NEW;
  ELSIF TG_OP = 'UPDATE' THEN
-- Datos INSERT omitidos para portafolio.

    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
-- Datos INSERT omitidos para portafolio.

    RETURN OLD;
  END IF;

  RETURN NULL;
END;
$$;


ALTER FUNCTION "auditoria"."fn_trigger_auditoria"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "inventario"."fn_actualizar_actualizado_en"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  NEW.actualizado_en := now();
  RETURN NEW;
END;
$$;


ALTER FUNCTION "inventario"."fn_actualizar_actualizado_en"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "inventario"."fn_actualizar_stock_bajo_calculado"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    NEW.stock_bajo_calculado := inventario.fn_calcular_stock_bajo(
      NEW.stock,
      NEW.stock_minimo
    );
    RETURN NEW;
  END IF;

  IF NEW.stock_minimo IS DISTINCT FROM OLD.stock_minimo
     OR NEW.stock > OLD.stock
     OR NEW.stock_bajo_calculado IS NULL THEN
    NEW.stock_bajo_calculado := inventario.fn_calcular_stock_bajo(
      NEW.stock,
      NEW.stock_minimo
    );
  ELSE
    NEW.stock_bajo_calculado := OLD.stock_bajo_calculado;
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "inventario"."fn_actualizar_stock_bajo_calculado"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "inventario"."fn_calcular_stock_bajo"("p_stock" integer, "p_stock_minimo" integer) RETURNS integer
    LANGUAGE "sql" IMMUTABLE
    AS $$
  SELECT GREATEST(
    COALESCE(p_stock_minimo, 0),
    COALESCE(p_stock_minimo, 0)
      + GREATEST(1, CEIL(GREATEST(COALESCE(p_stock, 0), 0) * 0.10)::integer)
  );
$$;


ALTER FUNCTION "inventario"."fn_calcular_stock_bajo"("p_stock" integer, "p_stock_minimo" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "inventario"."fn_registrar_movimiento_seguro"("p_session_token" "text", "p_producto_id" "uuid", "p_tipo" "text", "p_cantidad" integer, "p_motivo" "text" DEFAULT NULL::"text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'inventario', 'usuarios', 'public', 'extensions'
    AS $$
DECLARE
  ctx record;
  producto record;
  nuevo_stock integer;
BEGIN
  SELECT * INTO ctx FROM usuarios.fn_usuario_sesion(p_session_token);

  IF ctx.rol NOT IN ('admin', 'planta') THEN
    RAISE EXCEPTION 'admin or planta privileges required' USING ERRCODE = '42501';
  END IF;

  IF p_tipo NOT IN ('entrada', 'salida') THEN
    RAISE EXCEPTION 'invalid movement type' USING ERRCODE = '22023';
  END IF;

  IF p_cantidad IS NULL OR p_cantidad <= 0 THEN
    RAISE EXCEPTION 'invalid quantity' USING ERRCODE = '22023';
  END IF;

  SELECT * INTO producto
  FROM inventario.productos
  WHERE id = p_producto_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'product not found' USING ERRCODE = 'P0002';
  END IF;

  nuevo_stock := CASE
    WHEN p_tipo = 'entrada' THEN producto.stock + p_cantidad
    ELSE producto.stock - p_cantidad
  END;

  IF nuevo_stock < 0 THEN
    RAISE EXCEPTION 'insufficient stock for %', producto.nombre
      USING ERRCODE = '23514';
  END IF;

  UPDATE inventario.productos
  SET stock = nuevo_stock,
      actualizado_en = now()
  WHERE id = p_producto_id;
-- Datos INSERT omitidos para portafolio.


  RETURN jsonb_build_object('id', p_producto_id, 'stock', nuevo_stock);
END;
$$;


ALTER FUNCTION "inventario"."fn_registrar_movimiento_seguro"("p_session_token" "text", "p_producto_id" "uuid", "p_tipo" "text", "p_cantidad" integer, "p_motivo" "text") OWNER TO "postgres";


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


CREATE OR REPLACE FUNCTION "usuarios"."fn_base64url_decode"("p_text" "text") RETURNS "bytea"
    LANGUAGE "sql" IMMUTABLE
    AS $$
  SELECT decode(rpad(translate(p_text, '-_', '+/'), ((length(p_text) + 3) / 4) * 4, '='), 'base64');
$$;


ALTER FUNCTION "usuarios"."fn_base64url_decode"("p_text" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "usuarios"."fn_base64url_encode"("p_data" "bytea") RETURNS "text"
    LANGUAGE "sql" IMMUTABLE
    AS $$
  SELECT translate(trim(trailing '=' FROM encode(p_data, 'base64')), '+/', '-_');
$$;


ALTER FUNCTION "usuarios"."fn_base64url_encode"("p_data" "bytea") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "usuarios"."fn_bytea_xor"("p_left" "bytea", "p_right" "bytea") RETURNS "bytea"
    LANGUAGE "plpgsql" IMMUTABLE
    AS $$
DECLARE
  resultado bytea := p_left;
  indice integer;
BEGIN
  IF length(p_left) <> length(p_right) THEN
    RAISE EXCEPTION 'bytea length mismatch';
  END IF;

  FOR indice IN 0..length(p_left) - 1 LOOP
    resultado := set_byte(resultado, indice, get_byte(p_left, indice) # get_byte(p_right, indice));
  END LOOP;

  RETURN resultado;
END;
$$;


ALTER FUNCTION "usuarios"."fn_bytea_xor"("p_left" "bytea", "p_right" "bytea") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "usuarios"."fn_change_my_password_hash"("p_session_token" "text", "p_password_hash" "text") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  ctx record;
BEGIN
  SELECT * INTO ctx FROM usuarios.fn_usuario_sesion(p_session_token);

  UPDATE usuarios.usuarios
  SET hash_contrasena = p_password_hash,
      debe_cambiar_contrasena = false
  WHERE id = ctx.id;
END;
$$;


ALTER FUNCTION "usuarios"."fn_change_my_password_hash"("p_session_token" "text", "p_password_hash" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "usuarios"."fn_contexto_sesion"("p_session_token" "text") RETURNS TABLE("id" "uuid", "rol" "text", "vendedor_id" "uuid")
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO 'usuarios', 'public', 'extensions'
    AS $$
DECLARE
  v_token_hash text;
BEGIN
  IF p_session_token IS NULL OR btrim(p_session_token) = '' THEN
    RAISE EXCEPTION 'missing session token' USING ERRCODE = '28000';
  END IF;

  v_token_hash := encode(digest(convert_to(p_session_token, 'UTF8'), 'sha256'), 'hex');

  RETURN QUERY
  SELECT u.id, u.rol, u.vendedor_id
  FROM usuarios.sesiones_app s
  JOIN usuarios.usuarios u ON u.id = s.usuario_id
  WHERE s.token_hash = v_token_hash
    AND s.revocada_en IS NULL
    AND s.expira_en > now()
    AND u.activo = true
  LIMIT 1;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid session' USING ERRCODE = '28000';
  END IF;
END;
$$;


ALTER FUNCTION "usuarios"."fn_contexto_sesion"("p_session_token" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "usuarios"."fn_delete_user"("p_session_token" "text", "p_target_user_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  ctx record;
BEGIN
  SELECT * INTO ctx FROM usuarios.fn_usuario_sesion(p_session_token);

  IF ctx.rol <> 'admin' THEN
    RAISE EXCEPTION 'admin privileges required' USING ERRCODE = '42501';
  END IF;

  IF ctx.id = p_target_user_id THEN
    RAISE EXCEPTION 'cannot delete your own account';
  END IF;

  DELETE FROM usuarios.usuarios WHERE id = p_target_user_id;
END;
$$;


ALTER FUNCTION "usuarios"."fn_delete_user"("p_session_token" "text", "p_target_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "usuarios"."fn_desactivar_token_dispositivo"("p_session_token" "text", "p_token_firebase" "text") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'usuarios', 'extensions', 'public', 'pg_temp'
    AS $$
DECLARE
  ctx record;
BEGIN
  SELECT * INTO ctx FROM usuarios.fn_usuario_sesion(p_session_token);

  UPDATE usuarios.tokens_dispositivo t
  SET activo = false,
      actualizado_en = now()
  WHERE t.usuario_id = ctx.id
    AND t.token_firebase = btrim(p_token_firebase);
END;
$$;


ALTER FUNCTION "usuarios"."fn_desactivar_token_dispositivo"("p_session_token" "text", "p_token_firebase" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "usuarios"."fn_hash_password"("p_plain_password" "text") RETURNS "text"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $_$
DECLARE
  salt bytea := gen_random_bytes(16);
  iterations integer := 210000;
  derived bytea;
BEGIN
  derived := usuarios.fn_pbkdf2_sha256(p_plain_password, salt, iterations);
  RETURN format(
    'pbkdf2_sha256$%s$%s$%s',
    iterations,
    usuarios.fn_base64url_encode(salt),
    usuarios.fn_base64url_encode(derived)
  );
END;
$_$;


ALTER FUNCTION "usuarios"."fn_hash_password"("p_plain_password" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "usuarios"."fn_list_users"("p_session_token" "text") RETURNS TABLE("id" "uuid", "email" "text", "name" "text", "role" "text", "active" boolean, "seller_id" "uuid", "created_at" timestamp with time zone, "phone" "text", "avatar_url" "text")
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  ctx record;
BEGIN
  SELECT * INTO ctx FROM usuarios.fn_usuario_sesion(p_session_token);

  IF ctx.rol <> 'admin' THEN
    RAISE EXCEPTION 'admin privileges required' USING ERRCODE = '42501';
  END IF;

  RETURN QUERY
  SELECT
    u.id,
    pgp_sym_decrypt(u.email_enc, 'agua_milena_db_key_2026') AS email,
    u.nombre AS name,
    u.rol AS role,
    u.activo AS active,
    u.vendedor_id AS seller_id,
    u.creado_en AS created_at,
    CASE
      WHEN u.telefono_enc IS NOT NULL THEN pgp_sym_decrypt(u.telefono_enc, 'agua_milena_db_key_2026')
      ELSE NULL
    END AS phone,
    u.url_avatar AS avatar_url
  FROM usuarios.usuarios u
  ORDER BY u.nombre ASC;
END;
$$;


ALTER FUNCTION "usuarios"."fn_list_users"("p_session_token" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "usuarios"."fn_login"("p_email" "text", "p_password" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $_$
DECLARE
  usuario record;
  session_token text;
  session_hash text;
  target_hash text;
BEGIN
  target_hash := encode(digest(lower(trim(p_email)), 'sha256'), 'hex');

  SELECT id, email_enc, nombre, rol, vendedor_id, debe_cambiar_contrasena,
         hash_contrasena, telefono_enc, url_avatar
  INTO usuario
  FROM usuarios.usuarios
  WHERE email_hash = target_hash
    AND activo = true
  LIMIT 1;

  IF NOT FOUND OR NOT usuarios.fn_verify_password(p_password, usuario.hash_contrasena) THEN
    RAISE EXCEPTION 'invalid credentials' USING ERRCODE = '28000';
  END IF;

  IF usuario.hash_contrasena NOT LIKE 'pbkdf2_sha256$%' THEN
    UPDATE usuarios.usuarios
    SET hash_contrasena = usuarios.fn_hash_password(p_password)
    WHERE id = usuario.id;
  END IF;

  session_token := encode(gen_random_bytes(32), 'hex');
  session_hash := encode(digest(convert_to(session_token, 'UTF8'), 'sha256'), 'hex');
-- Datos INSERT omitidos para portafolio.


  RETURN jsonb_build_object(
    'session_token', session_token,
    'user', jsonb_build_object(
      'id', usuario.id,
      'email', pgp_sym_decrypt(usuario.email_enc, 'agua_milena_db_key_2026'),
      'name', usuario.nombre,
      'role', usuario.rol,
      'seller_id', usuario.vendedor_id,
      'must_change_password', usuario.debe_cambiar_contrasena,
      'phone', CASE
        WHEN usuario.telefono_enc IS NOT NULL THEN pgp_sym_decrypt(usuario.telefono_enc, 'agua_milena_db_key_2026')
        ELSE NULL
      END,
      'avatar_url', usuario.url_avatar
    )
  );
END;
$_$;


ALTER FUNCTION "usuarios"."fn_login"("p_email" "text", "p_password" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "usuarios"."fn_logout"("p_session_token" "text") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_token_hash text;
BEGIN
  IF p_session_token IS NULL OR btrim(p_session_token) = '' THEN
    RETURN;
  END IF;

  v_token_hash := encode(digest(convert_to(p_session_token, 'UTF8'), 'sha256'), 'hex');

  UPDATE usuarios.sesiones_app s
  SET revocada_en = now()
  WHERE s.token_hash = v_token_hash
    AND s.revocada_en IS NULL;
END;
$$;


ALTER FUNCTION "usuarios"."fn_logout"("p_session_token" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "usuarios"."fn_pbkdf2_sha256"("p_password" "text", "p_salt" "bytea", "p_iterations" integer) RETURNS "bytea"
    LANGUAGE "plpgsql" IMMUTABLE
    AS $$
DECLARE
  llave bytea := convert_to(p_password, 'UTF8');
  u bytea;
  resultado bytea;
  indice integer;
BEGIN
  IF p_iterations < 1 THEN
    RAISE EXCEPTION 'invalid iteration count';
  END IF;

  u := hmac(p_salt || decode('00000001', 'hex'), llave, 'sha256');
  resultado := u;

  FOR indice IN 2..p_iterations LOOP
    u := hmac(u, llave, 'sha256');
    resultado := usuarios.fn_bytea_xor(resultado, u);
  END LOOP;

  RETURN resultado;
END;
$$;


ALTER FUNCTION "usuarios"."fn_pbkdf2_sha256"("p_password" "text", "p_salt" "bytea", "p_iterations" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "usuarios"."fn_registrar_token_dispositivo"("p_session_token" "text", "p_token_firebase" "text", "p_plataforma" "text" DEFAULT 'android'::"text", "p_nombre_dispositivo" "text" DEFAULT NULL::"text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'usuarios', 'extensions', 'public', 'pg_temp'
    AS $$
DECLARE
  ctx record;
  token_guardado record;
BEGIN
  SELECT * INTO ctx FROM usuarios.fn_usuario_sesion(p_session_token);

  IF p_token_firebase IS NULL OR btrim(p_token_firebase) = '' THEN
    RAISE EXCEPTION 'missing firebase token' USING ERRCODE = '22023';
  END IF;
-- Datos INSERT omitidos para portafolio.


  RETURN jsonb_build_object(
    'id', token_guardado.id,
    'usuario_id', token_guardado.usuario_id,
    'activo', token_guardado.activo,
    'actualizado_en', token_guardado.actualizado_en
  );
END;
$$;


ALTER FUNCTION "usuarios"."fn_registrar_token_dispositivo"("p_session_token" "text", "p_token_firebase" "text", "p_plataforma" "text", "p_nombre_dispositivo" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "usuarios"."fn_rol_sesion_header"() RETURNS "text"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'usuarios', 'public', 'extensions'
    AS $$
DECLARE
  ctx record;
  token text;
BEGIN
  token := usuarios.fn_session_token_header();
  IF token IS NULL THEN
    RETURN NULL;
  END IF;

  SELECT * INTO ctx FROM usuarios.fn_contexto_sesion(token);
  RETURN ctx.rol;
EXCEPTION
  WHEN others THEN
    RETURN NULL;
END;
$$;


ALTER FUNCTION "usuarios"."fn_rol_sesion_header"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "usuarios"."fn_sesion_header_tiene_rol"("p_roles" "text"[]) RETURNS boolean
    LANGUAGE "sql" SECURITY DEFINER
    SET "search_path" TO 'usuarios', 'public', 'extensions'
    AS $$
  SELECT COALESCE(usuarios.fn_rol_sesion_header() = ANY(p_roles), false);
$$;


ALTER FUNCTION "usuarios"."fn_sesion_header_tiene_rol"("p_roles" "text"[]) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "usuarios"."fn_sesion_header_valida"() RETURNS boolean
    LANGUAGE "sql" SECURITY DEFINER
    SET "search_path" TO 'usuarios', 'public', 'extensions'
    AS $$
  SELECT usuarios.fn_rol_sesion_header() IS NOT NULL;
$$;


ALTER FUNCTION "usuarios"."fn_sesion_header_valida"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "usuarios"."fn_session_token_header"() RETURNS "text"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'usuarios', 'public', 'extensions'
    AS $$
DECLARE
  headers jsonb;
BEGIN
  headers := NULLIF(current_setting('request.headers', true), '')::jsonb;
  RETURN NULLIF(headers->>'x-agua-milena-session', '');
EXCEPTION
  WHEN others THEN
    RETURN NULL;
END;
$$;


ALTER FUNCTION "usuarios"."fn_session_token_header"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "usuarios"."fn_tokens_notificacion"("p_rol" "text" DEFAULT NULL::"text", "p_usuario_id" "uuid" DEFAULT NULL::"uuid") RETURNS TABLE("token_firebase" "text", "usuario_id" "uuid", "rol" "text")
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'usuarios', 'public', 'pg_temp'
    AS $$
BEGIN
  RETURN QUERY
  SELECT t.token_firebase, t.usuario_id, u.rol
  FROM usuarios.tokens_dispositivo t
  JOIN usuarios.usuarios u ON u.id = t.usuario_id
  WHERE t.activo = true
    AND u.activo = true
    AND (p_rol IS NULL OR u.rol = p_rol)
    AND (p_usuario_id IS NULL OR t.usuario_id = p_usuario_id);
END;
$$;


ALTER FUNCTION "usuarios"."fn_tokens_notificacion"("p_rol" "text", "p_usuario_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "usuarios"."fn_upsert_user"("p_session_token" "text", "p_target_user_id" "uuid" DEFAULT NULL::"uuid", "p_email" "text" DEFAULT NULL::"text", "p_name" "text" DEFAULT NULL::"text", "p_password_hash" "text" DEFAULT NULL::"text", "p_role" "text" DEFAULT NULL::"text", "p_active" boolean DEFAULT NULL::boolean, "p_seller_id" "uuid" DEFAULT NULL::"uuid", "p_must_change_password" boolean DEFAULT NULL::boolean, "p_phone" "text" DEFAULT NULL::"text", "p_avatar_url" "text" DEFAULT NULL::"text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  ctx record;
  usuario record;
BEGIN
  SELECT * INTO ctx FROM usuarios.fn_usuario_sesion(p_session_token);

  IF p_target_user_id IS NOT NULL AND ctx.id = p_target_user_id THEN
    NULL;
  ELSIF ctx.rol <> 'admin' THEN
    RAISE EXCEPTION 'admin privileges required' USING ERRCODE = '42501';
  END IF;

  IF p_target_user_id IS NULL THEN
    IF p_email IS NULL OR p_name IS NULL OR p_role IS NULL OR p_password_hash IS NULL THEN
      RAISE EXCEPTION 'missing required fields for create';
    END IF;
-- Datos INSERT omitidos para portafolio.


    RETURN jsonb_build_object(
      'id', usuario.id,
      'email', lower(trim(p_email)),
      'name', usuario.nombre,
      'role', usuario.rol,
      'active', usuario.activo,
      'seller_id', usuario.vendedor_id,
      'must_change_password', usuario.debe_cambiar_contrasena,
      'phone', p_phone,
      'avatar_url', usuario.url_avatar
    );
  END IF;

  UPDATE usuarios.usuarios
  SET
    email_hash = CASE WHEN p_email IS NOT NULL THEN encode(digest(lower(trim(p_email)), 'sha256'), 'hex') ELSE email_hash END,
    email_enc = CASE WHEN p_email IS NOT NULL THEN pgp_sym_encrypt(lower(trim(p_email)), 'agua_milena_db_key_2026') ELSE email_enc END,
    nombre = COALESCE(trim(p_name), nombre),
    hash_contrasena = COALESCE(p_password_hash, hash_contrasena),
    rol = CASE WHEN ctx.rol = 'admin' THEN COALESCE(p_role, rol) ELSE rol END,
    activo = CASE WHEN ctx.rol = 'admin' THEN COALESCE(p_active, activo) ELSE activo END,
    vendedor_id = CASE
      WHEN ctx.rol = 'admin' AND COALESCE(p_role, rol) <> 'vendedor' THEN NULL
      WHEN ctx.rol = 'admin' THEN COALESCE(p_seller_id, vendedor_id)
      ELSE vendedor_id
    END,
    debe_cambiar_contrasena = COALESCE(p_must_change_password, debe_cambiar_contrasena),
    telefono_enc = CASE
      WHEN p_phone = '' THEN NULL
      WHEN p_phone IS NOT NULL THEN pgp_sym_encrypt(p_phone, 'agua_milena_db_key_2026')
      ELSE telefono_enc
    END,
    url_avatar = COALESCE(p_avatar_url, url_avatar)
  WHERE id = p_target_user_id
  RETURNING id, nombre, rol, activo, vendedor_id, debe_cambiar_contrasena, email_enc, telefono_enc, url_avatar
  INTO usuario;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'user not found';
  END IF;

  RETURN jsonb_build_object(
    'id', usuario.id,
    'email', pgp_sym_decrypt(usuario.email_enc, 'agua_milena_db_key_2026'),
    'name', usuario.nombre,
    'role', usuario.rol,
    'active', usuario.activo,
    'seller_id', usuario.vendedor_id,
    'must_change_password', usuario.debe_cambiar_contrasena,
    'phone', CASE
      WHEN usuario.telefono_enc IS NOT NULL THEN pgp_sym_decrypt(usuario.telefono_enc, 'agua_milena_db_key_2026')
      ELSE NULL
    END,
    'avatar_url', usuario.url_avatar
  );
END;
$$;


ALTER FUNCTION "usuarios"."fn_upsert_user"("p_session_token" "text", "p_target_user_id" "uuid", "p_email" "text", "p_name" "text", "p_password_hash" "text", "p_role" "text", "p_active" boolean, "p_seller_id" "uuid", "p_must_change_password" boolean, "p_phone" "text", "p_avatar_url" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "usuarios"."fn_usuario_sesion"("p_session_token" "text") RETURNS TABLE("id" "uuid", "email" "text", "nombre" "text", "rol" "text", "vendedor_id" "uuid", "debe_cambiar_contrasena" boolean, "telefono" "text", "url_avatar" "text")
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_token_hash text;
BEGIN
  IF p_session_token IS NULL OR btrim(p_session_token) = '' THEN
    RAISE EXCEPTION 'missing session token' USING ERRCODE = '28000';
  END IF;

  v_token_hash := encode(digest(convert_to(p_session_token, 'UTF8'), 'sha256'), 'hex');

  UPDATE usuarios.sesiones_app s
  SET ultimo_acceso = now()
  WHERE s.token_hash = v_token_hash
    AND s.revocada_en IS NULL
    AND s.expira_en > now();

  RETURN QUERY
  SELECT
    u.id,
    pgp_sym_decrypt(u.email_enc, 'agua_milena_db_key_2026') AS email,
    u.nombre,
    u.rol,
    u.vendedor_id,
    u.debe_cambiar_contrasena,
    CASE
      WHEN u.telefono_enc IS NOT NULL THEN pgp_sym_decrypt(u.telefono_enc, 'agua_milena_db_key_2026')
      ELSE NULL
    END AS telefono,
    u.url_avatar
  FROM usuarios.sesiones_app s
  JOIN usuarios.usuarios u ON u.id = s.usuario_id
  WHERE s.token_hash = v_token_hash
    AND s.revocada_en IS NULL
    AND s.expira_en > now()
    AND u.activo = true
  LIMIT 1;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid session' USING ERRCODE = '28000';
  END IF;
END;
$$;


ALTER FUNCTION "usuarios"."fn_usuario_sesion"("p_session_token" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "usuarios"."fn_validate_session"("p_session_token" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  ctx record;
BEGIN
  SELECT * INTO ctx FROM usuarios.fn_usuario_sesion(p_session_token);

  RETURN jsonb_build_object(
    'id', ctx.id,
    'email', ctx.email,
    'name', ctx.nombre,
    'role', ctx.rol,
    'seller_id', ctx.vendedor_id,
    'must_change_password', ctx.debe_cambiar_contrasena,
    'phone', ctx.telefono,
    'avatar_url', ctx.url_avatar
  );
END;
$$;


ALTER FUNCTION "usuarios"."fn_validate_session"("p_session_token" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "usuarios"."fn_verify_password"("p_plain_password" "text", "p_stored_hash" "text") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $_$
DECLARE
  parts text[];
  iterations integer;
  salt bytea;
  expected bytea;
  derived bytea;
BEGIN
  IF p_stored_hash LIKE 'pbkdf2_sha256$%' THEN
    parts := string_to_array(p_stored_hash, '$');
    IF array_length(parts, 1) <> 4 THEN
      RETURN false;
    END IF;

    iterations := parts[2]::integer;
    salt := usuarios.fn_base64url_decode(parts[3]);
    expected := usuarios.fn_base64url_decode(parts[4]);
    derived := usuarios.fn_pbkdf2_sha256(p_plain_password, salt, iterations);
    RETURN derived = expected;
  END IF;

  RETURN encode(sha256(convert_to(p_plain_password || 'AguaMilenaSecureS4lt_2026!', 'UTF8')), 'hex') = p_stored_hash;
END;
$_$;


ALTER FUNCTION "usuarios"."fn_verify_password"("p_plain_password" "text", "p_stored_hash" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "ventas"."fn_crear_venta_segura"("p_session_token" "text", "p_items" "jsonb", "p_notas" "text" DEFAULT NULL::"text", "p_vendedor_id" "uuid" DEFAULT NULL::"uuid", "p_bidones_llenos_en_carro" integer DEFAULT 0, "p_bidones_vacios_recibidos" integer DEFAULT 0) RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'ventas', 'rutas', 'inventario', 'vendedores', 'usuarios', 'public', 'extensions'
    AS $$
DECLARE
  ctx record;
  item jsonb;
  producto record;
  vendedor record;
  venta_id uuid;
  ruta_id uuid;
  producto_id uuid;
  cantidad integer;
  total numeric := 0;
  subtotal numeric;
  bidones_cargados integer := 0;
  credito_aplicado numeric := 0;
  saldo_favor numeric := 0;
  restante_credito numeric := 0;
  ruta_credito record;
  nuevos_llenos integer := 0;
  nuevos_prestados integer := 0;
BEGIN
  SELECT * INTO ctx FROM usuarios.fn_usuario_sesion(p_session_token);

  IF ctx.rol NOT IN ('admin', 'planta') THEN
    RAISE EXCEPTION 'admin or planta privileges required' USING ERRCODE = '42501';
  END IF;

  IF p_items IS NULL OR jsonb_typeof(p_items) <> 'array' OR jsonb_array_length(p_items) = 0 THEN
    RAISE EXCEPTION 'sale items are required' USING ERRCODE = '22023';
  END IF;

  FOR item IN SELECT value FROM jsonb_array_elements(p_items)
  LOOP
    producto_id := (item->>'producto_id')::uuid;
    cantidad := COALESCE((item->>'cantidad')::integer, 0);

    IF cantidad <= 0 THEN
      RAISE EXCEPTION 'invalid item quantity' USING ERRCODE = '22023';
    END IF;

    SELECT * INTO producto
    FROM inventario.productos
    WHERE id = producto_id
    FOR UPDATE;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'product not found' USING ERRCODE = 'P0002';
    END IF;

    IF producto.stock < cantidad THEN
      RAISE EXCEPTION 'insufficient stock for %', producto.nombre
        USING ERRCODE = '23514';
    END IF;

    subtotal := producto.precio * cantidad;
    total := total + subtotal;

    IF lower(producto.nombre || ' ' || producto.unidad) LIKE '%bidon%'
       OR lower(producto.nombre || ' ' || producto.unidad) LIKE '%bidón%' THEN
      bidones_cargados := bidones_cargados + cantidad;
    END IF;
  END LOOP;

  IF p_vendedor_id IS NOT NULL THEN
    SELECT * INTO vendedor
    FROM vendedores.vendedores
    WHERE id = p_vendedor_id
    FOR UPDATE;

    IF NOT FOUND OR vendedor.activo IS NOT TRUE THEN
      RAISE EXCEPTION 'seller not found or inactive' USING ERRCODE = 'P0002';
    END IF;

    SELECT COALESCE(SUM(GREATEST(monto_cobrado - monto_total, 0)), 0)
    INTO saldo_favor
    FROM rutas.rutas
    WHERE vendedor_id = p_vendedor_id;

    credito_aplicado := LEAST(saldo_favor, total);

    SELECT id INTO ruta_id
    FROM rutas.rutas
    WHERE vendedor_id = p_vendedor_id
      AND fecha = CURRENT_DATE
      AND estado IN ('sin_cierre', 'pendiente', 'parcial')
    ORDER BY creado_en ASC
    LIMIT 1
    FOR UPDATE;

    IF ruta_id IS NULL THEN
-- Datos INSERT omitidos para portafolio.

    END IF;
  END IF;
-- Datos INSERT omitidos para portafolio.


  FOR item IN SELECT value FROM jsonb_array_elements(p_items)
  LOOP
    producto_id := (item->>'producto_id')::uuid;
    cantidad := COALESCE((item->>'cantidad')::integer, 0);

    SELECT * INTO producto
    FROM inventario.productos
    WHERE id = producto_id;
-- Datos INSERT omitidos para portafolio.


    UPDATE inventario.productos
    SET stock = stock - cantidad,
        actualizado_en = now()
    WHERE id = producto_id;
-- Datos INSERT omitidos para portafolio.

  END LOOP;

  IF p_vendedor_id IS NOT NULL THEN
    nuevos_llenos := GREATEST(COALESCE(p_bidones_llenos_en_carro, 0), 0) + bidones_cargados;
    nuevos_prestados := GREATEST(nuevos_llenos - COALESCE(vendedor.bidones_propios, 0), 0);

    UPDATE vendedores.vendedores
    SET bidones_llenos_actuales = nuevos_llenos,
        bidones_vacios_actuales = 0,
        bidones_prestados = nuevos_prestados
    WHERE id = p_vendedor_id;

    UPDATE rutas.rutas
    SET monto_total = monto_total + GREATEST(total - credito_aplicado, 0),
        bidones_cargados_hoy = bidones_cargados_hoy + bidones_cargados,
        estado = CASE WHEN monto_cobrado > 0 THEN 'parcial' ELSE 'pendiente' END
    WHERE id = ruta_id;

    restante_credito := credito_aplicado;
    FOR ruta_credito IN
      SELECT id, monto_total, monto_cobrado
      FROM rutas.rutas
      WHERE vendedor_id = p_vendedor_id
        AND monto_cobrado > monto_total
      ORDER BY creado_en ASC
      FOR UPDATE
    LOOP
      EXIT WHEN restante_credito <= 0;

      subtotal := LEAST(ruta_credito.monto_cobrado - ruta_credito.monto_total, restante_credito);
      UPDATE rutas.rutas
      SET monto_cobrado = monto_cobrado - subtotal
      WHERE id = ruta_credito.id;

      restante_credito := restante_credito - subtotal;
    END LOOP;
  END IF;

  RETURN venta_id;
END;
$$;


ALTER FUNCTION "ventas"."fn_crear_venta_segura"("p_session_token" "text", "p_items" "jsonb", "p_notas" "text", "p_vendedor_id" "uuid", "p_bidones_llenos_en_carro" integer, "p_bidones_vacios_recibidos" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "ventas"."fn_crear_venta_segura"("p_session_token" "text", "p_items" "jsonb", "p_notas" "text" DEFAULT NULL::"text", "p_vendedor_id" "uuid" DEFAULT NULL::"uuid", "p_fecha" "date" DEFAULT CURRENT_DATE, "p_bidones_llenos_en_carro" integer DEFAULT 0, "p_bidones_vacios_recibidos" integer DEFAULT 0) RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'ventas', 'rutas', 'inventario', 'vendedores', 'usuarios', 'public', 'extensions'
    AS $$
DECLARE
  ctx record;
  item jsonb;
  producto record;
  vendedor record;
  venta_id uuid;
  ruta_id uuid;
  producto_id uuid;
  cantidad integer;
  total numeric := 0;
  bidones_cargados integer := 0;
  saldo_favor numeric := 0;
  credito_aplicado numeric := 0;
  nuevos_llenos integer := 0;
  nuevos_prestados integer := 0;
  restante_credito numeric := 0;
  monto_consumir numeric := 0;
  ruta_credito record;
  fecha_venta date := COALESCE(p_fecha, CURRENT_DATE);
BEGIN
  SELECT * INTO ctx FROM usuarios.fn_usuario_sesion(p_session_token);

  IF ctx.rol NOT IN ('admin', 'planta') THEN
    RAISE EXCEPTION 'No autorizado para crear ventas.' USING ERRCODE = '42501';
  END IF;

  IF p_items IS NULL OR jsonb_array_length(p_items) = 0 THEN
    RAISE EXCEPTION 'La venta no tiene productos.' USING ERRCODE = '22023';
  END IF;

  FOR item IN SELECT value FROM jsonb_array_elements(p_items)
  LOOP
    producto_id := (item->>'producto_id')::uuid;
    cantidad := COALESCE((item->>'cantidad')::integer, 0);

    IF cantidad <= 0 THEN
      RAISE EXCEPTION 'Cantidad invalida.' USING ERRCODE = '22023';
    END IF;

    SELECT * INTO producto
    FROM inventario.productos
    WHERE id = producto_id
    FOR UPDATE;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Producto no encontrado.' USING ERRCODE = 'P0002';
    END IF;

    IF producto.stock < cantidad THEN
      RAISE EXCEPTION 'Stock insuficiente para %. Disponible: %.', producto.nombre, producto.stock
      USING ERRCODE = '22003';
    END IF;

    total := total + (producto.precio * cantidad);
    IF lower(producto.nombre) LIKE '%bid%' THEN
      bidones_cargados := bidones_cargados + cantidad;
    END IF;
  END LOOP;

  IF p_vendedor_id IS NOT NULL THEN
    SELECT * INTO vendedor
    FROM vendedores.vendedores
    WHERE id = p_vendedor_id
    FOR UPDATE;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Vendedor no encontrado.' USING ERRCODE = 'P0002';
    END IF;

    SELECT COALESCE(SUM(monto_cobrado - monto_total), 0)
    INTO saldo_favor
    FROM rutas.rutas
    WHERE vendedor_id = p_vendedor_id;

    credito_aplicado := LEAST(saldo_favor, total);

    SELECT id INTO ruta_id
    FROM rutas.rutas
    WHERE vendedor_id = p_vendedor_id
      AND fecha = fecha_venta
      AND estado IN ('sin_cierre', 'pendiente', 'parcial')
    ORDER BY creado_en ASC
    LIMIT 1
    FOR UPDATE;

    IF ruta_id IS NULL THEN
-- Datos INSERT omitidos para portafolio.

    END IF;
  END IF;
-- Datos INSERT omitidos para portafolio.


  FOR item IN SELECT value FROM jsonb_array_elements(p_items)
  LOOP
    producto_id := (item->>'producto_id')::uuid;
    cantidad := COALESCE((item->>'cantidad')::integer, 0);

    SELECT * INTO producto
    FROM inventario.productos
    WHERE id = producto_id;
-- Datos INSERT omitidos para portafolio.


    UPDATE inventario.productos
    SET stock = stock - cantidad,
        actualizado_en = now()
    WHERE id = producto_id;
-- Datos INSERT omitidos para portafolio.

  END LOOP;

  IF p_vendedor_id IS NOT NULL THEN
    nuevos_llenos := GREATEST(COALESCE(p_bidones_llenos_en_carro, 0), 0) + bidones_cargados;
    nuevos_prestados := GREATEST(nuevos_llenos - COALESCE(vendedor.bidones_propios, 0), 0);

    UPDATE vendedores.vendedores
    SET bidones_llenos_actuales = nuevos_llenos,
        bidones_vacios_actuales = 0,
        bidones_prestados = nuevos_prestados
    WHERE id = p_vendedor_id;

    UPDATE rutas.rutas
    SET monto_total = monto_total + GREATEST(total - credito_aplicado, 0),
        bidones_cargados_hoy = bidones_cargados_hoy + bidones_cargados,
        estado = CASE WHEN monto_cobrado > 0 THEN 'parcial' ELSE 'pendiente' END
    WHERE id = ruta_id;

    restante_credito := credito_aplicado;
    FOR ruta_credito IN
      SELECT id, monto_total, monto_cobrado
      FROM rutas.rutas
      WHERE vendedor_id = p_vendedor_id
        AND monto_cobrado > monto_total
      ORDER BY creado_en ASC
    LOOP
      EXIT WHEN restante_credito <= 0;
      monto_consumir := LEAST(restante_credito, ruta_credito.monto_cobrado - ruta_credito.monto_total);
      UPDATE rutas.rutas
      SET monto_cobrado = monto_cobrado - monto_consumir
      WHERE id = ruta_credito.id;
      restante_credito := restante_credito - monto_consumir;
    END LOOP;
  END IF;

  RETURN venta_id;
END;
$$;


ALTER FUNCTION "ventas"."fn_crear_venta_segura"("p_session_token" "text", "p_items" "jsonb", "p_notas" "text", "p_vendedor_id" "uuid", "p_fecha" "date", "p_bidones_llenos_en_carro" integer, "p_bidones_vacios_recibidos" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "ventas"."fn_resumen_ventas"("p_fecha_inicio" "date", "p_fecha_fin" "date", "p_vendedor_id" "uuid" DEFAULT NULL::"uuid", "p_solo_distribuidora" boolean DEFAULT false) RETURNS TABLE("cantidad" bigint, "total" numeric)
    LANGUAGE "sql" STABLE
    AS $$
  SELECT
    COUNT(*)::bigint AS cantidad,
    COALESCE(SUM(v.total), 0)::numeric AS total
  FROM ventas.ventas v
  WHERE v.fecha >= p_fecha_inicio
    AND v.fecha <= p_fecha_fin
    AND (
      (p_solo_distribuidora AND v.vendedor_id IS NULL)
      OR (
        NOT p_solo_distribuidora
        AND (p_vendedor_id IS NULL OR v.vendedor_id = p_vendedor_id)
      )
    );
$$;


ALTER FUNCTION "ventas"."fn_resumen_ventas"("p_fecha_inicio" "date", "p_fecha_fin" "date", "p_vendedor_id" "uuid", "p_solo_distribuidora" boolean) OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "auditoria"."log_auditoria" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "usuario_id" "text",
    "usuario_email" "text",
    "accion" "text" NOT NULL,
    "esquema" "text" NOT NULL,
    "tabla" "text" NOT NULL,
    "registro_id" "text",
    "datos_antes" "jsonb",
    "datos_despues" "jsonb",
    "ip_address" "text",
    "dispositivo" "text",
    "version_app" "text",
    "creado_en" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "log_auditoria_accion_check" CHECK (("accion" = ANY (ARRAY['INSERT'::"text", 'UPDATE'::"text", 'DELETE'::"text"])))
);


ALTER TABLE "auditoria"."log_auditoria" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "auditoria"."log_error" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "usuario_id" "text",
    "nivel" "text" DEFAULT 'error'::"text" NOT NULL,
    "mensaje" "text" NOT NULL,
    "stack_trace" "text",
    "pantalla" "text",
    "endpoint" "text",
    "dispositivo" "text",
    "version_os" "text",
    "version_app" "text",
    "metadata" "jsonb",
    "creado_en" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "log_error_nivel_check" CHECK (("nivel" = ANY (ARRAY['warning'::"text", 'error'::"text", 'fatal'::"text"])))
);


ALTER TABLE "auditoria"."log_error" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "configuracion"."versiones_aplicacion" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "plataforma" "text" NOT NULL,
    "version_actual" "text" NOT NULL,
    "numero_compilacion_actual" integer NOT NULL,
    "version_minima" "text" NOT NULL,
    "numero_compilacion_minima" integer NOT NULL,
    "url_actualizacion" "text" NOT NULL,
    "mensaje_actualizacion" "text",
    "actualizacion_obligatoria" boolean DEFAULT false NOT NULL,
    "modo_mantenimiento" boolean DEFAULT false NOT NULL,
    "mensaje_mantenimiento" "text",
    "activa" boolean DEFAULT true NOT NULL,
    "creado_en" timestamp with time zone DEFAULT "now"() NOT NULL,
    "actualizado_en" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "versiones_aplicacion_plataforma_check" CHECK (("plataforma" = ANY (ARRAY['android'::"text", 'ios'::"text", 'web'::"text"])))
);


ALTER TABLE "configuracion"."versiones_aplicacion" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "inventario"."alertas" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "producto_id" "uuid",
    "tipo" "text" NOT NULL,
    "mensaje" "text" NOT NULL,
    "leida" boolean DEFAULT false NOT NULL,
    "activada_en" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "inventario"."alertas" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "inventario"."configuracion_app" (
    "clave" "text" NOT NULL,
    "valor_json" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "actualizado_en" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "inventario"."configuracion_app" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "inventario"."movimientos_inventario" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "producto_id" "uuid" NOT NULL,
    "tipo" "text" NOT NULL,
    "cantidad" integer NOT NULL,
    "motivo" "text",
    "creado_en" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "movimientos_inventario_cantidad_check" CHECK (("cantidad" > 0)),
    CONSTRAINT "movimientos_inventario_tipo_check" CHECK (("tipo" = ANY (ARRAY['entrada'::"text", 'salida'::"text"])))
);


ALTER TABLE "inventario"."movimientos_inventario" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "inventario"."predicciones_modelo_alertas" (
    "clave" "text" NOT NULL,
    "tipo" "text" NOT NULL,
    "fecha_objetivo" "date" NOT NULL,
    "periodo_inicio" "date",
    "periodo_fin" "date",
    "titulo" "text" NOT NULL,
    "cuerpo" "text" NOT NULL,
    "demanda_bidones" integer,
    "demanda_fundas" integer,
    "carga_bidones" integer,
    "carga_fundas" integer,
    "riesgo_stock_bajo" numeric,
    "venta_alta_inesperada" numeric,
    "dia_pico" "date",
    "temporada_nombre" "text",
    "dias_restantes" integer,
    "modelo_nombre" "text",
    "origen" "text" DEFAULT 'tflite'::"text" NOT NULL,
    "creado_en" timestamp with time zone DEFAULT "now"() NOT NULL,
    "actualizado_en" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "predicciones_modelo_alertas_tipo_check" CHECK (("tipo" = ANY (ARRAY['diaria'::"text", 'semanal'::"text", 'mensual'::"text", 'temporada_mes'::"text", 'temporada_semana'::"text", 'temporada_dia'::"text"])))
);


ALTER TABLE "inventario"."predicciones_modelo_alertas" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "inventario"."productos" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "nombre" "text" NOT NULL,
    "descripcion" "text",
    "unidad" "text" DEFAULT 'unidad'::"text" NOT NULL,
    "precio" numeric(10,2) DEFAULT 0 NOT NULL,
    "stock" integer DEFAULT 0 NOT NULL,
    "stock_minimo" integer DEFAULT 5 NOT NULL,
    "url_imagen" "text",
    "catalogo" "text" DEFAULT 'distribuidora'::"text" NOT NULL,
    "creado_en" timestamp with time zone DEFAULT "now"() NOT NULL,
    "actualizado_en" timestamp with time zone DEFAULT "now"() NOT NULL,
    "stock_bajo_calculado" integer,
    CONSTRAINT "productos_catalogo_check" CHECK (("catalogo" = ANY (ARRAY['distribuidora'::"text", 'vendedor'::"text"]))),
    CONSTRAINT "productos_precio_check" CHECK (("precio" >= (0)::numeric)),
    CONSTRAINT "productos_stock_check" CHECK (("stock" >= 0)),
    CONSTRAINT "productos_stock_minimo_check" CHECK (("stock_minimo" >= 0))
);


ALTER TABLE "inventario"."productos" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "inventario"."versiones_aplicacion" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "plataforma" "text" NOT NULL,
    "version_actual" "text" DEFAULT '1.0.2'::"text" NOT NULL,
    "numero_compilacion_actual" integer DEFAULT 2004 NOT NULL,
    "version_minima" "text" DEFAULT '1.0.2'::"text" NOT NULL,
    "numero_compilacion_minima" integer DEFAULT 2004 NOT NULL,
    "url_actualizacion" "text" NOT NULL,
    "mensaje_actualizacion" "text" DEFAULT 'Hay una nueva version de Agua Milena disponible.'::"text" NOT NULL,
    "actualizacion_obligatoria" boolean DEFAULT false NOT NULL,
    "modo_mantenimiento" boolean DEFAULT false NOT NULL,
    "mensaje_mantenimiento" "text" DEFAULT 'La aplicacion esta en mantenimiento. Volveremos pronto.'::"text" NOT NULL,
    "activa" boolean DEFAULT true NOT NULL,
    "creado_en" timestamp with time zone DEFAULT "now"() NOT NULL,
    "actualizado_en" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "versiones_aplicacion_plataforma_check" CHECK (("plataforma" = ANY (ARRAY['android'::"text", 'ios'::"text", 'web'::"text"])))
);


ALTER TABLE "inventario"."versiones_aplicacion" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "rutas"."abonos" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "ruta_id" "uuid" NOT NULL,
    "monto" numeric(10,2) NOT NULL,
    "fecha" timestamp with time zone DEFAULT "now"() NOT NULL,
    "nota" "text",
    CONSTRAINT "abonos_monto_check" CHECK (("monto" > (0)::numeric))
);


ALTER TABLE "rutas"."abonos" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "rutas"."items_ruta" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "ruta_id" "uuid" NOT NULL,
    "producto_id" "uuid" NOT NULL,
    "nombre_producto" "text" NOT NULL,
    "unidad" "text" DEFAULT 'unidad'::"text" NOT NULL,
    "precio_unitario" numeric(10,2) NOT NULL,
    "cantidad_salida" integer NOT NULL,
    "cantidad_sin_vender" integer,
    "cantidad_retorno_vacio" integer,
    CONSTRAINT "items_ruta_cantidad_retorno_vacio_check" CHECK ((("cantidad_retorno_vacio" IS NULL) OR ("cantidad_retorno_vacio" >= 0))),
    CONSTRAINT "items_ruta_cantidad_salida_check" CHECK (("cantidad_salida" > 0)),
    CONSTRAINT "items_ruta_cantidad_sin_vender_check" CHECK ((("cantidad_sin_vender" IS NULL) OR ("cantidad_sin_vender" >= 0))),
    CONSTRAINT "items_ruta_precio_unitario_check" CHECK (("precio_unitario" >= (0)::numeric))
);


ALTER TABLE "rutas"."items_ruta" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "rutas"."rutas" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "vendedor_id" "uuid" NOT NULL,
    "fecha" "date" DEFAULT CURRENT_DATE NOT NULL,
    "monto_total" numeric(10,2) DEFAULT 0 NOT NULL,
    "monto_cobrado" numeric(10,2) DEFAULT 0 NOT NULL,
    "estado" "text" DEFAULT 'sin_cierre'::"text" NOT NULL,
    "notas" "text",
    "bidones_llenos_iniciales" integer DEFAULT 0 NOT NULL,
    "bidones_vacios_iniciales" integer DEFAULT 0 NOT NULL,
    "bidones_cargados_hoy" integer DEFAULT 0 NOT NULL,
    "bidones_retorno_llenos" integer,
    "bidones_retorno_vacios" integer,
    "creado_en" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "rutas_bidones_cargados_hoy_check" CHECK (("bidones_cargados_hoy" >= 0)),
    CONSTRAINT "rutas_bidones_llenos_iniciales_check" CHECK (("bidones_llenos_iniciales" >= 0)),
    CONSTRAINT "rutas_bidones_retorno_llenos_check" CHECK ((("bidones_retorno_llenos" IS NULL) OR ("bidones_retorno_llenos" >= 0))),
    CONSTRAINT "rutas_bidones_retorno_vacios_check" CHECK ((("bidones_retorno_vacios" IS NULL) OR ("bidones_retorno_vacios" >= 0))),
    CONSTRAINT "rutas_bidones_vacios_iniciales_check" CHECK (("bidones_vacios_iniciales" >= 0)),
    CONSTRAINT "rutas_estado_check" CHECK (("estado" = ANY (ARRAY['sin_cierre'::"text", 'pendiente'::"text", 'parcial'::"text", 'pagado'::"text"]))),
    CONSTRAINT "rutas_monto_cobrado_check" CHECK (("monto_cobrado" >= (0)::numeric)),
    CONSTRAINT "rutas_monto_total_check" CHECK (("monto_total" >= (0)::numeric))
);


ALTER TABLE "rutas"."rutas" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "vendedores"."vendedores" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "nombre" "text" NOT NULL,
    "telefono" "text",
    "activo" boolean DEFAULT true NOT NULL,
    "bidones_propios" integer DEFAULT 0 NOT NULL,
    "bidones_prestados" integer DEFAULT 0 NOT NULL,
    "bidones_llenos_actuales" integer DEFAULT 0 NOT NULL,
    "bidones_vacios_actuales" integer DEFAULT 0 NOT NULL,
    "creado_en" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "vendedores_bidones_llenos_actuales_check" CHECK (("bidones_llenos_actuales" >= 0)),
    CONSTRAINT "vendedores_bidones_prestados_check" CHECK (("bidones_prestados" >= 0)),
    CONSTRAINT "vendedores_bidones_propios_check" CHECK (("bidones_propios" >= 0)),
    CONSTRAINT "vendedores_bidones_vacios_actuales_check" CHECK (("bidones_vacios_actuales" >= 0))
);


ALTER TABLE "vendedores"."vendedores" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "ventas"."ventas" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "fecha" "date" DEFAULT CURRENT_DATE NOT NULL,
    "total" numeric(10,2) DEFAULT 0 NOT NULL,
    "notas" "text",
    "vendedor_id" "uuid",
    "ruta_id" "uuid",
    "credito_aplicado" numeric(10,2) DEFAULT 0 NOT NULL,
    "bidones_llenos_en_carro" integer DEFAULT 0 NOT NULL,
    "bidones_vacios_recibidos" integer DEFAULT 0 NOT NULL,
    "bidones_prestados_empresa" integer DEFAULT 0 NOT NULL,
    "creado_en" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "ventas_bidones_llenos_en_carro_check" CHECK (("bidones_llenos_en_carro" >= 0)),
    CONSTRAINT "ventas_bidones_prestados_empresa_check" CHECK (("bidones_prestados_empresa" >= 0)),
    CONSTRAINT "ventas_bidones_vacios_recibidos_check" CHECK (("bidones_vacios_recibidos" >= 0)),
    CONSTRAINT "ventas_credito_aplicado_check" CHECK (("credito_aplicado" >= (0)::numeric)),
    CONSTRAINT "ventas_total_check" CHECK (("total" >= (0)::numeric))
);


ALTER TABLE "ventas"."ventas" OWNER TO "postgres";


CREATE OR REPLACE VIEW "rutas"."v_rutas" WITH ("security_invoker"='true') AS
 SELECT "r"."id",
    "r"."vendedor_id",
    "r"."fecha",
    "r"."monto_total",
    "r"."monto_cobrado",
    "r"."estado",
    "r"."notas",
    "r"."bidones_llenos_iniciales",
    "r"."bidones_vacios_iniciales",
    "r"."bidones_cargados_hoy",
    "r"."bidones_retorno_llenos",
    "r"."bidones_retorno_vacios",
    "r"."creado_en",
    "vd"."nombre" AS "nombre_vendedor",
    "vd"."bidones_propios" AS "vendedor_bidones_propios",
    "vd"."bidones_prestados" AS "vendedor_bidones_prestados",
    "vd"."bidones_llenos_actuales" AS "vendedor_bidones_llenos_actuales",
    "vd"."bidones_vacios_actuales" AS "vendedor_bidones_vacios_actuales",
    COALESCE(( SELECT "jsonb_agg"("jsonb_build_object"('id', "ir"."id", 'ruta_id', "ir"."ruta_id", 'producto_id', "ir"."producto_id", 'nombre_producto', COALESCE("p"."nombre", "ir"."nombre_producto"), 'unidad', COALESCE("p"."unidad", "ir"."unidad"), 'precio_unitario', "ir"."precio_unitario", 'cantidad_salida', "ir"."cantidad_salida", 'cantidad_sin_vender', "ir"."cantidad_sin_vender", 'cantidad_retorno_vacio', "ir"."cantidad_retorno_vacio") ORDER BY "ir"."id") AS "jsonb_agg"
           FROM ("rutas"."items_ruta" "ir"
             LEFT JOIN "inventario"."productos" "p" ON (("p"."id" = "ir"."producto_id")))
          WHERE ("ir"."ruta_id" = "r"."id")), '[]'::"jsonb") AS "items_json",
    COALESCE(( SELECT "jsonb_agg"("jsonb_build_object"('id', "vv"."id", 'fecha', "vv"."fecha", 'total', "vv"."total", 'notas', "vv"."notas", 'vendedor_id', "vv"."vendedor_id", 'ruta_id', "vv"."ruta_id", 'credito_aplicado', "vv"."credito_aplicado", 'bidones_llenos_en_carro', "vv"."bidones_llenos_en_carro", 'bidones_vacios_recibidos', "vv"."bidones_vacios_recibidos", 'bidones_prestados_empresa', "vv"."bidones_prestados_empresa", 'creado_en', "vv"."creado_en", 'nombre_vendedor', "vd"."nombre") ORDER BY "vv"."creado_en" DESC) AS "jsonb_agg"
           FROM "ventas"."ventas" "vv"
          WHERE ("vv"."ruta_id" = "r"."id")), '[]'::"jsonb") AS "ventas_json",
    COALESCE(( SELECT "jsonb_agg"("jsonb_build_object"('id', "a"."id", 'ruta_id', "a"."ruta_id", 'monto', "a"."monto", 'fecha', "a"."fecha", 'nota', "a"."nota") ORDER BY "a"."fecha" DESC) AS "jsonb_agg"
           FROM "rutas"."abonos" "a"
          WHERE ("a"."ruta_id" = "r"."id")), '[]'::"jsonb") AS "abonos_json"
   FROM ("rutas"."rutas" "r"
     LEFT JOIN "vendedores"."vendedores" "vd" ON (("vd"."id" = "r"."vendedor_id")));


ALTER VIEW "rutas"."v_rutas" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "usuarios"."sesiones_app" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "usuario_id" "uuid" NOT NULL,
    "token_hash" "text" NOT NULL,
    "expira_en" timestamp with time zone DEFAULT ("now"() + '7 days'::interval) NOT NULL,
    "revocada_en" timestamp with time zone,
    "creado_en" timestamp with time zone DEFAULT "now"() NOT NULL,
    "ultimo_acceso" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "usuarios"."sesiones_app" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "usuarios"."tokens_dispositivo" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "usuario_id" "uuid" NOT NULL,
    "token_firebase" "text" NOT NULL,
    "plataforma" "text" DEFAULT 'android'::"text" NOT NULL,
    "nombre_dispositivo" "text",
    "activo" boolean DEFAULT true NOT NULL,
    "creado_en" timestamp with time zone DEFAULT "now"() NOT NULL,
    "actualizado_en" timestamp with time zone DEFAULT "now"() NOT NULL,
    "ultimo_uso_en" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "usuarios"."tokens_dispositivo" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "usuarios"."usuarios" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "email_hash" "text" NOT NULL,
    "email_enc" "bytea" NOT NULL,
    "nombre" "text" NOT NULL,
    "hash_contrasena" "text" NOT NULL,
    "rol" "text" DEFAULT 'planta'::"text" NOT NULL,
    "activo" boolean DEFAULT true NOT NULL,
    "debe_cambiar_contrasena" boolean DEFAULT true NOT NULL,
    "vendedor_id" "uuid",
    "telefono_enc" "bytea",
    "url_avatar" "text",
    "creado_en" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "usuarios_rol_check" CHECK (("rol" = ANY (ARRAY['admin'::"text", 'planta'::"text", 'vendedor'::"text"])))
);


ALTER TABLE "usuarios"."usuarios" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "ventas"."items_venta" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "venta_id" "uuid" NOT NULL,
    "producto_id" "uuid" NOT NULL,
    "cantidad" integer NOT NULL,
    "precio_unitario" numeric(10,2) NOT NULL,
    "subtotal" numeric(10,2) NOT NULL,
    CONSTRAINT "items_venta_cantidad_check" CHECK (("cantidad" > 0)),
    CONSTRAINT "items_venta_precio_unitario_check" CHECK (("precio_unitario" >= (0)::numeric)),
    CONSTRAINT "items_venta_subtotal_check" CHECK (("subtotal" >= (0)::numeric))
);


ALTER TABLE "ventas"."items_venta" OWNER TO "postgres";


CREATE OR REPLACE VIEW "ventas"."v_ventas" WITH ("security_invoker"='true') AS
 SELECT "v"."id",
    "v"."fecha",
    "v"."total",
    "v"."notas",
    "v"."vendedor_id",
    "v"."ruta_id",
    "v"."credito_aplicado",
    "v"."bidones_llenos_en_carro",
    "v"."bidones_vacios_recibidos",
    "v"."bidones_prestados_empresa",
    "v"."creado_en",
    "vd"."nombre" AS "nombre_vendedor",
    COALESCE(( SELECT "jsonb_agg"("jsonb_build_object"('id', "iv"."id", 'venta_id', "iv"."venta_id", 'producto_id', "iv"."producto_id", 'nombre_producto', "p"."nombre", 'cantidad', "iv"."cantidad", 'precio_unitario', "iv"."precio_unitario", 'subtotal', "iv"."subtotal") ORDER BY "iv"."id") AS "jsonb_agg"
           FROM ("ventas"."items_venta" "iv"
             LEFT JOIN "inventario"."productos" "p" ON (("p"."id" = "iv"."producto_id")))
          WHERE ("iv"."venta_id" = "v"."id")), '[]'::"jsonb") AS "items_json"
   FROM ("ventas"."ventas" "v"
     LEFT JOIN "vendedores"."vendedores" "vd" ON (("vd"."id" = "v"."vendedor_id")));


ALTER VIEW "ventas"."v_ventas" OWNER TO "postgres";


ALTER TABLE ONLY "auditoria"."log_auditoria"
    ADD CONSTRAINT "log_auditoria_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "auditoria"."log_error"
    ADD CONSTRAINT "log_error_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "configuracion"."versiones_aplicacion"
    ADD CONSTRAINT "versiones_aplicacion_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "configuracion"."versiones_aplicacion"
    ADD CONSTRAINT "versiones_aplicacion_plataforma_key" UNIQUE ("plataforma");



ALTER TABLE ONLY "inventario"."alertas"
    ADD CONSTRAINT "alertas_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "inventario"."configuracion_app"
    ADD CONSTRAINT "configuracion_app_pkey" PRIMARY KEY ("clave");



ALTER TABLE ONLY "inventario"."movimientos_inventario"
    ADD CONSTRAINT "movimientos_inventario_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "inventario"."predicciones_modelo_alertas"
    ADD CONSTRAINT "predicciones_modelo_alertas_pkey" PRIMARY KEY ("clave");



ALTER TABLE ONLY "inventario"."productos"
    ADD CONSTRAINT "productos_nombre_catalogo_key" UNIQUE ("nombre", "catalogo");



ALTER TABLE ONLY "inventario"."productos"
    ADD CONSTRAINT "productos_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "inventario"."versiones_aplicacion"
    ADD CONSTRAINT "versiones_aplicacion_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "inventario"."versiones_aplicacion"
    ADD CONSTRAINT "versiones_aplicacion_plataforma_key" UNIQUE ("plataforma");



ALTER TABLE ONLY "rutas"."abonos"
    ADD CONSTRAINT "abonos_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "rutas"."items_ruta"
    ADD CONSTRAINT "items_ruta_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "rutas"."rutas"
    ADD CONSTRAINT "rutas_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "usuarios"."sesiones_app"
    ADD CONSTRAINT "sesiones_app_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "usuarios"."sesiones_app"
    ADD CONSTRAINT "sesiones_app_token_hash_key" UNIQUE ("token_hash");



ALTER TABLE ONLY "usuarios"."tokens_dispositivo"
    ADD CONSTRAINT "tokens_dispositivo_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "usuarios"."tokens_dispositivo"
    ADD CONSTRAINT "tokens_dispositivo_token_firebase_key" UNIQUE ("token_firebase");



ALTER TABLE ONLY "usuarios"."usuarios"
    ADD CONSTRAINT "usuarios_email_hash_key" UNIQUE ("email_hash");



ALTER TABLE ONLY "usuarios"."usuarios"
    ADD CONSTRAINT "usuarios_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "vendedores"."vendedores"
    ADD CONSTRAINT "vendedores_nombre_key" UNIQUE ("nombre");



ALTER TABLE ONLY "vendedores"."vendedores"
    ADD CONSTRAINT "vendedores_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "ventas"."items_venta"
    ADD CONSTRAINT "items_venta_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "ventas"."ventas"
    ADD CONSTRAINT "ventas_pkey" PRIMARY KEY ("id");



CREATE INDEX "idx_log_auditoria_creado" ON "auditoria"."log_auditoria" USING "btree" ("creado_en" DESC);



CREATE INDEX "idx_log_auditoria_tabla" ON "auditoria"."log_auditoria" USING "btree" ("tabla");



CREATE INDEX "idx_log_auditoria_usuario" ON "auditoria"."log_auditoria" USING "btree" ("usuario_id");



CREATE INDEX "idx_log_error_creado" ON "auditoria"."log_error" USING "btree" ("creado_en" DESC);



CREATE INDEX "idx_log_error_nivel" ON "auditoria"."log_error" USING "btree" ("nivel");



CREATE INDEX "idx_alertas_leida" ON "inventario"."alertas" USING "btree" ("leida");



CREATE INDEX "idx_alertas_producto" ON "inventario"."alertas" USING "btree" ("producto_id");



CREATE INDEX "idx_movimientos_creado" ON "inventario"."movimientos_inventario" USING "btree" ("creado_en" DESC);



CREATE INDEX "idx_movimientos_producto" ON "inventario"."movimientos_inventario" USING "btree" ("producto_id");



CREATE INDEX "idx_predicciones_modelo_actualizado" ON "inventario"."predicciones_modelo_alertas" USING "btree" ("actualizado_en" DESC);



CREATE INDEX "idx_predicciones_modelo_tipo_fecha" ON "inventario"."predicciones_modelo_alertas" USING "btree" ("tipo", "fecha_objetivo");



CREATE INDEX "idx_productos_catalogo" ON "inventario"."productos" USING "btree" ("catalogo");



CREATE INDEX "idx_productos_nombre" ON "inventario"."productos" USING "btree" ("nombre");



CREATE INDEX "idx_abonos_fecha" ON "rutas"."abonos" USING "btree" ("fecha" DESC);



CREATE INDEX "idx_abonos_ruta" ON "rutas"."abonos" USING "btree" ("ruta_id");



CREATE INDEX "idx_items_ruta_producto" ON "rutas"."items_ruta" USING "btree" ("producto_id");



CREATE INDEX "idx_items_ruta_ruta" ON "rutas"."items_ruta" USING "btree" ("ruta_id");



CREATE INDEX "idx_rutas_creado" ON "rutas"."rutas" USING "btree" ("creado_en" DESC);



CREATE INDEX "idx_rutas_estado" ON "rutas"."rutas" USING "btree" ("estado");



CREATE INDEX "idx_rutas_fecha" ON "rutas"."rutas" USING "btree" ("fecha" DESC);



CREATE UNIQUE INDEX "idx_rutas_unica_abierta_vendedor_fecha" ON "rutas"."rutas" USING "btree" ("vendedor_id", "fecha") WHERE ("estado" = ANY (ARRAY['sin_cierre'::"text", 'pendiente'::"text", 'parcial'::"text"]));



CREATE INDEX "idx_rutas_vendedor" ON "rutas"."rutas" USING "btree" ("vendedor_id");



CREATE INDEX "idx_sesiones_expira" ON "usuarios"."sesiones_app" USING "btree" ("expira_en");



CREATE INDEX "idx_sesiones_usuario" ON "usuarios"."sesiones_app" USING "btree" ("usuario_id");



CREATE INDEX "idx_tokens_dispositivo_activo" ON "usuarios"."tokens_dispositivo" USING "btree" ("activo");



CREATE INDEX "idx_tokens_dispositivo_usuario" ON "usuarios"."tokens_dispositivo" USING "btree" ("usuario_id");



CREATE INDEX "idx_usuarios_activo" ON "usuarios"."usuarios" USING "btree" ("activo");



CREATE INDEX "idx_usuarios_rol" ON "usuarios"."usuarios" USING "btree" ("rol");



CREATE INDEX "idx_usuarios_vendedor" ON "usuarios"."usuarios" USING "btree" ("vendedor_id");



CREATE INDEX "idx_vendedores_activo" ON "vendedores"."vendedores" USING "btree" ("activo");



CREATE INDEX "idx_vendedores_nombre" ON "vendedores"."vendedores" USING "btree" ("nombre");



CREATE INDEX "idx_items_venta_producto" ON "ventas"."items_venta" USING "btree" ("producto_id");



CREATE INDEX "idx_items_venta_venta" ON "ventas"."items_venta" USING "btree" ("venta_id");



CREATE INDEX "idx_ventas_creado" ON "ventas"."ventas" USING "btree" ("creado_en" DESC);



CREATE INDEX "idx_ventas_fecha" ON "ventas"."ventas" USING "btree" ("fecha" DESC);



CREATE INDEX "idx_ventas_ruta" ON "ventas"."ventas" USING "btree" ("ruta_id");



CREATE INDEX "idx_ventas_vendedor" ON "ventas"."ventas" USING "btree" ("vendedor_id");



CREATE OR REPLACE TRIGGER "trg_actualizar_stock_bajo_calculado" BEFORE INSERT OR UPDATE OF "stock", "stock_minimo", "stock_bajo_calculado" ON "inventario"."productos" FOR EACH ROW EXECUTE FUNCTION "inventario"."fn_actualizar_stock_bajo_calculado"();



CREATE OR REPLACE TRIGGER "trg_audit_alertas" AFTER INSERT OR DELETE OR UPDATE ON "inventario"."alertas" FOR EACH ROW EXECUTE FUNCTION "auditoria"."fn_trigger_auditoria"();



CREATE OR REPLACE TRIGGER "trg_audit_movimientos" AFTER INSERT OR DELETE OR UPDATE ON "inventario"."movimientos_inventario" FOR EACH ROW EXECUTE FUNCTION "auditoria"."fn_trigger_auditoria"();



CREATE OR REPLACE TRIGGER "trg_audit_productos" AFTER INSERT OR DELETE OR UPDATE ON "inventario"."productos" FOR EACH ROW EXECUTE FUNCTION "auditoria"."fn_trigger_auditoria"();



CREATE OR REPLACE TRIGGER "trg_configuracion_actualizado_en" BEFORE UPDATE ON "inventario"."configuracion_app" FOR EACH ROW EXECUTE FUNCTION "inventario"."fn_actualizar_actualizado_en"();



CREATE OR REPLACE TRIGGER "trg_productos_actualizado_en" BEFORE UPDATE ON "inventario"."productos" FOR EACH ROW EXECUTE FUNCTION "inventario"."fn_actualizar_actualizado_en"();



CREATE OR REPLACE TRIGGER "trg_versiones_aplicacion_actualizado_en" BEFORE UPDATE ON "inventario"."versiones_aplicacion" FOR EACH ROW EXECUTE FUNCTION "inventario"."fn_actualizar_actualizado_en"();



CREATE OR REPLACE TRIGGER "trg_audit_abonos" AFTER INSERT OR DELETE OR UPDATE ON "rutas"."abonos" FOR EACH ROW EXECUTE FUNCTION "auditoria"."fn_trigger_auditoria"();



CREATE OR REPLACE TRIGGER "trg_audit_items_ruta" AFTER INSERT OR DELETE OR UPDATE ON "rutas"."items_ruta" FOR EACH ROW EXECUTE FUNCTION "auditoria"."fn_trigger_auditoria"();



CREATE OR REPLACE TRIGGER "trg_audit_rutas" AFTER INSERT OR DELETE OR UPDATE ON "rutas"."rutas" FOR EACH ROW EXECUTE FUNCTION "auditoria"."fn_trigger_auditoria"();



CREATE OR REPLACE TRIGGER "trg_audit_vendedores" AFTER INSERT OR DELETE OR UPDATE ON "vendedores"."vendedores" FOR EACH ROW EXECUTE FUNCTION "auditoria"."fn_trigger_auditoria"();



CREATE OR REPLACE TRIGGER "trg_audit_items_venta" AFTER INSERT OR DELETE OR UPDATE ON "ventas"."items_venta" FOR EACH ROW EXECUTE FUNCTION "auditoria"."fn_trigger_auditoria"();



CREATE OR REPLACE TRIGGER "trg_audit_ventas" AFTER INSERT OR DELETE OR UPDATE ON "ventas"."ventas" FOR EACH ROW EXECUTE FUNCTION "auditoria"."fn_trigger_auditoria"();



ALTER TABLE ONLY "inventario"."alertas"
    ADD CONSTRAINT "alertas_producto_id_fkey" FOREIGN KEY ("producto_id") REFERENCES "inventario"."productos"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "inventario"."movimientos_inventario"
    ADD CONSTRAINT "movimientos_inventario_producto_id_fkey" FOREIGN KEY ("producto_id") REFERENCES "inventario"."productos"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "rutas"."abonos"
    ADD CONSTRAINT "abonos_ruta_id_fkey" FOREIGN KEY ("ruta_id") REFERENCES "rutas"."rutas"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "rutas"."items_ruta"
    ADD CONSTRAINT "items_ruta_producto_id_fkey" FOREIGN KEY ("producto_id") REFERENCES "inventario"."productos"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "rutas"."items_ruta"
    ADD CONSTRAINT "items_ruta_ruta_id_fkey" FOREIGN KEY ("ruta_id") REFERENCES "rutas"."rutas"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "rutas"."rutas"
    ADD CONSTRAINT "rutas_vendedor_id_fkey" FOREIGN KEY ("vendedor_id") REFERENCES "vendedores"."vendedores"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "usuarios"."sesiones_app"
    ADD CONSTRAINT "sesiones_app_usuario_id_fkey" FOREIGN KEY ("usuario_id") REFERENCES "usuarios"."usuarios"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "usuarios"."tokens_dispositivo"
    ADD CONSTRAINT "tokens_dispositivo_usuario_id_fkey" FOREIGN KEY ("usuario_id") REFERENCES "usuarios"."usuarios"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "usuarios"."usuarios"
    ADD CONSTRAINT "usuarios_vendedor_id_fkey" FOREIGN KEY ("vendedor_id") REFERENCES "vendedores"."vendedores"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "ventas"."items_venta"
    ADD CONSTRAINT "items_venta_producto_id_fkey" FOREIGN KEY ("producto_id") REFERENCES "inventario"."productos"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "ventas"."items_venta"
    ADD CONSTRAINT "items_venta_venta_id_fkey" FOREIGN KEY ("venta_id") REFERENCES "ventas"."ventas"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "ventas"."ventas"
    ADD CONSTRAINT "ventas_ruta_id_fkey" FOREIGN KEY ("ruta_id") REFERENCES "rutas"."rutas"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "ventas"."ventas"
    ADD CONSTRAINT "ventas_vendedor_id_fkey" FOREIGN KEY ("vendedor_id") REFERENCES "vendedores"."vendedores"("id") ON DELETE SET NULL;



CREATE POLICY "app_delete" ON "auditoria"."log_auditoria" FOR DELETE TO "authenticated", "anon" USING ("usuarios"."fn_sesion_header_tiene_rol"(ARRAY['admin'::"text"]));



CREATE POLICY "app_insert" ON "auditoria"."log_auditoria" FOR INSERT TO "authenticated", "anon" WITH CHECK ("usuarios"."fn_sesion_header_tiene_rol"(ARRAY['admin'::"text", 'planta'::"text"]));



CREATE POLICY "app_select" ON "auditoria"."log_auditoria" FOR SELECT TO "authenticated", "anon" USING ("usuarios"."fn_sesion_header_valida"());



CREATE POLICY "app_update" ON "auditoria"."log_auditoria" FOR UPDATE TO "authenticated", "anon" USING ("usuarios"."fn_sesion_header_tiene_rol"(ARRAY['admin'::"text", 'planta'::"text"])) WITH CHECK ("usuarios"."fn_sesion_header_tiene_rol"(ARRAY['admin'::"text", 'planta'::"text"]));



ALTER TABLE "auditoria"."log_auditoria" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "auditoria"."log_error" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "configuracion"."versiones_aplicacion" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "inventario"."alertas" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "app_delete" ON "inventario"."alertas" FOR DELETE TO "authenticated", "anon" USING ("usuarios"."fn_sesion_header_tiene_rol"(ARRAY['admin'::"text"]));



CREATE POLICY "app_delete" ON "inventario"."configuracion_app" FOR DELETE TO "authenticated", "anon" USING ("usuarios"."fn_sesion_header_tiene_rol"(ARRAY['admin'::"text"]));



CREATE POLICY "app_delete" ON "inventario"."movimientos_inventario" FOR DELETE TO "authenticated", "anon" USING ("usuarios"."fn_sesion_header_tiene_rol"(ARRAY['admin'::"text"]));



CREATE POLICY "app_delete" ON "inventario"."predicciones_modelo_alertas" FOR DELETE TO "authenticated", "anon" USING ("usuarios"."fn_sesion_header_tiene_rol"(ARRAY['admin'::"text"]));



CREATE POLICY "app_delete" ON "inventario"."productos" FOR DELETE TO "authenticated", "anon" USING ("usuarios"."fn_sesion_header_tiene_rol"(ARRAY['admin'::"text"]));



CREATE POLICY "app_insert" ON "inventario"."alertas" FOR INSERT TO "authenticated", "anon" WITH CHECK ("usuarios"."fn_sesion_header_tiene_rol"(ARRAY['admin'::"text", 'planta'::"text"]));



CREATE POLICY "app_insert" ON "inventario"."configuracion_app" FOR INSERT TO "authenticated", "anon" WITH CHECK ("usuarios"."fn_sesion_header_tiene_rol"(ARRAY['admin'::"text", 'planta'::"text"]));



CREATE POLICY "app_insert" ON "inventario"."movimientos_inventario" FOR INSERT TO "authenticated", "anon" WITH CHECK ("usuarios"."fn_sesion_header_tiene_rol"(ARRAY['admin'::"text", 'planta'::"text"]));



CREATE POLICY "app_insert" ON "inventario"."predicciones_modelo_alertas" FOR INSERT TO "authenticated", "anon" WITH CHECK ("usuarios"."fn_sesion_header_tiene_rol"(ARRAY['admin'::"text", 'planta'::"text"]));



CREATE POLICY "app_insert" ON "inventario"."productos" FOR INSERT TO "authenticated", "anon" WITH CHECK ("usuarios"."fn_sesion_header_tiene_rol"(ARRAY['admin'::"text", 'planta'::"text"]));



CREATE POLICY "app_select" ON "inventario"."alertas" FOR SELECT TO "authenticated", "anon" USING ("usuarios"."fn_sesion_header_valida"());



CREATE POLICY "app_select" ON "inventario"."configuracion_app" FOR SELECT TO "authenticated", "anon" USING ("usuarios"."fn_sesion_header_valida"());



CREATE POLICY "app_select" ON "inventario"."movimientos_inventario" FOR SELECT TO "authenticated", "anon" USING ("usuarios"."fn_sesion_header_valida"());



CREATE POLICY "app_select" ON "inventario"."predicciones_modelo_alertas" FOR SELECT TO "authenticated", "anon" USING ("usuarios"."fn_sesion_header_valida"());



CREATE POLICY "app_select" ON "inventario"."productos" FOR SELECT TO "authenticated", "anon" USING ("usuarios"."fn_sesion_header_valida"());



CREATE POLICY "app_update" ON "inventario"."alertas" FOR UPDATE TO "authenticated", "anon" USING ("usuarios"."fn_sesion_header_tiene_rol"(ARRAY['admin'::"text", 'planta'::"text"])) WITH CHECK ("usuarios"."fn_sesion_header_tiene_rol"(ARRAY['admin'::"text", 'planta'::"text"]));



CREATE POLICY "app_update" ON "inventario"."configuracion_app" FOR UPDATE TO "authenticated", "anon" USING ("usuarios"."fn_sesion_header_tiene_rol"(ARRAY['admin'::"text", 'planta'::"text"])) WITH CHECK ("usuarios"."fn_sesion_header_tiene_rol"(ARRAY['admin'::"text", 'planta'::"text"]));



CREATE POLICY "app_update" ON "inventario"."movimientos_inventario" FOR UPDATE TO "authenticated", "anon" USING ("usuarios"."fn_sesion_header_tiene_rol"(ARRAY['admin'::"text", 'planta'::"text"])) WITH CHECK ("usuarios"."fn_sesion_header_tiene_rol"(ARRAY['admin'::"text", 'planta'::"text"]));



CREATE POLICY "app_update" ON "inventario"."predicciones_modelo_alertas" FOR UPDATE TO "authenticated", "anon" USING ("usuarios"."fn_sesion_header_tiene_rol"(ARRAY['admin'::"text", 'planta'::"text"])) WITH CHECK ("usuarios"."fn_sesion_header_tiene_rol"(ARRAY['admin'::"text", 'planta'::"text"]));



CREATE POLICY "app_update" ON "inventario"."productos" FOR UPDATE TO "authenticated", "anon" USING ("usuarios"."fn_sesion_header_tiene_rol"(ARRAY['admin'::"text", 'planta'::"text"])) WITH CHECK ("usuarios"."fn_sesion_header_tiene_rol"(ARRAY['admin'::"text", 'planta'::"text"]));



ALTER TABLE "inventario"."configuracion_app" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "inventario"."movimientos_inventario" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "inventario"."predicciones_modelo_alertas" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "inventario"."productos" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "inventario"."versiones_aplicacion" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "versiones_aplicacion_lectura_publica" ON "inventario"."versiones_aplicacion" FOR SELECT USING (true);



ALTER TABLE "rutas"."abonos" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "app_delete" ON "rutas"."abonos" FOR DELETE TO "authenticated", "anon" USING ("usuarios"."fn_sesion_header_tiene_rol"(ARRAY['admin'::"text"]));



CREATE POLICY "app_delete" ON "rutas"."items_ruta" FOR DELETE TO "authenticated", "anon" USING ("usuarios"."fn_sesion_header_tiene_rol"(ARRAY['admin'::"text"]));



CREATE POLICY "app_delete" ON "rutas"."rutas" FOR DELETE TO "authenticated", "anon" USING ("usuarios"."fn_sesion_header_tiene_rol"(ARRAY['admin'::"text"]));



CREATE POLICY "app_insert" ON "rutas"."abonos" FOR INSERT TO "authenticated", "anon" WITH CHECK ("usuarios"."fn_sesion_header_tiene_rol"(ARRAY['admin'::"text", 'planta'::"text"]));



CREATE POLICY "app_insert" ON "rutas"."items_ruta" FOR INSERT TO "authenticated", "anon" WITH CHECK ("usuarios"."fn_sesion_header_tiene_rol"(ARRAY['admin'::"text", 'planta'::"text"]));



CREATE POLICY "app_insert" ON "rutas"."rutas" FOR INSERT TO "authenticated", "anon" WITH CHECK ("usuarios"."fn_sesion_header_tiene_rol"(ARRAY['admin'::"text", 'planta'::"text"]));



CREATE POLICY "app_select" ON "rutas"."abonos" FOR SELECT TO "authenticated", "anon" USING ("usuarios"."fn_sesion_header_valida"());



CREATE POLICY "app_select" ON "rutas"."items_ruta" FOR SELECT TO "authenticated", "anon" USING ("usuarios"."fn_sesion_header_valida"());



CREATE POLICY "app_select" ON "rutas"."rutas" FOR SELECT TO "authenticated", "anon" USING ("usuarios"."fn_sesion_header_valida"());



CREATE POLICY "app_update" ON "rutas"."abonos" FOR UPDATE TO "authenticated", "anon" USING ("usuarios"."fn_sesion_header_tiene_rol"(ARRAY['admin'::"text", 'planta'::"text"])) WITH CHECK ("usuarios"."fn_sesion_header_tiene_rol"(ARRAY['admin'::"text", 'planta'::"text"]));



CREATE POLICY "app_update" ON "rutas"."items_ruta" FOR UPDATE TO "authenticated", "anon" USING ("usuarios"."fn_sesion_header_tiene_rol"(ARRAY['admin'::"text", 'planta'::"text"])) WITH CHECK ("usuarios"."fn_sesion_header_tiene_rol"(ARRAY['admin'::"text", 'planta'::"text"]));



CREATE POLICY "app_update" ON "rutas"."rutas" FOR UPDATE TO "authenticated", "anon" USING ("usuarios"."fn_sesion_header_tiene_rol"(ARRAY['admin'::"text", 'planta'::"text"])) WITH CHECK ("usuarios"."fn_sesion_header_tiene_rol"(ARRAY['admin'::"text", 'planta'::"text"]));



ALTER TABLE "rutas"."items_ruta" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "rutas"."rutas" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "usuarios"."sesiones_app" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "usuarios"."tokens_dispositivo" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "usuarios"."usuarios" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "app_delete" ON "vendedores"."vendedores" FOR DELETE TO "authenticated", "anon" USING ("usuarios"."fn_sesion_header_tiene_rol"(ARRAY['admin'::"text"]));



CREATE POLICY "app_insert" ON "vendedores"."vendedores" FOR INSERT TO "authenticated", "anon" WITH CHECK ("usuarios"."fn_sesion_header_tiene_rol"(ARRAY['admin'::"text", 'planta'::"text"]));



CREATE POLICY "app_select" ON "vendedores"."vendedores" FOR SELECT TO "authenticated", "anon" USING ("usuarios"."fn_sesion_header_valida"());



CREATE POLICY "app_update" ON "vendedores"."vendedores" FOR UPDATE TO "authenticated", "anon" USING ("usuarios"."fn_sesion_header_tiene_rol"(ARRAY['admin'::"text", 'planta'::"text"])) WITH CHECK ("usuarios"."fn_sesion_header_tiene_rol"(ARRAY['admin'::"text", 'planta'::"text"]));



ALTER TABLE "vendedores"."vendedores" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "app_delete" ON "ventas"."items_venta" FOR DELETE TO "authenticated", "anon" USING ("usuarios"."fn_sesion_header_tiene_rol"(ARRAY['admin'::"text"]));



CREATE POLICY "app_delete" ON "ventas"."ventas" FOR DELETE TO "authenticated", "anon" USING ("usuarios"."fn_sesion_header_tiene_rol"(ARRAY['admin'::"text"]));



CREATE POLICY "app_insert" ON "ventas"."items_venta" FOR INSERT TO "authenticated", "anon" WITH CHECK ("usuarios"."fn_sesion_header_tiene_rol"(ARRAY['admin'::"text", 'planta'::"text"]));



CREATE POLICY "app_insert" ON "ventas"."ventas" FOR INSERT TO "authenticated", "anon" WITH CHECK ("usuarios"."fn_sesion_header_tiene_rol"(ARRAY['admin'::"text", 'planta'::"text"]));



CREATE POLICY "app_select" ON "ventas"."items_venta" FOR SELECT TO "authenticated", "anon" USING ("usuarios"."fn_sesion_header_valida"());



CREATE POLICY "app_select" ON "ventas"."ventas" FOR SELECT TO "authenticated", "anon" USING ("usuarios"."fn_sesion_header_valida"());



CREATE POLICY "app_update" ON "ventas"."items_venta" FOR UPDATE TO "authenticated", "anon" USING ("usuarios"."fn_sesion_header_tiene_rol"(ARRAY['admin'::"text", 'planta'::"text"])) WITH CHECK ("usuarios"."fn_sesion_header_tiene_rol"(ARRAY['admin'::"text", 'planta'::"text"]));



CREATE POLICY "app_update" ON "ventas"."ventas" FOR UPDATE TO "authenticated", "anon" USING ("usuarios"."fn_sesion_header_tiene_rol"(ARRAY['admin'::"text", 'planta'::"text"])) WITH CHECK ("usuarios"."fn_sesion_header_tiene_rol"(ARRAY['admin'::"text", 'planta'::"text"]));



ALTER TABLE "ventas"."items_venta" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "ventas"."ventas" ENABLE ROW LEVEL SECURITY;




ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";


GRANT USAGE ON SCHEMA "auditoria" TO "anon";
GRANT USAGE ON SCHEMA "auditoria" TO "authenticated";
GRANT USAGE ON SCHEMA "auditoria" TO "service_role";






GRANT USAGE ON SCHEMA "inventario" TO "anon";
GRANT USAGE ON SCHEMA "inventario" TO "authenticated";
GRANT USAGE ON SCHEMA "inventario" TO "service_role";






GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";



GRANT USAGE ON SCHEMA "rutas" TO "anon";
GRANT USAGE ON SCHEMA "rutas" TO "authenticated";
GRANT USAGE ON SCHEMA "rutas" TO "service_role";



GRANT USAGE ON SCHEMA "usuarios" TO "anon";
GRANT USAGE ON SCHEMA "usuarios" TO "authenticated";
GRANT USAGE ON SCHEMA "usuarios" TO "service_role";



GRANT USAGE ON SCHEMA "vendedores" TO "anon";
GRANT USAGE ON SCHEMA "vendedores" TO "authenticated";
GRANT USAGE ON SCHEMA "vendedores" TO "service_role";



GRANT USAGE ON SCHEMA "ventas" TO "anon";
GRANT USAGE ON SCHEMA "ventas" TO "authenticated";
GRANT USAGE ON SCHEMA "ventas" TO "service_role";



GRANT ALL ON FUNCTION "auditoria"."fn_log_error_secure"("p_session_token" "text", "p_nivel" "text", "p_mensaje" "text", "p_stack_trace" "text", "p_pantalla" "text", "p_endpoint" "text", "p_dispositivo" "text", "p_os_version" "text", "p_app_version" "text", "p_metadata" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "auditoria"."fn_log_error_secure"("p_session_token" "text", "p_nivel" "text", "p_mensaje" "text", "p_stack_trace" "text", "p_pantalla" "text", "p_endpoint" "text", "p_dispositivo" "text", "p_os_version" "text", "p_app_version" "text", "p_metadata" "jsonb") TO "authenticated";











































































































































































GRANT ALL ON FUNCTION "inventario"."fn_registrar_movimiento_seguro"("p_session_token" "text", "p_producto_id" "uuid", "p_tipo" "text", "p_cantidad" integer, "p_motivo" "text") TO "anon";
GRANT ALL ON FUNCTION "inventario"."fn_registrar_movimiento_seguro"("p_session_token" "text", "p_producto_id" "uuid", "p_tipo" "text", "p_cantidad" integer, "p_motivo" "text") TO "authenticated";



GRANT ALL ON FUNCTION "public"."rls_auto_enable"() TO "anon";
GRANT ALL ON FUNCTION "public"."rls_auto_enable"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."rls_auto_enable"() TO "service_role";



GRANT ALL ON FUNCTION "usuarios"."fn_change_my_password_hash"("p_session_token" "text", "p_password_hash" "text") TO "anon";
GRANT ALL ON FUNCTION "usuarios"."fn_change_my_password_hash"("p_session_token" "text", "p_password_hash" "text") TO "authenticated";



GRANT ALL ON FUNCTION "usuarios"."fn_contexto_sesion"("p_session_token" "text") TO "anon";
GRANT ALL ON FUNCTION "usuarios"."fn_contexto_sesion"("p_session_token" "text") TO "authenticated";



GRANT ALL ON FUNCTION "usuarios"."fn_delete_user"("p_session_token" "text", "p_target_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "usuarios"."fn_delete_user"("p_session_token" "text", "p_target_user_id" "uuid") TO "authenticated";



GRANT ALL ON FUNCTION "usuarios"."fn_desactivar_token_dispositivo"("p_session_token" "text", "p_token_firebase" "text") TO "anon";
GRANT ALL ON FUNCTION "usuarios"."fn_desactivar_token_dispositivo"("p_session_token" "text", "p_token_firebase" "text") TO "authenticated";



GRANT ALL ON FUNCTION "usuarios"."fn_list_users"("p_session_token" "text") TO "anon";
GRANT ALL ON FUNCTION "usuarios"."fn_list_users"("p_session_token" "text") TO "authenticated";



GRANT ALL ON FUNCTION "usuarios"."fn_login"("p_email" "text", "p_password" "text") TO "anon";
GRANT ALL ON FUNCTION "usuarios"."fn_login"("p_email" "text", "p_password" "text") TO "authenticated";



GRANT ALL ON FUNCTION "usuarios"."fn_logout"("p_session_token" "text") TO "anon";
GRANT ALL ON FUNCTION "usuarios"."fn_logout"("p_session_token" "text") TO "authenticated";



GRANT ALL ON FUNCTION "usuarios"."fn_registrar_token_dispositivo"("p_session_token" "text", "p_token_firebase" "text", "p_plataforma" "text", "p_nombre_dispositivo" "text") TO "anon";
GRANT ALL ON FUNCTION "usuarios"."fn_registrar_token_dispositivo"("p_session_token" "text", "p_token_firebase" "text", "p_plataforma" "text", "p_nombre_dispositivo" "text") TO "authenticated";



GRANT ALL ON FUNCTION "usuarios"."fn_rol_sesion_header"() TO "anon";
GRANT ALL ON FUNCTION "usuarios"."fn_rol_sesion_header"() TO "authenticated";



GRANT ALL ON FUNCTION "usuarios"."fn_sesion_header_tiene_rol"("p_roles" "text"[]) TO "anon";
GRANT ALL ON FUNCTION "usuarios"."fn_sesion_header_tiene_rol"("p_roles" "text"[]) TO "authenticated";



GRANT ALL ON FUNCTION "usuarios"."fn_sesion_header_valida"() TO "anon";
GRANT ALL ON FUNCTION "usuarios"."fn_sesion_header_valida"() TO "authenticated";



GRANT ALL ON FUNCTION "usuarios"."fn_session_token_header"() TO "anon";
GRANT ALL ON FUNCTION "usuarios"."fn_session_token_header"() TO "authenticated";



GRANT ALL ON FUNCTION "usuarios"."fn_tokens_notificacion"("p_rol" "text", "p_usuario_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "usuarios"."fn_upsert_user"("p_session_token" "text", "p_target_user_id" "uuid", "p_email" "text", "p_name" "text", "p_password_hash" "text", "p_role" "text", "p_active" boolean, "p_seller_id" "uuid", "p_must_change_password" boolean, "p_phone" "text", "p_avatar_url" "text") TO "anon";
GRANT ALL ON FUNCTION "usuarios"."fn_upsert_user"("p_session_token" "text", "p_target_user_id" "uuid", "p_email" "text", "p_name" "text", "p_password_hash" "text", "p_role" "text", "p_active" boolean, "p_seller_id" "uuid", "p_must_change_password" boolean, "p_phone" "text", "p_avatar_url" "text") TO "authenticated";



GRANT ALL ON FUNCTION "usuarios"."fn_usuario_sesion"("p_session_token" "text") TO "anon";
GRANT ALL ON FUNCTION "usuarios"."fn_usuario_sesion"("p_session_token" "text") TO "authenticated";



GRANT ALL ON FUNCTION "usuarios"."fn_validate_session"("p_session_token" "text") TO "anon";
GRANT ALL ON FUNCTION "usuarios"."fn_validate_session"("p_session_token" "text") TO "authenticated";












GRANT ALL ON FUNCTION "ventas"."fn_crear_venta_segura"("p_session_token" "text", "p_items" "jsonb", "p_notas" "text", "p_vendedor_id" "uuid", "p_bidones_llenos_en_carro" integer, "p_bidones_vacios_recibidos" integer) TO "anon";
GRANT ALL ON FUNCTION "ventas"."fn_crear_venta_segura"("p_session_token" "text", "p_items" "jsonb", "p_notas" "text", "p_vendedor_id" "uuid", "p_bidones_llenos_en_carro" integer, "p_bidones_vacios_recibidos" integer) TO "authenticated";



GRANT ALL ON FUNCTION "ventas"."fn_crear_venta_segura"("p_session_token" "text", "p_items" "jsonb", "p_notas" "text", "p_vendedor_id" "uuid", "p_fecha" "date", "p_bidones_llenos_en_carro" integer, "p_bidones_vacios_recibidos" integer) TO "anon";
GRANT ALL ON FUNCTION "ventas"."fn_crear_venta_segura"("p_session_token" "text", "p_items" "jsonb", "p_notas" "text", "p_vendedor_id" "uuid", "p_fecha" "date", "p_bidones_llenos_en_carro" integer, "p_bidones_vacios_recibidos" integer) TO "authenticated";



GRANT ALL ON FUNCTION "ventas"."fn_resumen_ventas"("p_fecha_inicio" "date", "p_fecha_fin" "date", "p_vendedor_id" "uuid", "p_solo_distribuidora" boolean) TO "anon";
GRANT ALL ON FUNCTION "ventas"."fn_resumen_ventas"("p_fecha_inicio" "date", "p_fecha_fin" "date", "p_vendedor_id" "uuid", "p_solo_distribuidora" boolean) TO "authenticated";



GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "auditoria"."log_auditoria" TO "anon";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "auditoria"."log_auditoria" TO "authenticated";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "auditoria"."log_auditoria" TO "service_role";



GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "auditoria"."log_error" TO "anon";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "auditoria"."log_error" TO "authenticated";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "auditoria"."log_error" TO "service_role";



GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "configuracion"."versiones_aplicacion" TO "anon";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "configuracion"."versiones_aplicacion" TO "authenticated";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "configuracion"."versiones_aplicacion" TO "service_role";















GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "inventario"."alertas" TO "anon";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "inventario"."alertas" TO "authenticated";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "inventario"."alertas" TO "service_role";



GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "inventario"."configuracion_app" TO "anon";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "inventario"."configuracion_app" TO "authenticated";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "inventario"."configuracion_app" TO "service_role";



GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "inventario"."movimientos_inventario" TO "anon";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "inventario"."movimientos_inventario" TO "authenticated";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "inventario"."movimientos_inventario" TO "service_role";



GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "inventario"."predicciones_modelo_alertas" TO "service_role";
GRANT SELECT,INSERT,UPDATE ON TABLE "inventario"."predicciones_modelo_alertas" TO "anon";
GRANT SELECT,INSERT,UPDATE ON TABLE "inventario"."predicciones_modelo_alertas" TO "authenticated";



GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "inventario"."productos" TO "anon";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "inventario"."productos" TO "authenticated";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "inventario"."productos" TO "service_role";



GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "inventario"."versiones_aplicacion" TO "service_role";
GRANT SELECT ON TABLE "inventario"."versiones_aplicacion" TO "anon";
GRANT SELECT ON TABLE "inventario"."versiones_aplicacion" TO "authenticated";



GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "rutas"."abonos" TO "anon";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "rutas"."abonos" TO "authenticated";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "rutas"."abonos" TO "service_role";



GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "rutas"."items_ruta" TO "anon";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "rutas"."items_ruta" TO "authenticated";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "rutas"."items_ruta" TO "service_role";



GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "rutas"."rutas" TO "anon";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "rutas"."rutas" TO "authenticated";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "rutas"."rutas" TO "service_role";



GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "vendedores"."vendedores" TO "anon";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "vendedores"."vendedores" TO "authenticated";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "vendedores"."vendedores" TO "service_role";



GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "ventas"."ventas" TO "anon";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "ventas"."ventas" TO "authenticated";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "ventas"."ventas" TO "service_role";



GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "rutas"."v_rutas" TO "anon";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "rutas"."v_rutas" TO "authenticated";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "rutas"."v_rutas" TO "service_role";



GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "usuarios"."sesiones_app" TO "service_role";



GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "usuarios"."tokens_dispositivo" TO "service_role";



GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "usuarios"."usuarios" TO "service_role";









GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "ventas"."items_venta" TO "anon";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "ventas"."items_venta" TO "authenticated";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "ventas"."items_venta" TO "service_role";



GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "ventas"."v_ventas" TO "anon";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "ventas"."v_ventas" TO "authenticated";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "ventas"."v_ventas" TO "service_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "auditoria" GRANT SELECT,USAGE ON SEQUENCES TO "service_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "auditoria" GRANT SELECT,INSERT,DELETE,UPDATE ON TABLES TO "service_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "inventario" GRANT SELECT,USAGE ON SEQUENCES TO "service_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "inventario" GRANT SELECT,INSERT,DELETE,UPDATE ON TABLES TO "service_role";



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






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "rutas" GRANT SELECT,USAGE ON SEQUENCES TO "service_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "rutas" GRANT SELECT,INSERT,DELETE,UPDATE ON TABLES TO "service_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "usuarios" GRANT SELECT,USAGE ON SEQUENCES TO "service_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "usuarios" GRANT SELECT,INSERT,DELETE,UPDATE ON TABLES TO "service_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "vendedores" GRANT SELECT,USAGE ON SEQUENCES TO "service_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "vendedores" GRANT SELECT,INSERT,DELETE,UPDATE ON TABLES TO "service_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "ventas" GRANT SELECT,USAGE ON SEQUENCES TO "service_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "ventas" GRANT SELECT,INSERT,DELETE,UPDATE ON TABLES TO "service_role";
































