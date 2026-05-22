-- =====================================================================
-- 0009 — Podkategorie (jeden poziom)
-- =====================================================================
-- Kolumna categories.parent_id istnieje od 0001, ale nigdy nie była
-- używana. Włączamy ją jako podkategorie: kategoria główna (parent_id null)
-- może mieć podkategorie tego samego typu. Maks. JEDEN poziom.
--
-- Transakcje mogą wskazywać zarówno kategorię główną, jak i podkategorię
-- (decyzja produktowa). Na dashboardzie wydatki podkategorii sumują się
-- do rodzica (logika po stronie klienta).

-- 1) Usunięcie rodzica promuje podkategorie do głównych (zamiast blokować
--    usuwanie przez FK). Transakcje na rodzicu obsługuje osobny reassign.
alter table categories drop constraint if exists categories_parent_id_fkey;
alter table categories
  add constraint categories_parent_id_fkey
  foreign key (parent_id) references categories (id) on delete set null;

create index if not exists categories_parent_idx on categories (parent_id);

-- 2) Integralność niezależna od klienta: wymuszamy jeden poziom, ten sam
--    typ i to samo gospodarstwo, brak self-referencji.
create or replace function enforce_category_one_level()
returns trigger
language plpgsql
as $$
declare
  parent_household uuid;
  parent_type tx_type;
  parent_parent uuid;
begin
  if new.parent_id is null then
    return new;
  end if;

  if new.parent_id = new.id then
    raise exception 'Kategoria nie może być swoją podkategorią'
      using errcode = 'P0020';
  end if;

  select household_id, type, parent_id
    into parent_household, parent_type, parent_parent
    from categories where id = new.parent_id;

  if not found then
    raise exception 'Kategoria nadrzędna nie istnieje' using errcode = 'P0021';
  end if;
  if parent_household is distinct from new.household_id then
    raise exception 'Kategoria nadrzędna z innego gospodarstwa'
      using errcode = 'P0022';
  end if;
  if parent_type <> new.type then
    raise exception 'Kategoria nadrzędna ma inny typ (dochód/wydatek)'
      using errcode = 'P0023';
  end if;
  if parent_parent is not null then
    raise exception 'Dozwolony jest tylko jeden poziom podkategorii'
      using errcode = 'P0024';
  end if;

  -- Kategoria, która sama ma podkategorie, nie może stać się podkategorią.
  if exists (select 1 from categories where parent_id = new.id) then
    raise exception 'Ta kategoria ma podkategorie — nie może być podkategorią'
      using errcode = 'P0025';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_category_one_level on categories;
create trigger trg_category_one_level
  before insert or update on categories
  for each row execute function enforce_category_one_level();
