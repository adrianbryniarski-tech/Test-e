-- Testy RPC `delete_category_with_reassign` (migracja 0001): kody błędów
-- P0010/P0011/P0012 + happy-path (przeniesienie transakcji). Wymaga
-- zalogowanego członka gospodarstwa → ustawiamy GUC `test.uid`.
\set ON_ERROR_STOP on

begin;

insert into auth.users (id, email)
  values ('11111111-0000-0000-0000-000000000001', 'u1@x.pl');
insert into households (id, name) values
  ('33333333-0000-0000-0000-000000000001', 'H1'),
  ('33333333-0000-0000-0000-000000000002', 'H2');
insert into household_members (household_id, user_id, role)
  values ('33333333-0000-0000-0000-000000000001',
          '11111111-0000-0000-0000-000000000001', 'owner');

insert into categories (id, household_id, name, icon, color, type, is_system)
values
  -- systemowa (h1) → P0010
  ('c0000000-0000-0000-0000-000000000001',
   '33333333-0000-0000-0000-000000000001', 'Sys', 'i', '#111111',
   'expense', true),
  -- zwykłe w h1
  ('c0000000-0000-0000-0000-000000000002',
   '33333333-0000-0000-0000-000000000001', 'StareWyd', 'i', '#222222',
   'expense', false),
  ('c0000000-0000-0000-0000-000000000003',
   '33333333-0000-0000-0000-000000000001', 'CelWyd', 'i', '#333333',
   'expense', false),
  ('c0000000-0000-0000-0000-000000000004',
   '33333333-0000-0000-0000-000000000001', 'CelDoch', 'i', '#444444',
   'income', false),
  -- kategoria w innym gospodarstwie (h2)
  ('c0000000-0000-0000-0000-000000000005',
   '33333333-0000-0000-0000-000000000002', 'ObceH2', 'i', '#555555',
   'expense', false);

-- transakcja na StareWyd — happy-path powinien ją przenieść na CelWyd.
insert into transactions
  (household_id, occurred_at, amount_cents, type, category_id, source,
   dedup_hash)
values
  ('33333333-0000-0000-0000-000000000001', date '2026-05-01', 1000,
   'expense', 'c0000000-0000-0000-0000-000000000002', 'manual', 'h1');

set test.uid = '11111111-0000-0000-0000-000000000001';

-- P0010: kategoria systemowa.
do $$ begin
  begin
    perform delete_category_with_reassign(
      'c0000000-0000-0000-0000-000000000001',
      'c0000000-0000-0000-0000-000000000003');
    raise exception 'FAIL: systemowa powinna dać P0010';
  exception
    when sqlstate 'P0010' then null;
    when others then raise exception 'FAIL: oczekiwano P0010, było %', sqlstate;
  end;
end $$;

-- P0011: cel w innym gospodarstwie.
do $$ begin
  begin
    perform delete_category_with_reassign(
      'c0000000-0000-0000-0000-000000000002',
      'c0000000-0000-0000-0000-000000000005');
    raise exception 'FAIL: obce gospodarstwo powinno dać P0011';
  exception
    when sqlstate 'P0011' then null;
    when others then raise exception 'FAIL: oczekiwano P0011, było %', sqlstate;
  end;
end $$;

-- P0012: cel innego typu (income vs expense).
do $$ begin
  begin
    perform delete_category_with_reassign(
      'c0000000-0000-0000-0000-000000000002',
      'c0000000-0000-0000-0000-000000000004');
    raise exception 'FAIL: inny typ powinien dać P0012';
  exception
    when sqlstate 'P0012' then null;
    when others then raise exception 'FAIL: oczekiwano P0012, było %', sqlstate;
  end;
end $$;

-- Happy-path: przenosi transakcję i usuwa starą kategorię.
select delete_category_with_reassign(
  'c0000000-0000-0000-0000-000000000002',
  'c0000000-0000-0000-0000-000000000003');

do $$ begin
  if exists (select 1 from categories
             where id = 'c0000000-0000-0000-0000-000000000002') then
    raise exception 'FAIL: stara kategoria powinna być usunięta';
  end if;
  if (select category_id from transactions where dedup_hash = 'h1')
     <> 'c0000000-0000-0000-0000-000000000003' then
    raise exception 'FAIL: transakcja nie została przeniesiona na cel';
  end if;
end $$;

rollback;
