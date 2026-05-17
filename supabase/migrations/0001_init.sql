-- =====================================================================
-- Nasz budżet domowy — migracja 0001 (init)
-- Schemat: households, members, invitations, categories, transactions,
-- statement_imports, budgets + RLS na każdej tabeli + RPC.
-- =====================================================================

-- ---------- ROZSZERZENIA ----------
create extension if not exists "pgcrypto";   -- gen_random_uuid()
create extension if not exists "pg_trgm";    -- soft dedup (similarity)

-- ---------- TYPY ----------
do $$
begin
  if not exists (select 1 from pg_type where typname = 'tx_source') then
    create type tx_source as enum ('manual','voice','csv_import','pdf_import');
  end if;
  if not exists (select 1 from pg_type where typname = 'tx_type') then
    create type tx_type as enum ('income','expense');
  end if;
end$$;

-- ---------- HOUSEHOLDS ----------
create table households (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_at timestamptz not null default now()
);

create table household_members (
  household_id uuid not null references households(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('owner','member')) default 'member',
  joined_at timestamptz not null default now(),
  primary key (household_id, user_id)
);

create index household_members_user_idx on household_members (user_id);

-- ---------- INVITATIONS ----------
create table invitations (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references households(id) on delete cascade,
  code text not null unique,                       -- 6-znakowy kod (np. ABC-XYZ)
  invited_email text,
  expires_at timestamptz not null default (now() + interval '14 days'),
  accepted_by uuid references auth.users(id),
  accepted_at timestamptz,
  created_at timestamptz not null default now()
);

create index invitations_code_idx on invitations (code);

-- ---------- CATEGORIES ----------
create table categories (
  id uuid primary key default gen_random_uuid(),
  household_id uuid references households(id) on delete cascade,  -- null = systemowa szablonowa (nie używana w runtime)
  parent_id uuid references categories(id),
  name text not null,
  icon text not null,
  color text not null,
  type tx_type not null default 'expense',
  is_system boolean not null default false,
  created_at timestamptz not null default now(),
  constraint color_format check (color ~ '^#[0-9A-Fa-f]{6}$'),
  constraint icon_required check (length(icon) > 0),
  constraint name_required check (length(name) > 0 and length(name) <= 30)
);

create unique index categories_unique_name_per_household
  on categories (household_id, lower(name))
  where household_id is not null;

create index categories_household_idx on categories (household_id);

-- ---------- STATEMENT IMPORTS (v2/v3) ----------
create table statement_imports (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references households(id) on delete cascade,
  bank text not null,
  file_path text not null,                         -- private Storage bucket
  imported_by uuid references auth.users(id),
  imported_at timestamptz not null default now(),
  row_count int,
  status text not null default 'pending'
    check (status in ('pending','parsing','parsed','committed','error')),
  error_message text
);

create index statement_imports_household_idx on statement_imports (household_id, imported_at desc);

-- ---------- TRANSACTIONS ----------
create table transactions (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references households(id) on delete cascade,
  created_by uuid references auth.users(id),
  occurred_at date not null,
  amount_cents bigint not null check (amount_cents > 0),  -- znak w `type`
  type tx_type not null,
  category_id uuid not null references categories(id),
  description text,
  note text,
  source tx_source not null,
  import_id uuid references statement_imports(id) on delete set null,
  dedup_hash text not null,
  client_op_id uuid,                                -- idempotency key z offline kolejki
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint dedup_unique unique (household_id, dedup_hash)
);

create index transactions_household_date_idx
  on transactions (household_id, occurred_at desc);

create index transactions_category_idx on transactions (category_id);

create unique index transactions_client_op_unique
  on transactions (household_id, client_op_id)
  where client_op_id is not null;

-- trigger updated_at
create or replace function set_updated_at() returns trigger as $$
begin
  new.updated_at := now();
  return new;
end$$ language plpgsql;

create trigger trg_transactions_updated_at
  before update on transactions
  for each row execute function set_updated_at();

-- ---------- BUDGETS (v4, schema gotowy od początku) ----------
create table budgets (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references households(id) on delete cascade,
  category_id uuid not null references categories(id) on delete cascade,
  period text not null check (period in ('monthly')) default 'monthly',
  amount_cents bigint not null check (amount_cents > 0),
  starts_on date not null,
  created_at timestamptz not null default now()
);

