-- Test izolacji RLS dla `investment_sales`: członek jednego gospodarstwa
-- NIE widzi realizacji (sprzedaży) innego gospodarstwa. Realizacje niosą
-- informację o kwotach i wyniku — muszą być tak samo odgrodzone jak
-- transakcje i pozycje portfela.
\set ON_ERROR_STOP on

begin;

insert into auth.users (id, email) values
  ('aaaa1111-0000-0000-0000-000000000001', 's1@x.pl'),
  ('aaaa2222-0000-0000-0000-000000000002', 's2@x.pl');
insert into households (id, name) values
  ('bbbb1111-0000-0000-0000-000000000001', 'Rodzina1'),
  ('bbbb2222-0000-0000-0000-000000000002', 'Rodzina2');
insert into household_members (household_id, user_id, role) values
  ('bbbb1111-0000-0000-0000-000000000001',
   'aaaa1111-0000-0000-0000-000000000001', 'owner'),
  ('bbbb2222-0000-0000-0000-000000000002',
   'aaaa2222-0000-0000-0000-000000000002', 'owner');
insert into investments
  (id, household_id, created_by, asset_type, symbol, display_name,
   quantity, buy_price_cents)
values ('dddd1111-0000-0000-0000-000000000001',
        'bbbb1111-0000-0000-0000-000000000001',
        'aaaa1111-0000-0000-0000-000000000001', 'crypto', 'bitcoin',
        'Bitcoin', 1.0, 24000000);
insert into investment_sales
  (household_id, investment_id, created_by, quantity, proceeds_cents,
   cost_basis_cents, sold_at)
values ('bbbb1111-0000-0000-0000-000000000001',
        'dddd1111-0000-0000-0000-000000000001',
        'aaaa1111-0000-0000-0000-000000000001', 0.5, 10000000, 12000000,
        date '2026-05-10');

set local role authenticated;

-- Członek Rodziny1 widzi swoją realizację.
set local test.uid = 'aaaa1111-0000-0000-0000-000000000001';
do $$ begin
  if (select count(*) from investment_sales) <> 1 then
    raise exception 'FAIL: u1 powinien widzieć 1 realizację własnego gosp.';
  end if;
end $$;

-- Członek Rodziny2 NIE widzi cudzej realizacji.
set local test.uid = 'aaaa2222-0000-0000-0000-000000000002';
do $$ begin
  if (select count(*) from investment_sales) <> 0 then
    raise exception 'FAIL: u2 NIE powinien widzieć realizacji Rodziny1 (RLS)';
  end if;
end $$;

reset role;
rollback;
