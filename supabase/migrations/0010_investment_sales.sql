-- =====================================================================
-- 0010 — Realizacje (sprzedaż) pozycji inwestycyjnych
-- =====================================================================
-- Pozwala zapisać sprzedaż CAŁOŚCI lub CZĘŚCI pozycji i zobaczyć
-- zrealizowany wynik — zysk LUB stratę. Pozycja w `investments` zostaje
-- bez zmian; "ile jeszcze masz" liczymy jako:
--   quantity - SUMA(quantity sprzedanych)  (po stronie klienta).
-- Dzięki temu mamy pełną historię i da się cofnąć błędną sprzedaż
-- (usunięcie wiersza przywraca ilość), a wynik nie zmienia się gdy
-- później zmieni się średnia cena zakupu (snapshot kosztu w wierszu).
--
-- proceeds_cents   = ile odzyskałeś łącznie w PLN (przy całkowitej
--                    stracie = 0).
-- cost_basis_cents = koszt zakupu TEJ sprzedanej części (snapshot w
--                    momencie sprzedaży = sprzedana_ilość × cena_zakupu).
-- Zrealizowany wynik = proceeds_cents - cost_basis_cents
--                    (ujemny = strata).

create table investment_sales (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references households(id) on delete cascade,
  investment_id uuid not null references investments(id) on delete cascade,
  created_by uuid references auth.users(id),
  quantity numeric not null check (quantity > 0),
  proceeds_cents bigint not null check (proceeds_cents >= 0),
  cost_basis_cents bigint not null check (cost_basis_cents >= 0),
  sold_at date not null,
  created_at timestamptz not null default now()
);
create index investment_sales_household_idx
  on investment_sales (household_id);
create index investment_sales_investment_idx
  on investment_sales (investment_id);

-- RLS — wzorzec jak investments (członkowie gospodarstwa).
alter table investment_sales enable row level security;
create policy "members read investment_sales" on investment_sales for select
  using (is_household_member(household_id));
create policy "members insert investment_sales" on investment_sales for insert
  with check (is_household_member(household_id) and created_by = auth.uid());
create policy "members update investment_sales" on investment_sales for update
  using (is_household_member(household_id));
create policy "members delete investment_sales" on investment_sales for delete
  using (is_household_member(household_id));

-- REPLICA IDENTITY FULL — payload DELETE/UPDATE zawiera household_id, więc
-- filtr Realtime po household_id dopasowuje event (patrz 0007). Bez tego
-- usunięcie/cofnięcie sprzedaży nie znika z listy na drugim telefonie.
alter table investment_sales replica identity full;

-- Realtime — realizacje syncują się na żywo między telefonami.
alter publication supabase_realtime add table investment_sales;
