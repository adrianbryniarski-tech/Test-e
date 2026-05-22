-- Test izolacji RLS: członek jednego gospodarstwa NIE widzi transakcji
-- innego. To kluczowa własność bezpieczeństwa apki dla dwóch rodzin.
-- Wykonywane jako rola `authenticated` (RLS egzekwowane), tożsamość przez
-- GUC `test.uid`. `set local` → stan znika po rollback.
\set ON_ERROR_STOP on

begin;

insert into auth.users (id, email) values
  ('aaaa1111-0000-0000-0000-000000000001', 'u1@x.pl'),
  ('aaaa2222-0000-0000-0000-000000000002', 'u2@x.pl');
insert into households (id, name) values
  ('bbbb1111-0000-0000-0000-000000000001', 'Rodzina1'),
  ('bbbb2222-0000-0000-0000-000000000002', 'Rodzina2');
insert into household_members (household_id, user_id, role) values
  ('bbbb1111-0000-0000-0000-000000000001',
   'aaaa1111-0000-0000-0000-000000000001', 'owner'),
  ('bbbb2222-0000-0000-0000-000000000002',
   'aaaa2222-0000-0000-0000-000000000002', 'owner');
insert into categories (id, household_id, name, icon, color, type)
values ('cccc1111-0000-0000-0000-000000000001',
        'bbbb1111-0000-0000-0000-000000000001', 'Jedzenie', 'i', '#101010',
        'expense');
insert into transactions
  (household_id, occurred_at, amount_cents, type, category_id, source,
   dedup_hash)
values ('bbbb1111-0000-0000-0000-000000000001', date '2026-05-01', 500,
        'expense', 'cccc1111-0000-0000-0000-000000000001', 'manual', 'r1');

set local role authenticated;

-- Członek Rodziny1 widzi swoją transakcję.
set local test.uid = 'aaaa1111-0000-0000-0000-000000000001';
do $$ begin
  if (select count(*) from transactions) <> 1 then
    raise exception 'FAIL: u1 powinien widzieć 1 transakcję własnego gosp.';
  end if;
end $$;

-- Członek Rodziny2 NIE widzi cudzej transakcji.
set local test.uid = 'aaaa2222-0000-0000-0000-000000000002';
do $$ begin
  if (select count(*) from transactions) <> 0 then
    raise exception 'FAIL: u2 NIE powinien widzieć transakcji Rodziny1 (RLS)';
  end if;
end $$;

reset role;
rollback;
