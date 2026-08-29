-- schema.sql — run this once in Supabase's SQL editor (Project → SQL Editor → New query)
create table app_state (
  id int primary key default 1,
  data jsonb not null,
  updated_at timestamptz not null default now(),
  constraint singleton check (id = 1)
);

alter table app_state enable row level security;

-- Supabase's anon role has no table access by default — RLS only restricts
-- *rows*, it doesn't grant table-level access on its own. Without this,
-- every request is rejected the same way a wrong password would be.
grant select, update on app_state to anon;

create policy "password gate select"
on app_state for select
using (
  current_setting('request.headers', true)::json->>'x-app-password' = 'REPLACE_WITH_YOUR_TEAM_PASSWORD'
);

create policy "password gate update"
on app_state for update
using (
  current_setting('request.headers', true)::json->>'x-app-password' = 'REPLACE_WITH_YOUR_TEAM_PASSWORD'
)
with check (
  current_setting('request.headers', true)::json->>'x-app-password' = 'REPLACE_WITH_YOUR_TEAM_PASSWORD'
);
