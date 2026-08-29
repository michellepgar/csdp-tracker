-- fix_pgcrypto_search_path.sql — run once, after migration_va_pins.sql
-- Supabase installs pgcrypto into its own "extensions" schema by default,
-- not "public" — so set_pin/verify_pin need "extensions" on their search
-- path to find crypt()/gen_salt(). Redefines only these two functions.
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
