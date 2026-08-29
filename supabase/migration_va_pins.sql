-- migration_va_pins.sql — run once in Supabase's SQL editor, AFTER schema.sql
-- Supabase installs pgcrypto into its own "extensions" schema by default,
-- not "public" — set_pin/verify_pin below include "extensions" on their
-- search_path so crypt()/gen_salt() are found regardless of which schema
-- this ends up installed into.
create extension if not exists pgcrypto;

create table va_pins (
  name text primary key,
  pin_hash text not null,
  created_at timestamptz not null default now()
);

alter table va_pins enable row level security;
-- No policies added on purpose. RLS with zero policies blocks ALL direct
-- access (select/insert/update/delete) via the REST API, for every role,
-- including anon. The only way in is through the SECURITY DEFINER functions
-- below, which check the shared team password themselves before doing anything.

create or replace function pin_status(p_name text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_password text;
begin
  v_password := current_setting('request.headers', true)::json->>'x-app-password';
  if v_password is distinct from 'REPLACE_WITH_YOUR_TEAM_PASSWORD' then
    raise exception 'forbidden';
  end if;
  return exists (select 1 from va_pins where name = p_name);
end;
$$;

create or replace function set_pin(p_name text, p_pin text)
returns boolean
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_password text;
begin
  v_password := current_setting('request.headers', true)::json->>'x-app-password';
  if v_password is distinct from 'REPLACE_WITH_YOUR_TEAM_PASSWORD' then
    raise exception 'forbidden';
  end if;
  if exists (select 1 from va_pins where name = p_name) then
    return false;
  end if;
  insert into va_pins (name, pin_hash) values (p_name, crypt(p_pin, gen_salt('bf')));
  return true;
end;
$$;

create or replace function verify_pin(p_name text, p_pin text)
returns boolean
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_password text;
  v_hash text;
begin
  v_password := current_setting('request.headers', true)::json->>'x-app-password';
  if v_password is distinct from 'REPLACE_WITH_YOUR_TEAM_PASSWORD' then
    raise exception 'forbidden';
  end if;
  select pin_hash into v_hash from va_pins where name = p_name;
  if v_hash is null then
    return false;
  end if;
  return v_hash = crypt(p_pin, v_hash);
end;
$$;

grant execute on function pin_status(text) to anon;
grant execute on function set_pin(text, text) to anon;
grant execute on function verify_pin(text, text) to anon;
