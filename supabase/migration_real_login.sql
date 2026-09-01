-- migration_real_login.sql — run once in Supabase's SQL editor, AFTER
-- schema.sql and migration_va_pins.sql. This does NOT drop va_pins or the
-- old password check yet — see cleanup_real_login.sql for that, which is
-- a separate, later step run only once the whole team has migrated.

drop policy "password gate select" on app_state;
drop policy "password gate update" on app_state;

-- RLS only restricts *rows* — it doesn't grant table-level access on its
-- own, and that's a separate grant per Postgres role. schema.sql already
-- granted this to "anon" (every request before this feature existed ran
-- as anon), but a real login's requests run as "authenticated" instead,
-- which had no grant at all — every one would fail with a flat "permission
-- denied for table app_state" regardless of what the policies below allow.
grant select, update on app_state to authenticated;

-- Same REPLACE_WITH_YOUR_TEAM_PASSWORD value you set when you ran
-- schema.sql — keep it identical here, it's the same shared password,
-- just now one of two ways in instead of the only way.
create policy "app access select"
on app_state for select
using (
  current_setting('request.headers', true)::json->>'x-app-password' = 'REPLACE_WITH_YOUR_TEAM_PASSWORD'
  or (
    auth.uid() is not null
    and exists (
      select 1 from jsonb_array_elements(data->'vas') va
      where coalesce(va->>'email', '') <> ''
      and lower(va->>'email') = lower(coalesce(auth.jwt() ->> 'email', ''))
    )
  )
);

create policy "app access update"
on app_state for update
using (
  current_setting('request.headers', true)::json->>'x-app-password' = 'REPLACE_WITH_YOUR_TEAM_PASSWORD'
  or (
    auth.uid() is not null
    and exists (
      select 1 from jsonb_array_elements(data->'vas') va
      where coalesce(va->>'email', '') <> ''
      and lower(va->>'email') = lower(coalesce(auth.jwt() ->> 'email', ''))
    )
  )
)
with check (
  current_setting('request.headers', true)::json->>'x-app-password' = 'REPLACE_WITH_YOUR_TEAM_PASSWORD'
  or (
    auth.uid() is not null
    and exists (
      select 1 from jsonb_array_elements(data->'vas') va
      where coalesce(va->>'email', '') <> ''
      and lower(va->>'email') = lower(coalesce(auth.jwt() ->> 'email', ''))
    )
  )
);
