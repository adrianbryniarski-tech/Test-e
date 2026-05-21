-- =====================================================================
-- 0006 — Inwestycje: portfel aktywów (krypto / złoto / srebro)
-- =====================================================================
-- Zakładka "Inwestycje": user wpisuje ile ma danego aktywa + cenę
-- zakupu. Apka ściąga aktualny kurs (CoinGecko / NBP / stooq) i liczy
-- zysk/stratę. Wykres wartości portfela w czasie z `portfolio_snapshots`.

-- Pozycje portfela. quantity numeric (krypto bywa ułamkowe, np. 0.0015
-- BTC). buy_price_cents = grosze PLN za JEDNĄ jednostkę (1 coin / 1 gram).
create table investments (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references households(id) on delete cascade,
  created_by uuid references auth.users(id),
  asset_type text not null check (asset_type in ('crypto','gold','silver')),
  symbol text not null,            -- coingecko id (np. 'bitcoin') / 'XAU' / 'XAG'
  display_name text not null,      -- czytelna nazwa (np. 'Bitcoin', 'Złoto')
  quantity numeric not null check (quantity > 0),
  buy_price_cents bigint not null check (buy_price_cents >= 0),
  created_at timestamptz not null default now()
);
create index investments_household_idx on investments (household_id);

-- Dzienny snapshot łącznej wartości portfela (do wykresu w czasie).
-- Jeden wiersz na (gospodarstwo, dzień) — upsert przy każdym przeliczeniu.
create table portfolio_snapshots (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references households(id) on delete cascade,
  total_value_cents bigint not null,
  captured_at date not null,
  unique (household_id, captured_at)
);
create index portfolio_snapshots_household_idx
  on portfolio_snapshots (household_id, captured_at);

-- RLS — wzorzec jak transactions (członkowie gospodarstwa).
alter table investments enable row level security;
create policy "members read investments" on investments for select
  using (is_household_member(household_id));
create policy "members insert investments" on investments for insert
  with check (is_household_member(household_id) and created_by = auth.uid());
create policy "members update investments" on investments for update
  using (is_household_member(household_id));
create policy "members delete investments" on investments for delete
  using (is_household_member(household_id));

alter table portfolio_snapshots enable row level security;
create policy "members read snapshots" on portfolio_snapshots for select
  using (is_household_member(household_id));
create policy "members write snapshots" on portfolio_snapshots for all
  using (is_household_member(household_id))
  with check (is_household_member(household_id));

-- Realtime — pozycje syncują się na żywo między telefonami.
alter publication supabase_realtime add table investments;
alter publication supabase_realtime add table portfolio_snapshots;
