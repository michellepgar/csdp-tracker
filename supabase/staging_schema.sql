-- staging_schema.sql — run this once in the NEW Supabase project's SQL
-- editor (the one just for the test site — NOT the production project).
-- This is a from-scratch setup for the real-login-only system: no legacy
-- shared-password fallback, since this project never had one to begin with.

create table app_state (
  id int primary key default 1,
  data jsonb not null,
  updated_at timestamptz not null default now(),
  constraint singleton check (id = 1)
);

alter table app_state enable row level security;

-- RLS only restricts *rows* — it doesn't grant table-level access on its
-- own, and that's a separate grant per Postgres role. A request before
-- login runs as "anon"; a request from a signed-in user runs as
-- "authenticated" — both need the grant, or the authenticated one gets a
-- flat "permission denied for table app_state" regardless of what the RLS
-- policies below would otherwise allow.
grant select, update on app_state to anon;
grant select, update on app_state to authenticated;

create policy "app access select"
on app_state for select
using (
  auth.uid() is not null
  and exists (
    select 1 from jsonb_array_elements(data->'vas') va
    where coalesce(va->>'email', '') <> ''
    and lower(va->>'email') = lower(coalesce(auth.jwt() ->> 'email', ''))
  )
);

create policy "app access update"
on app_state for update
using (
  auth.uid() is not null
  and exists (
    select 1 from jsonb_array_elements(data->'vas') va
    where coalesce(va->>'email', '') <> ''
    and lower(va->>'email') = lower(coalesce(auth.jwt() ->> 'email', ''))
  )
)
with check (
  auth.uid() is not null
  and exists (
    select 1 from jsonb_array_elements(data->'vas') va
    where coalesce(va->>'email', '') <> ''
    and lower(va->>'email') = lower(coalesce(auth.jwt() ->> 'email', ''))
  )
);

-- Minimal starting data: a couple of demo-ish schools and a VA entry with
-- YOUR email already on it, so the moment you sign up with that email
-- you're allowlisted in — no separate "add my email" step needed here.
-- Replace 'YOUR_EMAIL_HERE' before running.
insert into app_state (id, data) values (1, jsonb_build_object(
  'schools', jsonb_build_array(
    jsonb_build_object('id', 'sch_test1', 'name', 'Test Elementary School'),
    jsonb_build_object('id', 'sch_test2', 'name', 'Test Middle School')
  ),
  'vas', jsonb_build_array(
    jsonb_build_object('id', 'va_test1', 'name', 'Michelle', 'email', 'YOUR_EMAIL_HERE')
  ),
  'schoolData', jsonb_build_object(
    'sch_test1', jsonb_build_object('vaAssigned', '', 'tasks', jsonb_build_array(), 'emailTracker', jsonb_build_array(), 'notes', jsonb_build_array()),
    'sch_test2', jsonb_build_object('vaAssigned', '', 'tasks', jsonb_build_array(), 'emailTracker', jsonb_build_array(), 'notes', jsonb_build_array())
  )
));
