-- =====================================================================
-- Supabase-compat shim — pozwala zaaplikować prawdziwe migracje na czystym
-- Postgresie (w testach / CI). Odtwarza tylko to, czego używają migracje:
-- schemat `auth`, `auth.uid()`, `auth.users`, role i publikację realtime.
--
-- auth.uid() czyta GUC `test.uid` — w testach ustawiamy go przez
--   set test.uid = '<uuid>';
-- aby udawać zalogowanego użytkownika.
-- =====================================================================
create extension if not exists pgcrypto;

create schema if not exists auth;

create table if not exists auth.users (
  id uuid primary key default gen_random_uuid(),
  email text
);

create or replace function auth.uid() returns uuid
  language sql stable
as $$
  select nullif(current_setting('test.uid', true), '')::uuid
$$;

do $$
begin
  if not exists (select from pg_roles where rolname = 'anon') then
    create role anon;
  end if;
  if not exists (select from pg_roles where rolname = 'authenticated') then
    create role authenticated;
  end if;
  if not exists (select from pg_roles where rolname = 'service_role') then
    create role service_role;
  end if;
end $$;

-- Migracje robią `alter publication supabase_realtime add table ...`.
create publication supabase_realtime;