create unique index budgets_unique_per_category
  on budgets (household_id, category_id, starts_on);

-- =====================================================================
-- RLS — Row Level Security
-- Wzorzec: użytkownik widzi/pisze tylko rekordy w gospodarstwach do
-- których należy. Sprawdzane przez `household_members`.
-- =====================================================================

-- Helper: czy bieżący użytkownik jest członkiem gospodarstwa
create or replace function is_household_member(hh_id uuid) returns boolean
language sql stable security invoker as $$
  select exists (
    select 1 from household_members
    where household_id = hh_id and user_id = auth.uid()
  );
$$;

-- ---- households ----
alter table households enable row level security;

create policy "members can read household"
  on households for select
  using (is_household_member(id));

create policy "authenticated can create household"
  on households for insert
  with check (auth.uid() is not null);

create policy "owners can update household"
  on households for update
  using (exists (
    select 1 from household_members
    where household_id = households.id
      and user_id = auth.uid()
      and role = 'owner'
  ));

-- ---- household_members ----
alter table household_members enable row level security;

create policy "members can read membership"
  on household_members for select
  using (is_household_member(household_id));

-- INSERT/DELETE membershipów idzie przez RPC (`accept_invitation`,
-- `create_household_with_owner`) jako security definer — brak bezpośredniego
-- write z klienta.

-- ---- invitations ----
alter table invitations enable row level security;

create policy "members can read household invitations"
  on invitations for select
  using (is_household_member(household_id));

create policy "members can create invitations"
  on invitations for insert
  with check (is_household_member(household_id));

create policy "members can delete invitations"
  on invitations for delete
  using (is_household_member(household_id));

-- ---- categories ----
alter table categories enable row level security;

create policy "members can read categories"
  on categories for select
  using (is_household_member(household_id));

create policy "members can write categories"
  on categories for insert
  with check (is_household_member(household_id) and is_system = false);

create policy "members can update own categories"
  on categories for update
  using (is_household_member(household_id) and is_system = false);

create policy "members can delete own categories"
  on categories for delete
  using (is_household_member(household_id) and is_system = false);

-- ---- transactions ----
alter table transactions enable row level security;

create policy "members can read transactions"
  on transactions for select
  using (is_household_member(household_id));

create policy "members can insert transactions"
  on transactions for insert
  with check (is_household_member(household_id) and created_by = auth.uid());

create policy "members can update transactions"
  on transactions for update
  using (is_household_member(household_id));

create policy "members can delete transactions"
  on transactions for delete
  using (is_household_member(household_id));

-- ---- statement_imports ----
alter table statement_imports enable row level security;

create policy "members can read imports"
  on statement_imports for select
  using (is_household_member(household_id));

create policy "members can write imports"
  on statement_imports for insert
  with check (is_household_member(household_id));

create policy "members can update imports"
  on statement_imports for update
  using (is_household_member(household_id));

-- ---- budgets ----
alter table budgets enable row level security;

create policy "members can read budgets"
  on budgets for select
  using (is_household_member(household_id));

create policy "members can write budgets"
  on budgets for all
  using (is_household_member(household_id))
  with check (is_household_member(household_id));

-- =====================================================================
-- RPC: tworzenie gospodarstwa + przyjmowanie zaproszeń + delete kategorii
-- Wszystkie security definer — kontrolowane omijanie RLS, z walidacją.
-- =====================================================================

