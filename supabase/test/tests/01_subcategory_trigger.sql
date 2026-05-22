-- Testy triggera `enforce_category_one_level` (migracja 0009) + zachowania
-- FK `parent_id ... on delete set null`. Uruchamiane jako superuser, więc
-- RLS nie przeszkadza — sprawdzamy CZYSTĄ logikę integralności.
\set ON_ERROR_STOP on

begin;

insert into auth.users (id, email)
  values ('11111111-1111-1111-1111-111111111111', 'a@x.pl');
insert into households (id, name)
  values ('22222222-2222-2222-2222-222222222222', 'Dom');

-- Kategorie główne (różne typy) + jedna podkategoria startowa.
insert into categories (id, household_id, name, icon, color, type, is_system)
values
  ('a0000000-0000-0000-0000-000000000001',
   '22222222-2222-2222-2222-222222222222', 'Auto', 'car', '#112233',
   'expense', false),
  ('a0000000-0000-0000-0000-000000000002',
   '22222222-2222-2222-2222-222222222222', 'Wyplata', 'cash', '#223344',
   'income', false),
  -- druga główna WYDATKOWA — do testu P0025 (ten sam typ co Auto).
  ('a0000000-0000-0000-0000-000000000003',
   '22222222-2222-2222-2222-222222222222', 'Dom', 'home', '#556600',
   'expense', false);

-- 1) Podkategoria pod kategorią główną tego samego typu → OK.
insert into categories (id, household_id, parent_id, name, icon, color, type)
values
  ('b0000000-0000-0000-0000-000000000001',
   '22222222-2222-2222-2222-222222222222',
   'a0000000-0000-0000-0000-000000000001', 'Paliwo', 'gas', '#334455',
   'expense');

-- 2) Self-parent → P0020.
do $$ begin
  begin
    update categories set parent_id = id
      where id = 'a0000000-0000-0000-0000-000000000001';
    raise exception 'FAIL: self-parent powinien być odrzucony';
  exception
    when sqlstate 'P0020' then null;
    when others then
      raise exception 'FAIL: self-parent oczekiwano P0020, było %', sqlstate;
  end;
end $$;

-- 3) Rodzic innego typu (income) dla wydatku → P0023.
do $$ begin
  begin
    insert into categories (household_id, parent_id, name, icon, color, type)
    values ('22222222-2222-2222-2222-222222222222',
      'a0000000-0000-0000-0000-000000000002', 'Zle', 'x', '#445566',
      'expense');
    raise exception 'FAIL: rodzic innego typu powinien być odrzucony';
  exception
    when sqlstate 'P0023' then null;
    when others then
      raise exception 'FAIL: inny typ oczekiwano P0023, było %', sqlstate;
  end;
end $$;

-- 4) Drugi poziom (podkategoria pod podkategorią) → P0024.
do $$ begin
  begin
    insert into categories (household_id, parent_id, name, icon, color, type)
    values ('22222222-2222-2222-2222-222222222222',
      'b0000000-0000-0000-0000-000000000001', 'Pb95', 'g', '#556677',
      'expense');
    raise exception 'FAIL: drugi poziom powinien być odrzucony';
  exception
    when sqlstate 'P0024' then null;
    when others then
      raise exception 'FAIL: 2 poziom oczekiwano P0024, było %', sqlstate;
  end;
end $$;

-- 5) Kategoria, która MA podkategorie, nie może stać się podkategorią → P0025.
-- Rodzic tego samego typu (Dom, expense), by ominąć wcześniejszy check typu.
do $$ begin
  begin
    update categories
      set parent_id = 'a0000000-0000-0000-0000-000000000003'
      where id = 'a0000000-0000-0000-0000-000000000001';
    raise exception 'FAIL: rodzic z dziećmi nie może stać się dzieckiem';
  exception
    when sqlstate 'P0025' then null;
    when others then
      raise exception 'FAIL: rodzic-z-dziećmi oczekiwano P0025, było %',
        sqlstate;
  end;
end $$;

-- 6) Usunięcie kategorii głównej promuje podkategorie (on delete set null).
delete from categories where id = 'a0000000-0000-0000-0000-000000000001';
do $$
declare p uuid;
begin
  select parent_id into p from categories
    where id = 'b0000000-0000-0000-0000-000000000001';
  if p is not null then
    raise exception 'FAIL: po usunięciu rodzica parent_id powinien być null';
  end if;
end $$;

rollback;
