-- =====================================================================
-- 0011 — Podgląd e-maili członków gospodarstwa
--
-- RLS na `auth.users` blokuje join'a z klienta, więc lista członków
-- pokazywała tylko surowe `user_id` (UUID — nieczytelne). Tu dodajemy
-- funkcję `security definer`, która zwraca członków RAZEM z e-mailem,
-- ale TYLKO dla gospodarstwa, do którego należy wołający (bramka
-- `is_household_member`). Dzięki temu nie ma wycieku adresów obcych
-- użytkowników — `auth.uid()` pochodzi z JWT i jest niefałszowalne.
-- =====================================================================

create or replace function household_members_with_email(p_household_id uuid)
returns table (
  user_id uuid,
  role text,
  joined_at timestamptz,
  email text
)
language sql
stable
security definer
set search_path = public, auth
as $$
  select hm.user_id, hm.role, hm.joined_at, u.email
  from household_members hm
  join auth.users u on u.id = hm.user_id
  where hm.household_id = p_household_id
    -- Bramka: wynik tylko gdy wołający jest członkiem tego gospodarstwa.
    and is_household_member(p_household_id)
  order by hm.joined_at;
$$;