-- Seed 12 polskich kategorii systemowych do nowo utworzonego gospodarstwa.
-- Spójne z paletą w lib/app/theme.dart (CategoryPalette).
create or replace function seed_categories_for_household(hh_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into categories (household_id, name, icon, color, type, is_system) values
    (hh_id, 'Spożywcze',     'shopping_cart',  '#7AB87A', 'expense', true),
    (hh_id, 'Rachunki',      'receipt_long',   '#5B8FB9', 'expense', true),
    (hh_id, 'Transport',     'directions_car', '#E8A24A', 'expense', true),
    (hh_id, 'Rozrywka',      'theaters',       '#B97AB8', 'expense', true),
    (hh_id, 'Zdrowie',       'local_pharmacy', '#E07A7A', 'expense', true),
    (hh_id, 'Dzieci',        'child_care',     '#E8C24A', 'expense', true),
    (hh_id, 'Mieszkanie',    'home_work',      '#8B7355', 'expense', true),
    (hh_id, 'Ubrania',       'checkroom',      '#B95B8F', 'expense', true),
    (hh_id, 'Pensja',        'payments',       '#4AE89E', 'income',  true),
    (hh_id, 'Inne dochody',  'savings',        '#7AE0D5', 'income',  true),
    (hh_id, 'Oszczędności',  'account_balance','#5B7AB9', 'expense', true),
    (hh_id, 'Inne',          'more_horiz',     '#94A3B8', 'expense', true);
end$$;

-- Tworzenie gospodarstwa: insert household + insert membership (owner) + seed kategorii.
-- Atomowe (jedna transakcja).
create or replace function create_household_with_owner(p_name text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  new_household_id uuid;
begin
  if auth.uid() is null then
    raise exception 'unauthenticated' using errcode = '42501';
  end if;

  insert into households (name) values (p_name)
    returning id into new_household_id;

  insert into household_members (household_id, user_id, role)
    values (new_household_id, auth.uid(), 'owner');

  perform seed_categories_for_household(new_household_id);

  return new_household_id;
end$$;

-- Przyjmowanie zaproszenia po kodzie.
create or replace function accept_invitation(p_code text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  inv_record invitations%rowtype;
begin
  if auth.uid() is null then
    raise exception 'unauthenticated' using errcode = '42501';
  end if;

  select * into inv_record from invitations where code = p_code;

  if not found then
    raise exception 'invitation_not_found' using errcode = 'P0002';
  end if;

  if inv_record.accepted_at is not null then
    raise exception 'invitation_already_used' using errcode = 'P0003';
  end if;

  if inv_record.expires_at < now() then
    raise exception 'invitation_expired' using errcode = 'P0004';
  end if;

  -- Już członek? Idempotent.
  if exists (
    select 1 from household_members
    where household_id = inv_record.household_id and user_id = auth.uid()
  ) then
    return inv_record.household_id;
  end if;

  insert into household_members (household_id, user_id, role)
    values (inv_record.household_id, auth.uid(), 'member');

  update invitations
    set accepted_by = auth.uid(), accepted_at = now()
    where id = inv_record.id;

  return inv_record.household_id;
end$$;

-- Usunięcie kategorii z przeniesieniem transakcji do innej kategorii.
-- Atomowe. Walidacja że obie kategorie są w tym samym gospodarstwie i tego samego typu.
create or replace function delete_category_with_reassign(
  p_old_id uuid,
  p_target_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  old_cat categories%rowtype;
  target_cat categories%rowtype;
begin
  if auth.uid() is null then
    raise exception 'unauthenticated' using errcode = '42501';
  end if;

  select * into old_cat from categories where id = p_old_id;
  if not found then
    raise exception 'category_not_found' using errcode = 'P0002';
  end if;

  if old_cat.is_system then
    raise exception 'cannot_delete_system_category' using errcode = 'P0010';
  end if;

  if not is_household_member(old_cat.household_id) then
    raise exception 'not_household_member' using errcode = '42501';
  end if;

  select * into target_cat from categories where id = p_target_id;
  if not found then
    raise exception 'target_category_not_found' using errcode = 'P0002';
  end if;

  if target_cat.household_id is distinct from old_cat.household_id then
    raise exception 'target_in_different_household' using errcode = 'P0011';
  end if;

  if target_cat.type <> old_cat.type then
    raise exception 'target_type_mismatch' using errcode = 'P0012';
  end if;

  update transactions
    set category_id = p_target_id
    where category_id = p_old_id;

  delete from categories where id = p_old_id;
end$$;

-- =====================================================================
-- STORAGE: bucket dla wyciągów bankowych (PDF/CSV). Tworzony imperatywnie
-- przez Supabase Dashboard lub `supabase storage create statements --private`.
-- Polityki RLS dla storage.objects ustawiać po stworzeniu bucketu (w v3).
-- =====================================================================
