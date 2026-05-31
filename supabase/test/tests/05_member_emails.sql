-- Test funkcji `household_members_with_email`:
--  (1) członek widzi e-maile WSZYSTKICH członków swojego gospodarstwa,
--  (2) obcy (członek innego gospodarstwa) NIE dostaje żadnych wierszy —
--      brak wycieku adresów. Wykonywane jako rola `authenticated`,
--      tożsamość przez GUC `test.uid`.
\set ON_ERROR_STOP on

begin;

insert into auth.users (id, email) values
  ('aaaa1111-0000-0000-0000-000000000001', 'mateusz@dom.pl'),
  ('aaaa2222-0000-0000-0000-000000000002', 'zona@dom.pl'),
  ('aaaa3333-0000-0000-0000-000000000003', 'obcy@inny.pl');
insert into households (id, name) values
  ('bbbb1111-0000-0000-0000-000000000001', 'NaszDom'),
  ('bbbb2222-0000-0000-0000-000000000002', 'ObcyDom');
insert into household_members (household_id, user_id, role) values
  ('bbbb1111-0000-0000-0000-000000000001',
   'aaaa1111-0000-0000-0000-000000000001', 'owner'),
  ('bbbb1111-0000-0000-0000-000000000001',
   'aaaa2222-0000-0000-0000-000000000002', 'member'),
  ('bbbb2222-0000-0000-0000-000000000002',
   'aaaa3333-0000-0000-0000-000000000003', 'owner');

set local role authenticated;

-- (1) Członek (mateusz) widzi oba e-maile swojego gospodarstwa.
set local test.uid = 'aaaa1111-0000-0000-0000-000000000001';
do $$
declare
  cnt int;
  has_wife boolean;
begin
  select count(*) into cnt
  from household_members_with_email(
    'bbbb1111-0000-0000-0000-000000000001');
  if cnt <> 2 then
    raise exception 'FAIL: członek powinien widzieć 2 członków, jest %', cnt;
  end if;

  select exists (
    select 1 from household_members_with_email(
      'bbbb1111-0000-0000-0000-000000000001')
    where email = 'zona@dom.pl'
  ) into has_wife;
  if not has_wife then
    raise exception 'FAIL: e-mail żony powinien być widoczny dla członka';
  end if;
end $$;

-- (2) Mateusz NIE dostaje członków OBCEGO gospodarstwa (brak wycieku).
do $$
declare cnt int;
begin
  select count(*) into cnt
  from household_members_with_email(
    'bbbb2222-0000-0000-0000-000000000002');
  if cnt <> 0 then
    raise exception
      'FAIL: nie-członek dostał % wierszy obcego gosp. (wyciek!)', cnt;
  end if;
end $$;

-- (3) Obcy też nie widzi naszego gospodarstwa.
set local test.uid = 'aaaa3333-0000-0000-0000-000000000003';
do $$
declare cnt int;
begin
  select count(*) into cnt
  from household_members_with_email(
    'bbbb1111-0000-0000-0000-000000000001');
  if cnt <> 0 then
    raise exception 'FAIL: obcy dostał % wierszy naszego gosp. (wyciek!)', cnt;
  end if;
end $$;

reset role;
rollback;
