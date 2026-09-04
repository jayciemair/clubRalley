-- Club Ralley Workspace — Supabase schema (Phase 5)
--
-- Run this in the SQL editor of Club Ralley's OWN Supabase project.
-- It is safe to re-run.
--
-- Security posture (see SECURITY.md):
--   * every table requires an authenticated user for read AND write
--   * tasks / resources / channels / members / categories can be deleted for
--     real by any authenticated user (matches the app's trust model: any
--     signed-in teammate can edit or remove anything)
--   * messages, activity, and settings are NEVER deleted — messages soft-delete
--     via a `deleted` flag inside their own data, activity is an append-only
--     log, settings is a singleton row that's only ever updated
--   * realtime enabled only on the tables the app subscribes to

------------------------------------------------------------------------
-- tables
------------------------------------------------------------------------

create table if not exists public.settings (
  id          text primary key default 'clubralley',
  data        jsonb not null default '{}'::jsonb,
  updated_at  timestamptz not null default now()
);

create table if not exists public.members (
  name        text primary key,
  color       text not null default '',
  updated_at  timestamptz not null default now()
);

create table if not exists public.categories (
  id          text primary key,
  name        text not null,
  color       text not null,
  sort        int  not null default 0
);

create table if not exists public.tasks (
  id          text primary key,
  data        jsonb not null,
  updated_at  timestamptz not null default now()
);

create table if not exists public.resources (
  id          text primary key,
  parent_id   text,
  data        jsonb not null,
  updated_at  timestamptz not null default now()
);

create table if not exists public.channels (
  id          text primary key,
  data        jsonb not null,
  updated_at  timestamptz not null default now()
);

create table if not exists public.messages (
  id          text primary key,
  channel_id  text not null,
  parent_id   text,
  data        jsonb not null,
  created_at  timestamptz not null default now()
);
create index if not exists messages_channel_idx on public.messages (channel_id, created_at);

create table if not exists public.activity (
  id          text primary key,
  data        jsonb not null,
  created_at  timestamptz not null default now()
);
create index if not exists activity_created_idx on public.activity (created_at desc);

-- join code check without shipping the hash to the browser
create table if not exists public.workspace_secret (
  id           int primary key default 1,
  joincode_sha text not null
);

------------------------------------------------------------------------
-- row level security: authenticated users only, no deletes
------------------------------------------------------------------------

do $$
declare t text;
begin
  foreach t in array array[
    'settings','members','categories','tasks','resources','channels','messages','activity'
  ] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists auth_read  on public.%I', t);
    execute format('drop policy if exists auth_write on public.%I', t);
    execute format('drop policy if exists auth_edit  on public.%I', t);
    execute format($p$create policy auth_read  on public.%I for select
                       using (auth.role() = 'authenticated')$p$, t);
    execute format($p$create policy auth_write on public.%I for insert
                       with check (auth.role() = 'authenticated')$p$, t);
    execute format($p$create policy auth_edit  on public.%I for update
                       using (auth.role() = 'authenticated')
                       with check (auth.role() = 'authenticated')$p$, t);
  end loop;

  -- real deletes, restricted to the same tables listed in the posture note above
  foreach t in array array['tasks','resources','channels','members','categories'] loop
    execute format('drop policy if exists auth_delete on public.%I', t);
    execute format($p$create policy auth_delete on public.%I for delete
                       using (auth.role() = 'authenticated')$p$, t);
  end loop;
end $$;

alter table public.workspace_secret enable row level security;
-- no policies on workspace_secret: only the RPC below (security definer) reads it

------------------------------------------------------------------------
-- join code RPC — call before allowing sign-up
------------------------------------------------------------------------

create or replace function public.check_join_code(candidate text)
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.workspace_secret
    where id = 1
      and joincode_sha = encode(digest('clubralley::v1::gate|' || lower(trim(candidate)), 'sha256'), 'hex')
  );
$$;

revoke all on function public.check_join_code(text) from public;
grant execute on function public.check_join_code(text) to anon, authenticated;

-- set / change the join code (run as needed; needs pgcrypto for digest())
create extension if not exists pgcrypto;
insert into public.workspace_secret (id, joincode_sha)
values (1, encode(digest('clubralley::v1::gate|ralley', 'sha256'), 'hex'))
on conflict (id) do update set joincode_sha = excluded.joincode_sha;

------------------------------------------------------------------------
-- realtime
------------------------------------------------------------------------

do $$
begin
  alter publication supabase_realtime add table
    public.tasks, public.resources, public.channels, public.messages,
    public.activity, public.members, public.categories, public.settings;
exception when duplicate_object then null;
end $$;

alter table public.tasks     replica identity full;
alter table public.resources replica identity full;
alter table public.channels  replica identity full;
alter table public.messages  replica identity full;
alter table public.activity  replica identity full;
alter table public.members   replica identity full;
alter table public.categories replica identity full;
alter table public.settings  replica identity full;
